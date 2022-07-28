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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// This contract is taken from Uniswaps's multi call implementation (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol)
// and was modified to be solidity 0.8 compatible. Additionally, the method was restricted to only work with msg.value
// set to 0 to avoid any nasty attack vectors on function calls that use value sent with deposits.
pragma solidity ^0.8.0;

/// @title MultiCaller
/// @notice Enables calling multiple methods in a single call to the contract
contract MultiCaller {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        require(msg.value == 0, "Only multicall with 0 value");
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run in production, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view virtual returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the currentTime variable set in the Timer.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./SpokePool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Ethereum L1 specific SpokePool. Used on Ethereum L1 to facilitate L2->L1 transfers.
 */
contract Ethereum_SpokePool is SpokePool, Ownable {
    /**
     * @notice Construct the Ethereum SpokePool.
     * @param _hubPool Hub pool address to set. Can be changed by admin.
     * @param _wethAddress Weth address for this network to set.
     * @param timerAddress Timer address to set.
     */
    constructor(
        address _hubPool,
        address _wethAddress,
        address timerAddress
    ) SpokePool(msg.sender, _hubPool, _wethAddress, timerAddress) {}

    /**************************************
     *          INTERNAL FUNCTIONS           *
     **************************************/

    function _bridgeTokensToHubPool(RelayerRefundLeaf memory relayerRefundLeaf) internal override {
        IERC20(relayerRefundLeaf.l2TokenAddress).transfer(hubPool, relayerRefundLeaf.amountToReturn);
    }

    // Admin is simply owner which should be same account that owns the HubPool deployed on this network. A core
    // assumption of this contract system is that the HubPool is deployed on Ethereum.
    function _requireAdminSender() internal override onlyOwner {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/AdapterInterface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Concise list of functions in HubPool implementation.
 */
interface HubPoolInterface {
    // This leaf is meant to be decoded in the HubPool to rebalance tokens between HubPool and SpokePool.
    struct PoolRebalanceLeaf {
        // This is used to know which chain to send cross-chain transactions to (and which SpokePool to send to).
        uint256 chainId;
        // Total LP fee amount per token in this bundle, encompassing all associated bundled relays.
        uint256[] bundleLpFees;
        // Represents the amount to push to or pull from the SpokePool. If +, the pool pays the SpokePool. If negative
        // the SpokePool pays the HubPool. There can be arbitrarily complex rebalancing rules defined offchain. This
        // number is only nonzero when the rules indicate that a rebalancing action should occur. When a rebalance does
        // occur, runningBalances must be set to zero for this token and netSendAmounts should be set to the previous
        // runningBalances + relays - deposits in this bundle. If non-zero then it must be set on the SpokePool's
        // RelayerRefundLeaf amountToReturn as -1 * this value to show if funds are being sent from or to the SpokePool.
        int256[] netSendAmounts;
        // This is only here to be emitted in an event to track a running unpaid balance between the L2 pool and the L1
        // pool. A positive number indicates that the HubPool owes the SpokePool funds. A negative number indicates that
        // the SpokePool owes the HubPool funds. See the comment above for the dynamics of this and netSendAmounts.
        int256[] runningBalances;
        // Used by data worker to mark which leaves should relay roots to SpokePools, and to otherwise organize leaves.
        // For example, each leaf should contain all the rebalance information for a single chain, but in the case where
        // the list of l1Tokens is very large such that they all can't fit into a single leaf that can be executed under
        // the block gas limit, then the data worker can use this groupIndex to organize them. Any leaves with
        // a groupIndex equal to 0 will relay roots to the SpokePool, so the data worker should ensure that only one
        // leaf for a specific chainId should have a groupIndex equal to 0.
        uint256 groupIndex;
        // Used as the index in the bitmap to track whether this leaf has been executed or not.
        uint8 leafId;
        // The bundleLpFees, netSendAmounts, and runningBalances are required to be the same length. They are parallel
        // arrays for the given chainId and should be ordered by the l1Tokens field. All whitelisted tokens with nonzero
        // relays on this chain in this bundle in the order of whitelisting.
        address[] l1Tokens;
    }

    // A data worker can optimistically store several merkle roots on this contract by staking a bond and calling
    // proposeRootBundle. By staking a bond, the data worker is alleging that the merkle roots all contain valid leaves
    // that can be executed later to:
    // - Send funds from this contract to a SpokePool or vice versa
    // - Send funds from a SpokePool to Relayer as a refund for a relayed deposit
    // - Send funds from a SpokePool to a deposit recipient to fulfill a "slow" relay
    // Anyone can dispute this struct if the merkle roots contain invalid leaves before the
    // challengePeriodEndTimestamp. Once the expiration timestamp is passed, executeRootBundle to execute a leaf
    // from the poolRebalanceRoot on this contract and it will simultaneously publish the relayerRefundRoot and
    // slowRelayRoot to a SpokePool. The latter two roots, once published to the SpokePool, contain
    // leaves that can be executed on the SpokePool to pay relayers or recipients.
    struct RootBundle {
        // Contains leaves instructing this contract to send funds to SpokePools.
        bytes32 poolRebalanceRoot;
        // Relayer refund merkle root to be published to a SpokePool.
        bytes32 relayerRefundRoot;
        // Slow relay merkle root to be published to a SpokePool.
        bytes32 slowRelayRoot;
        // This is a 1D bitmap, with max size of 256 elements, limiting us to 256 chainsIds.
        uint256 claimedBitMap;
        // Proposer of this root bundle.
        address proposer;
        // Number of pool rebalance leaves to execute in the poolRebalanceRoot. After this number
        // of leaves are executed, a new root bundle can be proposed
        uint8 unclaimedPoolRebalanceLeafCount;
        // When root bundle challenge period passes and this root bundle becomes executable.
        uint32 challengePeriodEndTimestamp;
    }

    // Each whitelisted L1 token has an associated pooledToken struct that contains all information used to track the
    // cumulative LP positions and if this token is enabled for deposits.
    struct PooledToken {
        // LP token given to LPs of a specific L1 token.
        address lpToken;
        // True if accepting new LP's.
        bool isEnabled;
        // Timestamp of last LP fee update.
        uint32 lastLpFeeUpdate;
        // Number of LP funds sent via pool rebalances to SpokePools and are expected to be sent
        // back later.
        int256 utilizedReserves;
        // Number of LP funds held in contract less utilized reserves.
        uint256 liquidReserves;
        // Number of LP funds reserved to pay out to LPs as fees.
        uint256 undistributedLpFees;
    }

    // Helper contracts to facilitate cross chain actions between HubPool and SpokePool for a specific network.
    struct CrossChainContract {
        address adapter;
        address spokePool;
    }

    function setPaused(bool pause) external;

    function emergencyDeleteProposal() external;

    function relaySpokePoolAdminFunction(uint256 chainId, bytes memory functionData) external;

    function setProtocolFeeCapture(address newProtocolFeeCaptureAddress, uint256 newProtocolFeeCapturePct) external;

    function setBond(IERC20 newBondToken, uint256 newBondAmount) external;

    function setLiveness(uint32 newLiveness) external;

    function setIdentifier(bytes32 newIdentifier) external;

    function setCrossChainContracts(
        uint256 l2ChainId,
        address adapter,
        address spokePool
    ) external;

    function enableL1TokenForLiquidityProvision(address l1Token) external;

    function disableL1TokenForLiquidityProvision(address l1Token) external;

    function addLiquidity(address l1Token, uint256 l1TokenAmount) external payable;

    function removeLiquidity(
        address l1Token,
        uint256 lpTokenAmount,
        bool sendEth
    ) external;

    function exchangeRateCurrent(address l1Token) external returns (uint256);

    function liquidityUtilizationCurrent(address l1Token) external returns (uint256);

    function liquidityUtilizationPostRelay(address l1Token, uint256 relayedAmount) external returns (uint256);

    function sync(address l1Token) external;

    function proposeRootBundle(
        uint256[] memory bundleEvaluationBlockNumbers,
        uint8 poolRebalanceLeafCount,
        bytes32 poolRebalanceRoot,
        bytes32 relayerRefundRoot,
        bytes32 slowRelayRoot
    ) external;

    function executeRootBundle(
        uint256 chainId,
        uint256 groupIndex,
        uint256[] memory bundleLpFees,
        int256[] memory netSendAmounts,
        int256[] memory runningBalances,
        uint8 leafId,
        address[] memory l1Tokens,
        bytes32[] memory proof
    ) external;

    function disputeRootBundle() external;

    function claimProtocolFeesCaptured(address l1Token) external;

    function setPoolRebalanceRoute(
        uint256 destinationChainId,
        address l1Token,
        address destinationToken
    ) external;

    function setDepositRoute(
        uint256 originChainId,
        uint256 destinationChainId,
        address originToken,
        bool depositsEnabled
    ) external;

    function poolRebalanceRoute(uint256 destinationChainId, address l1Token)
        external
        view
        returns (address destinationToken);

    function loadEthForL2Calls() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 * @dev The reason why we use this local contract instead of importing from uma/contracts is because of the addition
 * of the internal method `functionCallStackOriginatesFromOutsideThisContract` which doesn't exist in the one exported
 * by uma/contracts.
 */
contract Lockable {
    bool internal _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a nonReentrant function from another nonReentrant function is not supported. It is possible to
     * prevent this from happening by making the nonReentrant function external, and making it call a private
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a nonReentrant() state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    /**
     * @dev Returns true if the contract is currently in a non-entered state, meaning that the origination of the call
     * came from outside the contract. This is relevant with fallback/receive methods to see if the call came from ETH
     * being dropped onto the contract externally or due to ETH dropped on the the contract from within a method in this
     * contract, such as unwrapping WETH to ETH within the contract.
     */
    function functionCallStackOriginatesFromOutsideThisContract() internal view returns (bool) {
        return _notEntered;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every nonReentrant() method.
    // On entry into a function, _preEntranceCheck() should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call _postEntranceSet(), perform its logic, and
    // then call _postEntranceReset().
    // View-only methods can simply call _preEntranceCheck() to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./SpokePoolInterface.sol";
import "./HubPoolInterface.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Library to help with merkle roots, proofs, and claims.
 */
library MerkleLib {
    /**
     * @notice Verifies that a repayment is contained within a merkle root.
     * @param root the merkle root.
     * @param rebalance the rebalance struct.
     * @param proof the merkle proof.
     * @return bool to signal if the pool rebalance proof correctly shows inclusion of the rebalance within the tree.
     */
    function verifyPoolRebalance(
        bytes32 root,
        HubPoolInterface.PoolRebalanceLeaf memory rebalance,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encode(rebalance)));
    }

    /**
     * @notice Verifies that a relayer refund is contained within a merkle root.
     * @param root the merkle root.
     * @param refund the refund struct.
     * @param proof the merkle proof.
     * @return bool to signal if the relayer refund proof correctly shows inclusion of the refund within the tree.
     */
    function verifyRelayerRefund(
        bytes32 root,
        SpokePoolInterface.RelayerRefundLeaf memory refund,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encode(refund)));
    }

    /**
     * @notice Verifies that a distribution is contained within a merkle root.
     * @param root the merkle root.
     * @param slowRelayFulfillment the relayData fulfillment struct.
     * @param proof the merkle proof.
     * @return bool to signal if the slow relay's proof correctly shows inclusion of the slow relay within the tree.
     */
    function verifySlowRelayFulfillment(
        bytes32 root,
        SpokePoolInterface.RelayData memory slowRelayFulfillment,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encode(slowRelayFulfillment)));
    }

    // The following functions are primarily copied from
    // https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol with minor changes.

    /**
     * @notice Tests whether a claim is contained within a claimedBitMap mapping.
     * @param claimedBitMap a simple uint256 mapping in storage used as a bitmap.
     * @param index the index to check in the bitmap.
     * @return bool indicating if the index within the claimedBitMap has been marked as claimed.
     */
    function isClaimed(mapping(uint256 => uint256) storage claimedBitMap, uint256 index) internal view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @notice Marks an index in a claimedBitMap as claimed.
     * @param claimedBitMap a simple uint256 mapping in storage used as a bitmap.
     * @param index the index to mark in the bitmap.
     */
    function setClaimed(mapping(uint256 => uint256) storage claimedBitMap, uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
     * @notice Tests whether a claim is contained within a 1D claimedBitMap mapping.
     * @param claimedBitMap a simple uint256 value, encoding a 1D bitmap.
     * @param index the index to check in the bitmap. Uint8 type enforces that index can't be > 255.
     * @return bool indicating if the index within the claimedBitMap has been marked as claimed.
     */
    function isClaimed1D(uint256 claimedBitMap, uint8 index) internal pure returns (bool) {
        uint256 mask = (1 << index);
        return claimedBitMap & mask == mask;
    }

    /**
     * @notice Marks an index in a claimedBitMap as claimed.
     * @param claimedBitMap a simple uint256 mapping in storage used as a bitmap. Uint8 type enforces that index
     * can't be > 255.
     * @param index the index to mark in the bitmap.
     * @return uint256 representing the modified input claimedBitMap with the index set to true.
     */
    function setClaimed1D(uint256 claimedBitMap, uint8 index) internal pure returns (uint256) {
        return claimedBitMap | (1 << index % 256);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./MerkleLib.sol";
import "./interfaces/WETH9.sol";
import "./Lockable.sol";
import "./SpokePoolInterface.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@uma/core/contracts/common/implementation/Testable.sol";
import "@uma/core/contracts/common/implementation/MultiCaller.sol";

/**
 * @title SpokePool
 * @notice Base contract deployed on source and destination chains enabling depositors to transfer assets from source to
 * destination. Deposit orders are fulfilled by off-chain relayers who also interact with this contract. Deposited
 * tokens are locked on the source chain and relayers send the recipient the desired token currency and amount
 * on the destination chain. Locked source chain tokens are later sent over the canonical token bridge to L1 HubPool.
 * Relayers are refunded with destination tokens out of this contract after another off-chain actor, a "data worker",
 * submits a proof that the relayer correctly submitted a relay on this SpokePool.
 */
abstract contract SpokePool is SpokePoolInterface, Testable, Lockable, MultiCaller {
    using SafeERC20 for IERC20;
    using Address for address;

    // Address of the L1 contract that acts as the owner of this SpokePool. If this contract is deployed on Ethereum,
    // then this address should be set to the same owner as the HubPool and the whole system.
    address public crossDomainAdmin;

    // Address of the L1 contract that will send tokens to and receive tokens from this contract to fund relayer
    // refunds and slow relays.
    address public hubPool;

    // Address of wrappedNativeToken contract for this network. If an origin token matches this, then the caller can
    // optionally instruct this contract to wrap native tokens when depositing (ie ETH->WETH or MATIC->WMATIC).
    WETH9 public immutable wrappedNativeToken;

    // Any deposit quote times greater than or less than this value to the current contract time is blocked. Forces
    // caller to use an approximately "current" realized fee. Defaults to 10 minutes.
    uint32 public depositQuoteTimeBuffer = 600;

    // Count of deposits is used to construct a unique deposit identifier for this spoke pool.
    uint32 public numberOfDeposits;

    // This contract can store as many root bundles as the HubPool chooses to publish here.
    RootBundle[] public rootBundles;

    // Origin token to destination token routings can be turned on or off, which can enable or disable deposits.
    mapping(address => mapping(uint256 => bool)) public enabledDepositRoutes;

    // Each relay is associated with the hash of parameters that uniquely identify the original deposit and a relay
    // attempt for that deposit. The relay itself is just represented as the amount filled so far. The total amount to
    // relay, the fees, and the agents are all parameters included in the hash key.
    mapping(bytes32 => uint256) public relayFills;

    /****************************************
     *                EVENTS                *
     ****************************************/
    event SetXDomainAdmin(address indexed newAdmin);
    event SetHubPool(address indexed newHubPool);
    event EnabledDepositRoute(address indexed originToken, uint256 indexed destinationChainId, bool enabled);
    event SetDepositQuoteTimeBuffer(uint32 newBuffer);
    event FundsDeposited(
        uint256 amount,
        uint256 originChainId,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 indexed depositId,
        uint32 quoteTimestamp,
        address indexed originToken,
        address recipient,
        address indexed depositor
    );
    event RequestedSpeedUpDeposit(
        uint64 newRelayerFeePct,
        uint32 indexed depositId,
        address indexed depositor,
        bytes depositorSignature
    );
    event FilledRelay(
        uint256 amount,
        uint256 totalFilledAmount,
        uint256 fillAmount,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint64 appliedRelayerFeePct,
        uint64 realizedLpFeePct,
        uint32 depositId,
        address destinationToken,
        address indexed relayer,
        address indexed depositor,
        address recipient,
        bool isSlowRelay
    );
    event RelayedRootBundle(
        uint32 indexed rootBundleId,
        bytes32 indexed relayerRefundRoot,
        bytes32 indexed slowRelayRoot
    );
    event ExecutedRelayerRefundRoot(
        uint256 amountToReturn,
        uint256 indexed chainId,
        uint256[] refundAmounts,
        uint32 indexed rootBundleId,
        uint32 indexed leafId,
        address l2TokenAddress,
        address[] refundAddresses,
        address caller
    );
    event TokensBridged(
        uint256 amountToReturn,
        uint256 indexed chainId,
        uint32 indexed leafId,
        address indexed l2TokenAddress,
        address caller
    );
    event EmergencyDeleteRootBundle(uint256 indexed rootBundleId);

    /**
     * @notice Construct the base SpokePool.
     * @param _crossDomainAdmin Cross domain admin to set. Can be changed by admin.
     * @param _hubPool Hub pool address to set. Can be changed by admin.
     * @param _wrappedNativeTokenAddress wrappedNativeToken address for this network to set.
     * @param timerAddress Timer address to set.
     */
    constructor(
        address _crossDomainAdmin,
        address _hubPool,
        address _wrappedNativeTokenAddress,
        address timerAddress
    ) Testable(timerAddress) {
        _setCrossDomainAdmin(_crossDomainAdmin);
        _setHubPool(_hubPool);
        wrappedNativeToken = WETH9(_wrappedNativeTokenAddress);
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    // Implementing contract needs to override _requireAdminSender() to ensure that admin functions are protected
    // appropriately.
    modifier onlyAdmin() {
        _requireAdminSender();
        _;
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Change cross domain admin address. Callable by admin only.
     * @param newCrossDomainAdmin New cross domain admin.
     */
    function setCrossDomainAdmin(address newCrossDomainAdmin) public override onlyAdmin nonReentrant {
        _setCrossDomainAdmin(newCrossDomainAdmin);
    }

    /**
     * @notice Change L1 hub pool address. Callable by admin only.
     * @param newHubPool New hub pool.
     */
    function setHubPool(address newHubPool) public override onlyAdmin nonReentrant {
        _setHubPool(newHubPool);
    }

    /**
     * @notice Enable/Disable an origin token => destination chain ID route for deposits. Callable by admin only.
     * @param originToken Token that depositor can deposit to this contract.
     * @param destinationChainId Chain ID for where depositor wants to receive funds.
     * @param enabled True to enable deposits, False otherwise.
     */
    function setEnableRoute(
        address originToken,
        uint256 destinationChainId,
        bool enabled
    ) public override onlyAdmin nonReentrant {
        enabledDepositRoutes[originToken][destinationChainId] = enabled;
        emit EnabledDepositRoute(originToken, destinationChainId, enabled);
    }

    /**
     * @notice Change allowance for deposit quote time to differ from current block time. Callable by admin only.
     * @param newDepositQuoteTimeBuffer New quote time buffer.
     */
    function setDepositQuoteTimeBuffer(uint32 newDepositQuoteTimeBuffer) public override onlyAdmin nonReentrant {
        depositQuoteTimeBuffer = newDepositQuoteTimeBuffer;
        emit SetDepositQuoteTimeBuffer(newDepositQuoteTimeBuffer);
    }

    /**
     * @notice This method stores a new root bundle in this contract that can be executed to refund relayers, fulfill
     * slow relays, and send funds back to the HubPool on L1. This method can only be called by the admin and is
     * designed to be called as part of a cross-chain message from the HubPool's executeRootBundle method.
     * @param relayerRefundRoot Merkle root containing relayer refund leaves that can be individually executed via
     * executeRelayerRefundLeaf().
     * @param slowRelayRoot Merkle root containing slow relay fulfillment leaves that can be individually executed via
     * executeSlowRelayLeaf().
     */
    function relayRootBundle(bytes32 relayerRefundRoot, bytes32 slowRelayRoot) public override onlyAdmin nonReentrant {
        uint32 rootBundleId = uint32(rootBundles.length);
        RootBundle storage rootBundle = rootBundles.push();
        rootBundle.relayerRefundRoot = relayerRefundRoot;
        rootBundle.slowRelayRoot = slowRelayRoot;
        emit RelayedRootBundle(rootBundleId, relayerRefundRoot, slowRelayRoot);
    }

    /**
     * @notice This method is intended to only be used in emergencies where a bad root bundle has reached the
     * SpokePool.
     * @param rootBundleId Index of the root bundle that needs to be deleted. Note: this is intentionally a uint256
     * to ensure that a small input range doesn't limit which indices this method is able to reach.
     */
    function emergencyDeleteRootBundle(uint256 rootBundleId) public override onlyAdmin nonReentrant {
        delete rootBundles[rootBundleId];
        emit EmergencyDeleteRootBundle(rootBundleId);
    }

    /**************************************
     *         DEPOSITOR FUNCTIONS        *
     **************************************/

    /**
     * @notice Called by user to bridge funds from origin to destination chain. Depositor will effectively lock
     * tokens in this contract and receive a destination token on the destination chain. The origin => destination
     * token mapping is stored on the L1 HubPool.
     * @notice The caller must first approve this contract to spend amount of originToken.
     * @notice The originToken => destinationChainId must be enabled.
     * @notice This method is payable because the caller is able to deposit native token if the originToken is
     * wrappedNativeToken and this function will handle wrapping the native token to wrappedNativeToken.
     * @param recipient Address to receive funds at on destination chain.
     * @param originToken Token to lock into this contract to initiate deposit.
     * @param amount Amount of tokens to deposit. Will be amount of tokens to receive less fees.
     * @param destinationChainId Denotes network where user will receive funds from SpokePool by a relayer.
     * @param relayerFeePct % of deposit amount taken out to incentivize a fast relayer.
     * @param quoteTimestamp Timestamp used by relayers to compute this deposit's realizedLPFeePct which is paid
     * to LP pool on HubPool.
     */
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) public payable override nonReentrant {
        // Check that deposit route is enabled.
        require(enabledDepositRoutes[originToken][destinationChainId], "Disabled route");

        // We limit the relay fees to prevent the user spending all their funds on fees.
        require(relayerFeePct < 0.5e18, "invalid relayer fee");
        // This function assumes that L2 timing cannot be compared accurately and consistently to L1 timing. Therefore,
        // block.timestamp is different from the L1 EVM's. Therefore, the quoteTimestamp must be within a configurable
        // buffer of this contract's block time to allow for this variance.
        // Note also that quoteTimestamp cannot be less than the buffer otherwise the following arithmetic can result
        // in underflow. This isn't a problem as the deposit will revert, but the error might be unexpected for clients.
        require(
            getCurrentTime() >= quoteTimestamp - depositQuoteTimeBuffer &&
                getCurrentTime() <= quoteTimestamp + depositQuoteTimeBuffer,
            "invalid quote time"
        );
        // If the address of the origin token is a wrappedNativeToken contract and there is a msg.value with the
        // transaction then the user is sending ETH. In this case, the ETH should be deposited to wrappedNativeToken.
        if (originToken == address(wrappedNativeToken) && msg.value > 0) {
            require(msg.value == amount, "msg.value must match amount");
            wrappedNativeToken.deposit{ value: msg.value }();
            // Else, it is a normal ERC20. In this case pull the token from the user's wallet as per normal.
            // Note: this includes the case where the L2 user has WETH (already wrapped ETH) and wants to bridge them.
            // In this case the msg.value will be set to 0, indicating a "normal" ERC20 bridging action.
        } else IERC20(originToken).safeTransferFrom(msg.sender, address(this), amount);

        _emitDeposit(
            amount,
            chainId(),
            destinationChainId,
            relayerFeePct,
            numberOfDeposits,
            quoteTimestamp,
            originToken,
            recipient,
            msg.sender
        );

        // Increment count of deposits so that deposit ID for this spoke pool is unique.
        // @dev: Use pre-increment to save gas:
        // i++ --> Load, Store, Add, Store
        // ++i --> Load, Add, Store
        ++numberOfDeposits;
    }

    /**
     * @notice Convenience method that depositor can use to signal to relayer to use updated fee.
     * @notice Relayer should only use events emitted by this function to submit fills with updated fees, otherwise they
     * risk their fills getting disputed for being invalid, for example if the depositor never actually signed the
     * update fee message.
     * @notice This function will revert if the depositor did not sign a message containing the updated fee for the
     * deposit ID stored in this contract. If the deposit ID is for another contract, or the depositor address is
     * incorrect, or the updated fee is incorrect, then the signature will not match and this function will revert.
     * @param depositor Signer of the update fee message who originally submitted the deposit. If the deposit doesn't
     * exist, then the relayer will not be able to fill any relay, so the caller should validate that the depositor
     * did in fact submit a relay.
     * @param newRelayerFeePct New relayer fee that relayers can use.
     * @param depositId Deposit to update fee for that originated in this contract.
     * @param depositorSignature Signed message containing the depositor address, this contract chain ID, the updated
     * relayer fee %, and the deposit ID. This signature is produced by signing a hash of data according to the
     * EIP-1271 standard. See more in the _verifyUpdateRelayerFeeMessage() comments.
     */
    function speedUpDeposit(
        address depositor,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) public override nonReentrant {
        require(newRelayerFeePct < 0.5e18, "invalid relayer fee");

        _verifyUpdateRelayerFeeMessage(depositor, chainId(), newRelayerFeePct, depositId, depositorSignature);

        // Assuming the above checks passed, a relayer can take the signature and the updated relayer fee information
        // from the following event to submit a fill with an updated fee %.
        emit RequestedSpeedUpDeposit(newRelayerFeePct, depositId, depositor, depositorSignature);
    }

    /**************************************
     *         RELAYER FUNCTIONS          *
     **************************************/

    /**
     * @notice Called by relayer to fulfill part of a deposit by sending destination tokens to the recipient.
     * Relayer is expected to pass in unique identifying information for deposit that they want to fulfill, and this
     * relay submission will be validated by off-chain data workers who can dispute this relay if any part is invalid.
     * If the relay is valid, then the relayer will be refunded on their desired repayment chain. If relay is invalid,
     * then relayer will not receive any refund.
     * @notice All of the deposit data can be found via on-chain events from the origin SpokePool, except for the
     * realizedLpFeePct which is a function of the HubPool's utilization at the deposit quote time. This fee %
     * is deterministic based on the quote time, so the relayer should just compute it using the canonical algorithm
     * as described in a UMIP linked to the HubPool's identifier.
     * @param depositor Depositor on origin chain who set this chain as the destination chain.
     * @param recipient Specified recipient on this chain.
     * @param destinationToken Token to send to recipient. Should be mapped to the origin token, origin chain ID
     * and this chain ID via a mapping on the HubPool.
     * @param amount Full size of the deposit.
     * @param maxTokensToSend Max amount of tokens to send recipient. If higher than amount, then caller will
     * send recipient the full relay amount.
     * @param repaymentChainId Chain of SpokePool where relayer wants to be refunded after the challenge window has
     * passed.
     * @param originChainId Chain of SpokePool where deposit originated.
     * @param realizedLpFeePct Fee % based on L1 HubPool utilization at deposit quote time. Deterministic based on
     * quote time.
     * @param relayerFeePct Fee % to keep as relayer, specified by depositor.
     * @param depositId Unique deposit ID on origin spoke pool.
     */
    function fillRelay(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId
    ) public nonReentrant {
        // Each relay attempt is mapped to the hash of data uniquely identifying it, which includes the deposit data
        // such as the origin chain ID and the deposit ID, and the data in a relay attempt such as who the recipient
        // is, which chain and currency the recipient wants to receive funds on, and the relay fees.
        SpokePoolInterface.RelayData memory relayData = SpokePoolInterface.RelayData({
            depositor: depositor,
            recipient: recipient,
            destinationToken: destinationToken,
            amount: amount,
            realizedLpFeePct: realizedLpFeePct,
            relayerFeePct: relayerFeePct,
            depositId: depositId,
            originChainId: originChainId,
            destinationChainId: chainId()
        });
        bytes32 relayHash = _getRelayHash(relayData);

        uint256 fillAmountPreFees = _fillRelay(relayHash, relayData, maxTokensToSend, relayerFeePct, false);

        _emitFillRelay(relayHash, fillAmountPreFees, repaymentChainId, relayerFeePct, relayData, false);
    }

    /**
     * @notice Called by relayer to execute same logic as calling fillRelay except that relayer is using an updated
     * relayer fee %. The fee % must have been emitted in a message cryptographically signed by the depositor.
     * @notice By design, the depositor probably emitted the message with the updated fee by calling speedUpRelay().
     * @param depositor Depositor on origin chain who set this chain as the destination chain.
     * @param recipient Specified recipient on this chain.
     * @param destinationToken Token to send to recipient. Should be mapped to the origin token, origin chain ID
     * and this chain ID via a mapping on the HubPool.
     * @param amount Full size of the deposit.
     * @param maxTokensToSend Max amount of tokens to send recipient. If higher than amount, then caller will
     * send recipient the full relay amount.
     * @param repaymentChainId Chain of SpokePool where relayer wants to be refunded after the challenge window has
     * passed.
     * @param originChainId Chain of SpokePool where deposit originated.
     * @param realizedLpFeePct Fee % based on L1 HubPool utilization at deposit quote time. Deterministic based on
     * quote time.
     * @param relayerFeePct Original fee % to keep as relayer set by depositor.
     * @param newRelayerFeePct New fee % to keep as relayer also specified by depositor.
     * @param depositId Unique deposit ID on origin spoke pool.
     * @param depositorSignature Depositor-signed message containing updated fee %.
     */
    function fillRelayWithUpdatedFee(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) public override nonReentrant {
        _verifyUpdateRelayerFeeMessage(depositor, originChainId, newRelayerFeePct, depositId, depositorSignature);

        // Now follow the default fillRelay flow with the updated fee and the original relay hash.
        RelayData memory relayData = RelayData({
            depositor: depositor,
            recipient: recipient,
            destinationToken: destinationToken,
            amount: amount,
            realizedLpFeePct: realizedLpFeePct,
            relayerFeePct: relayerFeePct,
            depositId: depositId,
            originChainId: originChainId,
            destinationChainId: chainId()
        });
        bytes32 relayHash = _getRelayHash(relayData);
        uint256 fillAmountPreFees = _fillRelay(relayHash, relayData, maxTokensToSend, newRelayerFeePct, false);

        _emitFillRelay(relayHash, fillAmountPreFees, repaymentChainId, newRelayerFeePct, relayData, false);
    }

    /**************************************
     *         DATA WORKER FUNCTIONS      *
     **************************************/

    /**
     * @notice Executes a slow relay leaf stored as part of a root bundle. Will send the full amount remaining in the
     * relay to the recipient, less fees.
     * @dev This function assumes that the relay's destination chain ID is the current chain ID, which prevents
     * the caller from executing a slow relay intended for another chain on this chain.
     * @param depositor Depositor on origin chain who set this chain as the destination chain.
     * @param recipient Specified recipient on this chain.
     * @param destinationToken Token to send to recipient. Should be mapped to the origin token, origin chain ID
     * and this chain ID via a mapping on the HubPool.
     * @param amount Full size of the deposit.
     * @param originChainId Chain of SpokePool where deposit originated.
     * @param realizedLpFeePct Fee % based on L1 HubPool utilization at deposit quote time. Deterministic based on
     * quote time.
     * @param relayerFeePct Original fee % to keep as relayer set by depositor.
     * @param depositId Unique deposit ID on origin spoke pool.
     * @param rootBundleId Unique ID of root bundle containing slow relay root that this leaf is contained in.
     * @param proof Inclusion proof for this leaf in slow relay root in root bundle.
     */
    function executeSlowRelayLeaf(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 rootBundleId,
        bytes32[] memory proof
    ) public virtual override nonReentrant {
        _executeSlowRelayLeaf(
            depositor,
            recipient,
            destinationToken,
            amount,
            originChainId,
            chainId(),
            realizedLpFeePct,
            relayerFeePct,
            depositId,
            rootBundleId,
            proof
        );
    }

    /**
     * @notice Executes a relayer refund leaf stored as part of a root bundle. Will send the relayer the amount they
     * sent to the recipient plus a relayer fee.
     * @param rootBundleId Unique ID of root bundle containing relayer refund root that this leaf is contained in.
     * @param relayerRefundLeaf Contains all data necessary to reconstruct leaf contained in root bundle and to
     * refund relayer. This data structure is explained in detail in the SpokePoolInterface.
     * @param proof Inclusion proof for this leaf in relayer refund root in root bundle.
     */
    function executeRelayerRefundLeaf(
        uint32 rootBundleId,
        SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf,
        bytes32[] memory proof
    ) public virtual override nonReentrant {
        _executeRelayerRefundLeaf(rootBundleId, relayerRefundLeaf, proof);
    }

    /**************************************
     *           VIEW FUNCTIONS           *
     **************************************/

    /**
     * @notice Returns chain ID for this network.
     * @dev Some L2s like ZKSync don't support the CHAIN_ID opcode so we allow the implementer to override this.
     */
    function chainId() public view virtual override returns (uint256) {
        return block.chainid;
    }

    /**************************************
     *         INTERNAL FUNCTIONS         *
     **************************************/

    // Verifies inclusion proof of leaf in root, sends relayer their refund, and sends to HubPool any rebalance
    // transfers.
    function _executeRelayerRefundLeaf(
        uint32 rootBundleId,
        SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf,
        bytes32[] memory proof
    ) internal {
        // Check integrity of leaf structure:
        require(relayerRefundLeaf.chainId == chainId(), "Invalid chainId");
        require(relayerRefundLeaf.refundAddresses.length == relayerRefundLeaf.refundAmounts.length, "invalid leaf");

        RootBundle storage rootBundle = rootBundles[rootBundleId];

        // Check that inclusionProof proves that relayerRefundLeaf is contained within the relayer refund root.
        // Note: This should revert if the relayerRefundRoot is uninitialized.
        require(MerkleLib.verifyRelayerRefund(rootBundle.relayerRefundRoot, relayerRefundLeaf, proof), "Bad Proof");

        // Verify the leafId in the leaf has not yet been claimed.
        require(!MerkleLib.isClaimed(rootBundle.claimedBitmap, relayerRefundLeaf.leafId), "Already claimed");

        // Set leaf as claimed in bitmap. This is passed by reference to the storage rootBundle.
        MerkleLib.setClaimed(rootBundle.claimedBitmap, relayerRefundLeaf.leafId);

        // Send each relayer refund address the associated refundAmount for the L2 token address.
        // Note: Even if the L2 token is not enabled on this spoke pool, we should still refund relayers.
        uint256 length = relayerRefundLeaf.refundAmounts.length;
        for (uint256 i = 0; i < length; ) {
            uint256 amount = relayerRefundLeaf.refundAmounts[i];
            if (amount > 0)
                IERC20(relayerRefundLeaf.l2TokenAddress).safeTransfer(relayerRefundLeaf.refundAddresses[i], amount);

            // OK because we assume refund array length won't be > types(uint256).max.
            // Based on the stress test results in /test/gas-analytics/SpokePool.RelayerRefundLeaf.ts, the UMIP should
            // limit the refund count in valid proposals to be ~800 so any RelayerRefundLeaves with > 800 refunds should
            // not make it to this stage.

            unchecked {
                ++i;
            }
        }

        // If leaf's amountToReturn is positive, then send L2 --> L1 message to bridge tokens back via
        // chain-specific bridging method.
        if (relayerRefundLeaf.amountToReturn > 0) {
            _bridgeTokensToHubPool(relayerRefundLeaf);

            emit TokensBridged(
                relayerRefundLeaf.amountToReturn,
                relayerRefundLeaf.chainId,
                relayerRefundLeaf.leafId,
                relayerRefundLeaf.l2TokenAddress,
                msg.sender
            );
        }

        emit ExecutedRelayerRefundRoot(
            relayerRefundLeaf.amountToReturn,
            relayerRefundLeaf.chainId,
            relayerRefundLeaf.refundAmounts,
            rootBundleId,
            relayerRefundLeaf.leafId,
            relayerRefundLeaf.l2TokenAddress,
            relayerRefundLeaf.refundAddresses,
            msg.sender
        );
    }

    // Verifies inclusion proof of leaf in root and sends recipient remainder of relay. Marks relay as filled.
    function _executeSlowRelayLeaf(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 originChainId,
        uint256 destinationChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 rootBundleId,
        bytes32[] memory proof
    ) internal {
        RelayData memory relayData = RelayData({
            depositor: depositor,
            recipient: recipient,
            destinationToken: destinationToken,
            amount: amount,
            originChainId: originChainId,
            destinationChainId: destinationChainId,
            realizedLpFeePct: realizedLpFeePct,
            relayerFeePct: relayerFeePct,
            depositId: depositId
        });

        require(
            MerkleLib.verifySlowRelayFulfillment(rootBundles[rootBundleId].slowRelayRoot, relayData, proof),
            "Invalid proof"
        );

        bytes32 relayHash = _getRelayHash(relayData);

        // Note: use relayAmount as the max amount to send, so the relay is always completely filled by the contract's
        // funds in all cases. As this is a slow relay we set the relayerFeePct to 0. This effectively refunds the
        // relayer component of the relayerFee thereby only charging the depositor the LpFee.
        uint256 fillAmountPreFees = _fillRelay(relayHash, relayData, relayData.amount, 0, true);

        // Note: Set repayment chain ID to 0 to indicate that there is no repayment to be made. The off-chain data
        // worker can use repaymentChainId=0 as a signal to ignore such relays for refunds. Also, set the relayerFeePct
        // to 0 as slow relays do not pay the caller of this method (depositor is refunded this fee).
        _emitFillRelay(relayHash, fillAmountPreFees, 0, 0, relayData, true);
    }

    function _setCrossDomainAdmin(address newCrossDomainAdmin) internal {
        require(newCrossDomainAdmin != address(0), "Bad bridge router address");
        crossDomainAdmin = newCrossDomainAdmin;
        emit SetXDomainAdmin(newCrossDomainAdmin);
    }

    function _setHubPool(address newHubPool) internal {
        require(newHubPool != address(0), "Bad hub pool address");
        hubPool = newHubPool;
        emit SetHubPool(newHubPool);
    }

    // Should be overriden by implementing contract depending on how L2 handles sending tokens to L1.
    function _bridgeTokensToHubPool(SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf) internal virtual;

    function _verifyUpdateRelayerFeeMessage(
        address depositor,
        uint256 originChainId,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) internal view {
        // A depositor can request to speed up an un-relayed deposit by signing a hash containing the relayer
        // fee % to update to and information uniquely identifying the deposit to relay. This information ensures
        // that this signature cannot be re-used for other deposits. The version string is included as a precaution
        // in case this contract is upgraded.
        // Note: we use encode instead of encodePacked because it is more secure, more in the "warning" section
        // here: https://docs.soliditylang.org/en/v0.8.11/abi-spec.html#non-standard-packed-mode
        bytes32 expectedDepositorMessageHash = keccak256(
            abi.encode("ACROSS-V2-FEE-1.0", newRelayerFeePct, depositId, originChainId)
        );

        // Check the hash corresponding to the https://eth.wiki/json-rpc/API#eth_sign[eth_sign]
        // If the depositor signed a message with a different updated fee (or any other param included in the
        // above keccak156 hash), then this will revert.
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(expectedDepositorMessageHash);

        _verifyDepositorUpdateFeeMessage(depositor, ethSignedMessageHash, depositorSignature);
    }

    // This function is isolated and made virtual to allow different L2's to implement chain specific recovery of
    // signers from signatures because some L2s might not support ecrecover. To be safe, consider always reverting
    // this function for L2s where ecrecover is different from how it works on Ethereum, otherwise there is the
    // potential to forge a signature from the depositor using a different private key than the original depositor's.
    function _verifyDepositorUpdateFeeMessage(
        address depositor,
        bytes32 ethSignedMessageHash,
        bytes memory depositorSignature
    ) internal view virtual {
        // Note: We purposefully do not support EIP-1271 signatures (meaning that multisigs and smart contract wallets
        // like Argent are not supported) because of the possibility that a multisig that signed a message on the origin
        // chain does not have a parallel on this destination chain.
        require(depositor == ECDSA.recover(ethSignedMessageHash, depositorSignature), "invalid signature");
    }

    function _computeAmountPreFees(uint256 amount, uint64 feesPct) private pure returns (uint256) {
        return (1e18 * amount) / (1e18 - feesPct);
    }

    function _computeAmountPostFees(uint256 amount, uint64 feesPct) private pure returns (uint256) {
        return (amount * (1e18 - feesPct)) / 1e18;
    }

    function _getRelayHash(SpokePoolInterface.RelayData memory relayData) private pure returns (bytes32) {
        return keccak256(abi.encode(relayData));
    }

    // Unwraps ETH and does a transfer to a recipient address. If the recipient is a smart contract then sends wrappedNativeToken.
    function _unwrapwrappedNativeTokenTo(address payable to, uint256 amount) internal {
        if (address(to).isContract()) {
            IERC20(address(wrappedNativeToken)).safeTransfer(to, amount);
        } else {
            wrappedNativeToken.withdraw(amount);
            to.transfer(amount);
        }
    }

    /**
     * @notice Caller specifies the max amount of tokens to send to user. Based on this amount and the amount of the
     * relay remaining (as stored in the relayFills mapping), pull the amount of tokens from the caller
     * and send to the recipient.
     * @dev relayFills keeps track of pre-fee fill amounts as a convenience to relayers who want to specify round
     * numbers for the maxTokensToSend parameter or convenient numbers like 100 (i.e. relayers who will fully
     * fill any relay up to 100 tokens, and partial fill with 100 tokens for larger relays).
     * @dev Caller must approve this contract to transfer up to maxTokensToSend of the relayData.destinationToken.
     * The amount to be sent might end up less if there is insufficient relay amount remaining to be sent.
     */
    function _fillRelay(
        bytes32 relayHash,
        RelayData memory relayData,
        uint256 maxTokensToSend,
        uint64 updatableRelayerFeePct,
        bool useContractFunds
    ) internal returns (uint256 fillAmountPreFees) {
        // We limit the relay fees to prevent the user spending all their funds on fees. Note that 0.5e18 (i.e. 50%)
        // fees are just magic numbers. The important point is to prevent the total fee from being 100%, otherwise
        // computing the amount pre fees runs into divide-by-0 issues.
        require(updatableRelayerFeePct < 0.5e18 && relayData.realizedLpFeePct < 0.5e18, "invalid fees");

        // Check that the relay has not already been completely filled. Note that the relays mapping will point to
        // the amount filled so far for a particular relayHash, so this will start at 0 and increment with each fill.
        require(relayFills[relayHash] < relayData.amount, "relay filled");

        // Stores the equivalent amount to be sent by the relayer before fees have been taken out.
        if (maxTokensToSend == 0) return 0;

        // Derive the amount of the relay filled if the caller wants to send exactly maxTokensToSend tokens to
        // the recipient. For example, if the user wants to send 10 tokens to the recipient, the full relay amount
        // is 100, and the fee %'s total 5%, then this computation would return ~10.5, meaning that to fill 10.5/100
        // of the full relay size, the caller would need to send 10 tokens to the user.
        fillAmountPreFees = _computeAmountPreFees(
            maxTokensToSend,
            (relayData.realizedLpFeePct + updatableRelayerFeePct)
        );
        // If user's specified max amount to send is greater than the amount of the relay remaining pre-fees,
        // we'll pull exactly enough tokens to complete the relay.
        uint256 amountToSend = maxTokensToSend;
        uint256 amountRemainingInRelay = relayData.amount - relayFills[relayHash];
        if (amountRemainingInRelay < fillAmountPreFees) {
            fillAmountPreFees = amountRemainingInRelay;

            // The user will fulfill the remainder of the relay, so we need to compute exactly how many tokens post-fees
            // that they need to send to the recipient. Note that if the relayer is filled using contract funds then
            // this is a slow relay.
            amountToSend = _computeAmountPostFees(
                fillAmountPreFees,
                relayData.realizedLpFeePct + updatableRelayerFeePct
            );
        }

        // relayFills keeps track of pre-fee fill amounts as a convenience to relayers who want to specify round
        // numbers for the maxTokensToSend parameter or convenient numbers like 100 (i.e. relayers who will fully
        // fill any relay up to 100 tokens, and partial fill with 100 tokens for larger relays).
        relayFills[relayHash] += fillAmountPreFees;

        // If relay token is wrappedNativeToken then unwrap and send native token.
        if (relayData.destinationToken == address(wrappedNativeToken)) {
            // Note: useContractFunds is True if we want to send funds to the recipient directly out of this contract,
            // otherwise we expect the caller to send funds to the recipient. If useContractFunds is True and the
            // recipient wants wrappedNativeToken, then we can assume that wrappedNativeToken is already in the
            // contract, otherwise we'll need the user to send wrappedNativeToken to this contract. Regardless, we'll
            // need to unwrap it to native token before sending to the user.
            if (!useContractFunds)
                IERC20(relayData.destinationToken).safeTransferFrom(msg.sender, address(this), amountToSend);
            _unwrapwrappedNativeTokenTo(payable(relayData.recipient), amountToSend);
            // Else, this is a normal ERC20 token. Send to recipient.
        } else {
            // Note: Similar to note above, send token directly from the contract to the user in the slow relay case.
            if (!useContractFunds)
                IERC20(relayData.destinationToken).safeTransferFrom(msg.sender, relayData.recipient, amountToSend);
            else IERC20(relayData.destinationToken).safeTransfer(relayData.recipient, amountToSend);
        }
    }

    // The following internal methods emit events with many params to overcome solidity stack too deep issues.
    function _emitFillRelay(
        bytes32 relayHash,
        uint256 fillAmount,
        uint256 repaymentChainId,
        uint64 appliedRelayerFeePct,
        RelayData memory relayData,
        bool isSlowRelay
    ) internal {
        emit FilledRelay(
            relayData.amount,
            relayFills[relayHash],
            fillAmount,
            repaymentChainId,
            relayData.originChainId,
            relayData.destinationChainId,
            relayData.relayerFeePct,
            appliedRelayerFeePct,
            relayData.realizedLpFeePct,
            relayData.depositId,
            relayData.destinationToken,
            msg.sender,
            relayData.depositor,
            relayData.recipient,
            isSlowRelay
        );
    }

    function _emitDeposit(
        uint256 amount,
        uint256 originChainId,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 quoteTimestamp,
        address originToken,
        address recipient,
        address depositor
    ) internal {
        emit FundsDeposited(
            amount,
            originChainId,
            destinationChainId,
            relayerFeePct,
            depositId,
            quoteTimestamp,
            originToken,
            recipient,
            depositor
        );
    }

    // Implementing contract needs to override this to ensure that only the appropriate cross chain admin can execute
    // certain admin functions. For L2 contracts, the cross chain admin refers to some L1 address or contract, and for
    // L1, this would just be the same admin of the HubPool.
    function _requireAdminSender() internal virtual;

    // Added to enable the this contract to receive native token (ETH). Used when unwrapping wrappedNativeToken.
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Contains common data structures and functions used by all SpokePool implementations.
 */
interface SpokePoolInterface {
    // This leaf is meant to be decoded in the SpokePool to pay out successful relayers.
    struct RelayerRefundLeaf {
        // This is the amount to return to the HubPool. This occurs when there is a PoolRebalanceLeaf netSendAmount that
        // is negative. This is just the negative of this value.
        uint256 amountToReturn;
        // Used to verify that this is being executed on the correct destination chainId.
        uint256 chainId;
        // This array designates how much each of those addresses should be refunded.
        uint256[] refundAmounts;
        // Used as the index in the bitmap to track whether this leaf has been executed or not.
        uint32 leafId;
        // The associated L2TokenAddress that these claims apply to.
        address l2TokenAddress;
        // Must be same length as refundAmounts and designates each address that must be refunded.
        address[] refundAddresses;
    }

    // This struct represents the data to fully specify a relay. If any portion of this data differs, the relay is
    // considered to be completely distinct. Only one relay for a particular depositId, chainId pair should be
    // considered valid and repaid. This data is hashed and inserted into the slow relay merkle root so that an off
    // chain validator can choose when to refund slow relayers.
    struct RelayData {
        // The address that made the deposit on the origin chain.
        address depositor;
        // The recipient address on the destination chain.
        address recipient;
        // The corresponding token address on the destination chain.
        address destinationToken;
        // The total relay amount before fees are taken out.
        uint256 amount;
        // Origin chain id.
        uint256 originChainId;
        // Destination chain id.
        uint256 destinationChainId;
        // The LP Fee percentage computed by the relayer based on the deposit's quote timestamp
        // and the HubPool's utilization.
        uint64 realizedLpFeePct;
        // The relayer fee percentage specified in the deposit.
        uint64 relayerFeePct;
        // The id uniquely identifying this deposit on the origin chain.
        uint32 depositId;
    }

    // Stores collection of merkle roots that can be published to this contract from the HubPool, which are referenced
    // by "data workers" via inclusion proofs to execute leaves in the roots.
    struct RootBundle {
        // Merkle root of slow relays that were not fully filled and whose recipient is still owed funds from the LP pool.
        bytes32 slowRelayRoot;
        // Merkle root of relayer refunds for successful relays.
        bytes32 relayerRefundRoot;
        // This is a 2D bitmap tracking which leaves in the relayer refund root have been claimed, with max size of
        // 256x(2^248) leaves per root.
        mapping(uint256 => uint256) claimedBitmap;
    }

    function setCrossDomainAdmin(address newCrossDomainAdmin) external;

    function setHubPool(address newHubPool) external;

    function setEnableRoute(
        address originToken,
        uint256 destinationChainId,
        bool enable
    ) external;

    function setDepositQuoteTimeBuffer(uint32 buffer) external;

    function relayRootBundle(bytes32 relayerRefundRoot, bytes32 slowRelayRoot) external;

    function emergencyDeleteRootBundle(uint256 rootBundleId) external;

    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;

    function speedUpDeposit(
        address depositor,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) external;

    function fillRelay(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId
    ) external;

    function fillRelayWithUpdatedFee(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) external;

    function executeSlowRelayLeaf(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 rootBundleId,
        bytes32[] memory proof
    ) external;

    function executeRelayerRefundLeaf(
        uint32 rootBundleId,
        SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf,
        bytes32[] memory proof
    ) external;

    function chainId() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Sends cross chain messages and tokens to contracts on a specific L2 network.
 */

interface AdapterInterface {
    event MessageRelayed(address target, bytes message);

    event TokensRelayed(address l1Token, address l2Token, uint256 amount, address to);

    function relayMessage(address target, bytes calldata message) external payable;

    function relayTokens(
        address l1Token,
        address l2Token,
        uint256 amount,
        address to
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface WETH9 {
    function withdraw(uint256 wad) external;

    function deposit() external payable;

    function balanceOf(address guy) external view returns (uint256 wad);

    function transfer(address guy, uint256 wad) external;
}