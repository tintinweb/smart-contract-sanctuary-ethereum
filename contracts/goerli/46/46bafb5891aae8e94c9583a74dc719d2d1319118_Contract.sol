/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;






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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/Counters.sol

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
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

// File: contracts/Contract.sol

pragma solidity 0.8.17;

contract Contract is ERC1155, IERC2981, IERC1155Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => address) public creators;
    mapping (uint256 => address) public owners;
    mapping (uint256 => uint256) public prices;
    mapping (uint256 => string) public uris;
    mapping (uint256 => uint256) public royalties;
    mapping (uint256 => uint256) public cellsCount;
    mapping (uint256 => bool) public isAuction;
    mapping (address => uint256) public royaltyToWithdraw;
    mapping (uint256 => address) public auctionWinner;
    mapping (uint256 => uint256) public wonBidAmount;
    mapping (uint256 => bool) public isApproved;
    mapping (uint256 => bool) public isRejected;
    mapping (uint256 => bool) public isCreated;
    mapping (uint256 => uint256) public blockedCellsFee;
    mapping (uint256 => uint256) private tokenSupply;

    string public name;
    string public symbol;

    uint256 public cellCost = 1000000000000000;

    mapping (uint256 => mapping(address => bool)) public changeCellCostConfirmed;
    mapping (uint256 => mapping(address => bool)) public approveNftConfirmed;
    mapping (uint256 => mapping(string => mapping(address => bool))) public rejectNftConfirmed;
    mapping (
        uint256 => mapping(
            address => mapping(
                uint256 => mapping(uint256 => mapping(address => bool))
            )
        )
    ) private acceptBidConfirmed;
    mapping(address => mapping(address => bool)) public changeFirstAdminConfirmed;
    mapping(address => mapping(address => bool)) public changeSecondAdminConfirmed;
    mapping(address => mapping(address => bool)) public changeThirdAdminConfirmed;
    mapping(address => mapping(address => bool)) public changeReceiverConfirmed;

    address public _firstAdmin;
    address public _secondAdmin;
    address public _thirdAdmin;
    address public _ethReceiver;

    event Sold(address oldOwner, address newOwner, uint256 tokenId);
    event Withdraw(address receiver, uint256 tokenId);
    event Enter(address sender, uint256 tokenId);
    event NftApproved(uint256 tokenId);
    event NftRejected(uint256 tokenId, string rejectionReason);
    event RoyaltyWithdraw(address user, uint256 royalty);
    event BidAccepted(uint256 tokenId, address winner, uint256 bidAmount, uint256 bidId);
    event PriceChanged(uint256 tokenId, uint256 newPrice);
    event IsAuctionChanged(uint256 tokenId, bool isAuction, string sellType);

    constructor(address firstAdmin, address secondAdmin, address thirdAdmin, address ethReceiver) ERC1155("") {
        name = "NFT Marketplace";
        symbol = "NFT";

        _firstAdmin = firstAdmin;
        _secondAdmin = secondAdmin;
        _thirdAdmin = thirdAdmin;
        _ethReceiver = ethReceiver;
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return (uris[tokenId]);
    }

    function confirmFirstAdminChange(address firstAdmin) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );

        changeFirstAdminConfirmed[_msgSender()][firstAdmin] = true;
    }

    function setFirstAdmin(address firstAdmin) external {
        require(
            (changeFirstAdminConfirmed[_firstAdmin][firstAdmin] && changeFirstAdminConfirmed[_secondAdmin][firstAdmin]) ||
            (changeFirstAdminConfirmed[_firstAdmin][firstAdmin] && changeFirstAdminConfirmed[_thirdAdmin][firstAdmin]) ||
            (changeFirstAdminConfirmed[_secondAdmin][firstAdmin] && changeFirstAdminConfirmed[_thirdAdmin][firstAdmin]),
            "This operation needs to be confirmed by 2 admins"
        );

        _firstAdmin = firstAdmin;

        changeFirstAdminConfirmed[_firstAdmin][firstAdmin] = false;
        changeFirstAdminConfirmed[_secondAdmin][firstAdmin] = false;
        changeFirstAdminConfirmed[_thirdAdmin][firstAdmin] = false;
    }

    function confirmSecondAdminChange(address secondAdmin) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );

        changeSecondAdminConfirmed[_msgSender()][secondAdmin] = true;
    }

    function setSecondAdmin(address secondAdmin) external {
        require(
            (changeSecondAdminConfirmed[_firstAdmin][secondAdmin] && changeSecondAdminConfirmed[_secondAdmin][secondAdmin]) ||
            (changeSecondAdminConfirmed[_firstAdmin][secondAdmin] && changeSecondAdminConfirmed[_thirdAdmin][secondAdmin]) ||
            (changeSecondAdminConfirmed[_secondAdmin][secondAdmin] && changeSecondAdminConfirmed[_thirdAdmin][secondAdmin]),
            "This operation needs to be confirmed by 2 admins"
        );

        _secondAdmin = secondAdmin;

        changeSecondAdminConfirmed[_firstAdmin][secondAdmin] = false;
        changeSecondAdminConfirmed[_secondAdmin][secondAdmin] = false;
        changeSecondAdminConfirmed[_thirdAdmin][secondAdmin] = false;
    }

    function confirmThirdAdminChange(address thirdAdmin) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );

        changeThirdAdminConfirmed[_msgSender()][thirdAdmin] = true;
    }

    function setThirdAdmin(address thirdAdmin) external {
        require(
            (changeThirdAdminConfirmed[_firstAdmin][thirdAdmin] && changeThirdAdminConfirmed[_secondAdmin][thirdAdmin]) ||
            (changeThirdAdminConfirmed[_firstAdmin][thirdAdmin] && changeThirdAdminConfirmed[_thirdAdmin][thirdAdmin]) ||
            (changeThirdAdminConfirmed[_secondAdmin][thirdAdmin] && changeThirdAdminConfirmed[_thirdAdmin][thirdAdmin]),
            "This operation needs to be confirmed by 2 admins"
        );

        _thirdAdmin = thirdAdmin;

        changeThirdAdminConfirmed[_firstAdmin][thirdAdmin] = false;
        changeThirdAdminConfirmed[_secondAdmin][thirdAdmin] = false;
        changeThirdAdminConfirmed[_thirdAdmin][thirdAdmin] = false;
    }

    function confirmReceiverChange(address receiver) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );

        changeReceiverConfirmed[_msgSender()][receiver] = true;
    }

    function setReceiver(address receiver) external {
        require(
            (changeReceiverConfirmed[_firstAdmin][receiver] && changeReceiverConfirmed[_secondAdmin][receiver]) ||
            (changeReceiverConfirmed[_firstAdmin][receiver] && changeReceiverConfirmed[_thirdAdmin][receiver]) ||
            (changeReceiverConfirmed[_secondAdmin][receiver] && changeReceiverConfirmed[_thirdAdmin][receiver]),
            "This operation needs to be confirmed by 2 admins"
        );

        _ethReceiver = receiver;

        changeReceiverConfirmed[_firstAdmin][receiver] = false;
        changeReceiverConfirmed[_secondAdmin][receiver] = false;
        changeReceiverConfirmed[_thirdAdmin][receiver] = false;
    }

    function setPrice(uint256 price, uint256 _tokenId) public {
        require(_msgSender() == owners[_tokenId], "You are not an owner of this token");

        prices[_tokenId] = price;

        emit PriceChanged(_tokenId, price);
    }

    function setIsAuction(string memory sellType, bool _isAuction, uint256 price, uint256 _tokenId) external {
        require(_msgSender() == owners[_tokenId], "You are not an owner of this token");

        setPrice(price, _tokenId);

        isAuction[_tokenId] = _isAuction;

        emit IsAuctionChanged(_tokenId, _isAuction, sellType);
    }

    /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function confirmCellCostChange(uint256 _cellCost) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );

        changeCellCostConfirmed[_cellCost][_msgSender()] = true;
    }

    function setCellCost(uint256 _cellCost) external
    {
        require(
            (changeCellCostConfirmed[_cellCost][_firstAdmin] && changeCellCostConfirmed[_cellCost][_secondAdmin]) ||
            (changeCellCostConfirmed[_cellCost][_firstAdmin] && changeCellCostConfirmed[_cellCost][_thirdAdmin]) ||
            (changeCellCostConfirmed[_cellCost][_secondAdmin] && changeCellCostConfirmed[_cellCost][_thirdAdmin]), 
            "This operation needs to be confirmed by 2 admins"
        );

        cellCost = _cellCost;

        changeCellCostConfirmed[_cellCost][_firstAdmin] = false;
        changeCellCostConfirmed[_cellCost][_secondAdmin] = false;
        changeCellCostConfirmed[_cellCost][_thirdAdmin] = false;
    }

    function confirmAcceptBidOperation(uint256 _tokenId, address winner, uint256 bidAmount, uint256 bidId) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );

        acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_msgSender()] = true;
    }

    function acceptBid(uint256 _tokenId, address winner, uint256 bidAmount, uint256 bidId) external
    {
        bool isConfirmedByAdmins = (acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_firstAdmin] &&
            acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_secondAdmin]) ||
            (acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_firstAdmin] &&
            acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_thirdAdmin]) ||
            (acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_secondAdmin] &&
            acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_thirdAdmin]);

        require(_msgSender() == owners[_tokenId] || isConfirmedByAdmins, "You are not an owner of this token");
        require(isApproved[_tokenId], "Token isn't approved");
        require(!isRejected[_tokenId], "Token is rejected");
        require(winner != address(0), "Invalid winner address");
        require(isAuction[_tokenId], "This token is not in an auction");

        auctionWinner[_tokenId] = winner;
        wonBidAmount[_tokenId] = bidAmount;

        emit BidAccepted(_tokenId, winner, bidAmount, bidId);

        if (isConfirmedByAdmins) {
            acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_firstAdmin] = false;
            acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_secondAdmin] = false;
            acceptBidConfirmed[_tokenId][winner][bidAmount][bidId][_thirdAdmin] = false;
        }
    }

    function create(uint256 id) public
    {
        require(_exists(id), "Token doesn't exist");
        require(!isCreated[id], "Token is already created");

        _mint(address(this), id, 1, "0x0");

        isCreated[id] = true;
    }

    function payCellsFee(
        uint256 _cellsCount,
        uint256 price,
        uint256 royalty,
        bool _isAuction,
        string calldata _uri
    ) external payable returns (uint256)
    {
        require(bytes(_uri).length > 0, "Invalid URI");
        require(royalty <= 5000, "Royalty cannot exceed 50%");

        uint256 cellsPrice = cellCost * _cellsCount;
        require(msg.value >= cellsPrice, "Insufficient ETH amount to create this token");

        uint256 id = _tokenIds.current();

        creators[id] = _msgSender();
        owners[id] = _msgSender();
        tokenSupply[id] = 1;

        prices[id] = price;
        royalties[id] = royalty; 
        isAuction[id] = _isAuction;

        cellsCount[id] = _cellsCount;
        blockedCellsFee[id] = cellsPrice;

        uris[id] = _uri;

        emit URI(_uri, id);

        _tokenIds.increment();

        if (msg.value > cellsPrice) {
            uint256 change = msg.value - cellsPrice;

            (bool sent, ) = payable(_msgSender()).call{value: change}("");
            require(sent, "Failed to send change");
        }

        return id;
    }

    
    function confirmNftApproveOperation(uint256 _tokenId) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );
        require(_exists(_tokenId), "Token doesn't exist");

        approveNftConfirmed[_tokenId][_msgSender()] = true;
    }

    function approveNft(uint256 _tokenId) external {
        require(
            (approveNftConfirmed[_tokenId][_firstAdmin] && approveNftConfirmed[_tokenId][_secondAdmin]) ||
            (approveNftConfirmed[_tokenId][_firstAdmin] && approveNftConfirmed[_tokenId][_thirdAdmin]) ||
            (approveNftConfirmed[_tokenId][_secondAdmin] && approveNftConfirmed[_tokenId][_thirdAdmin]),
            "This operation needs to be confirmed by 2 admins"
        );
        require(_exists(_tokenId), "Token doesn't exist");
        require(!isApproved[_tokenId], "Token is already approved");
        require(!isRejected[_tokenId], "Token is rejected");
        isApproved[_tokenId] = true;

        approveNftConfirmed[_tokenId][_firstAdmin] = false;
        approveNftConfirmed[_tokenId][_secondAdmin] = false;
        approveNftConfirmed[_tokenId][_thirdAdmin] = false;

        emit NftApproved(_tokenId);

        uint256 feeAmount =  blockedCellsFee[_tokenId];
        blockedCellsFee[_tokenId] = 0;

        (bool sent, ) = payable(_ethReceiver).call{value: feeAmount}("");
        require(sent, "Failed to send cells fee to admin");
    }

    function confirmNftRejectOperation(uint256 _tokenId, string calldata rejectionReason) external {
        require(
            _firstAdmin == _msgSender() ||
            _secondAdmin == _msgSender() ||
            _thirdAdmin == _msgSender(),
            "You are not an admin"
        );
        require(_exists(_tokenId), "Token doesn't exist");

        rejectNftConfirmed[_tokenId][rejectionReason][_msgSender()] = true;
    }

    function rejectNft(uint256 _tokenId, string calldata rejectionReason) external {
        require(
            (rejectNftConfirmed[_tokenId][rejectionReason][_firstAdmin] && rejectNftConfirmed[_tokenId][rejectionReason][_secondAdmin]) ||
            (rejectNftConfirmed[_tokenId][rejectionReason][_firstAdmin] && rejectNftConfirmed[_tokenId][rejectionReason][_thirdAdmin]) ||
            (rejectNftConfirmed[_tokenId][rejectionReason][_secondAdmin] && rejectNftConfirmed[_tokenId][rejectionReason][_thirdAdmin]),
            "This operation needs to be confirmed by 2 admins"
        );
        require(_exists(_tokenId), "Token doesn't exist");
        require(!isRejected[_tokenId], "Token is already rejected");
        require(!isApproved[_tokenId], "Token is approved");
        isRejected[_tokenId] = true;

        rejectNftConfirmed[_tokenId][rejectionReason][_firstAdmin] = false;
        rejectNftConfirmed[_tokenId][rejectionReason][_secondAdmin] = false;
        rejectNftConfirmed[_tokenId][rejectionReason][_thirdAdmin] = false;

        emit NftRejected(_tokenId, rejectionReason);

        uint256 feeAmount =  blockedCellsFee[_tokenId];
        blockedCellsFee[_tokenId] = 0;

        (bool sent, ) = payable(creators[_tokenId]).call{value: feeAmount}("");
        require(sent, "Failed to send cells fee to creator");
    }

    function buyToken(uint256 _id, bool isFreeMinting) external payable
    {
        require(_exists(_id), "Token doesn't exist");
        require(isApproved[_id], "Token isn't approved");
        require(!isRejected[_id], "Token is rejected");
        require(_msgSender() != owners[_id], "You already own this art");
        require(!isAuction[_id] || auctionWinner[_id] == _msgSender(), "You are not a winner of auction");

        if (isFreeMinting) {
            create(_id);
        }

        require(balanceOf(address(this), _id) >= 1, "Insufficient balance for token");

        uint256 price;

        if (isAuction[_id]) {
            require(wonBidAmount[_id] > 0, "Incorrect won bid amount");
            price = wonBidAmount[_id];

            auctionWinner[_id] = address(0);
            wonBidAmount[_id] = 0;
        } else {
            price = prices[_id];
        }

        require(msg.value >= price, "Insufficient ETH amount to buy this token");

        emit Sold(owners[_id], _msgSender(), _id);

        uint256 royaltyAmount = price * royalties[_id] / 10000;

        address oldOwner = owners[_id];
        owners[_id] = _msgSender();

        require(royaltyToWithdraw[creators[_id]] + royaltyAmount >= royaltyToWithdraw[creators[_id]], "Royalty overflow");
        royaltyToWithdraw[creators[_id]] += royaltyAmount;

        (bool sent, ) = payable(oldOwner).call{value: price - royaltyAmount}("");
        require(sent, "Failed to send ETH to current owner");

        if (msg.value > price) {
            uint256 change = msg.value - price;

            (sent, ) = payable(_msgSender()).call{value: change}("");
            require(sent, "Failed to send change");
        }
    }

    function withdrawRoyalty(uint256 amount) external
    {
        require(amount > 0, "Amount must be greater than zero");
        require(royaltyToWithdraw[_msgSender()] >= amount, "Insufficient royalty amount");

        royaltyToWithdraw[_msgSender()] -= amount;

        emit RoyaltyWithdraw(_msgSender(), amount);

        (bool sent, ) = payable(_msgSender()).call{value: amount}("");
        require(sent, "Failed to send royalty amount");
    }

    function withdrawToken(uint256 _tokenId) external
    {
        require(_exists(_tokenId), "Token doesn't exist");
        require(balanceOf(address(this), _tokenId) > 0, "This token isn't created");
        require(_msgSender() == owners[_tokenId], "You don't have permitions for this action");
        _safeTransferFrom(address(this), _msgSender(), _tokenId, 1, "0x0");

        emit Withdraw(address(this), _tokenId);
    }

    function enterToken(uint256 _tokenId) external
    {
        require(_exists(_tokenId), "Token doesn't exist");
        require(balanceOf(_msgSender(), _tokenId) > 0, "You do not have this token");
        require(isApprovedForAll(_msgSender(), address(this)), "You should allow tokens transfer for this contract");

        _safeTransferFrom(_msgSender(), address(this), _tokenId, 1, "0x0");

        owners[_tokenId] = _msgSender();

        emit Enter(_msgSender(), _tokenId);
    }

    /** @dev EIP2981 royalties implementation. */

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address _receiver, uint256 royaltyAmount)
    {
        return (creators[_tokenId], (_salePrice * royalties[_tokenId]) / 10000);
    }

    /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}