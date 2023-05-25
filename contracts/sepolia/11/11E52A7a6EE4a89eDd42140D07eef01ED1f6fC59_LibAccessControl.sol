// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

library LibAccessControl {

    error AccessControl__MissingRole(bytes32 role);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessControlStorage {
        mapping(bytes32 => RoleData) _roles;
    }

    /// @dev Storage slot to use for Access Control specific storage
    bytes32 internal constant STORAGE_SLOT = keccak256("adventurehub.storage.AccessControl");

    /// @dev Default admin role identifier
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
    /// @dev `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite {RoleAdminChanged} not being emitted signaling this.
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

     /// @dev Emitted when `account` is granted `role`.
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /// @dev Emitted when `account` is revoked `role`.
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /// @dev Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return accessControlStorage()._roles[role].members[account];
    }

    /// @notice Returns the admin role that controls the provided `role`
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return accessControlStorage()._roles[role].adminRole;
    }

    /**
     * @notice Grants `role` to `account`.
     *
     * @dev    Throws if `msg.sender` is not the admin of `role`.
     * @dev    No-op if `account` already has `role`.
     * 
     * @dev    <h4>Postconditions</h4>
     * @dev    1. If `account` does not have `role`, emits a {RoleGranted} event.
     * @dev    2. If `account` does not have `role`, `account` has `role`.
     */
    function grantRole(bytes32 role, address account) external {
        _checkRole(getRoleAdmin(role));
        _grantRole(role, account);
    }

    /**
     * @notice Revokes `role` from `account`.
     *
     * @dev    Throws if `msg.sender` is not the admin of `role`.
     * @dev    No-op if `account` does not have `role`.
     * 
     * @dev    <h4>Postconditions</h4>
     * @dev    1. If `account` has `role`, emits a {RoleRevoked} event.
     * @dev    2. If `account` has `role`, `role` is removed from `account`.
     */
    function revokeRole(bytes32 role, address account) external {
        _checkRole(getRoleAdmin(role));
        _revokeRole(role, account);
    }

    /**
     * @notice Sets `adminRole` as ``role``'s admin role.
     *
     * @dev   <h4>Postconditions</h4>
     * @dev   1. Emits a {RoleAdminChanged} event.
     * @dev   2. `role`'s admin role is `adminRole`.
     */
    function _setAdminRole(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        accessControlStorage()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     * @dev Internal function without access restriction.
     *
     * @dev Emits a {RoleGranted} event if the account did not already have the role.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            accessControlStorage()._roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     * @dev Internal function without access restriction.
     *
     * @dev Emits a RoleRevoked event if the account had the role.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            accessControlStorage()._roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /// @dev Revert with a standard message if `msg.sender` is missing `role`.
    function _checkRole(bytes32 role) internal view {
        _checkRole(role, msg.sender);
    }

    /// @dev Revert with a standard message if `account` is missing `role`.
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert AccessControl__MissingRole(role);
        }
    }

    /// @dev Returns the storage data stored at the `STORAGE_SLOT`
    function accessControlStorage() internal pure returns (AccessControlStorage storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}