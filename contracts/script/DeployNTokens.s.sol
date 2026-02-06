// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// Simplified NToken that accepts pool address in constructor
contract SimpleNToken {
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
        balanceOf[from] -= amount;
        totalSupply -= amount;
        return amount;
    }
    
    function balanceOfUnderlying(address user) external view returns (uint256) {
        return balanceOf[user];
    }
}

interface INexusPool {
    function assetConfigs(address) external view returns (
        address nToken,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool isActive,
        bool canBeCollateral,
        bool canBeBorrowed
    );
}

contract DeployNTokens is Script {
    // NexusPool address
    address constant NEXUS_POOL = 0x108D8f153FCD367293ea61dbDC8Eb2Fa204F2276;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy NTokens with pool address
        SimpleNToken nWETH = new SimpleNToken("NexusLend WETH", "nWETH", NEXUS_POOL);
        SimpleNToken nUSDC = new SimpleNToken("NexusLend USDC", "nUSDC", NEXUS_POOL);
        SimpleNToken nDAI = new SimpleNToken("NexusLend DAI", "nDAI", NEXUS_POOL);

        console.log("=== NToken Contracts Deployed ===");
        console.log("nWETH:", address(nWETH));
        console.log("nUSDC:", address(nUSDC));
        console.log("nDAI:", address(nDAI));

        vm.stopBroadcast();
    }
}
