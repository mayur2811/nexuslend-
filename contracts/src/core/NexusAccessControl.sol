// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NexusAccessControl
 * @notice Role-based access control for NexusLend
 *
 * WHY ACCESS CONTROL?
 * - Different people have different permissions
 * - Owner can add assets, set parameters
 * - Guardian can pause in emergencies
 * - Nobody else can do anything dangerous
 *
 * ROLES:
 * ┌─────────────────────────────────────────────────────┐
 * │  OWNER (God Mode)                                   │
 * │  - Add/remove assets                               │
 * │  - Set risk parameters                             │
 * │  - Grant/revoke roles                              │
 * │  - Upgrade contracts                               │
 * ├─────────────────────────────────────────────────────┤
 * │  GUARDIAN (Emergency)                              │
 * │  - Pause protocol                                  │
 * │  - Freeze specific assets                          │
 * ├─────────────────────────────────────────────────────┤
 * │  RISK_ADMIN (Parameters)                           │
 * │  - Update interest rate parameters                 │
 * │  - Adjust LTV/liquidation thresholds              │
 * ├─────────────────────────────────────────────────────┤
 * │  ASSET_LISTER (Assets)                             │
 * │  - Add new assets                                  │
 * │  - Configure asset parameters                      │
 * └─────────────────────────────────────────────────────┘
 */
contract NexusAccessControl {
    // ============ Role Definitions ============

    bytes32 public constant OWNER_ROLE = keccak256("OWNER");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN");
    bytes32 public constant RISK_ADMIN_ROLE = keccak256("RISK_ADMIN");
    bytes32 public constant ASSET_LISTER_ROLE = keccak256("ASSET_LISTER");

    // ============ State Variables ============

    /// @notice Mapping: role => address => hasRole
    mapping(bytes32 => mapping(address => bool)) private _roles;

    /// @notice Mapping: role => admin role (who can grant/revoke)
    mapping(bytes32 => bytes32) private _roleAdmin;

    /// @notice Protocol pause state
    bool public paused;

    /// @notice Asset freeze state
    mapping(address => bool) public frozenAssets;

    // ============ Events ============

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event AssetFrozen(address indexed asset, address indexed by);
    event AssetUnfrozen(address indexed asset, address indexed by);

    // ============ Modifiers ============

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "AccessControl: missing role");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AccessControl: protocol paused");
        _;
    }

    modifier assetNotFrozen(address asset) {
        require(!frozenAssets[asset], "AccessControl: asset frozen");
        _;
    }

    // ============ Constructor ============

    constructor() {
        // Deployer gets OWNER role
        _grantRole(OWNER_ROLE, msg.sender);

        // OWNER is admin for all roles
        _roleAdmin[OWNER_ROLE] = OWNER_ROLE;
        _roleAdmin[GUARDIAN_ROLE] = OWNER_ROLE;
        _roleAdmin[RISK_ADMIN_ROLE] = OWNER_ROLE;
        _roleAdmin[ASSET_LISTER_ROLE] = OWNER_ROLE;
    }

    // ============ Role Management ============

    /**
     * @notice Check if address has a role
     * @param role Role to check
     * @param account Address to check
     * @return True if has role
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    /**
     * @notice Grant a role to an address
     * @param role Role to grant
     * @param account Address to receive role
     *
     * EXAMPLE:
     * grantRole(GUARDIAN_ROLE, 0x123...)
     * Now 0x123 can pause the protocol!
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @notice Revoke a role from an address
     * @param role Role to revoke
     * @param account Address to lose role
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(getRoleAdmin(role)) {
        require(
            !(role == OWNER_ROLE && account == msg.sender),
            "Cannot revoke own OWNER role"
        );
        _revokeRole(role, account);
    }

    /**
     * @notice Renounce your own role
     * @param role Role to give up
     */
    function renounceRole(bytes32 role) external {
        require(hasRole(role, msg.sender), "Don't have this role");
        require(role != OWNER_ROLE, "Cannot renounce OWNER");
        _revokeRole(role, msg.sender);
    }

    /**
     * @notice Get the admin role for a role
     * @param role Role to check
     * @return Admin role
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmin[role];
    }

    // ============ Emergency Functions ============

    /**
     * @notice Pause the entire protocol
     * @dev Only GUARDIAN or OWNER can call
     *
     * USE FOR:
     * - Critical vulnerability discovered
     * - Oracle manipulation detected
     * - Market extreme conditions
     */
    function pause() external {
        require(
            hasRole(GUARDIAN_ROLE, msg.sender) ||
                hasRole(OWNER_ROLE, msg.sender),
            "Not authorized to pause"
        );
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @notice Unpause the protocol
     * @dev Only OWNER can unpause (more restrictive)
     */
    function unpause() external onlyRole(OWNER_ROLE) {
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @notice Freeze a specific asset
     * @param asset Asset to freeze
     *
     * USE FOR:
     * - Asset-specific issues (oracle problems)
     * - Token contract vulnerability
     * - Regulatory concerns
     */
    function freezeAsset(address asset) external {
        require(
            hasRole(GUARDIAN_ROLE, msg.sender) ||
                hasRole(OWNER_ROLE, msg.sender),
            "Not authorized to freeze"
        );
        frozenAssets[asset] = true;
        emit AssetFrozen(asset, msg.sender);
    }

    /**
     * @notice Unfreeze an asset
     * @param asset Asset to unfreeze
     */
    function unfreezeAsset(address asset) external onlyRole(OWNER_ROLE) {
        frozenAssets[asset] = false;
        emit AssetUnfrozen(asset, msg.sender);
    }

    // ============ Internal Functions ============

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    // ============ View Functions ============

    /**
     * @notice Check if protocol is operational
     * @return True if not paused
     */
    function isOperational() external view returns (bool) {
        return !paused;
    }

    /**
     * @notice Check if asset is operational
     * @param asset Asset to check
     * @return True if not frozen and protocol not paused
     */
    function isAssetOperational(address asset) external view returns (bool) {
        return !paused && !frozenAssets[asset];
    }
}
