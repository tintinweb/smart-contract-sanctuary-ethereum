//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "./interfaces/IRule.sol";
import "../openzeppelin-contracts-upgradeable/contracts/access/IAccessControlUpgradeable.sol";

contract GlobalList {
    mapping(address => bool) whitelist;
    mapping(address => bool) blacklist;

    IAccessControlUpgradeable authorizationModule;

    constructor(address[] memory whitelist_, address[] memory blacklist_) {
        for (uint256 i = 0; i < whitelist_.length; i++) {
            whitelist[whitelist_[i]] = true;
        }
        for (uint256 i = 0; i < blacklist_.length; i++) {
            whitelist[blacklist_[i]] = true;
        }
    }

    function setWhitelist(address[] memory whitelist_, bool value) external {
        for (uint256 i = 0; i < whitelist_.length; i++) {
            whitelist[whitelist_[i]] = value;
        }
    }

    function setBlacklist(address[] memory blacklist_, bool value) external {
        for (uint256 i = 0; i < blacklist_.length; i++) {
            blacklist[blacklist_[i]] = value;
        }
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    function isBlacklisted(address addr) external view returns (bool) {
        return blacklist[addr];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;


import "./IERC1404Wrapper.sol";


interface IRule is IERC1404Wrapper {
     /**
     * @dev Returns true if the restriction code exists, and false otherwise.
     */
     function canReturnTransferRestrictionCode(uint8 _restrictionCode)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "./IERC1404.sol";


interface IERC1404Wrapper is IERC1404 {
    /**
     * @dev Returns true if the transfer is valid, and false otherwise.
     */
    function validateTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool isValid);
}

//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;


interface IERC1404 {
    /**
     * @dev See ERC-1404
     *
     */
    function detectTransferRestriction(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint8);

    /**
     * @dev See ERC-1404
     *
     */
    function messageForTransferRestriction(uint8 _restrictionCode)
        external
        view
        returns (string memory);
}