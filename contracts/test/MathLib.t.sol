// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/libraries/MathLib.sol";

/**
 * @title MathLibTest
 * @notice Tests for the math library
 */
contract MathLibTest is Test {
    using MathLib for uint256;

    uint256 constant RAY = 1e27;
    uint256 constant WAD = 1e18;

    // ============ Ray Math Tests ============

    function test_RayMul_Basic() public pure {
        // 50% * 50% = 25%
        uint256 result = MathLib.rayMul(5e26, 5e26);
        assertEq(result, 25e25); // 25%
    }

    function test_RayMul_OneHundredPercent() public pure {
        // 100% * 50% = 50%
        uint256 result = MathLib.rayMul(RAY, 5e26);
        assertEq(result, 5e26);
    }

    function test_RayMul_Zero() public pure {
        uint256 result = MathLib.rayMul(0, RAY);
        assertEq(result, 0);
    }

    function test_RayDiv_Basic() public pure {
        // 50% / 25% = 200%
        uint256 result = MathLib.rayDiv(5e26, 25e25);
        assertEq(result, 2e27); // 200%
    }

    function test_RayDiv_OneHundredPercent() public pure {
        // 50% / 100% = 50%
        uint256 result = MathLib.rayDiv(5e26, RAY);
        assertEq(result, 5e26);
    }

    function test_RayDiv_RevertOnZero() public {
        // Division by zero should revert
        bool reverted = false;
        try this.rayDivHelper(RAY, 0) returns (uint256) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted);
    }

    // Helper function for try/catch
    function rayDivHelper(
        uint256 a,
        uint256 b
    ) external pure returns (uint256) {
        return MathLib.rayDiv(a, b);
    }

    // ============ WAD Math Tests ============

    function test_WadMul_Basic() public pure {
        // 2 * 3 = 6
        uint256 result = MathLib.wadMul(2e18, 3e18);
        assertEq(result, 6e18);
    }

    function test_WadDiv_Basic() public pure {
        // 6 / 2 = 3
        uint256 result = MathLib.wadDiv(6e18, 2e18);
        assertEq(result, 3e18);
    }

    // ============ Percentage Tests ============

    function test_PercentOf_FivePercent() public pure {
        // 5% of 1000 = 50
        uint256 result = MathLib.percentOf(1000, 500); // 500 bp = 5%
        assertEq(result, 50);
    }

    function test_PercentOf_OneHundredPercent() public pure {
        // 100% of 1000 = 1000
        uint256 result = MathLib.percentOf(1000, 10000);
        assertEq(result, 1000);
    }

    function test_PercentageOf_Basic() public pure {
        // 50 is 5% of 1000
        uint256 result = MathLib.percentageOf(50, 1000);
        assertEq(result, 500); // 500 bp = 5%
    }

    // ============ Safe Math Tests ============

    function test_Min() public pure {
        assertEq(MathLib.min(5, 10), 5);
        assertEq(MathLib.min(10, 5), 5);
        assertEq(MathLib.min(5, 5), 5);
    }

    function test_Max() public pure {
        assertEq(MathLib.max(5, 10), 10);
        assertEq(MathLib.max(10, 5), 10);
        assertEq(MathLib.max(5, 5), 5);
    }

    function test_SubFloor_NoUnderflow() public pure {
        assertEq(MathLib.subFloor(10, 5), 5);
    }

    function test_SubFloor_WouldUnderflow() public pure {
        // Instead of reverting, returns 0
        assertEq(MathLib.subFloor(5, 10), 0);
    }

    // ============ Fuzz Tests ============

    function testFuzz_RayMulCommutative(uint256 a, uint256 b) public pure {
        // Bound to avoid overflow (max ~10^18 to prevent overflow with RAY)
        a = bound(a, 0, 1e30);
        b = bound(b, 0, 1e30);

        assertEq(MathLib.rayMul(a, b), MathLib.rayMul(b, a));
    }

    function testFuzz_MinMax(uint256 a, uint256 b) public pure {
        uint256 minVal = MathLib.min(a, b);
        uint256 maxVal = MathLib.max(a, b);

        assertLe(minVal, maxVal);
        assertTrue(minVal == a || minVal == b);
        assertTrue(maxVal == a || maxVal == b);
    }
}
