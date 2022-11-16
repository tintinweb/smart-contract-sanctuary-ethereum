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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../test/test-default/utils/DefimonsToken.sol";
import "./Authorizable.sol";

import "./BoosterPack/BoosterPacks.sol";

contract MasterHunter is Authorizable, ReentrancyGuard {
    // solhint-disable-previous-line max-states-count

    using SafeERC20 for IERC20;

    //
    // Structs
    //

    /**
     * @dev Constructor arguments for this contract.
     */
    struct ConstructorArgs {
        address govTokenAddress; //  Address of the rewards token contract.
        address boosterPacksAddress; //  Address of the Booster Packs contract.
        address devAddr; //  Developer address.
        address liquidityAddr; //  Liquidity address.
        address comFundAddr; //  Community Fund address.
        address founderAddr; //  Founder's address.
        uint256 rewardPerBlock; //  Base reward per block.
        uint256 startBlock; //  Block at which reward emissions begin.
        uint256 userDepFee; //  User deposit fee.
        uint256 devDepFee; //  Developer deposit fee.
        uint256 epochDuration; //  Duration of each Epoch, in blocks.
        uint256 numEpochs; //  Total number of Epochs in which rewards are emitted and locked.
        uint256[] rewardMultiplier; //  Reward multiplier of each Epoch.
        uint256[] withdrawalFeeStage; //  Time stages at which withdrawal fees are applied.
        uint256[] userFeeStage; //  User withdrawal fee depending on stage.
        uint256[] devFeeStage; //  Developer withdrawal fee depending on stage.
        uint256[] percentLockReward; //  Percentage of rewards to be locked depending on Epoch.
    }

    struct UserInfo {
        uint256 amount; //  Amount of LP Tokens the user currently has staked.
        uint256 rewardDebt; //  Amount of MON Tokens accumulated in harvests.
        uint256 rewardDebtAtBlock; //  Block number of the last harvest.
        uint256 lastWithdrawBlock; //  Last block at which a withdrawal was made
        uint256 firstDepositBlock; //  First block at which the user staked LP Tokens
        uint256 lastDepositBlock; //  Last block ar which the user staked LP Tokens
        //
        //  At any point in time the amount of MON entitled to a user
        //  but pending to be distributed is:
        //
        //      pending reward = (user.amount * pool.accGovTokenPerShare) - user.rewardDebt
        //          +
        //      boosted reward between boost.lastBoostedRewardBlock, block.number
        //
        //  Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //      1. The pool's `accGovTokenPerShare` (and `lastRewardBlock`) gets updated.
        //      2. User receives the pending reward sent to his/her address.
        //      3. User receives the pending boostedReward
        //      4. lastBoostedRewardBlock gets updated
        //      5. User's `amount` gets updated.
        //      6. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 lpToken; //  The pool's LP Token
        uint256 allocPoints; //  The pool's Allocation Points
        uint256 lastRewardBlock; //  The last block at which pool rewards were updated
        uint256 accGovTokenPerShare; //  Accumulated governance token per share of the pool
    }

    struct Boost {
        uint256 boostStartBlock; //  The block at which the Boost was applied.
        uint256 boostEndBlock; //  Final block at which the Boost is valid.
        uint256 boostMultiplier; //  Boost multiplier. Divide by 10 when using.
        uint256 lastBoostedRewardBlock; //  Last block at which this boost's rewards were harvested.
    }

    //
    // Events
    //

    event PoolAdded(address lpToken, uint256 allocPoints);
    event BoostActivated(
        uint256 indexed poolId,
        address user,
        uint256 boostStartBlock,
        uint256 boostEndBlock,
        uint256 boostMultiplier
    );
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SendBoostedRewards(address indexed user, uint256 indexed pid, uint256 amount);
    event SendGovernanceTokenReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);
    event SetRewardPerBlock(uint256 rewardPerBlock);
    event SetFinishRewardBlock(uint256 finishRewardBlock);
    event SetPercentDev(uint64 percentDev);
    event SetPercentLP(uint64 percentLP);
    event SetPercentCom(uint64 percentCom);
    event SetPercentFounder(uint64 percentFounder);
    event SetStartBlock(uint256 startBlock);

    //
    // State
    //

    //  The Reward Token.
    DefimonsToken public govToken;
    //  Booster Pack NFTs contract.
    BoosterPacks public boosterPacks;

    //  Developer Address.
    //  This address will receive all the withdrawal fees, as well as a percentage
    //  of Reward Tokens emitted if 'percentDev' is set.
    address public devAddr;
    //  Liquidity Address.
    address public liquidityAddr;
    //  Community Fund Address.
    address public comFundAddr;
    //  Founder Address.
    address public founderAddr;

    //  The duration of 1 Epoch.
    uint256 public epochDuration;
    //  Base Reward Emitted per Block.
    uint256 public rewardPerBlock;
    //  Block at which the Rewards emission starts.
    uint256 public startBlock;
    //  Reward Multiplier of Each Epoch.
    //  Divide by 10 when using.
    uint256[] public rewardMultiplier;
    //  Blocks at which the Reward Emissions go down.
    //  Emissions are only completed at the end of each block. You can only claim emissions of block x at block x + 1.
    //  E.g. If emissions start at block 20 and an Epoch lasts 10 blocks,
    //  then Epoch 1 would happen from block 20-29 and 'halvingAtBlock[0]' would be 30 like so:
    //  [epochStartBlock - epochEndBlock[
    uint256[] public halvingAtBlock;
    //  Used to see what withdrawal fee is applicable when withdraw() is called.
    uint256[] public withdrawalFeeStage;
    //  User withdrawal fee to use depending on withdrawal stage.
    uint256[] public userFeeStage;
    //  Developer withdrawal fee to use depending on withdrawal stage.
    uint256[] public devFeeStage;
    //  Block in which reward token emissions stop.
    uint256 public finishRewardBlock;
    //  User deposit fee.
    //  Divide by 10 000 when using.
    uint256 public userDepFee;
    //  Developer deposit fee.
    //  Divide by 10 000 when using.
    uint256 public devDepFee;

    //  Reward Locking Percentages per Epoch.
    uint256[] public percentLockReward;
    //  Percentage of Reward for Developers.
    uint64 public percentDev;
    //  Percentage of Reward for LP.
    uint64 public percentLP;
    //  Percentage of Reward for Community.
    uint64 public percentCom;
    //  Percentage of Reward for Founder.
    uint64 public percentFounder;

    //  Pool Info
    PoolInfo[] public poolInfo;
    //  poolAddress => poolId1
    //  Starts at 1, subtract 1 before using with poolInfo.
    mapping(address => uint256) public poolId1;
    //  Active boosts.
    //  user => poolId => Boost struct
    mapping(address => mapping(uint256 => Boost)) private _boosts;
    //  Info of each user that stakes LP Tokens. poolId => userAddress => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    //  Total allocation points.
    //  Sum of all alocation points in all pools.
    uint256 public totalAllocPoints = 0;

    /**
     * @notice Constructor for the MasterHunter contract.
     */
    constructor(ConstructorArgs memory args_) {
        require(args_.govTokenAddress != address(0), "Governance Token address cannot be address 0.");
        require(args_.boosterPacksAddress != address(0), "Booster Packs address cannot be address 0.");
        require(args_.devAddr != address(0), "Developer address cannot be address 0.");
        require(args_.liquidityAddr != address(0), "Liquidity address cannot be address 0.");
        require(args_.comFundAddr != address(0), "Community Fund address cannot be address 0.");
        require(args_.founderAddr != address(0), "Founder address cannot be address 0.");

        govToken = DefimonsToken(args_.govTokenAddress);
        boosterPacks = BoosterPacks(args_.boosterPacksAddress);
        devAddr = args_.devAddr;
        liquidityAddr = args_.liquidityAddr;
        comFundAddr = args_.comFundAddr;
        founderAddr = args_.founderAddr;
        rewardPerBlock = args_.rewardPerBlock;
        startBlock = args_.startBlock;
        epochDuration = args_.epochDuration;
        userDepFee = args_.userDepFee;
        devDepFee = args_.devDepFee;

        rewardMultiplier = args_.rewardMultiplier;
        withdrawalFeeStage = args_.withdrawalFeeStage;
        userFeeStage = args_.userFeeStage;
        devFeeStage = args_.devFeeStage;
        percentLockReward = args_.percentLockReward;

        for (uint256 i = 0; i < args_.numEpochs; ) {
            uint256 halvingAtBlock_ = (args_.startBlock + (args_.epochDuration * (i + 1)));
            halvingAtBlock.push(halvingAtBlock_);
            unchecked {
                ++i;
            }
        }

        halvingAtBlock.push(type(uint256).max);

        finishRewardBlock = args_.startBlock + args_.epochDuration * args_.numEpochs;
    }

    //
    // Owner API
    //

    /**
     * @notice Add a new LP Token to the pool. Can only be called by the owner.
     * @param allocPoints_  Allocation points attributed to this pool
     * @param lpToken_      LP Token contract to add
     * @param withUpdate_   Set to 'true' if all pools should be updated before adding this one.
     *                      Setting this parameter to 'true' is recommended when adding a new pool.
     */
    function add(
        uint256 allocPoints_,
        IERC20 lpToken_,
        bool withUpdate_
    ) public onlyOwner {
        require(poolId1[address(lpToken_)] == 0, "MasterHunter::add: lp is already in pool");

        if (withUpdate_) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

        totalAllocPoints += allocPoints_;
        poolId1[address(lpToken_)] = poolInfo.length + 1;

        poolInfo.push(
            PoolInfo({
                lpToken: lpToken_,
                allocPoints: allocPoints_,
                lastRewardBlock: lastRewardBlock,
                accGovTokenPerShare: 0
            })
        );

        emit PoolAdded(address(lpToken_), allocPoints_);
    }

    //
    // Public Write API
    //

    /**
     * @notice Boosts a Pool's generated rewards for a specific user by burning a Booster Pack NFT given by 'boostId_'.
     * @dev When boosting a pool, the user's pending rewards for that pool are always harvested.
     *      The user has to previously approve this contract to burn its Booster Pack.
     * @param poolId_   Pool ID referencing the Pool to be boosted.
     * @param boostId_  ID of the Booster Pack to be used.
     */
    function boost(uint256 poolId_, uint256 boostId_) public nonReentrant {
        require(poolId_ < poolInfo.length, "MasterHunter: Pool not found");

        require(
            _boosts[msg.sender][poolId_].boostEndBlock <= block.number,
            "MasterHunter: You already have an active boost for this pool"
        );

        //  Retrieve the Booster Pack parameters from the BoosterPacks contract.
        BoosterPacks.BoostParams memory boostParams_ = boosterPacks.getBoosterParams(boostId_);

        require(boostParams_.expiryBlock >= block.number, "MasterHunter: This Booster Pack has expired");

        updatePool(poolId_); //  Update the Pool.

        _harvest(poolId_); //  Harvest any rewards generated by a previous boost.

        uint256 boostStartBlock_;
        uint256 boostEndBlock_;

        if (block.number < startBlock) {
            boostStartBlock_ = startBlock;
            boostEndBlock_ = startBlock + epochDuration;
        } else {
            boostStartBlock_ = block.number;
            boostEndBlock_ = block.number + epochDuration;
        }

        Boost memory boost_ = Boost({ //  Create the Boost.
            boostStartBlock: boostStartBlock_,
            boostEndBlock: boostEndBlock_,
            boostMultiplier: boostParams_.boostMultiplier,
            lastBoostedRewardBlock: boostStartBlock_
        });

        _boosts[msg.sender][poolId_] = boost_; //  Activate the boost.

        boosterPacks.burn(msg.sender, boostId_, 1); //  Burn the Booster Pack NFT.

        emit BoostActivated(poolId_, msg.sender, boostStartBlock_, boostEndBlock_, boostParams_.boostMultiplier);
    }

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ) {
            updatePool(pid);

            unchecked {
                ++pid;
            }
        }
    }

    /**
     * @notice Updates the rewards of the given Pool.
     * @param poolId_   ID of the Pool to be updated.
     */
    function updatePool(uint256 poolId_) public {
        PoolInfo storage pool = poolInfo[poolId_];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 govTokenForDev;
        uint256 govTokenForFarmer;
        uint256 govTokenForLP;
        uint256 govTokenForCom;
        uint256 govTokenForFounders;
        (govTokenForDev, govTokenForFarmer, govTokenForLP, govTokenForCom, govTokenForFounders) = getPoolReward(
            poolId_,
            pool.lastRewardBlock,
            block.number
        );

        pool.accGovTokenPerShare += (govTokenForFarmer * 1e12) / lpSupply;
        pool.lastRewardBlock = block.number;

        govToken.mintLPReward(address(this), govTokenForFarmer);

        if (govTokenForDev > 0) {
            govToken.mintLPReward(address(devAddr), govTokenForDev);
            //  Dev fund has xx% locked during the starting bonus period.
            //  After which locked funds drip out linearly each block over 3 years.
            if (block.number <= finishRewardBlock) {
                govToken.lock(address(devAddr), (govTokenForDev * 75) / 100);
            }
        }
        if (govTokenForLP > 0) {
            govToken.mintLPReward(liquidityAddr, govTokenForLP);
            //  LP + Partnership fund has only xx% locked over time as most of it
            //  is needed early on for incentives and listings.
            //  The locked amount will drip out linearly each block after the bonus period.
            if (block.number <= finishRewardBlock) {
                govToken.lock(address(liquidityAddr), (govTokenForLP * 45) / 100);
            }
        }
        if (govTokenForCom > 0) {
            govToken.mintLPReward(comFundAddr, govTokenForCom);
            //  Community Fund has xx% locked during bonus period and then drips out linearly.
            if (block.number <= finishRewardBlock) {
                govToken.lock(address(comFundAddr), (govTokenForCom * 85) / 100);
            }
        }
        if (govTokenForFounders > 0) {
            govToken.mintLPReward(founderAddr, govTokenForFounders);
            //  The Founders reward has xx% of their funds locked during the bonus period which then drip out linearly.
            if (block.number <= finishRewardBlock) {
                govToken.lock(address(founderAddr), (govTokenForFounders * 95) / 100);
            }
        }
    }

    /**
     * @notice Claim rewards of msg.sender from all Pools passed in the array. Be careful of gas spending!
     * @param poolIds_  Pool IDs indicating which pools to update
     */
    function claimRewards(uint256[] memory poolIds_) public {
        for (uint256 i = 0; i < poolIds_.length; ) {
            claimReward(poolIds_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claims rewards of msg.sender from a certain pool.
     * @dev Updates the pool's rewards before calling '_harvest()'.
     * @param poolId_   ID of the pool to claim the rewards from
     */
    function claimReward(uint256 poolId_) public {
        updatePool(poolId_);
        _harvest(poolId_);
    }

    /**
     * @notice Deposits LP Tokens into the pool.
     * @dev Updates the given pool and harvests user rewards before depositing the new LP Tokens.
     *      Tokens have to be previously approved by the user.
     * @param poolId_   ID of the pool to deposit the LP Tokens of.
     * @param amount_   Amount of LP Tokens to deposit.
     */
    function deposit(uint256 poolId_, uint256 amount_) public nonReentrant {
        require(amount_ > 0, "MasterHunter::deposit: Amount must be greater than 0");

        PoolInfo memory pool_ = poolInfo[poolId_];
        UserInfo storage user = userInfo[poolId_][msg.sender];
        UserInfo storage devr = userInfo[poolId_][devAddr];

        updatePool(poolId_);
        _harvest(poolId_);

        pool_.lpToken.safeTransferFrom(msg.sender, address(this), amount_);

        if (user.amount == 0) {
            //  If the user's amount was zero before the deposit, '_harvest()' didn't execute.
            user.rewardDebtAtBlock = block.number;
        }

        //  Add new deposit to the user's amount accounting for the user deposit fee.
        user.amount += amount_ - ((amount_ * userDepFee) / 10000);
        user.rewardDebt = (user.amount * pool_.accGovTokenPerShare) / 1e12;

        devr.amount += amount_ - ((amount_ * devDepFee) / 10000);
        devr.rewardDebt = (devr.amount * pool_.accGovTokenPerShare) / 1e12;

        emit Deposit(msg.sender, poolId_, amount_);

        if (!(user.firstDepositBlock > 0)) user.firstDepositBlock = block.number;

        user.lastDepositBlock = block.number;
    }

    /**
     * @notice Withdraws the LP Tokens deposited by msg.sender from the given pool.
     * @dev Updates the pool and harvests user rewards before executing the withdrawal.
     * @param poolId_   ID of the pool to withdraw the tokens from
     * @param amount_   Amount of tokens to withdraw
     */
    function withdraw(uint256 poolId_, uint256 amount_) public nonReentrant {
        PoolInfo memory pool_ = poolInfo[poolId_];
        UserInfo storage user = userInfo[poolId_][msg.sender];

        require(user.amount >= amount_, "MasterHunter::withdraw: Amount is greater than user amount");

        updatePool(poolId_);
        _harvest(poolId_);

        if (amount_ > 0) {
            user.amount -= amount_;
            uint256 blockDelta;

            if (user.lastWithdrawBlock > 0) blockDelta = block.number - user.lastWithdrawBlock;
            else blockDelta = block.number - user.firstDepositBlock;

            user.rewardDebt = (user.amount * pool_.accGovTokenPerShare) / 1e12;
            user.lastWithdrawBlock = block.number;

            if (blockDelta == 0 || block.number == user.lastDepositBlock) {
                //  25% Slashing Fee
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[0]) / 100);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[0]) / 100);
            } else if (blockDelta < withdrawalFeeStage[0]) {
                //  8% Fee if user withdraws in under 1 hour
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[1]) / 100);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[1]) / 100);
            } else if (blockDelta < withdrawalFeeStage[1]) {
                // 4% Fee if user withdraws in under 24 hours
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[2]) / 100);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[2]) / 100);
            } else if (blockDelta < withdrawalFeeStage[2]) {
                // 2% Fee if user withdraws in under 3 days
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[3]) / 100);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[3]) / 100);
            } else if (blockDelta < withdrawalFeeStage[3]) {
                //  1% Fee if user withdraws in under 5 days
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[4]) / 100);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[4]) / 100);
            } else if (blockDelta < withdrawalFeeStage[4]) {
                //  0.5% Fee if user withdraws in under 2 weeks
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[5]) / 1000);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[5]) / 1000);
            } else if (blockDelta < withdrawalFeeStage[5]) {
                //  0.25% Fee if user withdraws in under 4 weeks
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[6]) / 10000);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[6]) / 10000);
            } else {
                //  0.01% Fee if user withdraws after 4 weeks
                pool_.lpToken.safeTransfer(msg.sender, (amount_ * userFeeStage[7]) / 10000);
                pool_.lpToken.safeTransfer(devAddr, (amount_ * devFeeStage[7]) / 10000);
            }

            emit Withdraw(msg.sender, poolId_, amount_);
        }
    }

    /**
     * @notice Withdraws all of the users deposited LP Tokens applying a 25% slashing fee.
     * @dev Should only be used in case of emergency e.g. DEX failure.
     *      The 25% fee is applied to defend from possible exploits.
     * @param poolId_ ID of the pool to withdraw the tokens from
     */
    function emergencyWithdraw(uint256 poolId_) public nonReentrant {
        PoolInfo memory pool_ = poolInfo[poolId_];
        UserInfo storage user = userInfo[poolId_][msg.sender];

        //  Automatic 25% Slashing fee on emergency withdrawal.
        uint256 amountToSend = (user.amount * 75) / 100;
        uint256 devToSend = (user.amount * 25) / 100;

        user.amount = 0;
        user.rewardDebt = 0;

        pool_.lpToken.safeTransfer(msg.sender, amountToSend);
        pool_.lpToken.safeTransfer(devAddr, devToSend);

        emit EmergencyWithdraw(msg.sender, poolId_, amountToSend);
    }

    //
    // Public Read API
    //

    /**
     * @notice Accumulated multiplier for the given timeframe.
     * @dev Divide by 10 before using.
     * @param from_ The lower limit of the timeframe to consider
     * @param to_ The upper limit of the timeframe to consider
     */
    function getAccumulatedMultiplier(uint256 from_, uint256 to_) public view returns (uint256) {
        uint256 result = 0;

        if (from_ < startBlock) return 0;

        uint256 length_ = halvingAtBlock.length;
        for (uint256 i = 0; i < length_; ) {
            uint256 endBlock = halvingAtBlock[i];

            if (i > rewardMultiplier.length - 1) return 0;

            if (to_ <= endBlock) {
                uint256 m = rewardMultiplier[i] * (to_ - from_);
                return result + m;
            }

            if (from_ < endBlock) {
                uint256 m = rewardMultiplier[i] * (endBlock - from_);
                from_ = endBlock;
                result += m;
            }

            unchecked {
                ++i;
            }
        }

        return result;
    }

    /**
     * @notice Lock percentage for the Epoch we're in.
     * @param from_ Lower limit of the timeframe we're considering
     * @param to_   Upper limit of the timerframe we're considering
     */
    function getLockPercentage(uint256 from_, uint256 to_) public view returns (uint256) {
        uint256 result = 0;

        if (from_ < startBlock) return 100;

        uint256 length_ = halvingAtBlock.length;
        for (uint256 i = 0; i < length_; ) {
            uint256 endBlock = halvingAtBlock[i];

            if (i > percentLockReward.length - 1) return 0;

            if (to_ <= endBlock) return percentLockReward[i];

            unchecked {
                ++i;
            }
        }

        return result;
    }

    /**
     * @notice Generates the pool rewards for a certain pool in a given timeframe.
     * @param poolId_       ID of the pool to generate the rewards of
     * @param from_         Lower limit of the timeframe to be considered
     * @param to_           Upper limit of the timeframe to be considered
     */
    function getPoolReward(
        uint256 poolId_,
        uint256 from_,
        uint256 to_
    )
        public
        view
        returns (
            uint256 forDev,
            uint256 forFarmer,
            uint256 forLP,
            uint256 forCom,
            uint256 forFounders
        )
    {
        uint256 multiplier = getAccumulatedMultiplier(from_, to_);
        uint256 amountBeforeDivide = rewardPerBlock * multiplier * poolInfo[poolId_].allocPoints;
        uint256 amount = amountBeforeDivide / totalAllocPoints / 10;

        uint256 govTokenCanMint = govToken.lpRewardsCap() - govToken.totalLPRewardsSupply();

        if (govTokenCanMint < amount) {
            forDev = 0;
            forFarmer = govTokenCanMint;
            forLP = 0;
            forCom = 0;
            forFounders = 0;
        } else {
            forDev = (amountBeforeDivide * percentDev) / totalAllocPoints / 1000;
            forFarmer = amount;
            forLP = (amountBeforeDivide * percentLP) / totalAllocPoints / 1000;
            forCom = (amountBeforeDivide * percentCom) / totalAllocPoints / 1000;
            forFounders = (amountBeforeDivide * percentFounder) / totalAllocPoints / 1000;
        }
    }

    /**
     * @notice Returns pool rewards generated by a pool's booster in a given timeframe
     * @param poolId_       ID of the pool to generate the Boosted rewards of
     * @param user_         Address to generate the Boosted rewards of
     * @param from_         Lower limit of the timeframe to consider
     * @param to_           Upper limit of the timeframe to consider
     */
    function getBoostAmount(
        uint256 poolId_,
        address user_,
        uint256 from_,
        uint256 to_
    ) public view returns (uint256) {
        Boost memory boost_ = _boosts[user_][poolId_]; //  Retrieve Boost.

        if (boost_.boostEndBlock < from_) return 0;

        PoolInfo memory pool_ = poolInfo[poolId_];
        UserInfo memory userInfo_ = userInfo[poolId_][user_];

        uint256 start = from_;
        uint256 end = to_;

        if (boost_.boostStartBlock > from_) start = boost_.boostStartBlock;
        if (boost_.boostEndBlock < to_) end = boost_.boostEndBlock;

        //  Getting the accumulated multiplier in the timeframe where Boost was active
        uint256 multiplier = getAccumulatedMultiplier(start, end);

        //  Pool rewards emitted for a specific user during the timeframe where
        //  the Boost was active.
        uint256 poolRewardsForBoostUserDuringBoost = (rewardPerBlock *
            multiplier *
            pool_.allocPoints *
            userInfo_.amount) /
            totalAllocPoints /
            pool_.lpToken.balanceOf(address(this)) /
            10;

        uint256 poolRewardsForBoostUserIncludingBoost = (rewardPerBlock *
            multiplier *
            pool_.allocPoints *
            userInfo_.amount *
            boost_.boostMultiplier) /
            totalAllocPoints /
            pool_.lpToken.balanceOf(address(this)) /
            100;

        //  The Pool Rewards for the Boost user during Boost
        //  *times* the boost multiplier
        //  *minus* the Pool Rewards for the Boost user during Boost.
        //  This gives us the amount of rewards produced **only** by the Boost.
        uint256 boostedRewards = poolRewardsForBoostUserIncludingBoost - poolRewardsForBoostUserDuringBoost;

        //  The amount of Boosted LP Rewards available to mint.
        uint256 boostedRewardsCanMint = govToken.boostedLPRewardsCap() - govToken.totalBoostedLPRewardsSupply();

        if (boostedRewardsCanMint == 0) {
            //  If there are no more available boosted lp rewards to mint.
            return 0;
        } else if (boostedRewardsCanMint < boostedRewards) {
            //  If there are Boosted rewards available to mint
            //  but they are less than the booster generated rewards.
            return boostedRewardsCanMint;
        }

        return boostedRewards;
    }

    /**
     * @notice If a boost is active for the given pool and user at this block.
     * @param poolId_   ID of the pool to verify the boost of
     * @param user_     User to verify the boost of
     */
    function isBoostActiveForUser(address user_, uint256 poolId_) public view returns (bool) {
        return block.number < _boosts[user_][poolId_].boostEndBlock;
    }

    /**
     * @notice Returns the active Boost for the given user and pool
     * @param user_     Address of the user to get the active boost of
     * @param poolId_   ID of the pool to get the active boost of
     */
    function getBoost(address user_, uint256 poolId_) public view returns (Boost memory) {
        return _boosts[user_][poolId_];
    }

    /**
     * @notice Returns the pending reward to be claimed from the pool with given pool ID by the user,
     * as well as the pending rewards from the applied boost, if the user has activated a boost.
     * @param poolId_   ID of the pool to calculate the pending rewards of
     * @param user_     User to calculate the pending rewards of
     */
    function pendingReward(uint256 poolId_, address user_) public view returns (uint256, uint256) {
        PoolInfo memory pool_ = poolInfo[poolId_];
        UserInfo memory userInfo_ = userInfo[poolId_][user_];
        uint256 accGovTokenPerShare = pool_.accGovTokenPerShare;
        uint256 lpSupply = pool_.lpToken.balanceOf(address(this));

        if (block.number > pool_.lastRewardBlock && lpSupply > 0) {
            (, uint256 govTokenForFarmer, , , ) = getPoolReward(poolId_, pool_.lastRewardBlock, block.number);

            accGovTokenPerShare += (govTokenForFarmer * 1e12) / lpSupply;
        }

        return (
            (userInfo_.amount * accGovTokenPerShare) / 1e12 - userInfo_.rewardDebt,
            getBoostAmount(poolId_, user_, _boosts[user_][poolId_].lastBoostedRewardBlock, block.number)
        );
    }

    /**
     * @notice Getter for the current reward per block, taking the multiplier into account.
     * @param poolId_   ID of the pool to calculate the reward per block of
     */
    function getNewRewardPerBlock(uint256 poolId_) public view returns (uint256) {
        uint256 multiplier = getAccumulatedMultiplier(block.number, block.number + 1);

        if (poolId_ == 0) return (multiplier * rewardPerBlock) / 10;
        else {
            return ((multiplier * rewardPerBlock * poolInfo[poolId_ - 1].allocPoints) / totalAllocPoints) / 10;
        }
    }

    /**
     * @notice Returns the user delta. This is used when calculating withdrawal fees.
     * @dev If the user has made a withdrawal, the delta is the time passed since the last withdrawal.
     * Else, the delta is the blocks passed since the user's first deposit.
     * @param poolId_   ID of the pool to calculate the user's delta of
     */
    function userDelta(uint256 poolId_) public view returns (uint256) {
        UserInfo memory user_ = userInfo[poolId_][msg.sender];

        if (user_.lastWithdrawBlock > 0) return block.number - user_.lastWithdrawBlock;
        else return block.number - user_.firstDepositBlock;
    }

    /**
     * @notice Getter for the length of the 'poolInfo' array.
     */
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    //
    // Authorized API
    //

    /**
     * @notice Updates the base reward per block.
     */
    function setRewardPerBlock(uint256 rewardPerBlock_) public onlyAuthorized {
        rewardPerBlock = rewardPerBlock_;
        emit SetRewardPerBlock(rewardPerBlock_);
    }

    /**
     * @notice Updates the reward multiplier array.
     */
    function setRewardMultiplier(uint256[] memory rewardMultiplier_) public onlyAuthorized {
        rewardMultiplier = rewardMultiplier_;
    }

    /**
     * @notice Updates the finish reward block.
     */
    function setFinishRewardBlock(uint256 finishRewardBlock_) public onlyAuthorized {
        finishRewardBlock = finishRewardBlock_;
        emit SetFinishRewardBlock(finishRewardBlock_);
    }

    /**
     * @notice Updates the halving at block array.
     */
    function setHalvingAtBlock(uint256[] memory halvingAtBlock_) public onlyAuthorized {
        halvingAtBlock = halvingAtBlock_;
    }

    /**
     * @notice Updates the developer address.
     */
    function setDevAddr(address devAddr_) public onlyAuthorized {
        require(devAddr_ != address(0), "Developer address cannot be address zero");
        devAddr = devAddr_;
    }

    /**
     * @notice Updates the liquidity address.
     */
    function setLiquidityAddr(address liquidityAddr_) public onlyAuthorized {
        require(liquidityAddr_ != address(0), "Liquidity address cannot be address zero");
        liquidityAddr = liquidityAddr_;
    }

    /**
     * @notice Updates the community fund address.
     */
    function setComFundAddr(address comFundAddr_) public onlyAuthorized {
        require(comFundAddr_ != address(0), "Community Fund address cannot be address zero");
        comFundAddr = comFundAddr_;
    }

    /**
     * @notice Updates the founder address.
     */
    function setFounderAddr(address founderAddr_) public onlyAuthorized {
        require(founderAddr_ != address(0), "Founder address cannot be address zero");
        founderAddr = founderAddr_;
    }

    /**
     * @notice Updates the withdrawal fee stage array.
     */
    function setWithdrawalFeeStage(uint256[] memory withdrawalFeeStage_) public onlyAuthorized {
        withdrawalFeeStage = withdrawalFeeStage_;
    }

    /**
     * @notice Updates the user fee stage array.
     */
    function setUserFeeStage(uint256[] memory userFeeStage_) public onlyAuthorized {
        userFeeStage = userFeeStage_;
    }

    /**
     * @notice Updates the developer fee stage array.
     */
    function setDevFeeStage(uint256[] memory devFeeStage_) public onlyAuthorized {
        devFeeStage = devFeeStage_;
    }

    /**
     * @notice Updates the percent lock reward array.
     */
    function setPercentLockReward(uint256[] memory percentLockReward_) public onlyAuthorized {
        percentLockReward = percentLockReward_;
    }

    /**
     * @notice Updates the developer reward percentage.
     */
    function setPercentDev(uint64 percentDev_) public onlyAuthorized {
        percentDev = percentDev_;
        emit SetPercentDev(percentDev_);
    }

    /**
     * @notice Updates the LP reward percentage.
     */
    function setPercentLP(uint64 percentLP_) public onlyAuthorized {
        percentLP = percentLP_;
        emit SetPercentLP(percentLP_);
    }

    /**
     * @notice Updates the community's rewards percentage.
     */
    function setPercentCom(uint64 percentCom_) public onlyAuthorized {
        percentCom = percentCom_;
        emit SetPercentCom(percentCom_);
    }

    /**
     * @notice Updates the founder's rewards percentage.
     */
    function setPercentFounder(uint64 percentFounder_) public onlyAuthorized {
        percentFounder = percentFounder_;
        emit SetPercentFounder(percentFounder_);
    }

    /**
     * @notice Updates the block at which reward emissions begin.
     */
    function setStartBlock(uint256 startBlock_) public onlyAuthorized {
        startBlock = startBlock_;
        emit SetStartBlock(startBlock_);
    }

    /**
     * @notice Updates the users deposit fee.
     */
    function setUserDepFee(uint256 userDepFee_) public onlyAuthorized {
        userDepFee = userDepFee_;
    }

    function setDevDepFee(uint256 devDepFee_) public onlyAuthorized {
        devDepFee = devDepFee_;
    }

    /**
     * @notice Force sets the last withdraw block of a user to an arbitrary block.
     * @dev Implemented for safety measures.
     * @param poolId_   ID of the pool to update the last withdraw block of
     * @param user_     User to update the last withdraw block of
     * @param block_    New block to set as the last withdraw block
     */
    function reviseWithdraw(
        uint256 poolId_,
        address user_,
        uint256 block_
    ) public onlyAuthorized {
        userInfo[poolId_][user_].lastWithdrawBlock = block_;
    }

    /**
     * @notice Force sets the first deposit block of a user to an arbitrary block.
     * @dev Implemented for safety measures.
     * @param poolId_   ID of the pool to update the first deposit block of
     * @param user_     User to update the first deposit block of
     * @param block_    New block to set as the first deposit block
     */
    function reviseDeposit(
        uint256 poolId_,
        address user_,
        uint256 block_
    ) public onlyAuthorized {
        userInfo[poolId_][user_].firstDepositBlock = block_;
    }

    /**
     * @notice Adds an authorized address to the 'DefimonsToken' contract if this contract is the owner.
     */
    function govTokenAddAuthorized(address authorized_) public onlyAuthorized {
        govToken.addAuthorized(authorized_);
    }

    /**
     * @notice Removes an authorized address from the 'DefimonsToken' contract if this contract is the owner.
     */
    function govTokenRemoveAuthorized(address toRemove_) public onlyAuthorized {
        govToken.removeAuthorized(toRemove_);
    }

    /**
     * @notice Transfers ownership of the Reward Token contract to a new address if this contract is the owner.
     * @param owner_    The address to transfer the ownership to
     */
    function reclaimOwnership(address owner_) public onlyAuthorized {
        govToken.transferOwnership(owner_);
    }

    /**
     * @notice Transfer the wanted amount of reward tokens out of this contract.
     * @dev Implemented for safety measures.
     * @param to_       The address to send the tokens to
     * @param amount_   The amount of tokens to transfer
     */
    function safeGovTokenTransfer(address to_, uint256 amount_) public onlyAuthorized {
        uint256 govTokenBal = govToken.balanceOf(address(this));
        bool transferSuccess = false;

        if (amount_ > govTokenBal) transferSuccess = govToken.transfer(to_, govTokenBal);
        else transferSuccess = govToken.transfer(to_, amount_);

        require(transferSuccess, "MasterHunter::safeGovTokenTransfer: Transfer failed");
    }

    //
    // Internal API
    //

    /**
     * @notice Harvests all of the user's pending rewards including rewards generated by Booster Packs.
     * @dev This function is only called after the 'updatePool()' function, so the rewards are always calculated
     * with the latest update.
     * @param poolId_   The pool to harvest the rewards from
     */
    function _harvest(uint256 poolId_) internal {
        PoolInfo memory pool_ = poolInfo[poolId_];
        UserInfo storage user = userInfo[poolId_][msg.sender];
        UserInfo memory user_ = userInfo[poolId_][msg.sender];

        //  Only harvest if the user has staked LP Tokens for this pool
        if (user_.amount > 0) {
            // Calculate the pending reward
            uint256 pending = ((user_.amount * pool_.accGovTokenPerShare) / 1e12) - user_.rewardDebt;

            uint256 pendingFromBoost = getBoostAmount(
                poolId_,
                msg.sender,
                _boosts[msg.sender][poolId_].lastBoostedRewardBlock,
                block.number
            );

            if (pendingFromBoost > 0) {
                emit SendBoostedRewards(msg.sender, poolId_, pendingFromBoost);
                _boosts[msg.sender][poolId_].lastBoostedRewardBlock = block.number;
                govToken.mintBoostedLPRewards(msg.sender, pendingFromBoost);
            }

            //  Make sure we aren't giving more tokens than we have
            uint256 masterBal = govToken.balanceOf(address(this));

            if (pending > masterBal) pending = masterBal;

            if (pending > 0) {
                //  If the user has a positive pending reward balance,
                //  transfer them to their wallet.
                bool success = govToken.transfer(msg.sender, pending);
                require(success, "MasterHunter::_harvest: Governance token transfer failed");

                //  Lock conditions
                uint256 lockAmount = 0;
                if (user_.rewardDebtAtBlock <= finishRewardBlock) {
                    //  If we are before or in finishRewardBlock, we need to lock some
                    //  of the sent tokens based on the current lock percentage.
                    //
                    //  Because Epochs are structured like so: [start, end[
                    //  the block rewards are only emitted at the end of each block.
                    //  This is why we measure lock percentage from [block.number - 1, block.number].
                    uint256 lockPercentage = getLockPercentage(block.number - 1, block.number);
                    uint256 total = pending + pendingFromBoost;
                    lockAmount = (total * lockPercentage) / 100;
                    govToken.lock(msg.sender, lockAmount);
                }

                //  Reset the rewardDebtAtBlock to the current block for the user
                user.rewardDebtAtBlock = block.number;

                emit SendGovernanceTokenReward(msg.sender, poolId_, pending, lockAmount);
            }

            //  Recalculate the rewardDebt for the user.
            user.rewardDebt = (user_.amount * pool_.accGovTokenPerShare) / 1e12;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { OFT } from "test/test-default/utils/Omnichain/token/oft/OFT.sol";
import { Authorizable } from "src/src-default/Authorizable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A LayerZero OmnichainFungibleToken example using OFT
 * @notice Works in tandem with a BasedOFT. Use this to contract on for all NON-BASE chains.
 * It burns tokens on send(), and mints on receive tokens from other chains.
 */
contract DefimonsToken is OFT, Authorizable {
    //
    // Constants
    //

    uint256 public constant PERCENTAGE_FOR_ICO = 25; //  TODO INPUT DEFIMONS PERCENTAGES
    uint256 public constant PERCENTAGE_FOR_MSIG = 30; //  TODO INPUT DEFIMONS PERCENTAGES
    uint256 public constant PERCENTAGE_FOR_LP_REWARDS = 30; //  TODO INPUT DEFIMONS PERCENTAGES
    uint256 public constant PERCENTAGE_FOR_BOOSTED_LP_REWARDS = 15; //  TODO INPUT DEFIMONS PERCENTAGES

    //
    // Events
    //

    event Lock(address indexed holder, uint256 amount);
    event Unlock(address indexed to, uint256 value);
    event MintedLPReward(address indexed to, uint256 amount);
    event MintedBoostedLPReward(address indexed to, uint256 amount);

    //
    // State
    //

    //  Total cap of tokens
    uint256 private _cap;
    //  Total cap of normal rewarded tokens
    uint256 private _lpRewardsCap;
    //  Total cap of boosted rewarded tokens
    uint256 private _boostedLPRewardsCap;
    //  Normal rewards supply
    uint256 private _totalLPRewardsSupply;
    //  Boosted rewards supply
    uint256 private _totalBoostedLPRewardsSupply;

    //
    //  Locking State
    //

    //  Total locked tokens
    uint256 private _totalLock;
    //  Block number when the lock starts
    uint256 public lockFromBlock;
    //  Block number when the lock ends
    uint256 public lockToBlock;
    //  Locked tokens per address
    mapping(address => uint256) private _locks;
    //  Last unlock block per address
    mapping(address => uint256) private _lastUnlockBlock;

    /**
     * @dev Constructor that sets the cap, lockFromBlock, lockToBlock, lpRewardsCap,
     * boostedLPRewardsCap and mints to the ICO and MSIG.
     * @param wallet_ The Multisig wallet address that will receive part of the initial minted tokens
     * @param ico_ The ICO address that will receive part of the initial minted tokens
     * @param cap_ The total supply cap
     * @param lockFromBlock_ The block number from which the tokens will be locked
     * @param lockToBlock_ The block number until which the tokens will be locked
     * @param name_ Name of the token
     * @param symbol_ Symbol of the token
     * @param layerZeroEndPoint_ Address of the LayerZero contract
     */
    constructor(
        address wallet_,
        address ico_,
        uint256 cap_,
        uint256 lockFromBlock_,
        uint256 lockToBlock_,
        string memory name_,
        string memory symbol_,
        address layerZeroEndPoint_
    ) OFT(name_, symbol_, layerZeroEndPoint_) {
        _cap = cap_;
        lockFromBlock = lockFromBlock_;
        lockToBlock = lockToBlock_;
        _lpRewardsCap = (cap_ * PERCENTAGE_FOR_LP_REWARDS) / 100;
        _boostedLPRewardsCap = (cap_ * PERCENTAGE_FOR_BOOSTED_LP_REWARDS) / 100;
        _mint(wallet_, (cap_ * PERCENTAGE_FOR_MSIG) / 100);
        _mint(ico_, (cap_ * PERCENTAGE_FOR_ICO) / 100);
    }

    /**
     * @dev Returns the amount of locked tokens of the specified address.
     * @param holder_ The address to query the the lock of.
     */
    function lockOf(address holder_) public view returns (uint256) {
        return _locks[holder_];
    }

    function lastUnlockBlock(address holder_) public view returns (uint256) {
        return _lastUnlockBlock[holder_];
    }

    /**
     * @dev Locks the specified amount of tokens for the specified holder.
     * @param holder_ The holder to lock tokens for
     * @param amount_ The amount of tokens to lock
     */
    function lock(address holder_, uint256 amount_) public onlyAuthorized {
        require(holder_ != address(0), "DefimonsToken: Cannot lock to zero address");
        require(amount_ <= balanceOf(holder_), "DefimonsToken: Lock amount over balance");

        _transfer(holder_, address(this), amount_);

        _locks[holder_] += amount_;
        _totalLock += amount_;

        //  If this is the holder's first lock
        if (_lastUnlockBlock[holder_] < lockFromBlock) _lastUnlockBlock[holder_] = lockFromBlock;

        emit Lock(holder_, amount_);
    }

    /**
     * @dev Unlocks the tokens of msg.sender.
     */
    function unlock() public {
        uint256 amount = canUnlockAmount(msg.sender);
        _unlock(msg.sender, amount);
    }

    /**
     * @dev Unlocks tokens.
     * Starts by unlocking any pending locked tokens that need to be unlocked.
     * Then unlocks amount_.
     * @param user_ Address to send unlocked tokens to
     * @param amount_ Amount of tokens to unlock
     */
    function unlockToUser(address user_, uint256 amount_) public onlyAuthorized {
        uint256 pendingLocked = canUnlockAmount(user_);

        if (pendingLocked > 0) _unlock(user_, pendingLocked);

        _unlock(user_, amount_);
    }

    /**
     * @dev Mints tokens. In MasterHunter mintLPReward() and mintBoostedLPReward() are used instead.
     * @param to_ Address to mint to.
     * @param amount_ Amount to mint.
     */
    function mint(address to_, uint256 amount_) public onlyOwner {
        _mint(to_, amount_);
    }

    /**
     * @dev Mints normal rewards.
     * @param to_ Address to mint to
     * @param amount_ Amount to mint
     */
    function mintLPReward(address to_, uint256 amount_) public onlyAuthorized {
        require(_totalLPRewardsSupply + amount_ <= _lpRewardsCap, "DefimonsToken: LP rewards cap exceeded");
        emit MintedLPReward(to_, amount_);
        _totalLPRewardsSupply += amount_;
        _mint(to_, amount_);
    }

    /**
     * @dev Mints boosted rewards.
     * @param to_ Address to mint to
     * @param amount_ Amount to mint
     */
    function mintBoostedLPRewards(address to_, uint256 amount_) public onlyAuthorized {
        require(
            _totalBoostedLPRewardsSupply + amount_ <= _boostedLPRewardsCap,
            "DefimonsToken: Boosted LP rewards cap exceeded"
        );
        emit MintedBoostedLPReward(to_, amount_);
        _totalBoostedLPRewardsSupply += amount_;
        _mint(to_, amount_);
    }

    /**
     * @dev Sets the cap of the token.
     * @param cap_ The new cap
     */
    function setCap(uint256 cap_) public onlyAuthorized {
        _cap = cap_;
    }

    /**
     * @dev Sets the cap normal rewards. Also sets the global cap.
     * @param lpRewardsCap_ The new cap for normal rewards
     */
    function setLPRewardsCap(uint256 lpRewardsCap_) public onlyAuthorized {
        _cap = _cap - _lpRewardsCap;
        _lpRewardsCap = lpRewardsCap_;
        _cap = _cap + lpRewardsCap_;
    }

    /**
     * @dev Sets the cap for boosted rewards. Also sets global cap.
     * @param boostedLPRewardsCap_ The new cap for boosted rewards
     */
    function setBoostedLPRewardsCap(uint256 boostedLPRewardsCap_) public onlyAuthorized {
        _cap = _cap - _boostedLPRewardsCap;
        _boostedLPRewardsCap = boostedLPRewardsCap_;
        _cap = _cap + boostedLPRewardsCap_;
    }

    /**
     * @dev Returns the amount of tokens that can be unlocked by holder_
     * @param holder_ Address of the holder
     */
    function canUnlockAmount(address holder_) public view returns (uint256) {
        if (block.number < lockFromBlock) {
            return 0;
        } else if (block.number >= lockToBlock) {
            return _locks[holder_];
        } else {
            uint256 releaseBlock = block.number - _lastUnlockBlock[holder_];
            uint256 numberLockBlock = lockToBlock - _lastUnlockBlock[holder_];
            return (_locks[holder_] * releaseBlock) / numberLockBlock;
        }
    }

    /**
     * @dev Returns the cap of tokens.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the cap for normal token rewards. This cap is for MasterHunter LP Rewards.
     */
    function lpRewardsCap() public view returns (uint256) {
        return _lpRewardsCap;
    }

    /**
     * @dev Returns the cap for boosted token rewards. This cap is for MasterHunter Boosted LP Rewards.
     */
    function boostedLPRewardsCap() public view returns (uint256) {
        return _boostedLPRewardsCap;
    }

    /**
     * @dev Returns the total supply of normal token rewards.
     */
    function totalLPRewardsSupply() public view returns (uint256) {
        return _totalLPRewardsSupply;
    }

    /**
     * @dev Returns the total supply of token boost rewards.
     */
    function totalBoostedLPRewardsSupply() public view returns (uint256) {
        return _totalBoostedLPRewardsSupply;
    }

    /**
     * @dev Updates the lockFromBlock.
     * @param newLockFrom_ The new lockFromBlock
     */
    function lockFromUpdate(uint256 newLockFrom_) public onlyAuthorized {
        lockFromBlock = newLockFrom_;
    }

    /**
     * @dev Updates the lockToBlock.
     * @param newLockTo_ The new lockToBlock
     */
    function lockToUpdate(uint256 newLockTo_) public onlyAuthorized {
        lockToBlock = newLockTo_;
    }

    /**
     * @dev Returns the total amount of unlocked tokens.
     */
    function unlockedSupply() public view returns (uint256) {
        return totalSupply() - _totalLock;
    }

    /**
     * @dev Returns the total locked amount of tokens.
     */
    function totalLock() public view returns (uint256) {
        return _totalLock;
    }

    /**
     * @dev Unlocks amount_ of tokens to holder_.
     * @param holder_ Address of the holder
     * @param amount_ Amount of tokens to unlock
     */
    function _unlock(address holder_, uint256 amount_) internal {
        require(_locks[holder_] > 0, "DefimonsToken: Insufficeint locked tokens");

        if (amount_ > _locks[holder_]) amount_ = _locks[holder_];

        if (amount_ > balanceOf(address(this))) amount_ = balanceOf(address(this));

        _transfer(address(this), holder_, amount_);

        _locks[holder_] -= amount_;
        _lastUnlockBlock[holder_] = block.number;
        _totalLock -= amount_;

        emit Unlock(holder_, amount_);
    }

    /**
     * @dev Overrides _beforeTokenTransfer to enable Omnichain interactions.
     * @param from_     The address that is transferring tokens
     * @param to_       The address that is receiving tokens
     * @param amount_   The amount of tokens being transferred
     */
    function _beforeTokenTransfer(
        // solhint-disable-next-line no-unused-vars
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual override {
        if (to_ == address(0)) {
            _cap -= amount_;
        }
        if (from_ == address(0)) {
            require(
                totalSupply() + amount_ <= _cap, 
                "DefimonsToken: Mint surpasses supply cap"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint256)) public minDstGasLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint256 _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        lzEndpoint.send{ value: _nativeFee }(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function _checkGasLimit(
        uint16 _dstChainId,
        uint16 _type,
        bytes memory _adapterParams,
        uint256 _extraGas
    ) internal view virtual {
        uint256 providedGasLimit = _getGasLimit(_adapterParams);
        uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint256 gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(
        uint16 _dstChainId,
        uint16 _packetType,
        uint256 _minGas
    ) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        // try-catch all errors/exceptions
        if (!success) {
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IOFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint256);

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes indexed _toAddress, uint256 _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, bytes _fromAddress, address indexed _to, uint256 _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IOFT.sol";
import "./OFTCore.sol";

// override decimal() function is needed
contract OFT is OFTCore, ERC20, IOFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint
    ) ERC20(_name, _symbol) OFTCore(_lzEndpoint) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(OFTCore, IERC165) returns (bool) {
        return
            interfaceId == type(IOFT).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function circulatingSupply() public view virtual override returns (uint256) {
        return totalSupply();
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _amount
    ) internal virtual override {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _amount
    ) internal virtual override {
        _mint(_toAddress, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../lzApp/NonblockingLzApp.sol";
import "./IOFTCore.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract OFTCore is NonblockingLzApp, ERC165, IOFTCore {
    using BytesLib for bytes;

    uint256 public constant NO_EXTRA_GAS = 0;

    // packet type
    uint16 public constant PT_SEND = 0;

    bool public useCustomAdapterParams;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOFTCore).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
        // mock the payload for sendFrom()
        bytes memory payload = abi.encode(PT_SEND, abi.encodePacked(msg.sender), _toAddress, _amount);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _amount, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) public virtual onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        uint16 packetType;
        assembly {
            packetType := mload(add(_payload, 32))
        }

        if (packetType == PT_SEND) {
            _sendAck(_srcChainId, _srcAddress, _nonce, _payload);
        } else {
            revert("OFTCore: unknown packet type");
        }
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        _checkAdapterParams(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory lzPayload = abi.encode(PT_SEND, abi.encodePacked(_from), _toAddress, _amount);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit SendToChain(_dstChainId, _from, _toAddress, _amount);
    }

    function _sendAck(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal virtual {
        (, bytes memory from, bytes memory toAddressBytes, uint256 amount) = abi.decode(
            _payload,
            (uint16, bytes, bytes, uint256)
        );

        address to = toAddressBytes.toAddress(0);

        _creditTo(_srcChainId, to, amount);
        emit ReceiveFromChain(_srcChainId, from, to, amount);
    }

    function _checkAdapterParams(
        uint16 _dstChainId,
        uint16 _pkType,
        bytes memory _adapterParams,
        uint256 _extraGas
    ) internal virtual {
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, _pkType, _adapterParams, _extraGas);
        } else {
            require(_adapterParams.length == 0, "OFTCore: _adapterParams must be empty.");
        }
    }

    function _debitFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount
    ) internal virtual;

    function _creditTo(
        uint16 _srcChainId,
        address _toAddress,
        uint256 _amount
    ) internal virtual;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}