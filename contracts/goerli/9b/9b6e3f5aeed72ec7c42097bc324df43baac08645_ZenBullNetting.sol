// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

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
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
// pragma abicoder v2;

// interface
import "v3-core/interfaces/callback/IUniswapV3SwapCallback.sol";
import "v3-core/interfaces/IUniswapV3Pool.sol";
// lib
import "v3-periphery/libraries/Path.sol";
import "v3-core/libraries/TickMath.sol";
import "v3-core/libraries/SafeCast.sol";

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB, uint24 fee)
        internal
        pure
        returns (PoolKey memory)
    {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, address tokenA, address tokenB, uint24 fee)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(
            PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee))
        );
        require(msg.sender == address(pool));
    }
}

/**
 * @notice FlashSwap contract
 * @dev contract that interacts with Uniswap pool
 * @author opyn team
 */
abstract contract FlashSwap is IUniswapV3SwapCallback {
    using Path for bytes;
    using SafeCast for uint256;

    /// @dev Uniswap factory address
    address internal immutable factory;

    struct SwapCallbackData {
        bytes path;
        address caller;
        uint8 callSource;
        bytes callData;
    }

    /**
     * @dev constructor
     * @param _factory uniswap factory address
     */
    constructor(address _factory) {
        require(_factory != address(0), "Invalid factory address");

        factory = _factory;
    }

    /**
     * @notice uniswap swap callback function for flashes
     * @param amount0Delta amount of token0
     * @param amount1Delta amount of token1
     * @param _data callback data encoded as SwapCallbackData struct
     */
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data)
        external
        override
    {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported

        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        //ensure that callback comes from uniswap pool
        address pool = address(CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee));

        //determine the amount that needs to be repaid as part of the flashswap
        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

        //calls the strategy function that uses the proceeds from flash swap and executes logic to have an amount of token to repay the flash swap
        _uniFlashSwap(pool, amountToPay, data.callData, data.callSource);
    }

    // /**
    //  * @notice function to be called by uniswap callback.
    //  * @dev this function should be overridden by the child contract
    //  * @param _uniFlashSwapData UniFlashswapCallbackData struct
    //  */
    function _uniFlashSwap(
        address pool,
        uint256 amountToPay,
        bytes memory callData,
        uint8 callSource
    ) internal virtual { }

    /**
     * @notice execute an exact-in flash swap (specify an exact amount to pay)
     * @param _tokenIn token address to sell
     * @param _tokenOut token address to receive
     * @param _fee pool fee
     * @param _amountIn amount to sell
     * @param _amountOutMinimum minimum amount to receive
     * @param _callSource function call source
     * @param _data arbitrary data assigned with the call
     */
    function _exactInFlashSwap(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint8 _callSource,
        bytes memory _data
    ) internal returns (uint256) {
        //calls internal uniswap swap function that will trigger a callback for the flash swap
        uint256 amountOut = _exactInputInternal(
            _amountIn,
            address(this),
            uint160(0),
            SwapCallbackData({
                path: abi.encodePacked(_tokenIn, _fee, _tokenOut),
                caller: msg.sender,
                callSource: _callSource,
                callData: _data
            })
        );

        //slippage limit check
        require(amountOut >= _amountOutMinimum, "amount out less than min");

        return amountOut;
    }

    /**
     * @notice execute an exact-out flash swap (specify an exact amount to receive)
     * @param _tokenIn token address to sell
     * @param _tokenOut token address to receive
     * @param _fee pool fee
     * @param _amountOut exact amount to receive
     * @param _amountInMaximum maximum amount to sell
     * @param _callSource function call source
     * @param _data arbitrary data assigned with the call
     */
    function _exactOutFlashSwap(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint8 _callSource,
        bytes memory _data
    ) internal {
        //calls internal uniswap swap function that will trigger a callback for the flash swap
        uint256 amountIn = _exactOutputInternal(
            _amountOut,
            address(this),
            uint160(0),
            SwapCallbackData({
                path: abi.encodePacked(_tokenOut, _fee, _tokenIn),
                caller: msg.sender,
                callSource: _callSource,
                callData: _data
            })
        );

        //slippage limit check
        require(amountIn <= _amountInMaximum, "amount in greater than max");
    }

    /**
     * @notice internal function for exact-in swap on uniswap (specify exact amount to pay)
     * @param _amountIn amount of token to pay
     * @param _recipient recipient for receive
     * @param _sqrtPriceLimitX96 sqrt price limit
     * @return amount of token bought (amountOut)
     */
    function _exactInputInternal(
        uint256 _amountIn,
        address _recipient,
        uint160 _sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        //uniswap token0 has a lower address than token1
        //if tokenIn<tokenOut, we are selling an exact amount of token0 in exchange for token1
        //zeroForOne determines which token is being sold and which is being bought
        bool zeroForOne = tokenIn < tokenOut;

        //swap on uniswap, including data to trigger call back for flashswap
        (int256 amount0, int256 amount1) = _getPool(tokenIn, tokenOut, fee).swap(
            _recipient,
            zeroForOne,
            _amountIn.toInt256(),
            _sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : _sqrtPriceLimitX96,
            abi.encode(data)
        );

        //determine the amountOut based on which token has a lower address
        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /**
     * @notice internal function for exact-out swap on uniswap (specify exact amount to receive)
     * @param _amountOut amount of token to receive
     * @param _recipient recipient for receive
     * @param _sqrtPriceLimitX96 price limit
     * @return amount of token sold (amountIn)
     */
    function _exactOutputInternal(
        uint256 _amountOut,
        address _recipient,
        uint160 _sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256) {
        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        //uniswap token0 has a lower address than token1
        //if tokenIn<tokenOut, we are buying an exact amount of token1 in exchange for token0
        //zeroForOne determines which token is being sold and which is being bought
        bool zeroForOne = tokenIn < tokenOut;

        //swap on uniswap, including data to trigger call back for flashswap
        (int256 amount0Delta, int256 amount1Delta) = _getPool(tokenIn, tokenOut, fee).swap(
            _recipient,
            zeroForOne,
            -_amountOut.toInt256(),
            _sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : _sqrtPriceLimitX96,
            abi.encode(data)
        );

        //determine the amountIn and amountOut based on which token has a lower address
        (uint256 amountIn, uint256 amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (_sqrtPriceLimitX96 == 0) require(amountOutReceived == _amountOut);

        return amountIn;
    }

    /**
     * @notice returns the uniswap pool for the given token pair and fee
     * @dev the pool contract may or may not exist
     * @param tokenA address of first token
     * @param tokenB address of second token
     * @param fee fee tier for pool
     */
    function _getPool(address tokenA, address tokenB, uint24 fee)
        internal
        view
        returns (IUniswapV3Pool)
    {
        return IUniswapV3Pool(
            PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee))
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// interface
import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";
import { IZenBullStrategy } from "./interface/IZenBullStrategy.sol";
import { IOracle } from "./interface/IOracle.sol";
import { IEulerSimpleLens } from "./interface/IEulerSimpleLens.sol";

library NettingLib {
    event TransferWethFromMarketMakers(
        address indexed trader,
        uint256 quantity,
        uint256 wethAmount,
        uint256 remainingOsqthBalance,
        uint256 clearingPrice
    );
    event TransferOsqthToMarketMakers(
        address indexed trader, uint256 bidId, uint256 quantity, uint256 remainingOsqthBalance
    );
    event TransferOsqthFromMarketMakers(
        address indexed trader, uint256 quantity, uint256 oSqthRemaining
    );
    event TransferWethToMarketMaker(
        address indexed trader,
        uint256 bidId,
        uint256 quantity,
        uint256 wethAmount,
        uint256 oSqthRemaining,
        uint256 clearingPrice
    );

    /**
     * @notice transfer WETH from market maker to netting contract
     * @dev this is executed during the deposit auction, MM buying OSQTH for WETH
     * @param _weth WETH address
     * @param _trader market maker address
     * @param _quantity oSQTH quantity
     * @param _oSqthToMint remaining amount of the total oSqthToMint
     * @param _clearingPrice auction clearing price
     */
    function transferWethFromMarketMakers(
        address _weth,
        address _trader,
        uint256 _quantity,
        uint256 _oSqthToMint,
        uint256 _clearingPrice
    ) external returns (bool, uint256) {
        uint256 wethAmount;
        uint256 remainingOsqthToMint;
        if (_quantity >= _oSqthToMint) {
            wethAmount = (_oSqthToMint * _clearingPrice) / 1e18;
            IERC20(_weth).transferFrom(_trader, address(this), wethAmount);

            emit TransferWethFromMarketMakers(
                _trader, _oSqthToMint, wethAmount, remainingOsqthToMint, _clearingPrice
                );
            return (true, remainingOsqthToMint);
        } else {
            wethAmount = (_quantity * _clearingPrice) / 1e18;
            remainingOsqthToMint = _oSqthToMint - _quantity;
            IERC20(_weth).transferFrom(_trader, address(this), wethAmount);

            emit TransferWethFromMarketMakers(
                _trader, _quantity, wethAmount, remainingOsqthToMint, _clearingPrice
                );
            return (false, remainingOsqthToMint);
        }
    }

    /**
     * @notice transfer oSQTH to market maker
     * @dev this is executed during the deposit auction, MM buying OSQTH for WETH
     * @param _oSqth oSQTH address
     * @param _trader market maker address
     * @param _bidId MM's bid ID
     * @param _oSqthBalance remaining netting contracts's oSQTH balance
     * @param _quantity oSQTH quantity in market maker order
     */
    function transferOsqthToMarketMakers(
        address _oSqth,
        address _trader,
        uint256 _bidId,
        uint256 _oSqthBalance,
        uint256 _quantity
    ) external returns (bool, uint256) {
        uint256 remainingOsqthBalance;
        if (_quantity < _oSqthBalance) {
            IERC20(_oSqth).transfer(_trader, _quantity);

            remainingOsqthBalance = _oSqthBalance - _quantity;

            emit TransferOsqthToMarketMakers(_trader, _bidId, _quantity, remainingOsqthBalance);

            return (false, remainingOsqthBalance);
        } else {
            IERC20(_oSqth).transfer(_trader, _oSqthBalance);

            emit TransferOsqthToMarketMakers(_trader, _bidId, _oSqthBalance, remainingOsqthBalance);

            return (true, remainingOsqthBalance);
        }
    }

    /**
     * @notice transfer oSQTH from market maker
     * @dev this is executed during the withdraw auction, MM selling OSQTH for WETH
     * @param _oSqth oSQTH address
     * @param _trader market maker address
     * @param _remainingOsqthToPull remaining amount of oSQTH from the total oSQTH amount to transfer from order array
     * @param _quantity oSQTH quantity in market maker order
     */
    function transferOsqthFromMarketMakers(
        address _oSqth,
        address _trader,
        uint256 _remainingOsqthToPull,
        uint256 _quantity
    ) internal returns (uint256) {
        uint256 oSqthRemaining;
        if (_quantity < _remainingOsqthToPull) {
            IERC20(_oSqth).transferFrom(_trader, address(this), _quantity);

            oSqthRemaining = _remainingOsqthToPull - _quantity;

            emit TransferOsqthFromMarketMakers(_trader, _quantity, oSqthRemaining);
        } else {
            IERC20(_oSqth).transferFrom(_trader, address(this), _remainingOsqthToPull);

            emit TransferOsqthFromMarketMakers(_trader, _remainingOsqthToPull, oSqthRemaining);
        }

        return oSqthRemaining;
    }

    /**
     * @notice transfer WETH to market maker
     * @dev this is executed during the withdraw auction, MM selling OSQTH for WETH
     * @param _weth WETH address
     * @param _trader market maker address
     * @param _bidId market maker bid ID
     * @param _remainingOsqthToPull total oSQTH to get from orders array
     * @param _quantity market maker's oSQTH order quantity
     * @param _clearingPrice auction clearing price
     */
    function transferWethToMarketMaker(
        address _weth,
        address _trader,
        uint256 _bidId,
        uint256 _remainingOsqthToPull,
        uint256 _quantity,
        uint256 _clearingPrice
    ) external returns (uint256) {
        uint256 oSqthQuantity;

        if (_quantity < _remainingOsqthToPull) {
            oSqthQuantity = _quantity;
        } else {
            oSqthQuantity = _remainingOsqthToPull;
        }

        uint256 wethAmount = (oSqthQuantity * _clearingPrice) / 1e18;
        _remainingOsqthToPull -= oSqthQuantity;
        IERC20(_weth).transfer(_trader, wethAmount);

        emit TransferWethToMarketMaker(
            _trader, _bidId, _quantity, wethAmount, _remainingOsqthToPull, _clearingPrice
            );

        return _remainingOsqthToPull;
    }

    /**
     * @notice get _crab token price
     * @param _oracle oracle address
     * @param _crab crab token address
     * @param _ethUsdcPool ETH/USDC Uni v3 pool address
     * @param _ethSqueethPool ETH/oSQTH Uni v3 pool address
     * @param _oSqth oSQTH address
     * @param _usdc USDC address
     * @param _weth WETH address
     * @param _zenBull ZenBull strategy address
     * @param _auctionTwapPeriod auction TWAP
     */
    function getCrabPrice(
        address _oracle,
        address _crab,
        address _ethUsdcPool,
        address _ethSqueethPool,
        address _oSqth,
        address _usdc,
        address _weth,
        address _zenBull,
        uint32 _auctionTwapPeriod
    ) external view returns (uint256, uint256) {
        uint256 squeethEthPrice =
            IOracle(_oracle).getTwap(_ethSqueethPool, _oSqth, _weth, _auctionTwapPeriod, false);
        uint256 _ethUsdcPrice =
            IOracle(_oracle).getTwap(_ethUsdcPool, _weth, _usdc, _auctionTwapPeriod, false);
        (uint256 crabCollateral, uint256 crabDebt) =
            IZenBullStrategy(_zenBull).getCrabVaultDetails();
        uint256 _crabFairPriceInEth = (crabCollateral - (crabDebt * squeethEthPrice / 1e18)) * 1e18
            / IERC20(_crab).totalSupply();

        return (_crabFairPriceInEth, _ethUsdcPrice);
    }

    /**
     * @notice get ZenBull token price
     * @param _zenBull ZenBull token address
     * @param _eulerLens EulerSimpleLens contract address
     * @param _usdc USDC address
     * @param _weth WETH address
     * @param _crabFairPriceInEth Crab token price
     * @param _ethUsdcPrice ETH/USDC price
     */
    function getZenBullPrice(
        address _zenBull,
        address _eulerLens,
        address _usdc,
        address _weth,
        uint256 _crabFairPriceInEth,
        uint256 _ethUsdcPrice
    ) external view returns (uint256) {
        uint256 zenBullCrabBalance = IZenBullStrategy(_zenBull).getCrabBalance();
        return (
            IEulerSimpleLens(_eulerLens).getETokenBalance(_weth, _zenBull)
                + (zenBullCrabBalance * _crabFairPriceInEth / 1e18)
                - (
                    (IEulerSimpleLens(_eulerLens).getDTokenBalance(_usdc, _zenBull) * 1e12 * 1e18)
                        / _ethUsdcPrice
                )
        ) * 1e18 / IERC20(_zenBull).totalSupply();
    }

    /**
     * @notice calculate oSQTH to mint and amount of eth to deposit into Crab v2 based on amount of crab token
     * @param _crab crab strategy address
     * @param _zenBull ZenBull strategy address
     * @param _crabAmount amount of crab token
     */
    function calcOsqthToMintAndEthIntoCrab(address _crab, address _zenBull, uint256 _crabAmount)
        external
        view
        returns (uint256, uint256)
    {
        uint256 crabTotalSupply = IERC20(_crab).totalSupply();
        (uint256 crabEth, uint256 crabDebt) = IZenBullStrategy(_zenBull).getCrabVaultDetails();
        uint256 _oSqthToMint = _crabAmount * crabDebt / crabTotalSupply;
        uint256 ethIntoCrab = _crabAmount * crabEth / crabTotalSupply;

        return (_oSqthToMint, ethIntoCrab);
    }

    /**
     * @notice calculate amount of WETH to lend in and USDC to borrow from Euler
     * @param _eulerLens EulerSimpleLens contract address
     * @param _zenBull ZenBull strategy address
     * @param _weth WETH address
     * @param _usdc USDC address
     * @param _crabAmount amount of crab token
     */
    function calcWethToLendAndUsdcToBorrow(
        address _eulerLens,
        address _zenBull,
        address _weth,
        address _usdc,
        uint256 _crabAmount
    ) external view returns (uint256, uint256) {
        uint256 share =
            div(_crabAmount, (IZenBullStrategy(_zenBull).getCrabBalance() + _crabAmount));
        uint256 wethToLend = div(
            mul(IEulerSimpleLens(_eulerLens).getETokenBalance(_weth, _zenBull), share), 1e18 - share
        );
        uint256 usdcToBorrow = div(
            mul(IEulerSimpleLens(_eulerLens).getDTokenBalance(_usdc, _zenBull), share), 1e18 - share
        );

        return (wethToLend, usdcToBorrow);
    }

    /**
     * @notice calculate amount of oSQTH to get based on amount of ZenBull to Withdraw
     * @param _zenBull ZenBull strategy address
     * @param _crab crab strategy address
     * @param _withdrawsToProcess amount of ZenBull token to withdraw
     */
    function calcOsqthAmount(address _zenBull, address _crab, uint256 _withdrawsToProcess)
        external
        view
        returns (uint256)
    {
        uint256 bullTotalSupply = IERC20(_zenBull).totalSupply();
        (, uint256 crabDebt) = IZenBullStrategy(_zenBull).getCrabVaultDetails();
        uint256 share = div(_withdrawsToProcess, bullTotalSupply);
        uint256 _crabAmount = mul(share, IZenBullStrategy(_zenBull).getCrabBalance());

        return div(mul(_crabAmount, crabDebt), IERC20(_crab).totalSupply());
    }

    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // add(mul(_x, _y), WAD / 2) / WAD;
        return ((_x * _y) + (1e18 / 2)) / 1e18;
    }

    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // add(mul(_x, WAD), _y / 2) / _y;
        return ((_x * 1e18) + (_y / 2)) / _y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
pragma abicoder v2;

// interface
import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";
import { IZenBullStrategy } from "./interface/IZenBullStrategy.sol";
import { IController } from "./interface/IController.sol";
import { IOracle } from "./interface/IOracle.sol";
import { IEulerSimpleLens } from "./interface/IEulerSimpleLens.sol";
import { IWETH } from "./interface/IWETH.sol";
import { ICrabStrategyV2 } from "./interface/ICrabStrategyV2.sol";
import { IFlashZen } from "./interface/IFlashZen.sol";
// contract
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { EIP712 } from "openzeppelin/utils/cryptography/draft-EIP712.sol";
import { ECDSA } from "openzeppelin/utils/cryptography/ECDSA.sol";
import { FlashSwap } from "./FlashSwap.sol";
// lib
import { Address } from "openzeppelin/utils/Address.sol";
import { NettingLib } from "./NettingLib.sol";

/**
 * Error codes
 * ZBN01: Auction TWAP is less than min value
 * ZBN02: OTC price tolerance is greater than max OTC tolerance price
 * ZBN03: Amount to queue for deposit is less than min amount
 * ZBN04: Can not dequeue deposited amount because auction is already live and force dequeued not activated
 * ZBN05: Amount of ETH to deposit left in the queue is less than min amount
 * ZBN06: Queued deposit is not longer than 1 week to force dequeue
 * ZBN07: Amount of ZenBull to queue for withdraw is less than min amount
 * ZBN08: Amount of ZenBull to withdraw left in the queue is less than min amount
 * ZBN09: Queued withdraw is not longer than 1 week to force dequeue
 * ZBN10: ETH quantity to net is less than queued for deposits
 * ZBN11: ZenBull quantity to net is less than queued for withdraws
 * ZBN12: ZenBull Price too high
 * ZBN13: ZenBull Price too low
 * ZBN14: Clearing price too high relative to Uniswap twap
 * ZBN15: Clearing price too low relative to Uniswap twap
 * ZBN16: Invalid order signer
 * ZBN17: Order already expired
 * ZBN18: Nonce already used
 * ZBN19: auction order is not selling
 * ZBN20: sell order price greater than clearing
 * ZBN21: auction order is not buying
 * ZBN22: buy order price greater than clearing
 * ZBN23: not enough buy orders for sqth
 * ZBN24: not authorized to perform netting at price
 */

/**
 * @dev ZenBullNetting contract
 * @notice Contract for Netting Deposits and Withdrawals in ZenBull
 * @author Opyn team
 */
contract ZenBullNetting is Ownable, EIP712, FlashSwap {
    using Address for address payable;

    /// @dev typehash for signed orders
    bytes32 private constant _ZENBULL_NETTING_TYPEHASH = keccak256(
        "Order(uint256 bidId,address trader,uint256 quantity,uint256 price,bool isBuying,uint256 expiry,uint256 nonce)"
    );
    /// @dev OTC price tolerance cannot exceed 20%
    uint256 public constant MAX_OTC_PRICE_TOLERANCE = 2e17; // 20%
    /// @dev min auction TWAP
    uint32 public constant MIN_AUCTION_TWAP = 180 seconds;

    /// @dev owner sets to true when starting auction
    bool public isAuctionLive;

    /// @dev min ETH amounts to withdraw or deposit via netting
    uint256 public minEthAmount;
    /// @dev min ZenBull amounts to withdraw or deposit via netting
    uint256 public minZenBullAmount;
    /// @dev array index of last processed deposits
    uint256 public depositsIndex;
    /// @dev array index of last processed withdraws
    uint256 public withdrawsIndex;
    // @dev OTC price must be within this distance of the uniswap twap price
    uint256 public otcPriceTolerance;
    /// @dev twap period to use for auction calculations
    uint32 public auctionTwapPeriod;

    /// @dev WETH token address
    address private immutable weth;
    /// @dev oSQTH token address
    address private immutable oSqth;
    /// @dev USDC token address
    address private immutable usdc;
    /// @dev ZenBull token address
    address private immutable zenBull;
    /// @dev WPowerPerp Oracle address
    address private immutable oracle;
    /// @dev ETH/oSQTH uniswap v3 pool address
    address private immutable ethSqueethPool;
    /// @dev ETH/USDC uniswap v3 pool address
    address private immutable ethUsdcPool;
    /// @dev Euler Simple Lens contract address
    address private immutable eulerLens;
    /// @dev crab strategy contract address
    address private immutable crab;
    /// @dev FlashZen contract address
    address private immutable flashZenBull;

    /// @dev bot address to automate netAtPrice() calls
    address public bot;

    /// @dev array of ETH deposit receipts
    Receipt[] public deposits;
    /// @dev array of ZenBull withdrawal receipts
    Receipt[] public withdraws;

    /// @dev ETH amount to deposit for an address
    mapping(address => uint256) public ethBalance;
    /// @dev ZenBull amount to withdraw for an address
    mapping(address => uint256) public zenBullBalance;
    /// @dev indexes of deposit receipts of an address
    mapping(address => uint256[]) public userDepositsIndex;
    /// @dev indexes of withdraw receipts of an address
    mapping(address => uint256[]) public userWithdrawsIndex;
    /// @dev store the used flag for a nonce for each address
    mapping(address => mapping(uint256 => bool)) public nonces;

    /// @dev order struct for a signed order from market maker
    struct Order {
        uint256 bidId;
        address trader;
        uint256 quantity;
        uint256 price;
        bool isBuying;
        uint256 expiry;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev receipt used to store deposits and withdraws
    struct Receipt {
        /// @dev address of the depositor or withdrawer
        address sender;
        /// @dev ETH amount to queue for deposit or ZenBull amount to queue for withdrawal
        uint256 amount;
        /// @dev time of deposit
        uint256 timestamp;
    }

    struct DepositAuctionParams {
        /// @dev WETH to deposit
        uint256 depositsToProcess;
        /// @dev Crab amount to deposit into ZenBull
        uint256 crabAmount;
        /// @dev orders to buy sqth
        Order[] orders;
        /// @dev price from the auction to sell sqth
        uint256 clearingPrice;
        /// @dev amount to deposit into crab in ZenBull flash deposit
        uint256 flashDepositEthToCrab;
        /// @dev min ETH to get from oSQTH in ZenBull flash deposit
        uint256 flashDepositMinEthFromSqth;
        /// @dev min ETH to get from USDC in ZenBull flash deposit
        uint256 flashDepositMinEthFromUsdc;
        /// @dev uniswap weth/wPowerPerp pool fee ZenBull flash deposit
        uint24 flashDepositWPowerPerpPoolFee;
        /// @dev uniswap fee for swapping eth to USD, and pool fee to use for ZenBull flash deposit
        uint24 wethUsdcPoolFee;
    }

    /// @dev params for withdraw auction
    struct WithdrawAuctionParams {
        /// @dev amont of bull to queue for withdrawal
        uint256 withdrawsToProcess;
        /// @dev orders that sell oSqth to the auction
        Order[] orders;
        /// @dev price that the auction pays for the purchased oSqth
        uint256 clearingPrice;
        /// @dev max WETH to pay for flashswapped USDC
        uint256 maxWethForUsdc;
        /// @dev uniswap fee for swapping eth to USD;
        uint24 wethUsdcPoolFee;
    }

    /// @dev struct to store proportional amounts of erc20s (received or to send)
    struct MemoryVar {
        uint256 currentZenBullBalance;
        uint256 remainingEth;
        uint256 remainingDeposits;
        uint256 oSqthBalance;
    }

    event SetMinZenBullAmount(uint256 oldAmount, uint256 newAmount);
    event SetMinEthAmount(uint256 oldAmount, uint256 newAmount);
    event SetDepositsIndex(uint256 oldDepositsIndex, uint256 newDepositsIndex);
    event SetWithdrawsIndex(uint256 oldWithdrawsIndex, uint256 newWithdrawsIndex);
    event SetAuctionTwapPeriod(uint32 previousTwap, uint32 newTwap);
    event SetOTCPriceTolerance(uint256 previousTolerance, uint256 newOtcPriceTolerance);
    event ToggledAuctionLive(bool isAuctionLive);
    event QueueEth(
        address indexed depositor,
        uint256 amount,
        uint256 depositorsBalance,
        uint256 indexed receiptIndex
    );
    event DequeueEth(address indexed depositor, uint256 amount, uint256 depositorsBalance);
    event QueueZenBull(
        address indexed withdrawer,
        uint256 amount,
        uint256 withdrawersBalance,
        uint256 indexed receiptIndex
    );
    event DequeueZenBull(address indexed withdrawer, uint256 amount, uint256 withdrawersBalance);
    event NetAtPrice(
        bool indexed isDeposit,
        address indexed receiver,
        uint256 amountQueuedProcessed,
        uint256 amountReceived,
        uint256 indexed index
    );
    event EthDeposited(
        address indexed depositor,
        uint256 ethAmount,
        uint256 zenBullAmount,
        uint256 indexed receiptIndex,
        uint256 refundedETH
    );
    event ZenBullWithdrawn(
        address indexed withdrawer,
        uint256 zenBullAmount,
        uint256 ethAmount,
        uint256 indexed receiptIndex
    );
    event SetBot(address bot);
    event DepositAuction(
        uint256 wethDeposited,
        uint256 crabAmount,
        uint256 clearingPrice,
        uint256 oSqthAmount,
        uint256 depositsIndex
    );
    event WithdrawAuction(
        uint256 zenBullWithdrawn, uint256 clearingPrice, uint256 oSqthAmount, uint256 withdrawsIndex
    );
    event CancelNonce(address trader, uint256 nonce);
    /// @dev shared events with the NettingLib for client side to detect them
    event TransferWethFromMarketMakers(
        address indexed trader, uint256 quantity, uint256 wethAmount, uint256 clearingPrice
    );
    event TransferOsqthToMarketMakers(
        address indexed trader, uint256 bidId, uint256 quantity, uint256 remainingOsqthBalance
    );
    event TransferOsqthFromMarketMakers(
        address indexed trader, uint256 quantity, uint256 oSqthRemaining
    );
    event TransferWethToMarketMaker(
        address indexed trader,
        uint256 bidId,
        uint256 quantity,
        uint256 wethAmount,
        uint256 oSqthRemaining,
        uint256 clearingPrice
    );

    constructor(
        address _zenBull,
        address _eulerSimpleLens,
        address _flashZenBull,
        address _uniFactory
    ) EIP712("ZenBullNetting", "1") FlashSwap(_uniFactory) {
        otcPriceTolerance = 5e16; // 5%
        auctionTwapPeriod = 420 seconds;

        zenBull = _zenBull;
        eulerLens = _eulerSimpleLens;
        weth = IController(IZenBullStrategy(_zenBull).powerTokenController()).weth();
        oracle = IController(IZenBullStrategy(_zenBull).powerTokenController()).oracle();
        ethSqueethPool =
            IController(IZenBullStrategy(_zenBull).powerTokenController()).wPowerPerpPool();
        ethUsdcPool =
            IController(IZenBullStrategy(_zenBull).powerTokenController()).ethQuoteCurrencyPool();
        usdc = IController(IZenBullStrategy(_zenBull).powerTokenController()).quoteCurrency();
        oSqth = IController(IZenBullStrategy(_zenBull).powerTokenController()).wPowerPerp();
        crab = IZenBullStrategy(zenBull).crab();
        flashZenBull = _flashZenBull;

        IERC20(usdc).approve(_zenBull, type(uint256).max);
        IERC20(oSqth).approve(_zenBull, type(uint256).max);
        IERC20(crab).approve(_zenBull, type(uint256).max);
    }

    /**
     * @notice receive function to allow ETH transfer to this contract
     */
    receive() external payable {
        if ((msg.sender != weth) && (msg.sender != zenBull) && (msg.sender != flashZenBull)) {
            _queueEth();
        }
    }

    /**
     * @dev view function to get the domain seperator used in signing
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev toggles the value of isAuctionLive
     */
    function toggleAuctionLive() external onlyOwner {
        isAuctionLive = !isAuctionLive;
        emit ToggledAuctionLive(isAuctionLive);
    }

    /**
     * @notice set min ETH amount
     * @param _amount the amount to be set as minEthAmount
     */
    function setMinEthAmount(uint256 _amount) external onlyOwner {
        emit SetMinEthAmount(minEthAmount, _amount);
        minEthAmount = _amount;
    }

    /**
     * @notice set minZenBullAmount
     * @param _amount the number to be set as minZenBullAmount
     */
    function setMinZenBullAmount(uint256 _amount) external onlyOwner {
        emit SetMinZenBullAmount(minZenBullAmount, _amount);

        minZenBullAmount = _amount;
    }

    /**
     * @notice set the depositIndex so that we want to skip processing some deposits
     * @param _newDepositsIndex the new deposits index
     */
    function setDepositsIndex(uint256 _newDepositsIndex) external onlyOwner {
        emit SetDepositsIndex(depositsIndex, _newDepositsIndex);

        depositsIndex = _newDepositsIndex;
    }

    /**
     * @notice set the withdraw index so that we want to skip processing some withdraws
     * @param _newWithdrawsIndex the new withdraw index
     */
    function setWithdrawsIndex(uint256 _newWithdrawsIndex) external onlyOwner {
        emit SetWithdrawsIndex(withdrawsIndex, _newWithdrawsIndex);

        withdrawsIndex = _newWithdrawsIndex;
    }

    /**
     * @notice owner can set the twap period in seconds that is used for obtaining TWAP prices
     * @param _auctionTwapPeriod the twap period, in seconds
     */
    function setAuctionTwapPeriod(uint32 _auctionTwapPeriod) external onlyOwner {
        require(_auctionTwapPeriod >= MIN_AUCTION_TWAP, "ZBN01");

        emit SetAuctionTwapPeriod(auctionTwapPeriod, _auctionTwapPeriod);

        auctionTwapPeriod = _auctionTwapPeriod;
    }

    /**
     * @notice owner can set a threshold, scaled by 1e18 that determines the maximum discount of a clearing sale price to the current uniswap twap price
     * @param _otcPriceTolerance the OTC price tolerance, in percent, scaled by 1e18
     */
    function setOTCPriceTolerance(uint256 _otcPriceTolerance) external onlyOwner {
        // Tolerance cannot be more than 20%
        require(_otcPriceTolerance <= MAX_OTC_PRICE_TOLERANCE, "ZBN02");

        emit SetOTCPriceTolerance(otcPriceTolerance, _otcPriceTolerance);

        otcPriceTolerance = _otcPriceTolerance;
    }

    /**
     * @notice set bot address
     * @param _bot bot address
     */
    function setBot(address _bot) external onlyOwner {
        bot = _bot;

        emit SetBot(_bot);
    }

    /**
     * @dev cancel nonce by marking it as used
     * @param _nonce nonce to cancel
     */
    function cancelNonce(uint256 _nonce) external {
        nonces[msg.sender][_nonce] = true;

        emit CancelNonce(msg.sender, _nonce);
    }

    /**
     * @notice queue ETH for deposit into ZenBull
     * @dev payable function
     */
    function queueEth() external payable {
        _queueEth();
    }

    /**
     * @notice withdraw ETH from queue
     * @param _amount ETH amount to dequeue
     * @param _force forceWithdraw if deposited more than a week ago
     */
    function dequeueEth(uint256 _amount, bool _force) external {
        require(!isAuctionLive || _force, "ZBN04");

        ethBalance[msg.sender] = ethBalance[msg.sender] - _amount;

        require(ethBalance[msg.sender] >= minEthAmount || ethBalance[msg.sender] == 0, "ZBN05");

        // start withdrawing from the users last deposit
        uint256 toWithdraw = _amount;
        uint256 lastDepositIndex = userDepositsIndex[msg.sender].length;
        for (uint256 i = lastDepositIndex; i > 0; i--) {
            Receipt storage receipt = deposits[userDepositsIndex[msg.sender][i - 1]];

            if (_force) {
                require(block.timestamp > receipt.timestamp + 1 weeks, "ZBN06");
            }
            if (receipt.amount > toWithdraw) {
                receipt.amount -= toWithdraw;
                break;
            } else {
                toWithdraw -= receipt.amount;
                delete deposits[userDepositsIndex[msg.sender][i - 1]];
                userDepositsIndex[msg.sender].pop();
            }
        }

        payable(msg.sender).sendValue(_amount);

        emit DequeueEth(msg.sender, _amount, ethBalance[msg.sender]);
    }

    /**
     * @notice queue ZenBull token for withdraw from strategy
     * @param _amount ZenBull amount to withdraw
     */
    function queueZenBull(uint256 _amount) external {
        require(_amount >= minZenBullAmount, "ZBN07");

        zenBullBalance[msg.sender] = zenBullBalance[msg.sender] + _amount;
        withdraws.push(Receipt(msg.sender, _amount, block.timestamp));
        userWithdrawsIndex[msg.sender].push(withdraws.length - 1);

        IERC20(zenBull).transferFrom(msg.sender, address(this), _amount);

        emit QueueZenBull(msg.sender, _amount, zenBullBalance[msg.sender], withdraws.length - 1);
    }

    /**
     * @notice withdraw ZenBull from queue
     * @param _amount ZenBull amount to dequeue
     * @param _force forceWithdraw if queued more than a week ago
     */
    function dequeueZenBull(uint256 _amount, bool _force) external {
        require(!isAuctionLive || _force, "ZBN04");

        zenBullBalance[msg.sender] = zenBullBalance[msg.sender] - _amount;

        require(
            zenBullBalance[msg.sender] >= minZenBullAmount || zenBullBalance[msg.sender] == 0,
            "ZBN08"
        );

        // deQueue ZenBull from the last, last in first out
        uint256 toRemove = _amount;
        uint256 lastWithdrawIndex = userWithdrawsIndex[msg.sender].length;
        for (uint256 i = lastWithdrawIndex; i > 0; i--) {
            Receipt storage receipt = withdraws[userWithdrawsIndex[msg.sender][i - 1]];
            if (_force) {
                require(block.timestamp > receipt.timestamp + 1 weeks, "ZBN09");
            }
            if (receipt.amount > toRemove) {
                receipt.amount -= toRemove;
                break;
            } else {
                toRemove -= receipt.amount;
                delete withdraws[userWithdrawsIndex[msg.sender][i - 1]];
                userWithdrawsIndex[msg.sender].pop();
            }
        }

        IERC20(zenBull).transfer(msg.sender, _amount);

        emit DequeueZenBull(msg.sender, _amount, zenBullBalance[msg.sender]);
    }

    /**
     * @notice swaps quantity amount of ETH for ZenBull token at ZenBull/ETH price
     * @param _price price of ZenBull in ETH
     * @param _quantity amount of ETH to net
     */
    function netAtPrice(uint256 _price, uint256 _quantity) external {
        require((msg.sender == owner()) || (msg.sender == bot), "ZBN24");

        uint256 zenBullFairPrice = _getZenBullPrice();

        require(_price <= (zenBullFairPrice * (1e18 + otcPriceTolerance)) / 1e18, "ZBN12");
        require(_price >= (zenBullFairPrice * (1e18 - otcPriceTolerance)) / 1e18, "ZBN13");

        uint256 zenBullQuantity = (_quantity * 1e18) / _price;

        require(_quantity <= address(this).balance, "ZBN10");
        require(zenBullQuantity <= IERC20(zenBull).balanceOf(address(this)), "ZBN11");

        // process deposits and send ZenBull
        uint256 i = depositsIndex;
        uint256 amountToSend;
        while (_quantity > 0) {
            Receipt memory deposit = deposits[i];
            if (deposit.amount == 0) {
                i++;
                continue;
            }
            if (deposit.amount <= _quantity) {
                // deposit amount is lesser than quantity use it fully
                _quantity = _quantity - deposit.amount;
                ethBalance[deposit.sender] -= deposit.amount;
                amountToSend = (deposit.amount * 1e18) / _price;
                IERC20(zenBull).transfer(deposit.sender, amountToSend);

                emit NetAtPrice(true, deposit.sender, deposit.amount, amountToSend, i);
                delete deposits[i];
                i++;
            } else {
                // deposit amount is greater than quantity; use it partially
                deposits[i].amount = deposit.amount - _quantity;
                ethBalance[deposit.sender] -= _quantity;
                amountToSend = (_quantity * 1e18) / _price;

                IERC20(zenBull).transfer(deposit.sender, amountToSend);

                emit NetAtPrice(true, deposit.sender, _quantity, amountToSend, i);
                break;
            }
        }
        depositsIndex = i;

        // process withdraws and send usdc
        i = withdrawsIndex;
        while (zenBullQuantity > 0) {
            Receipt memory withdraw = withdraws[i];
            if (withdraw.amount == 0) {
                i++;
                continue;
            }
            if (withdraw.amount <= zenBullQuantity) {
                zenBullQuantity = zenBullQuantity - withdraw.amount;
                zenBullBalance[withdraw.sender] -= withdraw.amount;
                amountToSend = (withdraw.amount * _price) / 1e18;

                payable(withdraw.sender).sendValue(amountToSend);

                emit NetAtPrice(false, withdraw.sender, withdraw.amount, amountToSend, i);

                delete withdraws[i];
                i++;
            } else {
                withdraws[i].amount = withdraw.amount - zenBullQuantity;
                zenBullBalance[withdraw.sender] -= zenBullQuantity;
                amountToSend = (zenBullQuantity * _price) / 1e18;

                payable(withdraw.sender).sendValue(amountToSend);

                emit NetAtPrice(false, withdraw.sender, zenBullQuantity, amountToSend, i);

                break;
            }
        }
        withdrawsIndex = i;
    }

    /**
     * @notice auction for queued deposits
     * @dev takes in orders from MM's to buy oSQTH
     * @param _params deposit Params
     */
    function depositAuction(DepositAuctionParams calldata _params) external onlyOwner {
        _checkOTCPrice(_params.clearingPrice, false);

        uint256 initialZenBullBalance = IERC20(zenBull).balanceOf(address(this));
        uint256 initialEthBalance = address(this).balance;
        (uint256 oSqthToMint, uint256 ethIntoCrab) =
            NettingLib.calcOsqthToMintAndEthIntoCrab(crab, zenBull, _params.crabAmount);

        // get WETH from MM
        for (uint256 i = 0; i < _params.orders.length; i++) {
            require(_params.orders[i].isBuying, "ZBN21");
            require(_params.orders[i].price >= _params.clearingPrice, "ZBN22");

            _checkOrder(_params.orders[i]);
            _useNonce(_params.orders[i].trader, _params.orders[i].nonce);

            bool shouldBreak;
            (shouldBreak, oSqthToMint) = NettingLib.transferWethFromMarketMakers(
                weth,
                _params.orders[i].trader,
                _params.orders[i].quantity,
                oSqthToMint,
                _params.clearingPrice
            );
            if (shouldBreak) break;
        }
        require(oSqthToMint == 0, "ZBN23");

        {
            // deposit into crab
            uint256 wethFromAuction = IWETH(weth).balanceOf(address(this));
            IWETH(weth).withdraw(wethFromAuction);

            ICrabStrategyV2(crab).deposit{value: ethIntoCrab}();

            (uint256 wethToLend, uint256 usdcToBorrow) = NettingLib.calcWethToLendAndUsdcToBorrow(
                eulerLens, zenBull, weth, usdc, IERC20(crab).balanceOf(address(this))
            );

            // flashswap WETH for USDC debt, and deposit crab + wethToLend into ZenBull
            uint256 minWethForUsdcDebt =
                wethToLend - (_params.depositsToProcess + wethFromAuction - ethIntoCrab);
            _exactInFlashSwap(
                usdc,
                weth,
                _params.wethUsdcPoolFee,
                usdcToBorrow,
                minWethForUsdcDebt,
                1,
                abi.encodePacked(wethToLend)
            );
        }

        MemoryVar memory memVar;
        memVar.remainingEth =
            address(this).balance - (initialEthBalance - _params.depositsToProcess);

        {
            if (memVar.remainingEth > 0 && _params.flashDepositEthToCrab > 0) {
                IFlashZen.FlashDepositParams memory params = IFlashZen.FlashDepositParams({
                    ethToCrab: _params.flashDepositEthToCrab,
                    minEthFromSqth: _params.flashDepositMinEthFromSqth,
                    minEthFromUsdc: _params.flashDepositMinEthFromUsdc,
                    wPowerPerpPoolFee: _params.flashDepositWPowerPerpPoolFee,
                    usdcPoolFee: _params.wethUsdcPoolFee
                });

                IFlashZen(flashZenBull).flashDeposit{value: memVar.remainingEth}(params);
            }
        }

        // send oSqth to market makers
        memVar.oSqthBalance = IERC20(oSqth).balanceOf(address(this));
        for (uint256 i = 0; i < _params.orders.length; i++) {
            bool shouldBreak;
            (shouldBreak, memVar.oSqthBalance) = NettingLib.transferOsqthToMarketMakers(
                oSqth,
                _params.orders[i].trader,
                _params.orders[i].bidId,
                memVar.oSqthBalance,
                _params.orders[i].quantity
            );
            if (shouldBreak) break;
        }

        // send ZenBull to depositor
        memVar.remainingDeposits = _params.depositsToProcess;
        uint256 k = depositsIndex;
        memVar.currentZenBullBalance =
            IERC20(zenBull).balanceOf(address(this)) - initialZenBullBalance;
        memVar.remainingEth =
            address(this).balance - (initialEthBalance - _params.depositsToProcess);

        while (memVar.remainingDeposits > 0) {
            Receipt memory depositReceipt = deposits[k];
            if (depositReceipt.amount == 0) {
                k++;
                continue;
            } else {
                uint256 zenBullAmountToSend;
                uint256 ethAmountToSend;
                if (depositReceipt.amount <= memVar.remainingDeposits) {
                    memVar.remainingDeposits = memVar.remainingDeposits - depositReceipt.amount;
                    ethBalance[depositReceipt.sender] -= depositReceipt.amount;

                    zenBullAmountToSend = depositReceipt.amount * memVar.currentZenBullBalance
                        / _params.depositsToProcess;

                    IERC20(zenBull).transfer(deposits[k].sender, zenBullAmountToSend);

                    delete deposits[k];
                    k++;

                    ethAmountToSend =
                        depositReceipt.amount * memVar.remainingEth / _params.depositsToProcess;
                    if (ethAmountToSend > 1e12) {
                        payable(depositReceipt.sender).sendValue(ethAmountToSend);
                    }

                    emit EthDeposited(
                        depositReceipt.sender,
                        depositReceipt.amount,
                        zenBullAmountToSend,
                        k,
                        ethAmountToSend
                        );
                } else {
                    ethBalance[depositReceipt.sender] -= memVar.remainingDeposits;

                    zenBullAmountToSend = memVar.remainingDeposits * memVar.currentZenBullBalance
                        / _params.depositsToProcess;
                    IERC20(zenBull).transfer(depositReceipt.sender, zenBullAmountToSend);

                    deposits[k].amount -= memVar.remainingDeposits;

                    ethAmountToSend =
                        memVar.remainingDeposits * memVar.remainingEth / _params.depositsToProcess;

                    if (ethAmountToSend > 1e12) {
                        payable(depositReceipt.sender).sendValue(ethAmountToSend);
                    }

                    emit EthDeposited(
                        depositReceipt.sender,
                        memVar.remainingDeposits,
                        zenBullAmountToSend,
                        k,
                        ethAmountToSend
                        );
                    break;
                }
            }
        }
        depositsIndex = k;
        isAuctionLive = false;

        emit DepositAuction(
            _params.depositsToProcess,
            _params.crabAmount,
            _params.clearingPrice,
            memVar.oSqthBalance,
            k
            );
    }

    /**
     * @notice auction for queued withdraws
     * @dev takes in orders from MM's to sell oSQTH
     * @param _params withdraw Params
     */
    function withdrawAuction(WithdrawAuctionParams calldata _params) external onlyOwner {
        _checkOTCPrice(_params.clearingPrice, true);

        uint256 initialEthBalance = address(this).balance;
        uint256 oSqthAmount = NettingLib.calcOsqthAmount(zenBull, crab, _params.withdrawsToProcess);

        // get oSQTH from market makers orders
        uint256 toExchange = oSqthAmount;
        for (uint256 i = 0; i < _params.orders.length && toExchange > 0; i++) {
            _checkOrder(_params.orders[i]);
            _useNonce(_params.orders[i].trader, _params.orders[i].nonce);

            require(!_params.orders[i].isBuying, "ZBN19");
            require(_params.orders[i].price <= _params.clearingPrice, "ZBN20");

            toExchange = NettingLib.transferOsqthFromMarketMakers(
                oSqth, _params.orders[i].trader, toExchange, _params.orders[i].quantity
            );
        }

        uint256 usdcToRepay = NettingLib.mul(
            NettingLib.div(_params.withdrawsToProcess, IERC20(zenBull).totalSupply()),
            IEulerSimpleLens(eulerLens).getDTokenBalance(usdc, zenBull)
        );

        // WETH-USDC swap
        _exactOutFlashSwap(
            weth,
            usdc,
            _params.wethUsdcPoolFee,
            usdcToRepay,
            _params.maxWethForUsdc,
            0,
            abi.encodePacked(_params.withdrawsToProcess)
        );

        // send WETH to market makers
        IWETH(weth).deposit{value: address(this).balance - initialEthBalance}();
        toExchange = oSqthAmount;
        for (uint256 i = 0; i < _params.orders.length && toExchange > 0; i++) {
            toExchange = NettingLib.transferWethToMarketMaker(
                weth,
                _params.orders[i].trader,
                _params.orders[i].bidId,
                toExchange,
                _params.orders[i].quantity,
                _params.clearingPrice
            );
        }

        // send ETH to withdrawers
        uint256 ethToWithdrawers = IWETH(weth).balanceOf(address(this));
        IWETH(weth).withdraw(ethToWithdrawers);

        uint256 remainingWithdraws = _params.withdrawsToProcess;
        uint256 j = withdrawsIndex;
        uint256 ethAmount;

        while (remainingWithdraws > 0) {
            Receipt memory withdraw = withdraws[j];
            if (withdraw.amount == 0) {
                j++;
                continue;
            }
            if (withdraw.amount <= remainingWithdraws) {
                // full usage
                remainingWithdraws -= withdraw.amount;
                zenBullBalance[withdraw.sender] -= withdraw.amount;

                // send proportional usdc
                ethAmount = withdraw.amount * ethToWithdrawers / _params.withdrawsToProcess;

                delete withdraws[j];
                j++;

                payable(withdraw.sender).sendValue(ethAmount);

                emit ZenBullWithdrawn(withdraw.sender, withdraw.amount, ethAmount, j);
            } else {
                withdraws[j].amount -= remainingWithdraws;
                zenBullBalance[withdraw.sender] -= remainingWithdraws;

                // send proportional usdc
                ethAmount = remainingWithdraws * ethToWithdrawers / _params.withdrawsToProcess;

                payable(withdraw.sender).sendValue(ethAmount);

                emit ZenBullWithdrawn(withdraw.sender, remainingWithdraws, ethAmount, j);

                break;
            }
        }

        withdrawsIndex = j;
        isAuctionLive = false;

        emit WithdrawAuction(_params.withdrawsToProcess, _params.clearingPrice, oSqthAmount, j);
    }

    /**
     * @dev to handle uniswap flashswap callback
     */
    function _uniFlashSwap(
        address pool,
        uint256 amountToPay,
        bytes memory callData,
        uint8 callSource
    ) internal override {
        if (callSource == 0) {
            uint256 zenBullAmountToBurn = abi.decode(callData, (uint256));

            IZenBullStrategy(zenBull).withdraw(zenBullAmountToBurn);
            IWETH(weth).deposit{value: amountToPay}();
            IWETH(weth).transfer(pool, amountToPay);
        } else if (callSource == 1) {
            uint256 wethToLend = abi.decode(callData, (uint256));

            IWETH(weth).withdraw(IWETH(weth).balanceOf(address(this)));
            IZenBullStrategy(zenBull).deposit{value: wethToLend}(
                IERC20(crab).balanceOf(address(this))
            );
            IERC20(usdc).transfer(pool, amountToPay);
        }
    }

    /**
     * @dev queue ETH for deposit into ZenBull
     */
    function _queueEth() internal {
        require(msg.value >= minEthAmount, "ZBN03");

        // update eth balance of user, add their receipt, and receipt index to user deposits index
        ethBalance[msg.sender] = ethBalance[msg.sender] + msg.value;
        deposits.push(Receipt(msg.sender, msg.value, block.timestamp));
        userDepositsIndex[msg.sender].push(deposits.length - 1);

        emit QueueEth(msg.sender, msg.value, ethBalance[msg.sender], deposits.length - 1);
    }

    /**
     * @notice get the sum of queued ETH
     * @return sum ETH amount in queue
     */
    function depositsQueued() external view returns (uint256) {
        uint256 j = depositsIndex;
        uint256 sum;
        while (j < deposits.length) {
            sum = sum + deposits[j].amount;
            j++;
        }
        return sum;
    }

    /**
     * @notice get a deposit receipt by index
     * @param _index deposit index in deposits array
     * @return receipt sender, amount and timestamp
     */
    function getDepositReceipt(uint256 _index) external view returns (address, uint256, uint256) {
        Receipt memory receipt = deposits[_index];

        return (receipt.sender, receipt.amount, receipt.timestamp);
    }

    /**
     * @notice get the sum of queued ZenBull
     * @return sum ZenBull amount in queue
     */
    function withdrawsQueued() external view returns (uint256) {
        uint256 j = withdrawsIndex;
        uint256 sum;
        while (j < withdraws.length) {
            sum = sum + withdraws[j].amount;
            j++;
        }
        return sum;
    }

    /**
     * @notice get a withdraw receipt by index
     * @param _index withdraw index in withdraws array
     * @return receipt sender, amount and timestamp
     */
    function getWithdrawReceipt(uint256 _index) external view returns (address, uint256, uint256) {
        Receipt memory receipt = withdraws[_index];

        return (receipt.sender, receipt.amount, receipt.timestamp);
    }

    /**
     * @notice checks the expiry nonce and signer of an order
     * @param _order Order struct
     */
    function checkOrder(Order memory _order) external view returns (bool) {
        return _checkOrder(_order);
    }

    /**
     * @dev set nonce flag of the trader to true
     * @param _trader address of the signer
     * @param _nonce number that is to be traded only once
     */
    function _useNonce(address _trader, uint256 _nonce) internal {
        require(!nonces[_trader][_nonce], "ZBN18");

        nonces[_trader][_nonce] = true;
    }

    /**
     * @dev get ZenBull token price using uniswap TWAP
     * @return ZenBull price
     */
    function _getZenBullPrice() internal view returns (uint256) {
        (uint256 crabFairPriceInEth, uint256 ethUsdcPrice) = NettingLib.getCrabPrice(
            oracle, crab, ethUsdcPool, ethSqueethPool, oSqth, usdc, weth, zenBull, auctionTwapPeriod
        );

        return NettingLib.getZenBullPrice(
            zenBull, eulerLens, usdc, weth, crabFairPriceInEth, ethUsdcPrice
        );
    }

    /**
     * @notice check that the proposed sale price is within a tolerance of the current Uniswap twap
     * @param _price clearing price provided by manager
     * @param _isAuctionBuying is auction buying or selling oSQTH
     */
    function _checkOTCPrice(uint256 _price, bool _isAuctionBuying) internal view {
        // Get twap
        uint256 squeethEthPrice =
            IOracle(oracle).getTwap(ethSqueethPool, oSqth, weth, auctionTwapPeriod, false);

        if (_isAuctionBuying) {
            require(_price <= (squeethEthPrice * (1e18 + otcPriceTolerance)) / 1e18, "ZBN14");
        } else {
            require(_price >= (squeethEthPrice * (1e18 - otcPriceTolerance)) / 1e18, "ZBN15");
        }
    }

    /**
     * @dev checks the expiry nonce and signer of an order
     * @param _order Order struct
     */
    function _checkOrder(Order memory _order) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                _ZENBULL_NETTING_TYPEHASH,
                _order.bidId,
                _order.trader,
                _order.quantity,
                _order.price,
                _order.isBuying,
                _order.expiry,
                _order.nonce
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address offerSigner = ECDSA.recover(hash, _order.v, _order.r, _order.s);
        require(offerSigner == _order.trader, "ZBN16");
        require(_order.expiry >= block.timestamp, "ZBN17");

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IController {
    function weth() external view returns (address);
    function quoteCurrency() external view returns (address);
    function ethQuoteCurrencyPool() external view returns (address);
    function wPowerPerp() external view returns (address);
    function wPowerPerpPool() external view returns (address);
    function oracle() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";

interface ICrabStrategyV2 is IERC20 {
    function getVaultDetails() external view returns (address, uint256, uint256, uint256);

    function deposit() external payable;

    function withdraw(uint256 _crabAmount) external;

    function flashDeposit(uint256 _ethToDeposit, uint24 _poolFee) external payable;

    function getWsqueethFromCrabAmount(uint256 _crabAmount) external view returns (uint256);

    function powerTokenController() external view returns (address);

    function weth() external view returns (address);

    function wPowerPerp() external view returns (address);

    function oracle() external view returns (address);

    function ethWSqueethPool() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IEulerSimpleLens {
    function getDTokenBalance(address underlying, address account)
        external
        view
        returns (uint256);
    function getETokenBalance(address underlying, address account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFlashZen {
    struct FlashDepositParams {
        uint256 ethToCrab;
        uint256 minEthFromSqth;
        uint256 minEthFromUsdc;
        uint24 wPowerPerpPoolFee;
        uint24 usdcPoolFee;
    }

    function flashDeposit(FlashDepositParams calldata _params) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOracle {
    function getTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";

interface IZenBullStrategy is IERC20 {
    function powerTokenController() external view returns (address);
    function getCrabBalance() external view returns (uint256);
    function getCrabVaultDetails() external view returns (uint256, uint256);
    function crab() external view returns (address);
    function withdraw(uint256 _bullAmount) external;
    function deposit(uint256 _crabAmount) external payable;
}