// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: LBUSL-1.1-or-later
// Taken from: https://github.com/gnosis/safe-contracts/blob/development/contracts/proxies/GnosisSafeProxy.sol
pragma solidity >=0.7.0;

/// @title IWalletProxyImplementation - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IWalletProxyImplementation {
	function masterCopy() external view returns (address);

	function walletFactory() external view returns (address);

	function version() external view returns (uint256);

	function upgradeMasterCopy(address newMasterCopy) external;

	function initialize(
		address resolver_,
		string[2] calldata domain_,
		address owner_,
		address feeRecipient,
		uint256 feeAmount
	) external;
}

/// @title WalletProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract WalletProxy {
	// masterCopy and walletFactory always need to be the first declared variables, to ensure that they are at the same location in the contracts to which calls are delegated.
	// To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
	address internal masterCopy;
	address internal walletFactory;

	/// @dev Constructor function sets the address of walletFactory contract
	constructor() {
		walletFactory = msg.sender;
	}

	/// @param _masterCopy Master copy address.
	function initializeFromWalletFactory(address _masterCopy) external {
		require(msg.sender == walletFactory, "WalletProxy: Forbidden");
		require(
			_masterCopy != address(0),
			"Invalid master copy address provided"
		);
		masterCopy = _masterCopy;
	}

	/// @dev Fallback function forwards all transactions and returns all received return data.
	fallback() external payable {
		assembly {
			let _masterCopy := and(
				sload(0),
				0xffffffffffffffffffffffffffffffffffffffff
			)
			// 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
			if eq(
				calldataload(0),
				0xa619486e00000000000000000000000000000000000000000000000000000000
			) {
				mstore(0, _masterCopy)
				return(0, 0x20)
			}
			calldatacopy(0, 0, calldatasize())
			let success := delegatecall(
				gas(),
				_masterCopy,
				0,
				calldatasize(),
				0,
				0
			)
			returndatacopy(0, 0, returndatasize())
			if eq(success, 0) {
				revert(0, returndatasize())
			}
			return(0, returndatasize())
		}
	}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.7.6;

library Recovery {
	//
	// Private functions
	//

	//
	// HOTP Verification functions
	//
	function _deriveChildTreeIdx(uint256 merkleHeight, bytes32 sides)
		public
		pure
		returns (uint32)
	{
		uint32 derivedIdx = 0;
		for (uint8 i = 0; i < merkleHeight; i++) {
			if (bytes1(0x01) == sides[i]) {
				derivedIdx |= uint32(0x01) << i;
			}
		}
		return derivedIdx;
	}

	function _reduceConfirmMaterial(bytes32[] memory confirmMaterial)
		public
		pure
		returns (bytes32)
	{
		//  and then compute h(OTP) to get the leaf of the tree
		confirmMaterial[0] = keccak256(abi.encodePacked(confirmMaterial[0]));
		bytes32 sides = confirmMaterial[confirmMaterial.length - 1];
		return _reduceAuthPath(confirmMaterial, sides);
	}

	function _reduceAuthPath(bytes32[] memory authPath, bytes32 sides)
		internal
		pure
		returns (bytes32)
	{
		for (uint8 i = 1; i < authPath.length - 1; i++) {
			if (bytes1(0x00) == sides[i - 1]) {
				authPath[0] = keccak256(
					abi.encodePacked(authPath[0], authPath[i])
				);
			} else {
				authPath[0] = keccak256(
					abi.encodePacked(authPath[i], authPath[0])
				);
			}
		}
		//emit DebugEvent(authPath[0]);
		return authPath[0];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC1271 {
	/**
	 * @dev Should return whether the signature provided is valid for the provided hash
	 * @param _hash      Hash of the data to be signed
	 * @param _signature Signature byte array associated with _hash
	 *
	 * MUST return the bytes4 magic value 0x1626ba7e when function passes.
	 * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
	 * MUST allow external calls
	 */
	function isValidSignature(bytes32 _hash, bytes memory _signature)
		external
		view
		returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context {
	using Address for address;

	function isTrustedForwarder(address forwarder)
		public
		view
		virtual
		returns (bool)
	{
		return forwarder == address(this);
	}

	function _msgSender() internal view virtual returns (address sender) {
		if (isTrustedForwarder(msg.sender)) {
			// The assembly code is more direct than the Solidity version using `abi.decode`.
			assembly {
				sender := shr(96, calldataload(sub(calldatasize(), 20)))
			}
		} else {
			return msg.sender;
		}
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		if (isTrustedForwarder(msg.sender)) {
			return msg.data[:msg.data.length - 20];
		} else {
			return msg.data;
		}
	}

	function _callToSelf(bytes memory data)
		internal
		virtual
		returns (bool success, bytes memory returnData)
	{
		// see _msgSender() to understand how this works
		(success, returnData) = address(this).call(
			abi.encodePacked(data, address(this))
		);
	}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.4;

import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { ERC2771Context } from "./SmartWallet02/ERC2771Context.sol";
import { IERC1271 } from "../utils/IERC1271.sol";
import { IWalletProxyImplementation } from "../external/walletproxy.sol";
import { Recovery } from "../features/recovery.sol";

contract SmartWallet05 is
	IWalletProxyImplementation,
	IERC1271,
	ERC721Holder,
	ERC1155Holder,
	ERC2771Context
{
	using EnumerableSet for EnumerableSet.AddressSet;
	using Address for address;
	using Address for address payable;
	using SafeERC20 for IERC20;

	// Rules for upgrading:
	// 1. Make a copy of the latest version of SmartWallet
	// 2. Structs are only upgradeable if used as a mapping value. Add new struct fields only to the end.
	//   - Type `MyStruct` is NOT upgradeable
	//   - Type `mapping(uint256 => MyStruct) is upgradeable(can add new fields to the end of `MyStruct`)

	address public override masterCopy;
	address public override walletFactory;
	address public owner;
	uint256 public nonce;
	bool public locked;
	// non-upgradeable struct
	struct CommitInfo {
		bytes32 dataHash;
		uint256 timestamp;
		bool revealed;
	}
	// non-upgradeable struct
	struct TwoFAInfo {
		bytes32 rootHash;
		uint8 merkleHeight;
		uint256 counter;
		uint256 initialCounter;
		string hashStorageID;
		mapping(bytes32 => CommitInfo) commitHash;
	}
	TwoFAInfo public twoFAInfo;
	EnumerableSet.AddressSet internal guardians;
	// non-upgradeable struct
	struct RecoveryInfo {
		address newOwner;
		uint256 expiration;
	}
	RecoveryInfo public pendingRecovery;
	address public ensResolver;
	// non-upgradable struct
	struct GuardiansRecoveryInfo {
		address newOwner;
		EnumerableSet.AddressSet guardiansWhoApproved;
	}
	mapping(uint256 => GuardiansRecoveryInfo) internal guardiansRecoveries;
	uint256 public currentGuardiansRecoveryId;
	uint256 public recoveryDelay;

	// END OF DATA LAYOUT
	struct Call {
		address to;
		uint256 value;
		bytes data;
	}

	event WalletTransfer(address to, uint256 amount);
	event Deposit(address indexed sender, uint256 value);
	event WalletUpgraded(address newImpl);
	event TransactionExecuted(
		bool indexed success,
		bytes returnData,
		bytes32 signedHash
	);
	event PaidMetaTransactionRefunded(
		address indexed refundToken,
		address indexed refundAddress,
		uint256 refundAmount,
		uint256 gasUsed,
		uint256 refundTokenTransferGasMargin
	);
	event Invoked(
		address indexed target,
		uint256 indexed value,
		bytes data,
		bool success,
		bytes returnData
	);
	// deprecated in favour of HOTP2FASetupWithCounter
	event HOTP2FASetup(
		string hashStorageID,
		bytes32 rootHash,
		uint8 merkleHeight,
		uint256 initialCounter
	);
	event HOTP2FASetupWithCounter(
		string hashStorageID,
		bytes32 rootHash,
		uint8 merkleHeight,
		uint256 initialCounter,
		uint256 counter
	);
	event Recovered(address indexed newOwner);
	event GuardiansRecoveryCancelled(address indexed newOwner);
	event RecoveryDelayChanged(uint256 delay);
	event PendingRecoveryCreated(
		address indexed newOwner,
		uint256 finalizeAfter
	);
	event RecoveryApprovedByGuardian(
		address indexed newOwner,
		address indexed guardian
	);

	// keep methods <= 8 parameters of get stack to deep
	function initialize(
		address,
		string[2] calldata, // empty means no registration
		address owner_,
		address,
		uint256
	) public virtual override {
		require(owner == address(0), "INITIALIZED_ALREADY");
		owner = owner_;
	}

	modifier onlyOwner() {
		require(_msgSender() == owner, "caller is not the owner");
		_;
	}

	modifier onlyGuardian() {
		require(guardians.contains(_msgSender()), "caller is not a guardian");
		_;
	}

	// confirmMaterial contains OTP + intermediatory hashes + sides
	modifier onlyValidTOTP(bytes32[] memory confirmMaterial) {
		bytes32 reduced = Recovery._reduceConfirmMaterial(confirmMaterial);
		require(reduced == twoFAInfo.rootHash, "UNEXPECTED PROOF");

		uint256 counterProvided = twoFAInfo.initialCounter +
			Recovery._deriveChildTreeIdx(
				twoFAInfo.merkleHeight,
				confirmMaterial[confirmMaterial.length - 1]
			);
		require(
			counterProvided >= twoFAInfo.counter,
			"Provided counter must be greater or same"
		);
		twoFAInfo.counter = counterProvided + 5; // 5 OTPs concatenated in one

		_;
	}

	function executeFreeMetaTx(
		bytes calldata data,
		bytes calldata signature,
		uint256 _nonce,
		uint256 gasPrice,
		uint256 gasLimit,
		address refundToken,
		address payable refundAddress
	) public virtual {
		address signer = ECDSA.recover(
			ECDSA.toEthSignedMessageHash(
				keccak256(
					abi.encodePacked(
						bytes1(0x19),
						bytes1(0), // 0 = free meta tx
						address(this),
						uint256(0), // value
						data,
						uint256(block.chainid),
						_nonce,
						gasPrice,
						gasLimit,
						refundToken,
						refundAddress
					)
				)
			),
			signature
		);
		(bool success, bytes memory returnData) = _executeMetaTx(
			data,
			_nonce,
			signer
		);
		Address.verifyCallResult(success, returnData, "metatx failed");
		emit TransactionExecuted(success, returnData, 0x0);
	}

	struct ExecutePaidMetaTxVars {
		bytes data;
		bytes signature;
		uint256 nonce;
		uint256 gasLimit;
		uint256 refundTokenTransferGasMargin;
		address refundToken;
		// accept gas prices multiplied by 1e18 because some tokens might have too few decimals (e.g., 6)
		uint256 refundTokenGasPriceMul1e18;
		uint256 refundTokenMaxGasPriceMul1e18;
		address refundAddress;
	}

	function executePaidMetaTx(ExecutePaidMetaTxVars calldata vars)
		public
		virtual
	{
		uint256 gasAtStart = gasleft();

		require(
			vars.refundTokenGasPriceMul1e18 <=
				vars.refundTokenMaxGasPriceMul1e18,
			"gasPrice > maxGasPrice"
		);
		address signer = _getPaidMetaTxSigner(vars);
		require(signer == owner, "Only owner can pay for metatx");
		(bool success, bytes memory returnData) = _executeMetaTx(
			vars.data,
			vars.nonce,
			signer
		);
		Address.verifyCallResult(success, returnData, "metatx failed");
		emit TransactionExecuted(success, returnData, 0x0);

		uint256 gasUsed = gasAtStart -
			gasleft() +
			vars.refundTokenTransferGasMargin; // add some gas for refund transfer
		require(gasUsed <= vars.gasLimit, "gasUsed > gasLimit");
		uint256 refundAmount = (gasUsed * vars.refundTokenGasPriceMul1e18) /
			1e18;
		if (refundAmount > 0) {
			if (vars.refundToken == address(0)) {
				payable(vars.refundAddress).sendValue(refundAmount);
			} else {
				IERC20(vars.refundToken).safeTransfer(
					vars.refundAddress,
					refundAmount
				);
			}
		}
		emit PaidMetaTransactionRefunded(
			vars.refundToken,
			vars.refundAddress,
			refundAmount,
			gasUsed,
			vars.refundTokenTransferGasMargin
		);
	}

	function _getPaidMetaTxSigner(ExecutePaidMetaTxVars calldata vars)
		internal
		view
		returns (address)
	{
		return
			ECDSA.recover(
				ECDSA.toEthSignedMessageHash(
					keccak256(
						abi.encodePacked(
							bytes1(0x19),
							bytes1(0x01), // 1 = paid meta tx
							address(this),
							uint256(0), // value
							vars.data,
							uint256(block.chainid),
							vars.nonce,
							vars.gasLimit,
							vars.refundToken,
							vars.refundTokenMaxGasPriceMul1e18,
							vars.refundAddress
						)
					)
				),
				vars.signature
			);
	}

	function _executeMetaTx(
		bytes calldata data,
		uint256 _nonce,
		address signer
	) internal virtual returns (bool success, bytes memory returnData) {
		require(nonce == _nonce, "invalid nonce");
		nonce++;
		(success, returnData) = address(this).call(
			abi.encodePacked(data, signer)
		);
	}

	function multiCall(Call[] calldata _transactions)
		public
		virtual
		onlyOwner
		returns (bytes[] memory)
	{
		bytes[] memory results = new bytes[](_transactions.length);
		for (uint256 i = 0; i < _transactions.length; i++) {
			results[i] = invoke(
				_transactions[i].to,
				_transactions[i].value,
				_transactions[i].data
			);
		}
		return results;
	}

	function setupHOTP2FA(
		string calldata hashStorageID,
		bytes32 rootHash,
		uint8 merkleHeight,
		uint256 initialCounter
	) public virtual onlyOwner {
		_setupHOTP2FA(
			hashStorageID,
			rootHash,
			merkleHeight,
			initialCounter,
			initialCounter
		);
	}

	function setupHOTP2FAWithForcedCounter(
		string calldata hashStorageID,
		bytes32 rootHash,
		uint8 merkleHeight,
		uint256 initialCounter,
		uint256 forcedCounter
	) public virtual onlyOwner {
		_setupHOTP2FA(
			hashStorageID,
			rootHash,
			merkleHeight,
			initialCounter,
			forcedCounter
		);
	}

	function _setupHOTP2FA(
		string calldata hashStorageID,
		bytes32 rootHash,
		uint8 merkleHeight,
		uint256 initialCounter,
		uint256 counter
	) internal virtual {
		require(merkleHeight > 0, "Invalid merkle height");
		require(counter >= initialCounter, "counter < initialCounter");
		twoFAInfo.hashStorageID = hashStorageID;
		twoFAInfo.rootHash = rootHash;
		twoFAInfo.merkleHeight = merkleHeight;
		twoFAInfo.initialCounter = initialCounter;
		twoFAInfo.counter = counter;
		emit HOTP2FASetupWithCounter(
			hashStorageID,
			rootHash,
			merkleHeight,
			initialCounter,
			counter
		);
	}

	//
	// Guardians functions
	//
	function addGuardian(address guardian) public virtual onlyOwner {
		require(guardians.add(guardian), "guardian exists");
	}

	function revokeGuardian(address guardian) public virtual onlyOwner {
		require(guardians.remove(guardian), "guardian does not exist");
		_cancelGuardiansRecovery();
	}

	function isGuardian(address addr) public view virtual returns (bool) {
		return guardians.contains(addr);
	}

	function getGuardians() public view virtual returns (address[] memory) {
		return guardians.values();
	}

	function getGuardiansRecoveryInfo()
		public
		view
		virtual
		returns (address newOwner, address[] memory guardiansWhoApproved)
	{
		GuardiansRecoveryInfo storage info = guardiansRecoveries[
			currentGuardiansRecoveryId
		];
		return (info.newOwner, info.guardiansWhoApproved.values());
	}

	function setRecoveryDelay(uint256 delayInSeconds) public virtual onlyOwner {
		recoveryDelay = delayInSeconds;
		emit RecoveryDelayChanged(delayInSeconds);
	}

	function approveRecoveryByGuardian(address newOwner)
		public
		virtual
		onlyGuardian
	{
		GuardiansRecoveryInfo storage info = guardiansRecoveries[
			currentGuardiansRecoveryId
		];
		if (info.newOwner == address(0)) {
			// a brand new recovery
			info.newOwner = newOwner;
		} else if (info.newOwner != newOwner) {
			// cancel recovery because of guardians decision mismatch
			_cancelGuardiansRecovery();
			return;
		}
		address guardian = _msgSender();
		require(info.guardiansWhoApproved.add(guardian), "Already approved");
		emit RecoveryApprovedByGuardian(newOwner, guardian);

		// recover if there are already enough approvals
		uint256 guardiansLength = guardians.length();
		uint256 approvalsLength = info.guardiansWhoApproved.length();
		require(guardiansLength > 0, "logic error: guardians");
		if (
			((guardiansLength == 1 || guardiansLength == 2) &&
				approvalsLength >= 1) ||
			(guardiansLength > 2 && approvalsLength >= 2)
		) {
			_startGuardiansRecovery();
		}
	}

	function _startGuardiansRecovery() internal virtual {
		address newOwner = guardiansRecoveries[currentGuardiansRecoveryId]
			.newOwner;
		currentGuardiansRecoveryId++;
		if (recoveryDelay == 0) {
			_recover(newOwner);
		} else {
			_startPendingRecovery(
				RecoveryInfo({
					newOwner: newOwner,
					expiration: block.timestamp + recoveryDelay
				})
			);
		}
	}

	function _cancelGuardiansRecovery() internal virtual {
		GuardiansRecoveryInfo storage info = guardiansRecoveries[
			currentGuardiansRecoveryId
		];
		emit GuardiansRecoveryCancelled(info.newOwner);
		currentGuardiansRecoveryId++;
	}

	// recover with combination of commithash and signatures
	function startRecoverCommit(bytes32 secretHash, bytes32 dataHash)
		public
		virtual
	{
		require(
			twoFAInfo.commitHash[secretHash].timestamp == 0,
			"COMMIT ALREADY EXIST"
		);
		twoFAInfo.commitHash[secretHash] = CommitInfo(
			dataHash,
			block.timestamp,
			false
		);
	}

	function startRecoveryReveal(
		address newOwner,
		bytes32[] calldata confirmMaterial
	) public virtual onlyValidTOTP(confirmMaterial) {
		require(_msgSender() == newOwner, "caller is not the new owner");
		bytes32 secretHash = keccak256(abi.encodePacked(confirmMaterial[0]));
		require(twoFAInfo.commitHash[secretHash].timestamp != 0, "NO COMMIT");
		require(
			twoFAInfo.commitHash[secretHash].revealed == false,
			"COMMIT ALREADY REVEALED"
		);
		require(
			block.timestamp - twoFAInfo.commitHash[secretHash].timestamp <
				1 days,
			"Commit is too old"
		);

		bytes32 hash = keccak256(
			abi.encodePacked(newOwner, confirmMaterial[0])
		);
		require(
			hash == twoFAInfo.commitHash[secretHash].dataHash,
			"Datahash does not match"
		);

		twoFAInfo.commitHash[secretHash].revealed = true;
		_recover(newOwner);
	}

	function isRecovering() public view virtual returns (bool) {
		return pendingRecovery.expiration != 0;
	}

	function cancelRecovery() public virtual onlyOwner {
		pendingRecovery = RecoveryInfo(address(0), 0);
	}

	function finalizeRecovery() public virtual {
		require(pendingRecovery.expiration > 0, "no pending recovery");
		require(
			_msgSender() == pendingRecovery.newOwner,
			"caller is not the new owner"
		);
		require(
			block.timestamp > pendingRecovery.expiration,
			"ongoing recovery period"
		);
		_recover(pendingRecovery.newOwner);
		pendingRecovery = RecoveryInfo(address(0), 0);
	}

	function _recover(address newOwner) internal virtual {
		owner = newOwner;
		emit Recovered(owner);
	}

	function _startPendingRecovery(RecoveryInfo memory _pendingRecovery)
		internal
		virtual
	{
		pendingRecovery = _pendingRecovery;
		emit PendingRecoveryCreated(
			_pendingRecovery.newOwner,
			_pendingRecovery.expiration
		);
	}

	function upgradeMasterCopy(address newMasterCopy)
		public
		virtual
		override
		onlyOwner
	{
		_upgradeMasterCopy(newMasterCopy);
	}

	function upgradeMasterCopyAndCall(
		address newMasterCopy,
		bytes calldata data
	) public virtual onlyOwner {
		_upgradeMasterCopy(newMasterCopy);
		(bool success, bytes memory returnData) = _callToSelf(data);
		Address.verifyCallResult(
			success,
			returnData,
			"call after upgrade reverted"
		);
	}

	function _upgradeMasterCopy(address newMasterCopy) internal virtual {
		masterCopy = newMasterCopy;
		emit WalletUpgraded(newMasterCopy);
	}

	function version() public pure virtual override returns (uint256) {
		return 5;
	}

	//
	// ERC1155 support
	//
	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) public virtual override returns (bytes4) {
		for (uint32 i = 0; i < ids.length; i++) {
			onERC1155Received(operator, from, ids[i], values[i], data);
		}
		return this.onERC1155BatchReceived.selector;
	}

	/// @notice ERC1271
	function isValidSignature(bytes32 _hash, bytes calldata _signature)
		external
		view
		override
		returns (bytes4)
	{
		require(
			ECDSA.recover(_hash, _signature) == owner,
			"signer is not the owner"
		);
		// bytes4(keccak256("isValidSignature(bytes32,bytes)")
		return 0x1626ba7e;
	}

	function supportsInterface(bytes4 interfaceID)
		public
		view
		virtual
		override
		returns (bool)
	{
		return
			interfaceID == type(IERC721Receiver).interfaceId ||
			super.supportsInterface(interfaceID);
	}

	//
	// Utility functions
	//

	/// @dev Fallback function allows to deposit ether.
	receive() external payable {
		emit Deposit(msg.sender, msg.value);
	}

	/**
	 * @notice Performs a generic transaction.
	 * @param _target The address for the transaction.
	 * @param _value The value of the transaction.
	 * @param _data The data of the transaction.
	 */
	function invoke(
		address _target,
		uint256 _value,
		bytes calldata _data
	) internal virtual returns (bytes memory _result) {
		require(_target != address(this), "call to self");

		bool success;
		(success, _result) = _target.call{ value: _value }(_data);

		emit Invoked(_target, _value, _data, success, _result);

		if (!success) {
			// solhint-disable-next-line no-inline-assembly
			assembly {
				returndatacopy(0, 0, returndatasize())
				revert(0, returndatasize())
			}
		}
	}
}