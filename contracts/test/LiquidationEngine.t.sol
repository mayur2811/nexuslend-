// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/LiquidationEngine.sol";
import "../src/core/MockPriceOracle.sol";

/**
 * @title LiquidationEngineTest
 * @notice Tests for the gradual liquidation system
 */
contract LiquidationEngineTest is Test {
    LiquidationEngine public engine;
    MockPriceOracle public oracle;

    address public pool;
    address public borrower;
    address public liquidator;

    uint256 constant RAY = 1e27;

    function setUp() public {
        pool = address(0x100);
        borrower = address(0x200);
        liquidator = address(0x300);

        oracle = new MockPriceOracle();
        engine = new LiquidationEngine(pool, address(oracle));
    }

    // ============ Constants Tests ============

    function test_GracePeriodIsOneHour() public view {
        assertEq(engine.GRACE_PERIOD(), 1 hours);
    }

    function test_MaxLiquidationIs25Percent() public view {
        assertEq(engine.MAX_LIQUIDATION_PERCENT(), 25);
    }

    function test_CooldownIs15Minutes() public view {
        assertEq(engine.LIQUIDATION_COOLDOWN(), 15 minutes);
    }

    function test_LiquidationBonusIs5Percent() public view {
        assertEq(engine.DEFAULT_LIQUIDATION_BONUS(), 5e25); // 5% in ray
    }

    // ============ Grace Period Tests ============

    function test_GracePeriodNotStartedInitially() public view {
        assertEq(engine.gracePeriodStart(borrower), 0);
    }

    function test_GetGracePeriodRemainingWhenNotStarted() public view {
        uint256 remaining = engine.getGracePeriodRemaining(borrower);
        assertEq(remaining, 0);
    }

    // ============ Liquidation Check Tests ============

    function test_CannotLiquidateHealthyUser() public view {
        (bool canLiq, string memory reason) = engine.canLiquidate(borrower);
        assertFalse(canLiq);
        assertEq(reason, "User is healthy");
    }

    // ============ Self-Rescue Tests ============

    function test_OnlyPoolCanNotifySelfRescue() public {
        vm.prank(liquidator);
        vm.expectRevert("Only pool can notify");
        engine.notifySelfRescue(borrower);
    }

    // ============ View Functions ============

    function test_GetMaxLiquidatableDebt() public view {
        // Returns 0 since it's a placeholder
        uint256 maxDebt = engine.getMaxLiquidatableDebt(borrower, address(0x1));
        assertEq(maxDebt, 0);
    }
}
