// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MathLib
 * @notice Math utilities for NexusLend calculations
 *
 * WHY A LIBRARY?
 * - Reusable code across contracts
 * - Gas efficient (inlined at compile time)
 * - Cleaner, more readable main contracts
 */
library MathLib {
    /// @notice Ray unit (27 decimals) - used for precise percentages
    uint256 internal constant RAY = 1e27;

    /// @notice Half ray for rounding
    uint256 internal constant HALF_RAY = RAY / 2;

    /// @notice WAD unit (18 decimals) - used for token amounts
    uint256 internal constant WAD = 1e18;

    /// @notice Half wad for rounding
    uint256 internal constant HALF_WAD = WAD / 2;

    // ============ Ray Math ============

    /**
     * @notice Multiply two ray values
     * @param a First value in ray
     * @param b Second value in ray
     * @return Result in ray
     *
     * EXAMPLE:
     * rayMul(0.5e27, 0.5e27) = 0.25e27  (50% × 50% = 25%)
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return 0;
        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @notice Divide two ray values
     * @param a Numerator in ray
     * @param b Denominator in ray
     * @return Result in ray
     *
     * EXAMPLE:
     * rayDiv(0.5e27, 0.25e27) = 2e27  (50% / 25% = 200%)
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathLib: division by zero");
        return (a * RAY + b / 2) / b;
    }

    // ============ WAD Math ============

    /**
     * @notice Multiply two wad values
     * @param a First value in wad
     * @param b Second value in wad
     * @return Result in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return 0;
        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @notice Divide two wad values
     * @param a Numerator in wad
     * @param b Denominator in wad
     * @return Result in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathLib: division by zero");
        return (a * WAD + b / 2) / b;
    }

    // ============ Percentage Math ============

    /**
     * @notice Calculate percentage of a value
     * @param value Base value
     * @param percentage Percentage in basis points (10000 = 100%)
     * @return Result
     *
     * EXAMPLE:
     * percentOf(1000, 500) = 50  (5% of 1000)
     */
    function percentOf(
        uint256 value,
        uint256 percentage
    ) internal pure returns (uint256) {
        return (value * percentage) / 10000;
    }

    /**
     * @notice Calculate what percentage a is of b
     * @param a Part
     * @param b Whole
     * @return Percentage in basis points (10000 = 100%)
     */
    function percentageOf(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        require(b != 0, "MathLib: division by zero");
        return (a * 10000) / b;
    }

    // ============ Safe Math ============

    /**
     * @notice Return minimum of two values
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Return maximum of two values
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice Subtract with floor at 0 (no underflow)
     */
    function subFloor(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}
