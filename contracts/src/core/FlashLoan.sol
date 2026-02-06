// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/Interfaces.sol";

/**
 * @title IFlashLoanReceiver
 * @notice Interface that flash loan receivers must implement
 */
interface IFlashLoanReceiver {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

/**
 * @title IFlashLoanMultiReceiver
 * @notice Multi-asset flash loan receiver interface
 */
interface IFlashLoanMultiReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

/**
 * @title FlashLoan
 * @notice Enables uncollateralized instant loans
 * 
 * WHAT IS A FLASH LOAN?
 * ─────────────────────
 * Borrow ANY amount with ZERO collateral!
 * BUT: Must repay in the SAME transaction.
 * 
 * HOW IT WORKS:
 * ┌────────────────────────────────────────────────────────┐
 * │  1. User requests 1,000,000 DAI                       │
 * │  2. FlashLoan sends 1,000,000 DAI to user contract    │
 * │  3. User contract does whatever (arbitrage, etc)      │
 * │  4. User contract repays 1,000,000 + fee to FlashLoan │
 * │  5. All in ONE transaction!                           │
 * │                                                        │
 * │  If step 4 fails → ENTIRE transaction reverts         │
 * │  User never actually "had" the money                  │
 * └────────────────────────────────────────────────────────┘
 * 
 * USE CASES:
 * - Arbitrage between DEXes
 * - Collateral swaps
 * - Self-liquidation
 * - Debt refinancing
 */
contract FlashLoan {
    
    // ============ Constants ============
    
    /// @notice Flash loan fee (0.09% like Aave)
    uint256 public constant FLASH_LOAN_FEE = 9;
    
    /// @notice Basis points denominator
    uint256 public constant BASIS_POINTS = 10000;
    
    // ============ State Variables ============
    
    /// @notice Main lending pool
    address public pool;
    
    /// @notice Owner
    address public owner;
    
    /// @notice Flash loan enabled status per asset
    mapping(address => bool) public flashLoanEnabled;
    
    /// @notice Accumulated fees per asset
    mapping(address => uint256) public accumulatedFees;
    
    // ============ Events ============
    
    event FlashLoanExecuted(
        address indexed receiver,
        address indexed asset,
        uint256 amount,
        uint256 fee
    );
    event FlashLoanAssetEnabled(address indexed asset, bool enabled);
    event FeesWithdrawn(address indexed asset, uint256 amount, address indexed to);
    
    // ============ Errors ============
    
    error FlashLoanNotEnabled();
    error InsufficientLiquidity();
    error RepaymentFailed();
    error InvalidReceiver();
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "FlashLoan: not owner");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _pool) {
        pool = _pool;
        owner = msg.sender;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Execute a flash loan
     * @param receiver Contract that receives and repays the loan
     * @param asset Asset to borrow
     * @param amount Amount to borrow
     * @param params Custom parameters for receiver
     */
    function flashLoan(
        address receiver,
        address asset,
        uint256 amount,
        bytes calldata params
    ) external {
        if (!flashLoanEnabled[asset]) {
            revert FlashLoanNotEnabled();
        }
        
        if (receiver == address(0)) {
            revert InvalidReceiver();
        }
        
        uint256 poolBalance = IERC20(asset).balanceOf(pool);
        if (poolBalance < amount) {
            revert InsufficientLiquidity();
        }
        
        uint256 fee = (amount * FLASH_LOAN_FEE) / BASIS_POINTS;
        
        IERC20(asset).transferFrom(pool, receiver, amount);
        
        bool success = IFlashLoanReceiver(receiver).executeOperation(
            asset,
            amount,
            fee,
            msg.sender,
            params
        );
        
        if (!success) {
            revert RepaymentFailed();
        }
        
        uint256 newBalance = IERC20(asset).balanceOf(pool);
        uint256 expectedBalance = poolBalance + fee;
        
        if (newBalance < expectedBalance) {
            revert RepaymentFailed();
        }
        
        accumulatedFees[asset] += fee;
        
        emit FlashLoanExecuted(receiver, asset, amount, fee);
    }
    
    /**
     * @notice Flash loan multiple assets at once
     */
    function flashLoanMultiple(
        address receiver,
        address[] calldata assets,
        uint256[] calldata amounts,
        bytes calldata params
    ) external {
        require(assets.length == amounts.length, "Length mismatch");
        
        uint256[] memory fees = new uint256[](assets.length);
        uint256[] memory balancesBefore = new uint256[](assets.length);
        
        for (uint256 i = 0; i < assets.length; i++) {
            if (!flashLoanEnabled[assets[i]]) {
                revert FlashLoanNotEnabled();
            }
            
            balancesBefore[i] = IERC20(assets[i]).balanceOf(pool);
            fees[i] = (amounts[i] * FLASH_LOAN_FEE) / BASIS_POINTS;
            
            IERC20(assets[i]).transferFrom(pool, receiver, amounts[i]);
        }
        
        bool success = IFlashLoanMultiReceiver(receiver).executeOperation(
            assets,
            amounts,
            fees,
            msg.sender,
            params
        );
        
        if (!success) {
            revert RepaymentFailed();
        }
        
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 newBalance = IERC20(assets[i]).balanceOf(pool);
            if (newBalance < balancesBefore[i] + fees[i]) {
                revert RepaymentFailed();
            }
            accumulatedFees[assets[i]] += fees[i];
            
            emit FlashLoanExecuted(receiver, assets[i], amounts[i], fees[i]);
        }
    }
    
    // ============ Admin Functions ============
    
    function setFlashLoanEnabled(address asset, bool enabled) external onlyOwner {
        flashLoanEnabled[asset] = enabled;
        emit FlashLoanAssetEnabled(asset, enabled);
    }
    
    function withdrawFees(address asset, address to) external onlyOwner {
        uint256 fees = accumulatedFees[asset];
        require(fees > 0, "No fees");
        
        accumulatedFees[asset] = 0;
        IERC20(asset).transferFrom(pool, to, fees);
        
        emit FeesWithdrawn(asset, fees, to);
    }
    
    // ============ View Functions ============
    
    function calculateFee(uint256 amount) external pure returns (uint256) {
        return (amount * FLASH_LOAN_FEE) / BASIS_POINTS;
    }
    
    function maxFlashLoan(address asset) external view returns (uint256) {
        if (!flashLoanEnabled[asset]) return 0;
        return IERC20(asset).balanceOf(pool);
    }
}
