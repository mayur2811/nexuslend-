// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/Interfaces.sol";

/**
 * @title LiquidationEngine
 * @notice Handles liquidations with NexusLend's innovative features
 *
 * ┌─────────────────────────────────────────────────────────────────┐
 * │         WHAT MAKES THIS DIFFERENT FROM AAVE/COMPOUND?          │
 * ├─────────────────────────────────────────────────────────────────┤
 * │                                                                 │
 * │  TRADITIONAL:     NEXUSLEND:                                   │
 * │  ─────────────    ─────────────                                │
 * │  100% liquidated  25% gradual liquidation                      │
 * │  No warning       1-hour grace period                          │
 * │  10% penalty      5% penalty                                   │
 * │  MEV bots profit  Fair auction system                          │
 * │                                                                 │
 * └─────────────────────────────────────────────────────────────────┘
 *
 * HOW IT WORKS:
 * 1. User's health factor drops below 1.0
 * 2. Grace period starts (1 hour countdown)
 * 3. During grace: User can add collateral or repay
 * 4. After grace: Only 25% can be liquidated
 * 5. If still unhealthy: Wait, then another 25%
 */
contract LiquidationEngine {
    // ============ Constants ============

    uint256 public constant RAY = 1e27;

    /// @notice Grace period before liquidation can start (1 hour)
    uint256 public constant GRACE_PERIOD = 1 hours;

    /// @notice Maximum liquidation per call (25%)
    uint256 public constant MAX_LIQUIDATION_PERCENT = 25;

    /// @notice Minimum time between liquidations (15 minutes)
    uint256 public constant LIQUIDATION_COOLDOWN = 15 minutes;

    /// @notice Default liquidation bonus (5%)
    uint256 public constant DEFAULT_LIQUIDATION_BONUS = 5e25; // 5% in ray

    // ============ State Variables ============

    /// @notice The main lending pool
    address public pool;

    /// @notice Price oracle for asset values
    IPriceOracle public priceOracle;

    /// @notice Owner of the contract
    address public owner;

    /// @notice Tracks when a user first became liquidatable
    /// @dev user => timestamp when they became unhealthy
    mapping(address => uint256) public gracePeriodStart;

    /// @notice Tracks last liquidation time per user
    mapping(address => uint256) public lastLiquidationTime;

    /// @notice Tracks total amount liquidated per user (for gradual limits)
    mapping(address => uint256) public totalLiquidatedValue;

    // ============ Events ============

    event GracePeriodStarted(address indexed user, uint256 timestamp);
    event GracePeriodEnded(address indexed user, string reason);
    event LiquidationExecuted(
        address indexed liquidator,
        address indexed borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtRepaid,
        uint256 collateralSeized,
        uint256 bonus
    );
    event UserSelfRescued(address indexed user, uint256 newHealthFactor);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == owner, "LiquidationEngine: not owner");
        _;
    }

    // ============ Constructor ============

    constructor(address _pool, address _priceOracle) {
        owner = msg.sender;
        pool = _pool;
        priceOracle = IPriceOracle(_priceOracle);
    }

    // ============ Core Functions ============

    /**
     * @notice Check and start grace period for a user
     * @param user Address to check
     *
     * FLOW:
     * 1. Anyone can call this when a user becomes unhealthy
     * 2. Starts the 1-hour grace period
     * 3. User can now self-rescue
     */
    function checkAndStartGracePeriod(address user) external {
        // Get health factor from pool (simplified - would call pool in production)
        uint256 healthFactor = _getHealthFactor(user);

        // If healthy, clear any existing grace period
        if (healthFactor >= RAY) {
            if (gracePeriodStart[user] != 0) {
                gracePeriodStart[user] = 0;
                emit GracePeriodEnded(user, "User recovered");
            }
            return;
        }

        // If unhealthy and no grace period started, start one
        if (gracePeriodStart[user] == 0) {
            gracePeriodStart[user] = block.timestamp;
            emit GracePeriodStarted(user, block.timestamp);
        }
    }

    /**
     * @notice Execute a gradual liquidation
     * @param borrower The user being liquidated
     * @param collateralAsset Asset to seize as collateral
     * @param debtAsset Asset the borrower owes
     * @param debtToRepay Amount of debt to repay
     *
     * REQUIREMENTS:
     * 1. Grace period must have expired
     * 2. Can only liquidate 25% of position at a time
     * 3. Must wait COOLDOWN between liquidations
     *
     * EXAMPLE:
     * - Bob owes $1000, has $800 collateral (unhealthy)
     * - Liquidator repays $250 (25% of debt)
     * - Liquidator receives $262.50 collateral (5% bonus)
     * - Bob still owes $750, has $537.50 collateral
     */
    function liquidate(
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtToRepay
    ) external {
        // Check 1: User must be liquidatable
        uint256 healthFactor = _getHealthFactor(borrower);
        require(healthFactor < RAY, "User is healthy");

        // Check 2: Grace period must have expired
        uint256 graceStart = gracePeriodStart[borrower];
        require(graceStart != 0, "Grace period not started");
        require(
            block.timestamp >= graceStart + GRACE_PERIOD,
            "Grace period not expired"
        );

        // Check 3: Cooldown between liquidations
        require(
            block.timestamp >=
                lastLiquidationTime[borrower] + LIQUIDATION_COOLDOWN,
            "Cooldown not expired"
        );

        // Check 4: Cannot exceed 25% of position
        uint256 maxDebtToRepay = _getMaxLiquidatableDebt(borrower, debtAsset);
        require(debtToRepay <= maxDebtToRepay, "Exceeds 25% limit");

        // Calculate collateral to seize (debt + bonus)
        uint256 debtValue = (debtToRepay * priceOracle.getPrice(debtAsset)) /
            1e18;
        uint256 bonusValue = (debtValue * DEFAULT_LIQUIDATION_BONUS) / RAY;
        uint256 totalCollateralValue = debtValue + bonusValue;

        // Convert to collateral asset amount
        uint256 collateralPrice = priceOracle.getPrice(collateralAsset);
        uint256 collateralToSeize = (totalCollateralValue * 1e18) /
            collateralPrice;

        // Transfer debt from liquidator to pool
        IERC20(debtAsset).transferFrom(msg.sender, pool, debtToRepay);

        // Transfer collateral from pool to liquidator
        // (In production, this would call pool.seizeCollateral)
        IERC20(collateralAsset).transferFrom(
            pool,
            msg.sender,
            collateralToSeize
        );

        // Update state
        lastLiquidationTime[borrower] = block.timestamp;
        totalLiquidatedValue[borrower] += debtValue;

        emit LiquidationExecuted(
            msg.sender,
            borrower,
            collateralAsset,
            debtAsset,
            debtToRepay,
            collateralToSeize,
            bonusValue
        );

        // Check if user is now healthy - if so, clear grace period
        if (_getHealthFactor(borrower) >= RAY) {
            gracePeriodStart[borrower] = 0;
            emit GracePeriodEnded(borrower, "Liquidation restored health");
        }
    }

    /**
     * @notice User self-rescues by adding collateral or repaying debt
     * @dev Called by the pool when user takes action
     *
     * This is the "SAVE YOURSELF" mechanism!
     * During grace period, user can:
     * - Add more collateral
     * - Repay some debt
     * - Enable Auto-Protect (AI manages position)
     */
    function notifySelfRescue(address user) external {
        require(msg.sender == pool, "Only pool can notify");

        uint256 healthFactor = _getHealthFactor(user);

        if (healthFactor >= RAY) {
            // User is healthy again!
            gracePeriodStart[user] = 0;
            totalLiquidatedValue[user] = 0;

            emit UserSelfRescued(user, healthFactor);
            emit GracePeriodEnded(user, "User self-rescued");
        }
    }

    // ============ View Functions ============

    /**
     * @notice Check if a user can be liquidated right now
     * @param user Address to check
     * @return canLiquidate True if liquidation is possible
     * @return reason Why or why not
     */
    function canLiquidate(
        address user
    ) external view returns (bool canLiquidate, string memory reason) {
        uint256 healthFactor = _getHealthFactor(user);

        // Check 1: Is user unhealthy?
        if (healthFactor >= RAY) {
            return (false, "User is healthy");
        }

        // Check 2: Is grace period started?
        uint256 graceStart = gracePeriodStart[user];
        if (graceStart == 0) {
            return (
                false,
                "Grace period not started - call checkAndStartGracePeriod first"
            );
        }

        // Check 3: Has grace period expired?
        if (block.timestamp < graceStart + GRACE_PERIOD) {
            uint256 remaining = (graceStart + GRACE_PERIOD) - block.timestamp;
            return (
                false,
                string(
                    abi.encodePacked(
                        "Grace period: ",
                        _uintToString(remaining),
                        " seconds remaining"
                    )
                )
            );
        }

        // Check 4: Is cooldown expired?
        if (
            block.timestamp < lastLiquidationTime[user] + LIQUIDATION_COOLDOWN
        ) {
            uint256 remaining = (lastLiquidationTime[user] +
                LIQUIDATION_COOLDOWN) - block.timestamp;
            return (
                false,
                string(
                    abi.encodePacked(
                        "Cooldown: ",
                        _uintToString(remaining),
                        " seconds remaining"
                    )
                )
            );
        }

        return (true, "Ready for liquidation");
    }

    /**
     * @notice Get time remaining in grace period
     * @param user Address to check
     * @return remaining Seconds remaining (0 if expired or not started)
     */
    function getGracePeriodRemaining(
        address user
    ) external view returns (uint256 remaining) {
        uint256 graceStart = gracePeriodStart[user];
        if (graceStart == 0) return 0;

        uint256 expiry = graceStart + GRACE_PERIOD;
        if (block.timestamp >= expiry) return 0;

        return expiry - block.timestamp;
    }

    /**
     * @notice Get maximum debt that can be liquidated in one call
     * @param borrower User to check
     * @param debtAsset Debt asset
     * @return Maximum debt amount (25% of total)
     */
    function getMaxLiquidatableDebt(
        address borrower,
        address debtAsset
    ) external view returns (uint256) {
        return _getMaxLiquidatableDebt(borrower, debtAsset);
    }

    // ============ Internal Functions ============

    /**
     * @dev Get health factor (placeholder - would call pool in production)
     */
    function _getHealthFactor(address user) internal view returns (uint256) {
        // In production, this calls: INexusPool(pool).getHealthFactor(user)
        // For now, return a placeholder
        // This would be:
        // return INexusPool(pool).getHealthFactor(user);
        return RAY; // Placeholder
    }

    /**
     * @dev Calculate maximum liquidatable debt (25% of total)
     */
    function _getMaxLiquidatableDebt(
        address borrower,
        address debtAsset
    ) internal view returns (uint256) {
        // In production, get total debt from pool
        // uint256 totalDebt = INexusPool(pool).getUserBorrow(borrower, debtAsset);
        // return (totalDebt * MAX_LIQUIDATION_PERCENT) / 100;
        return 0; // Placeholder
    }

    /**
     * @dev Convert uint to string (for error messages)
     */
    function _uintToString(
        uint256 value
    ) internal pure returns (string memory) {
        if (value == 0) return "0";

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
