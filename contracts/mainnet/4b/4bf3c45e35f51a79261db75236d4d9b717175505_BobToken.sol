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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "./proxy/EIP1967Admin.sol";
import "./token/ERC677.sol";
import "./token/ERC20Permit.sol";
import "./token/ERC20MintBurn.sol";
import "./token/ERC20Recovery.sol";
import "./token/ERC20Blocklist.sol";
import "./utils/Claimable.sol";

/**
 * @title BobToken
 */
contract BobToken is
    EIP1967Admin,
    BaseERC20,
    ERC677,
    ERC20Permit,
    ERC20MintBurn,
    ERC20Recovery,
    ERC20Blocklist,
    Claimable
{
    /**
     * @dev Creates a proxy implementation for BobToken.
     * @param _self address of the proxy contract, linked to the deployed implementation,
     * required for correct EIP712 domain derivation.
     */
    constructor(address _self) ERC20Permit(_self) {}

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return "BOB";
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view override returns (string memory) {
        return "BOB";
    }

    /**
     * @dev Tells if caller is the contract owner.
     * Gives ownership rights to the proxy admin as well.
     * @return true, if caller is the contract owner or proxy admin.
     */
    function _isOwner() internal view override returns (bool) {
        return super._isOwner() || _admin() == _msgSender();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IBurnableERC20 {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function SALTED_PERMIT_TYPEHASH() external view returns (bytes32);

    function receiveWithPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;

    function receiveWithSaltedPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC677 {
    function transferAndCall(address to, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC677Receiver {
    function onTokenTransfer(address from, uint256 value, bytes calldata data) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

/**
 * @title EIP1967Admin
 * @dev Upgradeable proxy pattern implementation according to minimalistic EIP1967.
 */
contract EIP1967Admin {
    // EIP 1967
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    uint256 internal constant EIP1967_ADMIN_STORAGE = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    modifier onlyAdmin() {
        require(msg.sender == _admin(), "EIP1967Admin: not an admin");
        _;
    }

    function _admin() internal view returns (address res) {
        assembly {
            res := sload(EIP1967_ADMIN_STORAGE)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title BaseERC20
 */
abstract contract BaseERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    function name() public view virtual override returns (string memory);

    function symbol() public view virtual override returns (string memory);

    function decimals() public view override returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view virtual override returns (uint256 _balance) {
        _balance = _balances[account];
        assembly {
            _balance := and(_balance, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _decreaseBalance(from, amount);
        _increaseBalance(to, amount);

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        _increaseBalance(account, amount);

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _decreaseBalance(account, amount);
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _increaseBalance(address _account, uint256 _amount) internal {
        uint256 balance = _balances[_account];
        require(balance < 1 << 255, "ERC20: account frozen");
        unchecked {
            _balances[_account] = balance + _amount;
        }
    }

    function _decreaseBalance(address _account, uint256 _amount) internal {
        uint256 balance = _balances[_account];
        require(balance < 1 << 255, "ERC20: account frozen");
        require(balance >= _amount, "ERC20: amount exceeds balance");
        unchecked {
            _balances[_account] = balance - _amount;
        }
    }

    function _decreaseBalanceUnchecked(address _account, uint256 _amount) internal {
        uint256 balance = _balances[_account];
        unchecked {
            _balances[_account] = balance - _amount;
        }
    }

    function _isFrozen(address _account) internal view returns (bool) {
        return _balances[_account] >= 1 << 255;
    }

    function _freezeBalance(address _account) internal {
        _balances[_account] |= 1 << 255;
    }

    function _unfreezeBalance(address _account) internal {
        _balances[_account] &= (1 << 255) - 1;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "../utils/Ownable.sol";
import "./BaseERC20.sol";

/**
 * @title ERC20Blocklist
 */
abstract contract ERC20Blocklist is Ownable, BaseERC20 {
    address public blocklister;

    event Blocked(address indexed account);
    event Unblocked(address indexed account);
    event BlocklisterChanged(address indexed account);

    /**
     * @dev Throws if called by any account other than the blocklister.
     */
    modifier onlyBlocklister() {
        require(msg.sender == blocklister, "Blocklist: caller is not the blocklister");
        _;
    }

    /**
     * @dev Checks if account is blocked.
     * @param _account The address to check.
     */
    function isBlocked(address _account) external view returns (bool) {
        return _isFrozen(_account);
    }

    /**
     * @dev Adds account to blocklist.
     * @param _account The address to blocklist.
     */
    function blockAccount(address _account) external onlyBlocklister {
        _freezeBalance(_account);
        emit Blocked(_account);
    }

    /**
     * @dev Removes account from blocklist.
     * @param _account The address to remove from the blocklist.
     */
    function unblockAccount(address _account) external onlyBlocklister {
        _unfreezeBalance(_account);
        emit Unblocked(_account);
    }

    /**
     * @dev Updates address of the blocklister account.
     * Callable only by the contract owner.
     * @param _newBlocklister address of new blocklister account.
     */
    function updateBlocklister(address _newBlocklister) external onlyOwner {
        blocklister = _newBlocklister;
        emit BlocklisterChanged(_newBlocklister);
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "../utils/Ownable.sol";
import "../interfaces/IMintableERC20.sol";
import "./BaseERC20.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IBurnableERC20.sol";

/**
 * @title ERC20MintBurn
 */
abstract contract ERC20MintBurn is IMintableERC20, IBurnableERC20, Ownable, BaseERC20 {
    mapping(address => uint256) internal permissions;

    event UpdateMinter(address indexed minter, bool canMint, bool canBurn);

    function isMinter(address _account) public view returns (bool) {
        return permissions[_account] & 2 > 0;
    }

    function isBurner(address _account) public view returns (bool) {
        return permissions[_account] & 1 > 0;
    }

    /**
     * @dev Updates mint/burn permissions of the specific account.
     * Callable only by the contract owner.
     * @param _account address of the new minter EOA or contract.
     * @param _canMint true if minting is allowed.
     * @param _canBurn true if burning is allowed.
     */
    function updateMinter(address _account, bool _canMint, bool _canBurn) external onlyOwner {
        permissions[_account] = (_canMint ? 2 : 0) + (_canBurn ? 1 : 0);
        emit UpdateMinter(_account, _canMint, _canBurn);
    }

    /**
     * @dev Mints the specified amount of tokens.
     * Callable only by one of the minter addresses.
     * @param _to address of the tokens receiver.
     * @param _amount amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external {
        require(isMinter(msg.sender), "ERC20MintBurn: not a minter");

        _mint(_to, _amount);
    }

    /**
     * @dev Burns tokens from the caller.
     * Callable only by one of the burner addresses.
     * @param _value amount of tokens to burn. Should be less than or equal to caller balance.
     */
    function burn(uint256 _value) external virtual {
        require(isBurner(msg.sender), "ERC20MintBurn: not a burner");

        _burn(msg.sender, _value);
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IERC20Permit.sol";
import "./BaseERC20.sol";
import "../utils/EIP712.sol";

/**
 * @title ERC20Permit
 */
abstract contract ERC20Permit is IERC20Permit, BaseERC20, EIP712 {
    // EIP2612 permit typehash
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    // Custom "salted" permit typehash
    // Works exactly the same as EIP2612 permit, except that includes an additional salt,
    // which should be explicitly signed by the user, as part of the permit message.
    bytes32 public constant SALTED_PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline,bytes32 salt)");

    mapping(address => uint256) public nonces;

    constructor(address _self) EIP712(_self, name(), "1") {}

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Allows to spend holder's unlimited amount by the specified spender according to EIP2612.
     * The function can be called by anyone, but requires having allowance parameters
     * signed by the holder according to EIP712.
     * Note: call to permit can be executed in the front-running transaction sent by other party,
     * contracts using permit/receiveWithPermit are advised to implement necessary fallbacks for failing permit calls,
     * avoiding entire transaction failures if possible.
     * @param _holder The holder's address.
     * @param _spender The spender's address.
     * @param _value Allowance value to set as a result of the call.
     * @param _deadline The deadline timestamp to call the permit function. Must be a timestamp in the future.
     * Note that timestamps are not precise, malicious miner/validator can manipulate them to some extend.
     * Assume that there can be a 900 seconds time delta between the desired timestamp and the actual expiration.
     * @param _v A final byte of signature (ECDSA component).
     * @param _r The first 32 bytes of signature (ECDSA component).
     * @param _s The second 32 bytes of signature (ECDSA component).
     */
    function permit(
        address _holder,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        _checkPermit(_holder, _spender, _value, _deadline, _v, _r, _s);
        _approve(_holder, _spender, _value);
    }

    /**
     * @dev Cheap shortcut for making sequential calls to permit() + transferFrom() functions.
     * Note: signatures from receiveWithPermit can be re-used in the front-running permit transaction sent by other party,
     * contracts using permit/receiveWithPermit are advised to implement necessary fallbacks for failing
     * receiveWithPermit calls, avoiding entire transaction failures if possible.
     */
    function receiveWithPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        virtual
    {
        _checkPermit(_holder, msg.sender, _value, _deadline, _v, _r, _s);

        // we don't make calls to _approve to avoid unnecessary storage writes
        // however, emitting ERC20 events is still desired
        emit Approval(_holder, msg.sender, _value);

        _approve(_holder, msg.sender, 0);
        _transfer(_holder, msg.sender, _value);
    }

    /**
     * @dev Cheap shortcut for making sequential calls to saltedPermit() + transferFrom() functions.
     */
    function receiveWithSaltedPermit(
        address _holder,
        uint256 _value,
        uint256 _deadline,
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        virtual
    {
        _checkSaltedPermit(_holder, msg.sender, _value, _deadline, _salt, _v, _r, _s);

        // we don't make calls to _approve to avoid unnecessary storage writes
        // however, emitting ERC20 events is still desired
        emit Approval(_holder, msg.sender, _value);

        _approve(_holder, msg.sender, 0);
        _transfer(_holder, msg.sender, _value);
    }

    function _checkPermit(
        address _holder,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        private
    {
        require(block.timestamp <= _deadline, "ERC20Permit: expired permit");

        uint256 nonce = nonces[_holder]++;
        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(), keccak256(abi.encode(PERMIT_TYPEHASH, _holder, _spender, _value, nonce, _deadline))
        );

        require(_holder == ECDSA.recover(digest, _v, _r, _s), "ERC20Permit: invalid ERC2612 signature");
    }

    function _checkSaltedPermit(
        address _holder,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        private
    {
        require(block.timestamp <= _deadline, "ERC20Permit: expired permit");

        uint256 nonce = nonces[_holder]++;
        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(abi.encode(SALTED_PERMIT_TYPEHASH, _holder, _spender, _value, nonce, _deadline, _salt))
        );

        require(_holder == ECDSA.recover(digest, _v, _r, _s), "ERC20Permit: invalid signature");
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "../utils/Ownable.sol";
import "../interfaces/IERC677Receiver.sol";
import "./BaseERC20.sol";

/**
 * @title ERC20Recovery
 */
abstract contract ERC20Recovery is Ownable, BaseERC20 {
    event ExecutedRecovery(bytes32 indexed hash, uint256 value);
    event CancelledRecovery(bytes32 indexed hash);
    event RequestedRecovery(
        bytes32 indexed hash, uint256 requestTimestamp, uint256 executionTimestamp, address[] accounts, uint256[] values
    );

    address public recoveryAdmin;

    address public recoveredFundsReceiver;
    uint64 public recoveryLimitPercent;
    uint32 public recoveryRequestTimelockPeriod;

    uint256 public totalRecovered;

    bytes32 public recoveryRequestHash;
    uint256 public recoveryRequestExecutionTimestamp;

    /**
     * @dev Throws if called by any account other than the contract owner or recovery admin.
     */
    modifier onlyRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin || _isOwner(), "Recovery: not authorized for recovery");
        _;
    }

    /**
     * @dev Updates the address of the recovery admin account.
     * Callable only by the contract owner.
     * Recovery admin is only authorized to request/execute/cancel recovery operations.
     * The availability, parameters and impact limits of recovery is controlled by the contract owner.
     * @param _recoveryAdmin address of the new recovery admin account.
     */
    function setRecoveryAdmin(address _recoveryAdmin) external onlyOwner {
        recoveryAdmin = _recoveryAdmin;
    }

    /**
     * @dev Updates the address of the recovered funds receiver.
     * Callable only by the contract owner.
     * Recovered funds receiver will receive ERC20, recovered from lost/unused accounts.
     * If receiver is a smart contract, it must correctly process a ERC677 callback, sent once on the recovery execution.
     * @param _recoveredFundsReceiver address of the new recovered funds receiver.
     */
    function setRecoveredFundsReceiver(address _recoveredFundsReceiver) external onlyOwner {
        recoveredFundsReceiver = _recoveredFundsReceiver;
    }

    /**
     * @dev Updates the max allowed percentage of total supply, which can be recovered.
     * Limits the impact that could be caused by the recovery admin.
     * Callable only by the contract owner.
     * @param _recoveryLimitPercent percentage, as a fraction of 1 ether, should be at most 100%.
     * In theory, recovery can exceed total supply, if recovered funds are then lost once again,
     * but in practice, we do not expect totalRecovered to reach such extreme values.
     */
    function setRecoveryLimitPercent(uint64 _recoveryLimitPercent) external onlyOwner {
        require(_recoveryLimitPercent <= 1 ether, "Recovery: invalid percentage");
        recoveryLimitPercent = _recoveryLimitPercent;
    }

    /**
     * @dev Updates the timelock period between submission of the recovery request and its execution.
     * Any user, who is not willing to accept the recovery, can safely withdraw his tokens within such period.
     * Callable only by the contract owner.
     * @param _recoveryRequestTimelockPeriod new timelock period in seconds.
     */
    function setRecoveryRequestTimelockPeriod(uint32 _recoveryRequestTimelockPeriod) external onlyOwner {
        require(_recoveryRequestTimelockPeriod >= 1 days, "Recovery: too low timelock period");
        require(_recoveryRequestTimelockPeriod <= 30 days, "Recovery: too high timelock period");
        recoveryRequestTimelockPeriod = _recoveryRequestTimelockPeriod;
    }

    /**
     * @dev Tells if recovery of funds is available, given the current configuration of recovery parameters.
     * @return true, if at least 1 wei of tokens could be recovered within the available limit.
     */
    function isRecoveryEnabled() external view returns (bool) {
        return _remainingRecoveryLimit() > 0;
    }

    /**
     * @dev Internal function telling the remaining available limit for recovery.
     * @return available recovery limit.
     */
    function _remainingRecoveryLimit() internal view returns (uint256) {
        if (recoveredFundsReceiver == address(0)) {
            return 0;
        }
        uint256 limit = totalSupply * recoveryLimitPercent / 1 ether;
        if (limit > totalRecovered) {
            return limit - totalRecovered;
        }
        return 0;
    }

    /**
     * @dev Creates a request to recover funds from abandoned/unused accounts.
     * Only one request could be active at a time. Any pending request would be cancelled and won't take any effect.
     * Callable only by the contract owner or recovery admin.
     * @param _accounts list of accounts to recover funds from.
     * @param _values list of max values to recover from each of the specified account.
     */
    function requestRecovery(address[] calldata _accounts, uint256[] calldata _values) external onlyRecoveryAdmin {
        require(_accounts.length == _values.length, "Recovery: different lengths");
        require(_accounts.length > 0, "Recovery: empty accounts");
        uint256 limit = _remainingRecoveryLimit();
        require(limit > 0, "Recovery: not enabled");

        bytes32 hash = recoveryRequestHash;
        if (hash != bytes32(0)) {
            emit CancelledRecovery(hash);
        }

        uint256[] memory values = new uint256[](_values.length);

        uint256 total = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            uint256 balance = balanceOf(_accounts[i]);
            uint256 value = balance < _values[i] ? balance : _values[i];
            values[i] = value;
            total += value;
        }
        require(total <= limit, "Recovery: exceed recovery limit");

        uint256 executionTimestamp = block.timestamp + recoveryRequestTimelockPeriod;
        hash = keccak256(abi.encode(executionTimestamp, _accounts, values));
        recoveryRequestHash = hash;
        recoveryRequestExecutionTimestamp = executionTimestamp;

        emit RequestedRecovery(hash, block.timestamp, executionTimestamp, _accounts, values);
    }

    /**
     * @dev Executes the request to recover funds from abandoned/unused accounts.
     * Executed request should have exactly the same parameters, as emitted in the RequestedRecovery event.
     * Request could only be executed once configured timelock was surpassed.
     * After execution of the request, total amount of recovered funds should not exceed the configured percentage.
     * Callable only by the contract owner or recovery admin.
     * @param _accounts list of accounts to recover funds from.
     * @param _values list of max values to recover from each of the specified account.
     */
    function executeRecovery(address[] calldata _accounts, uint256[] calldata _values) external onlyRecoveryAdmin {
        uint256 executionTimestamp = recoveryRequestExecutionTimestamp;
        delete recoveryRequestExecutionTimestamp;
        require(executionTimestamp > 0, "Recovery: no active recovery request");
        require(executionTimestamp <= block.timestamp, "Recovery: request still timelocked");
        uint256 limit = _remainingRecoveryLimit();
        require(limit > 0, "Recovery: not enabled");

        bytes32 storedHash = recoveryRequestHash;
        delete recoveryRequestHash;
        bytes32 receivedHash = keccak256(abi.encode(executionTimestamp, _accounts, _values));
        require(storedHash == receivedHash, "Recovery: request hashes do not match");

        uint256 value = _recoverTokens(_accounts, _values);

        require(value <= limit, "Recovery: exceed recovery limit");

        emit ExecutedRecovery(storedHash, value);
    }

    /**
     * @dev Cancels pending recovery request.
     * Callable only by the contract owner or recovery admin.
     */
    function cancelRecovery() external onlyRecoveryAdmin {
        bytes32 hash = recoveryRequestHash;
        require(hash != bytes32(0), "Recovery: no active recovery request");

        delete recoveryRequestHash;
        delete recoveryRequestExecutionTimestamp;

        emit CancelledRecovery(hash);
    }

    function _recoverTokens(address[] calldata _accounts, uint256[] calldata _values) internal returns (uint256) {
        uint256 total = 0;
        address receiver = recoveredFundsReceiver;

        for (uint256 i = 0; i < _accounts.length; i++) {
            uint256 balance = balanceOf(_accounts[i]);
            uint256 value = balance < _values[i] ? balance : _values[i];
            total += value;

            _decreaseBalanceUnchecked(_accounts[i], value);

            emit Transfer(_accounts[i], receiver, value);
        }

        _increaseBalance(receiver, total);

        totalRecovered += total;

        if (Address.isContract(receiver)) {
            require(IERC677Receiver(receiver).onTokenTransfer(address(this), total, new bytes(0)));
        }

        return total;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "../interfaces/IERC677.sol";
import "../interfaces/IERC677Receiver.sol";
import "./BaseERC20.sol";

/**
 * @title ERC677
 */
abstract contract ERC677 is IERC677, BaseERC20 {
    /**
     * @dev ERC677 extension to ERC20 transfer. Will notify receiver after transfer completion.
     * @param _to address of the tokens receiver.
     * @param _amount amount of tokens to mint.
     * @param _data extra data to pass in the notification callback.
     */
    function transferAndCall(address _to, uint256 _amount, bytes calldata _data) external override {
        _transfer(msg.sender, _to, _amount);
        require(IERC677Receiver(_to).onTokenTransfer(msg.sender, _amount, _data), "ERC677: callback failed");
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";

/**
 * @title Claimable
 */
contract Claimable is Ownable {
    address claimingAdmin;

    /**
     * @dev Throws if called by any account other than the contract owner or claiming admin.
     */
    modifier onlyClaimingAdmin() {
        require(_msgSender() == claimingAdmin || _isOwner(), "Claimable: not authorized for claiming");
        _;
    }

    /**
     * @dev Updates the address of the claiming admin account.
     * Callable only by the contract owner.
     * Claiming admin is only authorized to claim ERC20 tokens or native tokens mistakenly sent to the token contract address.
     * @param _claimingAdmin address of the new claiming admin account.
     */
    function setClaimingAdmin(address _claimingAdmin) external onlyOwner {
        claimingAdmin = _claimingAdmin;
    }

    /**
     * @dev Allows to transfer any locked token from this contract.
     * Callable only by the contract owner or claiming admin.
     * @param _token address of the token contract, or 0x00..00 for transferring native coins.
     * @param _to locked tokens receiver address.
     */
    function claimTokens(address _token, address _to) external virtual onlyClaimingAdmin {
        if (_token == address(0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(_to, balance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
 * Adapted from OpenZeppelin library to support address(this) overrides in proxy implementations.
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
    constructor(address self, string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash =
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion, self);
        _CACHED_THIS = self;
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, address(this));
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash,
        address self
    )
        private
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, self));
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

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol" as OZOwnable;

/**
 * @title Ownable
 */
contract Ownable is OZOwnable.Ownable {
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view override {
        require(_isOwner(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Tells if caller is the contract owner.
     * @return true, if caller is the contract owner.
     */
    function _isOwner() internal view virtual returns (bool) {
        return owner() == _msgSender();
    }
}