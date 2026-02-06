// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/InterestRateModel.sol";
import "../src/core/MockPriceOracle.sol";
import "../src/core/NexusPool.sol";
import "../src/core/LiquidationEngine.sol";
import "../src/core/NexusAccessControl.sol";
import "../src/core/FlashLoan.sol";
import "../src/core/PoolDataProvider.sol";

/**
 * @title DeployNexusLend
 * @notice Deploys all NexusLend contracts to the network
 *
 * DEPLOYMENT ORDER MATTERS!
 * 1. InterestRateModel (no dependencies)
 * 2. MockPriceOracle (no dependencies)
 * 3. NexusAccessControl (no dependencies)
 * 4. NexusPool (needs oracle, interest model)
 * 5. LiquidationEngine (needs pool, oracle)
 * 6. FlashLoan (needs pool)
 * 7. PoolDataProvider (needs pool, oracle)
 */
contract DeployNexusLend is Script {
    // Deployed contract addresses
    InterestRateModel public interestRateModel;
    MockPriceOracle public priceOracle;
    NexusAccessControl public accessControl;
    NexusPool public nexusPool;
    LiquidationEngine public liquidationEngine;
    FlashLoan public flashLoan;
    PoolDataProvider public poolDataProvider;

    // Interest rate parameters (like Aave)
    uint256 constant BASE_RATE = 2e25; // 2%
    uint256 constant SLOPE1 = 10e25; // 10%
    uint256 constant SLOPE2 = 100e25; // 100%
    uint256 constant OPTIMAL = 80e25; // 80%

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying NexusLend Contracts...");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ============ Step 1: Deploy InterestRateModel ============
        console.log("1. Deploying InterestRateModel...");
        interestRateModel = new InterestRateModel(
            BASE_RATE,
            SLOPE1,
            SLOPE2,
            OPTIMAL
        );
        console.log("   InterestRateModel:", address(interestRateModel));

        // ============ Step 2: Deploy MockPriceOracle ============
        console.log("2. Deploying MockPriceOracle...");
        priceOracle = new MockPriceOracle();
        console.log("   MockPriceOracle:", address(priceOracle));

        // ============ Step 3: Deploy NexusAccessControl ============
        console.log("3. Deploying NexusAccessControl...");
        accessControl = new NexusAccessControl();
        console.log("   NexusAccessControl:", address(accessControl));

        // ============ Step 4: Deploy NexusPool ============
        console.log("4. Deploying NexusPool...");
        nexusPool = new NexusPool(
            address(priceOracle),
            address(interestRateModel)
        );
        console.log("   NexusPool:", address(nexusPool));

        // ============ Step 5: Deploy LiquidationEngine ============
        console.log("5. Deploying LiquidationEngine...");
        liquidationEngine = new LiquidationEngine(
            address(nexusPool),
            address(priceOracle)
        );
        console.log("   LiquidationEngine:", address(liquidationEngine));

        // ============ Step 6: Deploy FlashLoan ============
        console.log("6. Deploying FlashLoan...");
        flashLoan = new FlashLoan(address(nexusPool));
        console.log("   FlashLoan:", address(flashLoan));

        // ============ Step 7: Deploy PoolDataProvider ============
        console.log("7. Deploying PoolDataProvider...");
        poolDataProvider = new PoolDataProvider(
            address(nexusPool),
            address(priceOracle)
        );
        console.log("   PoolDataProvider:", address(poolDataProvider));

        vm.stopBroadcast();

        // ============ Summary ============
        console.log("");
        console.log("========================================");
        console.log("NexusLend Deployment Complete!");
        console.log("========================================");
        console.log("");
        console.log("Contract Addresses:");
        console.log("-------------------");
        console.log("InterestRateModel:", address(interestRateModel));
        console.log("MockPriceOracle:", address(priceOracle));
        console.log("NexusAccessControl:", address(accessControl));
        console.log("NexusPool:", address(nexusPool));
        console.log("LiquidationEngine:", address(liquidationEngine));
        console.log("FlashLoan:", address(flashLoan));
        console.log("PoolDataProvider:", address(poolDataProvider));
        console.log("");
    }
}
