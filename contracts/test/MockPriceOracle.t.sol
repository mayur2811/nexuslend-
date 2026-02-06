// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/MockPriceOracle.sol";

/**
 * @title MockPriceOracleTest
 * @notice Tests for the price oracle
 */
contract MockPriceOracleTest is Test {
    MockPriceOracle public oracle;

    address constant WETH = address(0x1);
    address constant DAI = address(0x2);
    address constant USDC = address(0x3);

    function setUp() public {
        oracle = new MockPriceOracle();
    }

    // ============ Basic Tests ============

    function test_SetPrice() public {
        oracle.setPrice(WETH, 3000e18);
        assertEq(oracle.getPrice(WETH), 3000e18);
    }

    function test_SetMultiplePrices() public {
        oracle.setPrice(WETH, 3000e18);
        oracle.setPrice(DAI, 1e18);
        oracle.setPrice(USDC, 1e18);

        assertEq(oracle.getPrice(WETH), 3000e18);
        assertEq(oracle.getPrice(DAI), 1e18);
        assertEq(oracle.getPrice(USDC), 1e18);
    }

    function test_UpdatePrice() public {
        oracle.setPrice(WETH, 3000e18);
        oracle.setPrice(WETH, 3500e18);

        assertEq(oracle.getPrice(WETH), 3500e18);
    }

    function test_BatchSetPrices() public {
        address[] memory assets = new address[](3);
        assets[0] = WETH;
        assets[1] = DAI;
        assets[2] = USDC;

        uint256[] memory prices = new uint256[](3);
        prices[0] = 3000e18;
        prices[1] = 1e18;
        prices[2] = 1e18;

        oracle.batchSetPrices(assets, prices);

        assertEq(oracle.getPrice(WETH), 3000e18);
        assertEq(oracle.getPrice(DAI), 1e18);
        assertEq(oracle.getPrice(USDC), 1e18);
    }

    // ============ Access Control Tests ============

    function test_OnlyOwnerCanSetPrice() public {
        address notOwner = address(0x999);

        vm.prank(notOwner);
        vm.expectRevert("MockPriceOracle: not owner");
        oracle.setPrice(WETH, 3000e18);
    }

    // ============ Error Cases ============

    function test_RevertOnUnsetPrice() public {
        vm.expectRevert("MockPriceOracle: price not set");
        oracle.getPrice(WETH);
    }
}
