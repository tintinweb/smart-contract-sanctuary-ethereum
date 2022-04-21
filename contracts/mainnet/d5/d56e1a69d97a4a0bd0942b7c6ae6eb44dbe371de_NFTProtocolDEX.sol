/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}







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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}









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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}







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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}















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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}







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


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}





// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}





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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


contract NFTProtocolDEX is ERC1155Holder, ERC721Holder, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    /// @dev Event triggered when a swap was opened, see :sol:func:`make`.
    /// @param make array of swap components on the maker side, see :sol:struct:`Component`.
    /// @param take array of swap components on the taker side, see :sol:struct:`Component`.
    /// @param whitelist array of addresses that are allowed to take the swap.
    /// @param id id of the swap.
    event SwapMade(
        Component[] make,
        Component[] take,
        address indexed makerAddress,
        address[] whitelist,
        uint256 indexed id
    );

    /// @dev Emitted when a swap was executed, see :sol:func:`take`.
    /// @param swapId id of the swap that was taken.
    /// @param takerAddress address of the account that executed the swap.
    /// @param fee WEI of ETHER that was paid for the swap.
    event SwapTaken(uint256 swapId, address takerAddress, uint256 fee);

    /// @dev Emitted when a swap was dropped, ie. cancelled.
    /// @param swapId id of the dropped swap.
    event SwapDropped(uint256 swapId);

    /// @dev Emitted when fee parameters have changed, see :sol:func:`vote`, :sol:func:`fees`.
    /// @param flatFee fee to be paid by a swap taker in WEI of ETHER.
    /// @param feeBypassLow threshold of NFT Protocol tokens to be held by a swap taker in order to get a 10% fee discount.
    /// @param feeBypassHigh threshold of NFT Protocol tokens to be held by a swap taker in order to pay no fees.
    event Vote(uint256 flatFee, uint256 feeBypassLow, uint256 feeBypassHigh);

    /// @dev Multisig address for administrative functions.
    address public msig;

    /// @dev Address of the ERC20 NFT Protcol token.
    address public immutable nftProtocolTokenAddress;

    /// @dev Flat fee for all trades in WEI of ETHER, default is 0.001 ETHER.
    /// The flat fee can be changed by the multisig account, see :sol:func:`vote`.
    uint256 public flat = 1000000000000000;

    /// @dev Indicates if the DEX is locked down in case of an emergency.
    /// The value is `true` if the DEX is locked, `false` otherwise.
    bool public locked = false;

    /// @dev Low threshold of NFT Protocol token balance where a 10% fee discount is enabled.
    /// See :sol:func:`fees`, :sol:func:`vote`.
    uint256 public felo = 10000 * 10**18;

    /// @dev High threshold of NFT Protocol token balance where fees are waived.
    /// See :sol:func:`fees`, :sol:func:`vote`.
    uint256 public fehi = 100000 * 10**18;

    // Maker and taker side
    uint8 private constant LEFT = 0;
    uint8 private constant RIGHT = 1;

    /// @dev Asset type 0 for ERC1155 swap components.
    uint8 public constant ERC1155_ASSET = 0;

    /// @dev Asset type 1 for ERC721 swap components.
    uint8 public constant ERC721_ASSET = 1;

    /// @dev Asset type 2 for ERC20 swap components.
    uint8 public constant ERC20_ASSET = 2;

    /// @dev Asset type 3 for ETHER swap components.
    uint8 public constant ETHER_ASSET = 3;

    /// @dev Swap status 0 for swaps that are open and active.
    uint8 public constant OPEN_SWAP = 0;

    /// @dev Swap status 1 for swaps that are closed.
    uint8 public constant CLOSED_SWAP = 1;

    /// @dev Swap status 2 for swaps that are dropped, ie. cancelled.
    uint8 public constant DROPPED_SWAP = 2;

    // Swap structure.
    struct Swap {
        uint256 id;
        uint8 status;
        Component[][2] components;
        address makerAddress;
        address takerAddress;
        bool whitelistEnabled;
    }

    /// Structure representing a single component of a swap.
    struct Component {
        uint8 assetType;
        address tokenAddress;
        uint256[] tokenIds;
        uint256[] amounts;
    }

    /// @dev Map holding all swaps (including cancelled and executed swaps).
    mapping(uint256 => Swap) private swaps;

    // Total number of swaps in the database.
    uint256 public size;

    /// @dev Map from swapId to whitelist of a swap.
    mapping(uint256 => mapping(address => bool)) public list;

    // Map holding pending eth withdrawals.
    mapping(address => uint256) private pendingWithdrawals;

    // Maps to track the contract owned user balances for Ether.
    // The multisig account will not be able to withdraw assets that are owned by users.
    uint256 private usersEthBalance;

    // Unlocked DEX function modifier.
    modifier unlocked {
        require(!locked, "DEX shut down");
        _;
    }

    // Only msig caller function modifier.
    modifier onlyMsig {
        require(msg.sender == msig, "Unauthorized");
        _;
    }

    /// @dev Initializes the contract by setting the address of the NFT Protocol token
    /// and multisig (administrator) account.
    /// @param _nftProtocolToken address of the NFT Protocol ERC20 token
    /// @param _multisig address of the administrator account
    constructor(address _nftProtocolToken, address _multisig) {
        msig = _multisig;
        nftProtocolTokenAddress = _nftProtocolToken;
        emit Vote(flat, felo, fehi);
    }

    /// @dev Opens a swap with a list of assets on the maker side (_make) and on the taker side (_take).
    ///
    /// All assets listed on the maker side have to be available in the caller's account.
    /// They are transferred to the DEX contract during this contract call.
    ///
    /// If the maker list contains ETHER assets, then the total ETHER funds have to be sent along with
    /// the message of this contract call.
    ///
    /// Emits a :sol:event:`SwapMade` event.
    ///
    /// @param _make array of components for the maker side of the swap.
    /// @param _take array of components for the taker side of the swap.
    /// @param _whitelist list of addresses that shall be permitted to take the swap.
    /// If empty, then whitelisting will be disabled for this swap.
    function make(
        Component[] calldata _make,
        Component[] calldata _take,
        address[] calldata _whitelist
    ) external payable nonReentrant unlocked {
        // Prohibit multisig from making swap to maintain correct users balances.
        require(msg.sender != msig, "Multisig cannot make swap");
        require(_take.length > 0, "Empty taker array");
        require(_make.length > 0, "Empty maker array");

        // Check all values before changing state.
        checkAssets(_take);
        uint256 totalEther = checkAssets(_make);
        require(msg.value >= totalEther, "Insufficient ETH");

        // Initialize whitelist mapping for this swap.
        swaps[size].whitelistEnabled = _whitelist.length > 0;
        for (uint256 i = 0; i < _whitelist.length; i++) {
            list[size][_whitelist[i]] = true;
        }

        // Create swap entry and transfer assets to DEX.
        swaps[size].id = size;
        swaps[size].makerAddress = msg.sender;
        for (uint256 i = 0; i < _take.length; i++) {
            swaps[size].components[RIGHT].push(_take[i]);
        }
        for (uint256 i = 0; i < _make.length; i++) {
            swaps[size].components[LEFT].push(_make[i]);
        }

        // Account for Ether from this message.
        usersEthBalance += msg.value;

        // Credit excess Ether back to the sender.
        if (msg.value > totalEther) {
            pendingWithdrawals[msg.sender] += msg.value - totalEther;
        }

        // Add swap.
        size += 1;

        // Transfer in maker assets.
        for (uint256 i = 0; i < _make.length; i++) {
            transferAsset(_make[i], msg.sender, address(this));
        }

        // Issue event.
        emit SwapMade(_make, _take, msg.sender, _whitelist, size - 1);
    }

    /// @dev Takes a swap that is currently open.
    ///
    /// All assets listed on the taker side have to be available in the caller's account, see :sol:func:`make`.
    /// They are transferred to the maker's account in exchange for the maker's assets (that currently reside within the DEX contract),
    /// which are transferred to the taker's account.
    ///
    /// The fee for this trade has to be sent along with the message of this contract call, see :sol:func:`fees`.
    ///
    /// If the taker list contains ETHER assets, then the total ETHER value also has to be added in WEI to the value that is sent along with
    /// the message of this contract call.
    ///
    /// @param _swapId id of the swap to be taken.
    function take(uint256 _swapId) external payable nonReentrant unlocked {
        // Prohibit multisig from taking swap to maintain correct users balances.
        require(msg.sender != msig, "Multisig cannot take swap");

        // Get SwapData from the swap hash.
        require(_swapId < size, "Invalid swapId");
        Swap memory swp = swaps[_swapId];
        require(swp.status == OPEN_SWAP, "Swap not open");

        // Check if address attempting to fulfill swap is authorized in the whitelist.
        require(!swp.whitelistEnabled || list[_swapId][msg.sender], "Not whitelisted");

        // Determine how much total Ether has to be provided by the sender, including fees.
        uint256 totalEther = checkAssets(swp.components[RIGHT]);
        uint256 fee = fees();
        require(msg.value >= totalEther + fee, "Insufficient ETH (price+fee)");

        // Close out swap.
        swaps[_swapId].status = CLOSED_SWAP;
        swaps[_swapId].takerAddress = msg.sender;

        // Account for Ether from this message.
        usersEthBalance += totalEther;

        // Credit excess eth back to the sender.
        if (msg.value > totalEther + fee) {
            pendingWithdrawals[msg.sender] += msg.value - totalEther - fee;
        }

        // Transfer assets from DEX to taker.
        for (uint256 i = 0; i < swp.components[LEFT].length; i++) {
            transferAsset(swp.components[LEFT][i], address(this), msg.sender);
        }

        // Transfer assets from taker to maker.
        for (uint256 i = 0; i < swp.components[RIGHT].length; i++) {
            transferAsset(swp.components[RIGHT][i], msg.sender, swp.makerAddress);
        }

        // Issue event.
        emit SwapTaken(_swapId, msg.sender, fee);
    }

    /// @dev Cancel a swap and return the assets on the maker side back to the maker.
    ///
    /// All ERC1155, ERC721, and ERC20 assets will the transferred back directly to the maker.
    /// ETH assets are booked to the maker account and can be extracted via :sol:func:`pull`.
    ///
    /// Only the swap maker will be able to call this function successfully.
    ///
    /// Only swaps that are currently open can be dropped.
    ///
    /// @param _swapId id of the swap to be dropped.
    function drop(uint256 _swapId) external nonReentrant unlocked {
        Swap memory swp = swaps[_swapId];
        require(msg.sender == swp.makerAddress, "Not swap maker");
        require(swaps[_swapId].status == OPEN_SWAP, "Swap not open");

        // Drop swap.
        swaps[_swapId].status = DROPPED_SWAP;

        // Transfer assets back to maker.
        for (uint256 i = 0; i < swp.components[LEFT].length; i++) {
            transferAsset(swp.components[LEFT][i], address(this), swp.makerAddress);
        }

        // Issue event.
        emit SwapDropped(_swapId);
    }

    /// @dev WEI of ETHER that can be withdrawn by a user, see :sol:func:`pull`.
    function pend() public view returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /// @dev Withdraw ETHER funds from the contract, see :sol:func:`pend`.
    function pull() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        if (msg.sender != msig) {
            // Underflow should never happen and is handled by SafeMath if it does.
            usersEthBalance -= amount;
        }
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Ether transfer failed");
    }

    /// @dev Get a swap, including cancelled and executed swaps.
    /// @param _swapId id of the swap.
    /// @return swap struct.
    function swap(uint256 _swapId) public view returns (Swap memory) {
        require(_swapId < size, "Invalid swapId");
        return swaps[_swapId];
    }

    /// @dev Calculate the fee owed for a trade.
    /// This function is usually called by the taker to determine the amount of ETH
    /// that has to be paid for a trade.
    /// @return fees in WEI of ETHER to be paid by the caller as a taker.
    function fees() public view returns (uint256) {
        uint256 balance = IERC20(nftProtocolTokenAddress).balanceOf(msg.sender);
        if (balance >= fehi) {
            return 0;
        }
        if (balance < felo) {
            return flat;
        }
        // Take 10% off as soon as feeBypassLow is reached.
        uint256 startFee = (flat * 9) / 10;
        return startFee - (startFee * (balance - felo)) / (fehi - felo);
    }

    /// @dev Governance votes to set fees.
    /// @param _flatFee flat fee in WEI of ETHER that has to be paid for a trade,
    /// if the taker has less than `_feeBypassLow` NFT Protocol tokens in its account.
    /// @param _feeBypassLow threshold of NFT Protocol tokens to be held by a swap taker in order to get a 10% fee discount.
    /// @param _feeBypassHigh threshold of NFT Protocol tokens to be held by a swap taker in order to pay no fees.
    function vote(
        uint256 _flatFee,
        uint256 _feeBypassLow,
        uint256 _feeBypassHigh
    ) external onlyMsig {
        require(_feeBypassLow <= _feeBypassHigh, "bypassLow must be <= bypassHigh");

        flat = _flatFee;
        felo = _feeBypassLow;
        fehi = _feeBypassHigh;

        emit Vote(_flatFee, _feeBypassLow, _feeBypassHigh);
    }

    /// @dev Shut down the DEX in case of an emergency.
    ///
    /// Only the :sol:func:`msig` will be able to call this function successfully.
    ///
    /// @param _locked `true` to lock down the DEX, `false` to unlock the DEX.
    function lock(bool _locked) external onlyMsig {
        locked = _locked;
    }

    /// @dev Set multisig ie. administrator account.
    ///
    /// Only the :sol:func:`msig` will be able to call this function successfully.
    ///
    /// @param _to address of the new multisig/admin account
    function auth(address _to) external onlyMsig {
        require(_to != address(0x0), "Cannot set to zero address");
        msig = _to;
    }

    /// @dev Rescue ETHER funds from the DEX that do not belong the a user, e.g., fees and ETHER that have been sent to the DEX accidentally.
    ///
    /// This function books the contract's ETHER funds that do not belong to a user, to the :sol:func:`msig` account and makes them
    /// available for withdrawal through :sol:func:`pull`.
    ///
    /// The user funds that were transfered to the DEX through :sol:func:`make` are protected and cannot be extracted.
    ///
    /// Only the :sol:func:`msig` account will be able to call this function successfully.
    function lift() external onlyMsig {
        uint256 amount = address(this).balance;
        // Underflow should never happen and is handled by SafeMath if it does.
        pendingWithdrawals[msg.sender] = amount - usersEthBalance;
    }

    // Transfer asset from one account to another.
    function transferAsset(
        Component memory _comp,
        address _from,
        address _to
    ) internal {
        // All component checks were conducted before.
        if (_comp.assetType == ERC1155_ASSET) {
            IERC1155 nft = IERC1155(_comp.tokenAddress);
            nft.safeBatchTransferFrom(_from, _to, _comp.tokenIds, _comp.amounts, "");
        } else if (_comp.assetType == ERC721_ASSET) {
            IERC721 nft = IERC721(_comp.tokenAddress);
            nft.safeTransferFrom(_from, _to, _comp.tokenIds[0]);
        } else if (_comp.assetType == ERC20_ASSET) {
            IERC20 coin = IERC20(_comp.tokenAddress);
            uint256 amount = _comp.amounts[0];
            if (_from == address(this)) {
                coin.safeTransfer(_to, amount);
            } else {
                coin.safeTransferFrom(_from, _to, amount);
            }
        } else {
            // Ether, single length amounts array was checked before.
            pendingWithdrawals[_to] += _comp.amounts[0];
        }
    }

    // Check asset type and array sizes within a component.
    function checkAsset(Component memory _comp) internal pure returns (uint256) {
        if (_comp.assetType == ERC1155_ASSET) {
            require(
                _comp.tokenIds.length == _comp.amounts.length,
                "TokenIds and amounts len differ"
            );
        } else if (_comp.assetType == ERC721_ASSET) {
            require(_comp.tokenIds.length == 1, "TokenIds array length must be 1");
        } else if (_comp.assetType == ERC20_ASSET) {
            require(_comp.amounts.length == 1, "Amounts array length must be 1");
        } else if (_comp.assetType == ETHER_ASSET) {
            require(_comp.amounts.length == 1, "Amounts array length must be 1");
            return _comp.amounts[0];
        } else {
            revert("Invalid asset type");
        }
        return 0;
    }

    // Check all assets in a component array.
    function checkAssets(Component[] memory _assets) internal pure returns (uint256) {
        uint256 totalEther = 0;
        for (uint256 i = 0; i < _assets.length; i++) {
            totalEther += checkAsset(_assets[i]);
        }
        return totalEther;
    }
}