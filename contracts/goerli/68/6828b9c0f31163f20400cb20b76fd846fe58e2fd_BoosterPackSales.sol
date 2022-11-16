// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizable is Ownable {
    //  Authorized addresses
    mapping(address => bool) public authorized;

    //  Modifier to check if the caller is authorized
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "Authorizable: Caller is not authorized");
        _;
    }

    /**
     * @dev Authorize an address
     * @param toAdd_ Address to authorize
     */
    function addAuthorized(address toAdd_) public onlyOwner {
        authorized[toAdd_] = true;
    }

    /**
     * @dev Unauthorize an address
     * @param toRemove_ Address to unauthorize
     */
    function removeAuthorized(address toRemove_) public onlyOwner {
        require(toRemove_ != msg.sender, "Authorizable: Owner cannot remove himself");
        authorized[toRemove_] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Authorizable } from "../Authorizable.sol";

import { BoosterPacks } from "./BoosterPacks.sol";

contract BoosterPackSales is Authorizable {
    using SafeERC20 for IERC20;

    //
    // Events
    //

    event SaleCreated(
        uint256 saleId,
        uint256 indexed tokenId,
        bool limitedTime,
        uint64 startTime,
        uint64 endTime,
        uint64 boosterPackAmount,
        uint64 boosterPackPrice
    );
    event SaleEdited(
        uint256 indexed saleId,
        uint256 tokenId,
        bool limitedTime,
        uint64 startTime,
        uint64 endTime,
        uint64 boosterPackAmount,
        uint64 boosterPackPrice
    );
    event SaleActivated(uint256 saleId);
    event SaleDeactivated(uint256 saleId);
    event BoosterPacksBought(uint256 indexed saleId, address to, uint64 amount);
    event PaymentWithdrawn(address to, uint256 amount);

    //
    // Modifiers
    //

    modifier onlyActive(uint256 saleId_) {
        require(saleId_ < _sales.length, "BoosterPackSales: Sale not found");
        require(_sales[saleId_].active, "BoosterPackSales: This sale is not active yet");

        _;
    }

    modifier onlyInactive(uint256 saleId_) {
        require(saleId_ < _sales.length, "BoosterPackSales: Sale not found");
        require(!_sales[saleId_].active, "BoosterPackSales: This sale is currently active");

        _;
    }

    //
    // Structs
    //

    /**
     * @dev Struct that defines a Booster Pack Sale.
     * @param tokenId           The tokenId of the Booster Pack sold in this Sale.
     * @param limitedTime       Whether a Sale is a limited time sale or not.
     * @param active            Whether a Sale is active or not.
     * @param startTime         If a Sale is a limited time Sale, indicates its start.
     * @param endTime           If a Sale is a limited time Sale, indicates its end.
     * The max uint64 value is 18446744073709551615.
     * As a timestamp it corresponds to: Sun Jul 21 2554 23:34:33 GMT+0000
     * @param boosterPackAmount The total Booster Pack amount to be sold.
     * @param boosterPackPrice  The price at which each Booster Pack will be sold.
     * As native currency, the max uint64 value corresponds to 18,446744073709551615 ether.
     */
    struct Sale {
        bool limitedTime;
        bool active;
        uint192 tokenId;
        uint64 bought;
        uint64 startTime;
        uint64 endTime;
        uint64 boosterPackAmount;
        uint64 boosterPackPrice;
    }

    //
    // State
    //

    BoosterPacks public boosterPacks;

    Sale[] private _sales;

    //
    // Constructor
    //

    /**
     * @notice Constructor for the BoosterPackSales contract.
     * @param boosterPacksAddress_  Address of the BoosterPacks contract.
     */
    constructor(address boosterPacksAddress_) {
        boosterPacks = BoosterPacks(boosterPacksAddress_);
    }

    //
    // Public API
    //

    /**
     * @notice Buys some 'amount_' of Booster Packs from the Sale given by 'saleId_' and mints them to 'to_'.
     * @param saleId_   ID of the Sale to buy from.
     * @param to_       Address to mint the bought Booster Packs to.
     * @param amount_   Amount of Booster Packs to buy.
     */
    function buy(
        uint256 saleId_,
        address to_,
        uint64 amount_
    ) public payable {
        require(saleId_ < _sales.length, "BoosterPackSales: Sale not found");
        require(to_ != address(0), "BoosterPackSales: Buyer cannot be address 0");
        Sale memory sale_ = _sales[saleId_];

        require(sale_.active, "BoosterPackSales: This sale is not active yet");

        if (sale_.limitedTime) {
            require(block.timestamp >= sale_.startTime, "BoosterPackSales, This sale hasn't started yet");
            require(block.timestamp <= sale_.endTime, "BoosterPackSales: This sale is already over");
        }

        require(msg.value == sale_.boosterPackPrice * amount_, "BoosterPackSales: Incorrect value sent for this sale");
        require(
            sale_.bought + amount_ <= sale_.boosterPackAmount,
            "BoosterPackSales: Amount surpasses Sale's Booster Pack amount"
        );

        _sales[saleId_].bought += amount_;

        emit BoosterPacksBought(saleId_, to_, amount_);

        boosterPacks.mint(to_, sale_.tokenId, amount_, "");
    }

    //
    // Authorized API
    //

    /**
     * @notice Creates a new Sale for the Booster Pack with given 'tokenId_'.
     * @param tokenId_              Token ID of the Booster Pack being sold in this Sale.
     * @param limitedTime_          Whether this Sale is a limited time sale.
     * @param startTime_            If the Sale is of limited time, the time at which it starts.
     * @param endTime_              If the Sale is of limited time, the time at which it ends.
     * @param boosterPackAmount_    The amount of Booster Packs to be sold in this Sale.
     * @param boosterPackPrice_     The price of each Booster Pack in this Sale.
     * For more info on Sale parameters, check the 'Sale' struct definition.
     */
    function addSale(
        uint192 tokenId_,
        bool limitedTime_,
        uint64 startTime_,
        uint64 endTime_,
        uint64 boosterPackAmount_,
        uint64 boosterPackPrice_
    ) public onlyAuthorized {
        _validateSaleParams(tokenId_, limitedTime_, startTime_, endTime_, boosterPackAmount_, boosterPackPrice_);

        Sale memory sale_ = Sale({
            limitedTime: limitedTime_,
            active: false,
            tokenId: tokenId_,
            bought: 0,
            startTime: startTime_,
            endTime: endTime_,
            boosterPackAmount: boosterPackAmount_,
            boosterPackPrice: boosterPackPrice_
        });

        _sales.push(sale_);

        emit SaleCreated(
            _sales.length - 1,
            tokenId_,
            limitedTime_,
            startTime_,
            endTime_,
            boosterPackAmount_,
            boosterPackPrice_
        );
    }

    /**
     * @notice Edits the parameters of a previously created Sale.
     * @param saleId_               The ID of the Sale to edit the parameters of.
     * @param tokenId_              The new ID of the Booster Pack being sold in this phase.
     * @param limitedTime_          Whether this Sale is a limited time sale.
     * @param startTime_            If the Sale is of limited time, the new time at which it starts.
     * @param endTime_              If the Sale is of limited time, the new time at which it ends.
     * @param boosterPackAmount_    The new amount of Booster Packs to be sold in this Sale.
     * @param boosterPackPrice_     The new price of each Booster Pack in this Sale.
     * For more info on Sale parameters, check the 'Sale' struct definition.
     */
    function editSale(
        uint256 saleId_,
        uint192 tokenId_,
        bool limitedTime_,
        uint64 startTime_,
        uint64 endTime_,
        uint64 boosterPackAmount_,
        uint64 boosterPackPrice_
    ) public onlyAuthorized {
        _validateSaleParams(tokenId_, limitedTime_, startTime_, endTime_, boosterPackAmount_, boosterPackPrice_);
        require(saleId_ < _sales.length, "BoosterPackSales: Sale not found");

        Sale storage sale = _sales[saleId_];

        sale.tokenId = tokenId_;
        sale.limitedTime = limitedTime_;
        sale.startTime = startTime_;
        sale.endTime = endTime_;
        sale.boosterPackAmount = boosterPackAmount_;
        sale.boosterPackPrice = boosterPackPrice_;

        emit SaleEdited(saleId_, tokenId_, limitedTime_, startTime_, endTime_, boosterPackAmount_, boosterPackPrice_);
    }

    /**
     * @notice Activates a Sale.
     * @dev For Booster Packs to be bought from a Sale, the Sale needs to be activated beforehand.
     * @param saleId_   The ID of the Sale to activate.
     */
    function activateSale(uint256 saleId_) public onlyAuthorized {
        require(saleId_ < _sales.length, "BoosterPackSales: Sale not found");

        _sales[saleId_].active = true;

        emit SaleActivated(saleId_);
    }

    /**
     * @notice Deactivates a Sale.
     * @param saleId_   The ID of the Sale to deactivate.
     */
    function deactivateSale(uint256 saleId_) public onlyAuthorized {
        require(saleId_ < _sales.length, "BoosterPackSales: Sale not found");

        _sales[saleId_].active = false;

        emit SaleDeactivated(saleId_);
    }

    /**
     * @notice Withdraws the payment received from selling Booster Packs.
     * @param to_   The address to send the funds to.
     * @param amount_   The amount of funds to withdraw.
     */
    function withdrawPayment(address to_, uint256 amount_) public onlyAuthorized {
        require(to_ != address(0), "BoosterPackSales: Cannot send funds to address zero");
        require(amount_ <= address(this).balance, "BoosterPackSales: Not enough funds in Sales contract");

        emit PaymentWithdrawn(to_, amount_);
        payable(to_).transfer(amount_);
    }

    /**
     * @notice Withdraws any ERC20 tokens wrongfully sent to this contract.
     * @param token_    The address of the ERC20 token to withdraw.
     * @param to_       The address to withdraw the tokens to.
     * @param amount_   The amount of tokens to withdraw.
     */
    function withdrawERC20(
        address token_,
        address to_,
        uint256 amount_
    ) public onlyAuthorized {
        IERC20(token_).safeTransfer(to_, amount_);
    }

    //
    // Public Read API
    //

    /**
     * @notice Getter for a specific Sale's parameters.
     * @param saleId_   The ID of the Sale to get the parameters of.
     */
    function getSale(uint256 saleId_) public view returns (Sale memory) {
        return _sales[saleId_];
    }

    /**
     * @notice Getter for the number of created Sales.
     */
    function getSalesCount() public view returns (uint256) {
        return _sales.length;
    }

    /**
     * @notice Checks if the Sale with given 'saleId_' is active.
     */
    function isSaleActive(uint256 saleId_) public view returns (bool) {
        return _sales[saleId_].active;
    }

    /**
     * @notice Getter for the amount of Booster Packs that have yet to be sold in a given Sale.
     */
    function getAvailableAmount(uint256 saleId_) public view returns (uint64) {
        Sale memory sale_ = _sales[saleId_];
        return uint64(sale_.boosterPackAmount - sale_.bought);
    }

    //
    // Internal API
    //

    /**
     * @notice Internal function to validate Sale parameters.
     *
     * For more info on parameters, refer to the 'Sale' struct definition.
     */
    function _validateSaleParams(
        uint256 tokenId_,
        bool limitedTime_,
        uint64 startTime_,
        uint64 endTime_,
        uint64 boosterPackAmount_,
        uint64 boosterPackPrice_
    ) internal view {
        require(boosterPacks.exists(tokenId_), "BoosterPackSales: Invalid token ID");

        if (limitedTime_) {
            require(startTime_ > 0, "BoosterPackSales: Limited time sale cannot have zero start time");
            require(endTime_ > startTime_, "BoosterPackSales: End time must be greater than start time");
        }

        require(boosterPackAmount_ > 0, "BoosterPackSales: Booster Pack amount must be greater than zero");
        require(boosterPackPrice_ > 0, "BoosterPackSales: Booster Pack price must be greater than zero");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Authorizable } from "../Authorizable.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract BoosterPacks is ERC1155, Authorizable {
    //
    // Events
    //

    event URISet(string uri);
    event BoosterPackCreated(uint256 tokenId, uint256 maxSupply, uint256 expiryDate, uint256 boostMultiplier);
    event BoosterParamsUpdated(uint256 tokenId, uint256 expiryDate, uint256 boostMultiplier);
    event MaxSupplyUpdated(uint256 tokenId, uint256 newMaxSupply);
    event Minted(uint256 indexed tokenId, address to, uint256 amount);
    event Burned(uint256 indexed tokenId, address to, uint256 amount);

    //
    // Structs
    //

    struct BoostParams {
        uint256 expiryBlock; //  Block at which this Booster Pack expires.
        uint256 boostMultiplier; //  Value to multiply the rewards by. Divide by 10 after using.
    }

    //
    // State
    //

    string private _name; //  Collection's name.
    string private _symbol; //  Collection's symbol.

    //  mapping (tokenID => cap)
    mapping(uint256 => uint256) public maxSupply; //  Supply cap of each token.
    //  mapping (tokenID => totalSupply)
    mapping(uint256 => uint256) public totalSupply; //  Total supply of each token.

    //  mapping (tokenID => parameters)
    mapping(uint256 => BoostParams) public boosterParams; //  Parameters of each token.

    //
    // Constructor
    //

    /**
     * @notice Constructor for the BoosterPacks contract.
     * @param name_     The collection's name.
     * @param symbol_   The collection's symbol.
     * @param uri_      Initial URI of the collection. Can be modified afterwards.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;

        emit URISet(uri_);
    }

    //
    // Public Write API
    //

    /**
     * @notice Burns a Booster Pack if it has expired.
     * @param from_     The user to burn the tokens from.
     * @param tokenId_  The ID of the token to burn.
     * @param amount_   The amount of tokens to burn.
     */
    function burnExpired(
        address from_,
        uint256 tokenId_,
        uint256 amount_
    ) external {
        require(
            from_ == msg.sender || isApprovedForAll(from_, msg.sender),
            "BoosterPacks: caller is not token owner or approved"
        );
        require(
            boosterParams[tokenId_].expiryBlock < block.number,
            "BoosterPacks: This Booster Pack has not expired yet"
        );

        totalSupply[tokenId_] -= amount_;
        maxSupply[tokenId_] -= amount_;

        _burn(from_, tokenId_, amount_);

        emit Burned(tokenId_, from_, amount_);
    }

    //
    // Authorized API
    //

    /**
     * @notice Creates a new Booster Pack with the desired token ID.
     * @param tokenId_          Token ID to create the Booster Pack with.
     * @param maxSupply_        Supply cap of the newly created Booster Pack.
     * @param expiryBlock_      Block number at which this Booster Pack expires.
     * @param boostMultiplier_  Multiplier this Booster Pack applies to LP rewards.
     *                          Check struct definition for more info.
     */
    function createBoosterPack(
        uint256 tokenId_,
        uint256 maxSupply_,
        uint256 expiryBlock_,
        uint256 boostMultiplier_
    ) public onlyAuthorized {
        require(maxSupply[tokenId_] == 0, "BoosterPacks: Booster pack with this ID already exists");
        require(maxSupply_ > 0, "BoosterPacks: Cannot create booster pack with 0 max supply");
        require(expiryBlock_ > block.number, "BoosterPacks: Expiry block must be greater than block number");
        require(boostMultiplier_ > 10, "BoosterPacks: Boost multiplier must be greater than 10");

        maxSupply[tokenId_] = maxSupply_;

        BoostParams memory boosterParams_ = BoostParams({
            expiryBlock: expiryBlock_,
            boostMultiplier: boostMultiplier_
        });

        boosterParams[tokenId_] = boosterParams_;

        emit BoosterPackCreated(tokenId_, maxSupply_, expiryBlock_, boostMultiplier_);
    }

    /**
     * @notice Updates the parameters of the Booster Pack with the given token ID.
     * @param tokenId_          The ID of the Booster Pack to update the parameters of.
     * @param expiryBlock_      The new block at which this Booster Pack expires.
     * @param boostMultiplier_  The new multiplier this Booster Pack applies, when used.
     */
    function updateBoosterParams(
        uint256 tokenId_,
        uint256 expiryBlock_,
        uint256 boostMultiplier_
    ) public onlyAuthorized {
        require(exists(tokenId_), "BoosterPacks: Invalid token ID");
        //  Here we bypass the expiry and multiplier checks so authorized addresses can nullify
        //  the effects of a certain Booster Pack, in case of emergency.
        //
        //  E.g. If we set the multiplier to 10, then the Booster Pack has no effect. Likewise,
        //  if we set the expiryBlock to be lesser than block.timestamp, the Booster Pack cannot be
        //  activated.

        BoostParams storage boostParams = boosterParams[tokenId_];

        boostParams.expiryBlock = expiryBlock_;
        boostParams.boostMultiplier = boostMultiplier_;

        emit BoosterParamsUpdated(tokenId_, expiryBlock_, boostMultiplier_);
    }

    /**
     * @notice Updates the supply cap of the Booster Pack with given token ID.
     * @param tokenId_  The ID of the Booster Pack to update the supply cap of.
     * @param newMaxSupply_ The new supply cap of the Booster Pack.
     */
    function updateMaxSupply(uint256 tokenId_, uint256 newMaxSupply_) public onlyAuthorized {
        require(exists(tokenId_), "BoosterPacks: Invalid token ID");
        require(newMaxSupply_ > 0, "BoosterPacks: Max supply cannot be zero");
        require(
            newMaxSupply_ >= totalSupply[tokenId_],
            "BoosterPacks: Max supply must not be lesser than total supply"
        );

        maxSupply[tokenId_] = newMaxSupply_;

        emit MaxSupplyUpdated(tokenId_, newMaxSupply_);
    }

    /**
     * @notice Sets a new uri for this collection.
     * @param uri_  The new uri of the Booster Pack NFT collection.
     */
    function setURI(string memory uri_) public onlyAuthorized {
        _setURI(uri_);

        emit URISet(uri_);
    }

    /**
     * @notice Mints 'amount_' of tokens with 'tokenId_' to a user with address 'to_'.
     * @dev Only callable by previously authorized addresses.
     * @param to_       The address to mint the tokens to.
     * @param tokenId_  The ID of the token to mint.
     * @param amount_   The amount of tokens to be minted.
     * @param data_     Arbitrary data to be sent to the callback function.
     */
    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        bytes memory data_
    ) external onlyAuthorized {
        require(totalSupply[tokenId_] + amount_ <= maxSupply[tokenId_], "BoosterPacks: Mint surpasses the max supply");

        totalSupply[tokenId_] += amount_;

        _mint(to_, tokenId_, amount_, data_);

        emit Minted(tokenId_, to_, amount_);
    }

    /**
     * @notice Burns 'amount_' of tokens with 'tokenId_' from the holder with address 'from_'.
     * @dev To be used by the MasterHunter contract to activate Boosts.
     * @param from_     The address to burn the tokens from.
     * @param tokenId_  The ID of the tokens to burn.
     * @param amount_   The amount of tokens to burn.
     */
    function burn(
        address from_,
        uint256 tokenId_,
        uint256 amount_
    ) external onlyAuthorized {
        require(
            from_ == msg.sender || isApprovedForAll(from_, msg.sender),
            "ERC1155: caller is not token owner or approved"
        );

        totalSupply[tokenId_] -= amount_;
        maxSupply[tokenId_] -= amount_;

        _burn(from_, tokenId_, amount_);

        emit Burned(tokenId_, from_, amount_);
    }

    //
    // Public Read API
    //

    /**
     * @notice Getter for the Booster Parameters of the Booster Pack with the given ID.
     *         Check the 'BoostParams' struct definition for more info.
     * @param tokenId_  The token ID of the Booster Pack to get the parameters of.
     */
    function getBoosterParams(uint256 tokenId_) public view returns (BoostParams memory) {
        return boosterParams[tokenId_];
    }

    /**
     * @notice Getter for the mintable supply of tokens with the given token ID.
     * @param tokenId_  The token ID of the Booster Pack to get the available supply of.
     */
    function availableSupply(uint256 tokenId_) public view returns (uint256) {
        return maxSupply[tokenId_] - totalSupply[tokenId_];
    }

    /**
     * @notice Getter for the name of the collection.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Getter for the symbol of the collection.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Checks whether the token with the given ID has already been created.
     * @dev A token existing means that its supply cap is greater than 0.
     * @param tokenId_  The token ID of the token to check the existence of.
     */
    function exists(uint256 tokenId_) public view returns (bool) {
        return maxSupply[tokenId_] > 0;
    }
}