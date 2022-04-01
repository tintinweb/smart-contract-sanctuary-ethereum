// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./acl/OmniteAccessControl.sol";

contract AccessControlList is OmniteAccessControl {

    bytes32 public constant CONTROL_LIST_ADMIN_ROLE = keccak256("CONTROL_LIST_ADMIN_ROLE");
    bytes32 public constant BRIDGE_DEFAULT_ADMIN_ROLE = keccak256("BRIDGE_DEFAULT_ADMIN_ROLE");
    bytes32 public constant SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE = keccak256("SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE");
    bytes32 public constant FEE_COLLECTOR_DEFAULT_ADMIN_ROLE = keccak256("FEE_COLLECTOR_DEFAULT_ADMIN_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE = keccak256("COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE");
    bytes32 public constant TOKEN_UNLOCK_ROLE = keccak256("TOKEN_UNLOCK_ROLE");
    bytes32 public constant TOKEN_DEFAULT_ADMIN_ROLE = keccak256("TOKEN_DEFAULT_ADMIN_ROLE");

    bytes32 public constant SYSTEM_CONTEXT_ROLE = keccak256("SYSTEM_CONTEXT_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant CONTRACT_FACTORY_ROLE = keccak256("CONTRACT_FACTORY_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_ROLE = keccak256("COLLECTION_REGISTRY_ROLE");
    bytes32 public constant ACCESS_CONTROL_ROLE = keccak256("ACCESS_CONTROL_ROLE");
    bytes32 public constant OWNER_VERIFIER_ROLE = keccak256("OWNER_VERIFIER_ROLE");
    bytes32 public constant OMNITE_TOKEN_ROLE = keccak256("OMNITE_TOKEN_ROLE");

    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant NATIVE_TOKEN_ROLE = keccak256("NATIVE_TOKEN_ROLE");
    bytes32 public constant NON_NATIVE_TOKEN_ROLE = keccak256("NON_NATIVE_TOKEN_ROLE");

    constructor(address admin) {

        _setupRole(DEFAULT_ADMIN_ROLE, toBytes(admin));
        _setupRole(CONTROL_LIST_ADMIN_ROLE, toBytes(admin));
        _setupRole(SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE, toBytes(admin));
        _setupRole(COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE, toBytes(admin));
        _setupRole(TOKEN_DEFAULT_ADMIN_ROLE, toBytes(admin));
        _setupRole(FEE_COLLECTOR_DEFAULT_ADMIN_ROLE, toBytes(admin));
        _setupRole(ACCESS_CONTROL_ROLE, toBytes(address(this)));
        _setupRole(BRIDGE_ROLE, toBytes(address(this)));

        // CONTROL_LIST_ADMIN_ROLE is an admin of other administration roles
        _setRoleAdmin(SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(BRIDGE_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(FEE_COLLECTOR_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(TOKEN_UNLOCK_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(TOKEN_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(SYSTEM_CONTEXT_ROLE, CONTROL_LIST_ADMIN_ROLE);

        // SYSTEM_CONTEXT_ROLE is an admin of other system contract roles
        _setRoleAdmin(BRIDGE_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(CONTRACT_FACTORY_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(COLLECTION_REGISTRY_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(ACCESS_CONTROL_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(OWNER_VERIFIER_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(OMNITE_TOKEN_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(FEE_COLLECTOR_ROLE, SYSTEM_CONTEXT_ROLE);

        // Contract factory is an admin of NATIVE_TOKEN_ROLE and NON_NATIVE_TOKEN_ROLE
        _setRoleAdmin(NATIVE_TOKEN_ROLE, CONTRACT_FACTORY_ROLE);
        _setRoleAdmin(NON_NATIVE_TOKEN_ROLE, CONTRACT_FACTORY_ROLE);
    }

    function checkRole(bytes32 role, bytes memory account) external view {
        return _checkRole(role, account);
    }

    function grantNativeTokenRole(address addr) external {
        grantRole(NATIVE_TOKEN_ROLE, toBytes(addr));
    }

    function grantNonNativeTokenRole(address addr) external {
        grantRole(NON_NATIVE_TOKEN_ROLE, toBytes(addr));
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyRole(CONTROL_LIST_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    function checkRoleAddr(bytes32 role, address account) external view {
        return _checkRole(role, toBytes(account));
    }

    function hasRoleAddr(bytes32 role, address account) public view returns (bool) {
        return hasRole(role, toBytes(account));
    }

    function grantRoleAddr(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        grantRole(role, toBytes(account));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "./AclContext.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract OmniteAccessControl is AclContext, IAccessControl, ERC165 {
    struct RoleData {
        mapping(bytes => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, bytes memory account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, bytes memory account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function toHexString(bytes memory account) internal pure returns(string memory) {
        if (account.length == 20) { // all eth based addresses
            return Strings.toHexString(uint256(uint160(bytes20(account))));
        } else if (account.length <= 32) { // most of other addresses if not all of them
            return Strings.toHexString(uint256(bytes32(account)));
        }
        return string(account); // not supported, just return raw bytes (shouldn't happen)
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, bytes memory account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, bytes memory account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, bytes memory account) public virtual override {
        require(keccak256(account) == keccak256(_msgSender()), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, bytes memory account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, bytes memory account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, bytes memory account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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
    event RoleGranted(bytes32 indexed role, bytes indexed account, bytes indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, bytes indexed account, bytes indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, bytes calldata account) external view returns (bool);

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
    function grantRole(bytes32 role, bytes calldata account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, bytes calldata account) external;

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
    function renounceRole(bytes32 role, bytes calldata account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract AclContext {
    function _msgSender() internal view virtual returns (bytes memory) {
        return abi.encodePacked(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}