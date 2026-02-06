// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";
import {MockPriceOracle} from "../src/core/MockPriceOracle.sol";
import {NexusPool} from "../src/core/NexusPool.sol";

/**
 * @title DeployTestTokens
 * @notice Deploys mock tokens and sets up NexusPool for testing
 *
 * TOKENS WE'LL CREATE:
 * - MockWETH (Wrapped ETH) - Price: $3000
 * - MockUSDC (USD Coin) - Price: $1
 * - MockDAI (DAI Stablecoin) - Price: $1
 *
 * AFTER THIS:
 * - You can mint tokens to your wallet
 * - Supply them to NexusPool
 * - Borrow against collateral
 */
contract DeployTestTokens is Script {
    // Deployed NexusLend addresses (from previous deployment)
    address constant NEXUS_POOL = 0x108D8f153FCD367293ea61dbDC8Eb2Fa204F2276;
    address constant PRICE_ORACLE = 0x0E6bB20362f5f382534528A02Aa9cE9B69C4FF86;

    // Mock tokens
    MockERC20 public mockWETH;
    MockERC20 public mockUSDC;
    MockERC20 public mockDAI;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Test Tokens...");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ============ Deploy Mock Tokens ============

        console.log("1. Deploying MockWETH...");
        mockWETH = new MockERC20("Mock Wrapped ETH", "mWETH", 18);
        console.log("   MockWETH:", address(mockWETH));

        console.log("2. Deploying MockUSDC...");
        mockUSDC = new MockERC20("Mock USD Coin", "mUSDC", 6); // USDC has 6 decimals
        console.log("   MockUSDC:", address(mockUSDC));

        console.log("3. Deploying MockDAI...");
        mockDAI = new MockERC20("Mock DAI", "mDAI", 18);
        console.log("   MockDAI:", address(mockDAI));

        // ============ Set Prices in Oracle ============

        console.log("");
        console.log("4. Setting prices in MockPriceOracle...");
        MockPriceOracle oracle = MockPriceOracle(PRICE_ORACLE);

        oracle.setPrice(address(mockWETH), 3000e18); // $3000
        oracle.setPrice(address(mockUSDC), 1e18); // $1
        oracle.setPrice(address(mockDAI), 1e18); // $1

        console.log("   WETH: $3000");
        console.log("   USDC: $1");
        console.log("   DAI: $1");

        // ============ Mint Test Tokens to Deployer ============

        console.log("");
        console.log("5. Minting test tokens to deployer...");

        mockWETH.mint(deployer, 100e18); // 100 WETH ($300,000)
        mockUSDC.mint(deployer, 100000e6); // 100,000 USDC
        mockDAI.mint(deployer, 100000e18); // 100,000 DAI

        console.log("   100 WETH minted");
        console.log("   100,000 USDC minted");
        console.log("   100,000 DAI minted");

        vm.stopBroadcast();

        // ============ Summary ============
        console.log("");
        console.log("========================================");
        console.log("Test Tokens Deployed!");
        console.log("========================================");
        console.log("");
        console.log("Token Addresses:");
        console.log("-----------------");
        console.log("MockWETH:", address(mockWETH));
        console.log("MockUSDC:", address(mockUSDC));
        console.log("MockDAI:", address(mockDAI));
        console.log("");
        console.log("Your balances:");
        console.log("-----------------");
        console.log("WETH: 100 ($300,000)");
        console.log("USDC: 100,000");
        console.log("DAI: 100,000");
        console.log("");
    }
}
