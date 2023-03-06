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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/IBridgeV2.sol";
import "../utils/Block.sol";
import "../utils/Bls.sol";
import "../utils/Merkle.sol";
import "../utils/RequestIdChecker.sol";
// TODO typecast to lib
import "../utils/Typecast.sol";


contract BridgeV2 is IBridgeV2, AccessControl, Typecast {
    
    using Address for address;
    using Bls for Bls.Epoch;

    /// @dev gate keeper role id.
    bytes32 public constant GATEKEEPER_ROLE = keccak256("GATEKEEPER_ROLE");
    /// @dev human readable version
    string public version;
    /// @dev current state Active\Inactive
    State public state;
    /// @dev nonces
    mapping(address => uint256) public nonces;
    /// @dev received request IDs against relay
    RequestIdChecker public currentRequestIdChecker;
    /// @dev received request IDs against relay
    RequestIdChecker public previousRequestIdChecker;
    // current epoch
    Bls.Epoch internal currentEpoch;
    // previous epoch
    Bls.Epoch internal previousEpoch;
    /// @dev empty reserved space - https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[49] private __gap;

    event EpochUpdated(bytes key, uint32 epochNum, uint64 protocolVersion);

    event RequestSent(
        address from,
        bytes32 requestId,
        bytes data,
        address to,
        uint256 chainIdTo
    );

    event RequestReceived(bytes32 requestId, address to, bytes32 from, uint256 chainIdFrom, string error);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        version = "2.2.3";
        currentRequestIdChecker = new RequestIdChecker();
        previousRequestIdChecker = new RequestIdChecker();
        state = State.Inactive;
    }

    /**
     * @dev Get current epoch.
     */
    function getCurrentEpoch() public view returns (bytes memory, uint8, uint32) {
        return (abi.encode(currentEpoch.publicKey), currentEpoch.participantsCount, currentEpoch.epochNum);
    }

    /**
     * @dev Get previous epoch.
     */
    function getPreviousEpoch() public view returns (bytes memory, uint8, uint32) {
        return (abi.encode(previousEpoch.publicKey), previousEpoch.participantsCount, previousEpoch.epochNum);
    }

    /**
     * @dev Updates current epoch.
     *
     * @param params ReceiveParams struct.
     */
    function updateEpoch(ReceiveParams calldata params) external {
        // TODO ensure that new epoch really next one after previous (by hash)
        bytes memory payload = Merkle.prove(params.merkleProof, Block.txRootHash(params.blockHeader));
        (uint64 newEpochProtocolVersion, uint32 newEpochNum, bytes memory newKey, uint8 newParticipantsCount) = Block
            .decodeEpochUpdate(payload);

        require(currentEpoch.epochNum + 1 == newEpochNum, "Bridge: wrong epoch number");
    
        // TODO remove if when resetEpoch will be removed
        if (currentEpoch.isSet()) {
            verifyEpoch(currentEpoch, params);
            rotateEpoch();
        }

        // TODO ensure that new epoch really next one after previous (prev hash + params.blockHeader)
        bytes32 newHash = sha256(params.blockHeader);
        currentEpoch.update(newKey, newParticipantsCount, newEpochNum, newHash);

        onEpochStart(newEpochProtocolVersion);
    }

    /**
     * @dev Forcefully reset epoch on all chains.
     */
    function resetEpoch() public onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO consider to remove any possible manipulations from protocol
        rotateEpoch();
        currentEpoch.epochNum = previousEpoch.epochNum + 1;
        emit EpochUpdated(abi.encode(currentEpoch.publicKey), currentEpoch.epochNum, 0);
    }

    /**
     * @dev Send crosschain request v2.
     *
     * @param params struct with requestId, data, receiver and opposite cahinId
     * @param from sender's address
     * @param nonce sender's nonce
     */
    function sendV2(
        SendParams calldata params,
        address from,
        uint256 nonce
    ) external virtual override onlyRole(GATEKEEPER_ROLE) returns (bool) {
        require(state == State.Active, "Bridge: state inactive");
        require(currentEpoch.isSet(), "Bridge: epoch not set");
    
        verifyAndUpdateNonce(from, nonce);

        emit RequestSent(
            from,
            params.requestId,
            params.data,
            params.to,
            params.chainIdTo
        );

        return true;
    }

    /**
     * @dev Receive (batch) crosschain request v2.
     *
     * @param params array with ReceiveParams structs.
     */
    function receiveV2(ReceiveParams[] calldata params) external override returns (bool) { // TODO only pusher?
        require(state == State.Active, "Bridge: state inactive");

        for (uint256 i = 0; i < params.length; ++i) {
            bytes32 epochHash = Block.epochHash(params[i].blockHeader);

            // verify the block signature
            if (epochHash == currentEpoch.epochHash) {
                require(currentEpoch.isSet(), "Bridge: epoch not set");
                verifyEpoch(currentEpoch, params[i]);
            } else if (epochHash == previousEpoch.epochHash) {
                require(previousEpoch.isSet(), "Bridge: epoch not set");
                verifyEpoch(previousEpoch, params[i]);
            } else {
                revert("Bridge: wrong epoch");
            }

            // verify that the transaction is really in the block
            bytes memory payload = Merkle.prove(params[i].merkleProof, Block.txRootHash(params[i].blockHeader));

            uint256 chainIdFrom;
            bytes32 from;
            // get call data // TODO get chainIdFrom and from
            (bytes32 requestId, bytes32 bridgeFrom, address to, bytes memory receivedData) = Block.decodeRequest(payload);

            bool isRequestIdUniq;
            if (epochHash == currentEpoch.epochHash) {
                isRequestIdUniq = currentRequestIdChecker.check(requestId);
            } else {
                isRequestIdUniq = previousRequestIdChecker.check(requestId);
            }

            string memory err;
            
            if (isRequestIdUniq) {
                (bool success, bytes memory data) = to.call(receivedData);
                if (!success) {
                    // TODO should revert
                    err = Utils.extractErrorMessage(data);
                }
            } else {
                revert("Bridge: request id already seen");
            }

            emit RequestReceived(requestId, to, from, chainIdFrom, err);
        }

        return true;
    }

    /**
     * @dev Set new state.
     *
     * @param state_ Active\Inactive state
     */
    function setState(State state_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        state = state_;
    }

    /**
     * @dev Verifies epoch.
     *
     * @param epoch current or previous epoch;
     * @param params oracle tx params
     */
    function verifyEpoch(Bls.Epoch storage epoch, ReceiveParams calldata params) internal view {
        Block.verify(
            epoch,
            params.blockHeader,
            params.votersPubKey,
            params.votersSignature,
            params.votersMask
        );
    }

    /**
     * @dev Verifies and updates the sender's nonce.
     *
     * @param from sender's address
     * @param nonce provided nonce
     */
    function verifyAndUpdateNonce(address from, uint256 nonce) internal {
        require(nonces[from]++ == nonce, "Bridge: nonce mismatch");
    }

    /**
     * @dev Moves current epoch and current request filter to previous.
     */
    function rotateEpoch() internal {
        previousEpoch = currentEpoch;
        Bls.Epoch memory epoch;
        currentEpoch = epoch;
        previousRequestIdChecker.destroy();
        previousRequestIdChecker = currentRequestIdChecker;
        currentRequestIdChecker = new RequestIdChecker();
    }

    /**
     * @dev Hook on start new epoch.
     */
    function onEpochStart(uint64 protocolVersion_) internal virtual {
        emit EpochUpdated(abi.encode(currentEpoch.publicKey), currentEpoch.epochNum, protocolVersion_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBridgeV2 {

    enum State { Active, Inactive }

    struct SendParams {
        /// @param requestId unique request ID
        bytes32 requestId;
        /// @param data call data
        bytes data;
        /// @param to receiver contract address
        address to;
        /// @param chainIdTo destination chain ID
        uint256 chainIdTo;
    }

    struct ReceiveParams {
        /// @param blockHeader block header serialization
        bytes blockHeader;
        /// @param merkleProof OracleRequest transaction payload and its Merkle audit path
        bytes merkleProof;
        /// @param votersPubKey aggregated public key of the old epoch participants, who voted for the block
        bytes votersPubKey;
        /// @param votersSignature aggregated signature of the old epoch participants, who voted for the block
        bytes votersSignature;
        /// @param votersMask bitmask of epoch participants, who voted, among all participants
        uint256 votersMask;
    }

    function sendV2(
        SendParams calldata params,
        address sender,
        uint256 nonce
    ) external returns (bool);

    function receiveV2(ReceiveParams[] calldata params) external returns (bool);

    function nonces(address from) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/Bls.sol";
import "../utils/Utils.sol";
import "../utils/ZeroCopySource.sol";

library Block {

    function txRootHash(bytes calldata payload) internal pure returns (bytes32 txRootHash_) {
        txRootHash_ = Utils.bytesToBytes32(payload[72:104]);
    }

    function epochHash(bytes calldata payload) internal pure returns (bytes32 epochHash_) {
        epochHash_ = Utils.bytesToBytes32(payload[40:72]);
    }

    function decodeRequest(bytes memory payload) internal pure returns (
        bytes32 requestId,
        bytes32 bridgeFrom, // TODO remove
        address to,
        bytes memory data
    ) {
        uint256 off = 0;
        (requestId, off) = ZeroCopySource.NextHash(payload, off);
        (bridgeFrom, off) = ZeroCopySource.NextHash(payload, off);
        (to, off) = ZeroCopySource.NextAddress(payload, off);
        (data, off) = ZeroCopySource.NextVarBytes(payload, off);
    }

    function decodeEpochUpdate(bytes memory payload) internal pure returns (
        uint64 newEpochVersion,
        uint32 newEpochNum,
        bytes memory newKey,
        uint8 newEpochParticipantsCount
    ) {
        uint256 off = 0;
        (newEpochVersion, off) = ZeroCopySource.NextUint64(payload, off);
        (newEpochNum, off) = ZeroCopySource.NextUint32(payload, off);
        (newEpochParticipantsCount, off) = ZeroCopySource.NextUint8(payload, off);
        (newKey, off) = ZeroCopySource.NextVarBytes(payload, off);
    }

    function verify(
        Bls.Epoch memory epoch,
        bytes calldata blockHeader,
        bytes calldata votersPubKey,
        bytes calldata votersSignature,
        uint256 votersMask
    ) internal view {
        require(popcnt(votersMask) > (uint256(epoch.participantsCount) * 2) / 3, "Block: not enough participants");
        require(epoch.participantsCount == 255 || votersMask < (1 << epoch.participantsCount), "Block: bitmask too big");
        require(
            Bls.verifyMultisig(epoch, votersPubKey, blockHeader, votersSignature, votersMask),
            "Block: multisig mismatch"
        );
    }

    function popcnt(uint256 mask) internal pure returns (uint256 cnt) {
        cnt = 0;
        while (mask != 0) {
            mask = mask & (mask - 1);
            cnt++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ModUtils.sol";

/**
 * @title Verify BLS Threshold Signed values.
 *
 * Much of the code in this file is derived from here:
 * https://github.com/ConsenSys/gpact/blob/main/common/common/src/main/solidity/BlsSignatureVerification.sol
 * https://github.com/ConsenSys/gpact/blob/main/contracts/contracts/src/common/BlsSignatureVerification.sol
 */
library Bls {
    using ModUtils for uint256;

    struct E1Point {
        uint256 x;
        uint256 y;
    }

    /**
     * @dev Note that the ordering of the elements in each array needs to be the reverse of what you would
     * normally have, to match the ordering expected by the precompile.
     */
    struct E2Point {
        uint256[2] x;
        uint256[2] y;
    }

    /**
     * @dev P is a prime over which we form a basic field;
     * taken from go-ethereum/crypto/bn256/cloudflare/constants.go.
     */
    uint256 constant P = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct Epoch {
        /// @param sum of all participant public keys
        E2Point publicKey;
        /// @param // sum of H(Pub, i) hashes of all participants indexes
        E1Point precomputedSum;
        /// @param // participants count contributed to the epochKey
        uint8 participantsCount;
        /// @param epoch number
        uint32 epochNum;
        /// @param epoch hash
        bytes32 epochHash;
    }

    /**
     * @dev Tests that epoch is set or zero.
     */
    function isSet(Epoch memory epoch) internal pure returns (bool) {
        return epoch.publicKey.x[0] != 0 || epoch.publicKey.x[1] != 0;
    }

    /**
     * @dev Reset the epoch.
     */
    function reset(Epoch storage epoch) internal {
        epoch.publicKey.x[0] = 0;
        epoch.publicKey.x[1] = 0;
        epoch.precomputedSum.x = 0;
        epoch.epochHash = 0;
        epoch.participantsCount = 0;
    }

    /**
     * @dev Update epoch and precompute epoch sum as if all participants signed.
     *
     * @param epoch_ current epoch to update;
     * @param epochPublicKey sum of all participant public keys;
     * @param epochParticipantsCount number of participants;
     * @param epochNum number of participants;
     * @param epochHash epoch hash.
     */
    function update(
        Epoch storage epoch_,
        bytes memory epochPublicKey,
        uint8 epochParticipantsCount,
        uint32 epochNum,
        bytes32 epochHash
    ) internal {
        E2Point memory pub = decodeE2Point(epochPublicKey);
        E1Point memory sum = E1Point(0, 0);
        uint256 index = 0;
        bytes memory buf = abi.encodePacked(pub.x, pub.y, index);
        while (index < epochParticipantsCount) {
            assembly {
                mstore(add(buf, 160), index)
            } // overwrite index field, same as buf[128] = index
            sum = addCurveE1(sum, hashToCurveE1(buf));
            index++;
        }
        epoch_.publicKey = pub;
        epoch_.precomputedSum = sum;
        epoch_.participantsCount = epochParticipantsCount;
        epoch_.epochNum = epochNum;
        epoch_.epochHash = epochHash;
    }

    /**
     * @dev Checks if the BLS multisignature is valid in the current epoch.
     *
     * @param epoch_ current epoch;
     * @param partPublicKey Sum of participated public keys;
     * @param message Message that was signed;
     * @param partSignature Signature over the message;
     * @param signersBitmask Bitmask of participants in this signature;
     * @return True if the message was correctly signed by the given participants.
     */
    function verifyMultisig(
        Epoch memory epoch_,
        bytes memory partPublicKey,
        bytes memory message,
        bytes memory partSignature,
        uint256 signersBitmask
    ) internal view returns (bool) {
        E1Point memory sum = epoch_.precomputedSum;
        uint256 index = 0;
        uint256 mask = 1;
        bytes memory buf = abi.encodePacked(epoch_.publicKey.x, epoch_.publicKey.y, index);
        while (index < epoch_.participantsCount) {
            if (signersBitmask & mask == 0) {
                assembly {
                    mstore(add(buf, 160), index)
                } // overwrite index field, same as buf[128] = index
                sum = addCurveE1(sum, negate(hashToCurveE1(buf)));
            }
            mask <<= 1;
            index++;
        }

        E1Point[] memory e1points = new E1Point[](3);
        E2Point[] memory e2points = new E2Point[](3);
        e1points[0] = negate(decodeE1Point(partSignature));
        e1points[1] = hashToCurveE1(abi.encodePacked(epoch_.publicKey.x, epoch_.publicKey.y, message));
        e1points[2] = sum;
        e2points[0] = G2();
        e2points[1] = decodeE2Point(partPublicKey);
        e2points[2] = epoch_.publicKey;
        return pairing(e1points, e2points);
    }

    /**
     * @return The generator of E1.
     */
    function G1() private pure returns (E1Point memory) {
        return E1Point(1, 2);
    }

    /**
     * @return The generator of E2.
     */
    function G2() private pure returns (E2Point memory) {
        return E2Point({
            x: [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            y: [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        });
    }

    /**
     * Negate a point: Assuming the point isn't at infinity, the negation is same x value with -y.
     *
     * @dev Negates a point in E1;
     * @param _point Point to negate;
     * @return The negated point.
     */
    function negate(E1Point memory _point) private pure returns (E1Point memory) {
        if (isAtInfinity(_point)) {
            return E1Point(0, 0);
        }
        return E1Point(_point.x, P - (_point.y % P));
    }

    /**
     * Computes the pairing check e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *
     * @param _e1points List of points in E1;
     * @param _e2points List of points in E2;
     * @return True if pairing check succeeds.
     */
    function pairing(E1Point[] memory _e1points, E2Point[] memory _e2points) private view returns (bool) {
        require(_e1points.length == _e2points.length, "Bls: point count mismatch");

        uint256 elements = _e1points.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = _e1points[i].x;
            input[i * 6 + 1] = _e1points[i].y;
            input[i * 6 + 2] = _e2points[i].x[0];
            input[i * 6 + 3] = _e2points[i].x[1];
            input[i * 6 + 4] = _e2points[i].y[0];
            input[i * 6 + 5] = _e2points[i].y[1];
        }

        uint256[1] memory out;
        bool success;
        assembly {
            // Start at memory offset 0x20 rather than 0 as input is a variable length array.
            // Location 0 is the length field.
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        // The pairing operation will fail if the input data isn't the correct size (this won't happen
        // given the code above), or if one of the points isn't on the curve.
        require(success, "Bls: pairing operation failed");
        return out[0] != 0;
    }

    /**
     * @dev Checks if the point is the point at infinity.
     *
     * @param _point a point on E1;
     * @return true if the point is the point at infinity.
     */
    function isAtInfinity(E1Point memory _point) private pure returns (bool) {
        return (_point.x == 0 && _point.y == 0);
    }

    /**
     * @dev Hash a byte array message, m, and map it deterministically to a point on G1.
     * Note that this approach was chosen for its simplicity /
     * lower gas cost on the EVM, rather than good distribution of points on G1.
     */
    function hashToCurveE1(bytes memory m) internal view returns (E1Point memory) {
        bytes32 h = sha256(m);
        uint256 x = uint256(h) % P;
        uint256 y;

        while (true) {
            y = YFromX(x);
            if (y > 0) {
                return E1Point(x, y);
            }
            x += 1;
        }
        revert("hashToCurveE1: unreachable end point");
    }

    /**
     * @dev g1YFromX computes a Y value for a G1 point based on an X value.
     * This computation is simply evaluating the curve equation for Y on a given X,
     * and allows a point on the curve to be represented by just an X value + a sign bit.
     */
    function YFromX(uint256 x) internal view returns (uint256) {
        return ((x.modExp(3, P) + 3) % P).modSqrt(P);
    }

    /**
     * @dev return the sum of two points of G1.
     */
    function addCurveE1(E1Point memory _p1, E1Point memory _p2) internal view returns (E1Point memory res) {
        uint256[4] memory input;
        input[0] = _p1.x;
        input[1] = _p1.y;
        input[2] = _p2.x;
        input[3] = _p2.y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, res, 0x40)
        }
        require(success, "Bls: add points failed");
    }

    function decodeE1Point(bytes memory _sig) internal pure returns (E1Point memory signature) {
        uint256 sigx;
        uint256 sigy;
        assembly {
            sigx := mload(add(_sig, 0x20))
            sigy := mload(add(_sig, 0x40))
        }
        signature.x = sigx;
        signature.y = sigy;
    }

    function decodeE2Point(bytes memory _pubKey) internal pure returns (E2Point memory pubKey) {
        uint256 x1;
        uint256 x2;
        uint256 y1;
        uint256 y2;
        assembly {
            x1 := mload(add(_pubKey, 0x20))
            x2 := mload(add(_pubKey, 0x40))
            y1 := mload(add(_pubKey, 0x60))
            y2 := mload(add(_pubKey, 0x80))
        }
        pubKey.x[0] = x1;
        pubKey.x[1] = x2;
        pubKey.y[0] = y1;
        pubKey.y[1] = y2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ZeroCopySource.sol";

library Merkle {
    /* @notice          Do hash leaf as the multi-chain does
     *  @param _data     Data in bytes format
     *  @return          Hashed value in bytes32 format
     */
    function hashLeaf(bytes memory _data) internal pure returns (bytes32 result) {
        result = sha256(abi.encodePacked(uint8(0x0), _data));
    }

    /* @notice          Do hash children as the multi-chain does
     *  @param _l        Left node
     *  @param _r        Right node
     *  @return          Hashed value in bytes32 format
     */
    function hashChildren(bytes32 _l, bytes32 _r) internal pure returns (bytes32 result) {
        result = sha256(abi.encodePacked(bytes1(0x01), _l, _r));
    }

    /* @notice                  Verify merkle proove
     *  @param _auditPath        Merkle path
     *  @param _root             Merkle tree root
     *  @return                  The verified value included in _auditPath
     */
    function prove(bytes memory _auditPath, bytes32 _root) internal pure returns (bytes memory) {
        uint256 off = 0;
        bytes memory value;
        (value, off) = ZeroCopySource.NextVarBytes(_auditPath, off);

        bytes32 hash = hashLeaf(value);
        uint256 size = (_auditPath.length - off) / 33;
        bytes32 nodeHash;
        uint8 pos;
        for (uint256 i = 0; i < size; i++) {
            (pos, off) = ZeroCopySource.NextUint8(_auditPath, off);
            (nodeHash, off) = ZeroCopySource.NextHash(_auditPath, off);
            if (pos == 0x00) {
                hash = hashChildren(nodeHash, hash);
            } else if (pos == 0x01) {
                hash = hashChildren(hash, nodeHash);
            } else {
                revert("merkleProve eod");
            }
        }
        require(hash == _root, "merkleProve root");
        return value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library ModUtils {
    /**
     * @dev Wrap the modular exponent pre-compile introduced in Byzantium.
     * Returns base^exponent mod p.
     */
    function modExp(
        uint256 base,
        uint256 exponent,
        uint256 p
    ) internal view returns (uint256 o) {
        /* solium-disable-next-line */
        assembly {
            // Args for the precompile: [<length_of_BASE> <length_of_EXPONENT>
            // <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>]
            let output := mload(0x40)
            let args := add(output, 0x20)
            mstore(args, 0x20)
            mstore(add(args, 0x20), 0x20)
            mstore(add(args, 0x40), 0x20)
            mstore(add(args, 0x60), base)
            mstore(add(args, 0x80), exponent)
            mstore(add(args, 0xa0), p)

            // 0x05 is the modular exponent contract address
            if iszero(staticcall(not(0), 0x05, args, 0xc0, output, 0x20)) {
                revert(0, 0)
            }
            o := mload(output)
        }
    }

    /**
     * @dev Calculates and returns the square root of a mod p if such a square
     * root exists. The modulus p must be an odd prime. If a square root does
     * not exist, function returns 0.
     */
    function modSqrt(uint256 a, uint256 p) internal view returns (uint256) {
        if (legendre(a, p) != 1) {
            return 0;
        }

        if (a == 0) {
            return 0;
        }

        if (p % 4 == 3) {
            return modExp(a, (p + 1) / 4, p);
        }

        uint256 s = p - 1;
        uint256 e = 0;

        while (s % 2 == 0) {
            s = s / 2;
            e = e + 1;
        }

        // Note the smaller int- finding n with Legendre symbol or -1
        // should be quick
        uint256 n = 2;
        while (legendre(n, p) != -1) {
            n = n + 1;
        }

        uint256 x = modExp(a, (s + 1) / 2, p);
        uint256 b = modExp(a, s, p);
        uint256 g = modExp(n, s, p);
        uint256 r = e;
        uint256 gs = 0;
        uint256 m = 0;
        uint256 t = b;

        while (true) {
            t = b;
            m = 0;

            for (m = 0; m < r; m++) {
                if (t == 1) {
                    break;
                }
                t = modExp(t, 2, p);
            }

            if (m == 0) {
                return x;
            }

            gs = modExp(g, uint256(2)**(r - m - 1), p);
            g = (gs * gs) % p;
            x = (x * gs) % p;
            b = (b * g) % p;
            r = m;
        }
        revert("modSqrt: unreachable end point");
    }

    /**
     * @dev Calculates the Legendre symbol of the given a mod p.
     * @return Returns 1 if a is a quadratic residue mod p, -1 if it is
     * a non-quadratic residue, and 0 if a is 0.
     */
    function legendre(uint256 a, uint256 p) internal view returns (int256) {
        uint256 raised = modExp(a, (p - 1) / uint256(2), p);

        if (raised == 0 || raised == 1) {
            return int256(raised);
        } else if (raised == p - 1) {
            return -1;
        }

        revert("Failed to calculate legendre.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract RequestIdChecker {
    
    ///
    mapping(bytes32 => bool) public checks;
    /// 
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "RequestIdChecker: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function check(bytes32 id) public onlyOwner returns (bool) {
        if (checks[id] == false) {
            checks[id] = true;
            return true;
        }
        return false;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Typecast {
    function castToAddress(bytes32 x) public pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function castToBytes32(address a) public pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Utils {
    /* @notice      Convert the bytes array to bytes32 type, the bytes array length must be 32
     *  @param _bs   Source bytes array
     *  @return      bytes32
     */
    function bytesToBytes32(bytes memory _bs) internal pure returns (bytes32 value) {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            // load 32 bytes from memory starting from position _bs + 0x20 since the first 0x20 bytes stores _bs length
            value := mload(add(_bs, 0x20))
        }
    }

    /* @notice      Convert bytes to uint256
     *  @param _b    Source bytes should have length of 32
     *  @return      uint256
     */
    function bytesToUint256(bytes memory _bs) internal pure returns (uint256 value) {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            // load 32 bytes from memory starting from position _bs + 32
            value := mload(add(_bs, 0x20))
        }
        require(value <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Value exceeds the range");
    }

    /* @notice      Convert uint256 to bytes
     *  @param _b    uint256 that needs to be converted
     *  @return      bytes
     */
    function uint256ToBytes(uint256 _value) internal pure returns (bytes memory bs) {
        require(
            _value <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            "Value exceeds the range"
        );
        assembly {
            // Get a location of some free memory and store it in result as
            // Solidity does for memory variables.
            bs := mload(0x40)
            // Put 0x20 at the first word, the length of bytes for uint256 value
            mstore(bs, 0x20)
            //In the next word, put value in bytes format to the next 32 bytes
            mstore(add(bs, 0x20), _value)
            // Update the free-memory pointer by padding our last write location to 32 bytes
            mstore(0x40, add(bs, 0x40))
        }
    }

    /* @notice      Convert bytes to address
     *  @param _bs   Source bytes: bytes length must be 20
     *  @return      Converted address from source bytes
     */
    function bytesToAddress(bytes memory _bs) internal pure returns (address addr) {
        require(_bs.length == 20, "bytes length does not match address");
        assembly {
            // for _bs, first word store _bs.length, second word store _bs.value
            // load 32 bytes from mem[_bs+20], convert it into Uint160, meaning we take last 20 bytes as addr (address).
            addr := mload(add(_bs, 0x14))
        }
    }

    /* @notice      Convert address to bytes
     *  @param _addr Address need to be converted
     *  @return      Converted bytes from address
     */
    function addressToBytes(address _addr) internal pure returns (bytes memory bs) {
        assembly {
            // Get a location of some free memory and store it in result as
            // Solidity does for memory variables.
            bs := mload(0x40)
            // Put 20 (address byte length) at the first word, the length of bytes for uint256 value
            mstore(bs, 0x14)
            // logical shift left _a by 12 bytes, change _a from right-aligned to left-aligned
            mstore(add(bs, 0x20), shl(96, _addr))
            // Update the free-memory pointer by padding our last write location to 32 bytes
            mstore(0x40, add(bs, 0x40))
        }
    }

    /* @notice              Compare if two bytes are equal, which are in storage and memory, seperately
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L368
    *  @param _preBytes     The bytes stored in storage
    *  @param _postBytes    The bytes stored in memory
    *  @return              Bool type indicating if they are equal
    */
    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // fslot can contain both the length and contents of the array
                // if slength < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                // slength != 0
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /* @notice              Slice the _bytes from _start index till the result has length of _length
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L246
    *  @param _bytes        The original bytes needs to be sliced
    *  @param _start        The index of _bytes for the start of sliced bytes
    *  @param _length       The index of _bytes for the end of sliced bytes
    *  @return              The sliced bytes
    */
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                // lengthmod <= _length % 32
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /* @notice              Check if the elements number of _signers within _keepers array is no less than _m
     *  @param _keepers      The array consists of serveral address
     *  @param _signers      Some specific addresses to be looked into
     *  @param _m            The number requirement paramter
     *  @return              True means containment, false meansdo do not contain.
     */
    function containMAddresses(
        address[] memory _keepers,
        address[] memory _signers,
        uint256 _m
    ) internal pure returns (bool) {
        uint256 m = 0;
        for (uint256 i = 0; i < _signers.length; i++) {
            for (uint256 j = 0; j < _keepers.length; j++) {
                if (_signers[i] == _keepers[j]) {
                    m++;
                    delete _keepers[j];
                }
            }
        }
        return m >= _m;
    }

    /* @notice              TODO
     *  @param key
     *  @return
     */
    function compressMCPubKey(bytes memory key) internal pure returns (bytes memory newkey) {
        require(key.length >= 67, "key lenggh is too short");
        newkey = slice(key, 0, 35);
        if (uint8(key[66]) % 2 == 0) {
            newkey[2] = 0x02;
        } else {
            newkey[2] = 0x03;
        }
        return newkey;
    }

    /**
     * @dev Returns true if `account` is a contract.
     *      Refer from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L18
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Extracts error from the returned data of inter-contract call
     */
    function extractErrorMessage(bytes memory data) internal pure returns (string memory) {
        if (data.length < 68) return "unknown error";
        bytes memory revertData = BytesLib.slice(data, 4, data.length - 4);
        return abi.decode(revertData, (string));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Wrappers over decoding and deserialization operation from bytes into bassic types in Solidity for PolyNetwork cross chain utility.
 *
 * Decode into basic types in Solidity from bytes easily. It's designed to be used
 * for PolyNetwork cross chain application, and the decoding rules on Ethereum chain
 * and the encoding rule on other chains should be consistent, and . Here we
 * follow the underlying deserialization rule with implementation found here:
 * https://github.com/polynetwork/poly/blob/master/common/zero_copy_source.go
 *
 * Using this library instead of the unchecked serialization method can help reduce
 * the risk of serious bugs and handfule, so it's recommended to use it.
 *
 * Please note that risk can be minimized, yet not eliminated.
 */
library ZeroCopySource {
    /* @notice              Read next byte as boolean type starting at offset from buff
     *  @param buff          Source bytes array
     *  @param offset        The position from where we read the boolean value
     *  @return              The the read boolean value and new offset
     */
    function NextBool(bytes memory buff, uint256 offset) internal pure returns (bool, uint256) {
        require(offset + 1 <= buff.length && offset < offset + 1, "Offset exceeds limit");
        // byte === bytes1
        uint8 v;
        assembly {
            v := mload(add(add(buff, 0x20), offset))
        }
        bool value;
        if (v == 0x01) {
            value = true;
        } else if (v == 0x00) {
            value = false;
        } else {
            revert("NextBool value error");
        }
        return (value, offset + 1);
    }

    /* @notice              Read next byte as uint8 starting at offset from buff
     *  @param buff          Source bytes array
     *  @param offset        The position from where we read the byte value
     *  @return              The read uint8 value and new offset
     */
    function NextUint8(bytes memory buff, uint256 offset) internal pure returns (uint8, uint256) {
        require(offset + 1 <= buff.length && offset < offset + 1, "NextUint8, Offset exceeds maximum");
        uint8 v;
        assembly {
            let tmpbytes := mload(0x40)
            let bvalue := mload(add(add(buff, 0x20), offset))
            mstore8(tmpbytes, byte(0, bvalue))
            mstore(0x40, add(tmpbytes, 0x01))
            v := mload(sub(tmpbytes, 0x1f))
        }
        return (v, offset + 1);
    }

    /* @notice              Read next two bytes as uint16 type starting from offset
     *  @param buff          Source bytes array
     *  @param offset        The position from where we read the uint16 value
     *  @return              The read uint16 value and updated offset
     */
    function NextUint16(bytes memory buff, uint256 offset) internal pure returns (uint16, uint256) {
        require(offset + 2 <= buff.length && offset < offset + 2, "NextUint16, offset exceeds maximum");

        uint16 v;
        assembly {
            let tmpbytes := mload(0x40)
            let bvalue := mload(add(add(buff, 0x20), offset))
            mstore8(tmpbytes, byte(0x01, bvalue))
            mstore8(add(tmpbytes, 0x01), byte(0, bvalue))
            mstore(0x40, add(tmpbytes, 0x02))
            v := mload(sub(tmpbytes, 0x1e))
        }
        return (v, offset + 2);
    }

    /* @notice              Read next four bytes as uint32 type starting from offset
     *  @param buff          Source bytes array
     *  @param offset        The position from where we read the uint32 value
     *  @return              The read uint32 value and updated offset
     */
    function NextUint32(bytes memory buff, uint256 offset) internal pure returns (uint32, uint256) {
        require(offset + 4 <= buff.length && offset < offset + 4, "NextUint32, offset exceeds maximum");
        uint32 v;
        assembly {
            let tmpbytes := mload(0x40)
            let byteLen := 0x04
            for {
                let tindex := 0x00
                let bindex := sub(byteLen, 0x01)
                let bvalue := mload(add(add(buff, 0x20), offset))
            } lt(tindex, byteLen) {
                tindex := add(tindex, 0x01)
                bindex := sub(bindex, 0x01)
            } {
                mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
            }
            mstore(0x40, add(tmpbytes, byteLen))
            v := mload(sub(tmpbytes, sub(0x20, byteLen)))
        }
        return (v, offset + 4);
    }

    /* @notice              Read next eight bytes as uint64 type starting from offset
     *  @param buff          Source bytes array
     *  @param offset        The position from where we read the uint64 value
     *  @return              The read uint64 value and updated offset
     */
    function NextUint64(bytes memory buff, uint256 offset) internal pure returns (uint64, uint256) {
        require(offset + 8 <= buff.length && offset < offset + 8, "NextUint64, offset exceeds maximum");
        uint64 v;
        assembly {
            let tmpbytes := mload(0x40)
            let byteLen := 0x08
            for {
                let tindex := 0x00
                let bindex := sub(byteLen, 0x01)
                let bvalue := mload(add(add(buff, 0x20), offset))
            } lt(tindex, byteLen) {
                tindex := add(tindex, 0x01)
                bindex := sub(bindex, 0x01)
            } {
                mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
            }
            mstore(0x40, add(tmpbytes, byteLen))
            v := mload(sub(tmpbytes, sub(0x20, byteLen)))
        }
        return (v, offset + 8);
    }

    /* @notice              Read next 32 bytes as uint256 type starting from offset,
                            there are limits considering the numerical limits in multi-chain
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the uint256 value
    *  @return              The read uint256 value and updated offset
    */
    function NextUint255(bytes memory buff, uint256 offset) internal pure returns (uint256, uint256) {
        require(offset + 32 <= buff.length && offset < offset + 32, "NextUint255, offset exceeds maximum");
        uint256 v;
        assembly {
            let tmpbytes := mload(0x40)
            let byteLen := 0x20
            for {
                let tindex := 0x00
                let bindex := sub(byteLen, 0x01)
                let bvalue := mload(add(add(buff, 0x20), offset))
            } lt(tindex, byteLen) {
                tindex := add(tindex, 0x01)
                bindex := sub(bindex, 0x01)
            } {
                mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
            }
            mstore(0x40, add(tmpbytes, byteLen))
            v := mload(tmpbytes)
        }
        require(v <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Value exceeds the range");
        return (v, offset + 32);
    }

    /* @notice              Read next variable bytes starting from offset,
                            the decoding rule coming from multi-chain
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the bytes value
    *  @return              The read variable bytes array value and updated offset
    */
    function NextVarBytes(bytes memory buff, uint256 offset) internal pure returns (bytes memory, uint256) {
        uint256 len;
        (len, offset) = NextVarUint(buff, offset);
        require(offset + len <= buff.length && offset < offset + len, "NextVarBytes, offset exceeds maximum");
        bytes memory tempBytes;
        assembly {
            switch iszero(len)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(len, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, len)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(buff, lengthmod), mul(0x20, iszero(lengthmod))), offset)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, len)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return (tempBytes, offset + len);
    }

    /* @notice              Read next 32 bytes starting from offset,
     *  @param buff          Source bytes array
     *  @param offset        The position from where we read the bytes value
     *  @return              The read bytes32 value and updated offset
     */
    function NextHash(bytes memory buff, uint256 offset) internal pure returns (bytes32, uint256) {
        require(offset + 32 <= buff.length && offset < offset + 32, "NextHash, offset exceeds maximum");
        bytes32 v;
        assembly {
            v := mload(add(buff, add(offset, 0x20)))
        }
        return (v, offset + 32);
    }

    /* @notice              Read next 20 bytes starting from offset,
     *  @param buff          Source bytes array
     *  @param offset        The position from where we read the bytes value
     *  @return              The read bytes20 value and updated offset
     */
    function NextAddress(bytes memory buff, uint256 offset) internal pure returns (address, uint256) {
        require(offset + 20 <= buff.length && offset < offset + 20, "NextAddress, offset exceeds maximum");
        bytes20 v;
        assembly {
            v := mload(add(buff, add(offset, 0x20)))
        }
        return (address(v), offset + 20);
    }

    function NextVarUint(bytes memory buff, uint256 offset) internal pure returns (uint256, uint256) {
        uint8 v;
        (v, offset) = NextUint8(buff, offset);

        uint256 value;
        if (v == 0xFD) {
            // return NextUint16(buff, offset);
            (value, offset) = NextUint16(buff, offset);
            require(value >= 0xFD && value <= 0xFFFF, "NextUint16, value outside range");
            return (value, offset);
        } else if (v == 0xFE) {
            // return NextUint32(buff, offset);
            (value, offset) = NextUint32(buff, offset);
            require(value > 0xFFFF && value <= 0xFFFFFFFF, "NextVarUint, value outside range");
            return (value, offset);
        } else if (v == 0xFF) {
            // return NextUint64(buff, offset);
            (value, offset) = NextUint64(buff, offset);
            require(value > 0xFFFFFFFF, "NextVarUint, value outside range");
            return (value, offset);
        } else {
            // return (uint8(v), offset);
            value = uint8(v);
            require(value < 0xFD, "NextVarUint, value outside range");
            return (value, offset);
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}