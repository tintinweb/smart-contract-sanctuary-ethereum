// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Provides the metadata for an individual ERC-1155 token
/// @dev Supports the ERC-1155 contract
interface IMetadataProvider is IERC165 {

	/// Returns the encoded metadata
	/// @dev The implementation may choose to ignore the provided tokenId
	/// @param tokenId The ERC-1155 id of the token
	/// @return The raw string to be returned by the uri() function
	function metadata(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OnChainMetadataProvider.sol";

/// @title FuckNormalV2
contract FuckNormalV2 is OnChainMetadataProvider {

	/// @dev Constructs a new instance passing in the IERC1155 token contract
	/// @param tokenContract The IERC1155 that this OnChainMetadataProvider will support
	// solhint-disable-next-line no-empty-blocks
	constructor(address tokenContract) OnChainMetadataProvider(tokenContract) { }

	/// @inheritdoc OnChainMetadataProvider
	function svg() internal override pure returns (string memory) {
		string memory results = "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg'><rect width='100%' height='100%' fill='#000'/><g transform='translate(155.786,169.006),scale(0.01)'>";
		results = string.concat(results,
			_whitePathSimple(hex'a7689c27a75e9fbca703a40ea51aa8069f51b4129267b60c8842af3a8573ad5782e5ab2b819ea7cf7f47a1a681509971866b9536876c9448884a933588fd92088a05906c8b768f1e8d298e408edd8d6290c48cfc92ac8d1897b78d369cab8de4a10b90b0a4ea9339a73f96a9a7689c27'),
			_whitePathFull(hex'4d0bb86486430bc75fe30bcf5b420c5056a4430c7855fa0c7655480c4b549f430bc3551e0b6a55c80b5056814309d85b7408a8607b07c3659143075a682006d96aa6064e6d2d43062a6dd106206ed9050f6ea54303ff6e7004026d7a042a6c9b43052b671d063e61a207975c344308ab57da09cb53860bf44f8c430c544ed80c9f4e040dad4e56430e1e4e710e804eb50ec24f14430f044f740f1f4fe90f10505b430edc52c50e97552f0e615799430dd55ca10dcc61b30e4566bd430e5667510e3f68420ee86859430f6768680f8767780fbb66f343114d62ea122b5eaa13895a9243163b527a19014a681bbf4254431be441e71bef413c1c87414d431d1f415e1d1e42101d274293431d4244601c6545f31bfb479f431ab04cc4189c51b616ea56bf4315635b7f1419605512c86528431249670a11a768e310e56aaf43108c6b8110126c370f146c26430e996c240e226bfb0dbf6bb2430d5c6b680d136b020cee6a8d430c39689d0bd166950bb864865669b05a'),
			_whitePathFull(hex'4d2da601fc432a3102a626cc039c238104dc431edc06971a54089115cb0a8f4314480b38137d0c1213510dca4312da12091223163f112d1a684311101ae510b11b8f111d1be243118a1c3512141ba9128c1b764318b118cc1f1a16ce25ac158443266615652721155027dd1546432847154028c7152828db15c44328f0166028711676280c1691432654170b2495177322dc17f0431cf5198417381ba911b91e554311451e8710df1ed710931f3c4310471fa11016201810052096430f0026230e652bc10e363166430e3032220e1c32df0e06339a430dee346e0d94350e0c9a34dd430c6734d90c3534ca0c0834b0430bdb34970bb434750b95344b430b7734210b6233f20b5733bf430b4d338d0b4e33590b593326430c532d720c33279a0d8121e9430da921450dd220ad0cf42030430c171fb30c2a1ecd0d141e56430e501dbb0e8d1cb30ed11b87430fbe1732108f12d711230e774311320e0711810d7211040d274310a60cef10400d610fde0d86430eef0ddd0dbc0eeb0d280d83430ca40c460e3b0c200f050ba743103f0aea11de0aae123908ee431249089c12a8085212f2088c431446098f155b088b1672080e431c85054322c802e6293100fd432a9200a42bf7005c2d5f0028432dff00002ea700182f35006c432f9c00af300d00f92ff20186432fcf022b2f3c02012ec902044c2da601fc5a'),
			_whitePathSimple(hex'548443d1548145c554ce47b65566499255c24a9e56484ab556e049c55797488b5827473b588c45de598942da5a8d3fdc5b973ce65bc53c5e5bea3bb35cab3bb55cfd3bb85d4c3bd25d903c005dd43c2d5e0a3c6c5e2c3cb75eca3de35f103f365ef640895ed344fa5f1c49805e214de45da150275cfe52655c5e549d5c3255415bd955e95b0c55a15a3e55585a3e54b45a5e540b5a7a535e5aa452b45adb520d5ce04c535cf446605ce6406a5ce3402b5cd13fb95cbb3fb75c4c3fa85c4e401a5c3840615b7e42b15aba44fe5a174754599a48fe58f04a9a581c4c2157334de855cd4dfb54a44c5553414a5152e347f65289459d5285455a52814515527344d3524e443352b1433a520b430351ad42e3516143f5511e44844f9548184e554bc84d5f4f8e4c6f52e64c0b56604acb59a54a8c5a4b4a5e5afb497e5afd49255b0148cd5ae848855ab5483c5a8248065a3847ed59e3479d591b47885845486157ca48ae579448f1574f49245700495756b0497a5657498a55fa4acb522c4b7b4e374cc14a6a4ded46ea4f15436b50ef403451463f9d518e3edb52603eee52ce3ef853353f2753853f7253d63fbd540b4020541d408d544e41a2547042b9548443d1'),
			_whitePathSimple(hex'b0815a7db09f5c9eb0795ec1b01060daafed6171afd66208af1b621baec96221ae77620dae3261e2adec61b6adb76175ad996129ad18603dad2e5f38ad305e39ad355c98ad455af6ad525955ad4d5905ad7558a0ad2b5872acbc582eac8c58a9ac4958e4aaeb5a49a9bc5bd8a8c15d89a51c6362a17069389ec06f9a9dc171b49d5374079d8376599d8f77479de8782b9e8178e29f1a79999feb7a19a0d37a4fa2287aaba38c7abba4e77a7ea6437a41a78c79b9a8ae78f0ab2a776cad46755daed972eaaf197282af6171ffafef724bb07e7297b01d7313b0017373afc27488af4c758daea37672ab157ab1a6e97d77a1107c509f3c7bf29d9c7ae89c8279659b6977e39aec76059b24742b9b5571f69bf26fd09cf16dd5a08a66cda4815ff6a8d25959aa105770abd95629ad9754d2ae6a5431aef654f6af4355a9affd572cb06958d0b0815a7d'),
			_whitePathSimple(hex'31c5a36e31f1a0ab32539deb32e99b3733e19616344f90e234d18bb434df8b1f34f28a8c350589f935188966352f889b361588b9366e88be36c288e537008925373f8966376289bb37648a1437648a82375b8aef374a8b5a36e78ece36809242362495b73619961735c296a3364296d936c2970f36fe96833747963b3a30935f3c82900a3eec8cc6407f8aa4418a882f42a385d342d18563430984f8434b8492435d846d4378844d4399843443b9841b43df840a44078401442f83f8445883f84481840144a9840a44ce841c44ef8435451684494538846545538487456e84a9458184d1458c84fb4596852645978552458f857d458685a7457585d0455c85f342758c0d3e9f91aa39fd969538f897aa391c98043a5998ce3e5c9b59406f9f3e4163a3cd418ba48d4150a5404071a555403ea55b400aa5563fd9a5453fa8a5353f7ba51b3f55a4f83f2fa4d53f11a4aa3efea47a3eeaa44b3ee1a4173ee3a3e43eafa1ff3e14a02b3d1d9e863bb29c0739ff99dc36d1999135fa997e358f99c135689a9e34cd9e0933f8a16d3426a4f03430a59f343da6743350a68f3263a6aa3226a5d631ffa51931e6a49c31dfa42231c5a36e'),
			_whitePathSimple(hex'69190557686e081d67c30afa670f0dd766990fae6610117f659b1356658013c56519145e658214a8660615066671146166d6141869f411dc6c050eb96df10b856f65090370b5066e71e203c8722a032d725802047375027f749202fa744f03d273e304c0720808c56fe70ca76d8310606c4612576ab5141468e3158567fb163f680116b268c317836aa019876c371bc76d7d1e356e4f1fa26ead21476e8822eb6e7523996e6724686d7724656d4624676d15245e6ce8244c6cbb24396c93241c6c7323f76c5223d36c3b23a76c2e23786c2123496c1e23186c2722e76c821e2d69801b386699183f654016dd64851731641c190763b21add63431c9c62ca1e64629a1f18625b1ffd61601fb460651f6b60521e9560951da562e9157e64f20d4466d8050166fa046f66f3038e67d1039e68af03ae68ed047569190557'),
			_whitePathSimple(hex'3f3d5c8a3f0359a73dad56f73b82550a3a9d544f39c75383390252a737b2511038004fd239c74ece3c6b4d6c3e814b2d3fae48703fe048014004478d401c471640344673407145c03fdc454f3f4644de3eb645503e3b45933a3947cd371c4aa036594f8b35a1542a346b58b533735d4c33405e4732dc5ee131c05e8e30a45e3c30955d7530cb5c8c322656ce337d511134d04b5534df4b1334ea4ab935184a9b37cf48d1396745bb3c6d444b3df343923f7e428b412143d242c3451a425e470041db48c240e64c183e924e5c3bd350383a7951243a9a51d33bb852b93eb2551f40b9581941565bf1417c5c9241795d39414e5dd841225e6b40dc5efb40195ee43f575ece3f365e3e3f355d9b3f3c5d573f3d5d133f3d5c8a')
		);
		results = string.concat(results,
			_whitePathFull(hex'4d3057246b433054219730a61ec5314a1c0443321b183432ec146533ca10984333f00ff333f00ee134f90f194336010f513630102935f811354334e7164133771b3a32cc205b43328c2245324a243b32dd2628433390287934ed28e636a927334339cf24243be7205c3d861c52433fc316fb4187117442cc0bcd4342de0b7942cf0aea43540b054343800b0c43aa0b1c43d00b334343f60b4a44170b6944320b8d43444c0bb1445f0bd944690c054344740c3044750c5d446f0c894344560d9544240e9f43d90fa143426614be40ae19c73eb21eb5433d3d22283b4e256338f5284d4337c529b936772ad134802a6243328929f23165287b30c626a643309225ea306d252b3057246b5629955a'),
			_whitePathSimple(hex'4e1623e8481f244b456720fc46b41b9147751869492715c24af413294ccc10564ed60da5510c0b1951e00a2252dc095153f408ad544d087354b40854551d08525587085055ef086c564908a356a408d956ed0928571d0986574c09e457610a4e57570ab757420d0a56c30f5455e1117b5597122b552d12dd544012a653dc12905383125a5344120b530411bc52e1115952e210f452c30f88535c0e4653b90cf653da0c84543f0bd153f30bae537c0b7353140c1852c20c744fea0fa44d6013174b2b16bf49d718d848f01b3048841da248172064495221e74c1d21f44f552203523020c854ea1f3b56791e5957f91d57597e1c6e59d41c3b5a3c1bd05a9d1c3c5aff1ca85aab1d275a5b1d8558d21f1e570b20775517218452cc22cf505f23d74e1623e8'),
			_whitePathFull(hex'4d756837b343756339db755a3c0375583e2b4375583ef475533fb4766540024377284037771740fd769141604375694230759e434875d1445c43761d45cf763d474b763048c643762349b775f24ab074b04a8543736e4a5b739a497073d04878437422470373ce458973b7440a4373ad4354734f432672a8434b43715343976ffc43e46ea54422436dbd444d6db145006d8f45a9436d0348576c734b066bf44db5436bca4e9c6b664f176a7b4ee4436a484ede6a184ecc69ed4eaf4369c34e9369a04e6c69874e4043696e4e1369604de1695f4dae43695d4d7b69674d48697d4d19436b7247ce6c0f42236e263ce1436f123a927000384c71913657437228358f72df34df73f6355443746c358574ce35db7511364843755336b575723734756837b3563cdd5a'),
			_whitePathSimple(hex'83674224849441b285c6414586f240cf8a983f728e593e61922b3d9d92ff3d6d93c53d75944e3e3694813e77949b3ec794993f1994963f6b94763fba943f3ff793a840b492f240c092004074906e3ff38ee240a38d5f40fd89d541d586894360831e44a4826b450381a2453380d7452e7f7345007ee643f87f7a42b082893bef8593352a88642e4d88a52da788f42d0d893f2c70897e2bf389d32b798a7a2bc58abb2bdc8af12c0a8b132c468b342c828b3e2cc98b2f2d0c8afc2ddd8ab72eaa8a612f6f880634f285a83a7583463ff88317406582ed40d882b74144827941f7827f426083674224'),
			_whitePathSimple(hex'61c889d761e58b2762188c7662618dbf627f8e3e62678f0362fa8f1563ae8f2463b18e4a63e28dc264fc8ae664ef87e0653784e4655f8346656f81a46590800365977f9a65827f1a66247f0d665a7f0966917f1866be7f3766eb7f56670d7f83671e7fb7674a801967618083676180ee672884b566ee887e66a18c4466778de665f68f79652790e664c191a864689273636792816265928e61c891e561419121610890cc610c904a60909029607e908f606890f56057915c602392fa5fcf94945f5b96255f0d971d5e82979a5d7b97415c7396e95c8b96325cde95595e18922a5e718ed25ea08b725eb689fb5ef188845f13870d5f2586605f4985c6601d85b9604985b2607685b360a285be60cd85c860f685db611a85f5613e860f615c863161738657618a867d619986a761a086d361bb87d461c988d561c889d7'),
			_whitePathSimple(hex'2371624b201c62731de1606a1e295d1f1e93585f20a2544323b050a724804fb325974f4626c250202744508227a9510c269e514e25935190260351d3268e52392a0154b22b14582c2a7c5c302a0a5f31267762262371624b'),
			_whitePathSimple(hex'59be8be959df8eeb59b891bc589f946e5839956957e096845694968a55479691545895af53eb9477538c936e535592575304914852eb90f85325907852a5906752909068525a91025247915951e19336520e951f51db970051bd980c519f9918517b9a2251629ae3510e9b7f502b9b594f499b324eb69ab14eea99d34fe495aa4fe0915b50e88d35511c8c61515e8b7a526d8b7452e28b7553528ba053ab8beb54048c3754418c9f54558d1254c98eaf550f905b557591fc55939277557e934c5605935456b3936056b7928356e0920257f18e9d580f8b15585b87935861874557df86c7588186b158f586a0593a8719594c87885987890059f28a7e59be8be9'),
			_whitePathSimple(hex'92427a9c923377c4923377e08f5977fc8df378098dbc78868dd279c28de17b568dd97cea8dba7e7c8db07f298d917ffc8cb180068bb780158b8b7f3c8b897e768b817c858b867a948b8378a28b7077018b3c75628ae773c88acf733d8a9b72888b59724b8c16720e8c8572998ce273248cfe73528d1473848d2573b78d6874668d03757f8e1575aa8f6675db90bd759a91e574f2927374a4926173ec9264735b9271718492736fad92776dd692786d4192646c9393226c6e937a6c5e93d56c71941f6ca2946a6cd4949f6d2094b26d7794ed6e5594ff6f3b94e5701f94de71af94727344952b74c7953574d9953a74ed953b7501953c75169539752a9532753d93da777794bb79db94af7c2b94ab7cf694ca7ded93ab7df4928c7dfb92597d1d92557c3092577ba9924a7b2392427a9c')
		);
		results = string.concat(results,
			_whitePathSimple(hex'71278dca6dd78dfc6c378c6d6c4d89ba6c6187496d2084f76db4829e6def81af6ee681556f9880ca71077fb372af7ef174717e91752c7e6575e47e88761f7f54765a8020758b803e7514807473c280fc727e81a3714b826870c882c77059833f700483ca6fb084546f7884ee6f60858e6f4f85da6f2186416f7b86666fc8867570188665705a863a7189858672b184d273dc841e745a83d074db835875578408757184287583844d758e84747599849c759c84c5759784ee759285167584853e756f8561755a8584753f85a3751e85bb738f872971be88476fc389036ece89576e6689ab6ea58aa06eea8bac6fb28beb709b8ba672728b1973c289ca750988717568880c75898703765b8782772d880176fc88d77690897e751b8bb5734b8d7871278dca'),
			_whitePathSimple(hex'43079b16431798b943ad9627441a9390443592e1447d92464356929b431292ac42cb92a14290927e4254925b42299221421891de420891a2420e916242289129424290f1426f90c342a890a844f98ed5478e8d5d4a4f8c4d4aee8c184b888c194bcc8cbf4c108d664b6a8d8b4b0a8dc849868ebb47fb8fa54678909545db90f34566915d463992004666921e4685924d469092834690951f47db939748c99336497792f04a2292a04ad2925b4b3392354ba891fa4bec92824c3093094bcd93674b5a93a64a47944d492694e3481895924774960646d996854647970e462a971f4611973745fe975445ec977145e0979145dd97b345d997d545de97f845eb981845f79838460b98544624986b46b1990546f4997745ee99f344e79a7045529b7545959c2f45e79d1546ab9cc147529c7648589beb49439b324a079a534a549a074aab99b64b219a004b4f9a1e4b719a4b4b829a7e4b949ab14b949ae94b839b1d4b1c9d3a47729f6a45639ec543f79e55431d9d1543079b16'),
			_whitePathFull(hex'4dba2a6a8e43ba636d84b9196f16b71c704b43b4ff7194b2d971d0b0ac70a143aff0703eaf5a6fa0af016edf43aea76e1fae8f6d46aebc6c7743aef86ac1afa86924b0bb67cb43b1cd6671b3386568b4d464cb43b65e6422b7e064d4b8f0668943b9a367c5ba0e6924ba2a6a8e566fb85a'),
			_whitePathSimple(hex'01c7afc70118afd10081afae0040af110000ae740092ae1b0108ade60980aa2a119da5991a88a2e51b27a2b31c2fa2151c7ca2f01cc0a3af1ba1a3fc1affa44012c9a7b10accab9c02c0af65026baf900210afaa01c7afc7'),
			_whitePathSimple(hex'bb6e68dfbb9565f6bc53631ebd9e6081be035fa3be6d5ecabedf5df4bf295d66bf7a5cb5c04b5d1ac0765d2dc09d5d49c0bd5d6cc0dd5d8fc0f65db8c1055de5c1155e12c11b5e41c1175e70c1135ea0c1065ecec0ef5ef7c0895ff1c00860dfbf9e61d5beb263bbbe1265c2bdc567d9bda36931bdb36a85bf086b59c05c6c2dc1786ba6c2956af8c3406a90c3e06a11c4826996c4d96957c52e68f9c59d6955c60c69b1c5de6a19c5c26a82c5466c44c25d6e1dc0596deebf106dcebddd6d3abcf76c4dbc106b60bb856a29bb6e68df'),
			_whitePathFull(hex'4dc52f65c543c539641ec58e627dc62b60f443c64f608dc695601ec705601743c8486004c9405f35ca585eb843cac25e89cb325e26cb9b5ea543cc045f24cbc15fa1cb82601843cb0c60fdca0b6145c96461f343c9326228c8b0624ac8e6629d43c91b62efc977628cc9c0627443ca09625cca3a6239ca79622543cae66200cb65619ccbbf623243cbe76273cbf562c0cbe6630a43cbd66354cbaa6396cb6b63c043caa6647bc9af64fac8a5652e43c8376535c7c66547c7b365d343c7a66608c7a8663fc7ba667343c7cc66a6c7ec66d3c81666f543c87f6740c8e6670ec94466d843ca11666fcac465dbcb53652643cb9264d0cbbe6428cc5e648043ccd264bfccda6548ccd765bd43ccd0672ccade692dc937697d43c8736996c7ac696bc704690443c65c689cc5dd67fec59b674443c56e66c7c54a6647c52f65c5566aef5a'),
			_whitePathFull(hex'4d85ba753243865b751a86ef753a871675f243873c76ab869876cb862176f94383ee77d581b578a57f827984437d967a3e7bcd7b4a7a3b7c9c437a167cc079ea7cdb79ba7cec4379897cfd79567d0379237cfd4378ef7cf878be7ce778927ccd4378677cb278417c8e78257c644377777ba578127b20789e7ab7437a5279647c3678537e3a778f4380ac769c832e75d285ba7532567a5c5a'),
			_whitePathSimple(hex'82e17eb882de808382c3824e828f8416826d850a822485f480f085bf7fbc858a7ff084b1800e83c5807080cd80f97dd37fe87ae87fc37a7a7fbe7a10803179c9806079af809779a480cd79ac810379b3813679cc815c79f281ff7a6f826b7b26828d7bf082b27cd482c47dcb82e17eb8')
		);
		results = string.concat(results,
			_whitePathFull(hex'4d9fcc3e2d439fc63f079f683f929e933f93439d913f939d133ee29ce53dfe439cd93dd69cd63dab9cde3d82439ce53d599cf63d329d103d11439d293cef9d4b3cd59d713cc3439d973cb19dc03ca99dea3caa439e5d3ca19ecf3cc39f293d0c439f823d539fbd3dbb9fcc3e2d5643575a'),
			_blackPathSimple(hex'9462b1068ebeb143898aaef0858aaa54820ba64d824aa18983f19cbf84029c8f840b9c49844e9c55845e9c5484699cb684649ce9841e9ee5840ca0e7842ea2e68433a3468439a3a38448a4018460a4a1849ba56f8553a55b860ba54685e7a46c85dfa3e485a59f9c866b9b568823976988819678893395b18a19953b8d4793a9907b926094029446949294959541948b957f93e595d792f99517927894689247925391b6903891308e0791ae8d7191cf8c83924e8c5191c78c1f91408d0190bd8d8d905a8fbc8eca92378e8c94cb8ec099d28f279e9f901da2499405a34094f6a4049615a48a9753a5109891a55699e6a5569b3fa54da00ca4cea4bfa208a8dc9ee5ad889ac4b0a69462b106'),
			_blackPathSimple(hex'735b395373393b66733e3d7a73693f8d73764071732540fc724741207121414d6fc142466ee441656e3740b26f4b3f806f903e8570243c8f71013ab1722138fb725e3898729037e973063806737d3823733638d6735b3953'),
			_blackPathFull(hex'4d289b589a4328d35c51266b5fb4236460344321656089206f5fd820685dd84320725b40212258b4226856704322b655d52312553f236c54a843243d53572595531726b0543943274954c927c455772818563843286d56f8289957c8289b589a565dc45a'),
			_blackPathSimple(hex'b80f6a1fb8ba6d40b49d6f94b26d6f24b2086f18b1ab6ee7b1686e9bb1246e4fb0ff6dedb1006d87b0c96b2fb2ce685ab52667c7b54067c5b55c67c4b57567b5b75f66f6b7a76729b7f86957b807699bb80b69dab80f6a1f'),
			_whitePathFull(hex'4da012a10343a035a2049ffba3089f6fa3e2439ee4a4bc9e0fa55d9d17a5a8439957a6e795bda891925caa9e4391b5ab1190faab629034ab8e438e8dabcf8d1aaacb8d2fa927438d64a4e58dcea0a68d8e9c61438d839ba58e199b588eb39b0b4392b6991296a396ec9ad1954e439c1694d19d63946c9eb6941f439eeb94119f23940f9f599418439f8f94229fc294379fef945743a01c9477a04294a0a05d94d043a07994ffa0899534a08e956b43a0c19665a00b96b79f3c96c4439e2696de9e0097629e429861439f0b9b379fa79e1aa012a10356a62d5a'),
			_blackPathSimple(hex'9d649f799da3a2de9da8a2ee9b2ba3e797c2a52f9470a6b2913ca86f9025a90b8fc5a8d18fd7a7889019a48b9030a18b901a9e8b90189e3a902e9dea90599da590849d6090c29d29910c9d0894019b199728997d9a7498399bbf97c09bfb989c9c2999649cae9ba99d149df29d649f79'),
			"</g></svg>"
		);
		return results;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../interfaces/IMetadataProvider.sol";
import "../utils/BespokeStrings.sol";

/// @title Base On-Chain IMetadataProvider
abstract contract OnChainMetadataProvider is AccessControl, IMetadataProvider {

	/// Defines the metadata reader role
	bytes32 public constant METADATA_READER_ROLE = keccak256("METADATA_READER_ROLE");

	/// @dev Constructs a new instance passing in the IERC1155 token contract
	/// @param tokenContract The IERC1155 that this OnChainMetadataProvider will support
	constructor(address tokenContract) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setRoleAdmin(METADATA_READER_ROLE, DEFAULT_ADMIN_ROLE);
		grantRole(METADATA_READER_ROLE, tokenContract);
	}

	/// @dev returns the raw json metadata for the specified token i
	/// @param tokenId the id of the requested token
	/// @return The bytes stream of the json metadata
	function contents(uint256 tokenId) internal virtual view returns (bytes memory) {
		string memory encoded = Base64.encode(bytes(svg()));
		// Tier should be 1-4 (this is intentional for our four subclasses and designed to not revert in any case)
		unchecked {
			return abi.encodePacked("{\"name\":\"", "The Normal Series Tier ", Strings.toString(tokenId - 3), "\",\"image\":\"data:image/svg+xml;base64,", encoded, "\"}");
		}
	}

	/// @inheritdoc IMetadataProvider
	function metadata(uint256 tokenId) external view onlyRole(METADATA_READER_ROLE) returns (string memory) {
		return string.concat("data:application/json;base64,", Base64.encode(contents(tokenId)));
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public view override(AccessControl, IERC165) returns (bool) {
		return interfaceId == type(IMetadataProvider).interfaceId || super.supportsInterface(interfaceId);
	}

	/// Generates the on-chain SVG
	/// @dev Subclasses must implement this function
	function svg() internal virtual pure returns (string memory);

	/// Renders the path element using the provided data and fills with black
	/// @param path The bytes representing all operations in the path element
	/// @return black A path element filled with black
	function _blackPathFull(bytes memory path) internal pure returns (string memory black) {
		black = string.concat("<path d='", BespokeStrings.fullPathAttribute(path), "' fill='#000'/>");
	}

	/// Renders the path element using the provided data and fills with black
	/// @param path The bytes representing all operations in the path element
	/// @return black A path element filled with black
	function _blackPathSimple(bytes memory path) internal pure returns (string memory black) {
		black = string.concat("<path d='M", BespokeStrings.simplePathAttribute(path), "Z' fill='#000'/>");
	}

	/// Renders the path element using the provided data and fills with white
	/// @param path The bytes representing the M and C operations in the path element
	/// @return white A path element filled with white
	function _whitePathFull(bytes memory path) internal pure returns (string memory white) {
		white = string.concat("<path d='", BespokeStrings.fullPathAttribute(path), "' fill='#fff'/>");
	}

	/// Renders the path element using the provided data and fills with white
	/// @param path The bytes representing the M and C operations in the path element
	/// @return white A path element filled with white
	function _whitePathSimple(bytes memory path) internal pure returns (string memory white) {
		white = string.concat("<path d='M", BespokeStrings.simplePathAttribute(path), "Z' fill='#fff'/>");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title BespokeStrings
/// @dev Custom strings library that is separately unit tested
library BespokeStrings {

	/// Returns the entire path d attribute described by the stream of input bytes
	/// @param path Computer-generated stream of bytes that represents the entire d attribute
	/// @return string containing the entire path element's d attribute
	function fullPathAttribute(bytes memory path) internal pure returns (string memory) {
		unchecked {
			string memory dAttribute = "";
			uint index = 0;
			uint stop = path.length;
			while (index < stop) {
				bytes1 control = path[index++];
				dAttribute = string(abi.encodePacked(dAttribute, control));
				if (control == "C") {
					dAttribute = string.concat(dAttribute,
						BespokeStrings.stringFromBytes2(path, index), " ",
						BespokeStrings.stringFromBytes2(path, index + 2), " ",
						BespokeStrings.stringFromBytes2(path, index + 4), " ",
						BespokeStrings.stringFromBytes2(path, index + 6), " ",
						BespokeStrings.stringFromBytes2(path, index + 8), " ",
						BespokeStrings.stringFromBytes2(path, index + 10)
					);
					index += 12;
				} else if (control == "L" || control == "M") {
					dAttribute = string.concat(dAttribute,
						BespokeStrings.stringFromBytes2(path, index), " ",
						BespokeStrings.stringFromBytes2(path, index + 2)
					);
					index += 4;
				} else if (control == "H" || control == "V") {
					dAttribute = string.concat(dAttribute,
						BespokeStrings.stringFromBytes2(path, index)
					);
					index += 2;
				}
			}
			// require(index == stop, dAttribute);
			return dAttribute;
		}
	}

	/// Returns the d attribute between M and Z
	/// @dev Simple path consists of one M followed by repeated C's
	/// @param path Computer-generated stream of bytes that represents the d attribute
	/// @return string containing the text between the M and Z characters
	function simplePathAttribute(bytes memory path) internal pure returns (string memory) {
		unchecked {
			// Simple path starts with M
			string memory dAttribute = string.concat(
				BespokeStrings.stringFromBytes2(path, 0), " ",
				BespokeStrings.stringFromBytes2(path, 2)
			);
			uint index = 4;
			uint stop = path.length;
			while (index < stop) {
				dAttribute = string.concat(dAttribute,
					"C", BespokeStrings.stringFromBytes2(path, index),
					" ", BespokeStrings.stringFromBytes2(path, index + 2),
					" ", BespokeStrings.stringFromBytes2(path, index + 4),
					" ", BespokeStrings.stringFromBytes2(path, index + 6),
					" ", BespokeStrings.stringFromBytes2(path, index + 8),
					" ", BespokeStrings.stringFromBytes2(path, index + 10));
				index += 12;
			}
			// require(index == stop, dAttribute);
			return dAttribute;
		}
	}

	/// Converts a 2-byte number within a bytes stream into a decimal string
	/// @dev This function is optimized and unit-tested against a reference version written in pure Solidity
	/// @param encoded The stream of bytes containing 2-byte unsigned integers
	/// @param startIndex The index within the `encoded` bytes to parse
	/// @return a decimal string representing the 2-byte unsigned integer
	function stringFromBytes2(bytes memory encoded, uint256 startIndex) internal pure returns (string memory) {

		// Pull the value from `encoded` starting at `startIndex`
		uint value;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			// Load 2 bytes into `value` as uint from `encoded` starting at `startIndex`
			value := shr(240, mload(add(add(encoded, 32), startIndex))) // 240 = 256 - 16 bits
		}

		// Create the byte buffer -- optimized for a max of 5 digits, which represents any 16 bit number
		uint digits = value > 9999 ? 5 : value > 999 ? 4 : value > 99 ? 3 : value > 9 ? 2 : 1;
		bytes memory buffer = new bytes(digits);

		// Convert each digit to ascii starting from the least significant digit
		// solhint-disable-next-line no-inline-assembly
		assembly {
			for {
				// Calculate the starting address into buffer's data
				let bufferDataStart := add(buffer, 32)
				// Initialize the pointer to the least-significant digit
				let bufferDataPtr := add(bufferDataStart, digits)
			} gt(bufferDataPtr, bufferDataStart) { // While pointer > start index (don't check `value` because it could be 0)
				// divide `value` by 10 to get the next digit
				value := div(value, 10)
			} {
				// subtract the pointer before assigning to the buffer
				bufferDataPtr := sub(bufferDataPtr, 1)
				// assign the ascii value of the least-significant digit to the buffer
				mstore8(bufferDataPtr, add(48, mod(value, 10)))
			}
		}

		// Return the bytes buffer as a string
		return string(buffer);
	}
}