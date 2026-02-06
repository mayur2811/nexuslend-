// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title NToken
 * @notice Interest-bearing token representing deposits in NexusLend
 *
 * WHAT IS THIS?
 * When you deposit DAI into NexusLend, you get nDAI back.
 * nDAI is your "receipt" proving you deposited.
 *
 * HOW INTEREST WORKS:
 * We track an "exchangeRate" that grows over time.
 * - Day 1: 1 nDAI = 1.00 DAI (exchangeRate = 1.0)
 * - Day 30: 1 nDAI = 1.01 DAI (exchangeRate = 1.01)
 * - Day 365: 1 nDAI = 1.10 DAI (exchangeRate = 1.10)
 *
 * Your nDAI balance stays the same, but its VALUE increases!
 */
contract NToken is ERC20 {
    // ============ State Variables ============

    /// @notice The underlying asset this nToken represents (e.g., DAI)
    IERC20 public immutable underlyingAsset;

    /// @notice The main lending pool contract
    address public pool;

    /// @notice Exchange rate: how much underlying 1 nToken is worth
    /// Stored in ray format (1e27 = 1.0)
    uint256 public exchangeRate;

    /// @notice Ray constant for precision
    uint256 private constant RAY = 1e27;

    // ============ Events ============

    event Mint(
        address indexed user,
        uint256 underlyingAmount,
        uint256 nTokenAmount
    );
    event Burn(
        address indexed user,
        uint256 underlyingAmount,
        uint256 nTokenAmount
    );
    event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);

    // ============ Modifiers ============

    /// @notice Only the pool can call these functions
    modifier onlyPool() {
        require(msg.sender == pool, "NToken: caller is not the pool");
        _;
    }

    // ============ Constructor ============

    /**
     * @param _underlyingAsset The token this nToken wraps (e.g., DAI address)
     * @param _name Token name (e.g., "NexusLend DAI")
     * @param _symbol Token symbol (e.g., "nDAI")
     *
     * Example: For DAI deposits, we create an nDAI token
     */
    constructor(
        address _underlyingAsset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        underlyingAsset = IERC20(_underlyingAsset);
        pool = msg.sender; // The deployer (NexusPool) becomes the pool
        exchangeRate = RAY; // Start at 1:1 ratio
    }

    // ============ Core Functions ============

    /**
     * @notice Mint nTokens when user deposits
     * @param user Address receiving the nTokens
     * @param underlyingAmount Amount of underlying asset deposited
     * @return nTokenAmount Amount of nTokens minted
     *
     * EXAMPLE:
     * - User deposits 100 DAI
     * - Current exchangeRate = 1.05 (1 nDAI = 1.05 DAI)
     * - nTokens minted = 100 / 1.05 = 95.24 nDAI
     * - User gets 95.24 nDAI (worth 100 DAI)
     */
    function mint(
        address user,
        uint256 underlyingAmount
    ) external onlyPool returns (uint256 nTokenAmount) {
        // Calculate how many nTokens to mint
        // Formula: nTokens = underlyingAmount / exchangeRate
        nTokenAmount = (underlyingAmount * RAY) / exchangeRate;

        // Mint the nTokens to user
        _mint(user, nTokenAmount);

        emit Mint(user, underlyingAmount, nTokenAmount);
    }

    /**
     * @notice Burn nTokens when user withdraws
     * @param user Address whose nTokens are being burned
     * @param nTokenAmount Amount of nTokens to burn
     * @return underlyingAmount Amount of underlying asset to return
     *
     * EXAMPLE:
     * - User has 95.24 nDAI
     * - Current exchangeRate = 1.10 (1 nDAI = 1.10 DAI)
     * - Underlying to return = 95.24 * 1.10 = 104.76 DAI
     * - User withdraws 104.76 DAI (their original 100 + interest!)
     */
    function burn(
        address user,
        uint256 nTokenAmount
    ) external onlyPool returns (uint256 underlyingAmount) {
        // Calculate how much underlying to return
        // Formula: underlyingAmount = nTokens * exchangeRate
        underlyingAmount = (nTokenAmount * exchangeRate) / RAY;

        // Burn the nTokens from user
        _burn(user, nTokenAmount);

        emit Burn(user, underlyingAmount, nTokenAmount);
    }

    /**
     * @notice Update exchange rate (called by pool when interest accrues)
     * @param newRate The new exchange rate in ray
     *
     * This is called when borrowers pay interest:
     * - Interest goes into the pool
     * - Exchange rate increases
     * - Everyone's nTokens are now worth more!
     */
    function updateExchangeRate(uint256 newRate) external onlyPool {
        require(newRate >= exchangeRate, "NToken: rate can only increase");

        uint256 oldRate = exchangeRate;
        exchangeRate = newRate;

        emit ExchangeRateUpdated(oldRate, newRate);
    }

    // ============ View Functions ============

    /**
     * @notice Get underlying value of user's nToken balance
     * @param user Address to check
     * @return Value in underlying asset
     *
     * EXAMPLE:
     * - User has 100 nDAI
     * - Exchange rate = 1.10
     * - Underlying balance = 100 * 1.10 = 110 DAI
     */
    function balanceOfUnderlying(address user) external view returns (uint256) {
        return (balanceOf(user) * exchangeRate) / RAY;
    }

    /**
     * @notice Convert underlying amount to nToken amount
     * @param underlyingAmount Amount in underlying asset
     * @return Amount in nTokens
     */
    function underlyingToNToken(
        uint256 underlyingAmount
    ) external view returns (uint256) {
        return (underlyingAmount * RAY) / exchangeRate;
    }

    /**
     * @notice Convert nToken amount to underlying amount
     * @param nTokenAmount Amount in nTokens
     * @return Amount in underlying asset
     */
    function nTokenToUnderlying(
        uint256 nTokenAmount
    ) external view returns (uint256) {
        return (nTokenAmount * exchangeRate) / RAY;
    }
}
