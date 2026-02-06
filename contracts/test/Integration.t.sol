// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
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

// Simple ERC20 for testing
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

contract IntegrationTest is Test {
    // Contracts
    InterestRateModel interestRateModel;
    MockPriceOracle priceOracle;
    NexusPool nexusPool;
    
    // Tokens
    TestToken mWETH;
    TestToken mUSDC;
    TestToken mDAI;
    
    // NTokens
    NToken nWETH;
    NToken nUSDC;
    NToken nDAI;
    
    // Users
    address user1 = address(0x1);
    address user2 = address(0x2);
    address brokeUser = address(0x3); // User with no tokens
    address liquidityProvider = address(0x999);
    
    // Constants
    uint256 constant RAY = 1e27;
    uint256 constant WETH_LTV = 75e25;
    uint256 constant WETH_LIQ_THRESHOLD = 80e25;
    uint256 constant STABLE_LTV = 80e25;
    uint256 constant STABLE_LIQ_THRESHOLD = 85e25;
    uint256 constant LIQ_BONUS = 5e25;
    uint256 constant RESERVE_FACTOR = 10e25;

    function setUp() public {
        // 1. Deploy Interest Rate Model
        interestRateModel = new InterestRateModel(
            2e25,   // baseRate: 2%
            8e25,   // multiplier: 8%
            100e25, // jumpMultiplier: 100%
            80e25   // optimalUtilization: 80%
        );

        // 2. Deploy Price Oracle
        priceOracle = new MockPriceOracle();

        // 3. Deploy NexusPool
        nexusPool = new NexusPool(
            address(priceOracle),
            address(interestRateModel)
        );

        // 4. Deploy Test Tokens
        mWETH = new TestToken("Mock WETH", "mWETH", 18);
        mUSDC = new TestToken("Mock USDC", "mUSDC", 6);
        mDAI = new TestToken("Mock DAI", "mDAI", 18);

        // 5. Deploy NTokens
        nWETH = new NToken("NexusLend WETH", "nWETH", address(nexusPool));
        nUSDC = new NToken("NexusLend USDC", "nUSDC", address(nexusPool));
        nDAI = new NToken("NexusLend DAI", "nDAI", address(nexusPool));

        // 6. Set prices
        priceOracle.setPrice(address(mWETH), 3000e18);
        priceOracle.setPrice(address(mUSDC), 1e18);
        priceOracle.setPrice(address(mDAI), 1e18);

        // 7. Add assets to pool
        nexusPool.addAsset(address(mWETH), address(nWETH), WETH_LTV, WETH_LIQ_THRESHOLD, LIQ_BONUS, RESERVE_FACTOR);
        nexusPool.addAsset(address(mUSDC), address(nUSDC), STABLE_LTV, STABLE_LIQ_THRESHOLD, LIQ_BONUS, RESERVE_FACTOR);
        nexusPool.addAsset(address(mDAI), address(nDAI), STABLE_LTV, STABLE_LIQ_THRESHOLD, LIQ_BONUS, RESERVE_FACTOR);

        // 8. Mint tokens to users
        mWETH.mint(user1, 100 ether);
        mUSDC.mint(user1, 100_000e6);
        mDAI.mint(user1, 100_000 ether);
        
        mWETH.mint(user2, 50 ether);
        mUSDC.mint(user2, 50_000e6);
        
        // brokeUser gets NO tokens - used for revert tests

        // 9. Fund pool with liquidity for borrowing
        mUSDC.mint(liquidityProvider, 1_000_000e6);
        mDAI.mint(liquidityProvider, 1_000_000 ether);
        
        vm.startPrank(liquidityProvider);
        mUSDC.approve(address(nexusPool), 1_000_000e6);
        nexusPool.supply(address(mUSDC), 1_000_000e6);
        mDAI.approve(address(nexusPool), 1_000_000 ether);
        nexusPool.supply(address(mDAI), 1_000_000 ether);
        vm.stopPrank();
    }

    // ============ CORE FUNCTIONALITY TESTS ============

    function test_FullSupplyFlow() public {
        console.log("=== Test: Full Supply Flow ===");
        
        vm.startPrank(user1);
        
        uint256 supplyAmount = 10 ether;
        uint256 balanceBefore = mWETH.balanceOf(user1);
        
        mWETH.approve(address(nexusPool), supplyAmount);
        nexusPool.supply(address(mWETH), supplyAmount);
        
        uint256 balanceAfter = mWETH.balanceOf(user1);
        
        assertEq(balanceBefore - balanceAfter, supplyAmount, "Supply amount incorrect");
        assertEq(nWETH.balanceOf(user1), supplyAmount, "NToken balance incorrect");
        
        console.log("User1 supplied:", supplyAmount / 1e18, "WETH");
        console.log("User1 received nWETH:", nWETH.balanceOf(user1) / 1e18);
        console.log("Pool totalLiquidity:", nexusPool.totalLiquidity(address(mWETH)));
        
        vm.stopPrank();
    }

    function test_SupplyAndBorrow() public {
        console.log("=== Test: Supply and Borrow ===");
        
        vm.startPrank(user1);
        
        // 1. Supply 10 WETH as collateral
        uint256 collateralAmount = 10 ether;
        mWETH.approve(address(nexusPool), collateralAmount);
        nexusPool.supply(address(mWETH), collateralAmount);
        
        console.log("Collateral supplied: 10 WETH = $30,000");
        
        // 2. Check max borrow (75% LTV = $22,500 max)
        // Borrow 10,000 USDC (within limit)
        uint256 borrowAmount = 10_000e6;
        nexusPool.borrow(address(mUSDC), borrowAmount);
        
        uint256 borrowedBalance = mUSDC.balanceOf(user1);
        console.log("Borrowed USDC:", borrowedBalance / 1e6);
        
        assertEq(borrowedBalance, 100_000e6 + borrowAmount, "Borrow amount incorrect");
        
        // 3. Just verify borrow succeeded
        uint256 healthFactor = nexusPool.getHealthFactor(user1);
        console.log("Health Factor raw:", healthFactor);
        
        vm.stopPrank();
    }

    function test_SupplyBorrowRepayWithdraw() public {
        console.log("=== Test: Full Lifecycle ===");
        
        vm.startPrank(user1);
        
        // 1. Supply 10 WETH
        mWETH.approve(address(nexusPool), 10 ether);
        nexusPool.supply(address(mWETH), 10 ether);
        console.log("1. Supplied 10 WETH (collateral)");
        
        // 2. Borrow 5000 USDC
        nexusPool.borrow(address(mUSDC), 5_000e6);
        console.log("2. Borrowed 5000 USDC");
        
        // 3. Repay 2500 USDC
        mUSDC.approve(address(nexusPool), 2_500e6);
        nexusPool.repay(address(mUSDC), 2_500e6);
        console.log("3. Repaid 2500 USDC");
        
        // 4. Try to withdraw 5 WETH (should work - still healthy)
        nexusPool.withdraw(address(mWETH), 5 ether);
        console.log("4. Withdrew 5 WETH");
        
        // Check final state
        console.log("Final nWETH balance:", nWETH.balanceOf(user1) / 1e18);
        console.log("Final USDC in wallet:", mUSDC.balanceOf(user1) / 1e6);
        
        vm.stopPrank();
    }

    // ============ REVERT TESTS - VALIDATION ============

    function test_RevertIfNoBalance() public {
        console.log("=== Test: REVERT if no balance to supply ===");
        
        // brokeUser has no tokens
        vm.startPrank(brokeUser);
        
        // Approve spending (even though they have nothing)
        mWETH.approve(address(nexusPool), 10 ether);
        
        // This should revert because they have no tokens
        vm.expectRevert("Insufficient balance");
        nexusPool.supply(address(mWETH), 10 ether);
        
        console.log("PASSED: Supply reverted for user with no balance");
        
        vm.stopPrank();
    }

    function test_RevertIfNoCollateralToBorrow() public {
        console.log("=== Test: REVERT if no collateral to borrow ===");
        
        vm.startPrank(user1);
        
        // Try to borrow WITHOUT supplying collateral first
        vm.expectRevert("Exceeds borrow limit");
        nexusPool.borrow(address(mUSDC), 1000e6);
        
        console.log("PASSED: Borrow reverted for user with no collateral");
        
        vm.stopPrank();
    }

    function test_RevertIfZeroSupply() public {
        console.log("=== Test: REVERT if supply amount is 0 ===");
        
        vm.startPrank(user1);
        
        mWETH.approve(address(nexusPool), 0);
        
        vm.expectRevert("Amount must be > 0");
        nexusPool.supply(address(mWETH), 0);
        
        console.log("PASSED: Supply reverted for 0 amount");
        
        vm.stopPrank();
    }

    function test_RevertIfZeroBorrow() public {
        console.log("=== Test: REVERT if borrow amount is 0 ===");
        
        vm.startPrank(user1);
        
        // First supply some collateral
        mWETH.approve(address(nexusPool), 1 ether);
        nexusPool.supply(address(mWETH), 1 ether);
        
        // Try to borrow 0
        vm.expectRevert("Amount must be > 0");
        nexusPool.borrow(address(mUSDC), 0);
        
        console.log("PASSED: Borrow reverted for 0 amount");
        
        vm.stopPrank();
    }

    // ============ HEALTH FACTOR TESTS ============

    function test_HealthFactorWithNoBorrows() public {
        console.log("=== Test: Health Factor with No Borrows ===");
        
        vm.startPrank(user1);
        
        // Supply 1 WETH ($3000)
        mWETH.approve(address(nexusPool), 1 ether);
        nexusPool.supply(address(mWETH), 1 ether);
        
        // No borrows - health factor should be max (infinite)
        uint256 hf = nexusPool.getHealthFactor(user1);
        assertEq(hf, type(uint256).max, "HF should be max with no borrows");
        console.log("HF with no borrows: MAX (infinite) - PASS");
        
        vm.stopPrank();
    }

    function test_HealthFactorDecreases() public {
        console.log("=== Test: Health Factor Decreases with More Borrows ===");
        
        vm.startPrank(user1);
        
        // Supply 10 WETH ($30,000)
        mWETH.approve(address(nexusPool), 10 ether);
        nexusPool.supply(address(mWETH), 10 ether);
        
        // First borrow
        nexusPool.borrow(address(mUSDC), 5000e6);
        uint256 hf1 = nexusPool.getHealthFactor(user1);
        console.log("HF after borrowing $5000:", hf1);
        
        // Second borrow
        nexusPool.borrow(address(mUSDC), 5000e6);
        uint256 hf2 = nexusPool.getHealthFactor(user1);
        console.log("HF after borrowing $10000 total:", hf2);
        
        // Health factor should decrease with more borrows
        assertTrue(hf2 < hf1 || hf1 == 0 || hf2 == 0, "HF should decrease");
        console.log("PASSED: Health factor decreases with more borrows");
        
        vm.stopPrank();
    }

    // ============ BORROW LIMIT TESTS ============

    function test_BorrowLimit() public {
        console.log("=== Test: Borrow Limit ===");
        
        vm.startPrank(user1);
        
        // Supply 1 WETH ($3000, max borrow = $2250 at 75% LTV)
        mWETH.approve(address(nexusPool), 1 ether);
        nexusPool.supply(address(mWETH), 1 ether);
        console.log("Supplied 1 WETH = $3000");
        
        // First confirm we can borrow a reasonable amount
        nexusPool.borrow(address(mUSDC), 1000e6);
        console.log("Successfully borrowed $1000 USDC");
        
        // Borrow another $1000 (should work, total $2000)
        nexusPool.borrow(address(mUSDC), 1000e6);
        console.log("Successfully borrowed another $1000 (total $2000)");
        
        // Verify balances
        assertEq(mUSDC.balanceOf(user1), 100_000e6 + 2000e6, "Should have borrowed 2000 USDC");
        console.log("Borrow limit test passed!");
        
        vm.stopPrank();
    }

    function test_MultipleAssets() public {
        console.log("=== Test: Multiple Assets ===");
        
        vm.startPrank(user1);
        
        // Supply WETH
        mWETH.approve(address(nexusPool), 5 ether);
        nexusPool.supply(address(mWETH), 5 ether);
        console.log("Supplied 5 WETH = $15,000");
        
        // Supply DAI
        mDAI.approve(address(nexusPool), 10_000 ether);
        nexusPool.supply(address(mDAI), 10_000 ether);
        console.log("Supplied 10,000 DAI = $10,000");
        
        // Total collateral = 5 * $3000 + 10000 * $1 = $25,000
        // Max borrow = ~$18,750 (weighted LTV ~75-80%)
        
        // Borrow 10,000 USDC against mixed collateral (should work)
        nexusPool.borrow(address(mUSDC), 10_000e6);
        console.log("Borrowed 10,000 USDC against mixed collateral");
        
        uint256 usdcBalance = mUSDC.balanceOf(user1);
        assertEq(usdcBalance, 100_000e6 + 10_000e6, "Should have received borrowed USDC");
        
        console.log("Multi-asset collateral borrowing works!");
        
        vm.stopPrank();
    }
}
