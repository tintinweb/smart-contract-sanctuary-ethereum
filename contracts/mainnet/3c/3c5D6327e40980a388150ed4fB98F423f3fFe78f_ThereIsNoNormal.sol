// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../interfaces/IMetadataProvider.sol";
import "../utils/BespokeStrings.sol";

/// @title Base On-Chain IMetadataProvider
abstract contract OnChainMetadataProvider is AccessControl, IMetadataProvider {

	/// Defines the metadata reader role
	bytes32 public constant METADATA_READER_ROLE = keccak256("METADATA_READER_ROLE");

	/// @dev Controls the reveal
	bool internal wenReveal_;

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
		if (wenReveal_) {
			string memory encoded = Base64.encode(bytes(svg()));
			return abi.encodePacked("{\"name\":\"", "The Normal Series Tier ", Strings.toString(tokenId+1), "\",\"image\":\"data:image/svg+xml;base64,", encoded, "\"}");
		}
		string memory image = "ipfs://QmdAcHWafrfQcaTW2sv2rurJGHGzK3gQHSLthQx5U1RgLJ";
		return abi.encodePacked("{\"name\":\"The Normal Series (Unrevealed)\",\"image\":\"", image, "\"}");
	}

	/// @inheritdoc IMetadataProvider
	function metadata(uint256 tokenId) external view onlyRole(METADATA_READER_ROLE) returns (string memory) {
		return string.concat("data:application/json;base64,", Base64.encode(contents(tokenId)));
	}

	/// Wen the world is ready
	/// @dev Only the contract owner can invoke this
	function revealTokens() external onlyRole(DEFAULT_ADMIN_ROLE) {
		wenReveal_ = true;
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

import "./OnChainMetadataProvider.sol";

/// @title ThereIsNoNormal
contract ThereIsNoNormal is OnChainMetadataProvider {

	/// @dev Constructs a new instance passing in the IERC1155 token contract
	/// @param tokenContract The IERC1155 that this OnChainMetadataProvider will support
	// solhint-disable-next-line no-empty-blocks
	constructor(address tokenContract) OnChainMetadataProvider(tokenContract) { }

	/// @inheritdoc OnChainMetadataProvider
	function svg() internal override pure returns (string memory) {
		string memory results = "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg'><rect width='100%' height='100%' fill='#fff'/><g transform='translate(110.362,133.973),scale(0.01)'>";
		results = string.concat(results,
			_blackPathSimple(hex'b9749bb4baf99b99bc809bdebde39c7fbf479d1fc07e9e16c16b9f4cc286a0c4c3d9a20fc559a321c93fa5b9ca10a986c981adc9c913b0f7c7d0b3f9c5d9b683c3a2b94fc10abbc9be23bddebc2bbf3eb9d2bff6b76bbfeeb373c01eaf7fbf54abe8bda0a6fabb38a459b5f2a4edb04aa566abaca759a7b5aa0ba409aa4fa3a0aaa7a345ab0da2fcace9a1cdae86a045afce9e7ab1329c9cb3599c56b5699bfdb6c59bc4b81a9bc4b9749bb4'),
			_blackPathFull(hex'4d1e037fad431bfa7f8a1b7c7eb71bfc7ccd431cc979c41e0676e31f0f73ed4320f46e8922c6691d258e64114326ac62062845604e292e5e27432ab85de82b305ee32b4f6002432b7b61912b8c63222b8364b2432b616a012c016f432c58748b432c7576572c5878262c5879f64c2cbd7a05432dce77392ee7746f2fef719e4332216b7934c7657f37da5fbe433a905ae53db6564d4141520643446e4e2147d94a5e4c084771434cb146f14d7946a14e4c468b434cdd484a4b4649e7498b4b5c4344855008402d55613ca45b4143363e6589323570cb2e717c2f432e1a7d362da77e322d447f34432d277f8c2cf07fdb2ca68014432c5d804d2c03806f2ba68074432a4780282a107f122a107ddc432a107a4c2a2c76b92a10732a4329ed6df9294768d3295c63a243294e6332293662c3291662564325cb66e023d86b9e224470914320b075841e637a4a1e037fad5a'),
			_blackPathSimple(hex'1d491f4c1498236a0c14277004ee2dbc04982df3044f2e3c04192e9303e22ee803be2f4903b12faf03462feb02e030300280307c023130c701f831220182313d0017303800002f4b01352deb031b2bbd05782a1707d2287b0db9249013e921181a541e1a1afb1dce1b921d741c231d2b1c7c1ae81cc119cc1ffb1b63236b19ed26f0186c2a7916ef2c1216492cc616b42ce7189a286e19fe24161bc11fe91ddf1f242c131a2b38ea151f45bc1478476c13d2492d12854a7911f04ab411854a92110c49ea17223c651c292e6e1d491f4c'),
			_blackPathFull(hex'4da9b06efe43a7e37075a6fe721ea60973b843a31b789ca09d7daf9fa38361439f5e84d09f4f86479f7687bb439fdd8af9a22a8ccca56b8c9243ab178c29af758935b370857943b41f84d3b4a783fbb59d83ad43b644843cb5de84c2b59d852943b2a08a0aab978ef0a4cf8e94439fc58e529cbe8a5f9d348510439dc37ea9a0737908a387738d43a4af716aa60b6f64a7956d8343a8696c94a96b6bd3aa8b6b4b43abad6ab9acd26b1cad146c3543ae2670b7af39754aad9179e343ad6e7a2aad417a6dad0d7aa943abae7afcab1a7a26aab0792743a9b776eba9ae7489a9ae72284ca9b06efe5a'),
			_blackPathSimple(hex'b9f40000ba7e0065ba3d00dbba290154b9c103cab88b05dfb74f07fcb3980e52b04d14e1ad231b81ab881ecea9b52200a7ac250fa751259ca6e825ffa63825cca5df25b6a5912580a55d2535a52824eaa511248ea51c2433a53620cfa4de1d64a5a21a08a5e2190fa5e9180ca5b81711a4451a84a2cd1df4a1612172a00d24f09e7f28579cbc2ba29be02bca9b6f2b7b9aec2a88a0002184a368177ea7bb0deba9530daba9ae0e92a9ae0fb2a9861142a93712cca8c2144ca7d517b1a7351b2ba6e71eada6ba1fb3a6f620c1a78d219dae14166cb3150abab9f40000'),
			_blackPathSimple(hex'528eb9435135b98250e9b89d50afb7b35029b54b4ebcb32e4cb2b1cd4c0bb1634b72b0e84a75b1524a10b5bd49e5ba4248b6be6e47e6bef1475cbefa46b9be4d46e3ba25482ab5f14806b1b347c3b0e546cdb09f46dbaf7e48beaea4481bacda4815ab384809a7c1478ca4544747a0e2471fa04e472b9fb247689f2548e89ec8497f9f3449a6a0e249e6a3c94a18a6b94a4ca99a4a54aa014a2eaa754a9daaef4ee9a53350a89e6552b697cf547297e054bb98b3546e99cb528fa0b45043a76b4be8ad414b79adac4b34ae3c4b27aed64d01af7e4eadb0945006b201515fb36e525cb52752e9b7095312b767531eb7ce530eb83352feb89852d1b8f6528eb943'),
			_blackPathSimple(hex'7110609e6fd0609e6f985fba6f755ec96f2d5cc86f8f5ace6fb958d06fdc5727700e557e700c53c36dc4578e6d225c246a335faf68ad6002681e5ef667d45dbc67815c51675b5adb6715596e66f458c866fe58046630576863975c3662f06183620466a3605766bc605566ba5fbc653f60f36163616b5d5462d159836335585663a8572e642a560d64f7546e667c545067a955b368d65716692458ad696e5a56696c5a9869795ad869935b1469ae5b5069d55b856a065bb06cab57aa6d7d52cd705a4ef6721f4ed1727e501072895154728b52e472765475724a56037209592f718b5c5671ae5f8a71b35fc371a65ffb718a602d716e605e714360857110609e'),
			_blackPathFull(hex'4d25e82b8d4327db2ba1280d2cb027db2dea43278d2fc32735319926c433cc4c2bf6319f432ce72e772d072b172ddd27e5432f7027e53011286b2fd029be432e7330912d4e37712adb3dfe432a9c3ea42a643f65297e3f614328b33f6128653ecf28453e154329873b0e2a8437ec2b3c34b943290534f126093751257539354324bd3b8724043dd82345402743232340e722b74193221842054321614216210641a3208740e943234f3a2224d932e525e82b8d5a')
		);
		results = string.concat(results,
			_blackPathSimple(hex'8eba563093c353b798e551db9ddd4fa39fdc4eaca1f04de4a4134d4da5064d13a6064cdea65a4e27a6334ecca5b44ef3a5434f209d7d51ea95ee55458ea6592a8dcc59a28cf659fd8c0d59598b2458b48b3157b38b8856b68cc653168e6a4f9e8f7d4bed903c499d90b3473790df44ca927a4488930745519307469092fd481392b94993923c4b0391464e289053514f8f19545f8ec954ec8ea8558f8eba5630'),
			_blackPathFull(hex'4d4ee06810434dc767ea4d3d67514d8a661e434e73621d4fcc5e38518f5a824352a458615439568b562c55294357325467585953dd599d54ae435ae155805b1756c25aea581e435aa05a3b59985c2b58015d964c55fa5f6743566360a1574661595801623643597b63cf5a7465ce5acc67f4435ae268845adb69175ab769a4435a926a315a516ab559f76b284359686bec58c26c3557fa6b914357de6b6557cf6b3357cf6aff4357cf6acb57de6a9857fa6a6d43592a6815588266025707641643561362d9550761ac540760784353b5602c53785fcd53565f634353345ef9532e5e8853445e1b4356255c9258905a8058db56d9435806565e578e56d9571a572a4354b058af53695b0f52505d8e4351236077504e637f4fd56699434fb567324fae67cc4ee068105a'),
			_blackPathSimple(hex'81dd539b806255a181bc57f781195a047f8d5ac47eb85a487ebf58b77edd57db7ee156fc7ecb561f7ecb56087eac55f47e9255d07d2e55ae7bdb56fc7a4f55f67902597378235cf5768e602174ab602a73e75f2874af5dcd76ee59e9783e559979e1517a7af74ec47c014c0b7da9499c7e1f48f67e9c48417f9c4869809c48918100496481354a3d81b04c2f81514e37813550358128515c8105528c81dd539b'),
			_blackPathSimple(hex'4a0131444cf435434e3438e54d233a594bf33a874b8a39b24b4438ca4b0b38124af7374e4acc36924a9635794a0c3476494033ac487432e24770325a4656322645613448446d366f4386387742ac3906420938e54193383d41573800413337b1412d375c41273708413f36b44172366f4429334d44be2f3246722b9a471a29ff47f5287948fc271349d3260b4ad325174c4e25ab4dc9263e4e21277a4e1128d84de42c294cd52f164a013144'),
			_blackPathFull(hex'4d78689d004378ff9cd0794a9bfb7a2e9c3c437ad49d3c7a749e1f79b69ef0437895a0317752a131757ca0b14374e0a0857456a02c73ee9fb14373869f3673459e9e73349dfe43731f9d59731a9cb273279c0c4373279ae9733c99c5723198b043741a95d5772494b779e2930b4379d491817add90837c0b8fc1437ef58dc7821d8c3085708b074385fd8ad886938a9987258b1f43877e8c2486ca8c8e860c8cf24384228df382378ef3804e8ff6437d3a91977b1c945f786696734377579744762597f1753b990b4375e19aac752c9c6f759d9e004375d79e2e76209e45766a9e414376b49e3d76fb9e1e772f9dea4376899d4475919cfb75ca9ba84376c59a6477fe995479639889437ab099207a8099e379f49ab74379689b8c78a79c04786b9cfb4c78689d005a'),
			_blackPathFull(hex'4d36af30db4c36252f0f43373e2d9a38af2c77399d2ad4433c4c2b3d3e6a286e412029994341502ac640a82b1440032b60433eef2be03dd52c543cc42cde433b9f2d673aa22e3739e42f3d433927304238af3174388932b4433ad132213ce330b53f42315e433f7d32703eea32b43e4732f9433c8133a53ac5346a391535484336de368a362f37d336963a934338f53b393a7c39033c9d38a0433cb13ae139c53d2b37483d0843350c3ce933e43b50342c38d6433487360335a2337236af30db5a'),
			_blackPathSimple(hex'5b452b4c5a792e5057102e3955fd302a55043094548e300553fd302a538930bd539d315953e4321c55c5329d5701310f588b3074597c311a592431ce58a9326657a333b0562c348a548c34cb52f0350a5180338b516f319a5174303251b72ecd52372d7c528f2c6852e92b54533c2a4e51ef280451da27d953ff265356c6245659be22a75d3b22395e0f221f5e0f22235f2122905f7323a35eb023ef5de224305be024d659f125ae581a26b45777270056ea2773567e28015612289055ca293755ad29e755642b1d55082c4f54992d7a56fa2cb958d12b245b452b4c'),
			_blackPathSimple(hex'885b28138843279c880d272e87bf26d187712675870d262e869c2603855b255d840e24d882cf24347f8f228a7ece1eae81481c07835219e6860d188f88fc18418a3c18178b7918498bc41a2789b11a1287a21a8c85cf1b89845f1c4f82fc1d1e823b1eb08194201081bc213e83152209843e22af857f233a86b423d3882a246e8963257d8a3326d78af628488ac929a1898d2a71860d2cb9824a2e107e142dc57d642dca7cb72d927c2b2d287b9f2cbd7b3c2c267b122b7b800f2c1d84872b46885b2813')
		);
		results = string.concat(results,
			_blackPathSimple(hex'72dc369e7207359c727334a072a533c273862fc174722bc2757027c877941f4179be16bc7bef0e387c550cb07c8d0b047e080a0e7e490a0d7e880a217ebd0a457ef20a697f1b0a9c7f320ad87c5b14337a191d5877cf267c76aa2b0675952f9b746d34277434351673ee361972dc369e'),
			_blackPathSimple(hex'4a9d63c74a8367b549366b8f45c36e8643da702a41f4709b404c6fb33ea46eca3df46d0c3e676a773f0d6692403562e842e75fe443125fae43405f7a43715f4a44a25e4c45c55cdb47845da248685dfa492d5e9449ba5f5c4a4860234a9661104a9d62054aa062724a9d62e24a9d63c7'),
			_blackPathSimple(hex'bff5184ebfe61c32bd301f83b8e7204fb4b92115b1c11ddfb2f219c2b3bb16afb58a13f8b812120dbaed0fffbd3a1041bf1e13a6bfcb14e3c0041649bff5184e'),
			_blackPathFull(hex'4dcf8a705543cfe47123cff87208cfc372e343cf8e73bdcf137480ce65750e43cc7376d5ca037643c91773c243c80870e9c92e6e4cc9b16bda43ca956b60cb1c6bbfcbd66bab43cdab6a5acf9d6931d1a5683643d2de696dd2166a3bd13f6aec43cfd46bfbce806d27cd466e6d4ccff66cdb43d19e6e4cd02a6f2fcf8a70555a'),
			_blackPathSimple(hex'4f94a89751d3a60c568ca4455829a5635848a60957e3a6645769a6af56fea6ed568fa724561da75552dda8d852dda8f15334acdc54eeabcf5625aa265811a94e592caab657f7ab6d574dac4a56a3ad27557badd85531af3d56b1af3d5775adc858c5ada359beae2d5983aee75918af955884b05e57bdb0fd56d8b16055f3b1c454f7b1eb53ffb1cf524eb17d5134b04750daae2350b6ad0250a3abe050a0aabd5021aa1d4f29a9b24f94a897'),
			_blackPathSimple(hex'8ab7960f89b8960089539569896a94a7899992e089ef911f8a248f5a8a598d9589c78bd989b38a128b6089468bbd8a9c8c558b768c9e8b848ce98b7b8d2d8b5b8d708b3b8da78b078dcb8ac68dcb88388d2585958d8782f18ed382908f7083538f7a84498f8c887290a08c8b903490b8901b91b2903492d48ef893598d9793038dcb92038df391088e2b900f8e2e8f0c8dfb8e118d8b8e388d2a8e7f8ce48ede8c9e8f3d8c768faf8c7390258c4791608c21929c8bfb93d78bd694b78ba9958d8ab7960f'),
			_blackPathSimple(hex'5ef8a8f15e52aacc5f07acdf5d8fae4c5c60ae625b9caddf5bd5acd75c69a9fa5c5ba70d5cd0a4405e34a3125f00a40d5fa6a4f7601da5c16081a69560d2a77160eda7c26118a80c6152a84b618ba88a61d1a8bc621fa8de644ca5c56411a26263399ee664869e68651f9efa655e9ffb6639a33065fea69664b8a9a663beabee61deac34602caa5b5fc4a9ef5f6ba97a5ef8a8f1'),
			_blackPathSimple(hex'6a3aa81f693ba8db68a4a8686847a7a667ffa71067dca66b67e3a5c56829a2d368899fe468d89cfe6a429c4e6b269ccf6b719e6f6b9f9f876b71a0b26c46a2006efe9efc6f579bb06e43982a6f6e97ae6ff9982a703598f7713f9c8d711ba0056ed0a3246db2a4a96d07a4ca6aaea4526a30a4d96a44a5846a3da6276a36a6c96a3aa76e6a3aa81f')
		);
		results = string.concat(results,
			_blackPathSimple(hex'b1667b96b16677d6b3ff74fab7587519b91e7529bb3d7858bb3d7adebb3d7d64b85e7fbeb52a7fc4b2df7fcfb1637e1fb1667b96'),
			_blackPathSimple(hex'3822b6da384fb79d37b8b7f0373bb8343253bad42db0bde828f0c0ce27c5c18526d0c1742643c012281dbd8b3659b6363822b6da'),
			_blackPathSimple(hex'c53a772cc51878fcc30c7b04c16d7b10bfcd7b1bbe8779cebe5077c1be0574f9bf207264bf5c6f9fc1026f9fc1637082c14f719ec1347310c0ed747fc0b975f0c09976c9c07777a3c0fd7860c2937888c38476c9c53a772c'),
			_blackPathSimple(hex'81ca90b582fa90fc831791e8833892d4838195ac837c988b832a9b62831a9c3582de9cf281de9ce080de9cce80869c07809b9b2380bb99b181099840811a96ce812a955b810793ff80ff929880fa91e880da912981ca90b5'),
			_blackPathSimple(hex'ae004cb9ac4c4d76ab4a4cadab5b4ab3acd14a98ad954b4cae004cb9'),
			_whitePathFull(hex'4dac0aa56e43ab83a7cdab43aa39ab4caca743ab53ae29abf2af99ad07b0a743acfaabd2ad6ea72caf6ca2f743b1a7a1abb3c5a2ceb633a2e343b4ffa0e4b318a0dab168a03943b1ab9fbdb20a9f51b27d9eff43b2f09eaeb3759e78b4019e6143b6639de5b8d49dc0bb419df443bcd79e18be4e9ed9bf57a00e43c11fa229c314a41dc530a5e443c7f6a826c7c9ab36c717ae3a43c670b17cc4cbb476c263b6c043c12ab7e4bfeeb909bec5ba3c43bbe9bd2fb863be20b46abdc343b241bd98b021bd28ae14bc7743aa5abb2ba7f6b885a753b4ae43a66aaf28a81caa3dab82a5dc43ababa5b7abdaa59bac0da5874cac0aa56e5a'),
			_whitePathFull(hex'4dac60762c43abf97456abed7271ac3f709743acb3726bacbf7453ac60762c567f655a'),
			_whitePathSimple(hex'7edc52ff7dcc53877c9853b57b6c53827bf650b57d2d4e157ef84bdc7f554e417ee750937edc52ff')
		);
		results = string.concat(results,
			_whitePathSimple(hex'47092fa1482a2ca948fc29db4b8d27e64c8a2aea4a482eeb47092fa1'),
			_whitePathSimple(hex'40e96dbf3f75699f4325616047215f8547625f8947a25f9947de5fb648195fd2484e5ffa4879602b48a5605c48c7609548dc60d348f2611148fb615248f76193491f638548da657a482e674f4782692446726ace45116c3043fc6d4642bc6e5440e96dbf'),
			_whitePathFull(hex'4db8e7144e43b9e0141abac613debb92144e43bc421433bc0b136abc99133f43bce11353bd231379bd5a13ac43bd9013e0bdb9141fbdd1146643be52157cbe8416b0be6017e143be3d1911bdc61a31bd081b2243bb6f1d40b9421e60b6891dff43b51d1dcdb4961c84b4fc1ad143b5b8185ab711161cb8e7144e561d875a'),
			_whitePathSimple(hex'cb8f734acb60730fcb4072c9cb31727fcb217235cb2371e9cb3571a0cbc2715fcc08720dcc8271fdcd0d7217cd6971adcdd8717dcde171a6cdf171c7cde971d5cd4d729eccaf7353cb8f734a'),
			_whitePathFull(hex'4db4c778bb48b60a43b6b0787eb6bb7779b7a9778243b80477b4b85277f9b890784c43b8cd789fb8f978ffb90f796343b92579c8b9267a31b9117a9643b8fc7afbb8d27b5bb8957baf43b8857bc4b8717bd7b85d7bec43b7517d0cb4e07db8b41a7d1743b3547c76b3867ae4b4c778bb5a'),
			_blackPathFull(hex'4dae46aa2943b40ba6ebbabfa645c025a2b543c191a3edc184a41dbf2da63e43bf78a814bfc4aa0ac016abff43c053ad7dc094aefbc0d5b07943c0f8b14ac0d5b21fbff6b25243bca4b316ba1eb555b74fb6f943b633b7beb4fbb858b3b2b8c343b1cfb937b09db87cb046b69543b01eb5c9b011b4f9b01eb42a43b05ab13eafd7ae50aea0aba543ae77ab29ae59aaaaae46aa2956b3625a'),
			_whitePathSimple(hex'be5fb006ba68b204b70bb490b2edb66ab26db262b2e3aeabb38baa90b61aa918b963a86dbcbaa725bd44aa26bdceacf8be5fb006'),
			"</g></svg>"
		);
		return results;
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