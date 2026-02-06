// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/NexusAccessControl.sol";

/**
 * @title NexusAccessControlTest
 * @notice Tests for role-based access control
 */
contract NexusAccessControlTest is Test {
    NexusAccessControl public acl;

    address public owner;
    address public guardian;
    address public riskAdmin;
    address public user;

    // Role constants
    bytes32 constant OWNER_ROLE = keccak256("OWNER");
    bytes32 constant GUARDIAN_ROLE = keccak256("GUARDIAN");
    bytes32 constant RISK_ADMIN_ROLE = keccak256("RISK_ADMIN");

    function setUp() public {
        owner = address(this);
        guardian = address(0x1);
        riskAdmin = address(0x2);
        user = address(0x3);

        acl = new NexusAccessControl();
    }

    // ============ Initial State Tests ============

    function test_DeployerHasOwnerRole() public view {
        assertTrue(acl.hasRole(OWNER_ROLE, owner));
    }

    function test_ProtocolStartsUnpaused() public view {
        assertFalse(acl.paused());
        assertTrue(acl.isOperational());
    }

    // ============ Role Management Tests ============

    function test_GrantGuardianRole() public {
        acl.grantRole(GUARDIAN_ROLE, guardian);
        assertTrue(acl.hasRole(GUARDIAN_ROLE, guardian));
    }

    function test_RevokeGuardianRole() public {
        acl.grantRole(GUARDIAN_ROLE, guardian);
        acl.revokeRole(GUARDIAN_ROLE, guardian);
        assertFalse(acl.hasRole(GUARDIAN_ROLE, guardian));
    }

    function test_NonOwnerCannotGrantRole() public {
        vm.prank(user);
        vm.expectRevert("AccessControl: missing role");
        acl.grantRole(GUARDIAN_ROLE, user);
    }

    function test_CannotRevokeOwnOwnerRole() public {
        vm.expectRevert("Cannot revoke own OWNER role");
        acl.revokeRole(OWNER_ROLE, owner);
    }

    function test_CannotRenounceOwnerRole() public {
        vm.expectRevert("Cannot renounce OWNER");
        acl.renounceRole(OWNER_ROLE);
    }

    function test_RenounceGuardianRole() public {
        acl.grantRole(GUARDIAN_ROLE, guardian);

        vm.prank(guardian);
        acl.renounceRole(GUARDIAN_ROLE);

        assertFalse(acl.hasRole(GUARDIAN_ROLE, guardian));
    }

    // ============ Pause Tests ============

    function test_OwnerCanPause() public {
        acl.pause();
        assertTrue(acl.paused());
        assertFalse(acl.isOperational());
    }

    function test_GuardianCanPause() public {
        acl.grantRole(GUARDIAN_ROLE, guardian);

        vm.prank(guardian);
        acl.pause();

        assertTrue(acl.paused());
    }

    function test_UserCannotPause() public {
        vm.prank(user);
        vm.expectRevert("Not authorized to pause");
        acl.pause();
    }

    function test_OnlyOwnerCanUnpause() public {
        acl.grantRole(GUARDIAN_ROLE, guardian);

        // Guardian pauses
        vm.prank(guardian);
        acl.pause();

        // Guardian cannot unpause
        vm.prank(guardian);
        vm.expectRevert("AccessControl: missing role");
        acl.unpause();

        // Owner can unpause
        acl.unpause();
        assertFalse(acl.paused());
    }

    // ============ Asset Freeze Tests ============

    function test_FreezeAsset() public {
        address asset = address(0x100);

        acl.freezeAsset(asset);
        assertTrue(acl.frozenAssets(asset));
        assertFalse(acl.isAssetOperational(asset));
    }

    function test_UnfreezeAsset() public {
        address asset = address(0x100);

        acl.freezeAsset(asset);
        acl.unfreezeAsset(asset);

        assertFalse(acl.frozenAssets(asset));
        assertTrue(acl.isAssetOperational(asset));
    }

    function test_GuardianCanFreezeButNotUnfreeze() public {
        address asset = address(0x100);
        acl.grantRole(GUARDIAN_ROLE, guardian);

        // Guardian freezes
        vm.prank(guardian);
        acl.freezeAsset(asset);
        assertTrue(acl.frozenAssets(asset));

        // Guardian cannot unfreeze
        vm.prank(guardian);
        vm.expectRevert("AccessControl: missing role");
        acl.unfreezeAsset(asset);
    }
}
