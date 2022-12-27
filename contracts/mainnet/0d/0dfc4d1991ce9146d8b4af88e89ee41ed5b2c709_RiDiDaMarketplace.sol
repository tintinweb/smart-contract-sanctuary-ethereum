/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-13
 */

// SPDX-License-Identifier: MIT 
pragma solidity 0.8 .9;

interface IERC165 {
	/**
	 * @dev Returns true if this contract implements the interface defined by
	 * `interfaceId`. See the corresponding
	 * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
	 * to learn more about how these ids are created.
	 *
	 * This function call must use less than 30 000 gas.
	 */
	function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

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
	function balanceOf(address owner) external view returns(uint256 balance);

	/**
	 * @dev Returns the owner of the `tokenId` token.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function ownerOf(uint256 tokenId) external view returns(address owner);

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
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

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
	 * @dev Returns the account approved for `tokenId` token.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function getApproved(uint256 tokenId) external view returns(address operator);

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
	function isApprovedForAll(address owner, address operator) external view returns(bool);

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
}

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
	) external returns(bytes4);
}


interface IERC721Metadata is IERC721 {
	/**
	 * @dev Returns the token collection name.
	 */
	function name() external view returns(string memory);

	/**
	 * @dev Returns the token collection symbol.
	 */
	function symbol() external view returns(string memory);

	/**
	 * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
	 */
	function tokenURI(uint256 tokenId) external view returns(string memory);
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
	function balanceOf(address account, uint256 id) external view returns(uint256);

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
	returns(uint256[] memory);

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
	function isApprovedForAll(address account, address operator) external view returns(bool);

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
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external;

	// /**
	//  * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
	//  *
	//  * Emits a {TransferBatch} event.
	//  *
	//  * Requirements:
	//  *
	//  * - `ids` and `amounts` must have the same length.
	//  * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	//  * acceptance magic value.
	//  */
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;
}
abstract contract ERC165 is IERC165 {
	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}


interface IERC1155Receiver {
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
	) external returns(bytes4);

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
	) external returns(bytes4);
}
interface IERC1155MetadataURI is IERC1155 {
	/**
	 * @dev Returns the URI for token type `id`.
	 *
	 * If the `\{id\}` substring is present in the URI, it must be replaced by
	 * clients with the actual token type ID.
	 */
	function uri(uint256 id) external view returns(string memory);
}
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
	function isContract(address account) internal view returns(bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		assembly {
			size:= extcodesize(account)
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

		(bool success, ) = recipient.call {
			value: amount
		}("");
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
	function functionCall(address target, bytes memory data) internal returns(bytes memory) {
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
	) internal returns(bytes memory) {
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
	) internal returns(bytes memory) {
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
	) internal returns(bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call {
			value: value
		}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(address target, bytes memory data) internal view returns(bytes memory) {
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
	) internal view returns(bytes memory) {
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
	function functionDelegateCall(address target, bytes memory data) internal returns(bytes memory) {
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
	) internal returns(bytes memory) {
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
	) internal pure returns(bytes memory) {
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				assembly {
					let returndata_size:= mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}



/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
	using Address
	for address;

	// Mapping from token ID to account balances
	mapping(uint256 => mapping(address => uint256)) private _balances;

	// Mapping from account to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	// Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
	string private _uri;

	/**
	 * @dev See {_setURI}.
	 */
	constructor(string memory uri_) {
		_setURI(uri_);
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return
		interfaceId == type(IERC1155).interfaceId ||
			interfaceId == type(IERC1155MetadataURI).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC1155MetadataURI-uri}.
	 *
	 * This implementation returns the same URI for *all* token types. It relies
	 * on the token type ID substitution mechanism
	 * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
	 *
	 * Clients calling this function must replace the `\{id\}` substring with the
	 * actual token type ID.
	 */
	function uri(uint256) public view virtual override returns(string memory) {
		return _uri;
	}

	/**
	 * @dev See {IERC1155-balanceOf}.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 */
	function balanceOf(address account, uint256 id) public view virtual override returns(uint256) {
		require(account != address(0), "ERC1155: balance query for the zero address");
		return _balances[id][account];
	}

	/**
	 * @dev See {IERC1155-balanceOfBatch}.
	 *
	 * Requirements:
	 *
	 * - `accounts` and `ids` must have the same length.
	 */
	function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
	public
	view
	virtual
	override
	returns(uint256[] memory) {
		require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

		uint256[] memory batchBalances = new uint256[](accounts.length);

		for (uint256 i = 0; i < accounts.length; ++i) {
			batchBalances[i] = balanceOf(accounts[i], ids[i]);
		}

		return batchBalances;
	}

	/**
	 * @dev See {IERC1155-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC1155-isApprovedForAll}.
	 */
	function isApprovedForAll(address account, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[account][operator];
	}

	/**
	 * @dev See {IERC1155-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		_safeTransferFrom(from, to, id, amount, data);
	}

	/**
	 * @dev See {IERC1155-safeBatchTransferFrom}.
	 */
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: transfer caller is not owner nor approved"
		);
		_safeBatchTransferFrom(from, to, ids, amounts, data);
	}

	/**
	 * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `from` must have a balance of tokens of type `id` of at least `amount`.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
	 * acceptance magic value.
	 */
	function _safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}
		_balances[id][to] += amount;

		emit TransferSingle(operator, from, to, id, amount);

		_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	function _safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; ++i) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
			_balances[id][to] += amount;
		}

		emit TransferBatch(operator, from, to, ids, amounts);

		_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
	}

	/**
	 * @dev Sets a new URI for all token types, by relying on the token type ID
	 * substitution mechanism
	 * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
	 *
	 * By this mechanism, any occurrence of the `\{id\}` substring in either the
	 * URI or any of the amounts in the JSON file at said URI will be replaced by
	 * clients with the token type ID.
	 *
	 * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
	 * interpreted by clients as
	 * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
	 * for token type ID 0x4cce0.
	 *
	 * See {uri}.
	 *
	 * Because these URIs cannot be meaningfully represented by the {URI} event,
	 * this function emits no events.
	 */
	function _setURI(string memory newuri) internal virtual {
		_uri = newuri;
	}

	/**
	 * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
	 * acceptance magic value.
	 */
	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

		_balances[id][to] += amount;
		emit TransferSingle(operator, address(0), to, id, amount);

		_doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	function _mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; i++) {
			_balances[ids[i]][to] += amounts[i];
		}

		emit TransferBatch(operator, address(0), to, ids, amounts);

		_doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
	}

	/**
	 * @dev Destroys `amount` tokens of token type `id` from `from`
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `from` must have at least `amount` tokens of token type `id`.
	 */
	function _burn(
		address from,
		uint256 id,
		uint256 amount
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}

		emit TransferSingle(operator, from, address(0), id, amount);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 */
	function _burnBatch(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
		}

		emit TransferBatch(operator, from, address(0), ids, amounts);
	}

	/**
	 * @dev Approve `operator` to operate on all of `owner` tokens
	 *
	 * Emits a {ApprovalForAll} event.
	 */
	function _setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) internal virtual {
		require(owner != operator, "ERC1155: setting approval status for self");
		_operatorApprovals[owner][operator] = approved;
		emit ApprovalForAll(owner, operator, approved);
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning, as well as batched variants.
	 *
	 * The same hook is called on both single and batched variants. For single
	 * transfers, the length of the `id` and `amount` arrays will be 1.
	 *
	 * Calling conditions (for each `id` and `amount` pair):
	 *
	 * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * of token type `id` will be  transferred to `to`.
	 * - When `from` is zero, `amount` tokens of token type `id` will be minted
	 * for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
	 * will be burned.
	 * - `from` and `to` are never both zero.
	 * - `ids` and `amounts` have the same, non-zero length.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	function _doSafeTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns(bytes4 response) {
				if (response != IERC1155Receiver.onERC1155Received.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	function _doSafeBatchTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns(
				bytes4 response
			) {
				if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non ERC1155Receiver implementer");
			}
		}
	}

	function _asSingletonArray(uint256 element) private pure returns(uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
	using Address
	for address;
	using Strings
	for uint256;

	// Token name
	string private _name;

	// Token symbol
	string private _symbol;

	// Mapping from token ID to owner address
	mapping(uint256 => address) private _owners;

	// Mapping owner address to token count
	mapping(address => uint256) private _balances;

	// Mapping from token ID to approved address
	mapping(uint256 => address) private _tokenApprovals;

	// Mapping from owner to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	/**
	 * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
	 */
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return
		interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");
		return _balances[owner];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];
		require(owner != address(0), "ERC721: owner query for nonexistent token");
		return owner;
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() public view virtual override returns(string memory) {
		return _name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() public view virtual override returns(string memory) {
		return _symbol;
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
	}

	/**
	 * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
	 * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
	 * by default, can be overriden in child contracts.
	 */
	function _baseURI() internal view virtual returns(string memory) {
		return "";
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) public virtual override {
		address owner = ERC721.ownerOf(tokenId);
		require(to != owner, "ERC721: approval to current owner");

		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
			"ERC721: approve caller is not owner nor approved for all"
		);

		_approve(to, tokenId);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) public view virtual override returns(address) {
		require(_exists(tokenId), "ERC721: approved query for nonexistent token");

		return _tokenApprovals[tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != _msgSender(), "ERC721: approve to caller");

		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	/**
	 * @dev See {IERC721-transferFrom}.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

		_transfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
		_safeTransfer(from, to, tokenId, _data);
	}

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * `_data` is additional data, it has no specified format and it is sent in call to `to`.
	 *
	 * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
	 * implement alternative mechanisms to perform token transfer, such as signature-based.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeTransfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal virtual {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	/**
	 * @dev Returns whether `tokenId` exists.
	 *
	 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	 *
	 * Tokens start existing when they are minted (`_mint`),
	 * and stop existing when they are burned (`_burn`).
	 */
	function _exists(uint256 tokenId) internal view virtual returns(bool) {
		return _owners[tokenId] != address(0);
	}

	/**
	 * @dev Returns whether `spender` is allowed to manage `tokenId`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
		require(_exists(tokenId), "ERC721: operator query for nonexistent token");
		address owner = ERC721.ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}

	/**
	 * @dev Safely mints `tokenId` and transfers it to `to`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, "");
	}

	/**
	 * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
	 * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
	 */
	function _safeMint(
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal virtual {
		_mint(to, tokenId);
		require(
			_checkOnERC721Received(address(0), to, tokenId, _data),
			"ERC721: transfer to non ERC721Receiver implementer"
		);
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `to`.
	 *
	 * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - `to` cannot be the zero address.
	 *
	 * Emits a {Transfer} event.
	 */
	function _mint(address to, uint256 tokenId) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenId), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenId);

		_balances[to] += 1;
		_owners[tokenId] = to;

		emit Transfer(address(0), to, tokenId);
	}

	/**
	 * @dev Destroys `tokenId`.
	 * The approval is cleared when the token is burned.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 *
	 * Emits a {Transfer} event.
	 */
	function _burn(uint256 tokenId) internal virtual {
		address owner = ERC721.ownerOf(tokenId);

		_beforeTokenTransfer(owner, address(0), tokenId);

		// Clear approvals
		_approve(address(0), tokenId);

		_balances[owner] -= 1;
		delete _owners[tokenId];

		emit Transfer(owner, address(0), tokenId);
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 *
	 * Emits a {Transfer} event.
	 */
	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {
		require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenId);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;

		emit Transfer(from, to, tokenId);
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(address to, uint256 tokenId) internal virtual {
		_tokenApprovals[tokenId] = to;
		emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
	}

	/**
	 * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
	 * The call is not executed if the target address is not a contract.
	 *
	 * @param from address representing the previous owner of the given token ID
	 * @param to target address that will receive the tokens
	 * @param tokenId uint256 ID of the token to be transferred
	 * @param _data bytes optional data to send along with the call
	 * @return bool whether the call correctly returned the expected magic value
	 */
	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) private returns(bool) {
		if (to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert("ERC721: transfer to non ERC721Receiver implementer");
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning.
	 *
	 * Calling conditions:
	 *
	 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
	 * transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, ``from``'s `tokenId` will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {}
}


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
	function owner() public view virtual returns(address) {
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


abstract contract Pausable is Context {
	/**
	 * @dev Emitted when the pause is triggered by `account`.
	 */
	event Paused(address account);

	/**
	 * @dev Emitted when the pause is lifted by `account`.
	 */
	event Unpaused(address account);

	bool private _paused;

	/**
	 * @dev Initializes the contract in unpaused state.
	 */
	constructor() {
		_paused = false;
	}

	/**
	 * @dev Returns true if the contract is paused, and false otherwise.
	 */
	function paused() public view virtual returns(bool) {
		return _paused;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is not paused.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
	modifier whenNotPaused() {
		require(!paused(), "Pausable: paused");
		_;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is paused.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	modifier whenPaused() {
		require(paused(), "Pausable: not paused");
		_;
	}

	/**
	 * @dev Triggers stopped state.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
	function _pause() internal virtual whenNotPaused {
		_paused = true;
		emit Paused(_msgSender());
	}

	/**
	 * @dev Returns to normal state.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	function _unpause() internal virtual whenPaused {
		_paused = false;
		emit Unpaused(_msgSender());
	}
}
library Counters {
	struct Counter {
		// This variable should never be directly accessed by users of the library: interactions must be restricted to
		// the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
		// this feature: see https://github.com/ethereum/solidity/issues/4637
		uint256 _value; // default: 0
	}

	function current(Counter storage counter) internal view returns(uint256) {
		return counter._value;
	}

	function increment(Counter storage counter) internal {
		unchecked {
			counter._value += 1;
		}
	}

	function decrement(Counter storage counter) internal {
		uint256 value = counter._value;
		require(value > 0, "Counter: decrement overflow");
		unchecked {
			counter._value = value - 1;
		}
	}

	function reset(Counter storage counter) internal {
		counter._value = 0;
	}
}
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
	function trySub(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
	function tryMul(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
	function tryDiv(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
	function tryMod(uint256 a, uint256 b) internal pure returns(bool, uint256) {
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
	function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
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
	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
	function div(uint256 a, uint256 b) internal pure returns(uint256) {
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
	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
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
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns(uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns(uint256) {
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
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns(uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}

library Strings {
	bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

	/**
	 * @dev Converts a `uint256` to its ASCII `string` decimal representation.
	 */
	function toString(uint256 value) internal pure returns(string memory) {
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
	function toHexString(uint256 value) internal pure returns(string memory) {
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
	function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
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
	function tryRecover(bytes32 hash, bytes memory signature) internal pure returns(address, RecoverError) {
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
				r:= mload(add(signature, 0x20))
				s:= mload(add(signature, 0x40))
				v:= byte(0, mload(add(signature, 0x60)))
			}
			return tryRecover(hash, v, r, s);
		} else if (signature.length == 64) {
			bytes32 r;
			bytes32 vs;
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			assembly {
				r:= mload(add(signature, 0x20))
				vs:= mload(add(signature, 0x40))
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
	function recover(bytes32 hash, bytes memory signature) internal pure returns(address) {
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
	) internal pure returns(address, RecoverError) {
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
	) internal pure returns(address) {
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
	) internal pure returns(address, RecoverError) {
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
	) internal pure returns(address) {
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
	function toEthSignedMessageHash(bytes32 hash) internal pure returns(bytes32) {
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
	function toEthSignedMessageHash(bytes memory s) internal pure returns(bytes32) {
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
	function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns(bytes32) {
		return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	}
}

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
	function totalSupply() external view returns(uint256);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns(uint256);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `to`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address to, uint256 amount) external returns(bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender) external view returns(uint256);

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
	function approve(address spender, uint256 amount) external returns(bool);

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
	) external returns(bool);
}

interface IUniswapV2Factory {
	event PairCreated(
		address indexed token0,
		address indexed token1,
		address pair,
		uint256
	);

	function feeTo() external view returns(address);

	function feeToSetter() external view returns(address);

	function getPair(address tokenA, address tokenB)
	external
	view
	returns(address pair);

	function allPairs(uint256) external view returns(address pair);

	function allPairsLength() external view returns(uint256);

	function createPair(address tokenA, address tokenB)
	external
	returns(address pair);

	// function setFeeTo(address) external;
	// function setFeeToSetter(address) external;
}



interface IUniswapV2Pair {
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns(string memory);

	function symbol() external pure returns(string memory);

	function decimals() external pure returns(uint8);

	function totalSupply() external view returns(uint256);

	function balanceOf(address owner) external view returns(uint256);

	function allowance(address owner, address spender)
	external
	view
	returns(uint256);

	function approve(address spender, uint256 value) external returns(bool);

	function transfer(address to, uint256 value) external returns(bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns(bool);

	function DOMAIN_SEPARATOR() external view returns(bytes32);

	function PERMIT_TYPEHASH() external pure returns(bytes32);

	function nonces(address owner) external view returns(uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(
		address indexed sender,
		uint256 amount0,
		uint256 amount1,
		address indexed to
	);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns(uint256);

	function factory() external view returns(address);

	function token0() external view returns(address);

	function token1() external view returns(address);

	function getReserves()
	external
	view
	returns(
		uint112 reserve0,
		uint112 reserve1,
		uint32 blockTimestampLast
	);

	function price0CumulativeLast() external view returns(uint256);

	function price1CumulativeLast() external view returns(uint256);

	function kLast() external view returns(uint256);

	function mint(address to) external returns(uint256 liquidity);

	function burn(address to)
	external
	returns(uint256 amount0, uint256 amount1);

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}



interface IUniswapV2Router01 {
	function factory() external pure returns(address);

	function WETH() external pure returns(address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
	external
	returns(
		uint256 amountA,
		uint256 amountB,
		uint256 liquidity
	);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
	external
	payable
	returns(
		uint256 amountToken,
		uint256 amountETH,
		uint256 liquidity
	);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns(uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns(uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns(uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns(uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns(uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns(uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns(uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns(uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns(uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns(uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns(uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns(uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns(uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
	external
	view
	returns(uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
	external
	view
	returns(uint256[] memory amounts);
}



interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns(uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns(uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}




contract RiDiDaMarketplace is IERC1155Receiver, IERC721Receiver, Ownable, ReentrancyGuard {
	using Counters
	for Counters.Counter;
	Counters.Counter private _itemIds; //count of sale items
	Counters.Counter private _itemsSold; //count of sold items
	Counters.Counter private _itemsinActive;

	mapping(string => mapping(uint256 => bool)) public idToSale;

	address payable treasury; // to transfer listingPrice
	address payable _seller;
	address public tokenAddress;
	address public weth;
	uint256 public treasuryRoyaltySeller = 100;
	uint256 public treasuryRoyaltyBuyer = 100;

	IUniswapV2Router02 public uniswapV2Router; // uniswap dex router
	

	constructor(address token, address _treasury) {

		tokenAddress = token;
		treasury = payable(_treasury);
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
			0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
		);
		uniswapV2Router = _uniswapV2Router;
	}

	//struct for each market item
	struct MarketItem {
		uint itemId;
		uint256 tokenId;
		address payable seller;
		address payable owner;
		address contractAddress;
		address sellerCurrency;
		address buyerCurrency;
		uint256 price;
		bool sold;
		bool isActive;
		bool is721;
	}

	struct NftRecord {
		address user;
		uint256 id;
		uint256 quantity;

	}


	mapping(uint256 => MarketItem) public idToMarketItem;

	event saleCreated(
		uint indexed itemId,
		uint256 indexed tokenId,
		address seller,
		address owner,
		address contractAddress,
		address sellerCurrency,
		address buyerCurrency,
		uint256 price,
		bool sold,
		bool isActive,
		bool is721
	);

	event ItemBought(
		uint indexed itemId,
		uint256 indexed tokenId,
		address buyer,
		address contractAddress,
		address sellerCurrency,
		address buyerCurrency,
		uint256 buyerAmount,
		uint256 price,
		bool sold,
		bool isActive
	);




	function setTreasuryRoyalty(uint256 sellerRoyalty, uint256 buyerRoyalty) external onlyOwner {
		treasuryRoyaltySeller = sellerRoyalty;
		treasuryRoyaltyBuyer = buyerRoyalty;
	}

	function onERC721Received(address, address, uint256, bytes memory) public virtual override returns(bytes4) {
		return this.onERC721Received.selector;
	}

	function setTreasury(address _treasury) external onlyOwner {
		treasury = payable(_treasury);
	}

	/* Places an item for sale on the marketplace */
	function createSale(
		address nftContract,
		uint256 tokenId,
		address sellerCurrency,
		uint256 price,
		bool is721Nft
	) external nonReentrant {

		require(price > 0, "Price must be at least 1 wei");
		if (is721Nft) {
			require(IERC721(nftContract).isApprovedForAll(msg.sender, address(this)),
				"Caller must be approved or owner for token id");
			require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Only owner can sell");

		} else {
			require(IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)),
				"Caller must be approved or owner for token id");
			require(IERC1155(nftContract).balanceOf(msg.sender, tokenId) > 0, "Balance 0");

		}
		_itemIds.increment();
		uint256 itemId = _itemIds.current();
		idToMarketItem[itemId] = MarketItem(
			itemId,
			tokenId,
			payable(msg.sender),
			payable(treasury),
			nftContract,
			sellerCurrency,
			address(0),
			price,
			false,
			true,
			is721Nft
		);


		emit saleCreated(
			itemId,
			tokenId,
			msg.sender,
			treasury,
			nftContract,
			sellerCurrency,
			address(0),
			price,
			false,
			true,
			is721Nft
		);
	}


	//function to  buyItem
	function buyItem(
		uint256 itemId,
		address buyerCurrency
	) external payable nonReentrant {
		require(itemId <= _itemIds.current(), " Enter a valid Id");
		require(idToMarketItem[itemId].isActive == true, "the sale is not active");
		require(msg.sender != idToMarketItem[itemId].seller, "seller cannot buy");
		uint price = idToMarketItem[itemId].price;
		uint tokenId = idToMarketItem[itemId].tokenId;
		address nftContract = idToMarketItem[itemId].contractAddress;
		bool is721 = idToMarketItem[itemId].is721;
		require(idToMarketItem[itemId].sold == false, "Already Sold");
		_seller = idToMarketItem[itemId].seller;
		uint256 buyerPaid;
		if (idToMarketItem[itemId].sellerCurrency == buyerCurrency) {

			if (buyerCurrency == tokenAddress) {
				IERC20(tokenAddress).transferFrom(msg.sender, _seller, price);
				buyerPaid = price;
			} else {
				uint256 sellerFee = (price * treasuryRoyaltySeller) / 10000;
				uint256 buyerFee = (price * treasuryRoyaltyBuyer) / 10000;
				require(msg.value >= price + buyerFee, "Amount not sufficient for purchase");
				payable(treasury).transfer(sellerFee + buyerFee);
				payable(_seller).transfer(price - sellerFee);
				buyerPaid = price + buyerFee;
			}

		} else {

			if (buyerCurrency == tokenAddress) {
				(uint256 tokens, uint256 ethReturned) = swapTokensForEth(price);
				uint256 sellerFee = (ethReturned * treasuryRoyaltySeller) / 10000;
				payable(treasury).transfer(sellerFee);
				payable(_seller).transfer(ethReturned - sellerFee);
				buyerPaid = tokens;

			} else {

				(, uint256 tokensReturned, uint256 paid) = swapEthForTokens(price);
				IERC20(tokenAddress).transfer(_seller, tokensReturned);
				buyerPaid = paid;
				if (msg.value > buyerPaid) {
					payable(msg.sender).transfer(msg.value - buyerPaid);
				}
			}

		}

		if (is721) {
			IERC721(nftContract).safeTransferFrom(_seller, msg.sender, tokenId);
		} else {

			IERC1155(nftContract).safeTransferFrom(_seller, msg.sender, tokenId, 1, "");
		}

		idToMarketItem[itemId].owner = payable(msg.sender);
		idToMarketItem[itemId].sold = true;
		idToMarketItem[itemId].isActive = false;
		_itemsSold.increment();
		_itemsinActive.increment();
		emit ItemBought(
			itemId,
			tokenId,
			msg.sender,
			nftContract,
			idToMarketItem[itemId].sellerCurrency,
			buyerCurrency,
			buyerPaid,
			price,
			true,
			false
		);

	}

	function changeAddress(address token, address _treasury) external onlyOwner {

		tokenAddress = token;
		treasury = payable(_treasury);
	}

	function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns(bytes4) {
		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns(bytes4) {
		return this.onERC1155BatchReceived.selector;
	}


	//function to end the sale
	function endSale(uint256 itemId) external nonReentrant {
		require(itemId <= _itemIds.current(), " Enter a valid Id");
		require(msg.sender == idToMarketItem[itemId].seller && idToMarketItem[itemId].sold == false && idToMarketItem[itemId].isActive == true);
		idToMarketItem[itemId].isActive = false;
		_itemsinActive.increment();

	}

	//function to edit the sale price
	function editSale(uint256 itemId, uint256 price) external nonReentrant {
		require(itemId <= _itemIds.current(), " Enter a valid Id");
		require(msg.sender == idToMarketItem[itemId].seller && idToMarketItem[itemId].sold == false && idToMarketItem[itemId].isActive == true);
		idToMarketItem[itemId].price = price;

	}

	//    function getUserBurnNts(address user) external view returns(uint256[] memory ids){
	//        return(tokensBurnt[user]);
	//    }

	function getTokenToItem(uint256 token, bool is721) public view returns(uint256 itemId) {
		uint itemCount = _itemIds.current();
		uint256 saleId;
		for (uint i = 0; i < itemCount; i++) {
			if (idToMarketItem[i + (1)].isActive == true && idToMarketItem[i + (1)].is721 == is721 &&
				idToMarketItem[i + (1)].tokenId == token) {
				saleId = i + 1;
			}
		}
		return (saleId);
	}

	/* Returns all unsold market items */
	function fetchMarketItems() public view returns(MarketItem[] memory) {
		uint itemCount = _itemIds.current();
		uint unsoldItemCount = _itemIds.current() - (_itemsinActive.current());
		uint currentIndex = 0;

		MarketItem[] memory items = new MarketItem[](unsoldItemCount);
		for (uint i = 0; i < itemCount; i++) {
			if (idToMarketItem[i + (1)].isActive == true) {
				uint currentId = i + (1);
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex = currentIndex + (1);
			}
		}
		return items;
	}

	/* Returns  items that a user has purchased */
	function fetchMyNFTs() public view returns(MarketItem[] memory) {
		uint totalItemCount = _itemIds.current();
		uint itemCount = 0;
		uint currentIndex = 0;

		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].owner == msg.sender) {
				itemCount = itemCount + (1);
			}
		}

		MarketItem[] memory items = new MarketItem[](itemCount);
		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].owner == msg.sender) {
				uint currentId = i + (1);
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex = currentIndex + (1);
			}
		}
		return items;
	}


	/* Returns only items a user has created */
	function fetchItemsCreated() public view returns(MarketItem[] memory) {
		uint totalItemCount = _itemIds.current();
		uint itemCount = 0;
		uint currentIndex = 0;

		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].seller == msg.sender) {
				itemCount = itemCount + (1);
			}
		}
		MarketItem[] memory items = new MarketItem[](itemCount);
		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].seller == msg.sender) {
				uint currentId = i + (1);
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex = currentIndex + (1);
			}
		}
		return items;
	}

	function fetch721Items() public view returns(MarketItem[] memory) {
		uint totalItemCount = _itemIds.current();
		uint itemCount = 0;
		uint currentIndex = 0;

		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].is721) {
				itemCount = itemCount + (1);
			}
		}
		MarketItem[] memory items = new MarketItem[](itemCount);
		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].is721) {
				uint currentId = i + (1);
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex = currentIndex + (1);
			}
		}
		return items;
	}

	function fetch1155Items() public view returns(MarketItem[] memory) {
		uint totalItemCount = _itemIds.current();
		uint itemCount = 0;
		uint currentIndex = 0;

		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].is721 == false) {
				itemCount = itemCount + (1);
			}
		}
		MarketItem[] memory items = new MarketItem[](itemCount);
		for (uint i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + (1)].is721 == false) {
				uint currentId = i + (1);
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex = currentIndex + (1);
			}
		}
		return items;
	}

	function swapTokensForEth(uint256 ethAmount) private returns(uint256 tokenUsed, uint256 ethReturned) {

		address[] memory path = new address[](2);
		path[0] = tokenAddress;
		path[1] = uniswapV2Router.WETH();
		uint256[] memory amounts = new uint256[](2);
		amounts = uniswapV2Router.getAmountsIn(ethAmount, path);
		uint256 tokenAmount = amounts[0];
		IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
		IERC20(tokenAddress).approve(address(uniswapV2Router), 2 ** 256 - 1);
		amounts = uniswapV2Router.swapTokensForExactETH(
			ethAmount,
			tokenAmount,
			path,
			address(this),
			block.timestamp + 1000
		);
		tokenUsed = amounts[0];
		ethReturned = amounts[1];

	}

	function swapEthForTokens(uint256 tokenAmount) private returns(uint256 ethUsed,
		uint256 tokensReturned, uint256 buyerPaid) {

		address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = tokenAddress;
		uint256[] memory amounts = new uint256[](2);
		amounts = uniswapV2Router.getAmountsIn(tokenAmount, path);
		uint256 ethAmount = amounts[0];
		require(msg.value >= ethAmount, "Insufficient amount provided");
		amounts = uniswapV2Router.swapETHForExactTokens {
			value: ethAmount
		}(
			tokenAmount,
			path,
			address(this),
			block.timestamp + 1000
		);
		ethUsed = amounts[0];
		uint256 buyerFee = (ethUsed * treasuryRoyaltyBuyer) / 10000;
		require(msg.value >= ethUsed + buyerFee, "Amount not sufficient for fee");
		buyerPaid = ethUsed + buyerFee;
		payable(treasury).transfer(buyerFee);
		tokensReturned = amounts[1];


	}


	function withdrawTokens(IERC20 token, address wallet) external onlyOwner {
		uint256 balanceOfContract = token.balanceOf(address(this));
		token.transfer(wallet, balanceOfContract);
	}

	/*
    @param wallet address that gets the Eth
     */

	function withdrawFunds(address wallet) external onlyOwner {
		uint256 balanceOfContract = address(this).balance;
		payable(wallet).transfer(balanceOfContract);
	}

	function getPrice(uint256 item, address currency) public view returns(uint256 price) {

		if (currency == idToMarketItem[item].sellerCurrency) {
			price = (idToMarketItem[item].price);
			if(currency != tokenAddress){
				price += (price*treasuryRoyaltyBuyer/10000 );
			}
		} else {

			address[] memory path = new address[](2);
			path[0] = currency;
			path[1] = idToMarketItem[item].sellerCurrency;
			uint256[] memory amounts = new uint256[](2);
			amounts = uniswapV2Router.getAmountsIn(idToMarketItem[item].price, path);
			price = amounts[0];
			if(currency != tokenAddress){
				price += (price*treasuryRoyaltyBuyer/10000 );
			}

		}

	}

	receive() external payable {}
	fallback() external payable {}
}