/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

/** 
 *  SourceUnit: /Users/wizardsorb/Documents/KODEX/byte-store/contracts/ByteStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/wizardsorb/Documents/KODEX/byte-store/contracts/ByteStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: /Users/wizardsorb/Documents/KODEX/byte-store/contracts/ByteStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/wizardsorb/Documents/KODEX/byte-store/contracts/ByteStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




/** 
 *  SourceUnit: /Users/wizardsorb/Documents/KODEX/byte-store/contracts/ByteStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/wizardsorb/Documents/KODEX/byte-store/contracts/ByteStore.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


/** 
 *  SourceUnit: /Users/wizardsorb/Documents/KODEX/byte-store/contracts/ByteStore.sol
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
////import "@openzeppelin/contracts/access/AccessControl.sol";

/*
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*+++++*@@RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * [email protected]++++++++*RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * [email protected]RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*++++++++*RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*+++++++++RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR+++++++++RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR+R++++++++++RRRRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*+RR*+++++++++RRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR+++++++RRRRRR++RRR*+++++++++RRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR++++++++RRRR+++RRRR******+++*RRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR++++++RRRR**+RRRRRR*******++RRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR***+++RRR****RRRRRR********+*RRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR****[email protected]****RRRRRRR********+*RRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR****++R##***RRRRRRRRR*********RRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#****+R###**RRRRRRRRRR*********@RRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR##****R###**RRRRRRRRRRR**********RRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR###***####**RRRRRRRRRRRR**********RRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#####**####**RRRRRRRRRRRRR**********RRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR######*#####**RRRRRRRRRRRRRR*********RRRRRRRRRRR
 * [email protected]######*#####*RRRRRRRRRRRRRRRR*********RRRRRRRRRR
 * [email protected]##############RRRRRRRRRRRRRRRRR*********RRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR###############RRRRRRRRRRRRRRRRRRR*********RRRRRRRR
 * [email protected]+++++RRRR*RR################RRRRRRRRRRRRRRRRRRR**********RRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRR*++++++++++++*RR####################RRRRRRRRRRRRRRRRR*********RRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRR+++++++++++++**RRR#######################RRRRRRRRRRRRRRRR*********RRRRRR
 * RRRRRRRRRRRRRRRRRRRRRR+++++++++++++**RRRR#######**################RRRRRRRRRRRRRRR**********RRRRR
 * RRRRRRRRRRRRRRRRRRRR+++++++++++++***RRRR######*********############*RRRRRRRRRRRRRR*********RRRRR
 * RRRRRRRRRRRRRRRRRRR++++++++++++****RRRR**####R++***+***###########***RRRRRRRRRRRRR**********RRRR
 * RRRRRRRRRRRRRRRRR+++++++++++++***RRRRRR***##R++++++++***##*#######**++RRRRRRRRRRRRR*********RRRR
 * RRRRRRRRRRRRRRRR+++*************RRRRRR*****RR+++*****++++++++++++++++++RRRRRRRRRRRRR*********RRR
 * [email protected]****************RRRRRRR++**RRR+********+++*********++++++RRRRRRRRRRRR*********RRR
 * RRRRRRRRRRRRR******************RRRRRRR+++RRR#####******+************++++*RRRRRRRRRRR*********RRR
 * RRRRRRRRRRRR******************RRRRRRRR++*R#########*******************++RRRRRRRRRRRRR*********RR
 * RRRRRRRRRRR******************RRRRRRRRR++*############******************+RR+RRRRRRRRRR*********RR
 * RRRRRRRRRRR*****************RRRRRRRRRR+*##############**********##*******[email protected]@RRRRRRRRR#********RR
 * RRRR*RRRRR**********#*******RRRRRRRRRR*###############***********##*****+RR+RRRRRRRRRR*********R
 * RRRR*RRRR********####******RRRRRRRRRR*#####******######**********###*****RR+RRRRRRRRRR*********R
 * RRR*RRRR******######*******RRRRRRRRR**###****##****####***********###*****RR+RRRRRRRRR#********R
 * RRR+RRRR*****######*******RRRRRRRRRR**##**#RRRR###**###************###****RR+RRRRRRRRR#********R
 * RR*+RRR*****#######*******RRRRRRRRRR**#**#RRRRRRR##**##*************##****RR+*RRRRRRRRR#*******R
 * RR++RRR****#######********RRRRRRRRRR**#**RRRRRRRRRR#**#***#*********###***RR++RRRRRRRRR#********
 * RR++RR****#######********RRRRRRRRRRR****RRRRRRRRRRR##*****##***#****###***RR++RRRRRRRRR#********
 * R*++RR***########********RRRRRRRRRRR***RRRRRRRRRRRRR#*****##***#*****##***RR*+RRRRRRRRR##*******
 * R+++R****#######******+**RRRRRRRRRRR***RRRRRRRRRRRRRR****####**#*****##***RRR++RRRRRRRR#********
 * R+++R***########******+**RRRRRRRRRRRR*RRRRRRRRRRRRRRR****####***#****##***RRR++RRRRRRRR#********
 * R+++R**#########*****#***RRRRRRRRRRRR*RRRRRRRRRRRRRRRR***####***#*****#***RRR++RRRRRRRR##*******
 * @+++***########*****#****RRRRRRRRRRRRRRRRRRRRRRRRRRRRR***####***#********RRRR++RRRRRRRR##*******
 * ++++**#########*****#****RRRRRRRRRRRRRRRRRRRRRRRRRRRRR**#####***#********RRR*++RRRRRRRR##*******
 * ++++**#########*****#****RRRRRRRRRRRRRRRRRRRRRRRRRRRRR*+#####***#********RRR*++RRRRRRRR##*******
 * ++++**########*****##*****RRRRRRRRRRRRRRRRRRRRRRRRRRR*++#####**##*******RRRR*+++RRRRRRR##*******
 * ++++**########*****###****RRRRRRRRRRRRRRRRRRRRRRRRRRR++R#####**##*******RRRR*+++RRRRRRR##*******
 * ++++*#########*****###****RRRRRRRRRRRRRRRRRRRRRRRRRR+++R####***##*******RRRR*+++RRRRRRR##*******
 * ++++*#########*****###*****RRRRRRRRRRRRRRRRRRRRRRRRR++RR####***#*******RRRR**+++RRRRRRR##*******
 * ++++*#########*****###*****RRRRRRRRRRRRRRRRRRRRRRRR*+RR####***##*******RRRR**+++RRRRRRR#********
 * ++++*#########*****###*****RRRRRRRRRRRRRRRRRRRRRRRRRRRR###****#*******[email protected]**+++RRRRRRR#********
 * ++++*#########*****####*****RRRRRRRRRRRRRRRRRRRRRRRRRRR##***********[email protected]***++RRRRRRR##********
 * ++++*#########******###******RRRRRRRRRRRRRRRRRRRRRRRRR##*****#*****++RRRRR**+++RRRRRRR##********
 * +++++*########******###******RRRRRRRRRRRRRRRRRRRRRRRRR************++RRRRR***+++RRRRRRR#********R
 * @++++*########******####******RRRRRRRRRRRRRRRRRRRRRRR*************+RRRRR****+++RRRRRRR#********R
 * @++++*#########*****####*******RRRRRRRRRRRRRRRRRRRRR*************+RRRRRR***++++RRRRRRR#********R
 * R++++**########******####*******RRRRRRRRRRRRRRRRRRR*************+RRRRRR****++++RRRRRR#*********R
 * R+++++*########******####********RRRRRRRRRRRRRRRR*****++*******+RRRRRR****++++*RRRRRR#*********R
 * R+++++*#########*****#####*******#RRR++RRRRRRRR+*+++++*******++RRRRRR*****++++RRRRRRR#********RR
 * RR++++**########******#####*******#[email protected]+++++++++++++*******+++RRRRRR******++++RRRRRR#*********RR
 * RR++++***#######******#####********#RRRRR++++++++******+++++RRRRRR*******+++++RRRRRR#*********RR
 * RR++++****#######******#####********#[email protected]++++++++++++++RRRRRRR*******[email protected]*********RRR
 * RRR+++*****######*******#####*********#RRRRRRRRR*++*++RRRRRRRRR********++++++RRRRRR**********RRR
 * RRR+++*******#####******######*********##RRRRRRRRRRRRRRRRRRRR**********++++++RRRRRR**********RRR
 * RRRR++*********###********#####**********###RRRRRRRRRRRRRR************++++++RRRRRR**********RRRR
 * RRRR++*********************#####************######RR####*************+++++++RRRRRR**********RRRR
 * [email protected]+**********************#####***************#*******************[email protected]**********RRRRR
 * RRRRR+***********************######********************************++++++++RRRRRR**********RRRRR
 * RRRRRR+************************#####*****************************+++**++++RRRRRR***********RRRRR
 * RRRRRR**********#****************####***************************+++**+++++RRRRRR**********RRRRRR
 * RRRRRRR*********##*******************##***********************++++***++++RRRRRR**********RRRRRRR
 * RRRRRRRR*********###**+++***********************************++++****+++++RRRRR***********RRRRRRR
 * RRRRRRRRR*********####*+++*******************************++++++*****++++RRRRRR**********RRRRRRRR
 * RRRRRRRRR*********######*++*******************************++++******+++RRRRRR***********RRRRRRRR
 * RRRRRRRRRR*********#######*++****************************+++*******+++RRRRRR***********RRRRRRRRR
 * RRRRRRRRRRR********##########++***********************++++*********[email protected]***********RRRRRRRRRR
 * RRRRRRRRRRRR********###########*********************++++**********++RRRRRR***********@RRRRRRRRRR
 * RRRRRRRRRRRRR********#############***************++++************[email protected]***********RRRRRRRRRRR
 * RRRRRRRRRRRRRR*********###############********+++**##***********++RRRRRRR***********RRRRRRRRRRRR
 * RRRRRRRRRRRRRRR*********###########################**************RRRRRRR**********+RRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRR********########################***************RRRRRRR*********++RRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRR*********#####################**************RRRRRRRR*********++RRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRR*********################****************RRRRRRR*********+++RRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRR*************########*****************RRRRRRRR*********[email protected]
 * RRRRRRRRRRRRRRRRRRRRRRR**********************************RRRRRRRRR*******+++++RRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRR****************************RRRRRRRRRR*******++++++RRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRR************************RRRRRRRRRRR*****+++++++*RRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*****************RRRRRRRRRRRRR*++*+++++++++*RRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*+++++++++++++RRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR*++++++++++++++RRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR+++++++++++++++RRRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRR**RRRRRRRRRRRRRRRRRRRRRRRRRRR*+++++++++++++++RRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * [email protected]@++++++++++++++++++RRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * [email protected]++++++++++*++++++++++++++++++++++++RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR++++++++++++++++++++++++++++*RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * [email protected]++++++++++++++++++++*RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
 * KODEX BYTE STORE
 */
contract ByteStore is AccessControl {
    bytes32 public constant ROLE_ADMIN = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant ROLE_MODERATOR = keccak256("MODERATOR");
    
    event DataAdded (
        bytes data,
        uint id,
        uint timeAdded
    );

    event DataChanged (
        bytes data,
        uint id,
        uint timeUpdated
    );

    event DataRemoved (
        bytes data,
        uint id,
        uint timeRemoved
    );

    event Manifest (
        bytes hash,
        uint timeUpdated
    );
    
    bytes private _manifest;
    address[] private _moderators;
    uint private _dataCount = 0;
    mapping(uint256 => bytes) public _data;

    string public name;
    uint256 public deployedBlock = block.number;
    uint public createDate = block.timestamp;

    constructor (
        string memory _name
    ) {
        name = _name;

        _moderators.push(_msgSender());
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(ROLE_MODERATOR, _msgSender());
    }   

    function addModerator (address moderator) public onlyRole(ROLE_ADMIN) {
        grantRole(ROLE_MODERATOR, moderator);
        _moderators.push(moderator);
    }

    function removeModerator (address moderator) public onlyRole(ROLE_ADMIN) {
        renounceRole(ROLE_MODERATOR, moderator);
    }

    function getModerators() public view returns (address[] memory moderators) {
        return _moderators;
    }

    function getModeratorsCount() public view returns (uint256 moderatorCount) {
        return _moderators.length;
    }
    
    function setManifest (bytes memory manifest) public onlyRole(ROLE_MODERATOR) {
        _manifest = manifest;
        emit Manifest(manifest, block.timestamp);
    }

    function getManifest () public view returns (bytes memory manifest) {
        return _manifest;
    }

    function getDataCount () public view returns (uint256 dataCount) {
        return _dataCount;
    }

    function hasData (bytes memory _hash) public view returns (bool, uint256) {
        for (uint256 i = 0; i < _dataCount; i++) {
            bytes memory candidate = _data[i];
            if (keccak256(candidate) == keccak256(_hash)) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    function getData (uint256 index) public view returns (bytes memory data) {
        return _data[index];
    }

    function addData (bytes memory _hash) public onlyRole(ROLE_MODERATOR) returns (bool, uint256) {
        (bool dataFound, ) = hasData(_hash);

        if (!dataFound) {
            _data[_dataCount] = _hash;
            emit DataAdded(_hash, _dataCount, block.timestamp);
            _dataCount++;

            return (dataFound, _dataCount);
        }

        return (dataFound, _dataCount);
    }

    function addMultiple (bytes[] memory _hashes) public onlyRole(ROLE_MODERATOR) {
        for (uint256 i = 0; i < _hashes.length; i++) {
            bytes memory candidate = _hashes[i];

            (bool dataFound,) = hasData(candidate);

            if (!dataFound) {
                addData(candidate);
            }
            
        }
    }

    function updateData (uint256 index, bytes memory _hash) public onlyRole(ROLE_MODERATOR) {
        _data[index] = _hash;
        emit DataChanged(_hash, index, block.timestamp);
    }

    function removeData (uint256 index) public onlyRole(ROLE_MODERATOR) {
        if (keccak256(_data[index]) != keccak256(abi.encode(0x0))) {
            emit DataRemoved(_data[index], index, block.timestamp);
            delete _data[index];
        }
    }
}