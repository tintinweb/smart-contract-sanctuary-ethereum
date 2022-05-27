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

import "./OnChainMetadataProvider.sol";

/// @title NobodyIsNormal
contract NobodyIsNormal is OnChainMetadataProvider {

	/// @dev Constructs a new instance passing in the IERC1155 token contract
	/// @param tokenContract The IERC1155 that this OnChainMetadataProvider will support
	// solhint-disable-next-line no-empty-blocks
	constructor(address tokenContract) OnChainMetadataProvider(tokenContract) { }

	/// @inheritdoc OnChainMetadataProvider
	function svg() internal override pure returns (string memory) {
		string memory results = "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg'><rect width='100%' height='100%' fill='#fff'/><g transform='translate(109.719,149.169),scale(0.01)'>";
		results = string.concat(results,
			_blackPathSimple(hex'c21ca6d0c21faa02c1a3ad2fc0afb03bbfffb2a4befbb4f2bda9b713bba6ba57b920bd0ab572be79aef3c0ffa917bf11a349bc189f37ba019c3cb6fa9ab8b2ae9995af7999cbac2b9a91a8e19b66a54e9d2aa2299f029f159fc99dc7a06b9c5fa1389b28a2839936a4cf9854a6ea974caad39560aece95deb2dd967fb5e096e2b8bb980dbb2699e5bf3b9d2cc203a142c21ca6d0'),
			_blackPathFull(hex'4d105941c44310193d1010a838b4114434584311f22f7e12a72aa4135825c2431355259f134f255e133925534312ed253312d6257f12bb25ad43114b28320fe82ac60e712d4b430c1531740a0935c908503a404308393a7707f43ac108383ae943087c3b11089c3aa508c83a7c4308f43a5409283a25095739f743093f3a3409223a6f09003aa74307213d0e0675401104f742a9430420441a038c45b402db473b4302a647b10275482301d1482643018148220133480a00ef47de4300ab47b300744777004e472f43000046be00624660009d45f643019a44300299426a037040924304473eba052d3cd506193af543071f38dd07e4369c08d5347d430af02fda0d4a2b560fe326f543112f24b4125b2262138920104313e01f6f142f1eb515081f0b4315711f3315c81f8015fc1fe44316302048163d20bb162121284315292697148c2c1313d2318743134535b912af39e8126a3e214312653e6b12393eda129d3ef34313013f0d130a3e9413283e4e4314163c6e14d43a6d15cd388b431687372216be3578173e33ef4317b332951847314418d22ff5431a1e2cda1b0729901cd626b1431d5025ed1d76248f1e012474431f8f24271f6122961fd821d74320b52073218d1eed227a1d8a43242e1b00263418a027f9161b43295614312a87121c2bc71018432c050fb22c430f652cc30fa5432d430fe62d9010662d3b10dd432c35124e2b9c13f72a8d156743286c1850267d1b4e24821e444322b1210320c523b21f262694431d402a331ba22df61a4e31d543189b367a16cb3b1d15013fb343147a410e13e24261134c43b84313184434129e4425123744294311e0442e11894416114043e44310f843b310c2436b10a6431843108042aa10674237105941c456512d5a'),
			_blackPathSimple(hex'21a1790b223576d4222a7461226871f622ad6ea422bf6b4e229d67f9229963a822cf5f58233d5b0d233e5af2233c5ad823375abe23025ae422d25b1122a95b44214d5d5b1fe85f6f1ea261981b406745188c6d4d15ac733e146c75d41327786811ca7af0118e7b5d114c7c3510617beb0f547b960fcf7adf0ffb7a4a10ae77ee121675eb133473c1143c71bb15426fab16576daf17fe6ab6190d67771ae664901c3362841d24603f1e665e2b1ff35ba521a7592b234a56af235e568f23865679238f565823cd5588244154e5252c553726175589265b566c2620576225125bc324d5603c24a364b0246669ff24bc6f4e244b749a245074bc245974dd246874fc249074dd24c774c724dd749f25d872e326c8712127c86f69294f6cc72a9a6a032c2067672d2d65a42dbe63a02f1d621d2fbe616b2fce605b308b5fef311d5f9c30ee5f4d310e5ee8312d5e83312a5e3431c95e6732425e8d32235ddf322c5d9c325a5c78328f5b8233f05b1a34385b0634e559dd34d758f834d358a434f0585235265812355d57d135aa57a835fd579e36f5578936895702368d5699368c568f3670567a3673567736d155f8373c558437b2551d380354e037d054963802545b38fb536039da524d3a9a51253b36500b3be54efc3ca64dfa3d534d313e114c773edd4bcd3efe4bac3f274b8a3f394be13f3a4bec3f674bf63f7c4bf13f854bec3f8c4be43f924bdc3f984bd33f9b4bc93f9c4bbf3f944b233fbc4a88400e4a034060497f40d84916416848d841bd48af41ca47ed421d47cb442e46f0451f44be472143c747e24367489e42aa496f422d4a0141d64a8d41e04ad442584b1b42cf4a6a42fa4a29433948a54499471745ed457d473642b3498840354c323e134f223bc6522039955535377b585533b45dee304463c02d2f69c22a626f3e278274ac24a07a1e247f7a60244a7a9624097ab723c77ad8237d7ae323347ad622fc7ad322c47ac522917aac225e7a9322307a70220a7a4621e57a1b21c879e921b679b321a4797d219d794421a1790b'),
			_blackPathFull(hex'4d6bd579b6436b8278dc6bc4784b6c807841436cd778416d2b78626d6b789e436daa78d96dd1792b6dd67982436e3d7bf56d497e086c0680064369618430659f870861688973435fb18a6d5d6c8afb5cff8d6a435cb08f3d5d2490ee5db4929e435e5d949f5f3e968b6054985a4361d09aca618b9d5560da9fea436071a177600ea3065fa6a493435f86a50a5f1aa5385eb5a54e435e50a5645e38a5175e12a4d2435db8a41a5daba3465deda285435ea89fca5ff69d125eec9a2f435e2397f05d0295d05c13939c435bb892c05b7f91d45b3390f0435b2590d05b1490b15b019093435ae890b15abf90cd5ab790ef435a1c94395871973357e39a804357c89b28574c9b7e56cc9b4a43566b9b2756199ae255e79a884355b49a2e55a499c555b999604355f298405641972556a496104359098f915aa788d05b7581ef435b87814a5b9180865c61808f435c9180935cc080a15ceb80b8435d1680cf5d3c80ee5d5b8114435d79813a5d9081655d9e8194435dab81c25db081f35daa8224435daf843c5d1e86435cc7884f435cc088a75cc088ff5cc58957435cfa893a5d3189205d6989094360e487be63ba8569667b82f64368d180dc6a957e336b9c7b3b436bbd7abc6bd07a3a6bd579b656891f5a'),
			_blackPathFull(hex'4dc137864443bcbe86bfba88825cbae67ea843bb567b2abc4e77c3bdc4749043bfa87058c1f46c51c4a1688c43c5f4669ac74a648ec98c636e43ca9162ffcba362b4ccbc629143cdea625bce8a63c0ce8d64c743ce9e68d8ced16cfacca370b143cc617121cc4871cbcb9671a443cb387196cae37168caa4712243ca6570dcca407082ca3b702343ca156d9ccac56b2fcb2b68ba43cb5467c2cb8566cccbaa65d343cbae65bacbac65a1cba4658943cb9d6571cb90655bcb7e654843cb616534cb1b6551caf0656343c87d66aac71468f4c5866b1543c1fd6febbf527555bda47b1543bcfb7d58bc857f94bd2381f443bddb84afc106850fc2d7843b43c34e83fec3c883c8c444839843c4848382c4f68373c50f839443c54a83ddc50a842ec4d6847543c46c8507c3e0857ec33f85ce43c29d861fc1eb8647c13786445695ad5a'),
			_blackPathSimple(hex'65385573653b559d653f55c8654255f3655d568a65185732657157c766015758661556a4665d560c6799537868cd50e26a034e4b6a134e246a314e036a564def6a7c4ddb6aa74dd56ad14dde6b374de66b984e126be14e5a6c2a4ea26c584f026c624f696ce551e76c8954656c4b56e06c1858ed6bcb5af56b8f5cff6b7d5d9a6b365e0e6aa05e106a745e116a4a5e086a225df769fb5de569d75dcc69ba5dac699d5d8c69875d67697a5d3d696d5d1569685ce9696c5cbe696b5b35699359ac69e3582b6a2d56596a5154746a8352996a8052766a7752546a6952346a4f524f6a2852656a1a528468a755dd66f7591a66045ca665fc5cca65ec5cec65d55d0965be5d2665a15d3e65805d4f655f5d5f653b5d6865165d6a64f15d6b64cc5d6464aa5d55643f5d3163e45cea63a65c8c63695c2d634e5bbc63595b4c63675886634655c062f452ff62e552ca62ce529962b1526b62815290623b52aa622152dc611d550b600b573a5f2159705da35d165c3560c55acc64765a6065915995656658e665025836649e579e63fe5838632d5acc5fc75be45bae5d9e57e45ec855505fbd52a1615350416175500b61a54fdf61dd4fc162154fa362544f9462944f9462d34f9563124fa663494fc563814fe463af501163d15048650251cf64fa53aa65385573'),
			_blackPathFull(hex'4d372a377843354c378d33f13724336735634333523526333634ed337234c943338834c133a034be33b834c04333d034c333e634cb33fa34d84335cd36b137d035e039a5350d433bda340f3e0c32da3ebd303e433f1e2ed03ed72d6b3d882c85433c6c2bc33b3a2c073a1c2ca143399a2cea391f2d42389d2d8a4337e92def376b2d9937112d014336b62c69367f2bfc374d2b844339752a443b4028a13bee261f433c0d258e3c1624f83c082465433c0123913b82235d3ad823b343394c2471380625a83735272b4335952a4d34a32da833cc310a43336a329a327933f832433597433224368e315a36ae30a7365f432fc136042f64351d2fff34674331e13219325c2f3e335e2c9743347529b834bd266e3710242943384622fb397921623b9521e2433d3f22473e5424203e032624433ddf27753d6528b73c9f29ca433c742a013c442a363cab2a56433f3d2b20407a2cf940b92f8b4340ff32613f66341d3d233573433b4e368439463734372a37785646e25a'),
			_blackPathFull(hex'4d57e045c743578643c2592542ad5927412243593a405b59633f9659a03ed84359c13e3b5a833e2b5a953dbe435ad53c245c473af75c573967435c6a37ed5cf536845de2355e435f0f33ea5ee331ed605530994360e3301261162ecf61902de94362762c3c633c2a7e641528cb43642028b9642828a5642b289043642e287b642d286664272851436421283d6418282a640a28194363fd280963ec27fb63d927f24361652623608b23535f6220b5435f5920a25f54208e5f532079435f5320645f5820505f61203d435f6a202b5f77201b5f87200e435f9820015fab1ff95fbf1ff54360031fe3604b1fe9608b20054360cc2021610120526123208f436213223a62a2241c63dd259b43642d25f9648a268564ec268c43654f2693656b25df659a25774367772149699c1d336a8d18a8436a97187a6ae118346b00183a436b38183d6b6f184e6b9e186c436bce188a6bf618b26c1218e3436cbf1a596be81b9c6b6a1cd54368b42394659c2a28625530a843601e35095dd2396c5be53df8435acf4087597842f7583a457743582b4599580245ad57e345c74c57e045c75a')
		);
		results = string.concat(results,
			_blackPathSimple(hex'560754c055e8534654c452f652f753ef4f9b55c34e0758df4d095c5b4c3f5ed44bbb61604b7e63f54b74648f4b0165454a3b64f3497464a248c663e0490b63234a495fd14abd5c464c1958fc4d4f560f4f03539c51ec522e5364517654f65132565952355805536b580e553857be571457395a1e54f85b4752665bf7503e5c8b4ff45d1a511f5efa524a60da5427624754f4646c551e64c7553e652755546589556e6642556c671d5492674b53b86779539f66a0537a660352ee63c55149623a4ff2607f4f345f9e4ea35e9a4e455d834dae5b784e905aaf511c5a3553a759bb567157d7560754c0'),
			_blackPathFull(hex'4d7f3e4d10437f44502a7efa53437e61564f437e2f57337e7358377dd158fc437d6359827ce6594a7c7058e1437bd958547b8857b17be05701437c6456037c6054f47ca353f1437ca653d87ca453bf7c9d53a7437c8053ab7c6453b37c4953bf437a4754e9781055ac75c355fc43759956027571561475515630437531564b75195670750d5698437468583d73ca59e373235b8c4372eb5c1a72da5cec71ea5ca14370d55c4970475b6b70e15a794372555832735555b5747853484375b050a576994dd878624b854379594a3d7a19488b7bf14868437dca48457efc49d47f304c0e4c7f3e4d105a'),
			_blackPathSimple(hex'8a717f408a50811b89f982f2896f84ba896784f4896885308974856a89a2854b89cb852689ed84fa8b9481ea8cf07eb38dfd7b628e467a948e9f79cc8f08790c8f2978ca8f4b78538fbe788d8ff478a4902078ca903f78fc905d792d906b7967906779a190757b8f8f567d1c8ebf7ed08d6f82968c19866189b789ab895b8a2c89148aec88358aad87b88a9487488a4e86fb89e986ae8983868989058692888686ab87a986d386cf870a85f8870b85dc870985c0870385a486f185b386d685bf86cf85d385cf883184d98a8c83e98cee83bf8d5983ce8dd583378dfd83038e0a82cc8e0782998df382678de0823d8dbc82208d8f81ee8d5f81cc8d2181be8cdc81b08c9881b88c5281d48c12834088cf84f085a8861c82488687811686fd7fe5877e7ebc87cd7e0088317d2a892d7d658a107da28a457e798a717f40'),
			_blackPathFull(hex'4d7b2d8936437b3b89e77b4a8a967b598b45437b688b797b7e8baa7b9b8bd9437bcc8bc07bf88b9f7c1f8b78437e1188cf7f3d85c6803d82ad4380d880d4817f7f0e82237d404382337d1482587cdd828e7d084382c67d2882f37d5883117d9143832f7dca833d7e0a83397e4b43830c7f7182cf8094828481b34381a484db80ee88147f2f8ae7437e628c2b7df78dbe7caa8eb5437b938f837ac48f237a218e1e43791a8c7879508a97791588c34379098832790b873778ac8738437826873a78338821780388aa43772d8b0f76478d70756b8fd4437544903c752b90aa7509910f4374d191c27490928c739f922c4372ae91cb7213912e72a08fec4374228c7a757688fb76e2858343774984857778832278f18357437a3d83857a9084bd7ac185e1437af287057b1488107b3c89284c7b2d89365a'),
			_blackPathSimple(hex'8e7d01068e6300868e5700008ee2001e8f3d00338f8f00658fcb00ae900700f690290150902c01ae904803b28fa5059a8f0f077c8c760fd089c6181b873a207685e624b284dc2903841d2d62840f2db784132e4483722e21834f2e1f832d2e15830e2e0682ef2df682d42de082be2dc582a82daa82972d8a828e2d6882852d4782832d2482882d0182c229f2834e26ec842c23fb86af1bd3893913ae8bca0b8b8ccb085d8dee05388e6b01e58e7501948e78013f8e7d0106'),
			_blackPathSimple(hex'3d4a6ad43cdb6ae13c6a6ad73bfe6ab73b936a963b2f6a613ad96a193a8369d13a3c69783a09691439d668b039b8684339b067d3394f64843a6a618e3be15ea73cd45cc63da95ad43f4e596c403d587b418057ef42d457e5431657e3435857f6438f581a43c7583f43f25873440b58b1441a58c5442558dd442958f6442d590f442c592944245942441d595a440f597043fe598343ec599543d659a343be59ab43b759b843b359c643b259d543b259e443b559f343bc5a0044b35b5744cc5cd344c05e6f449b63744291676b3e7d6a573e1e6a903db66aba3d4a6ad4'),
			_blackPathSimple(hex'2b3d2f182b2e34df29033989240d3cad22bf3d7f21473dba1ff53cb61ea43bb11eb93a301f1238ce2047343e225c2ff525332c30258f2ba626062b3026902ad6271b2a7b27b62a3d285a2a2128b02a08290d2a12295c2a3c29ac2a6629e82aae2a042b042a6d2c5a2b582d8f2b3d2f18'),
			_blackPathSimple(hex'8e06253d8d0825698c5f252a8c2a247e8bf623d28cc723d88d2823bc9107225894d920d898411e8098f91e009a211da39a041c9a99e81b92989d1bb597d71b6596511aca949c1a8b9378193b9204178e9237156c9416137c95f4118d980d0f9b9ab40e919b670e499c150e1a9cbf0ead9cee0ed49d130f079d280f419d3d0f7b9d420fba9d360ff69d2710789cb710759c531093994a119096a9138594d8162693f91755946e185995c018e296f51963983219d299731a309b0f1aa79c231b9e9c441d3b9c601e859b471f3b9a3f1fd9971021ca93b22369903124b18f7b24eb8ec225198e06253d')
		);
		results = string.concat(results,
			_blackPathSimple(hex'65968e4d65728d1d65b28c8867118d0a67c98d4f68648cb068f98c5669428c2868e48c1968c08c0668778beb68368bbf68028b8467cf8b4a67ab8b0467998ab867848a17681189bb688589716bb5873e6eee851d72c684307341841473d483c7740c8470743b850573e68577735385c0702987316d2b88fc6a678b176a208b5b69df8ba569a68bf56a048bf46a638bec6ac18bdd6c3e8b7b6dbb8b166f358aa96fa88a8870028aa770268b0670498b6570048bad6fac8be86daa8d466b388d9669238ec168ba8efd67f78f0d680e8fb468109020682f9089686990e468a3913f68f59188695691b76afb92666c8d920c6e1891526eba91016f55909e6ffd905c7044903c70c7901e70e790487102906f7111909d711290cc711390fc7106912a70ed9152702e92e36d46947f6b61945b6872942566f99320663c90be65f88fe065cc8f1565968e4d'),
			_blackPathFull(hex'4dab8d85d843ab798608ac2186a7ab4a86df43aa748718a9f5868da9c885dc43a8f782bdaa438005ab7d7d4b43aba97ce3abde7c80ac1b7c2243ac7b7b96ad037b35ada17bad43adc97bc3adec7be1ae087c0543ae237c29ae387c52ae437c7e43ae4f7caaae527cd8ae4c7d0543ae457d32ae367d5dae1e7d8443ae0e7dadae047dd8ae017e0443ae447dffae877df9aec97df443b2287d88b2967af8b2f1784f43b315776db34c768eb39475b543b3bf7525b3d67441b4ad748143b4e1748fb51274a8b53c74ca43b56674ecb5887516b5a1754643b5ba7576b5c975abb5cd75e143b5d17617b5c9764db5b7768043b56377d7b4ee7926b4a97a7f43b4007dc9b357810fb17083ed43b15e8410b143842fb124844743b104845fb0df8470b0b9847843b0928480b069847fb043847643b01c846daff8845bafd9844243af5183f7af42836eaf9582da43afff8215b05c8149b0b6807b43b0c28046b0c2800eb0b77fd943b08a7fddb05e7fe8b0347ff843af28807eae218113ad317fc243ad0e7f90acd57fafacc37fe843ac1281d1abaa83d1ab8d85d85695415a'),
			_blackPathSimple(hex'8ccb47638cd44a7c8b934d298a0e4fc0896950db88be51f5881753108801534387ef537887e353ae882953ba887053ba88b653ae8b6a52b98e1951b890ce50c491b050769297503793815007939e4ffe93bc4ffc93d94fff93f750029414500c942e501a94485029945f503c947150549483506b94915086949950a394c65129947a51709414519c901853448c25550587f956278782564e8702564a868e561c861a55ee85ba5598857f552a84c053d4856b52b8861c51a388124e948a544ba88abb47de8ac047698ab446f48a9646838a7d46098a26457a8ac445328b6244eb8be745368c4445d28c91464b8cc046d58ccb4763'),
			_blackPathSimple(hex'dd5777e9dd4c764ade8b7496df4172b7df637273df727228df6d71dcdf687191df507148df277109dea0701adf6b6f88e0326f31e29f6e05e5256d0fe7bc6c52e8526c2be9186b82e9676c8be9a86d67e8f66ddfe83c6e2ee68c6eebe4df6fa8e32a704ce1de70cce1b971f5e1877308e16873b0e21073a3e287738be3e87334e5097259e64171ace67f7189e6be7159e6f9719ce73571dfe6e97213e6c6724be5b773f0e3f574dae2817612e25b7639e22a7654e1f47660e1bf766ce1877668e1547654dff275b1dff276c6dfbf7795dfa47801dff877fae03777e5e1407791e2347707e3057650e36175ffe3857521e43c7595e520761ce46176e4e4207748e31e78e7e18d7a19dfba7aa5dea17afadd9c79fddd5777e9'),
			_blackPathSimple(hex'5aa925fa5b0f296d599d2b8256dc2c8255902cfc544c2d7752e32d5d521b2d4d524c2e4c51b92e8251562ea650fc2f0350942ea550602e7d503b2e46502a2e0650192dc7501d2d8450362d4851e629cd51ac25f852562248525f21e05285217d52c32129530220d65356209553b7206f544d203954ef2029558d2040562c205756c22094574420f25829217d58ee2238598423165a1a23f55a7e24f15aa925fa'),
			_blackPathFull(hex'4d99e279fb439a6c7a069b1c79e19bb77a62439bf17a969c217a5a9c4c7a3743a012775aa4a175b8a95c758843aa3f757dab267572abd1764943abeb7663abfd7685ac0376aa43ac0976cfac0476f5abf4771643abe2773aabc77758aba4776d43ab827781ab5a778cab32778a43a6df778ea2a578d49f087b34439e967b809e2a7bd79dbe7c2d439d797c659d1a7c899ce67c4d439b6f7aa09a017c2198ac7c704396e07cdb951c7d93940b7f524393c77fc393477fbc92cd7f8a4392927f73925f7f4b92397f184392147ee591fe7ea891fa7e694391ef7e0b92007dac922b7d594392567d05929a7cc092ec7c9343950b7b3f976a7a5d99e279fb5689645a'),
			_blackPathFull(hex'4d44cc2fd74344b62ce446002a58471d27c14347d3261a493e25934a9a24e0434ab424d14ad124c84aee24c5434b0c24c24b2924c64b4524cf434b6124d94b7b24e94b9024fd434ba625124bb7252b4bc12546434dad286a4ce92b604b412e57434a762f9c497330ba484531a44347f231e9478e32134723321f4346b9322b464d321745ee31e543458f31b445413168450d310a4344d930ad44c2304244ca2fd74c44cc2fd75a'),
			_blackPathSimple(hex'd19d7540d1ec797bcf327d3ecb637e16c98d7e81c8417cebc8cf7aebc98678b1caa876a0cc2774d5cc83745cccd973dbcd2f735ecdcd7274ce8a71e5cfbf723bd0387256d0a47299d0f272f8d1417357d16e73ced172744ad17f74b2d191751cd19d7540')
		);
		results = string.concat(results,
			_blackPathFull(hex'4d94a48946439428895893a889499333891b4392be88ed925688a19207883f4391b887dd91838768916f86eb43915a866f916785ef9192857943923b8358936e817a948a7f914394c67f2895297f3695897f4c4396307f749641800d964a808843965b815896af813f973580f84397d580a29876804e991a800543996d7fdf99df7fc59a0f8023439a3e80819a6280f799db815a4397e582b795f88424940885894393de85a893c285d593b786084393ac863b93b3867093cc869e4394048711948886e194dc86b843962c86179773856398bf84bb4399018499994384279989846f4399ad849a99c284cf99c585064399c7853d99b78574999785a143986b876396ab88ad94a489465698af5a'),
			_blackPathFull(hex'4d31749ea343301d9ec02ed79ec42db19de7432d739dbd2d439d812d269d3b432d099cf62d029ca92d109c60432d299bd02dc79bb72e439bad432ec09b922f429b962fbe9bb84332809cc734f59b8037729ac3433a1a99fa3cb099053f589828433f8c98163ff0981b4000983643403b98bb3fc699173f7e9948433b229bd136649da031749ea356ae0c5a'),
			_blackPathSimple(hex'd7557b54d6e17b5fd66b7b4dd5ff7b20d5937af4d5337aaed4e87a54d49d79fad4687990d44f791dd43678abd4397834d45777c3d51174a4d6ec720dd86c6f4cd8776f37d8866f25d8986f17d8aa6f0ad8bf6f00d8d56efbd8ec6ef6d9036ef7d9196efcd92f6f02d9446f0cd9566f1bd9e16f76da3e6febd9ec70a0d8d27311d7bc7585d69f77f5d64778b7d69778f2d74d78eed8dc78e5da2e7817db9d779bdbd1778adc047747dc287798dc4c77eadc63785bdc46786fdac27999d9737b2dd7557b54'),
			_blackPathSimple(hex'a4597d9ba3ce8109a2a28455a0e48755a0d28776a0ba8791a09b87a6a07d87bba05b87c9a03687cea01287d39fed87cf9fca87c49fa787b89f8887a49f6e878a9f4e877a9f3287639f1b87489f04872c9ef3870c9ee886ea9ede86c89edb86a49edf86809ee4865d9eef863a9f01861ba08e832ca20e8038a2827cdea2937c5ca3047c6ba3547c66a3a57c60a4407d16a4597d9b'),
			_blackPathSimple(hex'a32b4d8ba33d4bb1a4d44bf0a5c54b9da69c4b54a6ee4c3ea6d04ce6a6a34ddea6564f01a5364f3aa3f94f70a38b4e68a32b4d8b'),
			_blackPathFull(hex'4d9d3150bf439cb750b89c4350869beb5031439b934fdc9b5c4f6a9b514ef0439b264d4b9c9f4d839d924d42439db34d3c9dd64d3d9df74d46439e174d509e364d609e4f4d77439e684d8e9e7c4daa9e884dca439e944dea9e994e0c9e964e2e439e9d4eb29e7f4f359e3f4fa9439e00501d9da3507d9d3150bf5660285a'),
			_blackPathSimple(hex'ac1e4c6aac0f4bb8ac614b3eacf54b3cad6c4b3baddf4b68ae364bbaae8c4c0daebf4c7daec44cf4aecf4d73aed84e63ae144e62acd84e63ac5b4d6bac1e4c6a'),
			_whitePathSimple(hex'bffca6bfbff7adb8bdeab432b8c2b962b74ebadeb587bbffb391bcaeb19bbd5daf84bd95ad74bd53a7edbcc4a30ebaa89f30b69c9badb2f09b94ae729c9ea9c69d9fa5909f91a1a3a24e9e49a6ac98bdaddd9754b32d9af6b3e29b72b4fd9c1ab4819cf2b4049dcab2ef9d03b2399caab06d9bcaaef19a42acd19a15abfe9a03ab279a0caa989ac4aa339b47aacc9ba1aafd9c08ab0c9c31ab2a9c53ab529c66ab799c79aba69c7cabd09c6eadf69bb8af729cf6b0fe9e20b2389f0cb3879fd0b5279f94b54a9f96b56c9fa0b58c9faeb5609fd6b52f9ff6b4fba00fb2cca09ab09aa11aae6da1a9ad9ba1dfacd4a243ac03a27eab31a2b9aa4ba36ba966a269a94aa244a922a22aa8f5a21fa8c7a215a898a21aa86ea22fa849a24ba82ea271a820a29da811a2c9a810a2f8a81da324a8eaa920a725aed7a648b4a4a5ffb696a6bab7dea864b7e1a89eb7e6a8d8b7d8a909b7b8ab39b53cae52b4eab13ab41bb2f0b3a0b4b4b34eb648b268b6cfb21bb6f6b1b4b6b6b138b69cb0f9b66cb0c6b62fb0a8b5f2b089b5adb082b56bb093b24bb1b8aefeb214abc5b2c6ab59b2deaaf2b30daa86b32aaa1ab347a99bb3d7a94cb379a8feb31aa92fb284a941b208a9bcaeecaae2abdcaaa0a8b3aa44a460ade9a500b023a403b1d3a345b3c0a30ab58fa290b631a265b68ca27bb688a340b679a731b7a2ab09b76faefab75eb044b72bb17ab89ab210b989b274b9f4b1eab9f4b0ffb9f8ad38b92ba988b8e3a5c9b8c5a463b827a2bbba14a1d7ba8aa1a0ba70a0e7ba40a083b9d49fb7b9589ef4b8cd9e3cb8ab9e0eb8439ddcb8209defb6b49eb1b6d29d87b68a9cc1b6329bd7b5aa9b04b4fa9a53b44a99a3b377991ab28e98c2b24298a2b1fc9886b1e29837b2239833b2649834b2a5983bb4ed9898b71c996cb90e9aacbb009bebbcab9d8ebdf49f7abf6fa19abf97a40ebffca6bf')
		);
		results = string.concat(results,
			_whitePathSimple(hex'7d5b4cec7d3a4e6c7d16503a7cf052087ce652727cd1529b7c4f52597baf52047afe52757a565292792952d3780d532b76e7537576b4537c7680536e7657534e76465343765a52f7766f52d277ce507d78a74dd77a974bda7b144b507bac4ae37c574a997cbc4a707cfa4a8b7d0a4b037d1a4b7b7d364c127d5b4cec'),
			_whitePathSimple(hex'3bc567363bb963fc3d1c612e3e885e673f135d463fcc5c3e40ab5b5841445ac241c05af042525b2c428f5b4742c35b7442e75bac430b5be5431e5c26431e5c6943435f4c4280622740f06495401166013ee667383d8368253c5668ec3bbf68ab3bc56736'),
			_whitePathFull(hex'4d29a62ed34329f233c5263239b121db3b2f4321333b6a21023b1520f23a8e4320d0395e215b384421c1372e4322db33a7249a305d26e72d7943273e2d10279e2c2c28132c754328772ca628cf2cee29142d464329582d9f29872e06299e2e734c29a62ed35a'),
			_whitePathFull(hex'4d58ec2608435911284b55d92b7a539b2b454353592b4053262b2c532d2ade43536528745392260b53e0239f4353f922e6544f220a553f21f643567c21db575422a45807238643589a243c58eb251f58ec26085635715a'),
			_whitePathSimple(hex'4b2a28754b662aa649502e6b475f2f5e47462f6947112f70470c2f6546f22f3e46e52f1146e42ee347362c1f486229864a3f27754a5927574a99273b4ab427484b3a278c4aeb28254b2a2875'),
			_whitePathSimple(hex'd00d7577d03f77d8ce047adecbae7b56cb857b59cb5c7b56cb347b4ecb337b26cb387afecb427ad7cc26790ecce0772dce7a75d9ce9f75aecebc757cced07546cefd74f1cefd7472cf8e747ecfdb7486cffe74cbd00d7577'),
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