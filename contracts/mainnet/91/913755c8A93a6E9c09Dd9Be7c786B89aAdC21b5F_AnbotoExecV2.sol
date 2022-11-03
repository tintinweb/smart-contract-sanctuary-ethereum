// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/* ========== STRUCTS ========== */

/**
 * @notice Represents a customer order.
 * @member inputToken Token being sold.
 * @member totalAmount Amount to sell.
 * @member outputToken Token being bought.
 * @member outMin Minumum amount to buy.
 * @member maxGasPrice Maximum gas price accepted.
 * @member feeAmount Agreed fee amount in percents, where 1_00 equals one percent.
 * @member deadline Deadline until which the order is valid.
 * @member salt Random additional input to make the order unique.
 */
struct Order {
    IERC20 inputToken;
    uint256 totalAmount;
    IERC20 outputToken;
    uint256 outMin;
    uint256 maxGasPrice;
    uint256 feeAmount;
    uint256 deadline;
    uint256 salt;
}

/**
 * @notice Exchange quote for swapping tokens.
 * @member spender Address approved to execute swap.
 * @member swapTarget Contract executing the swap.
 * @member sellAmount Amount to sell in the swap.
 * @member swapCallData Custom swap data.
 */
struct Quote {
    address spender;
    address swapTarget;
    uint256 sellAmount;
    bytes swapCallData;
}

/**
 * @notice CoW settlement details.
 * @member sellAmount Amount to sell to the CoW.
 * @member buyAmount Amount to buy from the CoW.
 */
struct Settlement {
    uint256 sellAmount;
    uint256 buyAmount;
}

/* ========== CONTRACTS ========== */

/**
 * @title Composite order contract version 2.
 * @notice This contract manages sliced execution of customer's swap orders.
 * Slices can be executed in two ways:
 * - via executing a swap on external exchange based on a quote
 * - by settling a CoW order based on settlement provided by Anboto CoW solver
 * @dev Contract is Ownable and EIP712.
 * It uses SafeERC20 for token operations.
 * It supports EIP1271 signed messages.
 */
contract AnbotoExecV2 is Ownable, EIP712 {
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    /**
     * @notice Event emitted when new Anboto authorized address is set.
     * @dev Emitted when `setAnboto` is called.
     * @param anboto Anboto authorized address.
     * @param set `true` if authorized, `false` if unathorized.
     */
    event AnbotoSet(address indexed anboto, bool set);

    /**
     * @notice Event emitted when address for Anboto CoW solver is set.
     * @dev Emitted when `setAnbotoCowSolver` is called.
     * @param anbotoCowSolver Address belonging to Anboto CoW solver.
     */
    event AnbotoCowSolverSet(address indexed anbotoCowSolver);

    /**
     * @notice Event emitted when order slice is executed.
     * @dev Emitted when `executeOrder` is called.
     * @param maker Maker of the order.
     * @param sig Order signature.
     * @param soldToken Token sold in execution.
     * @param boughtToken Token bought in execution.
     * @param soldAmount Amount bought in execution.
     * @param boughtAmount Amount sold in execution.
     */
    event OrderExecuted(
        address indexed maker,
        bytes indexed sig,
        address soldToken,
        address boughtToken,
        uint256 soldAmount,
        uint256 boughtAmount
    );

    /**
     * @notice Event emitted when part of the order is executed by settling CoW order.
     * @dev Emitted when `settleCow` is called.
     * @param maker Maker of the order.
     * @param sig Order signature.
     * @param soldToken Token sold in settlement.
     * @param boughtToken Token bought in settlement.
     * @param soldAmount Amount sold in settlement.
     * @param boughtAmount Amount bought in settlement.
     */
    event CowSettled(
        address indexed maker,
        bytes indexed sig,
        address soldToken,
        address boughtToken,
        uint256 soldAmount,
        uint256 boughtAmount
    );

    /**
     * @notice Event emitted when gas is deposited into gas tank.
     * @dev Emitted when `depositGas` is called.
     * @param maker Who made deposit.
     * @param amount Amount deposited.
     */
    event GasDeposited(address indexed maker, uint256 amount);

    /**
     * @notice Event emitted when gas is withdrawn from gas tank.
     * @dev Emitted when `withdrawGas` is called.
     * @param maker Who made withdrawal.
     * @param amount Amount withdrawn.
     */
    event GasWithdrawn(address indexed maker, uint256 amount);

    /**
     * @notice Event emitted when fees are claimed.
     * @dev Emitted when `claimFees` is called.
     * @param claimedTo Where claimed fees were sent to.
     * @param token Token claimed.
     * @param amount Amount claimed.
     */
    event FeesClaimed(address indexed claimedTo, address indexed token, uint256 amount);

    /* ========== CONSTANTS ========== */

    /** @notice One hundred percent. */
    uint256 public constant FULL_PERCENT = 100_00;
    /** @notice Max fee is one percent. */
    uint256 public constant MAX_FEE = 1_00;
    /** @notice Base transaction gas cost. */
    uint256 private constant BASE_TX_GAS = 21_000;

    /** @notice Order struct type signature hash. */
    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            "Order(address inputToken,uint256 totalAmount,address outputToken,uint256 outMin,uint256 maxGasPrice,uint256 feeAmount,uint256 deadline,uint256 salt)"
        );

    /* ========== STATE VARIABLES ========== */

    /** @notice Addresses approved to execute order slices. */
    mapping(address => bool) public isAnboto;
    /** @notice Tracks how much each order is already fulfilled. */
    mapping(bytes => uint256) public orderFulfilledAmount;
    /** @notice Tracks deposited gas per maker. */
    mapping(address => uint256) public gasTank;

    /** @notice Address where CoW settlement contract is deployed. */
    address public immutable cowSettlementContract;
    /** @notice Address of approved Anboto CoW solver. */
    address public anbotoCowSolver;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Contract constructor setting contract domain name and version,
     * and other state.
     * @param _cowSettlementContract Address where CoW settlement contract is deployed.
     * @param _anbotoCowSolver Address of approved Anboto CoW solver.
     */
    constructor(address _cowSettlementContract, address _anbotoCowSolver)
        EIP712("AnbotoExecV2", "2")
    {
        cowSettlementContract = _cowSettlementContract;
        _setAnbotoCowSolver(_anbotoCowSolver);
    }

    /* ========== ADMINISTRATION ========== */

    /**
     * @notice Sets or unsets the address as Anboto approved.
     * @dev Requirements:
     * - can only be called by owner
     * @param _anboto Address to approve or unapprove.
     * @param _set Approves the address when `true`, unapproves when `false`.
     */
    function setAnboto(address _anboto, bool _set) external onlyOwner {
        isAnboto[_anboto] = _set;

        emit AnbotoSet(_anboto, _set);
    }

    /**
     * @notice Sets address as approved Anboto CoW solver.
     * @dev Requirements:
     * - can only be called by owner
     * @param _anbotoCowSolver Address to set.
     */
    function setAnbotoCowSolver(address _anbotoCowSolver) external onlyOwner {
        _setAnbotoCowSolver(_anbotoCowSolver);
    }

    /**
     * @dev Sets address as approved Anboto CoW solver.
     * @param _anbotoCowSolver Address to set.
     */
    function _setAnbotoCowSolver(address _anbotoCowSolver) private {
        anbotoCowSolver = _anbotoCowSolver;

        emit AnbotoCowSolverSet(_anbotoCowSolver);
    }

    /* ========== ORDER FULFILLMENT ========== */

    /**
     * @notice Executes a slice of the original order.
     * The slice is executed by swapping tokens with external exchange as
     * specified in the quote, while making sure that original order
     * specifications are honored.
     * Allowance should be set with input token beforehand by maker.
     * Gas should be deposited beforehand by maker and is reimbursed to the
     * caller. Unused gas can be withdrawn afterwards.
     * Portion of the output will be held as a fee.
     * Un-swapped  portion of the input will be returned to the maker.
     * @dev Requirements:
     * - should be called by owner or Anboto approved address
     * - should be called before order deadline
     * - should be called with gas price under limit specified by order
     * - should be called with order fee under max fee amount
     * - should be called with different token order input and output tokens
     * - should be called with valid signature; order is signed by maker and is unchanged
     * - quote sell amount should not over fulfill order
     * - quote buy amount should be over limit specified by order
     * - maker should have enough gas in their gas tank
     * @param _order Original order made by maker.
     * @param _quote Slice execution specifications.
     * @param _maker Anboto user that made the order.
     * @param _sig Order signed by maker.
     */
    function executeOrder(
        Order calldata _order,
        Quote calldata _quote,
        address _maker,
        bytes calldata _sig
    ) external trackGas(_maker) {
        // Verify conditions.
        require(
            msg.sender == owner() || isAnboto[msg.sender],
            "AnbotoExecV2::executeOrder: Caller is not Anboto."
        );
        validateOrder(_order, _maker, _sig);
        require(
            tx.gasprice <= _order.maxGasPrice,
            "AnbotoExecV2::executeOrder: Gas price too high."
        );

        // Unpack structs.
        uint256 sliceInputAmount = _quote.sellAmount;
        IERC20 inputToken = _order.inputToken;
        IERC20 outputToken = _order.outputToken;

        // Update state and check that order total is not exceeded.
        orderFulfilledAmount[_sig] += sliceInputAmount;
        checkOrderTotal(_order, _sig);

        // Get the balance before the swap.
        uint256 swapInputBalance = inputToken.balanceOf(address(this));
        uint256 swapOutputBalance = outputToken.balanceOf(address(this));

        // Execute the swap.
        inputToken.safeTransferFrom(_maker, address(this), sliceInputAmount);
        inputToken.safeApprove(_quote.spender, sliceInputAmount);
        {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = _quote.swapTarget.call(
                _quote.swapCallData
            );
            if (!success) revert(getRevertMsg(data));
        }

        // Get the balance after the swap.
        // Equals amount of input tokens that were pulled from maker but not swapped.
        swapInputBalance = inputToken.balanceOf(address(this)) - swapInputBalance;
        // Equals amount of output tokens that were obtained in the swap.
        swapOutputBalance = outputToken.balanceOf(address(this)) - swapOutputBalance;

        // If input tokens went unspent, return them and update balances.
        if (swapInputBalance > 0) {
            sliceInputAmount -= swapInputBalance;
            orderFulfilledAmount[_sig] -= swapInputBalance;
            inputToken.safeTransfer(_maker, swapInputBalance);
            inputToken.safeApprove(_quote.spender, 0);
        }

        // Check if enough output tokens were received by the swap.
        checkOutputAmount(_order, sliceInputAmount, swapOutputBalance);

        // Transfer output tokens (minus fees) to the maker.
        outputToken.safeTransfer(
            _maker,
            swapOutputBalance - getFee(swapOutputBalance, _order.feeAmount)
        );

        emit OrderExecuted(
            _maker,
            _sig,
            address(inputToken),
            address(outputToken),
            sliceInputAmount,
            swapOutputBalance
        );
    }

    /**
     * @notice Use a slice of the original order to settle a CoW order.
     * The CoW order is settled by swapping tokens with CoW settlement contract
     * as specified in the settlement, while making sure that original order
     * specifications are honored.
     * Allowance should be set with input token beforehand by maker.
     * Portion of the output will be held as a fee.
     * @dev Requirements:
     * - should be called by CoW settlement contract
     * - transaction should be originating from Anboto CoW solver
     * - should be called before order deadline
     * - should be called with order fee under max fee amount
     * - should be called with different token order input and output tokens
     * - should be called with valid signature; order is signed by maker and is unchanged
     * - settlement sell amount should not over fulfill order
     * - settlement buy amount should be over limit specified by order
     * @param _order Original order made by maker.
     * @param _settlement CoW settlement specifications.
     * @param _maker Anboto user that made the order.
     * @param _sig Order signed by maker.
     */
    function settleCow(
        Order calldata _order,
        Settlement calldata _settlement,
        address _maker,
        bytes calldata _sig
    ) external {
        // Verify conditions.
        require(
            msg.sender == cowSettlementContract,
            "AnbotoExecV2::settleCow: Caller is not CoW settlement contract."
        );
        require(
            // solhint-disable-next-line avoid-tx-origin
            tx.origin == anbotoCowSolver,
            "AnbotoExecV2::settleCow: Origin is not Anboto CoW solver."
        );
        validateOrder(_order, _maker, _sig);

        // Unpack structs.
        IERC20 inputToken = _order.inputToken;
        IERC20 outputToken = _order.outputToken;
        uint256 sellAmount = _settlement.sellAmount;
        uint256 buyAmount = _settlement.buyAmount;

        // Update balance and verify settlement.
        orderFulfilledAmount[_sig] += sellAmount;
        checkOrderTotal(_order, _sig);
        checkOutputAmount(_order, sellAmount, buyAmount);

        // Settle order.
        inputToken.safeTransferFrom(_maker, cowSettlementContract, sellAmount);
        outputToken.safeTransferFrom(cowSettlementContract, address(this), buyAmount);

        // Transfer output tokens (minus fees) to the maker.
        outputToken.safeTransfer(_maker, buyAmount - getFee(buyAmount, _order.feeAmount));

        emit CowSettled(
            _maker,
            _sig,
            address(inputToken),
            address(outputToken),
            sellAmount,
            buyAmount
        );
    }

    /* ========== GAS AND FEES ========== */

    /**
     * @notice Deposit gas into gas tank.
     * Deposited gas is used to reimburse Anboto for executing order. Leftover
     * gas can be withdrawn afterwards.
     */
    receive() external payable {
        depositGas();
    }

    /**
     * @notice Deposit gas into gas tank.
     * Deposited gas is used to reimburse Anboto for executing order. Leftover
     * gas can be withdrawn afterwards.
     */
    function depositGas() public payable {
        gasTank[msg.sender] += msg.value;

        emit GasDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw gas from gas tank.
     * @dev Requirements:
     * - enough gas is present in the gas tank
     * @param _amount Amount of gas to withdraw.
     */
    function withdrawGas(uint256 _amount) external {
        require(
            gasTank[msg.sender] >= _amount,
            "AnbotoExecV2::withdrawGas: Not enough gas."
        );

        unchecked {
            gasTank[msg.sender] -= _amount;
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = payable(msg.sender).call{ value: _amount }(
            ""
        );
        if (!success) revert(getRevertMsg(data));

        emit GasWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Claim collected fees.
     * @dev Requirements:
     * - can only be called by owner
     * - cannot be claimed to null address
     * @param _tokens Claim fees collected in these tokens.
     * @param _claimTo Where to send collected fees.
     */
    function claimFees(IERC20[] calldata _tokens, address _claimTo) external onlyOwner {
        require(
            _claimTo != address(0),
            "AnbotoExecV2::claimFees: Cannot claim to null address."
        );

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 amountToClaim = _tokens[i].balanceOf(address(this));
            _tokens[i].transfer(_claimTo, amountToClaim);

            emit FeesClaimed(_claimTo, address(_tokens[i]), amountToClaim);
        }
    }

    /* ========== HELPERS ========== */

    /**
     * @notice Checks validitiy of order signature.
     * The signature is considered valid, if
     * - it is signed by provided signer and
     * - provided order matches signed one.
     * @dev Uses EIP712 and EIP1271 standard libraries.
     * @param _order Signed order.
     * @param _signer Order signer.
     * @param _sig Signature to validate.
     * @return `true` if order is valid, `false` otherwise.
     */
    function isValidSignature(
        Order calldata _order,
        address _signer,
        bytes calldata _sig
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(hashOrder(_order));
        return SignatureChecker.isValidSignatureNow(_signer, digest, _sig);
    }

    /**
     * @dev Calculates hash of an Order struct.
     * Used as part of EIP712 and checking validity of order signature.
     * @param _order Order to hash.
     * @return Hash of the order.
     */
    function hashOrder(Order calldata _order) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    _order.inputToken,
                    _order.totalAmount,
                    _order.outputToken,
                    _order.outMin,
                    _order.maxGasPrice,
                    _order.feeAmount,
                    _order.deadline,
                    _order.salt
                )
            );
    }

    /**
     * @dev Gets revert message when a low-level call reverts, so that it can
     * be bubbled-up to caller.
     * @param _returnData Data returned from reverted low-level call.
     * @return Revert message.
     */
    function getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // if the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68)
            return "AnbotoExecV2::getRevertMsg: Transaction reverted silently.";

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // slice the sig hash
            _returnData := add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string)); // all that remains is the revert string
    }

    /**
     * @dev Calculates fee owed to Anboto.
     * @param amount Amount of tokens bought.
     * @param fee Fee in percents, where 1_00 equals one percent.
     * @return Fee owed in output tokens.
     */
    function getFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return (amount * fee) / FULL_PERCENT;
    }

    /**
     * @dev Validates order and its signature:
     * - order deadline should not have passed
     * - order fee amount should not be too high
     * - order input and output tokens should not be same
     * - order should be signed by maker and should be unchanged
     * @param _order Order made by maker.
     * @param _maker Anboto user that made the order.
     * @param _sig Order signed by maker.
     */
    function validateOrder(
        Order calldata _order,
        address _maker,
        bytes calldata _sig
    ) private view {
        require(
            block.timestamp <= _order.deadline,
            "AnbotoExecV2::validateOrder: Order deadline passed."
        );
        require(
            _order.feeAmount <= MAX_FEE,
            "AnbotoExecV2::validateOrder: Fee too high."
        );
        require(
            _order.inputToken != _order.outputToken,
            "AnbotoExecV2::validateOrder: Input and output tokens are same."
        );

        // Verify signature.
        require(
            isValidSignature(_order, _maker, _sig),
            "AnbotoExecV2::validateOrder: Invalid signature."
        );
    }

    /**
     * @dev Checks that order total amount has not been exceeded.
     * @param _order Order made by maker.
     * @param _sig Order signed by maker.
     */
    function checkOrderTotal(Order calldata _order, bytes calldata _sig) private view {
        require(
            orderFulfilledAmount[_sig] <= _order.totalAmount,
            "AnbotoExecV2::checkOrderTotal: Order total exceeded."
        );
    }

    /**
     * @dev Checks that output amount is not too low.
     * @param _order Order made by maker.
     * @param _soldAmount Amount of tokens sold in trade.
     * @param _boughtAmount Amount of tokens bought in trade.
     */
    function checkOutputAmount(
        Order calldata _order,
        uint256 _soldAmount,
        uint256 _boughtAmount
    ) private pure {
        require(
            _boughtAmount >= (_order.outMin * _soldAmount) / _order.totalAmount,
            "AnbotoExecV2::checkOutputAmount: Output amount too low."
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Tracks gas used by a transaction.
     * Used gas is reimbursed to the caller from maker's gas tank.
     * @dev Requirements:
     * - maker needs enough gas to cover the transaction
     */
    modifier trackGas(address _maker) {
        uint256 gas = gasleft();
        _;
        unchecked {
            uint256 gasUsed = gas + BASE_TX_GAS + (msg.data.length * 10) - gasleft();
            uint256 coinGasUsed = gasUsed * tx.gasprice;

            require(
                gasTank[_maker] >= coinGasUsed,
                "AnbotoExecV2::trackGas: Not enough gas in the tank."
            );

            gasTank[_maker] -= coinGasUsed;

            // solhint-disable-next-line avoid-low-level-calls, avoid-tx-origin
            (bool success, bytes memory data) = payable(tx.origin).call{
                value: coinGasUsed
            }("");
            if (!success) revert(getRevertMsg(data));
        }
    }
}