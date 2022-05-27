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

/// @title AbnormalIsTheOnlyNormal
contract AbnormalIsTheOnlyNormal is OnChainMetadataProvider {

	/// @dev Constructs a new instance passing in the IERC1155 token contract
	/// @param tokenContract The IERC1155 that this OnChainMetadataProvider will support
	// solhint-disable-next-line no-empty-blocks
	constructor(address tokenContract) OnChainMetadataProvider(tokenContract) { }

	/// @inheritdoc OnChainMetadataProvider
	function svg() internal override pure returns (string memory) {
		string memory results = "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg'><rect width='100%' height='100%' fill='#fff'/><g transform='translate(138.335,146.492),scale(0.01)'>";
		results = string.concat(results,
			_blackPathSimple(hex'12853194113931f512de34cb107634700f6934480ee9333c0f87321715bb268a1ad31a781fd60e5e20060de620d10d39211a0d51220a0da122620e5721eb0f6d1f3a15b61c9a1c0519fb225519eb227d1a1f22ee1a4122f41cb423761f3e234f219d2283221e225521fc203922081f00224a17f8228710f022be09e822c10948231008f2239808ff24ad092024fa09f824f10ae724a7124d244419b8240e211923e5267c25402bde24353145240a322123e9331b229f32ca21773281218831c921cd30c922d32cf522472913220d2535220424a021a624c2215524de1e8725d81ba0257518bf25bd17ff25d0175327e316b0291515502bd113fb2e9b12853194'),
			_blackPathSimple(hex'3edb25803e0027253cbc288a3b2f298e39a22a9137d92b2b36002b4b34c22b6a33c92a683308296333b7294f3467294135152927369428e93802285e394b27903a9326c23bae25b43c8d24763d61235c3e43219a3d3220973b891f0339321fd237181ff935bb201333e321b133211f7432431ce335391d5d36491c4d37d41ac439d419bc3b7b184e3c8d176b3ddd16313ccf14ad3bc2132a39ec1371385b13fa32da15db31a01a4b31091f7e307324b22f2229c52e1a2ee52e112f172da02f6c2d802f602c862efb2bc02e5d2c082d242dc125412fd41d6c2fce15422fcf1501303414b33065147832c6168b33a71381350012d638e010e73cbf10e93e7c13e640bf17c73de319df3b431bf23aa81c6c3a0d1ce539701d5e3a271d7c3adf1d923b951db83ef21e64409321ad3edb2580'),
			_blackPathSimple(hex'890ecec882b7cc17802cc6568186c0858267bc5484a4b88b87e5b5c18a3ab3b28c88b1de8f91b116906ab0e2914cb0ef921db13b92eeb18893a3b2109427b2c3967ab5979a5eb5e69cb5b8efa0c4be269f6fc73699c1caad953dcd6e90d9d0418b32cf568b07cf518addcf4a8ab3cf408a02cf0f8952ceda890ecec8'),
			_blackPathSimple(hex'2c0c78d42e6a75452f4c71442fa26d192fb26c672f9f6bc32fb56b1e2fcb6a782eb969312fc7690a314d68d331476a9131566b7f31e474692e137ba3285a82142812826327b3829b274b82b326e382cb267682c22612829b2573826b24e7820b248081882419810623de806723d57fc123717bf8232d782c22d9746022d4742522a873ed228f73b5227273e6225a741a2244744f1fc77b0e1e5882251e0589541dfb8a381d398a021cb189ff1b8389f61b3988fc1b5188301c4c80bf1e15796e20a4725f20ec7196218070552202704e23cf702f24c6717c24f67327254f76442575796625bf7c8725db7da726217ec526537fe427337f3128447ea028ed7dc12a157c2c2b017a7b2c0c78d4'),
			_blackPathSimple(hex'b9fd3340bc3e2e80be612a31c14d2660c1582646c15e262bc15e260fc15d25f3c15725d7c14b25bebc5f2448be3c2098bea61d80bec11cd2be931b50bfd11b9ac1631bf7c1041d41c0931e77bfca20a0bf7222f4c21a23e9c35b245cc3c9226ec46d2186c7541d6bca131932cce41507cd721438ce4013e2cefa14b9cf95156bcf151600ce9716b9ca621cd3c62d22efc2202924bcec311db9c93a12b5724273b4c743bdb4c945e6b2904610b27f4609b25245f8b25345edb2484589b24b4525b25c44c3b4463e6cb7e138eeb9fd3340'),
			_blackPathSimple(hex'42f4a21443fca16d42e39e7f45b79f0c45dc9f1245ff9f21461d9f37463c9f4e46549f6c46659f8e46769fb0467e9fd5467d9ffb467ca0214672a0464660a06743aaa6a84090acb73ba9b1913987b3ae3afbb50e3c1bb6a53d94b8ac3f13bab54078bcd140e4bd744131be75404abed63f90bf243f54be253ef4bda03ce7badc3addb81838c0b5653861b4eb3856b584384cb5bd37e4b8733785bb2c3711bddd36fbbe0d36dabe3736afbe563685be753653be88361fbe8f34febe5d3499bd7d34c4bc753572b82c364fb3ec36daafa43743ac6d374aa92b3786a5ed3790a567374ca4893845a496393da4a33a07a51339f2a62e39b7a96b396aaca73924afea3926b017392db044393ab0703964b05a3996b04f39b2b02e3d71abf940c2a79642f4a214'),
			_blackPathFull(hex'4d9a6386c54397808cea97fc92249b27943a439ea19685a20c953fa533935343a64d92a9a72a925ea840931143a7bb93c5a727946ea686950a43a1cc98f59b6d985097de939543957490619615898797f7865a43996f84169b0c81eb9cce7fdd439f9e7c52a2e4792aa776786543a92d781baa737a3daaa17c1f43aad37e2aab3c8043aa19824643a9b382fba9a583dba89983af43a78e8382a711829ea721819a43a7378029a7807ebba7977d4a43a7a67c52a7de7acda75e7a7843a66479d0a5377ab7a4517b5a43a0217e4c9cb882379a6386c55689f55a'),
			_blackPathFull(hex'4d7bde42ca4375f7404874ea3a42786f3560437ba430f47f192d2b84352b134385eb2a64879d2a9289522adc4389822ae589a92b2089d42b4443895d2b7988e02bda886f2be04381e32c1478d03520789d3bac43787940097c66421c814f404a4382873fd784093fbb84f23eee4386e23d3b89613c4e8ae139ec438d0b367b8c4d317a88ea2fe643878a2f4185dd2e66852530d743851b30f084e430fd84c13110438479308184452fe984282f4b43842a2f0f843b2ed484582ea04384762e6c84a02e4084d32e2043879e2cdf8c5c2fd88ca032ee438ca634188cd235418d223661438e0c38e68ce73af88b583c7f438762406582f5439d7ce9430a437c8e42ff7c3442e97bde42ca5645f95a')
		);
		results = string.concat(results,
			_blackPathFull(hex'4d7379114f43723e165e70911b4f6e752011436e5f20496e3e207a6e1220a3436de620cb6db220e96d7a20fb436d3920f86cfb20e76cc120ca436c8820ad6c5520846c2d2051436bc61fcc6b341f116bc31e6d436f7a1a2b70b414dd726f0fb54372cc0ea272bf0c2474130c7743764a0d04765b0f73765211824c764914c74376b113c2772412c0779b11b74378dd0ee77a230c187b6a094b437b8509257ba709057bcd08ec437c5d099d7d440a3a7d6f0b03437e3d0e997d4212207cdb15ad437cba16d37cc817fe7ca91924437c9319d37d131af07c001afb437ac61b097a6119e77a7c18df437ada156d7b5612087bb70ea0437bb70e137ba70d877b870cfe437b5f0d627b290dbf7b030e2343796f122b77e0163876411a3b4376251a7175fc1a9e75ca1ac04375981ae1755e1af675231afc4373cb1abf7399199273ab18754373d11627741413da7447118e4374421131743210d67416107e4c7379114f5a'),
			_blackPathFull(hex'4d5b41687c435ab66c255a1770545977748143595f7524592875bb586075b443572e75ae565c7509567073d643568e71f256466f9957456e464359906b3d5946677b5ae16459435b0c64165b4c63e25b9763c7435c68646a5d7164f75de465d1435e8a674b5f1668d05f866a5e435fb36ac65fe86b2a60256b8b4360986b3860fb6ad3614b6a5f4362bd6737632663c463e8606c4364065fe663b15ee664a65f004364fe5f0e65525f31659b5f644365e45f9766205fda664c60284367d2644766c5688a66bc6cbc4366b96de3677c703c65a470124363556fdd64666d7d64686bfc436479699364ac672c64ce64c44364c7647f64b7643a649e63f943647764376458647a644264bf4363ba677963e06a5862586cd84361e66d9161ae6e8060a76e7b4360216e785f9e6e4b5f316dfc435ec46dad5e726d3f5e446cc0435da26b365d27699c5c916808435c6d67b95c46676c5c1a67214c5b41687c5a'),
			_blackPathFull(hex'4d4de1201c434f051be94f23168f4fcd1147434fe8106c50260f15510f0f414351f80f6c51b61088518d119b4350c216a7505b1bc54f9c20d3434f4f22684ec923f04e0e255f434d8826804cb227b44b34275d43495f26f448c52547484523ba4347fa229b47c4217747a620514347851f8b476a1ec9474f1dfb4347201ec346e51f87469f20474345642336441e261f42d629094342cb292242ba293942a4294b43428e295d427429694259296e43423d2973422129724206296a4341eb296141d2295241bf293e43411f28af4077280340f827144343af221746231d04471a175543473b168b462c14ce47f314fb43496a1524497f16d6498c18294349a41b5749a91e8449d421af4349e222bc4a0424514b0e2479434c1724a14c8223154d11222d434d6021814da620d04de1201c56234c5a'),
			_blackPathFull(hex'4d52b545af43522247ff51924a5150f34c9e4350eb4cd350d84d0650ba4d3243509c4d5e50754d8350474d9f4350184dba4fe54dca4faf4dce434f7a4dd34f454dcb4f134db8434e434d654e584c984e884bdd434ee04a7b4f3949174f9447b5434e6648484d2f48c54bf0492c4347324a5b49cf4e7c48b6511f43486e51d3490e531147b8531443468d5317466251ef465c51194346514bf247d547124935422f43497e412949223fa94a753f52434af33f324c423fec4c074100434b9c42b64b1b44654a84460e434a5446a04a7946a64afb468e434ee045e7516f441d51c53fbe4351ee3da752bc3bad534639a6435355398253a4394653b5394e43547e39c255943a1f554e3b4a43547f3ec65397423952ba45b14c52b545af5a'),
			_blackPathSimple(hex'2cfb486c2fe74681328d44ad359f438739a842053daa406641f43fca42a83fb043ef4039441f40c2446f41aa4348419942a441ca406642713e2a431f3beb43be39ac445e3c1945403bc0462b3aba492139dd4c2339294f303885519c37ee540c3759567c37235754368e581335c157de34d957a434b156b934f055c93660505437cf4adf393d456a394a45493942450a392a44f8391244e538d944ef38b744ff357f4695320d47da2f3a4a3c2efb4a572eb64a622e724a5b2e2d4a552deb4a3e2db24a182d4d49c92d3c49172cfb486c'),
			_blackPathSimple(hex'1726573b1669571914a156b112d1567a12245674117b563f10e955e2105755850fe055020f9154680ed352d60fb7518510c3507812d04e6a14fb4c69171d4a7417a949f418614961191d49d219c04a291a3c4abc1a784b6b1aa14c3319a04c5019094cab16624e6514035085120252f8113e53d911e2542b12b2544d153e54b917d055101a1b56641d1958231d7c5ab01abd5cb717ac5f001467612c105661490fed614d0f8160c20f18607a0f5a60330fa45ff30ff45fbb12dc5e1615cd5c7f18af5ace19575a6c1a5159f91a1f590119ed580918f757e01726573b'),
			_blackPathFull(hex'4d5f921e6a4362281a7761d115a6640311be4364a7109865af0fb766ec0f464368bf0ec86a850f946af511a4436b5e139769631413684d15134367f115526791158a672d15bb4364fe1731632a186f66b21abc4369c41cc26b4c201a6bfe23ba436c2024686c7425596b7e259b436a2825ee69d824d069d123d34369b41f9666f81d1e63e21ae04363c81ae763b01af3639c1b044363871b1463761b2863691b404362fa1cd9629a1e7762282010436221203a620f206161f420834361d920a461b620be618f20ce43616720de613c20e4611220e04360e820db60bf20cc609c20b343603920795fea20215fba1fb9435f8b1f505f7d1edb5f921e6a56219a5a'),
			_blackPathFull(hex'4d9e162f85439efb2c3ba04128b5a09924f443a0a824b9a0ce2486a103246643a11b2453a1752465a176246843a1862536a18a2605a18126d343a1642842a0e629bca11f2b1a43a1692cf59dbc36519bd1370243997337db98e335d69848342843983733fe982133d6980e33ad4397f833d597e733ff97dc342a43979936ef963a395394ee3bb74394913c6393fb3cd4934e3c6c43926d3be491eb3ad4929d3a0643962735eb966430db96fd2bdf43970c2b5896e82a6797a02a7b43981a2a86988d2abb98e42b1243993b2b6999712bdb997d2c564399b92e3999d830209a163205439a3832c49a6833809aa43439439b5133ad9bf133129c823268439d19317b9da030849e162f855632b55a')
		);
		results = string.concat(results,
			_blackPathSimple(hex'85e61414854c12fb882211a785eb104c853b0fe1853610bc8510111f844a132a8394153d82c6174582af1774828e179d826317bb823a17d9820917ed81d517f3815b17e08084176c808b173580b515c17ee013c981fb12fd832e12b0838e106783970ec2839c0deb82510c8d84ae0c8985330c8785c00a438637090186de073c873f0553882d03b8887703368998045389c905158a6d076589ea09ba89b80c0c89a70cd1892a0d9b8a290e3c8ac60ea08abf0f1f8a050f9d880a10fa88f9136d88001531879015fc87a3179186a417758463173a8562159e85e61414'),
			_blackPathSimple(hex'45ed71dd47536ccf480368824c2f66014db165164ed364cb500c661d5145677050f96909500d6a4c4ebf6c034d0a6d5f4b136e4249c66ee34ac46fcf4b3070754ccd730a4fad743051d3762c51ff7655521f76df520476f751c7772c51507767511777504d9475a84a8a737048876ffe486b6fd8484c6fb548296f9648156fc747de6ff547e2702248067287468474ff4838775a4867779b482b784d47ed78ac47cc78dd473e78e446e978d1468578c84627789945e2784e459e7804457777a24576773d459a750f45d772f945ed71dd'),
			_blackPathSimple(hex'6c1d69fa6f1666046ea360c070805c3d70d75b6470f959e171dd5a0173fa5a4e747f5c4674d65e1275015f567514609c751061e37513623b7510629b759b625277956139750e632475eb62c87601630777a962447659635874206527756567a974db69cb74a36aa374436b86737e6b67725f6b3071fd6a42724a69067270682772806746727b6664719c667d702b66526ffb66bd6f5468236f1e69c06ebd6b466e946bed6ef26ce06e096d086d626d126cbf6cdb6c406c6e6b8a6bcd6b8c6af16c1d69fa'),
			_blackPathSimple(hex'95f6073a94db094593a50b7d92720db9925e0def92520e28924e0e6292880e6e92c40e7393000e71969b0de799df0c599d370b029f240a3ea112097ca30108bba31b08b1a34208c6a36208cea3390950a33a0a01a2e20a4e9f760d4f9b1d0e7196f80fe394f01098928712799095106d8e530e1590c60bef91e709ef9377072f94d60468952d0130953700c495a7006595e700009656007a96fd00e09728017097a603709675052895f6073a'),
			_blackPathSimple(hex'3cfe75563bf677c93a6379f938637bb937f37c2037627c5c36ca7c6236327c69359c7c3935247bdc33587aa3337478bc33c776f0346a734935dd6fd238046ccc38a16bf039706b423a696c193b266cbd3a4c6d4b39f66de53812715c366e74ec361b78f136207936362f797a364779bb368779ac36c579973701797b396278053aa075d13baf73433cda70753dbe6dda3c4c6af33c426adf3c796aab3c916a873cf26ac93d826af63daf6b533f346ec23e0b720d3cfe7556'),
			_blackPathSimple(hex'c4c876d3c51a7368c8dd7336cc21725ccc837243cd5072fecd9c737ecdfe741dcd627456ccd7749fca8975c4c75e75bac68e7900c684793bc6807977c68179b3c6b379a8c6e979a2c71c7991c8137938c90e78efca0e78b5cabf7897cb99795ecb3979c9c9f17b32c8887ca8c6507c75c60a7c70c5897c55c5877c5ac54c7d65c51c7e71c4ea7f7cc5407f81c5a27fa4c5eb7f89c6d97f30c7b37eaec8a77e69c9037e4dc9837ea7c9f07ecac9a17f62c9778026c8fb8084c7948198c6138321c42c8220c19680c2c2537e58c2f77c2bc3607aaec3ef7948c4c876d3'),
			_blackPathSimple(hex'ad0a281cac5a29d3abfe2ab9aba22b9fab632c3dab362cf2aaff2d9babf52d4cace62cedadd12c80b0eb2adfb3ff291fb7192775b73a2770b75b2775b7792781b798278db7b327a1b7c727bab7d027e1b7d12808b7c9282fb7c12855b7b02879b7992899b3fc2bc5afef2e66ab903068ab35309eaacc30b9aa6230b7a9f730b5a9903095a937305ba8062f81a7fe2e42a8682d1aaa06287dacfd2450acc31f1facc31f1face11f02ace41f04ad6d1f77ae511fd8ae7b206caf922394ad832623ad0a281c'),
			_blackPathSimple(hex'0147634e045d5c34062853e8088a4bca08c94af208f249bd0a324a020b714a470af14b520aba4c24088354be064d5d57032065a602d8665b03f7685c01ea67ba0000671b0091656f0147634e')
		);
		results = string.concat(results,
			_blackPathSimple(hex'55b917475617169556ba154f576d141257c1137c582b12ef58f913615929137559531395597413bd599513e559ac141559b8144859c3147a59c214af59b514e159a81514598f1542596c1569570118a3562d1c5a55f9203d56022096561920ec563d213d568d212456d92100572020d35b2a1d5f5c10189d5c7613b05c8612e35b72123e5bf811565bfd11495c1a113b5c2111405d6111f05d6913265d6714575d5c19b45c751ec9589c22e857c523ce56de245d559b23dc5458235a53ff222c53ee210853c81db054651a5a55b91747'),
			_blackPathSimple(hex'59f6af955949b16a58dab25957b8b2465619b2245559b0df54a8af9c5479af445434aef353feaea153f2aeff53e1af5d53dcafbb53cdb15153ccb2e753acb479539bb4a7537eb4d05359b4f05334b5105307b52552d7b52f5278b531521cb50e51d7b4cd5191b48d5168b4345163b3d5517db08751b5ad3751eda9ea51f7a9c85207a9a9521ea98e5234a9745250a95e526fa94e5320a9955408a9d55461aa635528abcb55ddad3d567eaeb956a4aefa56d1af375703af6f5741af385775aef7579daeaf5846ac7b586caa27580da7e25804a74d5809a6b6581ba62258b8a6aa59c8a72259dea7be5a50aaa25a9cad9959f6af95'),
			_blackPathFull(hex'4d5f0a3e6e4c5ef43f38435f413f2e5f8d3f1c5fd63f014360ab3e9e61773e2b624d3dcd4362a93da3632b3d6e63753d8c4365343e3f64bc3f0e636f3fc743619540d15f9d41b45dd842e2435cbe43a15cce45135d2d4635435d7c471b5e4a46625ed64627435fd045c5609844c661d8453443621a4544625d454e62a1455143629145a4627145f46243463c4360d047de5f724a315cd648ec4359fa478b5a6f44c95b17424c435b9d408a5c3e3ecf5cfa3d20435d3e3c775d673b405e4e3b99435f673c045fd93d1b5f0a3e6e5a'),
			_blackPathSimple(hex'86029c0c860a9baf86169b19861f9a8286019a7785e19a7185c09a7383e49a9d834e9bd383289d8183109e868383a03281c3a00380039fd480a09e5f80ca9d3b81269aae816e982181c9959381df955082099515824094e98302955583e8959b83f096bf83f3975483739866845398608534985a8690982c868396828687950986aa939286ec9220871691a78753913587a190d088449152892d91a0891692ad88c89616887a997e881f9ce488279d25881a9d6787fb9da087dc9dd987ab9e0787709e2387349e3f86f29e4786b29e3b86729e2e86379e0e860a9dde85909d7f85709cdd86029c0c'),
			_blackPathFull(hex'4d7e945e58437fa65b8480a358b480b8559c4380ba5545811e54f08155549b4381fd552682b355ac82ba56a54382d85b0080ce5edb7f9162e4437f8363347f7c63847f7e63d5437fd263d0802463c1807463a843826c62c3845f61d6865560eb4c86a860ca4386aa60d586aa60e086aa60eb43863c632b8485643e82c1654d43814e66287fdd678d7e2d664c437c1a64c07d1b62a27daa60b5437ded5fe77e3b5f1d7e945e585661885a'),
			_blackPathFull(hex'4d645eab014363deabcb62f6ae5b6093ab0f436084aafa605eaafa6046aae5436031ab0e601fab396013ab66435fbdacf35f6cae7f5f18b008435f16b02d5f0cb0505efab06f435ee8b08e5eceb0a85eafb0bc435e91b0cf5e6eb0da5e4ab0dd435e26b0e05e02b0da5de1b0cc435cfeb0825c4fafe35c9daee9435db5ab9a5e7da8325ef1a4bd435f06a4695f34a41e5f75a3e5435ffea41c60b9a45460efa4c0436155a5a561a3a69261d9a786436203a81b621aa8b06243a9494362b3a8bf6311a827635ba7864363ada68c63c1a57e63fca47d436428a3bc6469a30364a0a24643659da2a06574a3a76588a44d4365eea69a6585a8f9645eab0156ae315a'),
			_blackPathSimple(hex'acd58564aeaa8465adfb8090b140808fb30d8090b46d81d4b50183a2b54f8487b55f857db52f866ab4ff8757b4928833b3f188e8b0c28c80ad9e8cd6ac3e89deab90886eac2c871aacd58564'),
			_blackPathSimple(hex'77dea4cb77c2a47e7755a3dc777aa39f78eaa120782a9e4f78b79bb378b89b7578ad9b3878999afe78589b0478199b1477dd9b2c76a09be0756b9c9f74319d4b73749db872a79dd672249d0a71a09c3e71e19b8972d79b1c7689997379e396de7e2d96c47e7196d47eb296ee7eee97127ed097557ea797917e7397c57ddf98347d3b988c7c8d98cc784b9a047c079d4c7ada9f6c7a32a0987a8fa2587a52a3d07a15a5177927a52d77dea4cb')
		);
		results = string.concat(results,
			_blackPathSimple(hex'13a3be22135abdc51320bd5f12f5bcf212ecbcd01364bc7b13afbc591a6eb926212cb5f027f2b2ce28feb2532a16b1a32b5db21e2b9db2382bdfb2452c1fb2592beeb29c2bb3b2d62b71b3062413b6ad1cb4ba4f1554bded14c7be151435be2713a3be22'),
			_blackPathSimple(hex'4509b9cb4299b8d140dcb365425db14f429cb14342ddb145431bb1554358b1654392b18343c3b1ad4567b42846d8b1dc4846b1754925b1364a03b0cd4a7fb1aa4afab28649f5b2e24968b34147f7b4364699b5ad449fb4504494b44b444fb4774451b4854495b5a743f2b73e457eb7af47a0b842495db7254af3b5cd4b19b5b44b45b5a44b72b59f4ba0b59a4bceb5a04bf9b5b04c78b6024cffb6684c85b7314b2db966475fbabe4509b9cb'),
			_blackPathFull(hex'4dbbd77d5243bb677ed2baea804fba9181d743ba5e82b7ba03841cbae3846243bbc384a7bd048404be1883ba43be9d8397bf79831cbf8d833643c0178404c04e84eabf35858443bd66868abb8a8810b978865643b767849db7ca8212b8707fc643b9157d7aba067b13bad578bb43bae178a4baf17890bb05787f43bba4792cbce37964bcb27aa843bc8d7b93bc4b7c78bc177d5f4cbbd77d525a'),
			_blackPathSimple(hex'6a13a58a6aeda33d70eda09770fea145712ba3017038a4a37020a67f7010a7f36e38aa216c07a9906916a8cd69c9a6776a13a58a'),
			_blackPathSimple(hex'5e853a3d5e5d3a1b5e3d39f15e2839c15e1339915e08395d5e0939295e0a38f55e1738c15e2e38925e4638635e67383b5e91381a5f2a377f5ff4371c60cc3702628536e3640d355465f2366d661e3684664136ab665336da666537096665373e6654376d63d4385f615239425e853a3d'),
			_blackPathFull(hex'4d4432b11f4343e0b08c4380b0204371afaf434374af7b4383af49439daf1b4343b6aeee43daaec84405aeaa4345d1ad9b47a7ac9a497dab9b4349ceab6f4a2dab654a85ab7e434adeab964b29abd14b58ac20434b6aac384afdacd64aaead11434904ae514756af8545a3b0b043452eb0e544b1b10a4432b11f56b44e5a'),
			_blackPathFull(hex'4d6af9a15e4369e8a0f06995a03569c69fac436a529e256bba9d746d289cfd436e3d9ca26fbe9c49702e9d9d43708c9ebe6eee9e8c6e449f004c6af9a15e5a'),
			_blackPathSimple(hex'8e7a65c68d1f64d68d7663838dd3623b8de6620d8e5b61c88e8561d8902c6282904a63fe901765628fff661f8f2365e58e7a65c6')
		);
		results = string.concat(results,
			_whitePathSimple(hex'9cc2c3509995cbe98b0ad028854cca288265c72182babfaf863ebabc8790b90d892fb7a08b05b6898e71b4479149b6639447b5c89501b5a2951fb655950eb6ff9501b77c9410b8359544b872965db8aa9685b7b496a9b6fe96c4b67696e1b6719753b69b9c57b8779eb7be039cc2c350'),
			_whitePathFull(hex'4d92bcb3144c93e9b421439331b4219284b42b91d1b42743907ab4218f21b4158dcab40b438db3b4088d9db4028d87b3fb438d91b3e28d9fb3ca8db1b3b6438f0db2bd9077b20a92bcb3145a'),
			_whitePathFull(hex'4d651a13b04365d8128166ac11906812116d43681b1171683d11bd683511c3436738128f66361357653314264c651a13b05a'),
			_whitePathFull(hex'4d86b90c134c87c809d04387a70b1a87890c66875b0db04387520dc786cc0df986af0de24385ec0d4786ca0cb386b90c135a'),
			_whitePathFull(hex'4d49406b64434a7a69ba4b9567ea4d9866f3434de166df4e2d66d54e7966d6434e7d67344ea867a14e8167eb434d6069e14ba76b6e49966c594349746c6949436c59491a6c5a4c49406b645a'),
			_whitePathSimple(hex'708c62707161609271175e88726b5d0f73235f1f72d4613d729b635272936398712f640d709f63dc6fe0639b707f62d0708c6270'),
			_whitePathSimple(hex'aef58675aff8853eb10283edb22482b5b255829eb28b8293b2c18297b2f7829bb32b82acb35882c9b3a2834db3c783e2b3c38479b3bf8511b39285a4b3418623b2b886eab20c8797b1458820b07f88c1afab895fae8e8942aeae8863aecf8783aef58675'),
			_whitePathFull(hex'4d6c5da5a0436d12a48b6e03a5c26eafa536436eb4a5486ec1a5676ebda569436df7a5e86d30a6626c69a6df4c6c5da5a05a')
		);
		results = string.concat(results,
			_blackPathFull(hex'4d8ba3c9834388bcc778897cc4d389f8c237438a30c10f8b25c0218a1dbea5438934bd558b21bce68bf4bc82438f88bae99331b97b971eb8fc439747b8fa9770b9019796b9104397bcb91f97deb93597fbb952439818b96f982fb992983eb9b843984cb9de9853ba069851ba2f439854ba899797badf9789bb43439742bce89713be9196fcc03b4396e9c1f99706c3b7970ac579439709c5cd96b8c66a9694c667439336c63490bdc8938dbec967438d0dc9878c57c9918ba3c98356ccb35a'),
			_whitePathSimple(hex'8d99bf168e01be109485bbc8948cbc1494adbd8b94b1bf059499c07d9487c1ca94afc3db9409c43c91a6c5788f1cc6628c7cc6f58b90c72d8be9c5bc8c08c5298c86c2f38d28c0c18d99bf16'),
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