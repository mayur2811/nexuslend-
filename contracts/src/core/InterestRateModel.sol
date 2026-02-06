// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title InterestRateModel
 * @notice Calculates borrow and supply rates based on pool utilization
 *
 * HOW IT WORKS:
 * - When utilization is LOW (few borrowers) → LOW rates
 * - When utilization is HIGH (many borrowers) → HIGH rates
 * - There's a "kink" at optimal utilization where rates spike
 *
 * THE MATH:
 * - Below optimal: Rate = BaseRate + (utilization/optimal) * Slope1
 * - Above optimal: Rate = BaseRate + Slope1 + ((utilization-optimal)/(1-optimal)) * Slope2
 */
contract InterestRateModel {
    // ============ Constants ============
    // All rates are in "ray" format: 1e27 = 100%
    // This gives us 27 decimal places of precision

    uint256 public constant RAY = 1e27; // 100% in ray
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // ============ Rate Parameters ============
    // These define the shape of our interest rate curve

    uint256 public baseRatePerYear; // Minimum rate (even at 0% utilization)
    uint256 public slope1; // Rate increase below optimal utilization
    uint256 public slope2; // Rate increase above optimal (steeper!)
    uint256 public optimalUtilization; // The "kink" point (usually 80%)

    // ============ Events ============
    // Events let frontend apps & indexers track changes

    event RateParametersUpdated(
        uint256 baseRate,
        uint256 slope1,
        uint256 slope2,
        uint256 optimalUtilization
    );

    // ============ Constructor ============
    // Sets initial parameters when contract is deployed

    /**
     * @param _baseRatePerYear Base rate in ray (e.g., 2% = 0.02e27)
     * @param _slope1 Slope before optimal in ray (e.g., 10% = 0.1e27)
     * @param _slope2 Slope after optimal in ray (e.g., 100% = 1e27)
     * @param _optimalUtilization Kink point in ray (e.g., 80% = 0.8e27)
     */
    constructor(
        uint256 _baseRatePerYear,
        uint256 _slope1,
        uint256 _slope2,
        uint256 _optimalUtilization
    ) {
        baseRatePerYear = _baseRatePerYear;
        slope1 = _slope1;
        slope2 = _slope2;
        optimalUtilization = _optimalUtilization;

        emit RateParametersUpdated(
            _baseRatePerYear,
            _slope1,
            _slope2,
            _optimalUtilization
        );
    }

    // ============ View Functions ============

    /**
     * @notice Calculate utilization rate of the pool
     * @param totalBorrows Total amount borrowed from pool
     * @param totalLiquidity Total available (supplied - borrowed + reserves)
     * @return Utilization rate in ray (0 to 1e27)
     *
     * Formula: Utilization = TotalBorrows / (TotalBorrows + AvailableLiquidity)
     */
    function getUtilizationRate(
        uint256 totalBorrows,
        uint256 totalLiquidity
    ) public pure returns (uint256) {
        // If no borrows, utilization is 0
        if (totalBorrows == 0) {
            return 0;
        }

        // If no liquidity at all, utilization is 100%
        if (totalLiquidity == 0) {
            return RAY;
        }

        // Calculate: borrows / (borrows + liquidity) * RAY
        // We multiply by RAY first to maintain precision
        return (totalBorrows * RAY) / (totalBorrows + totalLiquidity);
    }

    /**
     * @notice Calculate the current borrow rate per year
     * @param totalBorrows Total borrowed from pool
     * @param totalLiquidity Total available liquidity
     * @return Borrow rate per year in ray
     *
     * This implements the two-slope model:
     * - Gentle slope below optimal utilization
     * - Steep slope above optimal (to discourage over-borrowing)
     */
    function getBorrowRate(
        uint256 totalBorrows,
        uint256 totalLiquidity
    ) public view returns (uint256) {
        uint256 utilization = getUtilizationRate(totalBorrows, totalLiquidity);

        // CASE 1: Below or at optimal utilization
        // Rate = BaseRate + (utilization / optimal) * Slope1
        if (utilization <= optimalUtilization) {
            // (utilization * slope1) / optimalUtilization
            uint256 rateIncrease = (utilization * slope1) / optimalUtilization;
            return baseRatePerYear + rateIncrease;
        }

        // CASE 2: Above optimal utilization
        // Rate = BaseRate + Slope1 + ((utilization - optimal) / (1 - optimal)) * Slope2
        else {
            // First, add the full slope1 (we've passed optimal)
            uint256 normalRate = baseRatePerYear + slope1;

            // Calculate excess utilization (how much above optimal)
            uint256 excessUtilization = utilization - optimalUtilization;

            // Calculate remaining space (from optimal to 100%)
            uint256 remainingSpace = RAY - optimalUtilization;

            // Calculate steep rate increase
            uint256 steepIncrease = (excessUtilization * slope2) /
                remainingSpace;

            return normalRate + steepIncrease;
        }
    }

    /**
     * @notice Calculate the current supply rate per year
     * @param totalBorrows Total borrowed from pool
     * @param totalLiquidity Total available liquidity
     * @param reserveFactor Percentage of interest that goes to protocol (in ray)
     * @return Supply rate per year in ray
     *
     * Formula: SupplyRate = BorrowRate * Utilization * (1 - ReserveFactor)
     *
     * Why? Because:
     * - Only borrowed funds generate interest
     * - Protocol takes a cut (reserve factor)
     * - Rest is distributed to suppliers based on utilization
     */
    function getSupplyRate(
        uint256 totalBorrows,
        uint256 totalLiquidity,
        uint256 reserveFactor
    ) public view returns (uint256) {
        uint256 borrowRate = getBorrowRate(totalBorrows, totalLiquidity);
        uint256 utilization = getUtilizationRate(totalBorrows, totalLiquidity);

        // (1 - reserveFactor)
        uint256 oneMinusReserve = RAY - reserveFactor;

        // SupplyRate = BorrowRate * Utilization * (1 - ReserveFactor) / RAY / RAY
        // We divide by RAY after each multiplication to prevent overflow
        uint256 rateTimesUtil = (borrowRate * utilization) / RAY;
        return (rateTimesUtil * oneMinusReserve) / RAY;
    }

    /**
     * @notice Get borrow rate per second (for compounding)
     * @param totalBorrows Total borrowed
     * @param totalLiquidity Available liquidity
     * @return Rate per second in ray
     */
    function getBorrowRatePerSecond(
        uint256 totalBorrows,
        uint256 totalLiquidity
    ) external view returns (uint256) {
        return getBorrowRate(totalBorrows, totalLiquidity) / SECONDS_PER_YEAR;
    }
}
