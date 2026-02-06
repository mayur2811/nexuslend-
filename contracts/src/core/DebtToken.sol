// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title DebtToken
 * @notice Tracks user borrows as an ERC20 token
 *
 * WHY A SEPARATE DEBT TOKEN?
 * - Borrows are also "balances" that grow with interest
 * - Makes it easy to track who owes what
 * - Enables composability (debt can be traded/transferred)
 *
 * HOW IT WORKS:
 * - When you borrow 100 DAI, you get 100 debtDAI
 * - Your debtDAI balance GROWS as interest accrues
 * - When you repay, debtDAI is burned
 *
 * IMPORTANT: This token is NON-TRANSFERABLE!
 * You can't give your debt to someone else.
 */
contract DebtToken is ERC20 {
    // ============ State Variables ============

    /// @notice The underlying asset this debt represents
    address public immutable underlyingAsset;

    /// @notice The lending pool
    address public pool;

    /// @notice Tracks borrow index per user (for interest calculation)
    mapping(address => uint256) public userBorrowIndex;

    /// @notice Current borrow index (grows with interest)
    uint256 public borrowIndex;

    /// @notice Ray constant
    uint256 private constant RAY = 1e27;

    // ============ Events ============

    event Mint(address indexed user, uint256 amount, uint256 index);
    event Burn(address indexed user, uint256 amount, uint256 index);

    // ============ Modifiers ============

    modifier onlyPool() {
        require(msg.sender == pool, "DebtToken: only pool");
        _;
    }

    // ============ Constructor ============

    constructor(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        underlyingAsset = _underlyingAsset;
        pool = msg.sender;
        borrowIndex = RAY; // Start at 1.0
    }

    // ============ Core Functions ============

    /**
     * @notice Mint debt tokens when user borrows
     * @param user Borrower address
     * @param amount Amount borrowed
     * @param index Current borrow index
     *
     * EXAMPLE:
     * - User borrows 100 DAI
     * - Current index = 1.05 (5% interest accrued globally)
     * - User's debt = 100 (principal)
     * - Actual balance = 100 * 1.05 = 105 (with interest)
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external onlyPool {
        // Update user's index first
        userBorrowIndex[user] = index;
        borrowIndex = index;

        // Mint scaled amount (principal)
        uint256 scaledAmount = (amount * RAY) / index;
        _mint(user, scaledAmount);

        emit Mint(user, amount, index);
    }

    /**
     * @notice Burn debt tokens when user repays
     * @param user Borrower address
     * @param amount Amount being repaid
     * @param index Current borrow index
     */
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external onlyPool {
        borrowIndex = index;

        // Burn scaled amount
        uint256 scaledAmount = (amount * RAY) / index;
        _burn(user, scaledAmount);

        emit Burn(user, amount, index);
    }

    // ============ View Functions ============

    /**
     * @notice Get user's actual debt balance (with interest)
     * @param user Address to check
     * @return Actual debt amount
     *
     * EXAMPLE:
     * - User has 100 scaled debt tokens
     * - Current index = 1.10 (10% interest accrued)
     * - Actual debt = 100 * 1.10 = 110
     */
    function balanceOf(address user) public view override returns (uint256) {
        uint256 scaledBalance = super.balanceOf(user);
        if (scaledBalance == 0) return 0;

        // Actual = scaled * currentIndex / userIndex
        return (scaledBalance * borrowIndex) / RAY;
    }

    /**
     * @notice Get scaled (principal) balance
     * @param user Address to check
     * @return Scaled balance without interest
     */
    function scaledBalanceOf(address user) external view returns (uint256) {
        return super.balanceOf(user);
    }

    /**
     * @notice Total debt (with interest)
     */
    function totalSupply() public view override returns (uint256) {
        uint256 scaledSupply = super.totalSupply();
        return (scaledSupply * borrowIndex) / RAY;
    }

    /**
     * @notice Update the borrow index
     * @param newIndex New index value
     */
    function updateBorrowIndex(uint256 newIndex) external onlyPool {
        require(newIndex >= borrowIndex, "Index can only increase");
        borrowIndex = newIndex;
    }

    // ============ Transfer Restrictions ============

    /**
     * @notice DISABLED - Debt cannot be transferred!
     */
    function transfer(address, uint256) public pure override returns (bool) {
        revert("DebtToken: transfer not allowed");
    }

    /**
     * @notice DISABLED - Debt cannot be transferred!
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("DebtToken: transferFrom not allowed");
    }

    /**
     * @notice DISABLED - No approvals for debt
     */
    function approve(address, uint256) public pure override returns (bool) {
        revert("DebtToken: approve not allowed");
    }
}
