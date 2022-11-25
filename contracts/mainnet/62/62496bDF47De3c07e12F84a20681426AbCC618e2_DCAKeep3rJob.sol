// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '../interfaces/IDCAKeep3rJob.sol';

contract DCAKeep3rJob is AccessControl, EIP712, IDCAKeep3rJob {
  using Address for address;

  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant CAN_SIGN_ROLE = keccak256('CAN_SIGN_ROLE');
  bytes32 public constant WORK_TYPEHASH = keccak256('Work(address swapper,bytes data,uint256 nonce)');

  /// @inheritdoc IDCAKeep3rJob
  IKeep3r public immutable keep3r;
  /// @inheritdoc IDCAKeep3rJob
  SwapperAndNonce public swapperAndNonce; // Note: data grouped in struct to reduce SLOADs

  constructor(
    IKeep3r _keep3r,
    address _swapper,
    address _superAdmin,
    address[] memory _initialCanSign
  ) EIP712('Mean Finance - DCA Keep3r Job', '1') {
    if (address(_keep3r) == address(0)) revert ZeroAddress();
    if (_swapper == address(0)) revert ZeroAddress();
    if (_superAdmin == address(0)) revert ZeroAddress();

    keep3r = _keep3r;
    swapperAndNonce.swapper = _swapper;

    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(CAN_SIGN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);

    for (uint256 i = 0; i < _initialCanSign.length; ) {
      _setupRole(CAN_SIGN_ROLE, _initialCanSign[i]);
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAKeep3rJob
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }

  /// @inheritdoc IDCAKeep3rJob
  function setSwapper(address _swapper) external onlyRole(SUPER_ADMIN_ROLE) {
    if (address(_swapper) == address(0)) revert ZeroAddress();
    swapperAndNonce.swapper = _swapper;
    emit NewSwapperSet(_swapper);
  }

  /// @inheritdoc IDCAKeep3rJob
  function work(
    bytes calldata _call,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    if (!keep3r.isKeeper(msg.sender)) revert NotAKeeper();

    SwapperAndNonce memory _swapperAndNonce = swapperAndNonce;
    bytes32 _structHash = keccak256(abi.encode(WORK_TYPEHASH, _swapperAndNonce.swapper, keccak256(_call), _swapperAndNonce.nonce));
    bytes32 _hash = _hashTypedDataV4(_structHash);
    address _signer = ECDSA.recover(_hash, _v, _r, _s);
    if (!hasRole(CAN_SIGN_ROLE, _signer)) revert SignerCannotSignWork();

    swapperAndNonce.nonce = _swapperAndNonce.nonce + 1;
    _swapperAndNonce.swapper.functionCall(_call);

    keep3r.worked(msg.sender);
  }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import 'keep3r-v2/solidity/interfaces/IKeep3r.sol';

interface IDCAKeep3rJob {
  /// @notice A struct that contains the swapper and nonce to use
  struct SwapperAndNonce {
    address swapper;
    uint96 nonce;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when a user tries to execute work but the signature is invalid
  error SignerCannotSignWork();

  /// @notice Thrown when a non keep3r address tries to execute work
  error NotAKeeper();

  /**
   * @notice Emitted when a new swapper is set
   * @param newSwapper The new swapper
   */
  event NewSwapperSet(address newSwapper);

  /**
   * @notice The domain separator used for the work signature
   * @return The domain separator used for the work signature
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the swapper address
   * @return swapper The swapper's address
   * @return nonce The next nonce to use
   */
  function swapperAndNonce() external returns (address swapper, uint96 nonce);

  /**
   * @notice Returns the Keep3r address
   * @return The Keep3r address address
   */
  function keep3r() external returns (IKeep3r);

  /**
   * @notice Sets a new swapper address
   * @dev Will revert with ZeroAddress if the zero address is passed
   *      Can only be called by an admin
   * @param swapper The new swapper address
   */
  function setSwapper(address swapper) external;

  /**
   * @notice Takes an encoded call and executes it against the swapper
   * @dev Will revert with:
   *      - NotAKeeper if the caller is not a keep3r
   *      - SignerCannotSignWork if the address who signed the message cannot sign work
   * @param call The call to execut against the swapper
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function work(
    bytes calldata call,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
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
pragma solidity >=0.8.4 <0.9.0;

import './peripherals/IKeep3rJobs.sol';
import './peripherals/IKeep3rKeepers.sol';
import './peripherals/IKeep3rAccountance.sol';
import './peripherals/IKeep3rRoles.sol';
import './peripherals/IKeep3rParameters.sol';

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rV2 contract
/// @notice This contract inherits all the functionality of Keep3rV2
interface IKeep3r is IKeep3rJobs, IKeep3rKeepers, IKeep3rAccountance, IKeep3rRoles, IKeep3rParameters {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rDisputable contract
/// @notice Disputes keepers, or if they're already disputed, it can resolve the case
/// @dev Argument `bonding` can be the address of either a token or a liquidity
interface IKeep3rAccountance {
  // Events

  /// @notice Emitted when the bonding process of a new keeper begins
  /// @param _keeper The caller of Keep3rKeeperFundable#bond function
  /// @param _bonding The asset the keeper has bonded
  /// @param _amount The amount the keeper has bonded
  event Bonding(address indexed _keeper, address indexed _bonding, uint256 _amount);

  /// @notice Emitted when a keeper or job begins the unbonding process to withdraw the funds
  /// @param _keeperOrJob The keeper or job that began the unbonding process
  /// @param _unbonding The liquidity pair or asset being unbonded
  /// @param _amount The amount being unbonded
  event Unbonding(address indexed _keeperOrJob, address indexed _unbonding, uint256 _amount);

  // Variables

  /// @notice Tracks the total KP3R earnings of a keeper since it started working
  /// @return _workCompleted Total KP3R earnings of a keeper since it started working
  function workCompleted(address _keeper) external view returns (uint256 _workCompleted);

  /// @notice Tracks when a keeper was first registered
  /// @return timestamp The time at which the keeper was first registered
  function firstSeen(address _keeper) external view returns (uint256 timestamp);

  /// @notice Tracks if a keeper or job has a pending dispute
  /// @return _disputed Whether a keeper or job has a pending dispute
  function disputes(address _keeperOrJob) external view returns (bool _disputed);

  /// @notice Tracks how much a keeper has bonded of a certain token
  /// @return _bonds Amount of a certain token that a keeper has bonded
  function bonds(address _keeper, address _bond) external view returns (uint256 _bonds);

  /// @notice The current token credits available for a job
  /// @return _amount The amount of token credits available for a job
  function jobTokenCredits(address _job, address _token) external view returns (uint256 _amount);

  /// @notice Tracks the amount of assets deposited in pending bonds
  /// @return _pendingBonds Amount of a certain asset a keeper has unbonding
  function pendingBonds(address _keeper, address _bonding) external view returns (uint256 _pendingBonds);

  /// @notice Tracks when a bonding for a keeper can be activated
  /// @return _timestamp Time at which the bonding for a keeper can be activated
  function canActivateAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks when keeper bonds are ready to be withdrawn
  /// @return _timestamp Time at which the keeper bonds are ready to be withdrawn
  function canWithdrawAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks how much keeper bonds are to be withdrawn
  /// @return _pendingUnbonds The amount of keeper bonds that are to be withdrawn
  function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256 _pendingUnbonds);

  /// @notice Checks whether the address has ever bonded an asset
  /// @return _hasBonded Whether the address has ever bonded an asset
  function hasBonded(address _keeper) external view returns (bool _hasBonded);

  // Methods
  /// @notice Lists all jobs
  /// @return _jobList Array with all the jobs in _jobs
  function jobs() external view returns (address[] memory _jobList);

  /// @notice Lists all keepers
  /// @return _keeperList Array with all the jobs in keepers
  function keepers() external view returns (address[] memory _keeperList);

  // Errors

  /// @notice Throws when an address is passed as a job, but that address is not a job
  error JobUnavailable();

  /// @notice Throws when an action that requires an undisputed job is applied on a disputed job
  error JobDisputed();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rKeeperFundable contract
/// @notice Handles the actions required to become a keeper
interface IKeep3rKeeperFundable {
  // Events

  /// @notice Emitted when Keep3rKeeperFundable#activate is called
  /// @param _keeper The keeper that has been activated
  /// @param _bond The asset the keeper has bonded
  /// @param _amount The amount of the asset the keeper has bonded
  event Activation(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#withdraw is called
  /// @param _keeper The caller of Keep3rKeeperFundable#withdraw function
  /// @param _bond The asset to withdraw from the bonding pool
  /// @param _amount The amount of funds withdrawn
  event Withdrawal(address indexed _keeper, address indexed _bond, uint256 _amount);

  // Errors

  /// @notice Throws when the address that is trying to register as a job is already a job
  error AlreadyAJob();

  // Methods

  /// @notice Beginning of the bonding process
  /// @param _bonding The asset being bound
  /// @param _amount The amount of bonding asset being bound
  function bond(address _bonding, uint256 _amount) external;

  /// @notice Beginning of the unbonding process
  /// @param _bonding The asset being unbound
  /// @param _amount Allows for partial unbonding
  function unbond(address _bonding, uint256 _amount) external;

  /// @notice End of the bonding process after bonding time has passed
  /// @param _bonding The asset being activated as bond collateral
  function activate(address _bonding) external;

  /// @notice Withdraw funds after unbonding has finished
  /// @param _bonding The asset to withdraw from the bonding pool
  function withdraw(address _bonding) external;
}

/// @title Keep3rKeeperDisputable contract
/// @notice Handles the actions that can be taken on a disputed keeper
interface IKeep3rKeeperDisputable {
  // Events

  /// @notice Emitted when Keep3rKeeperDisputable#slash is called
  /// @param _keeper The slashed keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#slash
  /// @param _amount The amount of credits slashed from the keeper
  event KeeperSlash(address indexed _keeper, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#revoke is called
  /// @param _keeper The revoked keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#revoke
  event KeeperRevoke(address indexed _keeper, address indexed _slasher);

  /// @notice Keeper revoked

  // Methods

  /// @notice Allows governance to slash a keeper based on a dispute
  /// @param _keeper The address being slashed
  /// @param _bonded The asset being slashed
  /// @param _amount The amount being slashed
  function slash(
    address _keeper,
    address _bonded,
    uint256 _amount
  ) external;

  /// @notice Blacklists a keeper from participating in the network
  /// @param _keeper The address being slashed
  function revoke(address _keeper) external;
}

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rKeepers contract
interface IKeep3rKeepers is IKeep3rKeeperDisputable {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rJobFundableCredits contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobFundableCredits {
  // Events

  /// @notice Emitted when Keep3rJobFundableCredits#addTokenCreditsToJob is called
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being provided
  /// @param _provider The user that calls the function
  /// @param _amount The amount of credit being added to the job
  event TokenCreditAddition(address indexed _job, address indexed _token, address indexed _provider, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableCredits#withdrawTokenCreditsFromJob is called
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The credit being withdrawn from the job
  /// @param _receiver The user that receives the tokens
  /// @param _amount The amount of credit withdrawn
  event TokenCreditWithdrawal(address indexed _job, address indexed _token, address indexed _receiver, uint256 _amount);

  // Errors

  /// @notice Throws when the token is KP3R, as it should not be used for direct token payments
  error TokenUnallowed();

  /// @notice Throws when the token withdraw cooldown has not yet passed
  error JobTokenCreditsLocked();

  /// @notice Throws when the user tries to withdraw more tokens than it has
  error InsufficientJobTokenCredits();

  // Variables

  /// @notice Last block where tokens were added to the job [job => token => timestamp]
  /// @return _timestamp The last block where tokens were added to the job
  function jobTokenCreditsAddedAt(address _job, address _token) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Add credit to a job to be paid out for work
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being credited
  /// @param _amount The amount of credit being added
  function addTokenCreditsToJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Withdraw credit from a job
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The address of the token being withdrawn
  /// @param _amount The amount of token to be withdrawn
  /// @param _receiver The user that will receive tokens
  function withdrawTokenCreditsFromJob(
    address _job,
    address _token,
    uint256 _amount,
    address _receiver
  ) external;
}

/// @title  Keep3rJobFundableLiquidity contract
/// @notice Handles the funding of jobs through specific liquidity pairs
interface IKeep3rJobFundableLiquidity {
  // Events

  /// @notice Emitted when Keep3rJobFundableLiquidity#approveLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being approved
  event LiquidityApproval(address _liquidity);

  /// @notice Emitted when Keep3rJobFundableLiquidity#revokeLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being revoked
  event LiquidityRevocation(address _liquidity);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job to which liquidity will be added
  /// @param _liquidity The address of the liquidity being added
  /// @param _provider The user that calls the function
  /// @param _amount The amount of liquidity being added
  event LiquidityAddition(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _amount);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#withdrawLiquidityFromJob function is called
  /// @param _job The address of the job of which liquidity will be withdrawn from
  /// @param _liquidity The address of the liquidity being withdrawn
  /// @param _receiver The receiver of the liquidity tokens
  /// @param _amount The amount of liquidity being withdrawn from the job
  event LiquidityWithdrawal(address indexed _job, address indexed _liquidity, address indexed _receiver, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  /// @param _periodCredits The credits of the job for the current period
  event LiquidityCreditsReward(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits, uint256 _periodCredits);

  /// @notice Emitted when Keep3rJobFundableLiquidity#forceLiquidityCreditsToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  event LiquidityCreditsForced(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits);

  // Errors

  /// @notice Throws when the liquidity being approved has already been approved
  error LiquidityPairApproved();

  /// @notice Throws when the liquidity being removed has not been approved
  error LiquidityPairUnexistent();

  /// @notice Throws when trying to add liquidity to an unapproved pool
  error LiquidityPairUnapproved();

  /// @notice Throws when the job doesn't have the requested liquidity
  error JobLiquidityUnexistent();

  /// @notice Throws when trying to remove more liquidity than the job has
  error JobLiquidityInsufficient();

  /// @notice Throws when trying to add less liquidity than the minimum liquidity required
  error JobLiquidityLessThanMin();

  // Structs

  /// @notice Stores the tick information of the different liquidity pairs
  struct TickCache {
    int56 current; // Tracks the current tick
    int56 difference; // Stores the difference between the current tick and the last tick
    uint256 period; // Stores the period at which the last observation was made
  }

  // Variables

  /// @notice Lists liquidity pairs
  /// @return _list An array of addresses with all the approved liquidity pairs
  function approvedLiquidities() external view returns (address[] memory _list);

  /// @notice Amount of liquidity in a specified job
  /// @param _job The address of the job being checked
  /// @param _liquidity The address of the liquidity we are checking
  /// @return _amount Amount of liquidity in the specified job
  function liquidityAmount(address _job, address _liquidity) external view returns (uint256 _amount);

  /// @notice Last time the job was rewarded liquidity credits
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was rewarded liquidity credits
  function rewardedAt(address _job) external view returns (uint256 _timestamp);

  /// @notice Last time the job was worked
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was worked
  function workedAt(address _job) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Returns the liquidity credits of a given job
  /// @param _job The address of the job of which we want to know the liquidity credits
  /// @return _amount The liquidity credits of a given job
  function jobLiquidityCredits(address _job) external view returns (uint256 _amount);

  /// @notice Returns the credits of a given job for the current period
  /// @param _job The address of the job of which we want to know the period credits
  /// @return _amount The credits the given job has at the current period
  function jobPeriodCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates the total credits of a given job
  /// @param _job The address of the job of which we want to know the total credits
  /// @return _amount The total credits of the given job
  function totalJobCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates how many credits should be rewarded periodically for a given liquidity amount
  /// @dev _periodCredits = underlying KP3Rs for given liquidity amount * rewardPeriod / inflationPeriod
  /// @param _liquidity The liquidity to provide
  /// @param _amount The amount of liquidity to provide
  /// @return _periodCredits The amount of KP3R periodically minted for the given liquidity
  function quoteLiquidity(address _liquidity, uint256 _amount) external view returns (uint256 _periodCredits);

  /// @notice Observes the current state of the liquidity pair being observed and updates TickCache with the information
  /// @param _liquidity The liquidity pair being observed
  /// @return _tickCache The updated TickCache
  function observeLiquidity(address _liquidity) external view returns (TickCache memory _tickCache);

  /// @notice Gifts liquidity credits to the specified job
  /// @param _job The address of the job being credited
  /// @param _amount The amount of liquidity credits to gift
  function forceLiquidityCreditsToJob(address _job, uint256 _amount) external;

  /// @notice Approve a liquidity pair for being accepted in future
  /// @param _liquidity The address of the liquidity accepted
  function approveLiquidity(address _liquidity) external;

  /// @notice Revoke a liquidity pair from being accepted in future
  /// @param _liquidity The liquidity no longer accepted
  function revokeLiquidity(address _liquidity) external;

  /// @notice Allows anyone to fund a job with liquidity
  /// @param _job The address of the job to assign liquidity to
  /// @param _liquidity The liquidity being added
  /// @param _amount The amount of liquidity tokens to add
  function addLiquidityToJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Unbond liquidity for a job
  /// @dev Can only be called by the job's owner
  /// @param _job The address of the job being unbound from
  /// @param _liquidity The liquidity being unbound
  /// @param _amount The amount of liquidity being removed
  function unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Withdraw liquidity from a job
  /// @param _job The address of the job being withdrawn from
  /// @param _liquidity The liquidity being withdrawn
  /// @param _receiver The address that will receive the withdrawn liquidity
  function withdrawLiquidityFromJob(
    address _job,
    address _liquidity,
    address _receiver
  ) external;
}

/// @title Keep3rJobManager contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobManager {
  // Events

  /// @notice Emitted when Keep3rJobManager#addJob is called
  /// @param _job The address of the job to add
  /// @param _jobOwner The job's owner
  event JobAddition(address indexed _job, address indexed _jobOwner);

  // Errors

  /// @notice Throws when trying to add a job that has already been added
  error JobAlreadyAdded();

  /// @notice Throws when the address that is trying to register as a keeper is already a keeper
  error AlreadyAKeeper();

  // Methods

  /// @notice Allows any caller to add a new job
  /// @param _job Address of the contract for which work should be performed
  function addJob(address _job) external;
}

/// @title Keep3rJobWorkable contract
/// @notice Handles the mechanisms jobs can pay keepers with along with the restrictions jobs can put on keepers before they can work on jobs
interface IKeep3rJobWorkable {
  // Events

  /// @notice Emitted when a keeper is validated before a job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of keeper validation
  event KeeperValidation(uint256 _gasLeft);

  /// @notice Emitted when a keeper works a job
  /// @param _credit The address of the asset in which the keeper is paid
  /// @param _job The address of the job the keeper has worked
  /// @param _keeper The address of the keeper that has worked the job
  /// @param _amount The amount that has been paid out to the keeper in exchange for working the job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of payment
  event KeeperWork(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _amount, uint256 _gasLeft);

  // Errors

  /// @notice Throws if the address claiming to be a job is not in the list of approved jobs
  error JobUnapproved();

  /// @notice Throws if the amount of funds in the job is less than the payment that must be paid to the keeper that works that job
  error InsufficientFunds();

  // Methods

  /// @notice Confirms if the current keeper is registered, can be used for general (non critical) functions
  /// @param _keeper The keeper being investigated
  /// @return _isKeeper Whether the address passed as a parameter is a keeper or not
  function isKeeper(address _keeper) external returns (bool _isKeeper);

  /// @notice Confirms if the current keeper is registered and has a minimum bond of any asset. Should be used for protected functions
  /// @param _keeper The keeper to check
  /// @param _bond The bond token being evaluated
  /// @param _minBond The minimum amount of bonded tokens
  /// @param _earned The minimum funds earned in the keepers lifetime
  /// @param _age The minimum keeper age required
  /// @return _isBondedKeeper Whether the `_keeper` meets the given requirements
  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool _isBondedKeeper);

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Automatically calculates the payment for the keeper
  /// @param _keeper Address of the keeper that performed the work
  function worked(address _keeper) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with KP3R
  /// @param _keeper Address of the keeper that performed the work
  /// @param _payment The reward that should be allocated for the job
  function bondedPayment(address _keeper, uint256 _payment) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with a specific token
  /// @param _token The asset being awarded to the keeper
  /// @param _keeper Address of the keeper that performed the work
  /// @param _amount The reward that should be allocated
  function directTokenPayment(
    address _token,
    address _keeper,
    uint256 _amount
  ) external;
}

/// @title Keep3rJobOwnership contract
/// @notice Handles the ownership of the jobs
interface IKeep3rJobOwnership {
  // Events

  /// @notice Emitted when Keep3rJobOwnership#changeJobOwnership is called
  /// @param _job The address of the job proposed to have a change of owner
  /// @param _owner The current owner of the job
  /// @param _pendingOwner The new address proposed to be the owner of the job
  event JobOwnershipChange(address indexed _job, address indexed _owner, address indexed _pendingOwner);

  /// @notice Emitted when Keep3rJobOwnership#JobOwnershipAssent is called
  /// @param _job The address of the job which the proposed owner will now own
  /// @param _previousOwner The previous owner of the job
  /// @param _newOwner The newowner of the job
  event JobOwnershipAssent(address indexed _job, address indexed _previousOwner, address indexed _newOwner);

  // Errors

  /// @notice Throws when the caller of the function is not the job owner
  error OnlyJobOwner();

  /// @notice Throws when the caller of the function is not the pending job owner
  error OnlyPendingJobOwner();

  // Variables

  /// @notice Maps the job to the owner of the job (job => user)
  /// @return _owner The addres of the owner of the job
  function jobOwner(address _job) external view returns (address _owner);

  /// @notice Maps the owner of the job to its pending owner (job => user)
  /// @return _pendingOwner The address of the pending owner of the job
  function jobPendingOwner(address _job) external view returns (address _pendingOwner);

  // Methods

  /// @notice Proposes a new address to be the owner of the job
  function changeJobOwnership(address _job, address _newOwner) external;

  /// @notice The proposed address accepts to be the owner of the job
  function acceptJobOwnership(address _job) external;
}

/// @title Keep3rJobMigration contract
/// @notice Handles the migration process of jobs to different addresses
interface IKeep3rJobMigration {
  // Events

  /// @notice Emitted when Keep3rJobMigration#migrateJob function is called
  /// @param _fromJob The address of the job that requests to migrate
  /// @param _toJob The address at which the job requests to migrate
  event JobMigrationRequested(address indexed _fromJob, address _toJob);

  /// @notice Emitted when Keep3rJobMigration#acceptJobMigration function is called
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address at which the job had requested to migrate
  event JobMigrationSuccessful(address _fromJob, address indexed _toJob);

  // Errors

  /// @notice Throws when the address of the job that requests to migrate wants to migrate to its same address
  error JobMigrationImpossible();

  /// @notice Throws when the _toJob address differs from the address being tracked in the pendingJobMigrations mapping
  error JobMigrationUnavailable();

  /// @notice Throws when cooldown between migrations has not yet passed
  error JobMigrationLocked();

  // Variables

  /// @notice Maps the jobs that have requested a migration to the address they have requested to migrate to
  /// @return _toJob The address to which the job has requested to migrate to
  function pendingJobMigrations(address _fromJob) external view returns (address _toJob);

  // Methods

  /// @notice Initializes the migration process for a job by adding the request to the pendingJobMigrations mapping
  /// @param _fromJob The address of the job that is requesting to migrate
  /// @param _toJob The address at which the job is requesting to migrate
  function migrateJob(address _fromJob, address _toJob) external;

  /// @notice Completes the migration process for a job
  /// @dev Unbond/withdraw process doesn't get migrated
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address to which the job wants to migrate to
  function acceptJobMigration(address _fromJob, address _toJob) external;
}

/// @title Keep3rJobDisputable contract
/// @notice Handles the actions that can be taken on a disputed job
interface IKeep3rJobDisputable is IKeep3rJobFundableCredits, IKeep3rJobFundableLiquidity {
  // Events

  /// @notice Emitted when Keep3rJobDisputable#slashTokenFromJob is called
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token being slashed
  /// @param _slasher The user that slashes the token
  /// @param _amount The amount of the token being slashed
  event JobSlashToken(address indexed _job, address _token, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rJobDisputable#slashLiquidityFromJob is called
  /// @param _job The address of the job from which the liquidity will be slashed
  /// @param _liquidity The address of the liquidity being slashed
  /// @param _slasher The user that slashes the liquidity
  /// @param _amount The amount of the liquidity being slashed
  event JobSlashLiquidity(address indexed _job, address _liquidity, address indexed _slasher, uint256 _amount);

  // Errors

  /// @notice Throws when the token trying to be slashed doesn't exist
  error JobTokenUnexistent();

  /// @notice Throws when someone tries to slash more tokens than the job has
  error JobTokenInsufficient();

  // Methods

  /// @notice Allows governance or slasher to slash a job specific token
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token that will be slashed
  /// @param _amount The amount of the token that will be slashed
  function slashTokenFromJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Allows governance or a slasher to slash liquidity from a job
  /// @param _job The address being slashed
  /// @param _liquidity The address of the liquidity that will be slashed
  /// @param _amount The amount of liquidity that will be slashed
  function slashLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;
}

// solhint-disable-next-line no-empty-blocks
interface IKeep3rJobs is IKeep3rJobOwnership, IKeep3rJobDisputable, IKeep3rJobMigration, IKeep3rJobManager, IKeep3rJobWorkable {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rRoles contract
/// @notice Manages the Keep3r specific roles
interface IKeep3rRoles {
  // Events

  /// @notice Emitted when a slasher is added
  /// @param _slasher Address of the added slasher
  event SlasherAdded(address _slasher);

  /// @notice Emitted when a slasher is removed
  /// @param _slasher Address of the removed slasher
  event SlasherRemoved(address _slasher);

  /// @notice Emitted when a disputer is added
  /// @param _disputer Address of the added disputer
  event DisputerAdded(address _disputer);

  /// @notice Emitted when a disputer is removed
  /// @param _disputer Address of the removed disputer
  event DisputerRemoved(address _disputer);

  // Variables

  /// @notice Maps an address to a boolean to determine whether the address is a slasher or not.
  /// @return _isSlasher Whether the address is a slasher or not
  function slashers(address _slasher) external view returns (bool _isSlasher);

  /// @notice Maps an address to a boolean to determine whether the address is a disputer or not.
  /// @return _isDisputer Whether the address is a disputer or not
  function disputers(address _disputer) external view returns (bool _isDisputer);

  // Errors

  /// @notice Throws if the address is already a registered slasher
  error SlasherExistent();

  /// @notice Throws if caller is not a registered slasher
  error SlasherUnexistent();

  /// @notice Throws if the address is already a registered disputer
  error DisputerExistent();

  /// @notice Throws if caller is not a registered disputer
  error DisputerUnexistent();

  /// @notice Throws if the msg.sender is not a slasher or is not a part of governance
  error OnlySlasher();

  /// @notice Throws if the msg.sender is not a disputer or is not a part of governance
  error OnlyDisputer();

  // Methods

  /// @notice Registers a slasher by updating the slashers mapping
  function addSlasher(address _slasher) external;

  /// @notice Removes a slasher by updating the slashers mapping
  function removeSlasher(address _slasher) external;

  /// @notice Registers a disputer by updating the disputers mapping
  function addDisputer(address _disputer) external;

  /// @notice Removes a disputer by updating the disputers mapping
  function removeDisputer(address _disputer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

/// @title Keep3rParameters contract
/// @notice Handles and sets all the required parameters for Keep3r

interface IKeep3rParameters is IBaseErrors {
  // Events

  /// @notice Emitted when the Keep3rHelper address is changed
  /// @param _keep3rHelper The address of Keep3rHelper's contract
  event Keep3rHelperChange(address _keep3rHelper);

  /// @notice Emitted when the Keep3rV1 address is changed
  /// @param _keep3rV1 The address of Keep3rV1's contract
  event Keep3rV1Change(address _keep3rV1);

  /// @notice Emitted when the Keep3rV1Proxy address is changed
  /// @param _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  event Keep3rV1ProxyChange(address _keep3rV1Proxy);

  /// @notice Emitted when the KP3R-WETH pool address is changed
  /// @param _kp3rWethPool The address of the KP3R-WETH pool
  event Kp3rWethPoolChange(address _kp3rWethPool);

  /// @notice Emitted when bondTime is changed
  /// @param _bondTime The new bondTime
  event BondTimeChange(uint256 _bondTime);

  /// @notice Emitted when _liquidityMinimum is changed
  /// @param _liquidityMinimum The new _liquidityMinimum
  event LiquidityMinimumChange(uint256 _liquidityMinimum);

  /// @notice Emitted when _unbondTime is changed
  /// @param _unbondTime The new _unbondTime
  event UnbondTimeChange(uint256 _unbondTime);

  /// @notice Emitted when _rewardPeriodTime is changed
  /// @param _rewardPeriodTime The new _rewardPeriodTime
  event RewardPeriodTimeChange(uint256 _rewardPeriodTime);

  /// @notice Emitted when the inflationPeriod is changed
  /// @param _inflationPeriod The new inflationPeriod
  event InflationPeriodChange(uint256 _inflationPeriod);

  /// @notice Emitted when the fee is changed
  /// @param _fee The new token credits fee
  event FeeChange(uint256 _fee);

  // Variables

  /// @notice Address of Keep3rHelper's contract
  /// @return _keep3rHelper The address of Keep3rHelper's contract
  function keep3rHelper() external view returns (address _keep3rHelper);

  /// @notice Address of Keep3rV1's contract
  /// @return _keep3rV1 The address of Keep3rV1's contract
  function keep3rV1() external view returns (address _keep3rV1);

  /// @notice Address of Keep3rV1Proxy's contract
  /// @return _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  function keep3rV1Proxy() external view returns (address _keep3rV1Proxy);

  /// @notice Address of the KP3R-WETH pool
  /// @return _kp3rWethPool The address of KP3R-WETH pool
  function kp3rWethPool() external view returns (address _kp3rWethPool);

  /// @notice The amount of time required to pass after a keeper has bonded assets for it to be able to activate
  /// @return _days The required bondTime in days
  function bondTime() external view returns (uint256 _days);

  /// @notice The amount of time required to pass before a keeper can unbond what he has bonded
  /// @return _days The required unbondTime in days
  function unbondTime() external view returns (uint256 _days);

  /// @notice The minimum amount of liquidity required to fund a job per liquidity
  /// @return _amount The minimum amount of liquidity in KP3R
  function liquidityMinimum() external view returns (uint256 _amount);

  /// @notice The amount of time between each scheduled credits reward given to a job
  /// @return _days The reward period in days
  function rewardPeriodTime() external view returns (uint256 _days);

  /// @notice The inflation period is the denominator used to regulate the emission of KP3R
  /// @return _period The denominator used to regulate the emission of KP3R
  function inflationPeriod() external view returns (uint256 _period);

  /// @notice The fee to be sent to governance when a user adds liquidity to a job
  /// @return _amount The fee amount to be sent to governance when a user adds liquidity to a job
  function fee() external view returns (uint256 _amount);

  // solhint-disable func-name-mixedcase
  /// @notice The base that will be used to calculate the fee
  /// @return _base The base that will be used to calculate the fee
  function BASE() external view returns (uint256 _base);

  /// @notice The minimum rewardPeriodTime value to be set
  /// @return _minPeriod The minimum reward period in seconds
  function MIN_REWARD_PERIOD_TIME() external view returns (uint256 _minPeriod);

  // solhint-enable func-name-mixedcase

  // Errors

  /// @notice Throws if the reward period is less than the minimum reward period time
  error MinRewardPeriod();

  /// @notice Throws if either a job or a keeper is disputed
  error Disputed();

  /// @notice Throws if there are no bonded assets
  error BondsUnexistent();

  /// @notice Throws if the time required to bond an asset has not passed yet
  error BondsLocked();

  /// @notice Throws if there are no bonds to withdraw
  error UnbondsUnexistent();

  /// @notice Throws if the time required to withdraw the bonds has not passed yet
  error UnbondsLocked();

  // Methods

  /// @notice Sets the Keep3rHelper address
  /// @param _keep3rHelper The Keep3rHelper address
  function setKeep3rHelper(address _keep3rHelper) external;

  /// @notice Sets the Keep3rV1 address
  /// @param _keep3rV1 The Keep3rV1 address
  function setKeep3rV1(address _keep3rV1) external;

  /// @notice Sets the Keep3rV1Proxy address
  /// @param _keep3rV1Proxy The Keep3rV1Proxy address
  function setKeep3rV1Proxy(address _keep3rV1Proxy) external;

  /// @notice Sets the KP3R-WETH pool address
  /// @param _kp3rWethPool The KP3R-WETH pool address
  function setKp3rWethPool(address _kp3rWethPool) external;

  /// @notice Sets the bond time required to activate as a keeper
  /// @param _bond The new bond time
  function setBondTime(uint256 _bond) external;

  /// @notice Sets the unbond time required unbond what has been bonded
  /// @param _unbond The new unbond time
  function setUnbondTime(uint256 _unbond) external;

  /// @notice Sets the minimum amount of liquidity required to fund a job
  /// @param _liquidityMinimum The new minimum amount of liquidity
  function setLiquidityMinimum(uint256 _liquidityMinimum) external;

  /// @notice Sets the time required to pass between rewards for jobs
  /// @param _rewardPeriodTime The new amount of time required to pass between rewards
  function setRewardPeriodTime(uint256 _rewardPeriodTime) external;

  /// @notice Sets the new inflation period
  /// @param _inflationPeriod The new inflation period
  function setInflationPeriod(uint256 _inflationPeriod) external;

  /// @notice Sets the new fee
  /// @param _fee The new fee
  function setFee(uint256 _fee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

interface IBaseErrors {
  /// @notice Throws if a variable is assigned to the zero address
  error ZeroAddress();
}