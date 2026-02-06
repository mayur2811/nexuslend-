// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/Interfaces.sol";

/**
 * @title NexusPool
 * @notice The main lending pool contract for NexusLend
 *
 * THIS IS THE HEART OF THE PROTOCOL!
 *
 * WHAT IT DOES:
 * - Accepts deposits (supply)
 * - Issues loans (borrow)
 * - Tracks user positions
 * - Calculates health factors
 * - Triggers liquidations
 *
 * KEY CONCEPTS:
 * - Collateral: Assets you lock to guarantee loans
 * - Health Factor: How safe your position is (>1 = safe)
 * - LTV: Loan-to-Value ratio (max you can borrow per collateral)
 */
contract NexusPool {
    // ============ Constants ============

    uint256 public constant RAY = 1e27; // 100% in ray format
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // ============ Asset Configuration ============
    // Each asset has its own risk parameters

    struct AssetConfig {
        address nToken; // The receipt token for this asset
        uint256 ltv; // Loan-to-Value (e.g., 75% = 0.75e27)
        uint256 liquidationThreshold; // When liquidation can happen (e.g., 80%)
        uint256 liquidationBonus; // Bonus for liquidators (e.g., 5%)
        uint256 reserveFactor; // Protocol's cut (e.g., 10%)
        bool isActive; // Can this asset be used?
        bool canBeCollateral; // Can this be used as collateral?
        bool canBeBorrowed; // Can this be borrowed?
    }

    // ============ User Position ============
    // Tracks each user's deposits and borrows

    struct UserPosition {
        uint256 deposited; // Amount deposited (in underlying)
        uint256 borrowed; // Principal borrowed (in underlying)
        uint256 borrowIndex; // For calculating interest owed
        uint256 lastUpdateTime; // When position was last updated
    }

    // ============ State Variables ============

    /// @notice Owner of the protocol
    address public owner;

    /// @notice Price oracle for asset prices
    IPriceOracle public priceOracle;

    /// @notice Interest rate model
    IInterestRateModel public interestRateModel;

    /// @notice Mapping: asset address => asset configuration
    mapping(address => AssetConfig) public assetConfigs;

    /// @notice Mapping: user => asset => position
    mapping(address => mapping(address => UserPosition)) public userPositions;

    /// @notice Mapping: asset => total borrowed
    mapping(address => uint256) public totalBorrows;

    /// @notice Mapping: asset => total liquidity available
    mapping(address => uint256) public totalLiquidity;

    /// @notice Mapping: asset => borrow index (for interest calculation)
    mapping(address => uint256) public borrowIndices;

    /// @notice Mapping: asset => last update timestamp
    mapping(address => uint256) public lastUpdateTimestamps;

    /// @notice List of all supported assets
    address[] public supportedAssets;

    // ============ Events ============

    event Supply(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Borrow(address indexed user, address indexed asset, uint256 amount);
    event Repay(address indexed user, address indexed asset, uint256 amount);
    event Liquidation(
        address indexed liquidator,
        address indexed borrower,
        address indexed collateralAsset,
        address debtAsset,
        uint256 debtRepaid,
        uint256 collateralSeized
    );
    event AssetAdded(address indexed asset, address nToken);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == owner, "NexusPool: not owner");
        _;
    }

    modifier assetExists(address asset) {
        require(assetConfigs[asset].isActive, "NexusPool: asset not supported");
        _;
    }

    // ============ Constructor ============

    constructor(address _priceOracle, address _interestRateModel) {
        owner = msg.sender;
        priceOracle = IPriceOracle(_priceOracle);
        interestRateModel = IInterestRateModel(_interestRateModel);
    }

    // ============ Admin Functions ============

    /**
     * @notice Add a new asset to the protocol
     * @param asset The token address (e.g., DAI, WETH)
     * @param nToken The corresponding nToken address
     * @param ltv Maximum LTV for borrowing (in ray)
     * @param liquidationThreshold When liquidation triggers (in ray)
     * @param liquidationBonus Bonus for liquidators (in ray)
     *
     * EXAMPLE:
     * addAsset(DAI, nDAI, 0.75e27, 0.80e27, 0.05e27)
     * - Can borrow up to 75% of collateral value
     * - Liquidation happens when LTV reaches 80%
     * - Liquidators get 5% bonus
     */
    function addAsset(
        address asset,
        address nToken,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor
    ) external onlyOwner {
        require(!assetConfigs[asset].isActive, "Asset already exists");
        require(
            ltv < liquidationThreshold,
            "LTV must be < liquidation threshold"
        );

        assetConfigs[asset] = AssetConfig({
            nToken: nToken,
            ltv: ltv,
            liquidationThreshold: liquidationThreshold,
            liquidationBonus: liquidationBonus,
            reserveFactor: reserveFactor,
            isActive: true,
            canBeCollateral: true,
            canBeBorrowed: true
        });

        borrowIndices[asset] = RAY; // Start at 1.0
        lastUpdateTimestamps[asset] = block.timestamp;
        supportedAssets.push(asset);

        emit AssetAdded(asset, nToken);
    }

    // ============ Core Functions ============

    /**
     * @notice Supply assets to earn interest
     * @param asset The token to supply
     * @param amount Amount to supply
     *
     * FLOW:
     * 1. User approves NexusPool to spend their tokens
     * 2. User calls supply(DAI, 100e18)
     * 3. Pool transfers 100 DAI from user
     * 4. Pool mints nDAI to user (receipt)
     * 5. User can now use this as collateral!
     */
    function supply(address asset, uint256 amount) external assetExists(asset) {
        require(amount > 0, "Amount must be > 0");

        // Update interest rates first
        _updateAssetState(asset);

        // Transfer tokens from user to pool
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // Mint nTokens to user
        INToken nToken = INToken(assetConfigs[asset].nToken);
        nToken.mint(msg.sender, amount);

        // Update state
        userPositions[msg.sender][asset].deposited += amount;
        totalLiquidity[asset] += amount;

        emit Supply(msg.sender, asset, amount);
    }

    /**
     * @notice Withdraw supplied assets
     * @param asset The token to withdraw
     * @param amount Amount to withdraw
     *
     * IMPORTANT: Must maintain healthy position after withdrawal!
     */
    function withdraw(
        address asset,
        uint256 amount
    ) external assetExists(asset) {
        require(amount > 0, "Amount must be > 0");
        require(
            userPositions[msg.sender][asset].deposited >= amount,
            "Insufficient balance"
        );

        // Update interest rates
        _updateAssetState(asset);

        // Check if withdrawal would make position unhealthy
        // (Simulate the withdrawal and check health factor)
        uint256 newDeposit = userPositions[msg.sender][asset].deposited -
            amount;
        require(
            _checkHealthAfterChange(msg.sender, asset, newDeposit),
            "Would become unhealthy"
        );

        // Burn nTokens from user
        INToken nToken = INToken(assetConfigs[asset].nToken);
        nToken.burn(
            msg.sender,
            (nToken.balanceOfUnderlying(msg.sender) * amount) /
                userPositions[msg.sender][asset].deposited
        );

        // Update state
        userPositions[msg.sender][asset].deposited -= amount;
        totalLiquidity[asset] -= amount;

        // Transfer tokens to user
        IERC20(asset).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, asset, amount);
    }

    /**
     * @notice Borrow assets against collateral
     * @param asset The token to borrow
     * @param amount Amount to borrow
     *
     * REQUIREMENTS:
     * 1. Must have deposited collateral first
     * 2. Health factor must stay > 1 after borrow
     * 3. Pool must have enough liquidity
     *
     * EXAMPLE:
     * - User deposited 1 ETH ($3000)
     * - LTV = 75%
     * - Max borrow = $3000 * 0.75 = $2250
     * - User borrows 1000 USDC ✅ (within limit)
     */
    function borrow(address asset, uint256 amount) external assetExists(asset) {
        require(amount > 0, "Amount must be > 0");
        require(assetConfigs[asset].canBeBorrowed, "Asset not borrowable");
        require(totalLiquidity[asset] >= amount, "Insufficient liquidity");

        // Update interest rates
        _updateAssetState(asset);

        // Check if user has enough collateral
        uint256 userCollateralValue = _getUserTotalCollateralValue(msg.sender);
        uint256 userBorrowValue = _getUserTotalBorrowValue(msg.sender);
        uint256 newBorrowValue = userBorrowValue +
            ((amount * priceOracle.getPrice(asset)) / 1e18);

        // Check: newBorrowValue <= userCollateralValue * avgLTV
        uint256 maxBorrow = _getMaxBorrowValue(msg.sender);
        require(newBorrowValue <= maxBorrow, "Exceeds borrow limit");

        // Update user's borrow position
        userPositions[msg.sender][asset].borrowed += amount;
        userPositions[msg.sender][asset].borrowIndex = borrowIndices[asset];
        userPositions[msg.sender][asset].lastUpdateTime = block.timestamp;

        // Update global state
        totalBorrows[asset] += amount;
        totalLiquidity[asset] -= amount;

        // Transfer borrowed tokens to user
        IERC20(asset).transfer(msg.sender, amount);

        emit Borrow(msg.sender, asset, amount);
    }

    /**
     * @notice Repay borrowed assets
     * @param asset The token to repay
     * @param amount Amount to repay
     *
     * User pays back loan + interest
     */
    function repay(address asset, uint256 amount) external assetExists(asset) {
        require(amount > 0, "Amount must be > 0");

        // Update interest rates
        _updateAssetState(asset);

        // Calculate total owed (principal + interest)
        uint256 totalOwed = _getUserBorrowWithInterest(msg.sender, asset);
        uint256 repayAmount = amount > totalOwed ? totalOwed : amount;

        // Transfer tokens from user to pool
        IERC20(asset).transferFrom(msg.sender, address(this), repayAmount);

        // Update user's borrow position
        if (repayAmount >= totalOwed) {
            // Full repayment
            userPositions[msg.sender][asset].borrowed = 0;
        } else {
            // Partial repayment
            userPositions[msg.sender][asset].borrowed -= repayAmount;
        }
        userPositions[msg.sender][asset].borrowIndex = borrowIndices[asset];

        // Update global state
        totalBorrows[asset] -= repayAmount;
        totalLiquidity[asset] += repayAmount;

        emit Repay(msg.sender, asset, repayAmount);
    }

    // ============ Health Factor Functions ============

    /**
     * @notice Calculate user's health factor
     * @param user Address to check
     * @return Health factor in ray (1e27 = 1.0)
     *
     * FORMULA:
     * Health Factor = (Total Collateral * Avg Liquidation Threshold) / Total Borrows
     *
     * INTERPRETATION:
     * - > 1.0: SAFE ✅
     * - = 1.0: At liquidation threshold ⚠️
     * - < 1.0: Can be liquidated 💀
     */
    function getHealthFactor(address user) public view returns (uint256) {
        uint256 totalCollateralValue = _getUserTotalCollateralValue(user);
        uint256 totalBorrowValue = _getUserTotalBorrowValue(user);

        if (totalBorrowValue == 0) {
            return type(uint256).max; // No borrows = infinite health
        }

        // Weighted liquidation threshold
        uint256 weightedThreshold = _getWeightedLiquidationThreshold(user);

        // Health Factor = (Collateral * Threshold) / Borrows
        return
            (totalCollateralValue * weightedThreshold) / totalBorrowValue / RAY;
    }

    /**
     * @notice Check if user can be liquidated
     * @param user Address to check
     * @return True if health factor < 1
     */
    function isLiquidatable(address user) public view returns (bool) {
        return getHealthFactor(user) < RAY;
    }

    // ============ Internal Functions ============

    /**
     * @dev Update asset state (interest accrual)
     */
    function _updateAssetState(address asset) internal {
        uint256 timeElapsed = block.timestamp - lastUpdateTimestamps[asset];
        if (timeElapsed == 0) return;

        // Calculate interest accrued
        uint256 borrowRate = interestRateModel.getBorrowRate(
            totalBorrows[asset],
            totalLiquidity[asset]
        );

        // Compound interest: newIndex = oldIndex * (1 + rate * time / year)
        uint256 interestFactor = RAY +
            ((borrowRate * timeElapsed) / SECONDS_PER_YEAR);
        borrowIndices[asset] = (borrowIndices[asset] * interestFactor) / RAY;

        lastUpdateTimestamps[asset] = block.timestamp;
    }

    /**
     * @dev Get user's total collateral value in USD
     */
    function _getUserTotalCollateralValue(
        address user
    ) internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address asset = supportedAssets[i];
            if (assetConfigs[asset].canBeCollateral) {
                uint256 deposited = userPositions[user][asset].deposited;
                uint256 price = priceOracle.getPrice(asset);
                total += (deposited * price) / 1e18;
            }
        }
        return total;
    }

    /**
     * @dev Get user's total borrow value in USD
     */
    function _getUserTotalBorrowValue(
        address user
    ) internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address asset = supportedAssets[i];
            uint256 borrowed = _getUserBorrowWithInterest(user, asset);
            uint256 price = priceOracle.getPrice(asset);
            total += (borrowed * price) / 1e18;
        }
        return total;
    }

    /**
     * @dev Get user's borrow amount including accrued interest
     */
    function _getUserBorrowWithInterest(
        address user,
        address asset
    ) internal view returns (uint256) {
        UserPosition storage pos = userPositions[user][asset];
        if (pos.borrowed == 0) return 0;

        // Interest = principal * (currentIndex / userIndex)
        return (pos.borrowed * borrowIndices[asset]) / pos.borrowIndex;
    }

    /**
     * @dev Get maximum borrow value for user based on LTV
     */
    function _getMaxBorrowValue(address user) internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address asset = supportedAssets[i];
            if (assetConfigs[asset].canBeCollateral) {
                uint256 deposited = userPositions[user][asset].deposited;
                uint256 price = priceOracle.getPrice(asset);
                uint256 value = (deposited * price) / 1e18;
                total += (value * assetConfigs[asset].ltv) / RAY;
            }
        }
        return total;
    }

    /**
     * @dev Get weighted liquidation threshold
     */
    function _getWeightedLiquidationThreshold(
        address user
    ) internal view returns (uint256) {
        uint256 totalValue = 0;
        uint256 weightedThreshold = 0;

        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address asset = supportedAssets[i];
            uint256 deposited = userPositions[user][asset].deposited;
            if (deposited > 0) {
                uint256 price = priceOracle.getPrice(asset);
                uint256 value = (deposited * price) / 1e18;
                totalValue += value;
                weightedThreshold +=
                    value *
                    assetConfigs[asset].liquidationThreshold;
            }
        }

        if (totalValue == 0) return 0;
        return weightedThreshold / totalValue;
    }

    /**
     * @dev Check if position would be healthy after change
     */
    function _checkHealthAfterChange(
        address user,
        address asset,
        uint256 newDeposit
    ) internal view returns (bool) {
        // Simplified check - would need full recalculation in production
        uint256 currentDeposit = userPositions[user][asset].deposited;
        if (newDeposit >= currentDeposit) return true;

        uint256 reduction = currentDeposit - newDeposit;
        uint256 reductionValue = (reduction * priceOracle.getPrice(asset)) /
            1e18;
        uint256 currentCollateral = _getUserTotalCollateralValue(user);
        uint256 newCollateral = currentCollateral - reductionValue;
        uint256 borrowValue = _getUserTotalBorrowValue(user);

        if (borrowValue == 0) return true;

        uint256 threshold = _getWeightedLiquidationThreshold(user);
        return ((newCollateral * threshold) / RAY) >= borrowValue;
    }

    // ============ View Functions ============

    /**
     * @notice Get current utilization rate for an asset
     */
    function getUtilizationRate(address asset) external view returns (uint256) {
        return
            interestRateModel.getUtilizationRate(
                totalBorrows[asset],
                totalLiquidity[asset]
            );
    }

    /**
     * @notice Get current borrow rate for an asset
     */
    function getBorrowRate(address asset) external view returns (uint256) {
        return
            interestRateModel.getBorrowRate(
                totalBorrows[asset],
                totalLiquidity[asset]
            );
    }

    /**
     * @notice Get current supply rate for an asset
     */
    function getSupplyRate(address asset) external view returns (uint256) {
        return
            interestRateModel.getSupplyRate(
                totalBorrows[asset],
                totalLiquidity[asset],
                assetConfigs[asset].reserveFactor
            );
    }
}
