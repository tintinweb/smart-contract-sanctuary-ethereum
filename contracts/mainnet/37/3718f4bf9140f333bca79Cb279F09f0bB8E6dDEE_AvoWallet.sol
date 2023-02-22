// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
pragma solidity >=0.8.17;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { IAvoWalletV2 } from "../interfaces/IAvoWalletV2.sol";
import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { InstaFlashReceiverInterface } from "../external/InstaFlashReceiverInterface.sol";
import { SelfUpgradeable } from "./SelfUpgradeable.sol";
import { VariablesV1, AvoWallet__InvalidParams } from "./VariablesV1.sol";

/// @title  AvoWallet
/// @notice Smart wallet supporting meta transactions with EIP712 signature. Supports receiving NFTs.
///         The `cast` method allows the owner of the wallet to execute multiple arbitrary actions
///         Relayers are expected to call the forwarder contract `execute`, which deploys an AvoWallet if necessary first.
///         Upgradeable by calling `upgradeTo` (or `upgradeToAndCall`) through a `cast` call, see SelfUpgradeable.sol
/// @dev    This contract implements parts of EIP-2770 in a minimized form. E.g. domainSeparator is immutable etc.
///         This contract does not implement ERC2771, because trusting an upgradeable "forwarder"
///         bears a security risk for this non-custodial wallet
///         Signature related logic is based off of OpenZeppelin EIP712Upgradeable.
///         This contract validates all signatures for defaultChainId of 634 instead of current block.chainid from opcode (EIP-1344)
///         For replay protection, the current block.chainid instead is used in the EIP-712 salt
/// @dev    Note For any new implementation, the upgrade method MUST be in the implementation itself,
///         otherwise it can not be upgraded anymore! also see SelfUpgradeable
///
/// @dev    IMPORTANT: do not move around order of first 3 inheritance to keep storage layout: VariablesV1, SelfUpgradeable, Initializable
contract AvoWallet is VariablesV1, SelfUpgradeable, Initializable, ERC721Holder, InstaFlashReceiverInterface {
    using Address for address;
    using Strings for uint256;

    /***********************************|
    |               ERRORS              |
    |__________________________________*/

    error AvoWallet__InvalidSignature();
    error AvoWallet__Expired();
    error AvoWallet__Unauthorized();
    error AvoWallet__InsufficientGasSent();
    error AvoWallet__OutOfGas();

    /***********************************|
    |             CONSTANTS             |
    |__________________________________*/

    // constants for EIP712 values
    string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Safe";
    string public constant DOMAIN_SEPARATOR_VERSION = "2.0.0";

    /// @dev overwrite chain id for EIP712 is always set to 634
    uint256 public constant DEFAULT_CHAIN_ID = 634;

    /// @dev _TYPE_HASH is copied from OpenZeppelin EIP712 but with added salt as last param (we use it for block.chainid)
    bytes32 public constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    /// @dev EIP712 typehash for cast calls including struct for Action
    bytes32 public constant CAST_TYPE_HASH =
        keccak256(
            "Cast(Action[] actions,CastParams params,uint256 avoSafeNonce)Action(address target,bytes data,uint256 value,uint256 operation)CastParams(uint256 validUntil,uint256 gas,address source,uint256 id,bytes metadata)"
        );

    /// @dev EIP712 typehash for Action struct
    bytes32 public constant ACTION_TYPE_HASH =
        keccak256("Action(address target,bytes data,uint256 value,uint256 operation)");
    /// @dev EIP712 typehash for CastParams struct
    bytes32 public constant CAST_PARAMS_TYPE_HASH =
        keccak256("CastParams(uint256 validUntil,uint256 gas,address source,uint256 id,bytes metadata)");

    // hashed EIP712 values
    bytes32 internal constant DOMAIN_SEPARATOR_NAME_HASHED = keccak256(bytes(DOMAIN_SEPARATOR_NAME));
    bytes32 internal constant DOMAIN_SEPARATOR_VERSION_HASHED = keccak256(bytes(DOMAIN_SEPARATOR_VERSION));
    /// @dev amount of gas to keep in cast caller method as reserve for emitting CastFailed event
    uint256 internal constant CAST_RESERVE_GAS = 12000;

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice emitted when all actions for cast() are executed successfully
    event CastExecuted(address indexed source, address indexed caller, bytes metadata);

    /// @notice emitted if one of the actions in cast() fails. reason will be prefixed with the index of the action.
    /// e.g. if action 1 fails, then the reason will be 1_reason
    /// if an action in the flashloan callback fails, it will be prefixed with with two numbers:
    /// e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails, the reason will be 1_2_reason
    event CastFailed(address indexed source, address indexed caller, string reason, bytes metadata);

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice                        constructor sets avoVersionsRegistry and avoForwarder (immutable).
    ///                                also see SelfUpgradeable constructor for details about setting avoVersionsRegistry
    /// @param avoVersionsRegistry_    address of the avoVersionsRegistry contract
    /// @param avoForwarder_           address of the avoForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in AvoVersionsRegistry.
    constructor(IAvoVersionsRegistry avoVersionsRegistry_, address avoForwarder_)
        VariablesV1(avoVersionsRegistry_, avoForwarder_)
    {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @inheritdoc IAvoWalletV2
    function initialize(address owner_) public initializer {
        // owner must be EOA
        if (owner_.isContract() || owner_ == address(0)) {
            revert AvoWallet__InvalidParams();
        }

        owner = owner_;
    }

    /// @inheritdoc IAvoWalletV2
    function initializeWithVersion(address owner_, address avoWalletVersion_) public initializer {
        // owner must be EOA
        if (owner_.isContract() || owner_ == address(0)) {
            revert AvoWallet__InvalidParams();
        }

        owner = owner_;

        _avoWalletImpl = avoWalletVersion_;
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    receive() external payable {}

    /// @inheritdoc IAvoWalletV2
    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @inheritdoc IAvoWalletV2
    function verify(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external view returns (bool) {
        // do not use modifier to avoid stack too deep
        _validateParams(actions_, params_.validUntil);

        bytes32 digest_ = _getSigDigest(actions_, params_);

        if (!_verifySig(digest_, signature_)) {
            revert AvoWallet__InvalidSignature();
        }
        return true;
    }

    /// @inheritdoc IAvoWalletV2
    function cast(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external payable returns (bool success_, string memory revertReason_) {
        {
            if (msg.sender == avoForwarder) {
                // if sender is forwarder, first thing we must do is compare actual sent gas to user instructed gas
                // adding 500 to gasleft for approx. already used gas
                if ((gasleft() + 500) < params_.gas) {
                    // relayer has not sent enough gas to cover gas limit as user instructed
                    revert AvoWallet__InsufficientGasSent();
                }

                _validateParams(actions_, params_.validUntil);

                // if cast is called through forwarder signature must be valid
                bytes32 digest_ = _getSigDigest(actions_, params_);

                if (!_verifySig(digest_, signature_)) {
                    revert AvoWallet__InvalidSignature();
                }
            } else if (msg.sender == owner) {
                _validateParams(actions_, params_.validUntil);
            } else {
                // sender must be either owner or allowed forwarder
                revert AvoWallet__Unauthorized();
            }
        }

        // set status verified to 1 for call to _callTargets to avoid having to check signature etc. again
        _status = 1;

        // nonce increases *always* if signature is valid
        avoSafeNonce++;

        // execute _callTargets via a low-level call to create a separate execution frame
        // this is used to revert all the actions if one action fails without reverting the whole transaction
        bytes memory calldata_ = abi.encodeCall(AvoWallet._callTargets, (actions_, params_.id));
        bytes memory result_;
        // using inline assembly for delegatecall to define custom gas amount that should stay here in caller
        assembly {
            success_ := delegatecall(
                // reserve at least ~12k gas to make sure we can emit CastFailed event even for out of gas cases
                sub(gas(), CAST_RESERVE_GAS),
                sload(_avoWalletImpl.slot),
                add(calldata_, 0x20),
                mload(calldata_),
                0,
                0
            )
            let size := returndatasize()

            result_ := mload(0x40)
            mstore(0x40, add(result_, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(result_, size)
            returndatacopy(add(result_, 0x20), 0, size)
        }

        if (!success_) {
            if (result_.length == 0) {
                // @dev this case might be caused by edge-case out of gas errors that we were unable to catch
                // but could potentially also have other reasons
                revertReason_ = "AVO__REASON_NOT_DEFINED";
            } else if (bytes4(result_) == bytes4(0x8707015b)) {
                // 0x8707015b = selector for custom error AvoWallet__OutOfGas
                revertReason_ = "AVO__OUT_OF_GAS";
            } else {
                assembly {
                    result_ := add(result_, 0x04)
                }
                revertReason_ = abi.decode(result_, (string));
            }

            emit CastFailed(params_.source, msg.sender, revertReason_, params_.metadata);
        } else {
            emit CastExecuted(params_.source, msg.sender, params_.metadata);
        }
    }

    /***********************************|
    |         FLASHLOAN CALLBACK        |
    |__________________________________*/

    /// @dev                 callback used by Instadapp Flashloan Aggregator, executes operations while owning
    ///                      the flashloaned amounts. data_ must contain actions, one of them must pay back flashloan
    // /// @param assets_       assets_ received a flashloan for
    // /// @param amounts_      flashloaned amounts for each asset
    // /// @param premiums_     fees to pay for the flashloan
    /// @param initiator_    flashloan initiator -> must be this contract
    /// @param data_         data bytes containing the abi.encoded actions that are executed similarly to .callTargets
    function executeOperation(
        address[] calldata, /*  assets_ */
        uint256[] calldata, /*  amounts_ */
        uint256[] calldata, /*  premiums_ */
        address initiator_,
        bytes calldata data_
    ) external returns (bool) {
        // @dev using the valid case inverted via one ! instead of invalid case with 3 ! to optimize gas usage
        if (!((_status == 20 || _status == 21) && initiator_ == address(this))) {
            revert AvoWallet__Unauthorized();
        }

        // _status is set to original id_ pre-flashloan trigger in _callTargets
        uint256 id_ = _status;

        // reset status immediately
        _status = 0;

        // decode actions to be executed after getting the flashloan
        Action[] memory actions_ = abi.decode(data_, (Action[]));

        StorageSnapshot memory storageSnapshot_;
        if (id_ == 21) {
            // store values before execution to make sure storage vars are not modified by a delegatecall
            storageSnapshot_.owner = owner;
            storageSnapshot_.avoWalletImpl = _avoWalletImpl;
            storageSnapshot_.avoSafeNonce = avoSafeNonce;
        }

        uint256 actionsLength_ = actions_.length;
        for (uint256 i; i < actionsLength_; ) {
            Action memory action_ = actions_[i];

            // execute action
            bool success_;
            bytes memory result_;
            if (action_.operation == 0) {
                // no enforcing of id_ needed here because code would revert earlier if id is not 20 or 21
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else if (action_.operation == 1 && id_ == 21) {
                // delegatecall (operation =1 & id = mixed)
                (success_, result_) = action_.target.delegatecall(action_.data);
            } else {
                // either operation does not exist or the id was not set according to what the action wants to execute
                if (action_.operation > 2) {
                    revert(string.concat(i.toString(), "_AVO__OPERATION_NOT_EXIST"));
                } else if (action_.operation == 2) {
                    revert(string.concat(i.toString(), "_AVO__NO_FLASHLOAN_IN_FLASHLOAN"));
                } else {
                    // enforce that id must be set according to operation
                    revert(string.concat(i.toString(), "_AVO__ID_ACTION_MISMATCH"));
                }
            }

            if (!success_) {
                revert(string.concat(i.toString(), _getRevertReasonFromReturnedData(result_)));
            }

            unchecked {
                ++i;
            }
        }

        // if actions include delegatecall, make sure storage was not modified
        if (
            (storageSnapshot_.avoSafeNonce > 0) &&
            !(storageSnapshot_.avoWalletImpl == _avoWalletImpl &&
                storageSnapshot_.owner == owner &&
                storageSnapshot_.avoSafeNonce == avoSafeNonce &&
                _status == 0)
        ) {
            revert("AVO__MODIFIED_STORAGE");
        }

        return true;
    }

    /***********************************|
    |         INDIRECT INTERNAL         |
    |__________________________________*/

    /// @dev                  executes a low-level .call or .delegateCall on all actions, can only be called by this contract
    ///                       this is called like an external call to create a separate execution frame.
    ///                       this way we can revert all the actions if one fails without reverting the whole transaction
    /// @param actions_       the actions to execute (target, data, value)
    /// @param id_            id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable {
        // status must be verified or 0x000000000000000000000000000000000000dEaD used for backend gas estimations
        if (!(_status == 1 || tx.origin == 0x000000000000000000000000000000000000dEaD)) {
            revert AvoWallet__Unauthorized();
        }

        bool isCallId_ = id_ < 2 || id_ == 20 || id_ == 21;
        bool isDelegateCallId_ = id_ == 1 || id_ == 21;

        // reset status immediately
        _status = 0;

        StorageSnapshot memory storageSnapshot_;
        if (isDelegateCallId_) {
            // store values before execution to make sure storage vars are not modified by a delegatecall
            storageSnapshot_.owner = owner;
            storageSnapshot_.avoWalletImpl = _avoWalletImpl;
            storageSnapshot_.avoSafeNonce = avoSafeNonce;
        }

        uint256 actionsLength_ = actions_.length;
        for (uint256 i; i < actionsLength_; ) {
            Action memory action_ = actions_[i];

            // execute action
            bool success_;
            bytes memory result_;
            uint256 actionMinGasLeft_;
            if (action_.operation == 0 && isCallId_) {
                // call (operation =0 & id = call or mixed)
                // @dev try catch does not work for .call
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    actionMinGasLeft_ = gasleft() / 64;
                }
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else if (action_.operation == 1 && isDelegateCallId_) {
                // delegatecall (operation =1 & id = delegateCall(1) or mixed(2))
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    actionMinGasLeft_ = gasleft() / 64;
                }
                (success_, result_) = action_.target.delegatecall(action_.data);
            } else if (action_.operation == 2 && (id_ == 20 || id_ == 21)) {
                // flashloan is always execute via .call, flashloan aggregator uses msg.sender, so .delegatecall
                // wouldn't send funds to this contract but rather to the original sender
                _status = uint8(id_);
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    actionMinGasLeft_ = gasleft() / 64;
                }
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else {
                // either operation does not exist or the id was not set according to what the action wants to execute
                if (action_.operation > 2) {
                    revert(string.concat(i.toString(), "_AVO__OPERATION_NOT_EXIST"));
                } else {
                    // enforce that id must be set according to operation
                    revert(string.concat(i.toString(), "_AVO__ID_ACTION_MISMATCH"));
                }
            }

            if (!success_) {
                if (gasleft() < actionMinGasLeft_) {
                    // action ran out of gas, trigger revert with specific custom error
                    revert AvoWallet__OutOfGas();
                }

                revert(string.concat(i.toString(), _getRevertReasonFromReturnedData(result_)));
            }

            unchecked {
                ++i;
            }
        }

        // if actions include delegatecall, make sure storage was not modified
        if (
            (storageSnapshot_.avoSafeNonce > 0) &&
            !(storageSnapshot_.avoWalletImpl == _avoWalletImpl &&
                storageSnapshot_.owner == owner &&
                storageSnapshot_.avoSafeNonce == avoSafeNonce &&
                _status == 0)
        ) {
            revert("AVO__MODIFIED_STORAGE");
        }
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev                Validates input params to cast and verify calls. Reverts on invalid values.
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in,
    ///                     or 0 if request validity is not time-limited
    function _validateParams(Action[] calldata actions_, uint256 validUntil_) internal view {
        if (actions_.length == 0) {
            revert AvoWallet__InvalidParams();
        }

        // make sure request is still valid
        if (validUntil_ > 0 && validUntil_ < block.timestamp) {
            revert AvoWallet__Expired();
        }
    }

    /// @dev                Verifies a EIP712 signature
    /// @param digest_      the EIP712 digest for the signature
    /// @param signature_   the EIP712 signature, see verifySig method
    /// @return             true if the signature is valid, false otherwise
    function _verifySig(bytes32 digest_, bytes calldata signature_) internal view returns (bool) {
        address recoveredSigner_ = ECDSA.recover(digest_, signature_);

        return recoveredSigner_ == owner;
    }

    /// @dev                  gets the digest to verify an EIP712 signature
    /// @param actions_       the actions to execute (target, data, value)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @return               bytes32 digest to verify signature
    function _getSigDigest(Action[] calldata actions_, CastParams calldata params_) internal view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                // domain separator
                _domainSeparatorV4(),
                // structHash
                keccak256(
                    abi.encode(
                        CAST_TYPE_HASH,
                        // actions
                        getActionsHash_(actions_),
                        // CastParams
                        keccak256(
                            abi.encode(
                                CAST_PARAMS_TYPE_HASH,
                                params_.validUntil,
                                params_.gas,
                                params_.source,
                                params_.id,
                                keccak256(params_.metadata)
                            )
                        ),
                        avoSafeNonce
                    )
                )
            );
    }

    /// @dev                gets the keccak256 hash for actions array struct for EIP712 signature digest
    /// @param actions_     the actions to execute (target, data, value)
    /// @return             bytes32 hash for actions array struct to verify signature
    function getActionsHash_(Action[] calldata actions_) internal pure returns (bytes32) {
        // get keccak256s for actions
        uint256 actionsLength_ = actions_.length;
        bytes32[] memory keccakActions_ = new bytes32[](actionsLength_);
        for (uint256 i; i < actionsLength_; ) {
            keccakActions_[i] = keccak256(
                abi.encode(
                    ACTION_TYPE_HASH,
                    actions_[i].target,
                    keccak256(actions_[i].data),
                    actions_[i].value,
                    actions_[i].operation
                )
            );

            unchecked {
                ++i;
            }
        }

        return keccak256(abi.encodePacked(keccakActions_));
    }

    /// @notice Returns the domain separator for the chain with id 634
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    DOMAIN_SEPARATOR_NAME_HASHED,
                    DOMAIN_SEPARATOR_VERSION_HASHED,
                    DEFAULT_CHAIN_ID,
                    address(this),
                    keccak256(abi.encodePacked(block.chainid))
                )
            );
    }

    /// @dev Get the revert reason from the returnedData (supports Panic, Error & Custom Errors)
    /// Based on https://github.com/superfluid-finance/protocol-monorepo/blob/dev/packages/ethereum-contracts/contracts/libs/CallUtils.sol
    /// This is needed in order to provide some human-readable revert message from a call
    /// @param returnedData_ revert data of the call
    /// @return reason_      revert reason
    function _getRevertReasonFromReturnedData(bytes memory returnedData_)
        internal
        pure
        returns (string memory reason_)
    {
        if (returnedData_.length < 4) {
            // case 1: catch all
            return "_REASON_NOT_DEFINED";
        } else {
            bytes4 errorSelector;
            assembly {
                errorSelector := mload(add(returnedData_, 0x20))
            }
            if (
                errorSelector == bytes4(0x4e487b71) /* `seth sig "Panic(uint256)"` */
            ) {
                // case 2: Panic(uint256) (Defined since 0.8.0)
                // solhint-disable-next-line max-line-length
                // ref: https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require)
                reason_ = "_TARGET_PANICKED: 0x__";
                uint256 errorCode;
                assembly {
                    errorCode := mload(add(returnedData_, 0x24))
                    let reasonWord := mload(add(reason_, 0x20))
                    // [0..9] is converted to ['0'..'9']
                    // [0xa..0xf] is not correctly converted to ['a'..'f']
                    // but since panic code doesn't have those cases, we will ignore them for now!
                    let e1 := add(and(errorCode, 0xf), 0x30)
                    let e2 := shl(8, add(shr(4, and(errorCode, 0xf0)), 0x30))
                    reasonWord := or(
                        and(reasonWord, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000),
                        or(e2, e1)
                    )
                    mstore(add(reason_, 0x20), reasonWord)
                }
            } else {
                if (returnedData_.length > 68) {
                    // case 3: Error(string) (Defined at least since 0.7.0)
                    assembly {
                        returnedData_ := add(returnedData_, 0x04)
                    }
                    reason_ = string.concat("_", abi.decode(returnedData_, (string)));
                } else {
                    // case 4: Custom errors (Defined since 0.8.0)
                    reason_ = string.concat("_CUSTOM_ERROR:", fromCode(errorSelector));
                }
            }
        }
    }

    /// @dev used to convert bytes4 selector to string
    /// based on https://ethereum.stackexchange.com/a/111876
    function fromCode(bytes4 code) internal pure returns (string memory) {
        bytes memory result = new bytes(10);
        result[0] = bytes1("0");
        result[1] = bytes1("x");
        for (uint256 i = 0; i < 4; ++i) {
            result[2 * i + 2] = toHexDigit(uint8(code[i]) / 16);
            result[2 * i + 3] = toHexDigit(uint8(code[i]) % 16);
        }
        return string(result);
    }

    /// @dev used to convert bytes4 selector to string
    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { VariablesV1 } from "./VariablesV1.sol";

/// @title      SelfUpgradeable
/// @notice     Simple contract to upgrade the implementation address stored at storage slot 0x0
/// @dev        Mostly based on OpenZeppelin ERC1967Upgrade contract, adapted with selfCall etc.
///             IMPORANT to keep VariablesV1 at first inheritance to ensure proxy impl address is at 0x0
abstract contract SelfUpgradeable is VariablesV1 {
    error SelfUpgradeable__Unauthorized();

    /// @notice Emitted when the implementation is upgraded to a new AvoWallet logic contract
    event Upgraded(address indexed avoWalletImpl);

    /// @notice modifier that ensures the method can only be called by the same contract itself
    modifier onlySelf() {
        _requireSelfCalled();
        _;
    }

    /// @notice                 upgrade the contract to a new implementation address, if valid version
    ///                         can only be called by contract itself (in case of AvoWallet through `cast`)
    /// @param avoWalletImpl_   New contract address
    function upgradeTo(address avoWalletImpl_) public onlySelf {
        avoVersionsRegistry.requireValidAvoWalletVersion(avoWalletImpl_);

        _avoWalletImpl = avoWalletImpl_;
        emit Upgraded(avoWalletImpl_);
    }

    /// @notice                 upgrade the contract to a new implementation address, if valid version
    ///                         and call a function afterwards
    ///                         can only be called by contract itself (in case of AvoWallet through `cast`)
    /// @param avoWalletImpl_   New contract address
    /// @param data_            callData for function call on avoWalletImpl_ after upgrading
    /// @param forceCall_       optional flag to force send call even if callData (data_) is empty
    function upgradeToAndCall(
        address avoWalletImpl_,
        bytes calldata data_,
        bool forceCall_
    ) external payable virtual onlySelf {
        upgradeTo(avoWalletImpl_);
        if (data_.length > 0 || forceCall_) {
            Address.functionDelegateCall(avoWalletImpl_, data_);
        }
    }

    /// @dev internal method for modifier logic to reduce bytecode size of contract
    function _requireSelfCalled() internal view {
        if (msg.sender != address(this)) {
            revert SelfUpgradeable__Unauthorized();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoWalletV2 } from "../interfaces/IAvoWalletV2.sol";

error AvoWallet__InvalidParams();

/// @title      VariablesV1
/// @notice     Contains storage variables for AvoWallet.
abstract contract VariablesV1 is IAvoWalletV2 {
    /// @notice  registry holding the valid versions (addresses) for AvoWallet implementation contracts
    ///          The registry is used to verify a valid version before upgrading
    ///          immutable but could be updated in the logic contract when a new version of AvoWallet is deployed
    IAvoVersionsRegistry public immutable avoVersionsRegistry;

    /// @notice address of the AvoForwarder (proxy) that is allowed to forward tx with valid
    ///         signatures to this contract
    ///         immutable but could be updated in the logic contract when a new version of AvoWallet is deployed
    address public immutable avoForwarder;

    // the next 3 vars (avoWalletImpl, nonce, status) are tightly packed into 1 storage slot

    /// @notice address of the Avo wallet logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    IMPORTANT: DO NOT MOVE THIS VARIABLE
    ///         _avoWalletImpl MUST ALWAYS be the first declared variable here in the logic contract and in the proxy!
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    ///         immutable and constants do not take up storage slots so they can come before.
    address internal _avoWalletImpl;

    /// @notice nonce that is incremented for every `cast` transaction with valid signature
    uint88 public avoSafeNonce;

    /// @dev flag set temporarily to signal various cases:
    /// 0 -> default state
    /// 1 -> signature is valid or called by owner, _callTargets can be executed
    /// 20 / 21 -> flashloan receive can be executed (set to original id param from cast())
    uint8 internal _status;

    /// @notice owner of the smart wallet
    /// @dev theoretically immutable, can only be set in initialize (at proxy clone factory deployment)
    address public owner;

    /// @dev
    /// after owner variable there still is uint8 and bool from Initializable library. Rest of slot (10 bytes) should be empty
    /// uint8 private _initialized;
    /// bool private _initializing;

    /// @dev contracts deployed before V2 contain two more variables from EIP712Upgradeable: hashed domain separator
    /// name and version which were set at initialization (Now we do this in logic contract at deployment as constant)
    /// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/cryptography/EIP712Upgradeable.sol#L32
    /// bytes32 private _HASHED_NAME;
    /// bytes32 private _HASHED_VERSION;

    /// @notice constructor sets the immutable avoVersionsRegistry address
    /// @dev    setting this on the logic contract at deployment is ok because the
    ///         AvoVersionsRegistry is upgradeable so this address is the proxy address which really shouldn't change.
    ///         Even if it would change then worst case a new AvoWallet logic contract
    ///         has to be deployed pointing to a new registry
    /// @param avoVersionsRegistry_    address of the avoVersionsRegistry contract
    /// @param avoForwarder_           address of the avoForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in AvoVersionsRegistry.
    constructor(IAvoVersionsRegistry avoVersionsRegistry_, address avoForwarder_) {
        if (address(avoVersionsRegistry_) == address(0)) {
            revert AvoWallet__InvalidParams();
        }
        avoVersionsRegistry = avoVersionsRegistry_;

        avoVersionsRegistry.requireValidAvoForwarderVersion(avoForwarder_);
        avoForwarder = avoForwarder_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface InstaFlashReceiverInterface {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata _data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoVersionsRegistry {
    /// @notice                   checks if an address is listed as allowed AvoWallet version and reverts if it is not
    /// @param avoWalletVersion_  address of the Avo wallet logic contract to check
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view;

    /// @notice                      checks if an address is listed as allowed AvoForwarder version
    ///                              and reverts if it is not
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAvoWalletV2 {
    /// @notice an executable action via low-level call, including operation (call or delegateCall), target, data and value
    struct Action {
        address target; // the targets to execute the actions on
        bytes data; // the data to be passed to the call for each target
        uint256 value; // the msg.value to be passed to the call for each target. set to 0 if none
        uint256 operation; // 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call), id must be 0 or 2
    }

    struct CastParams {
        /// @param validUntil     As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
        ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
        ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
        uint256 validUntil;
        /// @param gas            As EIP-2770: an amount of gas limit to set for the execution
        ///                       Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        /// @param source         Source like e.g. referral for this tx
        address source;
        /// @param id             id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        /// @param metadata       Optional metadata for future flexibility
        bytes metadata;
    }

    /// @notice struct containing variables in storage for a snapshot
    struct StorageSnapshot {
        address avoWalletImpl;
        uint88 avoSafeNonce;
        address owner;
    }

    /// @notice             AvoSafe Owner
    function owner() external view returns (address);

    /// @notice             Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice             Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice             incrementing nonce for each valid tx executed (to ensure unique)
    function avoSafeNonce() external view returns (uint88);

    /// @notice             initializer called by AvoFactory after deployment
    /// @param owner_       the owner (immutable) of this smart wallet
    function initialize(address owner_) external;

    /// @notice                     initialize contract and set new AvoWallet version
    /// @param owner_               the owner (immutable) of this smart wallet
    /// @param avoWalletVersion_    version of AvoWallet logic contract to deploy
    function initializeWithVersion(address owner_, address avoWalletVersion_) external;

    /// @notice             returns the domainSeparator for EIP712 signature
    /// @return             the bytes32 domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice               Verify the transaction is valid and can be executed.
    ///                       Does not revert and returns successfully if the input is valid.
    ///                       Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param actions_       the actions to execute (target, data, value)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    function verify(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external view returns (bool);

    /// @notice               executes arbitrary actions according to datas on targets
    ///                       if one action fails, the transaction doesn't revert. Instead the CastFailed event is emitted
    ///                       and all previous actions are reverted. On success, emits CastExecuted event.
    /// @dev                  validates EIP712 signature then executes a .call or .delegateCall for every action.
    /// @param actions_       the actions to execute (target, data, value)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return success       true if all actions were executed succesfully, false otherwise.
    /// @return revertReason  revert reason if one of the actions fail
    function cast(
        Action[] calldata actions_,
        CastParams calldata params_,
        bytes calldata signature_
    ) external payable returns (bool success, string memory revertReason);
}