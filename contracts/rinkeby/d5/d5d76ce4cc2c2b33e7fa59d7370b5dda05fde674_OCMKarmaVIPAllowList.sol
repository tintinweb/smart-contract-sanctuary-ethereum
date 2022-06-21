/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

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




// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)




// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)





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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)





/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)



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


/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
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
        returns (uint256[] memory)
    {
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
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
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
    ) public virtual override {
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
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

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)





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


//   
//    ______     __   __     ______     __  __     ______     __     __   __    
//   /\  __ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\  __ \   /\ \   /\ "-.\ \   
//   \ \ \/\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \  __ \  \ \ \  \ \ \-.  \  
//    \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\ 
//     \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/\/_/   \/_/   \/_/ \/_/ 
//                                                                              
//    __    __     ______     __   __     __  __     ______     __  __          
//   /\ "-./  \   /\  __ \   /\ "-.\ \   /\ \/ /    /\  ___\   /\ \_\ \         
//   \ \ \-./\ \  \ \ \/\ \  \ \ \-.  \  \ \  _"-.  \ \  __\   \ \____ \        
//    \ \_\ \ \_\  \ \_____\  \ \_\\"\_\  \ \_\ \_\  \ \_____\  \/\_____\       
//     \/_/  \/_/   \/_____/   \/_/ \/_/   \/_/\/_/   \/_____/   \/_____/       
//                                                                              
//   
// 
// OnChainMonkey (OCM) Genesis was the first 100% On-Chain PFP collection in 1 transaction 
// (contract: 0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A)
// 
// created by Metagood
//
// OCM Karma VIP Allow List allows the holder to be first in line for a guaranteed spot to mint
// OCM Karma during the initial mint period. The nft will be burned when used.
//

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract OCMKarmaVIPAllowList is ERC1155, Ownable {
    string private svg1 = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1960" height="1960" fill="none"><style><![CDATA[.B{fill-rule:evenodd}.C{color-interpolation-filters:sRGB}]]></style><g clip-path="url(#L)"><path fill="#101010" d="M0 0h1960v1960H0z"/><g filter="url(#D)"><circle cx="986" cy="980" r="640" fill="#fff" fill-opacity=".2"/></g><path d="M919.9 352.1c1.878 11.96-5.976 23.24-17.72 25.32l4.485 25.44c26.15-4.611 43.61-29.55 39.0-55.7-.087-.495-.182-.987-.284-1.475l.023-.004-6.652-37.73-18.5 3.262.294 1.665c-2.599-1.357-5.327-2.481-8.152-3.349l7.431 42.15.76.43-.004.001zm-68.93 11.75l.38.21-.075-.421.0.21z" fill="#acacac" class="B"/><mask id="A" fill="#fff"><path d="M523.6 342.1c-43.51 7.672-72.57 49.17-64.89 92.68L677.4 1675c7.672 43.51 49.17 72.56 92.68 64.89l729.1-128.6c43.51-7.67 72.56-49.17 64.89-92.68L1345 278.4c-7.68-43.51-49.17-72.57-92.68-64.89L523.6 342.1zm293.8 40.5c-14.98 2.641-24.98 16.92-22.34 31.9s16.92 24.98 31.9 22.34l173.0-30.51c14.98-2.641 24.98-16.92 22.34-31.9s-16.92-24.98-31.9-22.34l-173.0 30.51z" class="B"/></mask><path d="M523.6 342.1c-43.51 7.672-72.57 49.17-64.89 92.68L677.4 1675c7.672 43.51 49.17 72.56 92.68 64.89l729.1-128.6c43.51-7.67 72.56-49.17 64.89-92.68L1345 278.4c-7.68-43.51-49.17-72.57-92.68-64.89L523.6 342.1zm293.8 40.5c-14.98 2.641-24.98 16.92-22.34 31.9s16.92 24.98 31.9 22.34l173.0-30.51c14.98-2.641 24.98-16.92 22.34-31.9s-16.92-24.98-31.9-22.34l-173.0 30.51z" fill="#262626" class="B"/><path d="M458.7 434.8l-13.79 2.431 13.79-2.431zM677.4 1675l13.79-2.43-13.79 2.43zm886.7-156.4l13.79-2.43-13.79 2.43zM1345 278.4l-13.79 2.431 13.79-2.431zM472.5 432.3c-6.329-35.9 17.64-70.13 53.54-76.46l-4.862-27.58c-51.13 9.015-85.26 57.77-76.25 108.9l27.57-4.862zM691.2 1673L472.5 432.3l-27.57 4.862L663.7 1678l27.57-4.86zm76.46 53.53c-35.9 6.33-70.13-17.64-76.46-53.53l-27.57 4.86c9.015 51.12 57.77 85.26 108.9 76.25l-4.863-27.58zm729.1-128.6l-729.1 128.6 4.863 27.58 729.1-128.6-4.86-27.58zm53.53-76.46c6.33 35.9-17.64 70.13-53.53 76.46l4.86 27.58c51.12-9.02 85.26-57.77 76.25-108.9l-27.58 4.86zM1332 280.9L1550 1521l27.58-4.86-218.7-1240-27.57 4.862zm-76.46-53.54c35.9-6.33 70.13 17.64 76.46 53.54l27.57-4.862c-9.01-51.13-57.77-85.26-108.9-76.25l4.86 27.58zm-729.1 128.6l729.1-128.6-4.86-27.58-729.1 128.6 4.862 27.58zm282.8 56.18a13.54 13.54 0 0 1 10.98-15.68l-4.862-27.58c-22.59 3.983-37.67 25.53-33.69 48.12l27.57-4.863zm15.68 10.98c-7.362 1.298-14.38-3.617-15.68-10.98l-27.57 4.863c3.983 22.59 25.53 37.67 48.12 33.69l-4.862-27.58zm173.0-30.51l-173.0 30.51 4.862 27.58 173.0-30.51-4.859-27.57zm10.98-15.68a13.54 13.54 0 0 1-10.98 15.68l4.859 27.57c22.59-3.983 37.68-25.53 33.69-48.12l-27.57 4.862zm-15.68-10.98a13.54 13.54 0 0 1 15.68 10.98l27.57-4.862c-3.98-22.59-25.52-37.67-48.11-33.69l4.862 27.58zm-173.0 30.51l173.0-30.51-4.862-27.58-173.0 30.51 4.862 27.58z" fill="url(#F)" mask="url(#A)"/><mask id="B" maskUnits="userSpaceOnUse" x="457" y="212" width="1109" height="1530" mask-type="alpha"><rect x="444.8" y="356.0" width="900.4" height="1420" rx="80" transform="rotate(350 444.8 356.0)" fill="#262626"/></mask><g mask="url(#B)"><g filter="url(#E)"><path d="M585.7 1155l765.2-845.0 77.42 439.0-765.2 845.0-77.41-439.0z" fill="#fff" fill-opacity=".2"/></g></g><path d="M790.0 1296l24.55-4.33c.792-.14 1.506.05 2.142.58.71.42 1.11.89 1.203 1.42s.128.0.101 1.34l-9.964 88.57c-.28 3.04-2.003 4.84-5.17 5.4l-30.09 5.31c-3.167.55-5.403-.55-6.706-3.31l-39.66-79.82c-.15-.34-.272-.77-.365-1.3-.093-.52.08-1.1.513-1.72.507-.72 1.156-1.16 1.948-1.3l24.55-4.32c3.167-.56 5.402.54 6.706 3.3l21.19 46.88 3.881-51.3c.28-3.04 2.003-4.84 5.171-5.4z" fill="url(#G)"/><path d="M874.7 1376l-26.92 4.75c-.968.2-1.866-.04-2.694-.62a3.47 3.47 0 0 1-1.498-2.32l-15.03-85.25c-.171-.97.03-1.86.613-2.69s1.354-1.33 2.322-1.5l26.92-4.75c.968-.17 1.866.04 2.694.62a3.47 3.47 0 0 1 1.498 2.32l15.03 85.25c.172.0-.034 1.86-.613 2.69s-1.354 1.33-2.321 1.5z" fill="url(#G)"/><path d="M882.6 1279l39.33-6.93c12.67-2.24 23.05-1.26 31.13 2.94s13.07 11.62 14.95 22.27c1.877 10.64-.298 19.14-6.524 25.5-6.139 6.35-15.59 10.64-28.34 12.89l-8.577 1.51 4.444 25.21a3.46 3.46 0 0 1-.613 2.69c-.58.83-1.354 1.33-2.322 1.5l-27.18 4.79c-.968.2-1.866-.03-2.694-.61a3.47 3.47 0 0 1-1.498-2.32l-15.03-85.25c-.171-.97.03-1.86.613-2.69s1.354-1.33 2.322-1.5zm34.42 19.24l2.583 14.65 9.238-1.63c1.583-.28 2.89-1.1 3.92-2.46 1.015-1.45 1.328-3.27.94-5.47s-1.197-3.97-2.429-5.29c-1.231-1.33-2.903-1.8-5.014-1.43l-9.238 1.63z" fill="url(#G)"/><path d="M1027 1254l39.33-6.93c12.67-2.24 23.05-1.26 31.13 2.94 8.09 4.2 13.07 11.62 14.95 22.27 1.88 10.64-.3 19.14-6.52 25.5-6.14 6.35-15.59 10.64-28.35 12.89l-8.57 1.52 4.44 25.2c.17.97-.03 1.87-.61 2.69-.58.83-1.36 1.33-2.32 1.5l-27.19 4.8c-.97.17-1.86-.04-2.69-.62s-1.33-1.35-1.5-2.32l-15.03-85.25c-.17-.97.03-1.86.61-2.69s1.36-1.33 2.32-1.5zm34.42 19.24l2.58 14.65 9.24-1.63c1.58-.28 2.89-1.1 3.92-2.46 1.01-1.45 1.33-3.27.94-5.47s-1.2-3.96-2.43-5.29c-1.23-1.32-2.9-1.8-5.01-1.43l-9.24 1.63z" fill="url(#G)"/><path d="M1138 1234l28.64-5.05c3.17-.56 5.4.54 6.71 3.3l44.27 79.01c.13.25.26.68.36 1.29.1.53-.11 1.16-.62 1.88-.43.62-1.04 1-1.84 1.14l-24.41 4.31c-2.64.46-4.55-.33-5.73-2.39l-4.7-8.15-28.37 5-1.63 9.27c-.41 2.34-1.93 3.74-4.57 4.2l-24.41 4.31c-.79.14-1.54 0-2.25-.42-.64-.52-1-1.05-1.1-1.58-.11-.61-.14-1.06-.1-1.34l14.58-89.38c.28-3.05 2.01-4.85 5.17-5.4zm16.5 53.42l14.91-2.63-11.85-23.22-3.06 25.85z" fill="url(#G)"/><path d="M1215 1251c-1.58-8.97.83-16.92 7.22-23.86 6.49-6.95 15.76-11.48 27.81-13.61 12.14-2.14 22.56-.94 31.25 3.61 8.78 4.53 13.74 10 14.87 16.42.14.8-.04 1.55-.55 2.28-.44.62-1 .99-1.71 1.12l-26.39 4.65c-2.02.36-4-.07-5.94-1.27-1.93-1.2-4.31-1.55-7.12-1.05-4.23.74-6.12 2.35-5.69 4.81.24 1.32 1.44 2.24 3.62 2.76 2.27.51 6.28.62 12.03.33 13.4-.64 23.27.8 29.61 4.31 6.4 3.4 10.4 9.63 12 18.7 1.58 8.97-1.26 17.05-8.52 24.22-7.19 7.07-17.42 11.78-30.71 14.13-13.28 2.34-24.19 1.45-32.72-2.67-8.52-4.12-13.48-10.1-14.86-17.93-.14-.79.01-1.5.45-2.12.5-.72 1.15-1.15 1.94-1.29l25.08-4.42c1.84-.33 4.02.19 6.53 1.57 2.6 1.35 5.88 1.68 9.84.98 6.6-1.16 9.68-2.97 9.24-5.44-.28-1.58-1.67-2.56-4.19-2.93-2.53-.46-7.17-.55-13.92-.27-23.23 1.01-36.28-6.66-39.17-23.03z" fill="url(#G)"/><path d="M1310 1234c-1.58-8.97.82-16.92 7.22-23.86 6.48-6.95 15.75-11.48 27.81-13.61 12.14-2.14 22.55-.94 31.25 3.61 8.78 4.53 13.74 10 14.87 16.42.14.8-.05 1.55-.55 2.28-.44.62-1.01.99-1.71 1.12l-26.39 4.65c-2.03.36-4.01-.07-5.94-1.27-1.94-1.2-4.31-1.55-7.13-1.05-4.22.74-6.11 2.35-5.68 4.81.23 1.32 1.44 2.24 3.62 2.76 2.26.51 6.27.62 12.03.33 13.4-.64 23.27.8 29.6 4.31 6.41 3.4 10.41 9.63 12.01 18.7 1.58 8.97-1.26 17.05-8.52 24.22-7.19 7.07-17.43 11.78-30.71 14.13-13.28 2.34-24.19 1.45-32.72-2.67s-13.48-10.1-14.86-17.93c-.14-.79.01-1.5.44-2.12.51-.72 1.16-1.15 1.95-1.29l25.07-4.42c1.85-.33 4.03.19 6.54 1.57 2.6 1.35 5.88 1.68 9.83.98 6.6-1.16 9.68-2.97 9.25-5.44-.28-1.58-1.68-2.56-4.19-2.93-2.53-.46-7.17-.55-13.93-.27-23.22 1.01-36.28-6.66-39.16-23.03z" fill="url(#G)"/><path d="M775.3 1533l8.58 48.66-9.19 1.62-8.58-48.66 9.19-1.62zm29.21-5.15l-15.33 27.17-9.059 13.89-3.211-8.63 5.98-11.43 10.36-19.02 11.26-1.98zm-1.646 50.46l-19.16-20.12 5.535-7.11 24.55 25.3-10.93 1.93zm54.66-52.2l-6.592 43.72-9.725 1.72 9.601-51.87 6.216-1.09.5 7.52zm18.87 39.23l-21.21-38.81-2.138-7.24 6.249-1.1 26.86 45.43-9.759 1.72zm-3.823-17.97l1.279 7.26-26.1 4.6-1.279-7.25 26.1-4.61zm37.39-38.12l17.68-3.12c3.698-.65 6.971-.65 9.819 0 2.848.64 5.177 1.93 6.988 3.86 1.811 1.94 2.997 4.49 3.559 7.68.444 2.52.384 4.78-.182 6.79-.565 2-1.551 3.77-2.957 5.31-1.384 1.53-3.105 2.84-5.163 3.94l-2.615 1.98-15.61 2.75-1.345-7.24 11.66-2.06c1.894-.33 3.406-.94 4.536-1.83s1.902-1.98 2.318-3.27c.438-1.29.523-2.7.256-4.21-.287-1.63-.846-2.98-1.678-4.05-.836-1.09-1.946-1.85-3.33-2.27-1.384-.43-3.045-.47-4.983-.12l-8.489 1.49 7.301 41.41-9.19 1.62-8.58-48.66zm36.05 43.82l-15.11-19.81 9.72-1.75 15.16 19.35.83.47-9.859 1.74zm38.85-57.03l7.953-1.4 19.76 34.28 6.81-38.96 7.98-1.41-9.5 51.85-6.38 1.12-26.63-45.48zm-4.011.71l7.787-1.37 7.338 33.4 2.646 15.01-9.191 1.62-8.58-48.66zm42.71-7.53l7.82-1.38 8.58 48.66-9.19 1.62-2.64-15-4.57-33.9zm65.81-3.99l-6.59 43.72-9.72 1.72 9.6-51.87 6.21-1.1.5 7.53zm18.88 39.23l-21.22-38.82-2.13-7.23 6.25-1.11 26.86 45.44-9.76 1.72zm-3.83-17.97l1.28 7.25-26.1 4.61-1.28-7.26 26.1-4.6zm85.83-46.66l7.95-1.4 19.76 34.28 6.81-38.97 7.99-1.41-9.5 51.85-6.38 1.13-26.63-45.48zm-4.01.71l7.79-1.38 7.33 33.41 2.65 15.01-9.19 1.62-8.58-48.66zm42.71-7.53l7.82-1.38 8.58 48.66-9.19 1.62-2.65-15.01-4.56-33.89zm54.35-9.59l8.58 48.66-9.19 1.62-8.58-48.66 9.19-1.62zm76.4-13.47l8.58 48.66-9.22 1.63-26.64-30.11 5.95 33.75-9.19 1.62-8.58-48.66 9.19-1.62 26.71 30.13-5.95-33.79 9.15-1.61zm56.62-9.98l8.58 48.66-9.15 1.61-8.58-48.66 9.15-1.61zm15.11-2.67l1.28 7.26-39.2 6.91-1.28-7.25 39.2-6.92z" fill="url(#H)"/><path transform="rotate(350 752.7 1463)" fill="url(#I)" d="M752.7 1463h677.4v9.615H752.7z"/><g class="B"><path d="M902.2 377.4h0l4.485 25.44h0c-26.15 4.611-51.08-12.85-55.7-39.0-.087-.495-.167-.99-.238-1.484l-.23.01-6.653-37.73 18.5-3.261.293 1.666a48.1 48.1 0 0 1 6.513-5.933l7.417 42.07.14.08.13.08.63.36.004-.001c2.327 11.89 13.57 19.8 25.31 17.73z" fill="#d9d9d9"/><path d="M697.5-33.43l70.51-32.88 95.97 205.8 19.79-226.2 77.5 6.781-31.54 360.5 7.332 15.72-9.078 4.233-1.583 18.09-31.34-2.742-28.51 13.3-7.676-16.46-9.978-.873 1.512-17.28L697.5-33.43z" fill="#8a8a8a"/></g><mask id="C" maskUnits="userSpaceOnUse" x="697" y="-67" width="241" height="397" mask-type="alpha"><path transform="matrix(-.9063 .422618 .422618 .9063 768.0 -66.31)" fill="#ff00f2" d="M0 0h77.8v400.0H0z"/></mask><g mask="url(#C)"><path transform="rotate(5 875.1 -125.5)" fill="#515151" d="M875.1-125.5h12.4v400.0h-12.4z"/></g><path fill="#fff" d="M821.8 254.0l119.7-21.1 14.12 80.06-119.7 21.1z"/><path transform="rotate(350 603.5 570.5)" stroke="url(#J)" stroke-width="16" d="M 603.5 570.5 L 1266 570.5 L 1266 1233 L 603.5 1233 Z"/><path d="M1185 730.4a72.13 72.13 0 0 0-11.52 3.049c-21.75-38.9-55.08-70.06-95.35-89.18-40.28-19.11-85.51-25.22-129.4-17.48-43.91 7.73-84.32 28.93-115.6 60.65s-51.96 72.4-59.1 116.4c-3.985.032-7.961.393-11.89 1.079a71.59 71.59 0 0 0-46.2 29.42 71.52 71.52 0 0 0-11.86 53.45 71.51 71.51 0 0 0 29.43 46.17c15.55 10.88 34.78 15.14 53.48 11.85a72.53 72.53 0 0 0 11.54-3.038c21.74 38.91 55.05 70.09 95.33 89.22 40.28 19.12 85.51 25.23 129.4 17.48 43.92-7.73 84.33-28.94 115.6-60.67a214.5 214.5 0 0 0 59.09-116.4 72.36 72.36 0 0 0 11.88-1.091 71.6 71.6 0 0 0 46.2-29.42 71.57 71.57 0 0 0 11.86-53.45 71.53 71.53 0 0 0-29.43-46.17 71.59 71.59 0 0 0-53.48-11.85zM781.4 903.2c-.62.11-1.225.303-1.86.415a28.63 28.63 0 0 1-21.39-4.738c-6.219-4.352-10.45-11.0-11.77-18.47s.389-15.16 4.744-21.38 11.0-10.45 18.48-11.77c.634-.111 1.255-.221 1.892-.231.4 9.527 1.424 19.02 3.077 28.41a215.5 215.5 0 0 0 6.828 27.76zm234.5 104.1c-44.86 7.91-91.03-2.31-128.3-28.43a171.6 171.6 0 0 1-70.63-110.8c-7.907-44.84 2.333-90.99 28.47-128.3s66.02-62.7 110.9-70.61 91.03 2.315 128.3 28.43a171.7 171.7 0 0 1 70.63 110.8c7.9 44.84-2.34 90.99-28.47 128.3a171.8 171.8 0 0 1-110.9 70.61zm186.6-178.2c-.62.11-1.24.218-1.87.243a215.2 215.2 0 0 0-3.1-28.42c-1.65-9.391-3.93-18.66-6.81-27.75.62-.109 1.23-.317 1.85-.426a28.64 28.64 0 0 1 21.39 4.738 28.61 28.61 0 0 1 11.77 18.47c1.31 7.473-.39 15.16-4.75 21.38-4.35 6.217-11 10.45-18.48 11.77zm-151.6-35.73a10.03 10.03 0 0 1-7.49-1.659c-2.18-1.523-3.66-3.848-4.12-6.464l19.74-3.48a10 10 0 0 1-1.67 7.484c-1.52 2.176-3.85 3.657-6.46 4.119zm-152.6 16.73l19.74-3.48a10.01 10.01 0 0 1-1.661 7.483 10.02 10.02 0 0 1-13.95 2.461 10.01 10.01 0 0 1-4.12-6.464zm201.5-35.53a38.36 38.36 0 0 1 .59 2.8c2.04 11.58-.6 23.51-7.35 33.14s-17.06 16.2-28.65 18.24-23.51-.598-33.15-7.344-16.2-17.04-18.25-28.63c-.16-.944-.33-1.874-.38-2.838l8.35-1.472a28.57 28.57 0 0 0 11.77 18.47 28.63 28.63 0 0 0 21.39 4.739c7.47-1.319 14.12-5.552 18.48-11.77 4.35-6.216 6.06-13.91 4.74-21.38l22.46-3.959zm-240.4 42.39l20.62-3.637a28.6 28.6 0 0 0 11.77 18.47 28.63 28.63 0 0 0 39.87-7.03c4.355-6.217 6.062-13.91 4.744-21.38l20.64-3.639c.375 12.04-3.602 23.8-11.2 33.15a50.12 50.12 0 0 1-30.18 17.73c-11.86 2.087-24.08-.166-34.41-6.348a50.07 50.07 0 0 1-21.86-27.31zm94.43-38.44l-105.7 18.64-3.727-21.13 105.7-18.64 3.726 21.13zm52.66-31.08l91.63-16.16 3.73 21.13-91.63 16.16-3.73-21.13zm-12.63 134.4c-65.39 11.53-114.6 42.34-110.0 68.78s61.46 38.56 126.9 27.03c65.4-11.53 114.6-42.32 110.0-68.78-4.67-26.46-61.45-38.56-126.9-27.03zm27.61 8.206a7.17 7.17 0 0 1 8.29 5.802c.33 1.869-.1 3.791-1.19 5.345-1.08 1.555-2.75 2.613-4.62 2.943a7.14 7.14 0 0 1-5.34-1.185c-1.56-1.088-2.62-2.749-2.95-4.617s.1-3.791 1.19-5.345a7.16 7.16 0 0 1 4.62-2.943zm-50.75 8.948c1.869-.329 3.793.097 5.348 1.185a7.15 7.15 0 0 1 1.756 9.963 7.16 7.16 0 0 1-4.62 2.942c-1.869.329-3.793-.097-5.348-1.185a7.15 7.15 0 0 1-2.942-4.617c-.33-1.869.097-3.791 1.186-5.345a7.16 7.16 0 0 1 4.62-2.943zm113.6 42.44l-155.1 27.34-.745-4.227 155.1-27.34.75 4.226z" fill="url(#K)"/></g><defs><filter id="D" x="-154" y="-160" width="2280" height="2280" filterUnits="userSpaceOnUse" class="C"><feFlood flood-opacity="0"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="250"/></filter><filter id="E" x="545.7" y="269.8" width="922.7" height="1364" filterUnits="userSpaceOnUse" class="C"><feFlood flood-opacity="0"/><feBlend in="SourceGraphic"/><feGaussianBlur stdDeviation="20"/></filter><linearGradient id="F" x1="888.2" y1="277.8" x2="1135" y2="1676" xlink:href="#M"><stop stop-color="#00f9c0"/><stop offset=".26" stop-color="#00c2ff"/><stop offset=".5" stop-color="#0fedc0"/><stop offset=".755" stop-color="#00c2ff"/><stop offset="1" stop-color="#0fedc0"/></linearGradient><linearGradient id="G" x1="718.0" y1="1137" x2="1037" y2="1599" xlink:href="#M"><stop offset=".007" stop-color="#0eedc0"/><stop offset=".244" stop-color="#00c2ff"/><stop offset=".438" stop-color="#0eedc0"/><stop offset=".891" stop-color="#00c2ff"/></linearGradient><linearGradient id="H" x1="776.0" y1="1444" x2="898.0" y2="1728" xlink:href="#M"><stop offset=".007" stop-color="#0eedc0"/><stop offset=".244" stop-color="#00c2ff"/><stop offset=".438" stop-color="#0eedc0"/><stop offset=".891" stop-color="#00c2ff"/></linearGradient><linearGradient id="I" x1="782.2" y1="1454" x2="783.2" y2="1491" xlink:href="#M"><stop offset=".007" stop-color="#0eedc0"/><stop offset=".244" stop-color="#00c2ff"/><stop offset=".438" stop-color="#0eedc0"/><stop offset=".891" stop-color="#00c2ff"/></linearGradient><linearGradient id="J" x1="933.4" y1="564.0" x2="933.4" y2="1242" xlink:href="#M"><stop/><stop offset=".745" stop-color="#898989" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity=".16"/></linearGradient><linearGradient id="K" x1="817.9" y1="577.4" x2="1232" y2="1069" xlink:href="#M"><stop offset=".073" stop-color="#0fedc0"/><stop offset=".332" stop-color="#00c2ff"/><stop offset=".764" stop-color="#0fedc0"/></linearGradient><clipPath id="L"><path fill="#fff" d="M0 0h1960v1960H0z"/></clipPath><linearGradient id="M" gradientUnits="userSpaceOnUse"/></defs></svg>';

    address public karmaContract; // allowed to eat/burn Desserts

    constructor() ERC1155("OCMKarmaVIPAllowList") {}

    // owner will air drop nfts via this mint function, designed to minimize gas used for multiple mints
    // if ads.length > quantity.length, transaction will fail and no mints will go through
    // if ads.length < quantity.length, the extra values in quantity will be ignored
    function ownerMint(address[] calldata ads, uint256[] calldata quantity) external onlyOwner {
        for (uint256 i=0; i<ads.length; i++) {
          _mint(ads[i], 1, quantity[i], "");
        }
    }

    // owner will air drop nfts via this mint function
    function ownerMint1(address[] calldata ads) external onlyOwner {
        for (uint256 i=0; i<ads.length; i++) {
          _mint(ads[i], 1, 1, "");
        }
    }    

    function setKarmaContractAddress(address karmaContractAddress) external onlyOwner {
        karmaContract = karmaContractAddress;
    }

    function burnAllowListForAddress(address burnTokenAddress) external {
        require(msg.sender == karmaContract, "ad err");
        _burn(burnTokenAddress, 1, 1);
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId==1, "type err");
        bytes memory svg;
        svg = bytes(svg1);
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{"name": "Karma VIP Allow List"}],"image": "data:image/svg+xml;base64,', Base64.encode(svg),'"}'))));
    }
}