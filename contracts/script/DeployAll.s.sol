// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/core/InterestRateModel.sol";
import "../src/core/MockPriceOracle.sol";
import "../src/core/NexusPool.sol";

// Simple NToken for testing
contract NToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public pool;
    
    constructor(string memory _name, string memory _symbol, address _pool) {
        name = _name;
        symbol = _symbol;
        pool = _pool;
    }
    
    modifier onlyPool() {
        require(msg.sender == pool, "Only pool");
        _;
    }
    
    function mint(address to, uint256 amount) external onlyPool returns (uint256) {
        balanceOf[to] += amount;
        totalSupply += amount;
        return amount;
    }
    
    function burn(address from, uint256 amount) external onlyPool returns (uint256) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        return amount;
    }
    
    function balanceOfUnderlying(address user) external view returns (uint256) {
        return balanceOf[user];
    }
}

// Simple ERC20 for testing (avoiding import conflict)
contract TestToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract DeployAll is Script {
    // Constants for asset configuration
    uint256 constant RAY = 1e27;
    
    // LTV and Liquidation params (in RAY)
    uint256 constant WETH_LTV = 75e25; // 75%
    uint256 constant WETH_LIQ_THRESHOLD = 80e25; // 80%
    uint256 constant STABLE_LTV = 80e25; // 80%
    uint256 constant STABLE_LIQ_THRESHOLD = 85e25; // 85%
    uint256 constant LIQ_BONUS = 5e25; // 5%
    uint256 constant RESERVE_FACTOR = 10e25; // 10%

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Deploying NexusLend ===");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Interest Rate Model
        InterestRateModel interestRateModel = new InterestRateModel(
            2e25,  // baseRate: 2%
            8e25,  // multiplier: 8%
            100e25, // jumpMultiplier: 100%
            80e25  // optimalUtilization: 80%
        );
        console.log("InterestRateModel:", address(interestRateModel));

        // 2. Deploy Price Oracle
        MockPriceOracle priceOracle = new MockPriceOracle();
        console.log("MockPriceOracle:", address(priceOracle));

        // 3. Deploy NexusPool
        NexusPool nexusPool = new NexusPool(
            address(priceOracle),
            address(interestRateModel)
        );
        console.log("NexusPool:", address(nexusPool));

        // 4. Deploy Test Tokens
        TestToken mWETH = new TestToken("Mock WETH", "mWETH", 18);
        TestToken mUSDC = new TestToken("Mock USDC", "mUSDC", 6);
        TestToken mDAI = new TestToken("Mock DAI", "mDAI", 18);
        console.log("mWETH:", address(mWETH));
        console.log("mUSDC:", address(mUSDC));
        console.log("mDAI:", address(mDAI));

        // 5. Deploy NTokens (with pool address)
        NToken nWETH = new NToken("NexusLend WETH", "nWETH", address(nexusPool));
        NToken nUSDC = new NToken("NexusLend USDC", "nUSDC", address(nexusPool));
        NToken nDAI = new NToken("NexusLend DAI", "nDAI", address(nexusPool));
        console.log("nWETH:", address(nWETH));
        console.log("nUSDC:", address(nUSDC));
        console.log("nDAI:", address(nDAI));

        // 6. Set prices in oracle
        priceOracle.setPrice(address(mWETH), 3000e18); // $3000
        priceOracle.setPrice(address(mUSDC), 1e18);    // $1
        priceOracle.setPrice(address(mDAI), 1e18);     // $1
        console.log("Prices set in oracle");

        // 7. Add assets to NexusPool
        nexusPool.addAsset(
            address(mWETH),
            address(nWETH),
            WETH_LTV,
            WETH_LIQ_THRESHOLD,
            LIQ_BONUS,
            RESERVE_FACTOR
        );
        
        nexusPool.addAsset(
            address(mUSDC),
            address(nUSDC),
            STABLE_LTV,
            STABLE_LIQ_THRESHOLD,
            LIQ_BONUS,
            RESERVE_FACTOR
        );
        
        nexusPool.addAsset(
            address(mDAI),
            address(nDAI),
            STABLE_LTV,
            STABLE_LIQ_THRESHOLD,
            LIQ_BONUS,
            RESERVE_FACTOR
        );
        console.log("Assets added to NexusPool");

        // 8. Mint test tokens to deployer
        mWETH.mint(deployer, 100 ether);
        mUSDC.mint(deployer, 100_000e6);
        mDAI.mint(deployer, 100_000 ether);
        console.log("Test tokens minted to deployer");

        vm.stopBroadcast();

        // Print summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("InterestRateModel:", address(interestRateModel));
        console.log("MockPriceOracle:", address(priceOracle));
        console.log("NexusPool:", address(nexusPool));
        console.log("---");
        console.log("mWETH:", address(mWETH));
        console.log("mUSDC:", address(mUSDC));
        console.log("mDAI:", address(mDAI));
        console.log("---");
        console.log("nWETH:", address(nWETH));
        console.log("nUSDC:", address(nUSDC));
        console.log("nDAI:", address(nDAI));
    }
}
