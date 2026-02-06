// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/DebtToken.sol";
import "./mocks/MockERC20.sol";

/**
 * @title DebtTokenTest
 * @notice Tests for the debt tracking token
 */
contract DebtTokenTest is Test {
    DebtToken public debtToken;
    MockERC20 public underlying;

    address public pool;
    address public borrower;

    uint256 constant RAY = 1e27;

    function setUp() public {
        pool = address(this); // This test contract is the pool
        borrower = address(0x200);

        underlying = new MockERC20("DAI", "DAI", 18);

        vm.prank(pool);
        debtToken = new DebtToken(address(underlying), "Debt DAI", "dDAI");
    }

    // ============ Initial State ============

    function test_InitialBorrowIndexIsRay() public view {
        assertEq(debtToken.borrowIndex(), RAY);
    }

    function test_InitialBalanceIsZero() public view {
        assertEq(debtToken.balanceOf(borrower), 0);
    }

    function test_UnderlyingAssetIsSet() public view {
        assertEq(debtToken.underlyingAsset(), address(underlying));
    }

    // ============ Mint Tests ============

    function test_Mint() public {
        debtToken.mint(borrower, 1000e18, RAY);

        // Balance should be 1000 (since index = 1.0)
        assertEq(debtToken.balanceOf(borrower), 1000e18);
    }

    function test_MintWithHigherIndex() public {
        // Index at 1.1 (10% interest accrued)
        uint256 index = 11e26; // 1.1 in ray

        debtToken.mint(borrower, 1000e18, index);

        // Stored scaled balance = 1000 / 1.1 ≈ 909
        // Actual balance = 909 * 1.1 ≈ 1000
        assertApproxEqRel(debtToken.balanceOf(borrower), 1000e18, 1e15);
    }

    function test_OnlyPoolCanMint() public {
        vm.prank(borrower);
        vm.expectRevert("DebtToken: only pool");
        debtToken.mint(borrower, 1000e18, RAY);
    }

    // ============ Burn Tests ============

    function test_Burn() public {
        debtToken.mint(borrower, 1000e18, RAY);
        debtToken.burn(borrower, 500e18, RAY);

        assertEq(debtToken.balanceOf(borrower), 500e18);
    }

    function test_OnlyPoolCanBurn() public {
        debtToken.mint(borrower, 1000e18, RAY);

        vm.prank(borrower);
        vm.expectRevert("DebtToken: only pool");
        debtToken.burn(borrower, 500e18, RAY);
    }

    // ============ Transfer Restriction Tests ============

    function test_CannotTransfer() public {
        debtToken.mint(borrower, 1000e18, RAY);

        vm.prank(borrower);
        vm.expectRevert("DebtToken: transfer not allowed");
        debtToken.transfer(address(0x999), 100e18);
    }

    function test_CannotTransferFrom() public {
        debtToken.mint(borrower, 1000e18, RAY);

        vm.prank(borrower);
        vm.expectRevert("DebtToken: transferFrom not allowed");
        debtToken.transferFrom(borrower, address(0x999), 100e18);
    }

    function test_CannotApprove() public {
        vm.prank(borrower);
        vm.expectRevert("DebtToken: approve not allowed");
        debtToken.approve(address(0x999), 100e18);
    }

    // ============ Index Tests ============

    function test_UpdateBorrowIndex() public {
        uint256 newIndex = 12e26; // 1.2
        debtToken.updateBorrowIndex(newIndex);

        assertEq(debtToken.borrowIndex(), newIndex);
    }

    function test_CannotDecreaseIndex() public {
        uint256 newIndex = 12e26;
        debtToken.updateBorrowIndex(newIndex);

        vm.expectRevert("Index can only increase");
        debtToken.updateBorrowIndex(RAY); // Lower than current
    }

    // ============ Scaled Balance Tests ============

    function test_ScaledBalance() public {
        debtToken.mint(borrower, 1000e18, RAY);

        uint256 scaled = debtToken.scaledBalanceOf(borrower);
        assertEq(scaled, 1000e18);
    }

    function test_BalanceGrowsWithIndex() public {
        // Borrow 1000 at index 1.0
        debtToken.mint(borrower, 1000e18, RAY);

        // Index increases to 1.1 (10% interest)
        debtToken.updateBorrowIndex(11e26);

        // Balance should be ~1100
        uint256 balance = debtToken.balanceOf(borrower);
        assertApproxEqRel(balance, 1100e18, 1e15);
    }
}
