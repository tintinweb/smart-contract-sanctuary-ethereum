// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// shamelessly stolen from the anonymice contract
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts the input data into a base64 string.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IUtilityERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./ChainScoutsExtension.sol";
import "./OpenSeaMetadata.sol";

/**
 * Base class for creating "passes" e.g. Scout Pass purchaseable with a Utility ERC20 token.
 */
abstract contract BasePass is ChainScoutsExtension, ERC1155Supply {
    IUtilityERC20 public token;
    uint256 public price;
    string public name;
    uint256 public MAX_SUPPLY;

    IERC1155 public oldPass; // old scout pass address
    uint256 public oldSupply; // migration purpose only

    constructor() ERC1155("") {}

    function init(
        address _oldPass,
        uint256 _oldSupply,
        address _token,
        uint256 _price,
        string memory _name
    ) internal {
        _setURI("");
        MAX_SUPPLY = 3_444;
        oldPass = IERC1155(_oldPass);
        oldSupply = _oldSupply;
        token = IUtilityERC20(_token);
        price = _price;
        name = _name;
    }

    /**
     * Sets the name of the pass. OpenSea uses this to determine the collection name.
     */
    function adminSetName(string memory _name) external onlyAdmin {
        name = _name;
    }

    /**
     * Sets the token used to purchase the pass.
     */
    function adminSetToken(IUtilityERC20 _token) external onlyAdmin {
        token = _token;
    }

    /**
     * Sets the amount of token() needed to purchase a pass. Remember that this is wei (10^-18 eth) for most tokens.
     */
    function adminSetPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    /**
     * Sets old supply for migration
     */
    function adminSetOldSupply(uint oldSupply_) external onlyAdmin {
        oldSupply = oldSupply_;
    }

    /**
     * Sets old pass for migration
     */
    function adminSetOldPass(address oldPass_) external onlyAdmin {
        oldPass = IERC1155(oldPass_);
    }

    /**
     * @dev Burns one or more passes. This is used by contracts that require passes in exchange for services.
     * You must be the owner of the pass(es) being burnt or an admin.
     */
    function burn(address owner, uint256 count) external virtual whenEnabled {
        require(
            chainScouts.isAdmin(msg.sender) || msg.sender == owner,
            "must be admin or owner"
        );
        _burn(msg.sender, 0, count);
    }

    /**
     * @dev Purchases one or more passes. Requires price() token() per pass.
     */
    function migrate(uint256 count) public virtual whenEnabled {
        require(count > 0, "Must be at least one");
        oldPass.safeTransferFrom(msg.sender, address(this), 0, count, hex"");
        _mint(msg.sender, 0, count, hex"");
    }

    /**
     * @dev Purchases one or more passes. Requires price() token() per pass.
     */
    function purchase(uint256 count) public virtual whenEnabled {
        require(count > 0, "Must mint at least one");
        require(totalSupply(0)+count <= MAX_SUPPLY-oldSupply, "Exceed max supply");
        token.burn(msg.sender, count * price);
        _mint(msg.sender, 0, count, hex"");
    }

    /**
     * @dev Returns the metadata of the pass. Used by OpenSea to render the image.
     */
    function metadata() public virtual view returns (OpenSeaMetadata memory);

    /**
     * @dev Returns the "symbol" of the pass. For example, Ethereum's symbol is "ETH".
     */
    function symbol() public virtual view returns (string memory);

    function uri(uint) public override view returns (string memory) {
        return OpenSeaMetadataLibrary.makeERC1155Metadata(metadata(), symbol());
    }

    // onReceive functions signatures
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
    ) public pure returns (bytes4) {
        return 0xf23a6e61; 
    }

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
    ) public pure returns (bytes4) { return 0xbc197c81; }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";

struct KeyValuePair {
    string key;
    string value;
}

struct ChainScoutMetadata {
    Accessory accessory;
    BackAccessory backaccessory;
    Background background;
    Clothing clothing;
    Eyes eyes;
    Fur fur;
    Head head;
    Mouth mouth;
    uint24 attack;
    uint24 defense;
    uint24 luck;
    uint24 speed;
    uint24 strength;
    uint24 intelligence;
    uint16 level;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainScouts.sol";

abstract contract ChainScoutsExtension {
    IChainScouts internal chainScouts;
    bool public enabled = true;

    modifier canAccessToken(uint tokenId) {
        require(chainScouts.canAccessToken(msg.sender, tokenId), "ChainScoutsExtension: you don't own the token");
        _;
    }

    modifier onlyAdmin() {
        require(chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: admins only");
        _;
    }

    modifier whenEnabled() {
        require(enabled, "ChainScoutsExtension: currently disabled");
        _;
    }

    function adminSetEnabled(bool e) external onlyAdmin {
        enabled = e;
    }

    function extensionKey() public virtual view returns (string memory);

    function setChainScouts(IChainScouts _contract) external {
        require(address(0) == address(chainScouts) || chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: The Chain Scouts contract must not be set or you must be an admin");
        chainScouts = _contract;
        chainScouts.adminSetExtension(extensionKey(), this);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Accessory {
    GOLD_EARRINGS,
    SCARS,
    GOLDEN_CHAIN,
    AMULET,
    CUBAN_LINK_GOLD_CHAIN,
    FANNY_PACK,
    NONE
}

enum BackAccessory {
    NETRUNNER,
    MERCENARY,
    RONIN,
    ENCHANTER,
    VANGUARD,
    MINER,
    PATHFINDER,
    SCOUT
}

enum Background {
    STARRY_PINK,
    STARRY_YELLOW,
    STARRY_PURPLE,
    STARRY_GREEN,
    NEBULA,
    STARRY_RED,
    STARRY_BLUE,
    SUNSET,
    MORNING,
    INDIGO,
    CITY__PURPLE,
    CONTROL_ROOM,
    LAB,
    GREEN,
    ORANGE,
    PURPLE,
    CITY__GREEN,
    CITY__RED,
    STATION,
    BOUNTY,
    BLUE_SKY,
    RED_SKY,
    GREEN_SKY
}

enum Clothing {
    MARTIAL_SUIT,
    AMETHYST_ARMOR,
    SHIRT_AND_TIE,
    THUNDERDOME_ARMOR,
    FLEET_UNIFORM__BLUE,
    BANANITE_SHIRT,
    EXPLORER,
    COSMIC_GHILLIE_SUIT__BLUE,
    COSMIC_GHILLIE_SUIT__GOLD,
    CYBER_JUMPSUIT,
    ENCHANTER_ROBES,
    HOODIE,
    SPACESUIT,
    MECHA_ARMOR,
    LAB_COAT,
    FLEET_UNIFORM__RED,
    GOLD_ARMOR,
    ENERGY_ARMOR__BLUE,
    ENERGY_ARMOR__RED,
    MISSION_SUIT__BLACK,
    MISSION_SUIT__PURPLE,
    COWBOY,
    GLITCH_ARMOR,
    NONE
}

enum Eyes {
    SPACE_VISOR,
    ADORABLE,
    VETERAN,
    SUNGLASSES,
    WHITE_SUNGLASSES,
    RED_EYES,
    WINK,
    CASUAL,
    CLOSED,
    DOWNCAST,
    HAPPY,
    BLUE_EYES,
    HUD_GLASSES,
    DARK_SUNGLASSES,
    NIGHT_VISION_GOGGLES,
    BIONIC,
    HIVE_GOGGLES,
    MATRIX_GLASSES,
    GREEN_GLOW,
    ORANGE_GLOW,
    RED_GLOW,
    PURPLE_GLOW,
    BLUE_GLOW,
    SKY_GLOW,
    RED_LASER,
    BLUE_LASER,
    GOLDEN_SHADES,
    HIPSTER_GLASSES,
    PINCENEZ,
    BLUE_SHADES,
    BLIT_GLASSES,
    NOUNS_GLASSES
}

enum Fur {
    MAGENTA,
    BLUE,
    GREEN,
    RED,
    BLACK,
    BROWN,
    SILVER,
    PURPLE,
    PINK,
    SEANCE,
    TURQUOISE,
    CRIMSON,
    GREENYELLOW,
    GOLD,
    DIAMOND,
    METALLIC
}

enum Head {
    HALO,
    ENERGY_FIELD,
    BLUE_TOP_HAT,
    RED_TOP_HAT,
    ENERGY_CRYSTAL,
    CROWN,
    BANDANA,
    BUCKET_HAT,
    HOMBURG_HAT,
    PROPELLER_HAT,
    HEADBAND,
    DORAG,
    PURPLE_COWBOY_HAT,
    SPACESUIT_HELMET,
    PARTY_HAT,
    CAP,
    LEATHER_COWBOY_HAT,
    CYBER_HELMET__BLUE,
    CYBER_HELMET__RED,
    SAMURAI_HAT,
    NONE
}

enum Mouth {
    SMIRK,
    SURPRISED,
    SMILE,
    PIPE,
    OPEN_SMILE,
    NEUTRAL,
    MASK,
    TONGUE_OUT,
    GOLD_GRILL,
    DIAMOND_GRILL,
    NAVY_RESPIRATOR,
    RED_RESPIRATOR,
    MAGENTA_RESPIRATOR,
    GREEN_RESPIRATOR,
    MEMPO,
    VAPE,
    PILOT_OXYGEN_MASK,
    CIGAR,
    BANANA,
    CHROME_RESPIRATOR,
    STOIC
}

library Enums {
    function toString(Accessory v) external pure returns (string memory) {
        if (v == Accessory.GOLD_EARRINGS) {
            return "Gold Earrings";
        }

        if (v == Accessory.SCARS) {
            return "Scars";
        }

        if (v == Accessory.GOLDEN_CHAIN) {
            return "Golden Chain";
        }

        if (v == Accessory.AMULET) {
            return "Amulet";
        }

        if (v == Accessory.CUBAN_LINK_GOLD_CHAIN) {
            return "Cuban Link Gold Chain";
        }

        if (v == Accessory.FANNY_PACK) {
            return "Fanny Pack";
        }

        if (v == Accessory.NONE) {
            return "None";
        }
        revert("invalid accessory");
    }

    function toString(BackAccessory v) external pure returns (string memory) {
        if (v == BackAccessory.NETRUNNER) {
            return "Netrunner";
        }

        if (v == BackAccessory.MERCENARY) {
            return "Mercenary";
        }

        if (v == BackAccessory.RONIN) {
            return "Ronin";
        }

        if (v == BackAccessory.ENCHANTER) {
            return "Enchanter";
        }

        if (v == BackAccessory.VANGUARD) {
            return "Vanguard";
        }

        if (v == BackAccessory.MINER) {
            return "Miner";
        }

        if (v == BackAccessory.PATHFINDER) {
            return "Pathfinder";
        }

        if (v == BackAccessory.SCOUT) {
            return "Scout";
        }
        revert("invalid back accessory");
    }

    function toString(Background v) external pure returns (string memory) {
        if (v == Background.STARRY_PINK) {
            return "Starry Pink";
        }

        if (v == Background.STARRY_YELLOW) {
            return "Starry Yellow";
        }

        if (v == Background.STARRY_PURPLE) {
            return "Starry Purple";
        }

        if (v == Background.STARRY_GREEN) {
            return "Starry Green";
        }

        if (v == Background.NEBULA) {
            return "Nebula";
        }

        if (v == Background.STARRY_RED) {
            return "Starry Red";
        }

        if (v == Background.STARRY_BLUE) {
            return "Starry Blue";
        }

        if (v == Background.SUNSET) {
            return "Sunset";
        }

        if (v == Background.MORNING) {
            return "Morning";
        }

        if (v == Background.INDIGO) {
            return "Indigo";
        }

        if (v == Background.CITY__PURPLE) {
            return "City - Purple";
        }

        if (v == Background.CONTROL_ROOM) {
            return "Control Room";
        }

        if (v == Background.LAB) {
            return "Lab";
        }

        if (v == Background.GREEN) {
            return "Green";
        }

        if (v == Background.ORANGE) {
            return "Orange";
        }

        if (v == Background.PURPLE) {
            return "Purple";
        }

        if (v == Background.CITY__GREEN) {
            return "City - Green";
        }

        if (v == Background.CITY__RED) {
            return "City - Red";
        }

        if (v == Background.STATION) {
            return "Station";
        }

        if (v == Background.BOUNTY) {
            return "Bounty";
        }

        if (v == Background.BLUE_SKY) {
            return "Blue Sky";
        }

        if (v == Background.RED_SKY) {
            return "Red Sky";
        }

        if (v == Background.GREEN_SKY) {
            return "Green Sky";
        }
        revert("invalid background");
    }

    function toString(Clothing v) external pure returns (string memory) {
        if (v == Clothing.MARTIAL_SUIT) {
            return "Martial Suit";
        }

        if (v == Clothing.AMETHYST_ARMOR) {
            return "Amethyst Armor";
        }

        if (v == Clothing.SHIRT_AND_TIE) {
            return "Shirt and Tie";
        }

        if (v == Clothing.THUNDERDOME_ARMOR) {
            return "Thunderdome Armor";
        }

        if (v == Clothing.FLEET_UNIFORM__BLUE) {
            return "Fleet Uniform - Blue";
        }

        if (v == Clothing.BANANITE_SHIRT) {
            return "Bananite Shirt";
        }

        if (v == Clothing.EXPLORER) {
            return "Explorer";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__BLUE) {
            return "Cosmic Ghillie Suit - Blue";
        }

        if (v == Clothing.COSMIC_GHILLIE_SUIT__GOLD) {
            return "Cosmic Ghillie Suit - Gold";
        }

        if (v == Clothing.CYBER_JUMPSUIT) {
            return "Cyber Jumpsuit";
        }

        if (v == Clothing.ENCHANTER_ROBES) {
            return "Enchanter Robes";
        }

        if (v == Clothing.HOODIE) {
            return "Hoodie";
        }

        if (v == Clothing.SPACESUIT) {
            return "Spacesuit";
        }

        if (v == Clothing.MECHA_ARMOR) {
            return "Mecha Armor";
        }

        if (v == Clothing.LAB_COAT) {
            return "Lab Coat";
        }

        if (v == Clothing.FLEET_UNIFORM__RED) {
            return "Fleet Uniform - Red";
        }

        if (v == Clothing.GOLD_ARMOR) {
            return "Gold Armor";
        }

        if (v == Clothing.ENERGY_ARMOR__BLUE) {
            return "Energy Armor - Blue";
        }

        if (v == Clothing.ENERGY_ARMOR__RED) {
            return "Energy Armor - Red";
        }

        if (v == Clothing.MISSION_SUIT__BLACK) {
            return "Mission Suit - Black";
        }

        if (v == Clothing.MISSION_SUIT__PURPLE) {
            return "Mission Suit - Purple";
        }

        if (v == Clothing.COWBOY) {
            return "Cowboy";
        }

        if (v == Clothing.GLITCH_ARMOR) {
            return "Glitch Armor";
        }

        if (v == Clothing.NONE) {
            return "None";
        }
        revert("invalid clothing");
    }

    function toString(Eyes v) external pure returns (string memory) {
        if (v == Eyes.SPACE_VISOR) {
            return "Space Visor";
        }

        if (v == Eyes.ADORABLE) {
            return "Adorable";
        }

        if (v == Eyes.VETERAN) {
            return "Veteran";
        }

        if (v == Eyes.SUNGLASSES) {
            return "Sunglasses";
        }

        if (v == Eyes.WHITE_SUNGLASSES) {
            return "White Sunglasses";
        }

        if (v == Eyes.RED_EYES) {
            return "Red Eyes";
        }

        if (v == Eyes.WINK) {
            return "Wink";
        }

        if (v == Eyes.CASUAL) {
            return "Casual";
        }

        if (v == Eyes.CLOSED) {
            return "Closed";
        }

        if (v == Eyes.DOWNCAST) {
            return "Downcast";
        }

        if (v == Eyes.HAPPY) {
            return "Happy";
        }

        if (v == Eyes.BLUE_EYES) {
            return "Blue Eyes";
        }

        if (v == Eyes.HUD_GLASSES) {
            return "HUD Glasses";
        }

        if (v == Eyes.DARK_SUNGLASSES) {
            return "Dark Sunglasses";
        }

        if (v == Eyes.NIGHT_VISION_GOGGLES) {
            return "Night Vision Goggles";
        }

        if (v == Eyes.BIONIC) {
            return "Bionic";
        }

        if (v == Eyes.HIVE_GOGGLES) {
            return "Hive Goggles";
        }

        if (v == Eyes.MATRIX_GLASSES) {
            return "Matrix Glasses";
        }

        if (v == Eyes.GREEN_GLOW) {
            return "Green Glow";
        }

        if (v == Eyes.ORANGE_GLOW) {
            return "Orange Glow";
        }

        if (v == Eyes.RED_GLOW) {
            return "Red Glow";
        }

        if (v == Eyes.PURPLE_GLOW) {
            return "Purple Glow";
        }

        if (v == Eyes.BLUE_GLOW) {
            return "Blue Glow";
        }

        if (v == Eyes.SKY_GLOW) {
            return "Sky Glow";
        }

        if (v == Eyes.RED_LASER) {
            return "Red Laser";
        }

        if (v == Eyes.BLUE_LASER) {
            return "Blue Laser";
        }

        if (v == Eyes.GOLDEN_SHADES) {
            return "Golden Shades";
        }

        if (v == Eyes.HIPSTER_GLASSES) {
            return "Hipster Glasses";
        }

        if (v == Eyes.PINCENEZ) {
            return "Pince-nez";
        }

        if (v == Eyes.BLUE_SHADES) {
            return "Blue Shades";
        }

        if (v == Eyes.BLIT_GLASSES) {
            return "Blit GLasses";
        }

        if (v == Eyes.NOUNS_GLASSES) {
            return "Nouns Glasses";
        }
        revert("invalid eyes");
    }

    function toString(Fur v) external pure returns (string memory) {
        if (v == Fur.MAGENTA) {
            return "Magenta";
        }

        if (v == Fur.BLUE) {
            return "Blue";
        }

        if (v == Fur.GREEN) {
            return "Green";
        }

        if (v == Fur.RED) {
            return "Red";
        }

        if (v == Fur.BLACK) {
            return "Black";
        }

        if (v == Fur.BROWN) {
            return "Brown";
        }

        if (v == Fur.SILVER) {
            return "Silver";
        }

        if (v == Fur.PURPLE) {
            return "Purple";
        }

        if (v == Fur.PINK) {
            return "Pink";
        }

        if (v == Fur.SEANCE) {
            return "Seance";
        }

        if (v == Fur.TURQUOISE) {
            return "Turquoise";
        }

        if (v == Fur.CRIMSON) {
            return "Crimson";
        }

        if (v == Fur.GREENYELLOW) {
            return "Green-Yellow";
        }

        if (v == Fur.GOLD) {
            return "Gold";
        }

        if (v == Fur.DIAMOND) {
            return "Diamond";
        }

        if (v == Fur.METALLIC) {
            return "Metallic";
        }
        revert("invalid fur");
    }

    function toString(Head v) external pure returns (string memory) {
        if (v == Head.HALO) {
            return "Halo";
        }

        if (v == Head.ENERGY_FIELD) {
            return "Energy Field";
        }

        if (v == Head.BLUE_TOP_HAT) {
            return "Blue Top Hat";
        }

        if (v == Head.RED_TOP_HAT) {
            return "Red Top Hat";
        }

        if (v == Head.ENERGY_CRYSTAL) {
            return "Energy Crystal";
        }

        if (v == Head.CROWN) {
            return "Crown";
        }

        if (v == Head.BANDANA) {
            return "Bandana";
        }

        if (v == Head.BUCKET_HAT) {
            return "Bucket Hat";
        }

        if (v == Head.HOMBURG_HAT) {
            return "Homburg Hat";
        }

        if (v == Head.PROPELLER_HAT) {
            return "Propeller Hat";
        }

        if (v == Head.HEADBAND) {
            return "Headband";
        }

        if (v == Head.DORAG) {
            return "Do-rag";
        }

        if (v == Head.PURPLE_COWBOY_HAT) {
            return "Purple Cowboy Hat";
        }

        if (v == Head.SPACESUIT_HELMET) {
            return "Spacesuit Helmet";
        }

        if (v == Head.PARTY_HAT) {
            return "Party Hat";
        }

        if (v == Head.CAP) {
            return "Cap";
        }

        if (v == Head.LEATHER_COWBOY_HAT) {
            return "Leather Cowboy Hat";
        }

        if (v == Head.CYBER_HELMET__BLUE) {
            return "Cyber Helmet - Blue";
        }

        if (v == Head.CYBER_HELMET__RED) {
            return "Cyber Helmet - Red";
        }

        if (v == Head.SAMURAI_HAT) {
            return "Samurai Hat";
        }

        if (v == Head.NONE) {
            return "None";
        }
        revert("invalid head");
    }

    function toString(Mouth v) external pure returns (string memory) {
        if (v == Mouth.SMIRK) {
            return "Smirk";
        }

        if (v == Mouth.SURPRISED) {
            return "Surprised";
        }

        if (v == Mouth.SMILE) {
            return "Smile";
        }

        if (v == Mouth.PIPE) {
            return "Pipe";
        }

        if (v == Mouth.OPEN_SMILE) {
            return "Open Smile";
        }

        if (v == Mouth.NEUTRAL) {
            return "Neutral";
        }

        if (v == Mouth.MASK) {
            return "Mask";
        }

        if (v == Mouth.TONGUE_OUT) {
            return "Tongue Out";
        }

        if (v == Mouth.GOLD_GRILL) {
            return "Gold Grill";
        }

        if (v == Mouth.DIAMOND_GRILL) {
            return "Diamond Grill";
        }

        if (v == Mouth.NAVY_RESPIRATOR) {
            return "Navy Respirator";
        }

        if (v == Mouth.RED_RESPIRATOR) {
            return "Red Respirator";
        }

        if (v == Mouth.MAGENTA_RESPIRATOR) {
            return "Magenta Respirator";
        }

        if (v == Mouth.GREEN_RESPIRATOR) {
            return "Green Respirator";
        }

        if (v == Mouth.MEMPO) {
            return "Mempo";
        }

        if (v == Mouth.VAPE) {
            return "Vape";
        }

        if (v == Mouth.PILOT_OXYGEN_MASK) {
            return "Pilot Oxygen Mask";
        }

        if (v == Mouth.CIGAR) {
            return "Cigar";
        }

        if (v == Mouth.BANANA) {
            return "Banana";
        }

        if (v == Mouth.CHROME_RESPIRATOR) {
            return "Chrome Respirator";
        }

        if (v == Mouth.STOIC) {
            return "Stoic";
        }
        revert("invalid mouth");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtensibleERC721Enumerable.sol";
import "./ChainScoutsExtension.sol";
import "./ChainScoutMetadata.sol";

interface IChainScouts is IExtensibleERC721Enumerable {
    function adminCreateChainScout(
        ChainScoutMetadata calldata tbd,
        address owner
    ) external;

    function adminRemoveExtension(string calldata key) external;

    function adminSetExtension(
        string calldata key,
        ChainScoutsExtension extension
    ) external;

    function adminSetChainScoutMetadata(
        uint256 tokenId,
        ChainScoutMetadata calldata tbd
    ) external;

    function getChainScoutMetadata(uint256 tokenId)
        external
        view
        returns (ChainScoutMetadata memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IExtensibleERC721Enumerable is IERC721Enumerable {
    function isAdmin(address addr) external view returns (bool);

    function addAdmin(address addr) external;

    function removeAdmin(address addr) external;

    function canAccessToken(address addr, uint tokenId) external view returns (bool);

    function adminBurn(uint tokenId) external;

    function adminTransfer(address from, address to, uint tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRenderer {
    function render(bytes[] memory sprites) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUtilityERC20 is IERC20 {
    function adminMint(address owner, uint amountWei) external;

    function adminSetTokenTimestamp(uint tokenId, uint timestamp) external;

    function burn(address owner, uint amountWei) external;

    function claimRewards() external;

    function stake(uint[] calldata tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Integer {
    /**
     * @dev Gets the bit at the given position in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *
     *      For example: bitAt(2, 0) == 0, because the rightmost bit of 10 is 0
     *                   bitAt(2, 1) == 1, because the second to last bit of 10 is 1
     */
    function bitAt(uint integer, uint pos) internal pure returns (uint) {
        require(pos <= 255, "pos > 255");

        return (integer & (1 << pos)) >> pos;
    }

    function setBitAt(uint integer, uint pos) internal pure returns (uint) {
        return integer | (1 << pos);
    }

    /**
     * @dev Gets the value of the bits between left and right, both inclusive, in the given integer.
     *      255 is the leftmost bit, 0 is the rightmost bit.
     *      
     *      For example: bitsFrom(10, 3, 1) == 7 (101 in binary), because 10 is *101*0 in binary
     *                   bitsFrom(10, 2, 0) == 2 (010 in binary), because 10 is 1*010* in binary
     */
    function bitsFrom(uint integer, uint left, uint right) internal pure returns (uint) {
        require(left >= right, "left > right");
        require(left <= 255, "left > 255");

        uint delta = left - right + 1;

        return (integer & (((1 << delta) - 1) << right)) >> right;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";
import "./Integer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

enum NumericAttributeType {
    NUMBER,
    BOOST_PERCENTAGE,
    BOOST_NUMBER,
    DATE
}

struct Attribute {
    string displayType;
    string key;
    string serializedValue;
    string maxValue;
}

struct OpenSeaMetadata {
    string svg;
    string description;
    string name;
    uint24 backgroundColor;
    Attribute[] attributes;
}

library OpenSeaMetadataLibrary {
    using Strings for uint;

    struct ObjectKeyValuePair {
        string key;
        string serializedValue;
    }

    function uintToColorString(uint value, uint nBytes) internal pure returns (string memory) {
        bytes memory symbols = "0123456789ABCDEF";
        bytes memory buf = new bytes(nBytes * 2);

        for (uint i = 0; i < nBytes * 2; ++i) {
            buf[nBytes * 2 - 1 - i] = symbols[Integer.bitsFrom(value, (i * 4) + 3, i * 4)];
        }

        return string(buf);
    }

    function quote(string memory str) internal pure returns (string memory output) {
        return bytes(str).length > 0 ? string(abi.encodePacked(
            '"',
            str,
            '"'
        )) : "";
    }

    function makeStringAttribute(string memory key, string memory value) internal pure returns (Attribute memory) {
        return Attribute("", key, quote(value), "");
    }

    function makeNumericAttribute(NumericAttributeType nat, string memory key, string memory value, string memory maxValue) private pure returns (Attribute memory) {
        string memory s = "number";
        if (nat == NumericAttributeType.BOOST_PERCENTAGE) {
            s = "boost_percentage";
        }
        else if (nat == NumericAttributeType.BOOST_NUMBER) {
            s = "boost_number";
        }
        else if (nat == NumericAttributeType.DATE) {
            s = "date";
        }

        return Attribute(s, key, value, maxValue);
    }

    function makeFixedPoint(uint value, uint decimals) internal pure returns (string memory) {
        bytes memory st = bytes(value.toString());

        while (st.length < decimals) {
            st = abi.encodePacked(
                "0",
                st
            );
        }

        bytes memory ret = new bytes(st.length + 1);

        if (decimals >= st.length) {
            return string(abi.encodePacked("0.", st));
        }

        uint dl = st.length - decimals;

        uint i = 0;
        uint j = 0;

        while (i < ret.length) {
            if (i == dl) {
                ret[i] = '.';
                i++;
                continue;
            }

            ret[i] = st[j];

            i++;
            j++;
        }

        return string(ret);
    }

    function makeFixedPointAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue, uint decimals) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, makeFixedPoint(value, decimals), maxValue == 0 ? "" : makeFixedPoint(maxValue, decimals));
    }

    function makeUintAttribute(NumericAttributeType nat, string memory key, uint value, uint maxValue) internal pure returns (Attribute memory) {
        return makeNumericAttribute(nat, key, value.toString(), maxValue == 0 ? "" : maxValue.toString());
    }

    function makeBooleanAttribute(string memory key, bool value) internal pure returns (Attribute memory) {
        return Attribute("", key, value ? "true" : "false", "");
    }

    function makeAttributesArray(Attribute[] memory attributes) internal pure returns (string memory output) {
        output = "[";
        bool empty = true;

        for (uint i = 0; i < attributes.length; ++i) {
            if (bytes(attributes[i].serializedValue).length > 0) {
                ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](4);
                kvps[0] = ObjectKeyValuePair("trait_type", quote(attributes[i].key));
                kvps[1] = ObjectKeyValuePair("display_type", quote(attributes[i].displayType));
                kvps[2] = ObjectKeyValuePair("value", attributes[i].serializedValue);
                kvps[3] = ObjectKeyValuePair("max_value", attributes[i].maxValue);

                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    makeObject(kvps)
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "]"));
    }

    function notEmpty(string memory s) internal pure returns (bool) {
        return bytes(s).length > 0;
    }

    function makeObject(ObjectKeyValuePair[] memory kvps) internal pure returns (string memory output) {
        output = "{";
        bool empty = true;

        for (uint i = 0; i < kvps.length; ++i) {
            if (bytes(kvps[i].serializedValue).length > 0) {
                output = string(abi.encodePacked(
                    output,
                    empty ? "" : ",",
                    '"',
                    kvps[i].key,
                    '":',
                    kvps[i].serializedValue
                ));
                empty = false;
            }
        }

        output = string(abi.encodePacked(output, "}"));
    }

    function makeMetadataWithExtraKvps(OpenSeaMetadata memory metadata, ObjectKeyValuePair[] memory extra) internal pure returns (string memory output) {
        /*
        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            string(Base64.encode(bytes(metadata.svg)))
        ));
        */

        string memory svgUrl = string(abi.encodePacked(
            "data:image/svg+xml;utf8,",
            metadata.svg
        ));

        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](5 + extra.length);
        kvps[0] = ObjectKeyValuePair("name", quote(metadata.name));
        kvps[1] = ObjectKeyValuePair("description", quote(metadata.description));
        kvps[2] = ObjectKeyValuePair("image", quote(svgUrl));
        kvps[3] = ObjectKeyValuePair("background_color", quote(uintToColorString(metadata.backgroundColor, 3)));
        kvps[4] = ObjectKeyValuePair("attributes", makeAttributesArray(metadata.attributes));
        for (uint i = 0; i < extra.length; ++i) {
            kvps[i + 5] = extra[i];
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(makeObject(kvps)))
        ));
    }

    function makeMetadata(OpenSeaMetadata memory metadata) internal pure returns (string memory output) {
        return makeMetadataWithExtraKvps(metadata, new ObjectKeyValuePair[](0));
    }

    function makeERC1155Metadata(OpenSeaMetadata memory metadata, string memory symbol) internal pure returns (string memory output) {
        ObjectKeyValuePair[] memory kvps = new ObjectKeyValuePair[](1);
        kvps[0] = ObjectKeyValuePair("symbol", quote(symbol));
        return makeMetadataWithExtraKvps(metadata, kvps);
    }
}

pragma solidity ^0.8.0;

/// @dev Proxy for NFT Factory
contract ProxyTarget {

    // Storage for this proxy
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
    bytes32 internal constant ADMIN_SLOT          = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./BasePass.sol";
import "./IRenderer.sol";
import "./OpenSeaMetadata.sol";
// import "./Sprites.sol";
import "./ProxyTarget.sol";

contract ScoutPass is BasePass, ProxyTarget {
    bool public initialized;
    IRenderer public renderer;
    string private _symbol;

    function initialize(address _oldPass, uint256 _oldSupply, address _token, IRenderer _renderer) external
    {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
		require(!initialized);
		initialized = true;
        // BasePass(
        //     _token,
        //     200 ether,
        //     "Scout Pass"
        // )
        init(_oldPass, _oldSupply, _token, 200 ether, "Scout Pass");
        _symbol = "SCOUTPASS";
        renderer = _renderer;
    }

    function extensionKey() public override pure returns (string memory) {
        return "metaversePass";
    }
    
    function adminSetRenderer(IRenderer _renderer) external onlyAdmin {
        renderer = _renderer;
    }

    function adminSetSymbol(string memory sym) external onlyAdmin {
        _symbol = sym;
    }

    function metadata() public virtual view override returns (OpenSeaMetadata memory) {
        bytes[] memory passSprite = new bytes[](1);
        passSprite[0] = getPassSprite();
        string memory sprite = renderer.render(passSprite);

        return OpenSeaMetadata({
            svg: sprite,
            name: "Scout Pass",
            description: "The Scout Pass is the key to unlock perks in the Chain Scouts ecosystem",
            backgroundColor: 0,
            attributes: new Attribute[](0)
        });
    }

    function symbol() public virtual view override returns (string memory) {
        return _symbol;
    }

    function getPassSprite() internal pure returns (bytes memory) {
        return
            hex"41F022E501C28B9A020905370826B808241CFC28B98040D8426122E67102428101114DC4221E04044E4409075F122E501868B99C609AA066AAA46044A866AAAC6ADE58D1BF6EE19B057C46FDBC866BECC6FDBD06FC8D46ADED866BEDC6044E066AAE4609A75E1A2E7F1836101888B99C809AA09126A48044A880EB576203CF720113823F6F920269D7C88B94062A2E672826A829AAA9283CEA2AC195D8AADEDCA0F3E0A6AAE4A09A75F2A2E500CC8B990C0D84A6322E673026A8308869303CD538CADE5F0300118D8CADEDCC0F3E0C221E4C09A75F322E5018E8B99CE09AA0F126A4E0F3A8EAC156D3AB7AE38012F3B86B0380118D8EADEDCE0F3E0F126E4E09AE8E8B9ECE1A179F3A2E501908B99D009AA10221A500F354C42B7AD40012E45E1AF400118590ADEDD00F3E10221E5009A75F422E501928B99D209AA126CDA520F354B4AB7AC48012D4DE1AE4C182F480118592ADEDD20F3E126AAE5209A75F4A2E500D48B99148BA4A6522E675026A850A129503CEA52B7AB50012C55E1AD560FEE54182F55E1B0500118CD4ADE69550013652B7B7503CF85088B95026BA522EFB52327C522E9EFD48B98168B98562AD8968C94665A2E675826A85834E958112A5AB7AB58012C5DE1AD5E0FEE5C182F5DE1B05C1818CD6004D1783FD56004D96ADEDD6044E160E4E5609A75C5A2E7D5A2EFE5A2EBF58AB60622BA1622ED11988B99D809AA180D3A58044A98ADEAD8004B19786B5983FB99060BD9786C197CE63464183560013662B7B76011386034F960269D7D88B981A8BF4266A2E676826A869AFA968112A6AB7AB68012C6DE1AD6DF3AE6E0FEF6C18306DE1B16DF3B26DE199D1B83FD5A02BD9AADEDDA044E1A6BEE5A09AE9A8D4EDA8B9F1A8C87BF6A2E5011C8B995C8D499C8E79DC09AA1CFDBA5C04454B72B7AC70012D75E1AE75F3AF760FD851D060D5C004D9CADEDDC044E1CFDBE5C044E9C8E777C72321EFDC8B94037A2E647A35257A3CA67A40E77811287BF6E978111531EADEB5E0045D07DE198CDF83FD1E0046B67AB7B77811387BF6F978113A7A645DF1E8F2F5E8E77DF7A32100608B98A08D48E08E79209039602C99A099E9E009AA20FDBA6004454D82B7974E000469682B7B780113883F6F98026BA826E3B82647C82427D80AD3E82353F8232208A35218A39E28A43A38A42648A69658A77268A7E678826A889AFA98811155A2ADEDE2044E226BEE6209AEA2A0EEE29D4F229B8F62909FA28F2FE28E78248F18648F28A49868E499E9249D4964A0E9A4A289E409AA246BEA6404455696213790113891AFB99026BA92A9FB92943C9287FD92797E926E3F9264609A40E19A64629A6B639A79649A87E59A9E669AB8A79826A899AFA99811155A6ADEDE6044E266BEE6609AEA6B15EE6AE2F26A6EF66A28FA6A05FE69AD82899E8689C38A89E58E8A39928AA7968B169A8B789E809AA29126A68044AA8ADE56CA0886DA2B797468221CA8ADE675A08876A2B7B7A01138A449B9A026BAA2EF7BA2DA7CA2BB7DA2A2FEA2977FA27E60A8BA61AA83A2AA9423AAAF64AAC565AAF4A6AB16E7A826A8AC49A9A8112AAAB7ABA8886CAAB796BAA221BEAADEC2A221C6AADE653A88874AAB7B5A88876AAB7B7A81138AC49B9A826BAAB2CBBAB0B3CAADCBDAAC2FEAAACBFA8C5E0B28361B29B62B2B123B2D7E4B2F365B31E66B34F67B026A8B449A9B011155ACADEDEC044E2D126E6C09AEACDF9EECCDFF2CC47F6CBD2FACB50FECABD82EA5086EAED8AEB698EEC1492EC9A96ED719AEE859EE09AA2E221A6E0F3AAEADE56EB8886FBAB79846E221CAEADECEE221D2EADED6E221DAEADEDEE044E2E221E6E09AEAEF09EEEE60F2ED36F6EC88FAEBE9FEEB43830AC4870B508B0C1D8F0CB2930D8A970E589B0F8D9F009AA306BEA700F354BC2B7ACC0886DC2B7973F0221C30ADE632C08873C2B79A570221DB0ADEDF0044E306BEE7009AEB104BEF0F61F30E79F70D67FB0C79FF0BE9832B16872BFA8B2C888F2D80932EA4972FB79B31089F209AA326BEA720F3556CAB7B7C83CF8C9AFB9C826BACC743BCC18FCCBE0BDCB9ABECB4F7FCB18A0D2E4E1D31AE2D34F63D3A164D3E0A5D447E6D48A27D026A8D449A9D03CD55B5884DF40F3E34FDBE7409AEB52DAEF51E8F35063F74F6BFB4E53FF4CDF836C14876CDF8B6E2A8F6F6B9370FD9772099B732C9F609AA37126A76044AB60EB576D83CF7D81138DBF6F9D826BADCFC7BDCAFFCDC743DDC12FEDBCEFFDB7E60E31E61E36662E3BD63E40864E473E5E4BBA6E4FC67E026A8E1AAA9E0112AE1AAABE2B796378FDBBB86C15F1E3F6F2E1AFB3E3F6F4E3F235E2B7B6E1AFB7E01138E1AAB9E026BAE51CBBE4EB3CE4A97DE466FEE3F0FFE3B760EB3A61EB7962EBE6E3EC56521BA0049FA090A3A044537E88878E81139E8241D73A004F7B25CFBB11FFFAF8283CD9987CEF58BD0308FC004487F60FE8F61014AFD846B3D8425B6F6119BE3D84273CF60FFDF0013EF4743FF3FDA0FB86E1FBD862FC4BA3FC9E64F801129FF786509FC181533F786B7F0605D2FDE1B3FC181A5BF7866F8FC181CEFF786F3E004F7F39BFBF25CFFF0F0";
    }

}