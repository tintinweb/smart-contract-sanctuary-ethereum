/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// 
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)
/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

// 
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// 
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

// 
contract NFTReceiver is IERC721Receiver, ERC1155Receiver {
    enum NftTypeEnum {
        ERC721_TYPE,
        ERC1155_TYPE
    }

    modifier onlyThis(address operator) {
        require(operator == address(this), "stake contract only");
        _;
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view override onlyThis(operator) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public view override onlyThis(operator) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public view override onlyThis(operator) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// 
interface IStripto {
    function init(bytes memory _data) external;
}

// 
interface IStriptoFactory {
    function addImplementation(address _implementation) external;

    function addManyWhitelist(
        address[] memory accounts,
        uint256[] memory credits
    ) external;

    function addWhitelist(address account, uint256 deployCredit) external;

    function createStripto(
        uint256 _index,
        bytes memory _data
    ) external returns (address stripto);

    function disableWhitelist() external;

    function enableWhitelist() external;

    function fee() external view returns (uint256);

    function implementations(uint256) external view returns (address);

    function implementationsLength() external view returns (uint256);

    function isWhitelistEnabled() external view returns (bool);

    function isWhitelisted(address account) external view returns (uint256);

    function owner() external view returns (address);

    function predictAddress(
        uint256 _index,
        bytes memory _data,
        address _deployer
    ) external view returns (address);

    function removeManyWhitelist(
        address[] memory accounts,
        uint256[] memory credits
    ) external;

    function removeWhitelist(address account, uint256 deployCredit) external;

    function renounceOwnership() external;

    function setFee(uint256 _fee) external;

    function striptos(uint256) external view returns (address);

    function striptosLength() external view returns (uint256);

    function transferOwnership(address newOwner) external;
}


uint256 constant REWARD_DEBT_SCALE = 1e36;

uint256 constant REWARD_PER_SECOND_SCALE = 1e9;

contract StriptoNFTStake is Ownable, NFTReceiver, IStripto {
    using SafeERC20 for IERC20;

    enum StakeTiers {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    struct InitCallData {
        address nft;
        address rewardToken;
        address owner;
        uint256[4] rewardsPerPeriod;
        uint256[4] lockPeriods; // in days
        uint256[4] penalties;
        uint256[4] minDeposit;
        uint256 initialRewards;
    }

    struct Pool {
        uint256 rewardsPerPeriod;
        uint256 lockPeriod; // in seconds
        uint256 penalty;
        uint256 minDeposit;
        uint256 lastRewardTime;
        uint256 rewardsPerSec;
        uint256 accPerShare;
        uint256 totalStaked;
    }

    struct UserStake {
        uint256[] tokenIds;
        uint256[] quantities; // for ERC1155
        StakeTiers tier;
        uint256 totalQuantity;
        uint256 rewardsDebt;
        uint256 unlockTime;
    }

    struct ExtendedUserStake {
        uint256[] tokenIds;
        uint256[] quantities; // for ERC1155
        StakeTiers tier;
        uint256 totalQuantity;
        uint256 rewardsDebt;
        uint256 unlockTime;
        uint256 lastRewardTime;
        uint256 pendingRewards;
    }

    NftTypeEnum public NftType;
    address public nft;
    address public rewardToken;

    Pool[] public pools;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalRewardsPerSec;

    uint256 public totalRewards;
    uint256 public totalStaked;

    address public immutable factory;

    mapping(address => UserStake[]) public userStakes;
    mapping(address => uint256) public userRewards;

    event Deposit(
        uint256 indexed tier,
        address indexed user,
        uint256[] tokenIds,
        uint256[] quantities
    );

    event Withdraw(
        uint256 indexed tier,
        address indexed user,
        uint256[] tokenIds,
        uint256[] quantities
    );

    event ClaimReward(
        uint256 indexed tier,
        address indexed user,
        uint256 reward
    );

    event EmergencyWithdraw(
        uint256 indexed tier,
        address indexed user,
        uint256[] tokenIds,
        uint256[] quantities
    );

    constructor(address _factory) {
        factory = _factory;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endTime, "stake ended");
        _;
    }

    modifier onlyWithFee() {
        require(
            msg.value >= (IStriptoFactory(factory).fee() * 10) / 100,
            "invalid fee"
        );
        address payable feeReceiver = payable(factory);
        feeReceiver.transfer(msg.value);
        _;
    }

    /**
        @dev initialize contract
        @param _data encoded InitCallData struct
     */
    function init(bytes memory _data) public override {
        require(msg.sender == factory, "only factory"); // this check suffices to preent multiple init calls

        InitCallData memory data = abi.decode(_data, (InitCallData));

        nft = data.nft;

        rewardToken = data.rewardToken;

        bool isERC721 = false;
        bool isERC1155 = false;

        isERC721 = IERC721(nft).supportsInterface(0x80ac58cd);
        if (!isERC721) isERC1155 = IERC1155(nft).supportsInterface(0xd9b67a26);

        require(isERC721 || isERC1155, "invalid nft");

        NftType = isERC721 ? NftTypeEnum.ERC721_TYPE : NftTypeEnum.ERC1155_TYPE;

        _transferOwnership(data.owner);

        startTime = block.timestamp;
        endTime = block.timestamp;
        lastEmissionChange = block.timestamp;

        _setUpStake(
            data.rewardsPerPeriod,
            data.lockPeriods,
            data.penalties,
            data.minDeposit
        );

        require(data.initialRewards > 0, "no rewards");
        _depositRewardToken(data.initialRewards, data.owner);
    }

    function _setUpStake(
        uint256[4] memory _tierRewardsPerPeriod,
        uint256[4] memory _tiersLock,
        uint256[4] memory _tiersPenalty,
        uint256[4] memory _tiersMinDeposit
    ) internal {
        for (uint256 i = 0; i < _tierRewardsPerPeriod.length; i++) {
            pools.push(
                Pool({
                    rewardsPerPeriod: _tierRewardsPerPeriod[i],
                    lockPeriod: _tiersLock[i] * 1 days,
                    penalty: _tiersPenalty[i],
                    minDeposit: _tiersMinDeposit[i],
                    rewardsPerSec: 0,
                    accPerShare: 0,
                    totalStaked: 0,
                    lastRewardTime: block.timestamp
                })
            );
        }
    }

    function _depositRewardToken(uint256 amount, address from) internal {
        // balance befroe
        uint256 balanceBefore = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransferFrom(from, address(this), amount);
        // balance after
        uint256 balanceAfter = IERC20(rewardToken).balanceOf(address(this));
        // add to total rewards
        totalRewards += balanceAfter - balanceBefore;

        // adjust end time
        if (totalRewardsPerSec > 0) {
            uint256 newTime = ((balanceAfter - balanceBefore) *
                REWARD_PER_SECOND_SCALE) / totalRewardsPerSec;

            endTime += newTime;
        } else endTime = type(uint256).max;
    }

    function depositRewardToken(uint256 amount)
        external
        payable
        onlyOwner
        onlyBeforeEnd
        onlyWithFee
    {
        _depositRewardToken(amount, msg.sender);
    }

    function setRewardsForPeriod(uint256 _tier, uint256 _rewardsPerPeriod)
        external
        payable
        onlyOwner
        onlyBeforeEnd
        onlyWithFee
    {
        Pool storage pool = pools[_tier];

        require(_rewardsPerPeriod > pool.rewardsPerPeriod, "can only increase");

        updatePool(_tier);

        uint256 newRewardsPerSec = (pool.rewardsPerSec * _rewardsPerPeriod) /
            pool.rewardsPerPeriod;

        _updateRewardsPerSecond(_tier, newRewardsPerSec);

        pool.rewardsPerPeriod = _rewardsPerPeriod;
    }

    function deposit(
        uint256 _tier,
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) public onlyBeforeEnd {
        require(_tier < pools.length, "invalid tier");
        require(_ids.length > 0, "no ids");
        require(_ids.length == _quantities.length, "length mismatch");

        Pool storage pool = pools[_tier];

        updatePool(_tier);

        uint256 totalQuantie = 0;

        if (NftType == NftTypeEnum.ERC721_TYPE) {
            // transfer all ids
            for (uint256 i = 0; i < _ids.length; i++) {
                IERC721(nft).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _ids[i]
                );
                totalQuantie += 1;
            }
        } else {
            IERC1155(nft).safeBatchTransferFrom(
                msg.sender,
                address(this),
                _ids,
                _quantities,
                ""
            );
            for (uint256 i = 0; i < _quantities.length; i++) {
                totalQuantie += _quantities[i];
            }
        }

        require(totalQuantie >= pool.minDeposit, "min deposit not met");

        uint256 rewardsDebt = (pool.accPerShare * totalQuantie) /
            REWARD_DEBT_SCALE;

        UserStake memory userStake = UserStake({
            tokenIds: _ids,
            quantities: _quantities,
            totalQuantity: totalQuantie,
            tier: StakeTiers(_tier),
            rewardsDebt: rewardsDebt,
            unlockTime: block.timestamp + pool.lockPeriod
        });

        uint256 rewardsForPeriod = (pool.rewardsPerPeriod *
            totalQuantie *
            REWARD_PER_SECOND_SCALE) /
            (pool.lockPeriod == 0 ? 1 days : pool.lockPeriod);

        _updateRewardsPerSecond(_tier, rewardsForPeriod + pool.rewardsPerSec);

        pool.totalStaked += totalQuantie;
        totalStaked += totalQuantie;

        userStakes[msg.sender].push(userStake);

        emit Deposit(_tier, msg.sender, _ids, _quantities);
    }

    function withdraw(uint256 index) external {
        // copy user stake to memory and remove it from array
        UserStake memory userStake = userStakes[msg.sender][index];

        require(
            userStake.unlockTime <= block.timestamp ||
                endTime < block.timestamp,
            "stake is locked"
        );

        // remove from array
        if (index != userStakes[msg.sender].length - 1) {
            userStakes[msg.sender][index] = userStakes[msg.sender][
                userStakes[msg.sender].length - 1
            ];
            userStakes[msg.sender].pop();
        } else {
            userStakes[msg.sender].pop();
        }

        Pool storage pool = pools[uint256(userStake.tier)];

        updatePool(uint256(userStake.tier));

        uint256 pending = ((userStake.totalQuantity * pool.accPerShare) /
            REWARD_DEBT_SCALE -
            userStake.rewardsDebt);

        pool.totalStaked -= userStake.totalQuantity;
        totalStaked -= userStake.totalQuantity;

        uint256 reducedRewards = (pool.rewardsPerPeriod *
            userStake.totalQuantity *
            REWARD_PER_SECOND_SCALE) /
            (pool.lockPeriod == 0 ? 1 days : pool.lockPeriod);

        _updateRewardsPerSecond(
            uint256(userStake.tier),
            pool.rewardsPerSec - reducedRewards
        );

        if (pending > 0) {
            IERC20(rewardToken).safeTransfer(msg.sender, pending);
            userRewards[msg.sender] += pending;
            emit ClaimReward(uint256(userStake.tier), msg.sender, pending);
        }

        if (NftType == NftTypeEnum.ERC721_TYPE) {
            for (uint256 i = 0; i < userStake.tokenIds.length; i++) {
                IERC721(nft).safeTransferFrom(
                    address(this),
                    msg.sender,
                    userStake.tokenIds[i]
                );
            }
        } else if (NftType == NftTypeEnum.ERC1155_TYPE) {
            IERC1155(nft).safeBatchTransferFrom(
                address(this),
                msg.sender,
                userStake.tokenIds,
                userStake.quantities,
                ""
            );
        }

        emit Withdraw(
            uint256(userStake.tier),
            msg.sender,
            userStake.tokenIds,
            userStake.quantities
        );
    }

    function earlyWithdraw(uint256 index) external {
        // copy user stake to memory and remove it from array
        UserStake memory userStake = userStakes[msg.sender][index];

        require(
            userStake.unlockTime > block.timestamp && endTime > block.timestamp,
            "stake is not locked"
        );

        // remove from array
        if (index != userStakes[msg.sender].length - 1) {
            userStakes[msg.sender][index] = userStakes[msg.sender][
                userStakes[msg.sender].length - 1
            ];
            userStakes[msg.sender].pop();
        } else {
            userStakes[msg.sender].pop();
        }

        Pool storage pool = pools[uint256(userStake.tier)];

        updatePool(uint256(userStake.tier));

        uint256 pending = ((userStake.totalQuantity * pool.accPerShare) /
            REWARD_DEBT_SCALE) - userStake.rewardsDebt;

        pool.totalStaked -= userStake.totalQuantity;
        totalStaked -= userStake.totalQuantity;

        uint256 reducedRewards = (pool.rewardsPerPeriod *
            userStake.totalQuantity *
            REWARD_PER_SECOND_SCALE) /
            (pool.lockPeriod == 0 ? 1 days : pool.lockPeriod);

        if (pending > 0) {
            uint256 penaltyAmount = (pending * pool.penalty) / 100;
            IERC20(rewardToken).safeTransfer(
                msg.sender,
                pending - penaltyAmount
            );

            // add penalty to total rewards
            totalRewards += penaltyAmount;

            userRewards[msg.sender] += pending - penaltyAmount;

            emit ClaimReward(
                uint256(userStake.tier),
                msg.sender,
                pending - penaltyAmount
            );
        }

        _updateRewardsPerSecond(
            uint256(userStake.tier),
            pool.rewardsPerSec - reducedRewards
        );

        if (NftType == NftTypeEnum.ERC721_TYPE) {
            for (uint256 i = 0; i < userStake.tokenIds.length; i++) {
                IERC721(nft).safeTransferFrom(
                    address(this),
                    msg.sender,
                    userStake.tokenIds[i]
                );
            }
        } else if (NftType == NftTypeEnum.ERC1155_TYPE) {
            IERC1155(nft).safeBatchTransferFrom(
                address(this),
                msg.sender,
                userStake.tokenIds,
                userStake.quantities,
                ""
            );
        }

        emit EmergencyWithdraw(
            uint256(userStake.tier),
            msg.sender,
            userStake.tokenIds,
            userStake.quantities
        );
    }

    function pendingRewards(address user, uint256 index)
        public
        view
        returns (uint256)
    {
        UserStake memory userStake = userStakes[user][index];

        Pool memory poolInfo = pools[uint256(userStake.tier)];

        uint256 latestTime = block.timestamp < endTime
            ? block.timestamp
            : endTime;

        uint256 nrOfSeconds = latestTime - poolInfo.lastRewardTime;

        uint256 bep20Reward = (nrOfSeconds *
            poolInfo.rewardsPerSec *
            REWARD_DEBT_SCALE) / REWARD_PER_SECOND_SCALE;

        poolInfo.accPerShare =
            poolInfo.accPerShare +
            ((bep20Reward) / poolInfo.totalStaked);

        poolInfo.lastRewardTime = uint128(latestTime);

        uint256 pending = (((userStake.totalQuantity * poolInfo.accPerShare) /
            REWARD_DEBT_SCALE) - userStake.rewardsDebt);

        return pending;
    }

    function totalPendingRewards(address user) external view returns (uint256) {
        uint256 totalPending = 0;
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            totalPending += pendingRewards(user, i);
        }
        return totalPending;
    }

    function userInfo(address user)
        external
        view
        returns (ExtendedUserStake[] memory)
    {
        UserStake[] memory userStake = userStakes[user];
        ExtendedUserStake[] memory extendedUserStake = new ExtendedUserStake[](
            userStake.length
        );

        for (uint256 i = 0; i < userStake.length; i++) {
            extendedUserStake[i].tier = userStake[i].tier;
            extendedUserStake[i].tokenIds = userStake[i].tokenIds;
            extendedUserStake[i].quantities = userStake[i].quantities;
            extendedUserStake[i].totalQuantity = userStake[i].totalQuantity;
            extendedUserStake[i].rewardsDebt = userStake[i].rewardsDebt;
            extendedUserStake[i].unlockTime = userStake[i].unlockTime;
            extendedUserStake[i].pendingRewards = pendingRewards(user, i);
        }

        return extendedUserStake;
    }

    function updatePool(uint256 pid) public {
        Pool storage poolInfo = pools[pid];
        uint256 latestTime = block.timestamp < endTime
            ? block.timestamp
            : endTime;
        if (latestTime <= poolInfo.lastRewardTime) {
            return;
        }

        uint256 lpSupply = poolInfo.totalStaked;
        if (lpSupply == 0) {
            poolInfo.lastRewardTime = uint128(latestTime);
            return;
        }

        uint256 nrOfSeconds = latestTime - poolInfo.lastRewardTime;
        uint256 bep20Reward = ((nrOfSeconds * poolInfo.rewardsPerSec) *
            REWARD_DEBT_SCALE) / REWARD_PER_SECOND_SCALE;

        poolInfo.accPerShare =
            poolInfo.accPerShare +
            ((bep20Reward) / lpSupply);

        poolInfo.lastRewardTime = uint128(latestTime);
    }

    uint256 public rewardsAmountBeforeLastChange;
    uint256 lastEmissionChange;

    function _updateRewardsPerSecond(uint256 tier, uint256 newRewardsPerSeconds)
        internal
    {
        if (endTime < block.timestamp) {
            return;
        }
        uint256 oldRewardsPerSeconds = pools[tier].rewardsPerSec;

        uint256 totalRewardsTillNow = _totalPastRewards();
        //uint256 leftRewards = totalBEP20Rewards - totalRewardsTillNow;

        // push this change into history
        lastEmissionChange = block.timestamp;
        uint256 newTotalRewardsPerSec = totalRewardsPerSec +
            newRewardsPerSeconds -
            oldRewardsPerSeconds;
        // endtime

        if (newTotalRewardsPerSec == 0) endTime = type(uint256).max;
        else
            endTime =
                block.timestamp +
                ((totalRewards - totalRewardsTillNow) /
                    (newTotalRewardsPerSec / REWARD_PER_SECOND_SCALE));

        rewardsAmountBeforeLastChange = totalRewardsTillNow;

        require(endTime > block.timestamp, "Not enough rewards");

        totalRewardsPerSec = newTotalRewardsPerSec;
        pools[tier].rewardsPerSec = newRewardsPerSeconds;
    }

    function _totalPastRewards() internal view returns (uint256) {
        uint256 lastTime = endTime < block.timestamp
            ? endTime
            : block.timestamp;
        uint256 diff = lastTime - lastEmissionChange;
        return
            rewardsAmountBeforeLastChange +
            ((totalRewardsPerSec * diff) / REWARD_PER_SECOND_SCALE);
    }

    function userInfoLength(address _user) public view returns (uint256) {
        return userStakes[_user].length;
    }

    function poolsLength() external view returns (uint256) {
        return pools.length;
    }

    function recoverLostTokens(address _token) external onlyOwner {
        require(
            _token != rewardToken || totalStaked == 0,
            "Cannot recover the rewardToken"
        );
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}