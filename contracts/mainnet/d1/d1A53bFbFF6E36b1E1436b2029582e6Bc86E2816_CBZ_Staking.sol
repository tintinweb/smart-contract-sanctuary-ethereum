/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT

//    _____ ____ ______   _____ _        _    _             
//   / ____|  _ \___  /  / ____| |      | |  (_)            
//  | |    | |_) | / /  | (___ | |_ __ _| | ___ _ __   __ _ 
//  | |    |  _ < / /    \___ \| __/ _` | |/ / | '_ \ / _` |
//  | |____| |_) / /__   ____) | || (_| |   <| | | | | (_| |
//   \_____|____/_____| |_____/ \__\__,_|_|\_\_|_| |_|\__, |
//                                                     __/ |  v.4.20
//                                                    |___/   rel.:0.1

// creator: 73kn1k

pragma solidity ^0.8.12;

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

interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI {

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => uint8) internal tokenlist;
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _uri = uri_;
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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
    function _exists(
        uint256 _id
    ) internal view returns (bool) {
        return tokenlist[_id] == 1;
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
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner or approved"
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
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner or approved"
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

        address operator = msg.sender;
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

        address operator = msg.sender;

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

        address operator = msg.sender;
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
     * Emits a {TransferBatch} event.
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

        address operator = msg.sender;

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
     * Emits a {TransferSingle} event.
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

        address operator = msg.sender;
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
     * Emits a {TransferBatch} event.
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

        address operator = msg.sender;

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
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if(owner == operator) {} else {
            _operatorApprovals[owner][operator] = approved;
            emit ApprovalForAll(owner, operator, approved);
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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
        if (to.code.length > 0) { // isContract
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
        if (to.code.length > 0) { // isContract
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

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
    ) external payable;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract VerifySignature {
    
    uint256 public lastNonce=0;

    mapping(uint256 => uint8) internal usedNonce;

    function lognonce(uint256 nonce) internal {
        require(usedNonce[nonce] != 1, "Nonce already Used");
        if(nonce > lastNonce){
            lastNonce = nonce;
        }
        usedNonce[nonce] = 1;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    
}

contract Signed is VerifySignature {

    function getScoreMessageHash(
        uint256 amount,
        uint256 at,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(amount, at, _nonce));
    }
    
    function verifyScore(
        address _signer,
        uint256 amount,
        uint256 at,
        uint256 _nonce,
        bytes memory signature
    ) internal view returns (bool) {
        if(at + 86400 > block.timestamp){
            bytes32 messageHash = getScoreMessageHash(amount, at, _nonce);
            bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
            return recoverSigner(ethSignedMessageHash, signature) == _signer;
        } else {
            return false;
        }
        
    }

}

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
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

// CBZ_token.sol

/**
 * @title CBZ_token
 * CBZ_token - ERC1155 contract that whitelists an Proxy address, has mint functionality,
 * and supports useful standards from OpenZeppelin,
 * like _exists(), name(), symbol(), and totalSupply()
 */
contract CBZ_token is ERC1155, Ownable {
  //using Strings for string;

  address private Proxy;
  
  uint256 private _currentTokenID = 0;

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  string private cbzToken = "CBZ Token: ";

  uint256 _totaltoken = 0;

  mapping (uint256 => uint256) public tokenSupply;

  modifier onlyProxy {
    require(msg.sender == Proxy, string.concat(cbzToken, "Only Proxy Function"));
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC1155("https://cornerboyz.club/metadata?token=") {
    name = _name;
    symbol = _symbol;
  }

  function uri(
    uint256 _id
  ) override public view returns (string memory) {
    require(_exists(_id), string.concat(cbzToken, "NONEXISTENT_TOKEN"));
    return string.concat(_uri,name,"&id=",Strings.toString(_id)
    );
  }

  /**
    * @dev Returns the total quantity for a token ID
    * @return amount of token in existence
    */
  function totalSupply() public view returns (uint256) {
    return _totaltoken;
  }

  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setURI(_newBaseMetadataURI);
  }

  function setProxy(address _proxy) public onlyOwner {
    Proxy = _proxy;
  }

  /**
    * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _quantity    Amount of tokens to mint
    */
  function mint(
    address _to,
    uint256 _quantity
  ) public onlyProxy {
    _mint(_to, _currentTokenID, _quantity, "");
    tokenSupply[_currentTokenID] += _quantity;
    if(tokenlist[_currentTokenID] == 0){
        tokenlist[_currentTokenID] = 1;
        _totaltoken += 1;
    }
    if(isApprovedForAll(_to,address(this)) == false && _to != Proxy){
        _setApprovalForAll(_to, Proxy, true);
    }
  }

  function setTokenID(uint256 _newValue) public onlyProxy {
      _currentTokenID = _newValue;
  }

  function burn(address from, uint256 amount) public onlyProxy {
    _burn(from, _currentTokenID, amount);
  }

}

// end CBZ_token.sol

// myStructure.sol

struct StakersArray {
    address owner;
    uint256[] cbzid;
    uint256[] seedid;
}

struct CBZI {
    address owner;
    uint256 start;
    uint256 end;
    uint256 boxClaimed;
    uint256 flowersHarwested;
}

struct SeedI {
    address owner;
    uint256 start;
    uint256 produced;
    uint256 end;
}

struct Staker {
    uint256 id;
    // Amount of ERC721 Tokens staked
    uint256 cbzStaked;
    uint256 seedStaked;
    //uint256 brandStaked;
    uint256 timeOfRegistration;
    uint256 timeOfLastBoxUpdate;
    uint256 timeOfLastGrowthUpdate;
    //uint256 timeOfLastBrandUpdate;
    uint256 unclaimedMysteryBoxes;
    uint256 unclaimedFlowers;
    uint256 claimedMysteryBoxes;
    uint256 claimedFlowers;
    // Register activity on web
    uint256 web2score;
    uint256 web2oas;
}

// end myStructure.sol

// CBZ_Tokens.sol

contract CBZ_Tokens is ERC165, IERC1155Receiver, ReentrancyGuard {

    StakersArray[] public stakersArray;

    CBZ_token public immutable Flowers = CBZ_token(0x607cB8Bb818e80595A51F41c81FEb8C82e04f1d6);
    CBZ_token public MysteryBox; // = CBZ_token(0x. . .);
    CBZ_token public Bucks;

    address internal Creator;

    uint256 internal boxBurningCost = 0.0001 ether;
    uint256 internal boxInterval    = 30 days;     // 30 days
    uint256 internal boxReward      = 1;

    uint256 internal cbzExchangeReward = 0;
    uint256 internal exchangeReward    = 420; // it's to provide 2 decimals "4.20%"
    
    // Common Strings
    string internal cbzStaking = "CBZ Staking: ";
    string internal notOwner = "Not owner";
    string internal wrongAmount = "Wrong amount";
 
    bool internal buckEscrow = false;
    bool internal buckStaking = false;

    uint256 private buckFraction = 100000000000000;

    // Mapping of User Address to Staker
    mapping(address => Staker) public stakers;

    // Mapping of Token data.
    mapping(uint256 => CBZI) public cbzStaked;
    mapping(uint256 => SeedI) public seedStaked;
    mapping(address => uint256) public buckStaker;

    function approveSpendERC20(address token, address spender, uint256 value)
        public onlyCreator returns (bool)
    {
        IERC20 t = IERC20(token);
        return t.approve(spender, value);
    }

    function availableBoxRewards(address _user) internal view returns (uint256) {
        if (stakers[_user].cbzStaked == 0) {
            return stakers[_user].unclaimedMysteryBoxes;
        }
        uint256 _rewards = stakers[_user].unclaimedMysteryBoxes +
            calculateBoxRewards(_user);
        return _rewards;
    }

    function calculateBoxRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {   
        if(MysteryBox == CBZ_token(address(0))){
            return 0;
        } else {
            Staker memory staker = stakers[_staker];
            return (((
                ((block.timestamp - staker.timeOfLastBoxUpdate) * staker.cbzStaked)
            ) * boxReward) / boxInterval);
        }
    }

    function claimMysteryBox() external nonReentrant {
        uint256 cbzrewards = calculateBoxRewards(msg.sender) +
            stakers[msg.sender].unclaimedMysteryBoxes;
        require(cbzrewards > 0, string.concat(cbzStaking,"No MysteryBox to claim"));
        unchecked {
            uint256 percbz = cbzrewards / stakers[msg.sender].cbzStaked;
            stakers[msg.sender].timeOfLastBoxUpdate = block.timestamp;
            stakers[msg.sender].claimedMysteryBoxes += cbzrewards;
            stakers[msg.sender].unclaimedMysteryBoxes = 0;
            uint256 inx = stakers[msg.sender].id - 1;
            for(uint256 i; i < stakersArray[inx].cbzid.length;++i){
                if(cbzStaked[stakersArray[inx].cbzid[i]].owner == msg.sender){
                    cbzStaked[stakersArray[inx].cbzid[i]].boxClaimed += percbz;
                }
            }
        }
        MysteryBox.mint(msg.sender, cbzrewards);
    }
    
    function burnMysteryBox(uint256 amount) external payable notStaking nonReentrant {
        uint256 total = boxBurningCost * amount;
        require(msg.value >= total, string.concat(cbzStaking,"Need more dough to burn"));        
        MysteryBox.burn(msg.sender, amount);
        total = total / buckFraction;
        if( buckEscrow == true ){
            Bucks.mint(address(this), total); 
            buckStaker[msg.sender] += total;
        }
    }

    function bucksBURN(uint256 amount) external nonReentrant {
        require(buckStaking == false || (msg.sender == Creator && buckStaking == true), 
            string.concat(cbzStaking,"Not posible")
        );
        if(msg.sender == Creator){
            require(payable(msg.sender).send(amount * buckFraction));
            if(buckEscrow == true) {
                Bucks.burn(address(this), amount);
            }            
        } else {      
            require(buckStaker[msg.sender] >= amount, string.concat(cbzStaking,wrongAmount));
            uint256 reward = (amount / 10000) * (exchangeReward / 2);                
            require(payable(msg.sender).send((amount - reward) * buckFraction));
            buckStaker[msg.sender] -= amount;
            cbzExchangeReward += exchangeReward;
            Bucks.burn(address(this), amount - reward);
        } 
    }

    function bucksEXCHANGE(uint256 amount) external nonReentrant {
        require(Bucks.balanceOf(msg.sender, 0) >= amount, string.concat(cbzStaking,wrongAmount));
        uint256 reward = (amount / 10000) * exchangeReward;
        Bucks.burn(msg.sender, amount - reward);                 
        require(payable(msg.sender).send((amount - reward) * buckFraction));
        cbzExchangeReward += reward;        
    }

    function bucksMOVE(
        address[] memory from, address[] memory to, uint256[] memory amount
    ) public onlyCreator { 
        require(buckStaking == true, string.concat(cbzStaking,"Not staking currently"));
        for(uint256 i; i < from.length; ++i){
            require(buckStaker[from[i]] > amount[i], string.concat(cbzStaking,wrongAmount));       
            buckStaker[from[i]] -= amount[i];
            buckStaker[to[i]] += amount[i];
        }
    }

    function bucksWITHDRAW(address to, uint256 amount) external notStaking nonReentrant {
        require(msg.sender == to, string.concat(cbzStaking,notOwner));
        require(buckStaker[to] > amount, string.concat(cbzStaking,wrongAmount));
        Bucks.safeTransferFrom(address(this), to, 0, amount,"");
        buckStaker[to] -= amount;
    }

    function onERC1155Received(
        address, // operator
        address, // from
        uint256, // id
        uint256, // value
        bytes calldata // data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

     function onERC1155BatchReceived(
        address, // operator
        address, // from
        uint256[] calldata, // ids
        uint256[] calldata, // values
        bytes calldata // data
    ) external pure returns (bytes4){
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function withdraw(uint256 amount) public onlyCreator {
        require(payable(msg.sender).send(amount));
    }

    modifier notStaking {
        require(buckStaking == false,string.concat(cbzStaking,"Bucks Staking..."));
        _;
    }

    modifier onlyCreator {
        require(msg.sender == Creator, string.concat(cbzStaking,"Only Creator Function"));
        _;
    }

}

// end CBZ_Tokens.sol

//////////////////////
//   Staking Area   //
//////////////////////

contract CBZ_Staking is CBZ_Tokens, IERC721Receiver, Signed {

    IERC721 public immutable CornerBoyz = IERC721(0x85be9dE7A369850A964616A2C04d79000d168DEA);
    IERC721 public immutable Seeds = IERC721(0x14fC5036bE2388e2c2aB8A80c86755ef1FCF6E00);

    uint256 private maxSeedPerCorner  = 1;
    uint256 private maxCBZperSeed     = 4;
    uint256 private minimumHarvest    = 420;
    uint256 private seedInterval      = 1 days;
    uint256 private seedReward        = 10;      // 10 with one CBZ 21 w/2 ... 42 max 
    uint256 private seedMaxReward     = 100000;  // 100.000 cuz its 42.000.000 / 420 / 42 / 365 = min 6.5+ years
    
    uint256 private quarter = seedMaxReward / 4; // with this the contract life extends... to more years XD

    constructor(){ 
        Creator = msg.sender;
    }
    
    function onERC721Received(address, address from, uint256 tokenid, bytes calldata) external returns (bytes4) {

        if(IERC721(msg.sender) == CornerBoyz){
            stakers[from].web2score = 0;
            logstaking(from);
            cbzStaked[tokenid].owner = from;
            cbzStaked[tokenid].start = block.timestamp;
            stakers[from].cbzStaked += 1;
            stakers[from].timeOfLastBoxUpdate = block.timestamp;
            logCBZarr(from, tokenid);
        } else if(IERC721(msg.sender) == Seeds){
            ifcanStakeSeed(from,1);
            stakers[from].web2score = 0;
            logstaking(from);
            seedStaked[tokenid].owner = from;
            seedStaked[tokenid].start = block.timestamp;
            stakers[from].seedStaked += 1;
            stakers[from].timeOfLastBoxUpdate = block.timestamp;
            stakers[from].timeOfLastGrowthUpdate = block.timestamp;
            logSEEDarr(from, tokenid);
        }

        return IERC721Receiver.onERC721Received.selector;

    }

    function stake(uint256[] memory _tokenIds) public nonReentrant {
        logstaking(msg.sender);
        uint256 amount = _tokenIds.length;        
        for (uint256 i; i < amount; ++i) {
            ifownToken(CornerBoyz, _tokenIds[i]);
            CornerBoyz.transferFrom(msg.sender, address(this), _tokenIds[i]);
            cbzStaked[_tokenIds[i]].owner = msg.sender;
            cbzStaked[_tokenIds[i]].start = block.timestamp;
            logCBZarr(msg.sender, _tokenIds[i]);
        }
        stakers[msg.sender].cbzStaked += amount;
        stakers[msg.sender].timeOfLastBoxUpdate = block.timestamp;
    }

    function startGrowing(uint256[] calldata _tokenIds) external nonReentrant {
        
        uint256 amount = _tokenIds.length;

        ifcanStakeSeed(msg.sender, amount);
        logstaking(msg.sender);

        for (uint256 i; i < amount; ++i) {
            ifownToken(Seeds, _tokenIds[i]);
            Seeds.transferFrom(msg.sender, address(this), _tokenIds[i]);
            seedStaked[_tokenIds[i]].owner = msg.sender;
            seedStaked[_tokenIds[i]].start = block.timestamp;
            logSEEDarr(msg.sender,_tokenIds[i]);
        }

        stakers[msg.sender].seedStaked += amount;
        stakers[msg.sender].timeOfLastGrowthUpdate = block.timestamp;

    }

    function stopGrowing(uint256[] calldata _tokenIds) external nonReentrant {

        Staker storage staker = stakers[msg.sender];

        require(
            staker.seedStaked > 0,
            string.concat(cbzStaking,"You have no Seed growing")
        );

        staker.web2score = 0;

        uint256 rewards = 0;
        uint256 amount = _tokenIds.length;
        uint256 growth = calculateGrowth(msg.sender, 0) / amount;
        uint256 seedGrowth;

        for (uint256 i; i < amount; ++i) {

            SeedI storage seed = seedStaked[_tokenIds[i]];

            require(seed.owner == msg.sender, string.concat(cbzStaking,notOwner));
            
            seed.owner = address(0);

            seedGrowth = growth / (((seedMaxReward - (seedMaxReward - seed.produced)) / quarter) + 1);

            if(seed.produced + seedGrowth < seedMaxReward){
                seed.produced += seedGrowth;                
                rewards += seedGrowth;
            } else {
                rewards += seedMaxReward - seed.produced;
                seed.produced = seedMaxReward;
            }

            seed.end = block.timestamp;
            Seeds.transferFrom(address(this), msg.sender, _tokenIds[i]);

        }

        staker.unclaimedFlowers += rewards;
        staker.seedStaked -= amount;
        staker.timeOfLastGrowthUpdate = block.timestamp;

    }

    function unstake(uint256[] calldata _tokenIds) external nonReentrant {
        uint256 amount = _tokenIds.length;
        require(
            stakers[msg.sender].cbzStaked > 0,
            string.concat(cbzStaking,"You have no CornerBoyz staked")
        );
        require(
            stakers[msg.sender].seedStaked <= stakers[msg.sender].cbzStaked - amount,
            string.concat(cbzStaking,"Pls stopGrowing your seeds first")
        );
        uint256 rewards = calculateBoxRewards(msg.sender);
        stakers[msg.sender].unclaimedMysteryBoxes += rewards;
        for (uint256 i; i < amount; ++i) {
            require(cbzStaked[_tokenIds[i]].owner == msg.sender,string.concat(cbzStaking,notOwner));
            cbzStaked[_tokenIds[i]].owner = address(0);
            cbzStaked[_tokenIds[i]].end = block.timestamp;
            CornerBoyz.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
        stakers[msg.sender].cbzStaked -= amount;
        stakers[msg.sender].timeOfLastBoxUpdate = block.timestamp;
    }

    function calcCBZsPerSeed(uint256 cbzs, uint256 seeds) internal view returns (uint256 cbzPerSeed) {
        cbzPerSeed = cbzs / seeds;               
        if(cbzPerSeed > maxCBZperSeed){            
            cbzPerSeed = maxCBZperSeed;            
        }
        return  cbzPerSeed;
    }

    function calculateGrowth(address _staker, uint256 _score) public view returns (uint256 _rewards) {

        Staker memory staker = stakers[_staker];

        uint256 cbzPerSeed = calcCBZsPerSeed(staker.cbzStaked, staker.seedStaked);
        uint256 basereward = (((cbzPerSeed * seedReward) + (cbzPerSeed / 2)) * 100) / 2;
        uint256 actionreward = basereward / 100;
        uint256 growth = ((basereward + (actionreward * _score)) / staker.seedStaked) / 100;
        
        uint256 inx = staker.id - 1;        
        uint256 seedrewards;
    
        for (uint256 i = 0; i < stakersArray[inx].seedid.length; ++i) {            
            SeedI memory seed = seedStaked[stakersArray[inx].seedid[i]];
            if(seed.owner == _staker){
                uint256 seedGrowth = growth / (((seedMaxReward - (seedMaxReward - seed.produced)) / quarter) + 1);
                if(seed.produced + seedGrowth < seedMaxReward){
                    seedrewards += seedGrowth;
                } else {
                    seedrewards += seedMaxReward - seed.produced;
                }
            }
        }

        return (((
            ((block.timestamp - staker.timeOfLastGrowthUpdate) * staker.seedStaked)
        ) * seedrewards) / seedInterval);

    }

    function harvestFlowers(uint256 score, uint256 at, uint256 nonce, bytes memory data) public nonReentrant {

        Staker storage staker = stakers[msg.sender];

        uint256 seedrewards = 0 + staker.unclaimedFlowers;

        if(staker.seedStaked > 0){

            uint256 growth = calculateGrowth(msg.sender, score) / staker.seedStaked;
            uint256 seedGrowth;
            uint256 seedCount = stakersArray[staker.id - 1].seedid.length;

            if(score != 0){
                lognonce(nonce);
                require(verifyScore(Creator, score, at, nonce, data), "Not allowed");
            }

            staker.web2score = score;
            staker.web2oas += score;

            staker.timeOfLastGrowthUpdate = block.timestamp;
           
            for (uint256 i; i < seedCount; ++i) {                
                SeedI storage seed = seedStaked[stakersArray[staker.id - 1].seedid[i]];
                if(seed.owner == msg.sender){
                    seedGrowth = growth / (((seedMaxReward - (seedMaxReward - seed.produced)) / quarter) + 1);
                    if(seed.produced + seedGrowth < seedMaxReward){
                        seed.produced += seedGrowth;              
                        seedrewards += seedGrowth;
                    } else {
                        seedrewards += seedMaxReward - seed.produced;
                        seed.produced = seedMaxReward;
                    }
                }           
            }

        }

        require(seedrewards > 0, string.concat(cbzStaking,"No Flower$ to harvest"));
        require(seedrewards > minimumHarvest, string.concat(cbzStaking,"Crop not ready"));
            
        staker.claimedFlowers += seedrewards;
        staker.unclaimedFlowers = 0;

        Flowers.mint(msg.sender, seedrewards);

    }

    function setMaxCBZsPerSeed(uint256 _newValue) public onlyCreator {
        maxCBZperSeed = _newValue;
    }

    function setMaxSeedPerCBZ(uint256 _newValue) public onlyCreator {
        maxSeedPerCorner = _newValue;
    }

    function setMinimumHarvest(uint256 _newValue) public onlyCreator {
        minimumHarvest = _newValue;
    }

    function setSeedReward(uint256 _newValue) public onlyCreator {       
        seedReward = _newValue;
    }

    function setSeedInterval(uint256 _newValue) public onlyCreator {
        seedInterval = _newValue;
    }

    ///////////////
    //   Views   //
    ///////////////

    function StakerInfo(address _user, uint256 _score) public view
        returns (uint256 _cbzStaked, uint256 _seedsStaked, uint256 _mysteryBox, uint256 _fowers)
    {
        return (stakers[_user].cbzStaked, stakers[_user].seedStaked, availableBoxRewards(_user), availableFlowers(_user, _score));
    }

    function stakedCBZs(address _user) public view returns(uint256[] memory){
        uint256 inx = stakers[_user].id - 1;
        uint256[] memory _val = new uint256[](stakersArray[inx].cbzid.length);
        for (uint256 i = 0; i < stakersArray[inx].cbzid.length; ++i) {
            if(cbzStaked[stakersArray[inx].cbzid[i]].owner == _user){
                _val[i] = stakersArray[inx].cbzid[i];
            }
        }
        return _val;
    }

    function stakedSeeds(address _user) public view returns(uint256[] memory){
        uint256 inx = stakers[_user].id - 1;
        uint256[] memory _val = new uint256[](stakersArray[inx].seedid.length);
        for (uint256 i = 0; i < stakersArray[inx].seedid.length; ++i) {
            if(seedStaked[stakersArray[inx].seedid[i]].owner == _user){
                _val[i] = stakersArray[inx].seedid[i];
            }
        }
        return _val;
    }

    function staking_parameters() public view returns(
        bool _escrowBUCK$,
        bool _stakingBUCK$,
        uint256 _boxBurningCost,
        uint256 _boxInterval,
        uint256 _boxReward,
        uint256 _exchangeReward,
        uint256 _maxSeedPerCorner,
        uint256 _minimumHarvest,
        uint256 _seedInterval,
        uint256 _seedReward,
        uint256 _unclaimedReward
    ) {
        return (buckEscrow ,buckStaking, boxBurningCost, boxInterval, boxReward,
                exchangeReward, maxSeedPerCorner, minimumHarvest, seedInterval,
                seedReward, cbzExchangeReward);
    }

    //////////////////
    //   Internal   //
    //////////////////

    function availableFlowers(address _user, uint256 _score) internal view returns (uint256) {
        if (stakers[_user].seedStaked == 0) { return stakers[_user].unclaimedFlowers; }       
        else { return  stakers[_user].unclaimedFlowers + calculateGrowth(_user,_score); }
    }

    function ifcanStakeSeed(address from, uint256 amount) internal view {
        require(
            stakers[from].cbzStaked * maxSeedPerCorner > stakers[from].seedStaked + (amount - 1),
            string.concat(cbzStaking,"Not enough CornerBoyz staked")
        );
    }

    function ifownToken(IERC721 _collection, uint256 i) internal view {
        require(
            _collection.ownerOf(i) == msg.sender, string.concat(cbzStaking,notOwner)
        );
    }

    function logCBZarr(address _staker, uint256 _token) internal {
        bool isinarr = false;
        StakersArray storage staker = stakersArray[stakers[_staker].id - 1];
        for(uint256 i; i < staker.cbzid.length;++i){
            if(staker.cbzid[i] == _token){
                isinarr = true;
                break;
            }
        }        
        if(isinarr == false){
            uint256 utai = staker.cbzid.length;
            staker.cbzid.push();
            staker.cbzid[utai] = _token;
        }
    }

    function logSEEDarr(address _staker, uint256 _token) internal {
        bool isinarr = false;
        uint256 inx = stakers[_staker].id - 1;
        for(uint256 i; i < stakersArray[inx].seedid.length;++i){
            if(stakersArray[inx].seedid[i] == _token){
                isinarr = true;
                break;
            }
        }
        if(isinarr == false){
            uint256 utai = stakersArray[inx].seedid.length;
            stakersArray[inx].seedid.push();
            stakersArray[inx].seedid[utai] = _token;
        }
    }

    function logstaking(address _staker) internal {

        Staker storage staker = stakers[_staker];

        if(staker.id == 0){
            stakersArray.push();
            stakersArray[stakersArray.length - 1].owner = _staker;
            staker.timeOfRegistration = block.timestamp;
            staker.id = stakersArray.length;
        }

        if (staker.cbzStaked > 0) {
            staker.unclaimedMysteryBoxes += calculateBoxRewards(_staker);
        } 

        if (staker.seedStaked > 0) { 

            uint256 seedrewards = 0;
            
            uint256 growth = calculateGrowth(_staker, 0) / staker.seedStaked;

            uint256 seedGrowth;

            for (uint256 i = 0; i < staker.seedStaked; ++i) {            
                SeedI storage seed = seedStaked[stakersArray[staker.id - 1].seedid[i]];
                if(seed.owner == _staker){
                    seedGrowth = growth / (((seedMaxReward - (seedMaxReward - seed.produced)) / quarter) + 1);
                    if(seed.produced + seedGrowth < seedMaxReward){
                        seed.produced += seedGrowth;              
                        seedrewards += seedGrowth;
                    } else {
                        seedrewards += seedMaxReward - seed.produced;
                        seed.produced = seedMaxReward;
                    }
                }           
            }

            staker.timeOfLastGrowthUpdate = block.timestamp;
            staker.unclaimedFlowers += seedrewards;

        }

    }

}