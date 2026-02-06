// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/InterestRateModel.sol";

/**
 * @title InterestRateModelTest
 * @notice Tests for the two-slope interest rate model
 */
contract InterestRateModelTest is Test {
    InterestRateModel public model;

    // Test parameters (like Aave)
    uint256 constant RAY = 1e27;
    uint256 constant BASE_RATE = 2e25; // 2%
    uint256 constant SLOPE1 = 10e25; // 10%
    uint256 constant SLOPE2 = 100e25; // 100%
    uint256 constant OPTIMAL = 80e25; // 80%

    function setUp() public {
        model = new InterestRateModel(BASE_RATE, SLOPE1, SLOPE2, OPTIMAL);
    }

    // ============ Utilization Rate Tests ============

    function test_UtilizationRate_ZeroBorrows() public view {
        // No borrows = 0% utilization
        uint256 utilization = model.getUtilizationRate(0, 1000e18);
        assertEq(utilization, 0);
    }

    function test_UtilizationRate_ZeroLiquidity() public view {
        // All borrowed = 100% utilization
        uint256 utilization = model.getUtilizationRate(1000e18, 0);
        assertEq(utilization, RAY);
    }

    function test_UtilizationRate_FiftyPercent() public view {
        // 500 borrowed, 500 available = 50%
        uint256 utilization = model.getUtilizationRate(500e18, 500e18);
        assertEq(utilization, 50e25); // 50% in ray
    }

    function test_UtilizationRate_EightyPercent() public view {
        // 800 borrowed, 200 available = 80%
        uint256 utilization = model.getUtilizationRate(800e18, 200e18);
        assertEq(utilization, 80e25); // 80% in ray
    }

    // ============ Borrow Rate Tests ============

    function test_BorrowRate_ZeroUtilization() public view {
        // 0% utilization = base rate only
        uint256 rate = model.getBorrowRate(0, 1000e18);
        assertEq(rate, BASE_RATE);
    }

    function test_BorrowRate_AtOptimal() public view {
        // 80% utilization = base + slope1
        uint256 rate = model.getBorrowRate(800e18, 200e18);
        uint256 expected = BASE_RATE + SLOPE1;
        assertEq(rate, expected);
    }

    function test_BorrowRate_BelowOptimal() public view {
        // 40% utilization (half of optimal)
        uint256 rate = model.getBorrowRate(400e18, 600e18);

        // Expected: base + (40/80) * slope1 = 2% + 5% = 7%
        uint256 expected = BASE_RATE + (SLOPE1 / 2);
        assertEq(rate, expected);
    }

    function test_BorrowRate_AboveOptimal() public view {
        // 90% utilization
        uint256 rate = model.getBorrowRate(900e18, 100e18);

        // Expected: base + slope1 + ((90-80)/(100-80)) * slope2
        // = 2% + 10% + (10/20) * 100% = 2% + 10% + 50% = 62%
        uint256 excessUtil = 10e25; // 10%
        uint256 remainingSpace = 20e25; // 20%
        uint256 steepIncrease = (excessUtil * SLOPE2) / remainingSpace;
        uint256 expected = BASE_RATE + SLOPE1 + steepIncrease;

        assertEq(rate, expected);
    }

    function test_BorrowRate_FullUtilization() public view {
        // 100% utilization
        uint256 rate = model.getBorrowRate(1000e18, 0);

        // Expected: base + slope1 + slope2 = 2% + 10% + 100% = 112%
        uint256 expected = BASE_RATE + SLOPE1 + SLOPE2;
        assertEq(rate, expected);
    }

    // ============ Supply Rate Tests ============

    function test_SupplyRate_ZeroUtilization() public view {
        // No borrows = no yield
        uint256 rate = model.getSupplyRate(0, 1000e18, 10e25);
        assertEq(rate, 0);
    }

    function test_SupplyRate_WithReserveFactor() public view {
        // 50% utilization, 10% reserve factor
        uint256 reserveFactor = 10e25; // 10%
        uint256 supplyRate = model.getSupplyRate(500e18, 500e18, reserveFactor);

        // Supply rate should be greater than 0 and less than borrow rate
        uint256 borrowRate = model.getBorrowRate(500e18, 500e18);

        assertGt(supplyRate, 0);
        assertLt(supplyRate, borrowRate);
    }

    // ============ Fuzz Tests ============

    function testFuzz_UtilizationNeverExceedsRay(
        uint256 borrows,
        uint256 liquidity
    ) public view {
        // Bound to reasonable values
        borrows = bound(borrows, 0, 1e30);
        liquidity = bound(liquidity, 0, 1e30);

        uint256 utilization = model.getUtilizationRate(borrows, liquidity);
        assertLe(utilization, RAY);
    }

    function testFuzz_BorrowRateIncreases(
        uint256 borrows1,
        uint256 borrows2,
        uint256 totalSupply
    ) public view {
        // Bound to reasonable values to avoid overflow (max $1 trillion)
        totalSupply = bound(totalSupply, 1, 1e30);
        borrows1 = bound(borrows1, 0, totalSupply);
        borrows2 = bound(borrows2, borrows1, totalSupply);

        uint256 liquidity1 = totalSupply - borrows1;
        uint256 liquidity2 = totalSupply - borrows2;

        uint256 rate1 = model.getBorrowRate(borrows1, liquidity1);
        uint256 rate2 = model.getBorrowRate(borrows2, liquidity2);

        // Higher utilization should = higher rate
        assertGe(rate2, rate1);
    }
}
