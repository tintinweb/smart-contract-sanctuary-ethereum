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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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

pragma solidity =0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// OpenOrders.DAO interfaces
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IStrategyManager} from "./interfaces/IStrategyManager.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {ISynchronousStrategy} from "./interfaces/ISynchronousStrategy.sol";
import {IAsynchronousStrategy} from "./interfaces/IAsynchronousStrategy.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";

// OpenOrders.DAO libs
import {Orders} from "./libraries/Orders.sol";
import {SignatureChecker} from "./libraries/SignatureChecker.sol";

/**
 * @title OpenOrdersDAOExchangeV0
 * @notice Universal exchange contract for decentralized orders
 *  _______                   _______          _                  ______  _______ _______
 * (_______)                 (_______)        | |                (______)(_______|_______)
 *  _     _ ____  _____ ____  _     _  ____ __| |_____  ____ ___  _     _ _______ _     _
 * | |   | |  _ \| ___ |  _ \| |   | |/ ___) _  | ___ |/ ___)___)| |   | |  ___  | |   | |
 * | |___| | |_| | ____| | | | |___| | |  ( (_| | ____| |  |___ || |__/ /| |   | | |___| |
 *  \_____/|  __/|_____)_| |_|\_____/|_|   \____|_____)_|  (___(_)_____/ |_|   |_|\_____/
 *         |_|
 */

contract OpenOrdersDAOExchangeV0 is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    using Orders for Orders.MakerOrder;
    using Orders for Orders.TakerOrder;
    using Orders for Orders.BrokerFee;

    bytes32 internal immutable _DOMAIN_SEPARATOR;
    uint256 internal immutable _CACHED_CHAIN_ID;

    address public protocolFeeRecipient;

    ICurrencyManager public currencyManager;
    IStrategyManager public strategyManager;
    IRoyaltyFeeManager public royaltyFeeManager;
    ITransferSelectorNFT public transferSelectorNFT;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) public isFullyExecutedOrCancelled;

    mapping(address => mapping(uint256 => bytes32)) public partialExecutedNonces;
    mapping(bytes32 => uint256) public partialExecutedAmounts;

    mapping(bytes32 => Orders.TakerOrder) public bestTakerBid;
    mapping(bytes32 => Orders.TakerOrder) public bestTakerAsk;

    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    event NewCurrencyManager(address indexed currencyManager);
    event NewStrategyManager(address indexed strategyManager);
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    event BrokerFeePayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed brokerFeeReceiver,
        address currency,
        uint256 amount
    );

    event TakerAsk(
        bytes32 orderHash, // bid hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed taker, // sender address for the taker ask order
        address indexed maker, // maker address of the initial bid order
        address indexed strategy, // strategy that defines the execution
        address currency, // currency address
        address collection, // collection address
        uint256 tokenId, // tokenId transferred
        uint256 amount, // amount of tokens transferred
        uint256 price, // final transacted price
        bool partialExecution // whether the original maker order was only partially fulfilled
    );

    event TakerBid(
        bytes32 orderHash, // ask hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed taker, // sender address for the taker bid order
        address indexed maker, // maker address of the initial ask order
        address indexed strategy, // strategy that defines the execution
        address currency, // currency address
        address collection, // collection address
        uint256 tokenId, // tokenId transferred
        uint256 amount, // amount of tokens transferred
        uint256 price, // final transacted price
        bool partialExecution // whether the original maker order was only partially fulfilled
    );

    constructor(
        address _currencyManager,
        address _strategyManager,
        address _royaltyFeeManager
    ) {
        _CACHED_CHAIN_ID = block.chainid;

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256("OpenOrdersDAOExchangeV0"),
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1"))
                block.chainid,
                address(this)
            )
        );

        currencyManager = ICurrencyManager(_currencyManager);
        strategyManager = IStrategyManager(_strategyManager);
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        bytes32 domainSeparator;
        if (_CACHED_CHAIN_ID == block.chainid) domainSeparator = _DOMAIN_SEPARATOR;
        else {
            domainSeparator = keccak256(
                abi.encode(
                    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256("OpenOrdersDAOExchangeV0"),
                    0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1"))
                    block.chainid,
                    address(this)
                )
            );
        }
        return domainSeparator;
    }

    /**
     * @notice Cancel all pending orders for a sender
     * @param minNonce minimum user nonce
     */
    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(minNonce > userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
        require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cancel: Cannot cancel more orders");
        userMinOrderNonce[msg.sender] = minNonce;

        emit CancelAllOrders(msg.sender, minNonce);
    }

    /**
     * @notice Cancel maker orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) external {
        require(orderNonces.length > 0, "Cancel: Cannot be empty");

        for (uint256 i = 0; i < orderNonces.length; i++) {
            require(orderNonces[i] >= userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
            isFullyExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
        }

        emit CancelMultipleOrders(msg.sender, orderNonces);
    }

    /**
     * @notice Match a takerBid with a matchAsk
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     */
    function matchAskWithTakerBid(Orders.TakerOrder calldata takerBid, Orders.MakerOrder calldata makerAsk)
        external
        nonReentrant
    {
        require((makerAsk.isAsk) && (!takerBid.isAsk), "Order: Wrong sides");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        bool isFullyExecuted;
        uint256 tokenId;
        uint256 amount;
        uint256 price;

        {
            // Check if requested amount can be fulfilled
            uint256 _amountFilled = partialExecutedAmounts[askHash];
            require(_amountFilled + takerBid.amount <= makerAsk.amount, "Order: Requested amount cannot be fulfilled");

            // Check with strategy
            (bool isExecutionValid, uint256 _tokenId, uint256 _amount, uint256 _price) = ISynchronousStrategy(
                makerAsk.strategy
            ).canExecuteTakerBid(takerBid, makerAsk);

            require(isExecutionValid, "Strategy: Execution invalid");

            tokenId = _tokenId;
            amount = _amount;
            price = _price;
            isFullyExecuted = (_amountFilled + amount == makerAsk.amount);

            if (isFullyExecuted) {
                // Update maker ask order status to true (prevents replay)
                isFullyExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;
            } else {
                // Mark order as partially executed to prevent nonce collisions
                partialExecutedNonces[makerAsk.signer][makerAsk.nonce] = askHash;
                partialExecutedAmounts[askHash] = _amountFilled + amount;
            }
        }

        // Execution part 1/2
        _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            price,
            makerAsk.minPercentageToAsk,
            makerAsk.brokerFee
        );

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            price,
            (!isFullyExecuted)
        );
    }

    /**
     * @notice Match a takerAsk with a makerBid
     * @param takerAsk taker ask order
     * @param makerBid maker bid order
     */
    function matchBidWithTakerAsk(Orders.TakerOrder calldata takerAsk, Orders.MakerOrder calldata makerBid)
        external
        nonReentrant
    {
        require((!makerBid.isAsk) && (takerAsk.isAsk), "Order: Wrong sides");
        require(msg.sender == takerAsk.taker, "Order: Taker must be the sender");

        // Check the maker bid order
        bytes32 bidHash = makerBid.hash();
        _validateOrder(makerBid, bidHash);

        uint256 tokenId;
        uint256 amount;
        uint256 price;
        bool isFullyExecuted;

        {
            // Check if requested amount can be fulfilled
            uint256 _amountFilled = partialExecutedAmounts[bidHash];
            require(_amountFilled + takerAsk.amount <= makerBid.amount, "Order: Requested amount cannot be fulfilled");

            (bool isExecutionValid, uint256 _tokenId, uint256 _amount, uint256 _price) = ISynchronousStrategy(
                makerBid.strategy
            ).canExecuteTakerAsk(takerAsk, makerBid);

            require(isExecutionValid, "Strategy: Execution invalid");

            tokenId = _tokenId;
            amount = _amount;
            price = _price;
            isFullyExecuted = (_amountFilled + amount == makerBid.amount);

            if (isFullyExecuted) {
                // Update maker ask order status to true (prevents replay)
                isFullyExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;
            } else {
                // Mark order as partially executed to prevent nonce collisions
                partialExecutedNonces[makerBid.signer][makerBid.nonce] = bidHash;
                partialExecutedAmounts[bidHash] = _amountFilled + amount;
            }
        }

        // Execution part 1/2
        _transferNonFungibleToken(makerBid.collection, msg.sender, makerBid.signer, tokenId, amount);

        // Execution part 2/2
        _transferFeesAndFunds(
            makerBid.strategy,
            makerBid.collection,
            tokenId,
            makerBid.currency,
            makerBid.signer,
            takerAsk.taker,
            price,
            takerAsk.minPercentageToAsk,
            takerAsk.brokerFee
        );

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            takerAsk.taker,
            makerBid.signer,
            makerBid.strategy,
            makerBid.currency,
            makerBid.collection,
            tokenId,
            amount,
            price,
            (!isFullyExecuted)
        );
    }

    function submitTakerBid(Orders.TakerOrder calldata takerBid, Orders.MakerOrder calldata makerAsk)
        external
        nonReentrant
        returns (bool)
    {
        require((makerAsk.isAsk) && (!takerBid.isAsk), "Order: Wrong sides");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        // Check with strategy
        Orders.TakerOrder memory bestBid = bestTakerBid[askHash];
        bool isBetterBid = IAsynchronousStrategy(makerAsk.strategy).canReplaceCurrentBestTakerBid(
            takerBid,
            makerAsk,
            bestBid
        );

        if (isBetterBid) bestTakerBid[askHash] = takerBid;
        return isBetterBid;
    }

    function submitTakerAsk(Orders.TakerOrder calldata takerAsk, Orders.MakerOrder calldata makerBid)
        external
        nonReentrant
        returns (bool)
    {
        require((!makerBid.isAsk) && (takerAsk.isAsk), "Order: Wrong sides");
        require(msg.sender == takerAsk.taker, "Order: Taker must be the sender");

        // Check the maker bid order
        bytes32 bidHash = makerBid.hash();
        _validateOrder(makerBid, bidHash);

        // Check with strategy
        Orders.TakerOrder memory bestAsk = bestTakerAsk[bidHash];
        bool isBetterAsk = IAsynchronousStrategy(makerBid.strategy).canReplaceCurrentBestTakerAsk(
            takerAsk,
            makerBid,
            bestAsk
        );

        if (isBetterAsk) bestTakerAsk[bidHash] = takerAsk;
        return isBetterAsk;
    }

    function settleBestTakerBid(Orders.MakerOrder calldata makerAsk) public nonReentrant {
        require((makerAsk.isAsk), "Order: Wrong side");
        // Check the maker ask order
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        // Check with strategy
        Orders.TakerOrder memory bestBid = bestTakerBid[askHash];
        (bool canSettleBid, uint256 tokenId, uint256 amount, uint256 price) = IAsynchronousStrategy(makerAsk.strategy)
            .canSettleTakerBid(bestBid, makerAsk);

        require(canSettleBid, "Strategy: Can not settle");

        // Execution part 1/2
        _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            price,
            makerAsk.minPercentageToAsk,
            makerAsk.brokerFee
        );

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, bestBid.taker, tokenId, amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            bestBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            price,
            (false)
        );
    }

    function settleBestTakerAsk(Orders.MakerOrder calldata makerBid) public nonReentrant {
        require((!makerBid.isAsk), "Order: Wrong side");
        // Check the maker ask order
        bytes32 bidHash = makerBid.hash();
        _validateOrder(makerBid, bidHash);

        // Check with strategy
        Orders.TakerOrder memory bestAsk = bestTakerAsk[bidHash];
        (bool canSettleAsk, uint256 tokenId, uint256 amount, uint256 price) = IAsynchronousStrategy(makerBid.strategy)
            .canSettleTakerBid(bestAsk, makerBid);

        require(canSettleAsk, "Strategy: Can not settle");

        // Execution part 1/2
        _transferNonFungibleToken(makerBid.collection, msg.sender, makerBid.signer, tokenId, amount);

        // Execution part 2/2
        _transferFeesAndFunds(
            makerBid.strategy,
            makerBid.collection,
            tokenId,
            makerBid.currency,
            makerBid.signer,
            bestAsk.taker,
            price,
            bestAsk.minPercentageToAsk,
            bestAsk.brokerFee
        );

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            bestAsk.taker,
            makerBid.signer,
            makerBid.strategy,
            makerBid.currency,
            makerBid.collection,
            tokenId,
            amount,
            price,
            (false)
        );
    }

    /**
     * @notice Update currency manager
     * @param _currencyManager new currency manager address
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Owner: Cannot be null address");
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    /**
     * @notice Update strategy manager
     * @param _strategyManager new strategy manager address
     */
    function updatestrategyManager(address _strategyManager) external onlyOwner {
        require(_strategyManager != address(0), "Owner: Cannot be null address");
        strategyManager = IStrategyManager(_strategyManager);
        emit NewStrategyManager(_strategyManager);
    }

    /**
     * @notice Update transfer selector NFT
     * @param _transferSelectorNFT new transfer selector address
     */
    function updateTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Owner: Cannot be null address");
        transferSelectorNFT = ITransferSelectorNFT(_transferSelectorNFT);

        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

    /**
     * @notice Update protocol fee and recipient
     * @param _protocolFeeRecipient new recipient for protocol fees
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice Verify the validity of the maker order
     * @param makerOrder maker order
     * @param orderHash computed hash for the order
     */
    function _validateOrder(Orders.MakerOrder calldata makerOrder, bytes32 orderHash) internal view {
        // Verify whether order nonce has expired
        require(
            (!isFullyExecutedOrCancelled[makerOrder.signer][makerOrder.nonce]) &&
                (makerOrder.nonce >= userMinOrderNonce[makerOrder.signer]),
            "Order: Matching order expired"
        );

        // Verify whether a different order with the same nonce is partially fulfilled
        require(
            partialExecutedNonces[makerOrder.signer][makerOrder.nonce] == 0x0 ||
                partialExecutedNonces[makerOrder.signer][makerOrder.nonce] == orderHash,
            "Order: Different order with same nonce partially fulfilled"
        );

        // Verify the signer is not address(0)
        require(makerOrder.signer != address(0), "Order: Invalid signer");

        // Verify the amount is not 0
        require(makerOrder.amount > 0, "Order: Amount cannot be 0");

        // Verify the validity of the signature
        require(
            SignatureChecker.verify(orderHash, makerOrder.signer, makerOrder.signature, DOMAIN_SEPARATOR()),
            "Signature: Invalid"
        );

        // Verify whether the currency is whitelisted
        require(currencyManager.isCurrencyWhitelisted(makerOrder.currency), "Currency: Not whitelisted");

        // TODO: also pass current user so that we (in the future) are able to whitelist strategies per user
        // Verify whether strategy can be executed
        require(
            strategyManager.isStrategyWhitelisted(makerOrder.strategy, makerOrder.signer),
            "Strategy: Not whitelisted"
        );
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param strategy address of the execution strategy
     * @param collection non fungible token address for the transfer
     * @param tokenId tokenId
     * @param currency currency being used for the purchase (e.g., WETH/USDC)
     * @param from sender of the funds
     * @param to seller's recipient
     * @param amount amount being transferred (in currency)
     * @param minPercentageToAsk minimum percentage of the gross amount that goes to ask
     * @param brokerFeeAsk broker fee struct from ask side
     */
    function _transferFeesAndFunds(
        address strategy,
        address collection,
        uint256 tokenId,
        address currency,
        address from,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk,
        Orders.BrokerFee memory brokerFeeAsk
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = amount;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(strategy, amount);

            // Check if the protocol fee is different than 0 for this strategy
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                IERC20(currency).safeTransferFrom(from, protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Broker fee
        {
            if ((brokerFeeAsk.fee != 0) && (brokerFeeAsk.receiver != address(0))) {
                uint256 brokerFeeAmount = (brokerFeeAsk.fee * amount) / 10000;
                IERC20(currency).safeTransferFrom(from, brokerFeeAsk.receiver, brokerFeeAmount);
                finalSellerAmount -= brokerFeeAmount;

                emit BrokerFeePayment(collection, tokenId, brokerFeeAsk.receiver, currency, brokerFeeAmount);
            }
        }

        // 3. Royalty fee
        {
            (address payable[] memory royaltyFeeRecipients, uint256[] memory royaltyFeeAmounts) = royaltyFeeManager
                .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

            // Check if there is a royalty fee and that it is different to 0
            for (uint256 i = 0; i < royaltyFeeRecipients.length; i++) {
                IERC20(currency).safeTransferFrom(from, royaltyFeeRecipients[i], royaltyFeeAmounts[i]);
                finalSellerAmount -= royaltyFeeAmounts[i];

                emit RoyaltyPayment(collection, tokenId, royaltyFeeRecipients[i], currency, royaltyFeeAmounts[i]);
            }
        }

        require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "Fees: Higher than expected");

        // 4. Transfer final amount (post-fees) to seller
        {
            IERC20(currency).safeTransferFrom(from, to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer NFT
     * @param collection address of the token collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 for ERC721, 1+ for ERC1155)
     * @dev For ERC721, amount is not used
     */
    function _transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        // Retrieve the transfer manager address
        address transferManager = transferSelectorNFT.checkTransferManagerForToken(collection);

        // If no transfer manager found, it returns address(0)
        require(transferManager != address(0), "Transfer: No NFT transfer manager available");

        // If one is found, transfer the token
        ITransferManagerNFT(transferManager).transferNonFungibleToken(collection, from, to, tokenId, amount);
    }

    /**
     * @notice Calculate protocol fee for an execution strategy
     * @param executionStrategy strategy
     * @param amount amount to transfer
     */
    function _calculateProtocolFee(address executionStrategy, uint256 amount) internal view returns (uint256) {
        uint256 protocolFee = IStrategy(executionStrategy).viewProtocolFee();
        return (protocolFee * amount) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import {IStrategy} from "./IStrategy.sol";
import {Orders} from "../libraries/Orders.sol";

interface IAsynchronousStrategy is IStrategy {
    function canReplaceCurrentBestTakerAsk(
        Orders.TakerOrder calldata takerAsk,
        Orders.MakerOrder calldata makerBid,
        Orders.TakerOrder calldata bestTakerAsk
    ) external view returns (bool);

    function canReplaceCurrentBestTakerBid(
        Orders.TakerOrder calldata takerBid,
        Orders.MakerOrder calldata makerAsk,
        Orders.TakerOrder calldata bestTakerBid
    ) external view returns (bool);

    function canSettleTakerAsk(Orders.TakerOrder calldata bestTakerAsk, Orders.MakerOrder calldata makerBid)
        external
        view
        returns (
            /** canExecute ask */
            bool,
            /** tokenId which the taker will receive */
            uint256,
            /** amountOfTokens which the taker will receive */
            uint256,
            /** total amount to pay in sum for all received tokens */
            uint256
        );

    function canSettleTakerBid(Orders.TakerOrder calldata bestTakerBid, Orders.MakerOrder calldata makerAsk)
        external
        view
        returns (
            /** canExecute bid */
            bool,
            /** tokenId which the taker will receive */
            uint256,
            /** amountOfTokens which the taker will receive */
            uint256,
            /** total amount to pay in sum for all received tokens */
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurrencyManager {
    function addCurrency(address currency) external;

    function removeCurrency(address currency) external;

    function isCurrencyWhitelisted(address currency) external view returns (bool);

    function viewWhitelistedCurrencies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedCurrencies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IStrategy {
    function viewProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IStrategyManager {
    function addStrategy(address strategy) external;

    function removeStrategy(address strategy) external;

    function isStrategyWhitelisted(address strategy, address user) external view returns (bool);

    function viewWhitelistedStrategies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedStrategies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import {IStrategy} from "./IStrategy.sol";
import {Orders} from "../libraries/Orders.sol";

interface ISynchronousStrategy is IStrategy {
    function canExecuteTakerAsk(Orders.TakerOrder calldata takerAsk, Orders.MakerOrder calldata makerBid)
        external
        view
        returns (
            /** canExecute ask */
            bool,
            /** tokenId which the taker will receive */
            uint256,
            /** amountOfTokens which the taker will receive */
            uint256,
            /** total amount to pay in sum for all received tokens */
            uint256
        );

    function canExecuteTakerBid(Orders.TakerOrder calldata takerBid, Orders.MakerOrder calldata makerAsk)
        external
        view
        returns (
            /** canExecute bid */
            bool,
            /** tokenId which the taker will receive */
            uint256,
            /** amountOfTokens which the taker will receive */
            uint256,
            /** total amount to pay in sum for all received tokens */
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ITransferManagerNFT {
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ITransferSelectorNFT {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

/**
 * Wording:
 *
 * MakerAsk (Sell Offer): OWNER whishes to SELL             <───────┐
 * MakerBid (Buy Offer): USER whishes to AQUIRE NFT          <───┐  │
 * TakerAsk (Accept Buy Offer): Counterpart of MakerBid      <───┘  │
 * TakerBid (Accept Sell Offer): Counterpart of MakerAsk    <───────┘
 */

library Orders {
    // keccak256("MakerOrder(bool isAsk,address signer,address collection,uint256 tokenId,uint256 amount,address currency,address strategy,bytes strategyParams,uint256 validFrom,uint256 validUntil,uint256 nonce,BrokerFee brokerFee,uint256 minPercentageToAsk)BrokerFee(uint256 fee,address receiver)")
    bytes32 internal constant MAKERORDER_TYPEHASH = 0xcac9e486395ffa4a33075176e6d3b42b568c59b6ee7e1743b5b2fd57db665ab4; // 0x8b6250d885c360e8aff79a8fc6a832b7f8b96a2b521b242df8ec79229bf32874;
    bytes32 internal constant BROKER_FEE_TYPEHASH = 0xc03efd31a241a3c6cdcc9afe195d45e9812d92c01d0cf464937aac1bb9bc590c;

    struct BrokerFee {
        uint256 fee; // 200 --> 2%
        address receiver; // wallet to receiver broker fee
    }

    struct MakerOrder {
        bool isAsk; // true --> MakerAsk; false --> MakerBid
        address signer; // acting wallet
        address collection; // nft collection address
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (always 1 for ERC721)
        address currency; // ERC20 token for payment; 0x for native token
        address strategy; // strategy to use (FixedPrice, EnglishAuction, DutchAuction)
        bytes strategyParams; // additional params for strategy
        uint256 validFrom; // unix timestamp in seconds
        uint256 validUntil; // unix timestamp in seconds
        uint256 nonce; // order nonce (must be unique unless new maker order is overriding existing one)
        // ATTENTION: Overriding an order by using the same nonce, does not invalidate the previous order.
        // Always cancel an order if you want to increase the desired sell price (MakerAsk) or want to reduce your offer (MakerBid)
        BrokerFee brokerFee; // struct of fee and receiving address of broker
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes signature; // Signature of MakerOrder.hash() by signer
    }

    struct TakerOrder {
        bool isAsk; // true --> TakerAsk; false --> TakerBid
        address taker; // acting wallet
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (always 1 for ERC721)
        bytes strategyParams; // additional params for strategy
        BrokerFee brokerFee; // struct of fee and receiving address of broker
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKERORDER_TYPEHASH,
                    makerOrder.isAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.currency,
                    makerOrder.strategy,
                    keccak256(makerOrder.strategyParams),
                    makerOrder.validFrom,
                    makerOrder.validUntil,
                    makerOrder.nonce,
                    hash(makerOrder.brokerFee),
                    makerOrder.minPercentageToAsk
                )
            );
    }

    function hash(BrokerFee memory brokerFee) internal pure returns (bytes32) {
        return keccak256(abi.encode(BROKER_FEE_TYPEHASH, brokerFee.fee, brokerFee.receiver));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SignatureChecker {
    function verify(
        bytes32 hash,
        address signer,
        bytes memory signature,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        bytes32 digest = ECDSA.toTypedDataHash(domainSeparator, hash);

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(digest, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}