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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library AccessBitMap {
    struct BitMap {
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(
        BitMap storage bitmap, 
        uint256 tokenId, 
        uint256 brandId, 
        uint256 index
    ) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[tokenId][brandId][bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 tokenId,
        uint256 brandId,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, tokenId, brandId, index);
        } else {
            unset(bitmap, tokenId, brandId, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 tokenId, uint256 brandId, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[tokenId][brandId][bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 tokenId, uint256 brandId, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[tokenId][brandId][bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SoulToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./AccessBitMap.sol";

// TODO: separate logic to separate contract

/**
 * @title KnymblSoul
 * 
 * @dev A soulbound token representing a user's profile in the Knymbl system. 
 * This contract allows users to create a profile, brands to register with the 
 * system, and for users to control those brands access to individual access 
 * points in their personal data.
 * 
 * @author Jack Chuma
 */
contract KnymblSoul is SoulToken, AccessControl {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using AccessBitMap for AccessBitMap.BitMap;
    using BitMaps for BitMaps.BitMap;

    bytes32 constant public ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Brand ID counter
    Counters.Counter brandIdCounter;

    // BitMap to track access points a user has granted to a brand
    AccessBitMap.BitMap userAccessPoints;

    // BitMap to track active access points in the system
    BitMaps.BitMap activeAccessPoints;

    // Mapping from brandID to associated wallet address
    mapping(uint256 => address) brands;

    // Mapping from brandAddress to brandId
    mapping(address => uint256) brandAddressToId;

    // Mapping from tokenId to emailHash
    mapping(uint256 => bytes32) tokenIdToEmail;

    // Mapping from brandId to emailHash
    mapping(uint256 => bytes32) brandIdToEmail;

    // Mapping from emailHash to boolean representing its availability
    mapping(bytes32 => bool) public emailInUse;

    // Mapping from user wallet address to signature nonce
    mapping(address => uint256) public userNonce;

    error SenderDoesNotOwnToken();
    error BrandDoesNotExist();
    error EmailTaken();
    error BrandAddressInUse();
    error InvalidSignature();
    error InvalidNonce();
    error LengthMismatch();
    error InvalidAccessPoint();

    event ProfileCreated(
        address indexed user, 
        uint256 indexed tokenId
    );
    event ProfileAccessUpdated(
        uint256 indexed tokenId, 
        uint256 indexed brandId, 
        uint256[] accessPoints, 
        bool[] accessGranted
    );
    event BrandRegistered(
        uint256 indexed brandId, 
        address indexed brandAddress
    );
    event BrandAddressUpdated(
        uint256 indexed brandId, 
        address indexed fromAddress,
        address indexed toAddress
    );
    event BrandRemoved(
        uint256 indexed brandId
    );
    event AccessPointsToggled(
        uint256[] accessPoints, 
        bool[] active
    );
    event BrandEmailUpdated(
        uint256 indexed brandId,
        bytes32 indexed emailHash
    );
    event UserEmailUpdated(
        uint256 indexed tokenId,
        bytes32 indexed emailHash
    );

    /**
     * @dev Initializes the contract by granting `DEFAULT_ADMIN_ROLE` to 
     * `_admin` and `ADMIN_ROLE` to `msg.sender`.
     */
    constructor(address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /***************************************************************************
     *                            ADMIN FUNCTIONS
     **************************************************************************/

    /**
     * @dev Admin function to add or remove `_accessPoints`.
     */
    function toggleAccessPoints(
        uint256[] calldata _accessPoints, 
        bool[] calldata _activate
    ) external onlyRole(ADMIN_ROLE) {
        uint256 _length = _accessPoints.length;
        if (_length != _activate.length) revert LengthMismatch();

        for (uint256 i; i < _length; ) {
            activeAccessPoints.setTo(_accessPoints[i], _activate[i]);
            unchecked { i++; }
        }

        emit AccessPointsToggled(_accessPoints, _activate);
    }

    /***************************************************************************
     *                         PUBLIC VIEW FUNCTIONS
     **************************************************************************/

    /**
     * @dev Returns true if `_accessPoint` is exposed to `_brandId` for 
     * `_tokenId`.
     */
    function checkAccessPoint(
        uint256 _tokenId, 
        uint256 _brandId, 
        uint256 _accessPoint
    ) external view returns (bool) {
        _brandExists(_brandId);
        _accessPointExists(_accessPoint);
        return userAccessPoints.get(_tokenId, _brandId, _accessPoint);
    }

    /**
     * @dev Returns true if `_accessPoint` is an active access point in the 
     * system.
     */
    function isAccessPointActive(
        uint256 _accessPoint
    ) external view returns (bool) {
        return activeAccessPoints.get(_accessPoint);
    }

    /**
     * @dev Returns the wallet address associated with `_brandId`.
     */
    function getBrandAddress(
        uint256 _brandId
    ) public view returns (address _brand) {
        _brand = brands[_brandId];
        if (_brand == address(0)) revert BrandDoesNotExist();
    }

    /**
     * @dev Returns the brand ID linked to `_brand`. Will revert if no such id 
     * exists.
     */
    function getBrandId(address _brand) external view returns (uint256 _id) {
        _id = brandAddressToId[_brand];
        if (_id == 0) revert BrandDoesNotExist();
    }

    /**
     * @dev Returns the email hash associated with `_tokenId` if it exists.
     */
    function getUserEmailHash(
        uint256 _tokenId
    ) external view returns (bytes32 _hash) {
        _hash = tokenIdToEmail[_tokenId];
        if (_hash == bytes32(0)) revert InvalidTokenId();
    }

    /**
     * @dev Returns the email hash associated with `_brandId` if it exists.
     */
    function getBrandEmailHash(
        uint256 _brandId
    ) external view returns (bytes32) {
        _brandExists(_brandId);
        return brandIdToEmail[_brandId];
    }

    /***************************************************************************
     *                           BRAND FUNCTIONS
     **************************************************************************/

    /**
     * @notice Admin function to register a brand.
     * 
     * @param _signature bytes string representing the signature of the brand.
     * @param _brand address to represent the brand.
     * @param _brandNonce signature nonce of the brand.
     * @param _emailHash hash of the brand's email address.
     */
    function registerBrand(
        bytes calldata _signature, 
        address _brand, 
        uint256 _brandNonce, 
        bytes32 _emailHash
    ) external onlyRole(ADMIN_ROLE) {
        // Generate a new brand ID
        brandIdCounter.increment();
        uint256 _brandId = brandIdCounter.current();

        // Check if the email hash is already in use, if yes, revert
        _emailHashAvailable(_emailHash);
        // Check if the brand address is in use, if yes, revert
        _brandAddressAvailable(_brand);
        // Validate brand's nonce
        _validNonce(_brand, _brandNonce);

        // Re-calculate hash of what _brand should have signed
        bytes32 _hash = keccak256(
            abi.encodePacked(_brand, _brandNonce, _emailHash)
        );
        // Validate the input signature
        _validSignature(_hash, _signature, _brand);

        // Mark email hash as in use
        emailInUse[_emailHash] = true;
        // Map brandId to emailHash
        brandIdToEmail[_brandId] = _emailHash;
        // Map brandId to brand address
        brands[_brandId] = _brand;
        // Map brand address to brandId
        brandAddressToId[_brand] = _brandId;

        emit BrandRegistered(_brandId, _brand);
    }

    /**
     * @notice Admin function to update the stored email hash on behalf of a 
     * brand.
     * 
     * @param _signature bytes string representing the signature of the brand.
     * @param _brandId ID of the brand.
     * @param _nonce signature nonce of the brand.
     * @param _emailHash the new email hash to be set.
     */
    function updateBrandEmailHash(
        bytes calldata _signature,
        uint256 _brandId,
        uint256 _nonce,
        bytes32 _emailHash
    ) external onlyRole(ADMIN_ROLE) {
        // Get the wallet address representing the brand
        address _brand = getBrandAddress(_brandId);
        // Get the current email hash associated with the brand ID
        bytes32 _fromEmailHash = brandIdToEmail[_brandId];

        // Call the update email helper function
        _updateEmail(
            _signature, _brand, _brandId, _nonce, _fromEmailHash, _emailHash
        );

        // Map brand ID to the new email hash
        brandIdToEmail[_brandId] = _emailHash;

        emit BrandEmailUpdated(_brandId, _emailHash);
    }

    /**
     * @notice Admin function to update address representing a brand.
     * 
     * @param _signature bytes string representing the signature of the brand.
     * @param _brandId ID of the brand.
     * @param _brandNonce signature nonce of the brand address.
     * @param _toAddress new address to represent the brand.
     */
    function transferBrand(
        bytes calldata _signature,
        uint256 _brandId, 
        uint256 _brandNonce,
        address _toAddress
    ) external onlyRole(ADMIN_ROLE) {
        // Check if the brand exists and get current address
        address _fromAddress = getBrandAddress(_brandId);
        // Validate the brand's signature nonce
        _validNonce(_fromAddress, _brandNonce);
        // Check if the brand address is in use, if yes, revert
        _brandAddressAvailable(_toAddress);

        // Re-calculate hash of what _fromAddress should have signed
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _brandId, _brandNonce, _fromAddress, _toAddress
            )
        );
        // Validate the input signature
        _validSignature(_hash, _signature, _fromAddress);

        // Map brandId to new address
        brands[_brandId] = _toAddress;
        // Map new address to brandId
        brandAddressToId[_toAddress] = _brandId;
        // Delete the old address from brandAddressToId mapping
        delete brandAddressToId[_fromAddress];

        emit BrandAddressUpdated(_brandId, _fromAddress, _toAddress);
    }
    
    /**
     * @notice Admin function to delete a brand from the system.
     * 
     * @param _signature bytes string representing the signature of the brand 
     * address.
     * @param _brandId ID of the brand.
     * @param _nonce signature nonce of the brand address.
     */
    function removeBrand(
        bytes calldata _signature,
        uint256 _brandId,
        uint256 _nonce
    ) external onlyRole(ADMIN_ROLE) {
        // Get the current address representing the brand
        address _brand = getBrandAddress(_brandId);
        // Validate the brand's signature nonce
        _validNonce(_brand, _nonce);

        // Re-calculate hash of what the brand should have signed
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _brandId, _nonce, "removeBrand"
            )
        );
        // Validate the input signature
        _validSignature(_hash, _signature, _brand);

        // Get the emailHash associated with the brand
        bytes32 _emailHash = brandIdToEmail[_brandId];
        // Delete the email hash from emailInUse mapping
        delete emailInUse[_emailHash];
        // Delete the brandId from brandIdToEmail mapping
        delete brandIdToEmail[_brandId];
        // Delete the brand address from brandAddressToId mapping
        delete brandAddressToId[_brand];
        // Delete the brandId from brands mapping
        delete brands[_brandId];
        
        emit BrandRemoved(_brandId);
    }

    /***************************************************************************
     *                          PROFILE FUNCTIONS
     **************************************************************************/

    /**
     * @notice Admin function to create a profile on behalf of a `_user`.
     * 
     * @param _signature bytes string representing the signature of the user.
     * @param _user address of the user.
     * @param _userNonce signature nonce of the user.
     * @param _emailHash hash of the user's email address.
     */
    function createProfile(
        bytes calldata _signature,
        address _user,
        uint256 _userNonce,
        bytes32 _emailHash
    ) external onlyRole(ADMIN_ROLE) {
        // Generate a new token ID
        uint256 _tokenId = _nextTokenId();

        // Check if the email hash is already in use, if yes, revert
        _emailHashAvailable(_emailHash);
        // Validate user's nonce
        _validNonce(_user, _userNonce);

        // Mark email hash as in use
        emailInUse[_emailHash] = true;
        // Map tokenId to emailHash
        tokenIdToEmail[_tokenId] = _emailHash;

        // Re-calculate hash of what _user should have signed
        bytes32 _hash = keccak256(
            abi.encodePacked(_user, _userNonce, _emailHash)
        );
        // Validate the input signature
        _validSignature(_hash, _signature, _user);

        // Mint token to `_user`
        _mint(_user);

        emit ProfileCreated(_user, _tokenId);
    }

    /**
     * @notice Admin function to update the stored email hash on behalf of a 
     * user.
     * 
     * @param _signature bytes string representing the signature of the user.
     * @param _tokenId ID of the token.
     * @param _nonce signature nonce of the token owner.
     * @param _emailHash the new email hash to be set.
     */
    function updateUserEmailHash(
        bytes calldata _signature,
        uint256 _tokenId,
        uint256 _nonce,
        bytes32 _emailHash
    ) external onlyRole(ADMIN_ROLE) {
        // Get the address of the token's owner
        address _owner = ownerOf(_tokenId);
        // Get the current email hash associated with the token ID
        bytes32 _fromEmailHash = tokenIdToEmail[_tokenId];

        // Call the update email helper function
        _updateEmail(
            _signature, _owner, _tokenId, _nonce, _fromEmailHash, _emailHash
        );

        // Map token ID to the new email hash
        tokenIdToEmail[_tokenId] = _emailHash;

        emit UserEmailUpdated(_tokenId, _emailHash);
    }

    /**
     * @dev Admin function to update what access points `_brandId` has access to 
     * for the owner of `_tokenId`.
     * 
     * @param _signature bytes string representing the signature of the token 
     * owner.
     * @param _tokenId ID of the token.
     * @param _brandId ID of the brand.
     * @param _nonce signature nonce of the token owner.
     * @param _accessPoints array of access point IDs.
     * @param _isGranted array of booleans representing whether access is 
     * granted or not.
     */
    function updateAccess(
        bytes calldata _signature,
        uint256 _tokenId,
        uint256 _brandId,
        uint256 _nonce,
        uint256[] calldata _accessPoints,
        bool[] calldata _isGranted
    ) external onlyRole(ADMIN_ROLE) {
        uint256 _length = _accessPoints.length;
        if (_length != _isGranted.length) revert LengthMismatch();

        // Get the owner of the token
        address _owner = ownerOf(_tokenId);
        // Check if brand exists
        _brandExists(_brandId);
        // Validate user's nonce
        _validNonce(_owner, _nonce);

        // Re-calculate hash of what _user should have signed
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _tokenId, _brandId, _nonce, _accessPoints, _isGranted
            )
        );
        // Validate the input signature
        _validSignature(_hash, _signature, _owner);

        // Update the access points
        for (uint256 i; i < _length; ) {
            // Validate the access point
            _accessPointExists(_accessPoints[i]);
            // Update the userAccessPionts bitmap
            userAccessPoints.setTo(
                _tokenId, 
                _brandId, 
                _accessPoints[i], 
                _isGranted[i]
            );

            unchecked { i++; }
        }

        emit ProfileAccessUpdated(
            _tokenId, _brandId, _accessPoints, _isGranted
        );
    }

    /**
     * @notice Admin function to delete a profile associated with a specific 
     * token ID.
     * 
     * @param _signature bytes string representing the signature of the token 
     * owner.
     * @param _tokenId ID of the token.
     * @param _nonce signature nonce of the token owner.
     */
    function deleteProfile(
        bytes calldata _signature,
        uint256 _tokenId,
        uint256 _nonce
    ) external onlyRole(ADMIN_ROLE) {
        // Get the owner of the token
        address _owner = ownerOf(_tokenId);
        // Validate the user's nonce
        _validNonce(_owner, _nonce);

        // Re-calculate the hash of what the user should have signed
        bytes32 _hash = keccak256(
            abi.encodePacked(_tokenId, _nonce, "deleteProfile")
        );
        // Validate the input signature
        _validSignature(_hash, _signature, _owner);

        // Get the emailHash associated with the token
        bytes32 _emailHash = tokenIdToEmail[_tokenId];
        // Delete the email hash from emailInUse mapping
        delete emailInUse[_emailHash];
        // Delete the tokenId from tokenIdToEmail mapping
        delete tokenIdToEmail[_tokenId];
        // Burn the token
        _burn(_tokenId);
    }

    /***************************************************************************
     *                     PRIVATE CONTRACT FUNCTIONS
     **************************************************************************/

    /**
     * @dev Reverts if `_brandId` does not exist.
     */
    function _brandExists(uint256 _brandId) private view {
        if (brands[_brandId] == address(0)) revert BrandDoesNotExist();
    }

    /**
     * @dev Reverts if `_accessPoint` does not exist.
     */
    function _accessPointExists(uint256 _accessPoint) private view {
        if (!activeAccessPoints.get(_accessPoint)) 
                revert InvalidAccessPoint();
    }

    function _emailHashAvailable(bytes32 _emailHash) private view {
        if (emailInUse[_emailHash]) revert EmailTaken();
    }

    /**
     * @dev Reverts if incoming `_nonce` for `_addr` is not the expected nonce. 
     * This prevents replay signature attacks.
     */
    function _validNonce(address _addr, uint256 _nonce) private {
        if (_nonce != userNonce[_addr]) revert InvalidNonce();
        unchecked { userNonce[_addr]++; }
    }

    /**
     * @dev Reverts if `_signature` is not a valid signature from `_signer` on 
     * `_hash`.
     */
    function _validSignature(
        bytes32 _hash, 
        bytes calldata _signature, 
        address _signer
    ) private pure {
        if (_hash.toEthSignedMessageHash().recover(_signature) != _signer) 
            revert InvalidSignature();
    }

    /**
     * @dev Reverts if `_brand` is already in use.
     */
    function _brandAddressAvailable(address _brand) private view {
        if (brandAddressToId[_brand] > 0) revert BrandAddressInUse();
    }

    /**
     * @dev Helper function to update the stored email hash for a tokenId or 
     * brandId.
     */
    function _updateEmail(
        bytes calldata _signature, 
        address _controller, 
        uint256 _id, 
        uint256 _nonce, 
        bytes32 _fromEmailHash, 
        bytes32 _toEmailHash
    ) private {
        _validNonce(_controller, _nonce);
        _emailHashAvailable(_toEmailHash);

        bytes32 _hash = keccak256(
            abi.encodePacked(
                _id, _nonce, _fromEmailHash, _toEmailHash
            )
        );
        _validSignature(_hash, _signature, _controller);

        emailInUse[_fromEmailHash] = false;
        emailInUse[_toEmailHash] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Soulbound Token
 * 
 * @dev The implementation of a non-transferable token
 * 
 * @author Jack Chuma
 */
contract SoulToken {
    // The next token ID to be minted
    uint256 _currentIndex;

    // The number of tokens burned
    uint256 _burnCounter;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping from owner address to tokenId
    mapping(address => uint256) _ownedToken;

    error ZeroAddress();
    error InvalidTokenId();
    error NonSoulReceiver();
    error AddressAlreadyOwnsToken();

    event TokenMinted(address indexed to, uint256 indexed tokenId);
    event TokenBurned(address indexed from, uint256 indexed tokenId);

    /**
     * @dev Initializes the contract by setting the starting token ID.
     */
    constructor() {
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the owner of the `_tokenId` token.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = _ownerOf(_tokenId);
        if (_owner == address(0)) revert InvalidTokenId();
    }

    /**
     * @dev Returns the tokenId owned by `_addr`.
     * 
     * Requirements:
     * 
     * - `_addr` must own a token.
     */
    function tokenOwned(address _addr) public view returns (uint256 _tokenId) {
        _tokenId = _tokenOwned(_addr);
        if (_tokenId == 0) revert NonSoulReceiver();
    }

    /**
     * @dev Returns the owner of the `_tokenId`. Does NOT revert if token 
     * doesn't exist
     */
    function _ownerOf(uint256 _tokenId) internal view returns (address) {
        return _owners[_tokenId];
    }

    /**
     * @dev Returns the token ID owned by `_addr`.
     */
    function _tokenOwned(address _addr) internal view returns (uint256) {
        return _ownedToken[_addr];
    }

    /**
     * @dev Mints `_tokenId` and transfers it to `_to`.
     *
     * Requirements:
     *
     * - `_tokenId` must not exist.
     * - `_to` cannot be the zero address.
     * - `_to` must not already own a token.
     *
     * Emits a {TokenMinted} event.
     */
    function _mint(address _to) internal {
        if (_to == address(0)) revert ZeroAddress();
        if (_ownedToken[_to] > 0) revert AddressAlreadyOwnsToken();

        uint256 _tokenId = _currentIndex;
        unchecked { _currentIndex++; }

        _ownedToken[_to] = _tokenId;
        _owners[_tokenId] = _to;

        emit TokenMinted(_to, _tokenId);
    }

    /**
     * @dev Destroys `_tokenId`.
     * This is an internal function that does not check if the sender is 
     * authorized to operate on the token.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     *
     * Emits a {TokenBurned} event.
     */
    function _burn(uint256 _tokenId) internal {
        address _owner = _ownerOf(_tokenId);

        delete _ownedToken[_owner];
        delete _owners[_tokenId];

        unchecked { _burnCounter++; }

        emit TokenBurned(_owner, _tokenId);
    }
}