// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Types } from "./Types.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Helpers {
    function uint2string(uint256 value) internal pure returns (string memory) {
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

    function _verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }

    function _hash(
        Types.TokenGatedMintArgs memory args,
        uint256 deadline,
        uint16 seasonId
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        args.tokenId,
                        args.amount,
                        args.tokenGatedId,
                        seasonId,
                        deadline,
                        args.pass,
                        address(this)
                    )
                )
            );
    }

    function readableStablePrice(
        uint256 stableMintPrice
    ) internal pure returns (string memory) {
        uint256 dollars = stableMintPrice / 1000000;
        uint256 cents = (stableMintPrice / 10000) % 100;
        return
            string(
                abi.encodePacked(
                    Helpers.uint2string(dollars),
                    ".",
                    Helpers.uint2string(cents)
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Types {
    struct TokenGatedMintArgs {
        uint256 tokenId;
        uint256 amount;
        uint256 tokenGatedId;
        address pass;
    }

    struct MintArgs {
        uint256[] tokenIds;
        uint256[] amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Errors {
    error WithdrawalPercentageWrongSize();
    error WithdrawalPercentageNot100();
    error WithdrawalPercentageZero();
    error MintNotAvailable();
    error InsufficientFunds();
    error SupplyLimitReached();
    error ContractCantMint();
    error InvalidSignature();
    error AccountAlreadyMintedMax();
    error TokenDoesNotExist();
    error NotOwner();
    error NotAuthorized();
    error MaxSupplyTooSmall();
    error CanNotIncreaseMaxSupply();
    error InvalidOwner();
    error TokenNotTransferable();

    error RoyaltiesPercentageTooHigh();
    error NothingToWithdraw();
    error WithdrawFailed();

    /* ReentrancyGuard.sol */
    error ContractLocked();

    /* Signable.sol */
    error NewSignerCantBeZero();

    /* StableMultiMintERC721.sol */
    error PaymentTypeNotEnabled();

    /* AgoriaXLedger.sol */
    error WrongInputSize();
    error IdBeyondSupplyLimit();
    error InvalidBaseContractURL();
    error InvalidBaseURI();

    /* MultiMint1155.sol */
    error MismatchLengths();
    error AccountMaxMintAmountExceeded();
    error InvalidMintMaxAmount();
    error InvalidMintPrice();
    error InsufficientBalance();
    error TokenSaleClosed(uint256 tokenId);
    error TokenGatedIdAlreadyUsed(uint256 tokenGatedId);
    error TokenAlreadyMinted();
    error MintDeadlinePassed();
    error TokenGatedIdAlreadyUsedInSeason(
        uint256 tokenGatedId,
        uint256 seasonId
    );
    error TokenNotSupported();
    error InvalidDeadlineLength();
    error OneTokenPerPass();
    error SignatureLengthMismatch();
    error TokenPriceNotSet();
    error DeadlineNotSet();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ERC1155 } from "@rari-capital/solmate/src/tokens/ERC1155.sol";

import { Signable } from "../generic/Signable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { Errors } from "../generic/Errors.sol";
import { Helpers } from "../Helpers.sol";
import { Types } from "../Types.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title MultiMint ERC1155
 */
contract MultiMint1155 is ERC1155, Signable, IERC2981, AccessControl {
    event FeaturesEnabled(Feature[] features);
    event FeatureStatusChanged(Feature features, bool status);
    event MaxSupplyPerTokenChanged(uint256[] tokenIds, uint256[] maxSupplies);
    event SeasonUpdated(uint16 seasonId);
    event ETHMintPricePerTokenChanged(uint256[] tokenIds, uint256[] prices);
    event TokenURIChanged(uint256 tokenId, string tokenURI);
    event TokenTypesChanged(address[] tokens, TokenType[] tokenTypes);
    event TokenDeadlinesChanged(uint256[] tokenIds, uint256[][] deadlines);
    event ContractURIChanged(string contractUri);
    event DefaultMaxMintChanged(uint256 defaultMaxMint);
    event MaxMintPerTokenChanged(uint256[] tokenIds, uint256[] maxMints);
    event RoyaltiesPercentageChanged(uint256 tokenId, uint256 percentage);
    event RoyaltiesSplitAddressChanged(address royaltiesSplitAddress);

    struct WithdrawalAddress {
        address account;
        uint96 percentage;
    }

    enum Feature {
        MINTER_CAN_MINT,
        ETH_WITH_SIGN,
        ETH_PUBLIC
    }

    enum TokenType {
        NONE,
        INFINITY,
        GENESIS
    }

    /*//////////////////////////////-////////////////////////////////
                            Storage
    ////////////////////////////////-//////////////////////////////*/
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Addresses where money from the contract will go if the owner of the contract will call withdraw function
    WithdrawalAddress[] public withdrawalAddresses;

    // Bit mapping of active features
    uint256 private featureEnabledBitMap;

    // Base contract URI
    string private baseContractURI;

    // Token URIs
    mapping(uint256 => string) private tokenURIs;

    /// @notice Mint prices, can be configured
    /// @return supply per specified token
    mapping(uint256 => uint256) public mintPrices;

    /// @notice Max supply per token
    /// @return supply per specified token
    mapping(uint256 => uint256) public maxSupplyPerToken;

    /// @notice Current supply per token
    /// @return supply per specified token
    mapping(uint256 => uint256) public currentSupplyPerToken;

    /// @notice Number of already minted tokens per account
    /// @return mapping
    mapping(address => mapping(uint256 => uint256)) public minted;

    /// @notice SeasonId for which signature will be valid for private sales. If seasonId is changed all signatures will be invalid and new ones should be generated
    uint16 public seasonId;

    /// @notice Token type per token
    mapping(address => TokenType) public tokenTypes;

    /// @notice Token deadlines
    mapping(uint256 => uint256[]) public tokenDeadlines;

    /// @notice Default max mint for an account on the public sale if specific mint for token is not specified.
    /// @return default number of mints
    uint256 public defaultMaxMint = 1000;

    /// @notice Max mint amounts, can be configured
    /// @return list of tokens with their's max amounts
    mapping(uint256 => uint256) public maxMintPerToken;

    /// @notice Used TokenGated Ids
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool))))
        public usedInfinityPasses;

    /// @notice Used TokenGated Ids within a season
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))))
        public usedGenesisPasses;

    address public royaltiesSplitAddress;

    // Base is 10000, 1000 = 10%
    mapping(uint256 => uint256) private royaltiesPercentage;

    /*//////////////////////////////-////////////////////////////////
                                Modifiers
    ////////////////////////////////-//////////////////////////////*/

    modifier checkCosts(Types.TokenGatedMintArgs[] calldata args) {
        Types.TokenGatedMintArgs[] memory tmpArgs = args;

        uint256 totalCost = 0;

        for (uint256 i; i < tmpArgs.length; ) {
            totalCost += priceETH(tmpArgs[i].tokenId, tmpArgs[i].amount);

            unchecked {
                ++i;
            }
        }

        if (msg.value < totalCost) revert Errors.InsufficientFunds();
        _;
    }

    // Modifier is used to check if the feature rule is met
    modifier featureRequired(Feature feature_) {
        if (!isFeatureEnabled(feature_)) revert Errors.MintNotAvailable();
        _;
    }

    // Modifier is used to check if the signature is still valid
    modifier onlyWithinDeadline(uint256[] calldata deadlines) {
        for (uint256 i; i < deadlines.length; ) {
            if (block.timestamp > deadlines[i]) {
                revert Errors.MintDeadlinePassed();
            }
            unchecked {
                ++i;
            }
        }

        _;
    }

    /**
     * @notice Checks the validity of a given token based on its deadlines.
     * @param tokenId The ID of the token to check validity for.
     * @dev This function reverts with an error message if the deadlines have not been set for the token or if the current block timestamp falls outside the token's specified deadlines.
     */
    function checkTokenValidity(uint256 tokenId) internal view {
        uint256[] memory deadlines = tokenDeadlines[tokenId];
        if (deadlines.length == 0) {
            revert Errors.DeadlineNotSet();
        }

        if (
            block.timestamp < tokenDeadlines[tokenId][0] ||
            block.timestamp > tokenDeadlines[tokenId][1]
        ) {
            revert Errors.TokenSaleClosed(tokenId);
        }
    }

    function onlyMatchingLengths(uint256 a, uint256 b) internal pure {
        if (a != b) revert Errors.MismatchLengths();
    }

    /**
     * @notice Initialize the contract. Call once upon deploy.
     * @param _baseContractURI The base URI used for generating contract-level metadata URI.
     * @param _royaltiesSplitAddress Address of the account that receives a percentage of each sale as royalties.
     * @param _withdrawalAddresses An array of WithdrawalAddress struct, which represents the payees and their respective percentages of the revenue. The length of the array must be greater than zero and the sum of all percentages must equal 100.
     */
    constructor(
        string memory _baseContractURI,
        address _royaltiesSplitAddress,
        WithdrawalAddress[] memory _withdrawalAddresses
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        baseContractURI = _baseContractURI;
        royaltiesSplitAddress = _royaltiesSplitAddress;

        uint256 length = _withdrawalAddresses.length;
        if (length == 0) revert Errors.WithdrawalPercentageWrongSize();

        uint256 sum;
        for (uint256 i; i < length; ) {
            uint256 percentage = _withdrawalAddresses[i].percentage;
            if (percentage == 0) revert Errors.WithdrawalPercentageZero();
            sum += percentage;
            withdrawalAddresses.push(_withdrawalAddresses[i]);
            unchecked {
                ++i;
            }
        }
        if (sum != 100) revert Errors.WithdrawalPercentageNot100();
    }

    /*//////////////////////////////-////////////////////////////////
                            External functions
    ////////////////////////////////-//////////////////////////////*/

    /**
     * @notice Account with a MINTER_ROLE can call this function to mint `amounts` of specified tokens into account with the address `to`
     * @param to Address on which tokens will be minted
     * @param tokenId The ID of the token to mint
     * @param amount The amount of the token to mint
     * @param data Tokens
     */
    function minterMint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) featureRequired(Feature.MINTER_CAN_MINT) {
        _mintLogic(to, tokenId, amount, data, false);
    }

    /**
     * @notice Mint function used with signature. Must be executed by an account with a MINTER_ROLE.
     * @dev This function mints the given tokens for the msg.sender, after verifying the signature for each mint request.
     * @param args An array of TokenGatedMintArgs struct, which represents the tokens to be minted and the pass required to mint them.
     * @param signatures An array of bytes, which represents the signature for each TokenGatedMintArgs struct.
     * @param deadlines An array of uint256, which represents the deadline timestamp for each signature.
     */
    function minterMintSign(
        Types.TokenGatedMintArgs[] calldata args,
        bytes[] calldata signatures,
        uint256[] calldata deadlines,
        bytes calldata data
    )
        external
        onlyRole(MINTER_ROLE)
        featureRequired(Feature.MINTER_CAN_MINT)
        featureRequired(Feature.ETH_WITH_SIGN)
        onlyWithinDeadline(deadlines)
    {
        _mintSignLogic(args, signatures, deadlines, data);
    }

    /**
     * @notice Function used to do minting (with signature). Contract feature `ETH_PUBLIC` must be enabled
     * @param tokenId The ID of the token to mint
     * @param amount The amount of the token to mint
     * @param data data
     */
    function mint(
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external payable featureRequired(Feature.ETH_PUBLIC) {
        checkTokenValidity(tokenId);

        if (msg.value < priceETH(tokenId, amount)) {
            revert Errors.InsufficientFunds();
        }

        _mintLogic(msg.sender, tokenId, amount, data, false);
    }

    /**
     * @notice Mint function used with signature.
     * @dev This function mints the given tokens for the msg.sender, after verifying the signature for each mint request.
     * @param args An array of TokenGatedMintArgs struct, which represents the tokens to be minted and the pass required to mint them.
     * @param signatures An array of bytes, which represents the signature for each TokenGatedMintArgs struct.
     * @param deadlines An array of uint256, which represents the deadline timestamp for each signature.
     */
    function mintSign(
        Types.TokenGatedMintArgs[] calldata args,
        bytes[] calldata signatures,
        uint256[] calldata deadlines,
        bytes calldata data
    )
        external
        payable
        featureRequired(Feature.ETH_WITH_SIGN)
        checkCosts(args)
        onlyWithinDeadline(deadlines)
    {
        _mintSignLogic(args, signatures, deadlines, data);
    }

    /**
     * @notice Burn specified amount of a given token ID from the specified token owner address
     * @param tokenId The ID of the token to burn
     * @param amount The amount of the token to burn
     * @param tokenOwner The address of the token owner whose tokens will be burned
     * @dev Only callable by an account with the BURNER_ROLE
     * @dev If the specified token owner does not have a sufficient balance of the given token to burn, this function will revert with an InsufficientBalance error
     * @dev Decreases the token owner's balance of the given token by the specified amount and decreases the current supply of the given token by the same amount
     */
    function burn(
        uint256 tokenId,
        uint256 amount,
        address tokenOwner
    ) external onlyRole(BURNER_ROLE) {
        if (balanceOf[tokenOwner][tokenId] < amount) {
            revert Errors.InsufficientBalance();
        }

        super._burn(tokenOwner, tokenId, amount);

        unchecked {
            minted[tokenOwner][tokenId] -= amount;
            currentSupplyPerToken[tokenId] -= amount;
        }
    }

    /**
     * @notice Contract owner can call this function to withdraw all ETH from the contract into a defined wallet
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.NothingToWithdraw();

        uint256 length = withdrawalAddresses.length;
        for (uint256 i; i < length; ) {
            uint256 percentage = withdrawalAddresses[i].percentage;
            address withdrawalAddress = withdrawalAddresses[i].account;
            uint256 value = (balance * percentage) / 100;

            (withdrawalAddress.call{ value: value }(""));

            unchecked {
                ++i;
            }
        }

        balance = address(this).balance;

        if (balance > 0) {
            withdrawalAddresses[0].account.call{ value: balance }("");
        }
    }

    /*//////////////////////////////-////////////////////////////////
                                Setters
    ////////////////////////////////-//////////////////////////////*/

    /**
     * @notice Set the enabled features for the contract
     * @param features An array of Feature enum values representing the features to be enabled
     * @dev Sets the featureEnabledBitMap variable to a bit map with the features that are enabled. Each bit position in the bit map corresponds to a Feature enum value, with a bit value of 1 indicating that the feature is enabled and 0 indicating that it is disabled.This function can only be called by the owner of the contract.
     */
    function setEnabledFeatures(Feature[] memory features) external onlyOwner {
        uint256 featuresBitMap = 0;
        for (uint256 i = 0; i < features.length; i++) {
            uint256 featureIndex = uint256(features[i]);
            featuresBitMap = featuresBitMap | (1 << featureIndex);
        }
        featureEnabledBitMap = featuresBitMap;
        emit FeaturesEnabled(features);
    }

    /**
     * @notice Sets the status of a particular feature
     * @param feature The feature to set the status for
     * @param status The desired status for the feature
     * If status is true, the feature will be enabled, otherwise it will be disabled.
     */
    function setFeatureStatus(Feature feature, bool status) external onlyOwner {
        uint256 featureIndex = uint256(feature);
        if (status == true) {
            featureEnabledBitMap = featureEnabledBitMap | (1 << featureIndex);
        } else {
            featureEnabledBitMap = featureEnabledBitMap & ~(1 << featureIndex);
        }

        emit FeatureStatusChanged(feature, status);
    }

    /**
     * @notice Set max supply specified token.
     * @param tokenIds_ Token Ids
     * @param maxSupplies_ Supplies of corresponding tokens by indexes
     */
    function setMaxSupplyPerToken(
        uint256[] calldata tokenIds_,
        uint256[] calldata maxSupplies_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, maxSupplies_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            maxSupplyPerToken[tokenIds_[i]] = maxSupplies_[i];
            unchecked {
                i++;
            }
        }

        emit MaxSupplyPerTokenChanged(tokenIds_, maxSupplies_);
    }

    /**
     * @notice Increment season.
     * @dev When season is incremented, all issued signatures become invalid.
     */
    function updateSeason() external onlyOwner {
        ++seasonId;
        emit SeasonUpdated(seasonId);
    }

    /**
     * @notice Set mint prices for specified tokens. Override default mint price for specified tokens
     * @param tokenIds_ Token Ids
     * @param mintPrices_ Prices of corresponding tokens by indexes
     */
    function setETHMintPricePerToken(
        uint256[] calldata tokenIds_,
        uint256[] calldata mintPrices_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, mintPrices_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            mintPrices[tokenIds_[i]] = mintPrices_[i];
            unchecked {
                i++;
            }
        }

        emit ETHMintPricePerTokenChanged(tokenIds_, mintPrices_);
    }

    /**
     * @notice Sets a new URI for all token types, by relying on the token type ID
     * @param tokenId_ tokenId for which uri to be set
     * @param uri_ Used as the URI for token type
     */
    function setTokenURI(
        uint256 tokenId_,
        string calldata uri_
    ) external onlyOwner {
        if (bytes(uri_).length == 0) {
            revert Errors.InvalidBaseURI();
        }
        tokenURIs[tokenId_] = uri_;

        emit TokenURIChanged(tokenId_, uri_);
    }

    /**
     * @notice Set token type
     * @param addresses_ array of token addresses
     * @param types_ types of token passes
     * @dev set infinity or genesis
     */
    function setTokenTypes(
        address[] calldata addresses_,
        TokenType[] calldata types_
    ) external onlyOwner {
        onlyMatchingLengths(addresses_.length, types_.length);
        for (uint256 i; i < addresses_.length; ) {
            tokenTypes[addresses_[i]] = types_[i];
            unchecked {
                i++;
            }
        }

        emit TokenTypesChanged(addresses_, types_);
    }

    /**
     * @notice Set token deadline
     * @param tokenIds_ token address
     * @param deadlines_ token address
     * @dev set infinity or genesis
     */
    function setTokenDeadlines(
        uint256[] calldata tokenIds_,
        uint256[][] calldata deadlines_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, deadlines_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            if (deadlines_[i].length != 2) {
                revert Errors.InvalidDeadlineLength();
            }

            tokenDeadlines[tokenIds_[i]] = deadlines_[i];
            unchecked {
                i++;
            }
        }

        emit TokenDeadlinesChanged(tokenIds_, deadlines_);
    }

    /**
     * @notice Set contract URI
     * @param baseContractURI_ Base contract URI
     */
    function setContractURI(
        string calldata baseContractURI_
    ) external onlyOwner {
        if (bytes(baseContractURI_).length == 0)
            revert Errors.InvalidBaseContractURL();

        baseContractURI = baseContractURI_;
        emit ContractURIChanged(baseContractURI_);
    }

    /**
     * @notice Set default max mint amount for all tokens
     * @param defaultMaxMint_ default max mint amount
     */
    function setDefaultMaxMint(uint256 defaultMaxMint_) external onlyOwner {
        defaultMaxMint = defaultMaxMint_;
        emit DefaultMaxMintChanged(defaultMaxMint_);
    }

    /**
     * @notice Set max supply specified token.
     * @param tokenIds_ Token Ids
     * @param maxMints_ Max mints of corresponding tokens by indexes
     */
    function setMaxMintPerToken(
        uint256[] calldata tokenIds_,
        uint256[] calldata maxMints_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, maxMints_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            maxMintPerToken[tokenIds_[i]] = maxMints_[i];
            unchecked {
                i++;
            }
        }

        emit MaxMintPerTokenChanged(tokenIds_, maxMints_);
    }

    /**
     * @notice Sets the royalties percentage for a given token.
     * @param tokenId The ID of the token to set royalties percentage for.
     * @param royaltiesPercentage_ The new royalties percentage for the token.
     * @dev This function can only be called by the owner of the contract. If the provided royalties percentage is greater than 10000, this function will revert with an error message. Otherwise, it sets the new royalties percentage for the token and emits a `RoyaltiesPercentageChanged` event.
     */
    function setRoyaltiesPercentage(
        uint256 tokenId,
        uint256 royaltiesPercentage_
    ) external onlyOwner {
        if (royaltiesPercentage_ > 10000) {
            revert Errors.RoyaltiesPercentageTooHigh();
        }
        royaltiesPercentage[tokenId] = royaltiesPercentage_;
        emit RoyaltiesPercentageChanged(tokenId, royaltiesPercentage_);
    }

    /**
     * @notice Sets the address to which royalties will be split.
     * @param royaltiesSplitAddress_ The new address to which royalties will be split.
     * @dev This function can only be called by the owner of the contract. It sets the new royalties split address and emits a `RoyaltiesSplitAddressChanged` event.
     */
    function setRoyaltiesSplitAddress(
        address royaltiesSplitAddress_
    ) external onlyOwner {
        royaltiesSplitAddress = royaltiesSplitAddress_;
        emit RoyaltiesSplitAddressChanged(royaltiesSplitAddress);
    }

    /*//////////////////////////////-////////////////////////////////
                                Getters
    ////////////////////////////////-//////////////////////////////*/

    /**
     * @notice Return contract URI
     * @return Contract URI
     */
    function contractURI() external view returns (string memory) {
        return baseContractURI;
    }

    /**
     * @notice Calculate total price of specified tokens depends on their's amounts
     * @param tokenIds List of tokens
     * @param amounts Amounts of corresponding tokens by indexes
     * @return totalPrice Total price
     */
    function totalPriceETH(
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public view returns (uint totalPrice) {
        for (uint i; i < tokenIds.length; ) {
            totalPrice += priceETH(tokenIds[i], amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Get price of specified token depends on it's amount
     * @param tokenId Token
     * @param amount Amounts of token
     * @return Token Price
     */
    function priceETH(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        return mintPrices[tokenId] * amount;
    }

    function isFeatureEnabled(Feature feature) public view returns (bool) {
        return (featureEnabledBitMap & (1 << uint256(feature))) != 0;
    }

    function uri(
        uint256 tokenId_
    ) public view override returns (string memory) {
        return tokenURIs[tokenId_];
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155, AccessControl, IERC165)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /**
     * @dev See IERC2981
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (
            royaltiesSplitAddress,
            (salePrice * royaltiesPercentage[tokenId]) / 10000
        );
    }

    /**
     * @notice Maximum mint per token
     * @param tokenId, Token
     * @return Max mint amount per token
     */
    function getMaxMintPerToken(uint256 tokenId) public view returns (uint256) {
        return
            maxMintPerToken[tokenId] > 0
                ? maxMintPerToken[tokenId]
                : defaultMaxMint;
    }

    /*//////////////////////////////-////////////////////////////////
                            Private functions
    ////////////////////////////////-//////////////////////////////*/

    function _mintSignLogic(
        Types.TokenGatedMintArgs[] calldata args,
        bytes[] calldata signatures,
        uint256[] calldata deadlines,
        bytes calldata data
    ) private {
        Types.TokenGatedMintArgs[] memory tmpArgsArr = args;
        uint256[] memory tmpDeadlines = deadlines;
        bytes[] memory tmpSignatures = signatures;
        bytes memory tmpData = data;

        onlyMatchingLengths(tmpArgsArr.length, tmpSignatures.length);
        onlyMatchingLengths(tmpSignatures.length, tmpDeadlines.length);

        for (uint i = 0; i < tmpArgsArr.length; ) {
            if (
                tokenTypes[tmpArgsArr[i].pass] != TokenType.GENESIS &&
                tokenTypes[tmpArgsArr[i].pass] != TokenType.INFINITY
            ) {
                revert Errors.TokenNotSupported();
            }

            Types.TokenGatedMintArgs memory tmpArgs = tmpArgsArr[i];

            checkTokenValidity(tmpArgs.tokenId);

            if (
                !Helpers._verify(
                    signer(),
                    Helpers._hash(tmpArgs, tmpDeadlines[i], seasonId),
                    tmpSignatures[i]
                )
            ) revert Errors.InvalidSignature();

            if (tokenTypes[tmpArgs.pass] == TokenType.GENESIS) {
                _processGenesisPass(
                    tmpArgs.pass,
                    tmpArgs.tokenGatedId,
                    tmpArgs.tokenId
                );
            } else {
                _processInfinityPass(tmpArgs.pass, tmpArgs.tokenGatedId);
            }

            _mintLogic(
                msg.sender,
                tmpArgs.tokenId,
                tmpArgs.amount,
                tmpData,
                true
            );

            unchecked {
                ++i;
            }
        }
    }

    function _processGenesisPass(
        address pass,
        uint256 tokenGatedId,
        uint256 tokenId
    ) private {
        if (usedGenesisPasses[pass][tokenGatedId][seasonId][tokenId]) {
            revert Errors.TokenGatedIdAlreadyUsed(tokenGatedId);
        }

        usedGenesisPasses[pass][tokenGatedId][seasonId][tokenId] = true;
    }

    function _processInfinityPass(address pass, uint256 tokenGatedId) private {
        if (usedInfinityPasses[pass][tokenGatedId][msg.sender][seasonId]) {
            revert Errors.TokenGatedIdAlreadyUsedInSeason(
                tokenGatedId,
                seasonId
            );
        }
        usedInfinityPasses[pass][tokenGatedId][msg.sender][seasonId] = true;
    }

    function _mintLogic(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data,
        bool isTokenGated
    ) private {
        if (
            currentSupplyPerToken[tokenId] + amount > maxSupplyPerToken[tokenId]
        ) {
            revert Errors.SupplyLimitReached();
        }

        if (
            !isTokenGated &&
            minted[to][tokenId] + amount > getMaxMintPerToken(tokenId)
        ) {
            revert Errors.AccountAlreadyMintedMax();
        }

        minted[to][tokenId] += amount;
        currentSupplyPerToken[tokenId] += amount;

        super._mint(to, tokenId, amount, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@rari-capital/solmate/src/auth/Owned.sol";

/// @title Contract that manages the signer/owner roles
abstract contract Signable is Owned {
    error NewSignerCantBeZero();

    address private _signer;

    constructor() Owned(msg.sender) {
        _signer = msg.sender;
    }

    function signer() public view returns (address) {
        return _signer;
    }

    /// @notice This method allow the owner change the signer role
    /// @dev At first, the signer role and the owner role is associated to the same address
    /// @param newSigner The address of the new signer
    function transferSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) revert NewSignerCantBeZero();

        _signer = newSigner;
    }
}