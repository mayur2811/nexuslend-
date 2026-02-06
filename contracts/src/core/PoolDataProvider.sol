// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/Interfaces.sol";

/**
 * @title PoolDataProvider
 * @notice Read-only contract for frontend/analytics
 *
 * WHY THIS CONTRACT?
 * - Frontend needs lots of data
 * - Better to have one contract with all view functions
 * - Reduces frontend complexity
 * - Gas-free reads!
 */
contract PoolDataProvider {
    /// @notice Main lending pool
    address public immutable pool;

    /// @notice Price oracle
    IPriceOracle public immutable priceOracle;

    /// @notice Ray constant
    uint256 private constant RAY = 1e27;

    constructor(address _pool, address _priceOracle) {
        pool = _pool;
        priceOracle = IPriceOracle(_priceOracle);
    }

    // ============ User Data ============

    /**
     * @notice Get complete user position data
     * @param user Address to query
     * @return totalCollateralUSD Total collateral in USD
     * @return totalDebtUSD Total debt in USD
     * @return availableBorrowUSD How much more can be borrowed
     * @return healthFactor Current health factor
     * @return ltv Current loan-to-value ratio
     */
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralUSD,
            uint256 totalDebtUSD,
            uint256 availableBorrowUSD,
            uint256 healthFactor,
            uint256 ltv
        )
    {
        // These would call the pool contract in production
        // For now, returning placeholder structure

        // In production:
        // totalCollateralUSD = INexusPool(pool).getUserTotalCollateral(user);
        // totalDebtUSD = INexusPool(pool).getUserTotalDebt(user);
        // healthFactor = INexusPool(pool).getHealthFactor(user);

        return (0, 0, 0, RAY, 0); // Placeholder
    }

    /**
     * @notice Get user's position for a specific asset
     * @param user User address
     * @param asset Asset address
     * @return currentSupply Current supply balance
     * @return currentBorrow Current borrow balance
     * @return supplyRate Current supply APY
     * @return borrowRate Current borrow APY
     */
    function getUserAssetData(
        address user,
        address asset
    )
        external
        view
        returns (
            uint256 currentSupply,
            uint256 currentBorrow,
            uint256 supplyRate,
            uint256 borrowRate
        )
    {
        // Placeholder - would call pool in production
        return (0, 0, 0, 0);
    }

    // ============ Asset Data ============

    /**
     * @notice Get complete data for an asset
     * @param asset Asset address
     * @return totalSupply Total supplied
     * @return totalBorrow Total borrowed
     * @return supplyRate Current supply APY
     * @return borrowRate Current borrow APY
     * @return utilizationRate Current utilization
     * @return priceUSD Current price in USD
     * @return ltv Loan-to-value ratio
     * @return liquidationThreshold When liquidation triggers
     */
    function getAssetData(
        address asset
    )
        external
        view
        returns (
            uint256 totalSupply,
            uint256 totalBorrow,
            uint256 supplyRate,
            uint256 borrowRate,
            uint256 utilizationRate,
            uint256 priceUSD,
            uint256 ltv,
            uint256 liquidationThreshold
        )
    {
        priceUSD = priceOracle.getPrice(asset);
        // Other values would come from pool
        return (0, 0, 0, 0, 0, priceUSD, 0, 0);
    }

    /**
     * @notice Get all supported assets
     * @return List of asset addresses
     */
    function getAllAssets() external view returns (address[] memory) {
        // Would return INexusPool(pool).getSupportedAssets()
        return new address[](0);
    }

    // ============ Protocol Data ============

    /**
     * @notice Get total protocol TVL
     * @return Total value locked in USD
     */
    function getTotalValueLocked() external view returns (uint256) {
        // Sum of all assets' total supply * price
        return 0; // Placeholder
    }

    /**
     * @notice Get total protocol debt
     * @return Total borrows in USD
     */
    function getTotalDebt() external view returns (uint256) {
        // Sum of all assets' total borrow * price
        return 0; // Placeholder
    }

    /**
     * @notice Get protocol utilization
     * @return Overall utilization rate
     */
    function getProtocolUtilization() external view returns (uint256) {
        uint256 tvl = this.getTotalValueLocked();
        uint256 debt = this.getTotalDebt();

        if (tvl == 0) return 0;
        return (debt * RAY) / tvl;
    }

    // ============ Liquidation Data ============

    /**
     * @notice Check if user can be liquidated
     * @param user User to check
     * @return canLiquidate Whether liquidation is possible
     * @return healthFactor Current health factor
     * @return maxLiquidatableDebt Maximum debt that can be liquidated
     */
    function getLiquidationData(
        address user
    )
        external
        view
        returns (
            bool canLiquidate,
            uint256 healthFactor,
            uint256 maxLiquidatableDebt
        )
    {
        // Would call LiquidationEngine
        return (false, RAY, 0);
    }
}
