// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

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
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
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
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
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
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
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
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
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
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
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
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
        if (to.isContract()) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Royalties.sol";

interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
    function transfer(address to, uint value) external;

}

contract ERC1155MarketPlace is ERC1155Holder, Royalties {

    address public MarketPlaceOwner;
    uint public marketPlaceCommision = 0;



    constructor() {
        MarketPlaceOwner = msg.sender;
    }

    struct FixedPrice {
        bool isSold;
        bool forsale;
        address paymentToken;
        address owner; //Seller
        address newowner; //Buyer
        address nftAddress;
        uint256 price;
        uint256 paid;
        uint256 fixedid;
        uint256 tokenid;
        uint256 totalcopies;
    }

    FixedPrice[] public Fixedprices;

    struct Auction {
        bool isSold;
        bool OpenForBidding;
        uint256 initialPrice;
        uint256 auctionid;
        uint256 tokenId;
        uint256 numberofcopies;
        uint256 auctionEndTime;
        uint256 auctionStartTime;
        uint256 currentBidAmount;
        address currentBidOwner;
        address nftAddress;
        address nftOwner;
        address paymentToken;
    }

    Auction[] public auctions;

    // mapping(address => bool) public approvedPaymentTokenList;

    event BidIcrease(address bidder, uint amount, uint id);
    event OfferSale(uint256 _fixeditemid);
    event AuctionStart(uint256 _auctionid);
    event AuctionEnded(uint id);

    modifier IsForSale(uint256 id) {
        require(Fixedprices[id].isSold == false, "Item is already Sold");
        _;
    }

    modifier OnlyTokenHolders(uint256 _tokenid, address _nftAddress) {
        require(
            IERC1155(_nftAddress).balanceOf(msg.sender, _tokenid) > 0,
            "You are not the owner of Token"
        );
        _;
    }

    modifier ItemExists(uint256 id) {
        require(
            id < Fixedprices.length && Fixedprices[id].fixedid == id,
            "Could not find item"
        );
        _;
    }

    modifier OnlyMPOwner() {
        require(MarketPlaceOwner == msg.sender, "Only owner function");
        _;
    }

    // MULTIPLY THE PERCENTAGE BY 100
    function setMPCommision(uint _newPercentage) external OnlyMPOwner {
        marketPlaceCommision = _newPercentage;
    }

    // function addApprovedPaymentTokenList(
    //     address _tokenAddress
    // ) external OnlyMPOwner {
    //     approvedPaymentTokenList[_tokenAddress] = true;
    // }

    // function removeApprovedPaymentTokenList(
    //     address _tokenAddress
    // ) external OnlyMPOwner {
    //     approvedPaymentTokenList[_tokenAddress] = false;
    // }

    // ListingNFTforFixedPointSellingFunction

    function listItemForFixedPrice(
        address _paymentToken,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _nftAddress
    ) public OnlyTokenHolders(_tokenId, _nftAddress) returns (uint256) {
        require(_tokenId >= 0, "TokenId can not be negative integer");
        require(_amount > 0, "amount of nfts can not be zero");
        require(_price > 0, "Cannot list for 0");
        require(_nftAddress != address(0), "NFT address cannot be 0");

        uint256 newItemId = Fixedprices.length;
        Fixedprices.push(
            FixedPrice(
                false,
                true,
                _paymentToken,
                msg.sender,
                address(0),
                _nftAddress,
                _price,
                0,
                newItemId,
                _tokenId,
                _amount
            )
        );
        IERC1155(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            "0x00"
        );

        emit OfferSale(newItemId);
        return newItemId;
    }

    // BuyingFixedPriceSellingItemFunction

    // Call Approve with the cost amount before calling this function if it is listed in usdt

    function BuyFixedPriceItem(
        uint256 Id
    ) public payable ItemExists(Id) IsForSale(Id) returns (bool) {
        FixedPrice storage fixedPrices = Fixedprices[Id];
        require(
            msg.sender != fixedPrices.owner,
            "owner of this nft can not buy"
        );
        require(fixedPrices.forsale, "This NFT is not for sale");

        if (fixedPrices.paymentToken == address(0)) {
            require(msg.value >= fixedPrices.price, "Invalid Price");
            fixedPrices.paid = msg.value;
            fixedPrices.newowner = msg.sender;
            IERC1155(fixedPrices.nftAddress).safeTransferFrom(
                address(this),
                fixedPrices.newowner,
                fixedPrices.tokenid,
                fixedPrices.totalcopies,
                "0x00"
            );

            bool sucess = _ethPayment(fixedPrices);
            return sucess;
        } else {
            // require(
                IERC20_USDT(fixedPrices.paymentToken).transferFrom(
                    tx.origin,
                    address(this),
                    fixedPrices.price
                );
            //     "ERC20 Payment not transfered"
            // );
            // Fixedprices[Id].paid = msg.value;
            fixedPrices.newowner = msg.sender;
            IERC1155(fixedPrices.nftAddress).safeTransferFrom(
                address(this),
                fixedPrices.newowner,
                fixedPrices.tokenid,
                fixedPrices.totalcopies,
                "0x00"
            );

            //ERC20 Payment
            bool sucess = _ERC20Payment(fixedPrices);
            return sucess;
        }
    }

    // ListingItemForAuctionFunction

    function listItemForAuction(
        uint256 _initialPrice,
        uint256 _biddingStartTime,
        uint256 _biddingendtime,
        uint256 tokenId,
        uint256 _numberofcopies,
        address _nftAddress,
        address _paymentToken
    ) public OnlyTokenHolders(tokenId, _nftAddress) returns (uint256) {
        require(_initialPrice > 0, "Initial price can't be zero");
        require(tokenId >= 0, "TokenId can not be negative integer");
        require(_numberofcopies > 0, "amount of nfts can not be zero");
        require(
            _nftAddress != address(0),
            "NFT address cannot be 0x0000000000000000000000"
        );
        require(_biddingStartTime >= block.timestamp, "Invalid Start Time");
        require(
            _biddingendtime > block.timestamp &&
                _biddingendtime > _biddingStartTime,
            "Invalid End Time"
        );

        uint256 newauctionid = auctions.length;
        auctions.push(
            Auction(
                false,
                true,
                _initialPrice,
                newauctionid,
                tokenId,
                _numberofcopies,
                _biddingendtime,
                _biddingStartTime,
                0,
                address(0),
                _nftAddress,
                msg.sender,
                _paymentToken
            )
        );
        IERC1155(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            _numberofcopies,
            "0x00"
        );
        emit AuctionStart(newauctionid);
        return newauctionid;
    }

    // Call Approve Before this for USDT only

    // Implement Mutex

    //Implement royalty
    function bid(uint256 Id, uint _paymentTokenAmount) public payable {
        Auction storage auction = auctions[Id];
        require(msg.sender != auction.nftOwner, "Owner can't bid");
        require(auction.OpenForBidding == true, "Not open for bidding");
        require(
            auction.auctionStartTime >= block.timestamp,
            "Bidding hasn't started"
        );
        require(auction.auctionEndTime > block.timestamp, "Bidding time ended");

        if (auction.paymentToken == address(0)) {
            require(
                msg.value > auction.initialPrice,
                "Bid price must be higher than initial price"
            );

            require(
                msg.value > auction.currentBidAmount,
                "Already higher bid exist"
            );

            if (msg.value > auction.currentBidAmount) {
                payable(auction.currentBidOwner).transfer(
                    auction.currentBidAmount
                );
            }
            auction.currentBidOwner = msg.sender;
            auction.currentBidAmount = msg.value;

        } else {
            require(
                _paymentTokenAmount > auction.initialPrice,
                "Bid price must be higher than initial price"
            );
                   require(
                _paymentTokenAmount > auction.currentBidAmount,
                "There is already higher bid exist"
            );
                IERC20_USDT(auction.paymentToken).transferFrom(
                    msg.sender,
                    address(this),
                    _paymentTokenAmount
                );

            if (_paymentTokenAmount > auction.currentBidAmount) {
                IERC20_USDT(auction.paymentToken).transfer(
                    auction.currentBidOwner,
                    auction.currentBidAmount
                );
            }
            auction.currentBidOwner = msg.sender;
            auction.currentBidAmount = _paymentTokenAmount;

        }
    }

    // callable for auction creator
    function auctionEndAndClaimReward(uint256 Id) public returns (bool) {
        Auction storage auction = auctions[Id];

        require(msg.sender == auction.nftOwner, "Only owner of NFT can end");

        require(auction.OpenForBidding, "Already Ended");

        require(
            auction.auctionEndTime < block.timestamp,
            "Time is not over yet"
        );

        //IMPLEMENT NO BIDDER WITHDRAWL

        if (auction.currentBidOwner != address(0)) {
            if (auction.paymentToken == address(0)) {

                bool sucess = _ethPaymentForAuction(auction);
                emit AuctionEnded(auction.auctionid);

                return sucess;
            } else {

                bool sucess = _ERC20PaymentForAuction(auction);

                emit AuctionEnded(auction.auctionid);
                return sucess;
            }

            // Will return NFT to OWner if noBody Bidded
        } else {
            IERC1155(auction.nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                auction.tokenId,
                auction.numberofcopies,
                "0x00"
            );
            // auction.isSold = true;
            auction.OpenForBidding = false;
        }
    }

    function claimNft(uint256 Id) public returns (bool) {
        Auction storage auction = auctions[Id];

        require(
            msg.sender == auction.currentBidOwner,
            "You are not the highest bidder"
        );
        require(
            block.timestamp > auction.auctionEndTime,
            "Auction still in Progress"
        );
        require(auction.isSold == false, "Already Claimed");

        IERC1155(auction.nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            auction.tokenId,
            auction.numberofcopies,
            "0x00"
        );
        auction.isSold = true;

        emit AuctionEnded(auction.auctionid);

        return true;
    }

    function calculatCommision(uint _sellingPrice) public view returns (uint) {
        return (_sellingPrice * marketPlaceCommision) / 10000;
    }

    function _ethPayment(
        FixedPrice memory fixedPrices
    ) internal returns (bool) {
        uint royaltyAmount = calculateRoyalties(
            fixedPrices.nftAddress,
            fixedPrices.price
        );

        uint mpCommision = calculatCommision(fixedPrices.price);
        uint256 amountToSendSeller = fixedPrices.price -
            royaltyAmount -
            mpCommision;

        payable(fixedPrices.owner).transfer(amountToSendSeller);

        if (royaltyAmount != 0) {
            address royaltyAddress = getRoyaltyReciever(fixedPrices.nftAddress);
            payable(royaltyAddress).transfer(royaltyAmount);
        }

        fixedPrices.isSold = true;
        fixedPrices.forsale = false;
        return true;
    }

    function _ERC20Payment(
        FixedPrice memory fixedPrices
    ) internal returns (bool) {
        uint royaltyAmount = calculateRoyalties(
            fixedPrices.nftAddress,
            fixedPrices.price
        );
        uint mpCommision = calculatCommision(fixedPrices.price);

        uint256 amountToSendSeller = fixedPrices.price -
            royaltyAmount -
            mpCommision;

        IERC20_USDT(fixedPrices.paymentToken).transfer(
            fixedPrices.owner,
            amountToSendSeller
        );

        if (royaltyAmount != 0) {
            address royaltyAddress = getRoyaltyReciever(fixedPrices.nftAddress);
            IERC20_USDT(fixedPrices.paymentToken).transfer(
                royaltyAddress,
                royaltyAmount
            );
        }

        fixedPrices.isSold = true;
        fixedPrices.forsale = false;
        return true;
    }

    function _ethPaymentForAuction(
        Auction memory _auction
    ) internal returns (bool) {
        uint royaltyAmount = calculateRoyalties(
            _auction.nftAddress,
            _auction.currentBidAmount
        );

        uint mpCommision = calculatCommision(_auction.currentBidAmount);
        uint256 amountToSendSeller = _auction.currentBidAmount -
            royaltyAmount -
            mpCommision;

        payable(_auction.nftOwner).transfer(amountToSendSeller);

        if (royaltyAmount != 0) {
            address royaltyAddress = getRoyaltyReciever(_auction.nftAddress);
            payable(royaltyAddress).transfer(royaltyAmount);
        }
        _auction.OpenForBidding = false;
        return true;
    }

    function _ERC20PaymentForAuction(
        Auction memory _auction
    ) internal returns (bool) {
        uint royaltyAmount = calculateRoyalties(
            _auction.nftAddress,
            _auction.currentBidAmount
        );

        uint mpCommision = calculatCommision(_auction.currentBidAmount);
        uint256 amountToSendSeller = _auction.currentBidAmount -
            royaltyAmount -
            mpCommision;

        IERC20_USDT(_auction.paymentToken).transfer(
            _auction.nftOwner,
            amountToSendSeller
        );

        if (royaltyAmount != 0) {
            address royaltyAddress = getRoyaltyReciever(_auction.nftAddress);
            IERC20_USDT(_auction.paymentToken).transfer(
                royaltyAddress,
                royaltyAmount
            );
        }
        _auction.OpenForBidding = false;
        return true;
    }

    function getAllFixedPriceSales() public view returns (FixedPrice[] memory) {
        return Fixedprices;
    }

    function getAllAuctions() public view returns (Auction[] memory) {
        return auctions;
    }

    function getSpecificFixedPriceSale(
        uint _id
    ) public view returns (FixedPrice memory) {
        return Fixedprices[_id];
    }

    function getSpecificAuction(uint _id) public view returns (Auction memory) {
        return auctions[_id];
    }

    function withdrawEthFromMp() external payable OnlyMPOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withDrawERC20FromMp(address _token, address _withdrawalAddress) external OnlyMPOwner{
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20_USDT(_token).transfer(_withdrawalAddress, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Tempelate is ERC1155, Ownable {
    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155Tempelate.sol";

contract Royalties {
    // Struct for saving address and percentage
    struct RoyaltiesData {
        address royaltyReciever;
        uint256 percentageOfRoyalty;
    }

    // event RoyalityCreated(
    //     address NFTCollection,
    //     address to,
    //     uint256 percentage
    // );
    // event RoyaltyPaid(address to, uint256 amount);
    // event RoyaltyDataUpdated(address reciever, uint256 Percentage);

    error InvalidAddresses();
    error InvalidPercentageAmount();

    //Mappings for storing records
    mapping(address => RoyaltiesData) public RoyaltyRecord;

    // Checks the owner of the collection
    modifier ownerOfContract(address _addressNFTCollection) {
        require(ERC1155Tempelate(_addressNFTCollection).owner() == msg.sender, "not the owner of the contract");
        _;
    }

    /** 
    * @notice Method for setting Royalties and reciever address
    * @param _addressNFTCollection is address of the contract
    * @param _royaltyReciever Address of the singular royalty
    * @param _royaltyPercentage Percentage of royalty from to 1000 in BIPs 

     */
    function setRoyalty(
        address _addressNFTCollection,
        address _royaltyReciever,
        uint256 _royaltyPercentage
    ) public ownerOfContract(_addressNFTCollection) {
        if (
            _addressNFTCollection == address(0) ||
            _royaltyReciever == address(0)
        ) {
            revert InvalidAddresses();
        }
        // require(_addressNFTCollection != address(0) || _royaltyReciever != address(0), "Invalid addresses");
        if (_royaltyPercentage < 0 && _royaltyPercentage > 500) {
            revert InvalidPercentageAmount();
        }
        // require(_royaltyPercentage >= 0 && _royaltyPercentage <= 10, "Invalid Royalty Percentage amount");

        RoyaltyRecord[_addressNFTCollection] = RoyaltiesData(
            _royaltyReciever,
            _royaltyPercentage
        );

        // emit RoyalityCreated(
        //     _addressNFTCollection,
        //     _royaltyReciever,
        //     _royaltyPercentage
        // );
    }

    /** 
    * @notice Method for Updating Royalties and reciever address
    * @param _addressNFTCollection is address of the contract
    * @param _royaltyReciever Address of the singular royalty
    * @param _royaltyPercentage Percentage of royalty from to 1000 in the form of bips

     */
    function updateRoyalty(
        address _addressNFTCollection,
        address _royaltyReciever,
        uint256 _royaltyPercentage
    ) public ownerOfContract(_addressNFTCollection) {
        if (_royaltyReciever == address(0)) {
            revert InvalidAddresses();
        }
        if (_royaltyPercentage < 0 && _royaltyPercentage > 1000) {
            revert InvalidPercentageAmount();
        }

        // Set new percentage for the contract
        RoyaltyRecord[_addressNFTCollection]
            .percentageOfRoyalty = _royaltyPercentage;

        // Set new reciever address
        RoyaltyRecord[_addressNFTCollection].royaltyReciever = _royaltyReciever;

        // emit RoyaltyDataUpdated(_royaltyReciever, _royaltyPercentage);
    }

    /**
     * @notice Method for calculating royalty
     * @param _addressNFTCollection is address of the contract
     * @param _price is the cost selling price of that NFT
     */
    function calculateRoyalties(address _addressNFTCollection, uint256 _price)
        public
        view
        returns (uint256)
    {
        //Stores percentage in a temperorary variable
        uint256 tempPercentage = RoyaltyRecord[_addressNFTCollection]
            .percentageOfRoyalty;
        //Calculate amount of royalties from the given percentage
        uint256 royaltyShare = ((_price * tempPercentage) / 10000);
        //Returns amount
        return royaltyShare;
    }


    function getRoyaltyReciever(address _addressNFTCollection) public view returns (address) {
        return RoyaltyRecord[_addressNFTCollection].royaltyReciever;
    }
}