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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../library/sealable/v1/Sealable.sol";
import "../library/random/v1/OnChainRandom.sol";
import "./IFPXEmoji.sol";
import "../library/opensea-operatorfilter/v1/FlexibleOperatorFilterer.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.17;

/**
 * @title FPXEmoji
 * @author BaseLabs
 */
contract FPXEmoji is
    ERC1155,
    IFPXEmoji,
    Pausable,
    OnChainRandom,
    ReentrancyGuard,
    Ownable,
    Sealable,
    FlexibleOperatorFilterer
{
    string public constant name = "FPX FLY x Cheers UP Emoji";
    string public constant symbol = "FPXCUPEMOJI";
    mapping(uint256 => Formula) private _formulas;
    mapping(uint256 => Uint256Pair[]) private _airdropPlans;
    mapping(uint256 => string) public tokenURIs;

    constructor() ERC1155("") {}

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice airdrop method handles the airdrop process for a specified airdrop plan. The
     * airdrop plan specifies the number of each type of token to be airdropped.
     * The function receives an array of addresses and an array of numbers, where
     * each number in the array represents the number of tokens to be airdropped to
     * the corresponding address in the addresses array.
     * @param airdropId_ The ID of the airdrop plan to be used for the airdrop.
     * @param addresses_ The array of addresses to receive the airdrop.
     * @param nums_ The array of numbers, where each number represents the number
     *              of tokens to be airdropped to the corresponding address.
     */
    function airdrop(
        uint256 airdropId_,
        address[] calldata addresses_,
        uint256[] calldata nums_
    ) external onlyOwner onlyNotSealed nonReentrant {
        Uint256Pair[] memory airdropPlan = _airdropPlans[airdropId_];
        uint256 planSize = airdropPlan.length;
        if (planSize == 0) revert ErrInvalidAirdropPlan();
        uint256 totalSize = 0;
        for (uint256 i = 0; i < planSize; ++i) {
            totalSize += airdropPlan[i].value;
        }
        for (uint256 i = 0; i < addresses_.length; ++i) {
            address account = addresses_[i];
            uint256 num = nums_[i];
            for (uint256 j = 0; j < num; ++j) {
                uint256 entropy = _unsafeRandom() % totalSize;
                uint256 step = 0;
                bool minted = false;
                for (uint256 k = 0; k < planSize; ++k) {
                    step += airdropPlan[k].value;
                    if (entropy < step) {
                        airdropPlan[k].value--;
                        totalSize--;
                        _mint(account, airdropPlan[k].key, 1, "");
                        minted = true;
                        break;
                    }
                }
                if (!minted) revert ErrUnreachableCode();
            }
        }
        _overwriteAirdropPlan(airdropId_, airdropPlan);
    }

    /**
     * @notice The merge function merges the given formula and burns its input tokens.
     * It then generates a new token using the output of the formula and mints it
     * to the caller of the function.
     * @param formulaId_ The ID of the formula to be used for the merge.
     * @dev The onlyEOA and nonReentrant modifiers are used to restrict the
     * caller to external accounts and to prevent reentrancy, respectively.
     */
    function merge(uint256 formulaId_) external onlyEOA nonReentrant {
        (Formula memory formula, bool valid) = getFormula(formulaId_);
        if (!valid) revert ErrFormulaIsInvalid();
        for (uint256 i = 0; i < formula.input.length; ++i) {
            _burn(msg.sender, formula.input[i].key, formula.input[i].value);
        }
        uint256 tokenId = _dice(formula.output);
        _mint(msg.sender, tokenId, 1, "");
        emit Rerolled(msg.sender, formulaId_, tokenId);
    }

    /**
     * @notice Burn a batch of tokens from an account.
     * @param account_ The address of the account from which the tokens will be burned.
     * @param ids_ The IDs of the tokens to burn.
     * @param values_ The numbers of the tokens to burn.
     */
    function burnBatch(
        address account_,
        uint256[] memory ids_,
        uint256[] memory values_
    ) external {
        if (account_ != msg.sender && !isApprovedForAll(account_, msg.sender))
            revert ErrNotPermitted();
        _burnBatch(account_, ids_, values_);
    }

    /**
     * @notice _dice is used to select a key from a list of key-value pairs with
     * probabilities proportional to their values.
     * @param pairs_ The list of key-value pairs.
     * @return The selected key.
     */
    function _dice(Uint256Pair[] memory pairs_) internal returns (uint256) {
        unchecked {
            if (pairs_.length == 1) {
                return pairs_[0].key;
            }
            uint256 totalSize = 0;
            for (uint256 i = 0; i < pairs_.length; ++i) {
                totalSize += pairs_[i].value;
            }
            uint256 entropy = _unsafeRandom() % totalSize;
            uint256 step = 0;
            for (uint256 i = 0; i < pairs_.length; ++i) {
                step += pairs_[i].value;
                if (entropy < step) {
                    return pairs_[i].key;
                }
            }
            revert ErrUnreachableCode();
        }
    }

    /***********************************|
    |              Admin                |
    |__________________________________*/

    /**
     * @notice mint is used to mints multiple tokens at once
     * @param addresses_ the addresses to which the tokens will be minted
     * @param tokenIds_ the token IDs of the tokens to be minted
     * @param nums_ the number of tokens to be minted
     */
    function mint(
        address[] calldata addresses_,
        uint256[] calldata tokenIds_,
        uint256[] calldata nums_
    ) external onlyOwner onlyNotSealed nonReentrant {
        if (
            addresses_.length == 0 ||
            addresses_.length != tokenIds_.length ||
            addresses_.length != nums_.length
        ) revert ErrInvalidArguments();
        for (uint256 i = 0; i < addresses_.length; ++i) {
            _mint(addresses_[i], tokenIds_[i], nums_[i], "");
        }
    }

    /**
     * @notice setTokenURI is used to set the URI for a given token ID.
     * @param tokenIds_ The IDs of the tokens to set the URI for.
     * @param tokenURIs_ The URI values to set for the token IDs.
     */
    function setTokenURI(
        uint256[] calldata tokenIds_,
        string[] calldata tokenURIs_
    ) external onlyOwner onlyNotSealed {
        if ((tokenIds_.length == 0) || (tokenIds_.length != tokenURIs_.length))
            revert ErrInvalidArguments();
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            uint256 tokenId = tokenIds_[i];
            string memory tokenURI = tokenURIs_[i];
            tokenURIs[tokenId] = tokenURI;
            emit URI(tokenURI, tokenId);
        }
    }

    /**
     * @notice setFormula is used to sets the formula with the given ID.
     * @param formulaId_ ID of the formula to set.
     * @param formula_ Formula to set.
     * @param overwrite_ Flag to indicate if the formula should be overwritten if it already exists.
     */
    function setFormula(
        uint256 formulaId_,
        Formula calldata formula_,
        bool overwrite_
    ) external onlyOwner onlyNotSealed {
        if (!overwrite_) {
            if (_formulas[formulaId_].input.length != 0)
                revert ErrFormulaAlreadyExists();
        }
        if (formula_.output.length == 0 || formula_.input.length == 0)
            revert ErrInvalidArguments();
        _formulas[formulaId_] = formula_;
        emit FormulaUpdated(formulaId_);
    }

    /**
     * @notice setAirdropPlan is used to set an airdrop plan for the given airdrop ID.
     * If `overwrite` is set to true, the existing plan for the given ID will be overwritten.
     * If the given plan is empty or a plan already exists for the given ID and `overwrite` is not set to true, the function will revert.
     *
     * @param airdropId_ The ID of the airdrop for which to set the plan.
     * @param plan_ The airdrop plan to set.
     * @param overwrite_ Whether to overwrite an existing plan for the given airdrop ID.
     */
    function setAirdropPlan(
        uint256 airdropId_,
        Uint256Pair[] calldata plan_,
        bool overwrite_
    ) external onlyOwner onlyNotSealed {
        if (overwrite_) {
            _overwriteAirdropPlan(airdropId_, plan_);
            return;
        }
        if (_airdropPlans[airdropId_].length != 0)
            revert ErrAirdropPlanAlreadyExists();
        if (plan_.length == 0) revert ErrInvalidAirdropPlan();
        Uint256Pair[] storage airdropPlan = _airdropPlans[airdropId_];
        for (uint256 i = 0; i < plan_.length; ++i) {
            airdropPlan.push(plan_[i]);
        }
        emit AirdropPlanUpdated(airdropId_);
    }

    /**
     * @notice _overwriteAirdropPlan is used to overwrite the existing airdrop plan.
     * @param airdropId_ The ID of the airdrop.
     * @param plan_ The new airdrop plan to be set.
     */
    function _overwriteAirdropPlan(
        uint256 airdropId_,
        Uint256Pair[] memory plan_
    ) internal {
        if (_airdropPlans[airdropId_].length != plan_.length)
            revert ErrInvalidArguments();
        for (uint256 i = 0; i < plan_.length; ++i) {
            _airdropPlans[airdropId_][i] = plan_[i];
        }
        emit AirdropPlanUpdated(airdropId_);
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner onlyNotSealed {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner onlyNotSealed {
        _unpause();
    }

    /**
     * @notice sealContract is used to seal the contract.
     */
    function sealContract() external onlyOwner onlyNotSealed {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |             Getters               |
    |__________________________________*/

    /**
     * @notice uri is used to get the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @return metadata uri corresponding to the token
     */
    function uri(
        uint256 tokenId_
    ) public view virtual override(ERC1155, IFPXEmoji) returns (string memory) {
        return tokenURIs[tokenId_];
    }

    /**
     * @notice isFormulaValid is used to check if a formula is valid.
     * @param formula_ The formula to be checked.
     * @return This function returns true if the formula is valid, otherwise it returns false.
     */
    function isFormulaValid(
        Formula memory formula_
    ) public view returns (bool) {
        if (formula_.input.length == 0 || formula_.output.length == 0) {
            return false;
        }
        if (formula_.endTime > 0 && block.timestamp > formula_.endTime) {
            return false;
        }
        return formula_.startTime > 0 && block.timestamp > formula_.startTime;
    }

    /**
     * @notice getFormula is used to get a formula.
     * @param formulaId_ The ID of the formula.
     * @return formula_ the formula.
     * @return valid_ a bool indicating whether the formula is valid.
     */
    function getFormula(
        uint256 formulaId_
    ) public view returns (Formula memory formula_, bool valid_) {
        formula_ = _formulas[formulaId_];
        valid_ = isFormulaValid(formula_);
    }

    /**
     * @notice getAirdropPlan is used to get an airdrop plan.
     * @param airdropId_ The ID of the airdrop.
     * @return This function returns the airdrop plan.
     */
    function getAirdropPlan(
        uint256 airdropId_
    ) external view returns (Uint256Pair[] memory) {
        return _airdropPlans[airdropId_];
    }

    /**
     * @notice supportsInterface is used to check if an interface is supported by this contract.
     * @param interfaceId The interface ID to be checked.
     * @return This function returns true if the interface is supported, otherwise it returns false.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC165.supportsInterface(interfaceId);
    }

    /**
     * @notice _beforeTokenTransfer is used to perform actions before a token transfer.
     * @param operator The address of the operator calling this function.
     * @param from The address of the account sending the tokens.
     * @param to The address of the account receiving the tokens.
     * @param ids The IDs of the tokens being transferred.
     * @param amounts The amounts of the tokens being transferred.
     * @param data Additional data provided with the transfer.
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
        if (paused()) revert ErrContractPaused();
    }

    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert ErrOnlyEOA();
        _;
    }

    /***********************************|
    |     Operator Filter Registry      |
    |__________________________________*/

    /**
     * @notice setApprovalForAll is used to set an operator's approval for all token transfers.
     * @param operator The address of the operator to set approval for.
     * @param approved Whether the operator is approved or not.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC1155, IERC1155) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice safeTransferFrom is used to safely transfer tokens from one account to another.
     * @param from The address of the account sending the tokens.
     * @param to The address of the account receiving the tokens.
     * @param tokenId The ID of the token being transferred.
     * @param amount The amount of the token being transferred.
     * @param data Additional data provided with the transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155, IERC1155) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @notice safeBatchTransferFrom is used to safely transfer multiple tokens from one account to another.
     * @param from The address of the account sending the tokens.
     * @param to The address of the account receiving the tokens.
     * @param ids The IDs of the tokens being transferred.
     * @param amounts The amounts of the tokens being transferred.
     * @param data Additional data provided with the transfer.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155, IERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice owner is used to get the owner address of this contract.
     * @return the address of the owner of this contract
     */
    function owner()
        public
        view
        virtual
        override(Ownable, FlexibleOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title IFPXEmoji
 * @author BaseLabs
 */
interface IFPXEmoji is IERC1155 {
    error ErrOnlyEOA();
    error ErrUnreachableCode();
    error ErrNotPermitted();
    error ErrContractPaused();
    error ErrFormulaAlreadyExists();
    error ErrInvalidArguments();
    error ErrFormulaIsInvalid();
    error ErrInvalidAirdropPlan();
    error ErrAirdropPlanAlreadyExists();

    event FormulaUpdated(uint256 formulaId);
    event AirdropPlanUpdated(uint256 airdropId);
    event Rerolled(
        address indexed account,
        uint256 indexed formulaId,
        uint256 indexed tokenId
    );

    struct Uint256Pair {
        uint256 key;
        uint256 value;
    }
    struct Formula {
        uint256 startTime;
        uint256 endTime;
        Uint256Pair[] input;
        Uint256Pair[] output;
    }
    struct Airdrop {
        Uint256Pair[] data;
    }

    /**
     * @notice airdrop method handles the airdrop process for a specified airdrop plan. The
     * airdrop plan specifies the number of each type of token to be airdropped.
     * The function receives an array of addresses and an array of numbers, where
     * each number in the array represents the number of tokens to be airdropped to
     * the corresponding address in the addresses array.
     * @param airdropId_ The ID of the airdrop plan to be used for the airdrop.
     * @param addresses_ The array of addresses to receive the airdrop.
     * @param nums_ The array of numbers, where each number represents the number
     *              of tokens to be airdropped to the corresponding address.
     */
    function airdrop(
        uint256 airdropId_,
        address[] calldata addresses_,
        uint256[] calldata nums_
    ) external;

    /**
     * @notice The merge function merges the given formula and burns its input tokens.
     * It then generates a new token using the output of the formula and mints it
     * to the caller of the function.
     * @param formulaId_ The ID of the formula to be used for the merge.
     * @dev The onlyEOA and nonReentrant modifiers are used to restrict the
     * caller to external accounts and to prevent reentrancy, respectively.
     */
    function merge(uint256 formulaId_) external;

    /**
     * @notice Burn a batch of tokens from an account.
     * @param account_ The address of the account from which the tokens will be burned.
     * @param ids_ The IDs of the tokens to burn.
     * @param values_ The numbers of the tokens to burn.
     */
    function burnBatch(
        address account_,
        uint256[] memory ids_,
        uint256[] memory values_
    ) external;

    /**
     * @notice mint is used to mints multiple tokens at once
     * @param addresses_ the addresses to which the tokens will be minted
     * @param tokenIds_ the token IDs of the tokens to be minted
     * @param nums_ the number of tokens to be minted
     */
    function mint(
        address[] calldata addresses_,
        uint256[] calldata tokenIds_,
        uint256[] calldata nums_
    ) external;

    /**
     * @notice setTokenURI is used to set the URI for a given token ID.
     * @param tokenIds_ The IDs of the tokens to set the URI for.
     * @param tokenURIs_ The URI values to set for the token IDs.
     */
    function setTokenURI(
        uint256[] calldata tokenIds_,
        string[] calldata tokenURIs_
    ) external;

    /**
     * @notice setFormula is used to sets the formula with the given ID.
     * @param formulaId_ ID of the formula to set.
     * @param formula_ Formula to set.
     * @param overwrite_ Flag to indicate if the formula should be overwritten if it already exists.
     */
    function setFormula(
        uint256 formulaId_,
        Formula calldata formula_,
        bool overwrite_
    ) external;

    /**
     * @notice setAirdropPlan is used to set an airdrop plan for the given airdrop ID.
     * If `overwrite` is set to true, the existing plan for the given ID will be overwritten.
     * If the given plan is empty or a plan already exists for the given ID and `overwrite` is not set to true, the function will revert.
     *
     * @param airdropId_ The ID of the airdrop for which to set the plan.
     * @param plan_ The airdrop plan to set.
     * @param overwrite_ Whether to overwrite an existing plan for the given airdrop ID.
     */
    function setAirdropPlan(
        uint256 airdropId_,
        Uint256Pair[] calldata plan_,
        bool overwrite_
    ) external;

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external;

    /**
     * @notice unpause the contract
     */
    function unpause() external;

    /**
     * @notice sealContract is used to seal the contract.
     */
    function sealContract() external;

    /**
     * @notice isFormulaValid is used to check if a formula is valid.
     * @param formula_ The formula to be checked.
     * @return This function returns true if the formula is valid, otherwise it returns false.
     */
    function isFormulaValid(
        Formula memory formula_
    ) external view returns (bool);

    /**
     * @notice getFormula is used to get a formula.
     * @param formulaId_ The ID of the formula.
     * @return formula_ the formula.
     * @return valid_ a bool indicating whether the formula is valid.
     */
    function getFormula(
        uint256 formulaId_
    ) external view returns (Formula memory formula_, bool valid_);

    /**
     * @notice getAirdropPlan is used to get an airdrop plan.
     * @param airdropId_ The ID of the airdrop.
     * @return This function returns the airdrop plan.
     */
    function getAirdropPlan(
        uint256 airdropId_
    ) external view returns (Uint256Pair[] memory);

    /**
     * @notice uri is used to get the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @return metadata uri corresponding to the token
     */
    function uri(uint256 tokenId_) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title FlexibleOperatorFilterer
 * @author BaseLabs
 */
abstract contract FlexibleOperatorFilterer is OperatorFilterer {
    error ErrOnlyOwner();

    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    bool public isOperatorFilterRegistryEnabled;
    mapping(address => bool) public operatorFilterWhitelist;

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}

    modifier onlyAllowedOperator(address from) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            isOperatorFilterRegistryEnabled &&
            !operatorFilterWhitelist[msg.sender] &&
            address(OPERATOR_FILTER_REGISTRY).code.length > 0
        ) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            isOperatorFilterRegistryEnabled &&
            !operatorFilterWhitelist[operator] &&
            address(OPERATOR_FILTER_REGISTRY).code.length > 0
        ) {
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    /**
     * @notice setOperatorFilterRegistryWhitelist is used to set the whitelist of operator filter registry.
     * @param state_ If state_ is true, OperatorFilterRegistry for this address will be disabled.
     */
    function setOperatorFilterRegistryWhitelist(
        address address_,
        bool state_
    ) external {
        if (msg.sender != owner()) {
            revert ErrOnlyOwner();
        }
        operatorFilterWhitelist[address_] = state_;
    }

    /**
     * @notice setOperatorFilterRegistryState is used to update the state of isOperatorFilterRegistryEnabled flag.
     * @param enabled_ If enabled_ is true, OperatorFilterRegistry will be enabled.
     */
    function setOperatorFilterRegistryState(bool enabled_) external {
        if (msg.sender != owner()) {
            revert ErrOnlyOwner();
        }
        isOperatorFilterRegistryEnabled = enabled_;
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title OnChainRandom
 * @author BaseLabs
 */
contract OnChainRandom {
    uint256 private _seed;

    /**
     * @notice _unsafeRandom is used to generate a random number by on-chain randomness.
     * Please note that on-chain random is potentially manipulated by miners,
     * so VRF is recommended for most security-sensitive scenarios.
     * @return randomly generated number.
     */
    function _unsafeRandom() internal returns (uint256) {
        unchecked {
            _seed++;
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - 1),
                            block.difficulty,
                            block.timestamp,
                            block.coinbase,
                            _seed,
                            tx.origin
                        )
                    )
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice define a set of error types

/**
 * @title Sealable
 * @author BaseLabs
 */
contract Sealable {
    error ErrContractSealed();
    event ContractSealed();

    /// @notice whether the contract is sealed
    bool public contractSealed;

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function _sealContract() internal {
        contractSealed = true;
        emit ContractSealed();
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier onlyNotSealed() {
        if (contractSealed) revert ErrContractSealed();
        _;
    }
}