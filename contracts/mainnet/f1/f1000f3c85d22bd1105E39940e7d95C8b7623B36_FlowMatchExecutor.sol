// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../governance/utils/IVotes.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is IVotes, ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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
    ) internal pure returns (address, RecoverError) {
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
    ) internal pure returns (address) {
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
    ) internal pure returns (address, RecoverError) {
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
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
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
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// external imports
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// internal imports
import { IFlowExchange } from "../interfaces/IFlowExchange.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { IFlowComplication } from "../interfaces/IFlowComplication.sol";

/**
@title FlowExchange
@author nneverlander. Twitter @nneverlander
@notice The main NFT exchange contract that holds state and does asset transfers
@dev This contract can be extended via 'complications' - strategies that let the exchange execute various types of orders
      like dutch auctions, reverse dutch auctions, floor price orders, private sales, etc.
*/
contract FlowExchange is IFlowExchange, ReentrancyGuard, Ownable, Pausable {
    /// @dev WETH address of a chain; set at deploy time to the WETH address of the chain that this contract is deployed to
    // solhint-disable-next-line var-name-mixedcase
    address public immutable WETH;
    /// @dev This is the address that is used to send auto sniped orders for execution on chain
    address public matchExecutor;
    /// @dev Gas cost for auto sniped orders are paid by the buyers and refunded to this contract in the form of WETH
    uint32 public wethTransferGasUnits = 5e4;
    /// @notice max weth transfer gas units
    uint32 public constant MAX_WETH_TRANSFER_GAS_UNITS = 2e5;
    /// @notice Exchange fee in basis points (250 bps = 2.5%)
    uint32 public protocolFeeBps = 250;
    /// @notice Max exchange fee in basis points (2000 bps = 20%)
    uint32 public constant MAX_PROTOCOL_FEE_BPS = 2000;

    /// @dev Used in division
    uint256 public constant PRECISION = 1e4; // precision for division; similar to bps

    /**
   @dev All orders should have a nonce >= to this value. 
        Any orders with nonce value less than this are non-executable. 
        Used for cancelling all outstanding orders.
  */
    mapping(address => uint256) public userMinOrderNonce;

    /// @dev This records already executed or cancelled orders to prevent replay attacks.
    mapping(address => mapping(uint256 => bool))
        public isUserOrderNonceExecutedOrCancelled;

    ///@notice admin events
    event ETHWithdrawn(address indexed destination, uint256 amount);
    event ERC20Withdrawn(
        address indexed destination,
        address indexed currency,
        uint256 amount
    );
    event MatchExecutorUpdated(address indexed matchExecutor);
    event WethTransferGasUnitsUpdated(uint32 wethTransferGasUnits);
    event ProtocolFeeUpdated(uint32 protocolFee);

    /// @notice user events
    event MatchOrderFulfilled(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        address indexed seller,
        address indexed buyer,
        address complication, // address of the complication that defines the execution
        address indexed currency, // token address of the transacting currency
        uint256 amount, // amount spent on the order
        OrderTypes.OrderItem[] nfts // items in the order
    );
    event TakeOrderFulfilled(
        bytes32 orderHash,
        address indexed seller,
        address indexed buyer,
        address complication, // address of the complication that defines the execution
        address indexed currency, // token address of the transacting currency
        uint256 amount, // amount spent on the order
        OrderTypes.OrderItem[] nfts // items in the order
    );
    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);

    /**
    @param _weth address of a chain; set at deploy time to the WETH address of the chain that this contract is deployed to
    @param _matchExecutor address of the match executor used by match* functions to auto execute orders 
   */
    constructor(address _weth, address _matchExecutor) {
        WETH = _weth;
        matchExecutor = _matchExecutor;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // =================================================== USER FUNCTIONS =======================================================

    /**
   @notice Matches orders one to one where each order has 1 NFT. Example: Match 1 specific NFT buy with one specific NFT sell.
   @dev Can execute orders in batches for gas efficiency. Can only be called by the match executor. Buyers refund gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
   @param makerOrders1 Maker order 1
   @param makerOrders2 Maker order 2
  */
    function matchOneToOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders1,
        OrderTypes.MakerOrder[] calldata makerOrders2
    ) external override nonReentrant whenNotPaused {
        uint256 startGas = gasleft();
        uint256 numMakerOrders = makerOrders1.length;
        require(msg.sender == matchExecutor, "only match executor");
        require(numMakerOrders == makerOrders2.length, "mismatched lengths");

        // the below 3 variables are copied locally once to save on gas
        // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
        // since these values won't change during function execution, we can save on gas by copying them locally once
        // instead of SLOADing once for each loop iteration
        uint32 _protocolFeeBps = protocolFeeBps;
        uint32 _wethTransferGasUnits = wethTransferGasUnits;
        address weth = WETH;
        uint256 sharedCost = (startGas - gasleft()) / numMakerOrders;
        for (uint256 i; i < numMakerOrders; ) {
            uint256 startGasPerOrder = gasleft() + sharedCost;
            _matchOneToOneOrders(
                makerOrders1[i],
                makerOrders2[i],
                startGasPerOrder,
                _protocolFeeBps,
                _wethTransferGasUnits,
                weth
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
   @notice Matches one order to many orders. Example: A buy order with 5 specific NFTs with 5 sell orders with those specific NFTs.
   @dev Can only be called by the match executor. Buyers refund gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
   @param makerOrder The one order to match
   @param manyMakerOrders Array of multiple orders to match the one order against
  */
    function matchOneToManyOrders(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external override nonReentrant whenNotPaused {
        uint256 startGas = gasleft();
        require(msg.sender == matchExecutor, "only match executor");

        (bool canExec, bytes32 makerOrderHash) = IFlowComplication(
            makerOrder.execParams[0]
        ).canExecMatchOneToMany(makerOrder, manyMakerOrders);
        require(canExec, "cannot execute");

        bool makerOrderExpired = isUserOrderNonceExecutedOrCancelled[
            makerOrder.signer
        ][makerOrder.constraints[5]] ||
            makerOrder.constraints[5] < userMinOrderNonce[makerOrder.signer];
        require(!makerOrderExpired, "maker order expired");

        uint256 ordersLength = manyMakerOrders.length;
        // the below 3 variables are copied locally once to save on gas
        // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
        // since these values won't change during function execution, we can save on gas by copying them locally once
        // instead of SLOADing once for each loop iteration
        uint32 _protocolFeeBps = protocolFeeBps;
        uint32 _wethTransferGasUnits = wethTransferGasUnits;
        address weth = WETH;
        if (makerOrder.isSellOrder) {
            // 20000 for the SSTORE op that updates maker nonce status from zero to a non zero status
            uint256 sharedCost = (startGas + 20000 - gasleft()) / ordersLength;
            for (uint256 i; i < ordersLength; ) {
                uint256 startGasPerOrder = gasleft() + sharedCost;
                _matchOneMakerSellToManyMakerBuys(
                    makerOrderHash,
                    makerOrder,
                    manyMakerOrders[i],
                    startGasPerOrder,
                    _protocolFeeBps,
                    _wethTransferGasUnits,
                    weth
                );
                unchecked {
                    ++i;
                }
            }
            isUserOrderNonceExecutedOrCancelled[makerOrder.signer][
                makerOrder.constraints[5]
            ] = true;
        } else {
            // check gas price constraint
            if (makerOrder.constraints[6] > 0) {
                require(
                    tx.gasprice <= makerOrder.constraints[6],
                    "gas price too high"
                );
            }
            uint256 protocolFee;
            for (uint256 i; i < ordersLength; ) {
                protocolFee =
                    protocolFee +
                    _matchOneMakerBuyToManyMakerSells(
                        makerOrderHash,
                        manyMakerOrders[i],
                        makerOrder,
                        _protocolFeeBps
                    );
                unchecked {
                    ++i;
                }
            }
            isUserOrderNonceExecutedOrCancelled[makerOrder.signer][
                makerOrder.constraints[5]
            ] = true;
            uint256 gasCost = (startGas - gasleft() + _wethTransferGasUnits) *
                tx.gasprice;
            // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
            // else we need to send the protocol fee separately in the execution currency
            // since the buyer is common across many sell orders, this part can be executed outside the above for loop
            // in contrast to the case where if the one order is a sell order, we need to do this in each for loop
            if (makerOrder.execParams[1] == weth) {
                IERC20(weth).transferFrom(
                    makerOrder.signer,
                    address(this),
                    protocolFee + gasCost
                );
            } else {
                IERC20(makerOrder.execParams[1]).transferFrom(
                    makerOrder.signer,
                    address(this),
                    protocolFee
                );
                IERC20(weth).transferFrom(
                    makerOrder.signer,
                    address(this),
                    gasCost
                );
            }
        }
    }

    /**
   @notice Matches orders one to one where no specific NFTs are specified. 
          Example: A collection wide buy order with any 2 NFTs with a sell order that has any 2 NFTs from that collection.
   @dev Can only be called by the match executor. Buyers refund gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
        The constructs param specifies the actual NFTs that will be executed since buys and sells need not specify actual NFTs - only 
        a higher level intent.
   @param sells User signed sell orders
   @param buys User signed buy orders
   @param constructs Intersection of the NFTs in the sells and buys. Constructed by an off chain matching engine.
  */
    function matchOrders(
        OrderTypes.MakerOrder[] calldata sells,
        OrderTypes.MakerOrder[] calldata buys,
        OrderTypes.OrderItem[][] calldata constructs
    ) external override nonReentrant whenNotPaused {
        uint256 startGas = gasleft();
        uint256 numSells = sells.length;
        require(msg.sender == matchExecutor, "only match executor");
        require(numSells == buys.length, "mismatched lengths");
        require(numSells == constructs.length, "mismatched lengths");
        // the below 3 variables are copied locally once to save on gas
        // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
        // since these values won't change during function execution, we can save on gas by copying them locally once
        // instead of SLOADing once for each loop iteration
        uint32 _protocolFeeBps = protocolFeeBps;
        uint32 _wethTransferGasUnits = wethTransferGasUnits;
        address weth = WETH;
        uint256 sharedCost = (startGas - gasleft()) / numSells;
        for (uint256 i; i < numSells; ) {
            uint256 startGasPerOrder = gasleft() + sharedCost;
            _matchOrders(
                sells[i],
                buys[i],
                constructs[i],
                startGasPerOrder,
                _protocolFeeBps,
                _wethTransferGasUnits,
                weth
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
   @notice Batch buys or sells orders with specific `1` NFTs. Transaction initiated by an end user.
   @param makerOrders The orders to fulfill
  */
    function takeMultipleOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders
    ) external payable override nonReentrant whenNotPaused {
        uint256 totalPrice;
        address currency = makerOrders[0].execParams[1];
        if (currency != address(0)) {
            require(msg.value == 0, "msg has value");
        }
        bool isMakerSeller = makerOrders[0].isSellOrder;
        if (!isMakerSeller) {
            require(currency != address(0), "offers only in ERC20");
        }
        for (uint256 i; i < makerOrders.length; ) {
            require(
                currency == makerOrders[i].execParams[1],
                "cannot mix currencies"
            );
            require(
                isMakerSeller == makerOrders[i].isSellOrder,
                "cannot mix order sides"
            );
            require(msg.sender != makerOrders[i].signer, "no dogfooding");

            bool orderExpired = isUserOrderNonceExecutedOrCancelled[
                makerOrders[i].signer
            ][makerOrders[i].constraints[5]] ||
                makerOrders[i].constraints[5] <
                userMinOrderNonce[makerOrders[i].signer];
            require(!orderExpired, "order expired");

            (bool canExec, bytes32 makerOrderHash) = IFlowComplication(
                makerOrders[i].execParams[0]
            ).canExecTakeOneOrder(makerOrders[i]);
            require(canExec, "cannot execute");

            uint256 execPrice = _getCurrentPrice(makerOrders[i]);
            totalPrice = totalPrice + execPrice;
            _execTakeOneOrder(
                makerOrderHash,
                makerOrders[i],
                isMakerSeller,
                execPrice
            );
            unchecked {
                ++i;
            }
        }
        // check to ensure that for ETH orders, enough ETH is sent
        // for non ETH orders, IERC20 transferFrom will throw error if insufficient amount is sent
        if (currency == address(0)) {
            require(msg.value >= totalPrice, "insufficient total price");
            if (msg.value > totalPrice) {
                (bool sent, ) = msg.sender.call{
                    value: msg.value - totalPrice
                }("");
                require(sent, "failed returning excess ETH");
            }
        }
    }

    /**
   @notice Batch buys or sells orders where maker orders can have unspecified NFTs. Transaction initiated by an end user.
   @param makerOrders The orders to fulfill
   @param takerNfts The specific NFTs that the taker is willing to take that intersect with the higher level intent of the maker
   Example: If a makerOrder is 'buy any one of these 2 specific NFTs', then the takerNfts would be 'this one specific NFT'.
  */
    function takeOrders(
        OrderTypes.MakerOrder[] calldata makerOrders,
        OrderTypes.OrderItem[][] calldata takerNfts
    ) external payable override nonReentrant whenNotPaused {
        require(makerOrders.length == takerNfts.length, "mismatched lengths");
        uint256 totalPrice;
        address currency = makerOrders[0].execParams[1];
        if (currency != address(0)) {
            require(msg.value == 0, "msg has value");
        }
        bool isMakerSeller = makerOrders[0].isSellOrder;
        if (!isMakerSeller) {
            require(currency != address(0), "offers only in ERC20");
        }
        for (uint256 i; i < makerOrders.length; ) {
            require(
                currency == makerOrders[i].execParams[1],
                "cannot mix currencies"
            );
            require(
                isMakerSeller == makerOrders[i].isSellOrder,
                "cannot mix order sides"
            );
            require(msg.sender != makerOrders[i].signer, "no dogfooding");
            uint256 execPrice = _getCurrentPrice(makerOrders[i]);
            totalPrice = totalPrice + execPrice;
            _takeOrders(makerOrders[i], takerNfts[i], execPrice);
            unchecked {
                ++i;
            }
        }
        // check to ensure that for ETH orders, enough ETH is sent
        // for non ETH orders, IERC20 transferFrom will throw error if insufficient amount is sent
        if (currency == address(0)) {
            require(msg.value >= totalPrice, "insufficient total price");
            if (msg.value > totalPrice) {
                (bool sent, ) = msg.sender.call{
                    value: msg.value - totalPrice
                }("");
                require(sent, "failed returning excess ETH");
            }
        }
    }

    /**
   @notice Helper function (non exchange related) to send multiple NFTs in one go. Only ERC721
   @param to the receiver address
   @param items the specific NFTs to transfer
  */
    function transferMultipleNFTs(
        address to,
        OrderTypes.OrderItem[] calldata items
    ) external override nonReentrant whenNotPaused {
        require(to != address(0), "invalid address");
        _transferMultipleNFTs(msg.sender, to, items);
    }

    /**
     * @notice Cancel all pending orders
     * @param minNonce minimum user nonce
     */
    function cancelAllOrders(uint256 minNonce) external override {
        require(minNonce > userMinOrderNonce[msg.sender], "nonce too low");
        require(minNonce < userMinOrderNonce[msg.sender] + 1e5, "too many");
        userMinOrderNonce[msg.sender] = minNonce;
        emit CancelAllOrders(msg.sender, minNonce);
    }

    /**
     * @notice Cancel multiple orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleOrders(
        uint256[] calldata orderNonces
    ) external override {
        require(orderNonces.length != 0, "cannot be empty");
        for (uint256 i; i < orderNonces.length; ) {
            require(
                orderNonces[i] >= userMinOrderNonce[msg.sender],
                "nonce too low"
            );
            require(
                !isUserOrderNonceExecutedOrCancelled[msg.sender][
                    orderNonces[i]
                ],
                "nonce already exec or cancelled"
            );
            isUserOrderNonceExecutedOrCancelled[msg.sender][
                orderNonces[i]
            ] = true;
            unchecked {
                ++i;
            }
        }
        emit CancelMultipleOrders(msg.sender, orderNonces);
    }

    // ====================================================== VIEW FUNCTIONS ======================================================

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param nonce nonce of the order
     * @return whether nonce is valid
     */
    function isNonceValid(
        address user,
        uint256 nonce
    ) external view override returns (bool) {
        return
            !isUserOrderNonceExecutedOrCancelled[user][nonce] &&
            nonce >= userMinOrderNonce[user];
    }

    // ====================================================== INTERNAL FUNCTIONS ================================================

    /**
     * @notice Internal helper function to match orders one to one
     * @param makerOrder1 first order
     * @param makerOrder2 second maker order
     * @param startGasPerOrder start gas when this order started execution
     * @param _protocolFeeBps exchange fee
     * @param _wethTransferGasUnits gas units that a WETH transfer will use
     * @param weth WETH address
     */
    function _matchOneToOneOrders(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2,
        uint256 startGasPerOrder,
        uint32 _protocolFeeBps,
        uint32 _wethTransferGasUnits,
        address weth
    ) internal {
        OrderTypes.MakerOrder calldata sell;
        OrderTypes.MakerOrder calldata buy;
        if (makerOrder1.isSellOrder) {
            sell = makerOrder1;
            buy = makerOrder2;
        } else {
            sell = makerOrder2;
            buy = makerOrder1;
        }

        require(
            sell.execParams[0] == buy.execParams[0],
            "complication mismatch"
        );

        (
            bool canExec,
            bytes32 sellOrderHash,
            bytes32 buyOrderHash,
            uint256 execPrice
        ) = IFlowComplication(sell.execParams[0]).canExecMatchOneToOne(
                sell,
                buy
            );

        require(canExec, "cannot execute");

        bool sellOrderExpired = isUserOrderNonceExecutedOrCancelled[
            sell.signer
        ][sell.constraints[5]] ||
            sell.constraints[5] < userMinOrderNonce[sell.signer];
        require(!sellOrderExpired, "sell order expired");

        bool buyOrderExpired = isUserOrderNonceExecutedOrCancelled[buy.signer][
            buy.constraints[5]
        ] || buy.constraints[5] < userMinOrderNonce[buy.signer];
        require(!buyOrderExpired, "buy order expired");

        _execMatchOneToOneOrders(
            sellOrderHash,
            buyOrderHash,
            sell,
            buy,
            startGasPerOrder,
            execPrice,
            _protocolFeeBps,
            _wethTransferGasUnits,
            weth
        );
    }

    /**
     * @notice Internal helper function to match one maker sell order to many maker buys
     * @param sellOrderHash sell order hash
     * @param sell the sell order
     * @param buy the buy order
     * @param startGasPerOrder start gas when this order started execution
     * @param _protocolFeeBps exchange fee
     * @param _wethTransferGasUnits gas units that a WETH transfer will use
     * @param weth WETH address
     */
    function _matchOneMakerSellToManyMakerBuys(
        bytes32 sellOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        uint256 startGasPerOrder,
        uint32 _protocolFeeBps,
        uint32 _wethTransferGasUnits,
        address weth
    ) internal {
        require(
            sell.execParams[0] == buy.execParams[0],
            "complication mismatch"
        );

        (bool verified, bytes32 buyOrderHash) = IFlowComplication(
            sell.execParams[0]
        ).verifyMatchOneToManyOrders(false, sell, buy);
        require(verified, "order not verified");

        bool buyOrderExpired = isUserOrderNonceExecutedOrCancelled[buy.signer][
            buy.constraints[5]
        ] || buy.constraints[5] < userMinOrderNonce[buy.signer];
        require(!buyOrderExpired, "buy order expired");

        _execMatchOneMakerSellToManyMakerBuys(
            sellOrderHash,
            buyOrderHash,
            sell,
            buy,
            startGasPerOrder,
            _getCurrentPrice(buy),
            _protocolFeeBps,
            _wethTransferGasUnits,
            weth
        );
    }

    /**
     * @notice Internal helper function to match one maker buy order to many maker sells
     * @param buyOrderHash buy order hash
     * @param sell the sell order
     * @param buy the buy order
     * @param _protocolFeeBps exchange fee
     */
    function _matchOneMakerBuyToManyMakerSells(
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        uint32 _protocolFeeBps
    ) internal returns (uint256) {
        require(
            sell.execParams[0] == buy.execParams[0],
            "complication mismatch"
        );

        (bool verified, bytes32 sellOrderHash) = IFlowComplication(
            sell.execParams[0]
        ).verifyMatchOneToManyOrders(true, sell, buy);
        require(verified, "order not verified");

        bool sellOrderExpired = isUserOrderNonceExecutedOrCancelled[
            sell.signer
        ][sell.constraints[5]] ||
            sell.constraints[5] < userMinOrderNonce[sell.signer];
        require(!sellOrderExpired, "sell order expired");

        return
            _execMatchOneMakerBuyToManyMakerSells(
                sellOrderHash,
                buyOrderHash,
                sell,
                buy,
                _getCurrentPrice(sell),
                _protocolFeeBps
            );
    }

    /**
   * @notice Internal helper function to match orders specified via a higher level intent
   * @param sell the sell order
   * @param buy the buy order
   * @param constructedNfts the nfts constructed by an off chain matching that are guaranteed to intersect
            with the user specified signed intents (orders)
   * @param startGasPerOrder start gas when this order started execution
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
    function _matchOrders(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts,
        uint256 startGasPerOrder,
        uint32 _protocolFeeBps,
        uint32 _wethTransferGasUnits,
        address weth
    ) internal {
        require(
            sell.execParams[0] == buy.execParams[0],
            "complication mismatch"
        );
        (
            bool executionValid,
            bytes32 sellOrderHash,
            bytes32 buyOrderHash,
            uint256 execPrice
        ) = IFlowComplication(sell.execParams[0]).canExecMatchOrder(
                sell,
                buy,
                constructedNfts
            );
        require(executionValid, "cannot execute");

        bool sellOrderExpired = isUserOrderNonceExecutedOrCancelled[
            sell.signer
        ][sell.constraints[5]] ||
            sell.constraints[5] < userMinOrderNonce[sell.signer];
        require(!sellOrderExpired, "sell order expired");

        bool buyOrderExpired = isUserOrderNonceExecutedOrCancelled[buy.signer][
            buy.constraints[5]
        ] || buy.constraints[5] < userMinOrderNonce[buy.signer];
        require(!buyOrderExpired, "buy order expired");

        _execMatchOrders(
            sellOrderHash,
            buyOrderHash,
            sell,
            buy,
            constructedNfts,
            startGasPerOrder,
            execPrice,
            _protocolFeeBps,
            _wethTransferGasUnits,
            weth
        );
    }

    /**
     * @notice Internal helper function that executes contract state changes and does asset transfers for match one to one orders
     * @dev Updates order nonce states, does asset transfers and emits events. Also refunds gas expenditure to the contract
     * @param sellOrderHash sell order hash
     * @param buyOrderHash buy order hash
     * @param sell the sell order
     * @param buy the buy order
     * @param startGasPerOrder start gas when this order started execution
     * @param execPrice execution price
     * @param _protocolFeeBps exchange fee
     * @param _wethTransferGasUnits gas units that a WETH transfer will use
     * @param weth WETH address
     */
    function _execMatchOneToOneOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        uint256 startGasPerOrder,
        uint256 execPrice,
        uint32 _protocolFeeBps,
        uint32 _wethTransferGasUnits,
        address weth
    ) internal {
        if (buy.constraints[6] > 0) {
            require(tx.gasprice <= buy.constraints[6], "gas price too high");
        }
        isUserOrderNonceExecutedOrCancelled[sell.signer][
            sell.constraints[5]
        ] = true;
        isUserOrderNonceExecutedOrCancelled[buy.signer][
            buy.constraints[5]
        ] = true;
        uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
        uint256 remainingAmount = execPrice - protocolFee;
        _transferMultipleNFTs(sell.signer, buy.signer, sell.nfts);
        // transfer final amount (post-fees) to seller
        IERC20(buy.execParams[1]).transferFrom(
            buy.signer,
            sell.signer,
            remainingAmount
        );
        _emitMatchEvent(
            sellOrderHash,
            buyOrderHash,
            sell.signer,
            buy.signer,
            buy.execParams[0],
            buy.execParams[1],
            execPrice,
            buy.nfts
        );
        uint256 gasCost = (startGasPerOrder -
            gasleft() +
            _wethTransferGasUnits) * tx.gasprice;
        // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
        // else we need to send the protocol fee separately in the execution currency
        if (buy.execParams[1] == weth) {
            IERC20(weth).transferFrom(
                buy.signer,
                address(this),
                protocolFee + gasCost
            );
        } else {
            IERC20(buy.execParams[1]).transferFrom(
                buy.signer,
                address(this),
                protocolFee
            );
            IERC20(weth).transferFrom(buy.signer, address(this), gasCost);
        }
    }

    /**
     * @notice Internal helper function that executes contract state changes and does asset transfers for match one sell to many buy orders
     * @dev Updates order nonce states, does asset transfers and emits events. Also refunds gas expenditure to the contract
     * @param sellOrderHash sell order hash
     * @param buyOrderHash buy order hash
     * @param sell the sell order
     * @param buy the buy order
     * @param startGasPerOrder start gas when this order started execution
     * @param execPrice execution price
     * @param _protocolFeeBps exchange fee
     * @param _wethTransferGasUnits gas units that a WETH transfer will use
     * @param weth WETH address
     */
    function _execMatchOneMakerSellToManyMakerBuys(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        uint256 startGasPerOrder,
        uint256 execPrice,
        uint32 _protocolFeeBps,
        uint32 _wethTransferGasUnits,
        address weth
    ) internal {
        if (buy.constraints[6] > 0) {
            require(tx.gasprice <= buy.constraints[6], "gas price too high");
        }
        isUserOrderNonceExecutedOrCancelled[buy.signer][
            buy.constraints[5]
        ] = true;
        uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
        uint256 remainingAmount = execPrice - protocolFee;
        _execMatchOneToManyOrders(
            sell.signer,
            buy.signer,
            buy.nfts,
            buy.execParams[1],
            remainingAmount
        );
        _emitMatchEvent(
            sellOrderHash,
            buyOrderHash,
            sell.signer,
            buy.signer,
            buy.execParams[0],
            buy.execParams[1],
            execPrice,
            buy.nfts
        );
        uint256 gasCost = (startGasPerOrder -
            gasleft() +
            _wethTransferGasUnits) * tx.gasprice;
        // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
        // else we need to send the protocol fee separately in the execution currency
        if (buy.execParams[1] == weth) {
            IERC20(weth).transferFrom(
                buy.signer,
                address(this),
                protocolFee + gasCost
            );
        } else {
            IERC20(buy.execParams[1]).transferFrom(
                buy.signer,
                address(this),
                protocolFee
            );
            IERC20(weth).transferFrom(buy.signer, address(this), gasCost);
        }
    }

    /**
   * @notice Internal helper function that executes contract state changes and does asset transfers for match one buy to many sell orders
   * @dev Updates order nonce states, does asset transfers and emits events. Gas expenditure refund is done in the caller
          since it does not need to be done in a loop
   * @param sellOrderHash sell order hash
   * @param buyOrderHash buy order hash
   * @param sell the sell order
   * @param buy the buy order
   * @param execPrice execution price
   * @param _protocolFeeBps exchange fee
   * @return the protocolFee so that the buyer can pay the protocol fee and gas cost in one go
   */
    function _execMatchOneMakerBuyToManyMakerSells(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        uint256 execPrice,
        uint32 _protocolFeeBps
    ) internal returns (uint256) {
        isUserOrderNonceExecutedOrCancelled[sell.signer][
            sell.constraints[5]
        ] = true;
        uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
        uint256 remainingAmount = execPrice - protocolFee;
        _execMatchOneToManyOrders(
            sell.signer,
            buy.signer,
            sell.nfts,
            buy.execParams[1],
            remainingAmount
        );
        _emitMatchEvent(
            sellOrderHash,
            buyOrderHash,
            sell.signer,
            buy.signer,
            buy.execParams[0],
            buy.execParams[1],
            execPrice,
            sell.nfts
        );
        return protocolFee;
    }

    /// @dev This helper purely exists to help reduce contract size a bit and avoid any stack too deep errors
    function _execMatchOneToManyOrders(
        address seller,
        address buyer,
        OrderTypes.OrderItem[] calldata constructedNfts,
        address currency,
        uint256 amount
    ) internal {
        _transferMultipleNFTs(seller, buyer, constructedNfts);
        // transfer final amount (post-fees) to seller
        IERC20(currency).transferFrom(buyer, seller, amount);
    }

    /**
     * @notice Internal helper function that executes contract state changes and does asset transfers for match orders
     * @dev Updates order nonce states, does asset transfers, emits events and does gas refunds
     * @param sellOrderHash sell order hash
     * @param buyOrderHash buy order hash
     * @param sell the sell order
     * @param buy the buy order
     * @param constructedNfts the constructed nfts
     * @param startGasPerOrder gas when this order started execution
     * @param execPrice execution price
     * @param _protocolFeeBps exchange fee
     * @param _wethTransferGasUnits gas units that a WETH transfer will use
     * @param weth WETH address
     */
    function _execMatchOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts,
        uint256 startGasPerOrder,
        uint256 execPrice,
        uint32 _protocolFeeBps,
        uint32 _wethTransferGasUnits,
        address weth
    ) internal {
        // checks if maker specified a max gas price
        if (buy.constraints[6] > 0) {
            require(tx.gasprice <= buy.constraints[6], "gas price too high");
        }
        uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
        uint256 remainingAmount = execPrice - protocolFee;
        _execMatchOrder(
            sell.signer,
            buy.signer,
            sell.constraints[5],
            buy.constraints[5],
            constructedNfts,
            buy.execParams[1],
            remainingAmount
        );
        _emitMatchEvent(
            sellOrderHash,
            buyOrderHash,
            sell.signer,
            buy.signer,
            buy.execParams[0],
            buy.execParams[1],
            execPrice,
            constructedNfts
        );
        uint256 gasCost = (startGasPerOrder -
            gasleft() +
            _wethTransferGasUnits) * tx.gasprice;
        // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
        // else we need to send the protocol fee separately in the execution currency
        if (buy.execParams[1] == weth) {
            IERC20(weth).transferFrom(
                buy.signer,
                address(this),
                protocolFee + gasCost
            );
        } else {
            IERC20(buy.execParams[1]).transferFrom(
                buy.signer,
                address(this),
                protocolFee
            );
            IERC20(weth).transferFrom(buy.signer, address(this), gasCost);
        }
    }

    /// @dev This helper purely exists to help reduce contract size a bit and avoid any stack too deep errors
    function _execMatchOrder(
        address seller,
        address buyer,
        uint256 sellNonce,
        uint256 buyNonce,
        OrderTypes.OrderItem[] calldata constructedNfts,
        address currency,
        uint256 amount
    ) internal {
        // Update order execution status to true (prevents replay)
        isUserOrderNonceExecutedOrCancelled[seller][sellNonce] = true;
        isUserOrderNonceExecutedOrCancelled[buyer][buyNonce] = true;
        _transferMultipleNFTs(seller, buyer, constructedNfts);
        // transfer final amount (post-fees) to seller
        IERC20(currency).transferFrom(buyer, seller, amount);
    }

    /// @notice Internal helper function to emit match events
    function _emitMatchEvent(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        address seller,
        address buyer,
        address complication,
        address currency,
        uint256 amount,
        OrderTypes.OrderItem[] calldata nfts
    ) internal {
        emit MatchOrderFulfilled(
            sellOrderHash,
            buyOrderHash,
            seller,
            buyer,
            complication,
            currency,
            amount,
            nfts
        );
    }

    /**
   * @notice Internal helper function that executes contract state changes and does asset transfers 
              for simple take orders
   * @dev Updates order nonce state, does asset transfers and emits events
   * @param makerOrderHash maker order hash
   * @param makerOrder the maker order
   * @param isMakerSeller is the maker order a sell order
   * @param execPrice execution price
   */
    function _execTakeOneOrder(
        bytes32 makerOrderHash,
        OrderTypes.MakerOrder calldata makerOrder,
        bool isMakerSeller,
        uint256 execPrice
    ) internal {
        isUserOrderNonceExecutedOrCancelled[makerOrder.signer][
            makerOrder.constraints[5]
        ] = true;
        if (isMakerSeller) {
            _transferNFTsAndFees(
                makerOrder.signer,
                msg.sender,
                makerOrder.nfts,
                makerOrder.execParams[1],
                execPrice
            );
            _emitTakerEvent(
                makerOrderHash,
                makerOrder.signer,
                msg.sender,
                makerOrder,
                execPrice,
                makerOrder.nfts
            );
        } else {
            _transferNFTsAndFees(
                msg.sender,
                makerOrder.signer,
                makerOrder.nfts,
                makerOrder.execParams[1],
                execPrice
            );
            _emitTakerEvent(
                makerOrderHash,
                msg.sender,
                makerOrder.signer,
                makerOrder,
                execPrice,
                makerOrder.nfts
            );
        }
    }

    /**
     * @notice Internal helper function to take orders
     * @dev verifies whether order can be executed
     * @param makerOrder the maker order
     * @param takerItems nfts to be transferred
     * @param execPrice execution price
     */
    function _takeOrders(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems,
        uint256 execPrice
    ) internal {
        bool orderExpired = isUserOrderNonceExecutedOrCancelled[
            makerOrder.signer
        ][makerOrder.constraints[5]] ||
            makerOrder.constraints[5] < userMinOrderNonce[makerOrder.signer];
        require(!orderExpired, "order expired");

        (bool executionValid, bytes32 makerOrderHash) = IFlowComplication(
            makerOrder.execParams[0]
        ).canExecTakeOrder(makerOrder, takerItems);
        require(executionValid, "cannot execute");
        _execTakeOrders(
            makerOrderHash,
            makerOrder,
            takerItems,
            makerOrder.isSellOrder,
            execPrice
        );
    }

    /**
   * @notice Internal helper function that executes contract state changes and does asset transfers 
              for take orders specifying a higher level intent
   * @dev Updates order nonce state, does asset transfers and emits events
   * @param makerOrderHash maker order hash
   * @param makerOrder the maker order
   * @param takerItems nfts to be transferred
   * @param isMakerSeller is the maker order a sell order
   * @param execPrice execution price
   */
    function _execTakeOrders(
        bytes32 makerOrderHash,
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems,
        bool isMakerSeller,
        uint256 execPrice
    ) internal {
        isUserOrderNonceExecutedOrCancelled[makerOrder.signer][
            makerOrder.constraints[5]
        ] = true;
        if (isMakerSeller) {
            _transferNFTsAndFees(
                makerOrder.signer,
                msg.sender,
                takerItems,
                makerOrder.execParams[1],
                execPrice
            );
            _emitTakerEvent(
                makerOrderHash,
                makerOrder.signer,
                msg.sender,
                makerOrder,
                execPrice,
                takerItems
            );
        } else {
            _transferNFTsAndFees(
                msg.sender,
                makerOrder.signer,
                takerItems,
                makerOrder.execParams[1],
                execPrice
            );
            _emitTakerEvent(
                makerOrderHash,
                msg.sender,
                makerOrder.signer,
                makerOrder,
                execPrice,
                takerItems
            );
        }
    }

    /// @notice Internal helper function to emit events for take orders
    function _emitTakerEvent(
        bytes32 orderHash,
        address seller,
        address buyer,
        OrderTypes.MakerOrder calldata order,
        uint256 amount,
        OrderTypes.OrderItem[] calldata nfts
    ) internal {
        emit TakeOrderFulfilled(
            orderHash,
            seller,
            buyer,
            order.execParams[0],
            order.execParams[1],
            amount,
            nfts
        );
    }

    /**
     * @notice Transfers NFTs and fees
     * @param seller the seller
     * @param buyer the buyer
     * @param nfts nfts to transfer
     * @param currency currency of the transfer
     * @param amount amount to transfer
     */
    function _transferNFTsAndFees(
        address seller,
        address buyer,
        OrderTypes.OrderItem[] calldata nfts,
        address currency,
        uint256 amount
    ) internal {
        // transfer NFTs
        _transferMultipleNFTs(seller, buyer, nfts);
        // transfer fees
        _transferFees(seller, buyer, currency, amount);
    }

    /**
     * @notice Transfers multiple NFTs in a loop
     * @param from the from address
     * @param to the to address
     * @param nfts nfts to transfer
     */
    function _transferMultipleNFTs(
        address from,
        address to,
        OrderTypes.OrderItem[] calldata nfts
    ) internal {
        for (uint256 i; i < nfts.length; ) {
            _transferNFTs(from, to, nfts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Transfer NFTs
     * @dev Only supports ERC721, no ERC1155 or NFTs that conform to both ERC721 and ERC1155
     * @param from address of the sender
     * @param to address of the recipient
     * @param item item to transfer
     */
    function _transferNFTs(
        address from,
        address to,
        OrderTypes.OrderItem calldata item
    ) internal {
        require(
            IERC165(item.collection).supportsInterface(0x80ac58cd) &&
                !IERC165(item.collection).supportsInterface(0xd9b67a26),
            "only erc721"
        );
        _transferERC721s(from, to, item);
    }

    /**
     * @notice Transfer ERC721s
     * @dev requires approvals to be set
     * @param from address of the sender
     * @param to address of the recipient
     * @param item item to transfer
     */
    function _transferERC721s(
        address from,
        address to,
        OrderTypes.OrderItem calldata item
    ) internal {
        for (uint256 i; i < item.tokens.length; ) {
            IERC721(item.collection).transferFrom(
                from,
                to,
                item.tokens[i].tokenId
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
   * @notice Transfer fees. Fees are always transferred from buyer to the seller and the exchange although seller is 
            the one that actually 'pays' the fees
   * @dev if the currency ETH, no additional transfer is needed to pay exchange fees since reqd functions are 'payable'
   * @param seller the seller
   * @param buyer the buyer
   * @param currency currency of the transfer
   * @param amount amount to transfer
   */
    function _transferFees(
        address seller,
        address buyer,
        address currency,
        uint256 amount
    ) internal {
        // protocol fee
        uint256 protocolFee = (protocolFeeBps * amount) / PRECISION;
        uint256 remainingAmount = amount - protocolFee;
        // ETH
        if (currency == address(0)) {
            // transfer amount to seller
            (bool sent, ) = seller.call{ value: remainingAmount }("");
            require(sent, "failed to send ether to seller");
        } else {
            // transfer final amount (post-fees) to seller
            IERC20(currency).transferFrom(buyer, seller, remainingAmount);
            // send fee to protocol
            IERC20(currency).transferFrom(buyer, address(this), protocolFee);
        }
    }

    // =================================================== UTILS ==================================================================

    /// @dev Gets current order price for orders that vary in price over time (dutch and reverse dutch auctions)
    function _getCurrentPrice(
        OrderTypes.MakerOrder calldata order
    ) internal view returns (uint256) {
        (uint256 startPrice, uint256 endPrice) = (
            order.constraints[1],
            order.constraints[2]
        );
        if (startPrice == endPrice) {
            return startPrice;
        }

        uint256 duration = order.constraints[4] - order.constraints[3];
        if (duration == 0) {
            return startPrice;
        }

        // solhint-disable-next-line not-rely-on-time
        uint256 elapsedTime = block.timestamp - order.constraints[3];
        unchecked {
            uint256 portionBps = elapsedTime > duration
                ? PRECISION
                : ((elapsedTime * PRECISION) / duration);
            if (startPrice > endPrice) {
                uint256 priceDiff = ((startPrice - endPrice) * portionBps) /
                    PRECISION;
                return startPrice - priceDiff;
            } else {
                uint256 priceDiff = ((endPrice - startPrice) * portionBps) /
                    PRECISION;
                return startPrice + priceDiff;
            }
        }
    }

    // ====================================================== ADMIN FUNCTIONS ======================================================

    /// @dev Used for withdrawing exchange fees paid to the contract in ETH
    function withdrawETH(address destination) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = destination.call{ value: amount }("");
        require(sent, "failed");
        emit ETHWithdrawn(destination, amount);
    }

    /// @dev Used for withdrawing exchange fees paid to the contract in ERC20 tokens
    function withdrawTokens(
        address destination,
        address currency,
        uint256 amount
    ) external onlyOwner {
        IERC20(currency).transfer(destination, amount);
        emit ERC20Withdrawn(destination, currency, amount);
    }

    /// @dev Updates auto snipe executor
    function updateMatchExecutor(address _matchExecutor) external onlyOwner {
        require(_matchExecutor != address(0), "match executor cannot be 0");
        matchExecutor = _matchExecutor;
        emit MatchExecutorUpdated(_matchExecutor);
    }

    /// @dev Updates the gas units required for WETH transfers
    function updateWethTransferGas(
        uint32 _newWethTransferGasUnits
    ) external onlyOwner {
        require(
            _newWethTransferGasUnits <= MAX_WETH_TRANSFER_GAS_UNITS,
            "gas units too high"
        );
        wethTransferGasUnits = _newWethTransferGasUnits;
        emit WethTransferGasUnitsUpdated(_newWethTransferGasUnits);
    }

    /// @dev Updates exchange fees
    function updateProtocolFee(uint32 _newProtocolFeeBps) external onlyOwner {
        require(
            _newProtocolFeeBps <= MAX_PROTOCOL_FEE_BPS,
            "protocol fee too high"
        );
        protocolFeeBps = _newProtocolFeeBps;
        emit ProtocolFeeUpdated(_newProtocolFeeBps);
    }

    /// @dev Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { FlowMatchExecutorTypes } from "../libs/FlowMatchExecutorTypes.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { SignatureChecker } from "../libs/SignatureChecker.sol";
import { IFlowExchange } from "../interfaces/IFlowExchange.sol";
import { EIP2098_allButHighestBitMask } from "../libs/Constants.sol";

/**
@title FlowMatchExecutor
@author Joe
@notice The contract that is called to execute order matches
*/
contract FlowMatchExecutor is
    IERC1271,
    IERC721Receiver,
    Ownable,
    Pausable,
    SignatureChecker
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    IFlowExchange public immutable exchange;

    /*//////////////////////////////////////////////////////////////
                              EXCHANGE STATES
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping to keep track of which exchanges are enabled
    EnumerableSet.AddressSet private _enabledExchanges;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
      //////////////////////////////////////////////////////////////*/
    event EnabledExchangeAdded(address indexed exchange);
    event EnabledExchangeRemoved(address indexed exchange);
    event InitiatorChanged(address indexed oldVal, address indexed newVal);

    ///@notice admin events
    event ETHWithdrawn(address indexed destination, uint256 amount);
    event ERC20Withdrawn(
        address indexed destination,
        address indexed currency,
        uint256 amount
    );

    address public initiator;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IFlowExchange _exchange, address _initiator) {
        exchange = _exchange;
        initiator = _initiator;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    ///////////////////////////////////////////////// OVERRIDES ///////////////////////////////////////////////////////

    // returns the magic value if the message is signed by the owner of this contract, invalid value otherwise
    function isValidSignature(
        bytes32 message,
        bytes calldata signature
    ) external view override returns (bytes4) {
        _assertValidSignatureHelper(owner(), message, signature);
        return 0x1626ba7e; // EIP-1271 magic value
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    ///////////////////////////////////////////////// EXTERNAL FUNCTIONS ///////////////////////////////////////////////////////

    /**
     * @notice The entry point for executing brokerage matches. Callable only by owner
     * @param batches The batches of calls to make
     */
    function executeBrokerMatches(
        FlowMatchExecutorTypes.Batch[] calldata batches
    ) external whenNotPaused {
        require(msg.sender == initiator, "only initiator can call");
        uint256 numBatches = batches.length;
        for (uint256 i; i < numBatches; ) {
            _broker(batches[i].externalFulfillments);
            _matchOrders(batches[i].matches);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice The entry point for executing native matches. Callable only by owner
     * @param matches The matches to make
     */
    function executeNativeMatches(
        FlowMatchExecutorTypes.MatchOrders[] calldata matches
    ) external whenNotPaused {
        require(msg.sender == initiator, "only initiator can call");
        _matchOrders(matches);
    }

    //////////////////////////////////////////////////// INTERNAL FUNCTIONS ///////////////////////////////////////////////////////

    /**
     * @notice broker a trade by fulfilling orders on other exchanges and transferring nfts to the intermediary
     * @param externalFulfillments The specification of the external calls to make and nfts to transfer
     */
    function _broker(
        FlowMatchExecutorTypes.ExternalFulfillments
            calldata externalFulfillments
    ) internal {
        uint256 numCalls = externalFulfillments.calls.length;
        if (numCalls > 0) {
            for (uint256 i; i < numCalls; ) {
                _call(externalFulfillments.calls[i]);
                unchecked {
                    ++i;
                }
            }
        }

        if (externalFulfillments.nftsToTransfer.length > 0) {
            for (uint256 i; i < externalFulfillments.nftsToTransfer.length; ) {
                bool isApproved = IERC721(
                    externalFulfillments.nftsToTransfer[i].collection
                ).isApprovedForAll(address(this), address(exchange));

                if (!isApproved) {
                    IERC721(externalFulfillments.nftsToTransfer[i].collection)
                        .setApprovalForAll(address(exchange), true);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Execute a call to the specified contract
     * @param params The call to execute
     */
    function _call(
        FlowMatchExecutorTypes.Call memory params
    ) internal returns (bytes memory) {
        if (params.isPayable) {
            require(
                _enabledExchanges.contains(params.to),
                "contract is not enabled"
            );
            (bool _success, bytes memory _result) = params.to.call{
                value: params.value
            }(params.data);
            require(_success, "external MP call failed");
            return _result;
        } else {
            require(params.value == 0, "value not 0 in non-payable call");
            (bool _success, bytes memory _result) = params.to.call(params.data);
            require(_success, "external MP call failed");
            return _result;
        }
    }

    /**
     * @notice Function called to execute a batch of matches by calling the exchange contract
     * @param matches The batch of matches to execute on the exchange
     */
    function _matchOrders(
        FlowMatchExecutorTypes.MatchOrders[] calldata matches
    ) internal {
        uint256 numMatches = matches.length;
        if (numMatches > 0) {
            for (uint256 i; i < numMatches; ) {
                FlowMatchExecutorTypes.MatchOrdersType matchType = matches[i]
                    .matchType;
                if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToOneSpecific
                ) {
                    exchange.matchOneToOneOrders(
                        matches[i].buys,
                        matches[i].sells
                    );
                } else if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToOneUnspecific
                ) {
                    exchange.matchOrders(
                        matches[i].sells,
                        matches[i].buys,
                        matches[i].constructs
                    );
                } else if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToMany
                ) {
                    if (matches[i].buys.length == 1) {
                        exchange.matchOneToManyOrders(
                            matches[i].buys[0],
                            matches[i].sells
                        );
                    } else if (matches[i].sells.length == 1) {
                        exchange.matchOneToManyOrders(
                            matches[i].sells[0],
                            matches[i].buys
                        );
                    } else {
                        revert("invalid one to many order");
                    }
                } else {
                    revert("invalid match type");
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    // ======================================================= VIEW FUNCTIONS ============================================================

    function numEnabledExchanges() external view returns (uint256) {
        return _enabledExchanges.length();
    }

    function getEnabledExchangeAt(
        uint256 index
    ) external view returns (address) {
        return _enabledExchanges.at(index);
    }

    function isExchangeEnabled(address _exchange) external view returns (bool) {
        return _enabledExchanges.contains(_exchange);
    }

    //////////////////////////////////////////////////// ADMIN FUNCTIONS ///////////////////////////////////////////////////////

    function withdrawETH(address destination) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = destination.call{ value: amount }("");
        require(sent, "failed");
        emit ETHWithdrawn(destination, amount);
    }

    /// @dev Used for withdrawing exchange fees paid to the contract in ERC20 tokens
    function withdrawTokens(
        address destination,
        address currency,
        uint256 amount
    ) external onlyOwner {
        IERC20(currency).transfer(destination, amount);
        emit ERC20Withdrawn(destination, currency, amount);
    }

    /**
     * @notice Enable an exchange
     * @param _exchange The exchange to enable
     */
    function addEnabledExchange(address _exchange) external onlyOwner {
        _enabledExchanges.add(_exchange);
        emit EnabledExchangeAdded(_exchange);
    }

    /**
     * @notice Disable an exchange
     * @param _exchange The exchange to disable
     */
    function removeEnabledExchange(address _exchange) external onlyOwner {
        _enabledExchanges.remove(_exchange);
        emit EnabledExchangeRemoved(_exchange);
    }

    function updateInitiator(address _initiator) external onlyOwner {
        address oldVal = initiator;
        initiator = _initiator;
        emit InitiatorChanged(oldVal, _initiator);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time
pragma solidity 0.8.14;

// external imports
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// internal imports
import { OrderTypes, SignatureChecker } from "../libs/SignatureChecker.sol";
import { IFlowComplication } from "../interfaces/IFlowComplication.sol";

/**
 * @title FlowOrderBookComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication to execute orderbook orders
 */
contract FlowOrderBookComplication is
    IFlowComplication,
    Ownable,
    SignatureChecker
{
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 public constant PRECISION = 1e4; // precision for division; similar to bps

    /// @dev WETH address of the chain being used
    // solhint-disable-next-line var-name-mixedcase
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant ORDER_HASH =
        0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;

    // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant ORDER_ITEM_HASH =
        0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;

    // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant TOKEN_INFO_HASH =
        0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;

    /// @dev Used in order signing with EIP-712
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @dev Storage variable that keeps track of valid currencies used for payment (tokens)
    EnumerableSet.AddressSet private _currencies;

    bool public trustedExecEnabled = false;

    event CurrencyAdded(address currency);
    event CurrencyRemoved(address currency);
    event TrustedExecutionChanged(bool oldVal, bool newVal);

    constructor() {
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("FlowComplication"),
                keccak256(bytes("1")), // for versionId = 1
                block.chainid,
                address(this)
            )
        );

        // add default currencies
        _currencies.add(WETH);
        _currencies.add(address(0)); // ETH
    }

    // ======================================================= EXTERNAL FUNCTIONS ==================================================

    /**
   * @notice Checks whether one to one matches can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have one specific NFT only, whether time is still valid,
          prices are valid and whether the nfts intersect.
   * @param makerOrder1 first makerOrder
   * @param makerOrder2 second makerOrder
   * @return returns whether the order can be executed, orderHashes and the execution price
   */
    function canExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view override returns (bool, bytes32, bytes32, uint256) {
        // check if the orders are valid
        bool _isPriceValid;
        uint256 makerOrder1Price = _getCurrentPrice(makerOrder1);
        uint256 makerOrder2Price = _getCurrentPrice(makerOrder2);
        uint256 execPrice;
        if (makerOrder1.isSellOrder) {
            _isPriceValid = makerOrder2Price >= makerOrder1Price;
            execPrice = makerOrder1Price;
        } else {
            _isPriceValid = makerOrder1Price >= makerOrder2Price;
            execPrice = makerOrder2Price;
        }

        bytes32 sellOrderHash = _hash(makerOrder1);
        bytes32 buyOrderHash = _hash(makerOrder2);

        if (trustedExecEnabled) {
            bool trustedExec = makerOrder2.constraints.length == 8 &&
                makerOrder2.constraints[7] == 1 &&
                makerOrder1.constraints.length == 8 &&
                makerOrder1.constraints[7] == 1;
            if (trustedExec) {
                bool sigValid = SignatureChecker.verify(
                    sellOrderHash,
                    makerOrder1.signer,
                    makerOrder1.sig,
                    DOMAIN_SEPARATOR
                ) &&
                    SignatureChecker.verify(
                        buyOrderHash,
                        makerOrder2.signer,
                        makerOrder2.sig,
                        DOMAIN_SEPARATOR
                    );
                return (sigValid, sellOrderHash, buyOrderHash, execPrice);
            }
        }

        require(
            verifyMatchOneToOneOrders(
                sellOrderHash,
                buyOrderHash,
                makerOrder1,
                makerOrder2
            ),
            "order not verified"
        );

        // check constraints
        bool numItemsValid = makerOrder2.constraints[0] ==
            makerOrder1.constraints[0] &&
            makerOrder2.constraints[0] == 1 &&
            makerOrder2.nfts.length == 1 &&
            makerOrder2.nfts[0].tokens.length == 1 &&
            makerOrder1.nfts.length == 1 &&
            makerOrder1.nfts[0].tokens.length == 1;

        bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
            makerOrder2.constraints[4] >= block.timestamp &&
            makerOrder1.constraints[3] <= block.timestamp &&
            makerOrder1.constraints[4] >= block.timestamp;

        return (
            numItemsValid &&
                _isTimeValid &&
                doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) &&
                _isPriceValid,
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view returns (bool, bytes32, bytes32, uint256) {
        // check if the orders are valid
        bool _isPriceValid;
        uint256 makerOrder1Price = _getCurrentPrice(makerOrder1);
        uint256 makerOrder2Price = _getCurrentPrice(makerOrder2);
        uint256 execPrice;
        if (makerOrder1.isSellOrder) {
            _isPriceValid = makerOrder2Price >= makerOrder1Price;
            execPrice = makerOrder1Price;
        } else {
            _isPriceValid = makerOrder1Price >= makerOrder2Price;
            execPrice = makerOrder2Price;
        }

        bytes32 sellOrderHash = _hash(makerOrder1);
        bytes32 buyOrderHash = _hash(makerOrder2);

        require(
            verifyMatchOneToOneOrders(
                sellOrderHash,
                buyOrderHash,
                makerOrder1,
                makerOrder2
            ),
            "order not verified"
        );

        // check constraints
        bool numItemsValid = makerOrder2.constraints[0] ==
            makerOrder1.constraints[0] &&
            makerOrder2.constraints[0] == 1 &&
            makerOrder2.nfts.length == 1 &&
            makerOrder2.nfts[0].tokens.length == 1 &&
            makerOrder1.nfts.length == 1 &&
            makerOrder1.nfts[0].tokens.length == 1;

        bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
            makerOrder2.constraints[4] >= block.timestamp &&
            makerOrder1.constraints[3] <= block.timestamp &&
            makerOrder1.constraints[4] >= block.timestamp;

        return (
            numItemsValid &&
                _isTimeValid &&
                doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) &&
                _isPriceValid,
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
   * @notice Checks whether one to many matches can be executed
   * @dev This function is called by the main exchange to check whether one to many matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect. All orders are expected to contain specific items.
   * @param makerOrder the one makerOrder
   * @param manyMakerOrders many maker orders
   * @return returns whether the order can be executed and orderHash of the one side order
   */
    function canExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view override returns (bool, bytes32) {
        bytes32 makerOrderHash = _hash(makerOrder);

        if (trustedExecEnabled) {
            bool isTrustedExec = makerOrder.constraints.length == 8 &&
                makerOrder.constraints[7] == 1;
            for (uint256 i; i < manyMakerOrders.length; ) {
                isTrustedExec =
                    isTrustedExec &&
                    manyMakerOrders[i].constraints.length == 8 &&
                    manyMakerOrders[i].constraints[7] == 1;
                if (!isTrustedExec) {
                    break; // short circuit
                }
                unchecked {
                    ++i;
                }
            }

            if (isTrustedExec) {
                bool sigValid = SignatureChecker.verify(
                    makerOrderHash,
                    makerOrder.signer,
                    makerOrder.sig,
                    DOMAIN_SEPARATOR
                );
                return (sigValid, makerOrderHash);
            }
        }

        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        // check the constraints of the 'one' maker order
        uint256 numNftsInOneOrder;
        for (uint256 i; i < makerOrder.nfts.length; ) {
            numNftsInOneOrder =
                numNftsInOneOrder +
                makerOrder.nfts[i].tokens.length;
            unchecked {
                ++i;
            }
        }

        // check the constraints of many maker orders
        uint256 totalNftsInManyOrders;
        bool numNftsPerManyOrderValid = true;
        bool isOrdersTimeValid = true;
        bool itemsIntersect = true;
        for (uint256 i; i < manyMakerOrders.length; ) {
            uint256 nftsLength = manyMakerOrders[i].nfts.length;
            uint256 numNftsPerOrder;
            for (uint256 j; j < nftsLength; ) {
                numNftsPerOrder =
                    numNftsPerOrder +
                    manyMakerOrders[i].nfts[j].tokens.length;
                unchecked {
                    ++j;
                }
            }
            numNftsPerManyOrderValid =
                numNftsPerManyOrderValid &&
                manyMakerOrders[i].constraints[0] == numNftsPerOrder;
            totalNftsInManyOrders = totalNftsInManyOrders + numNftsPerOrder;

            isOrdersTimeValid =
                isOrdersTimeValid &&
                manyMakerOrders[i].constraints[3] <= block.timestamp &&
                manyMakerOrders[i].constraints[4] >= block.timestamp;

            itemsIntersect =
                itemsIntersect &&
                doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

            if (!numNftsPerManyOrderValid) {
                return (false, makerOrderHash); // short circuit
            }

            unchecked {
                ++i;
            }
        }

        bool _isTimeValid = isOrdersTimeValid &&
            makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
        uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

        bool _isPriceValid;
        if (makerOrder.isSellOrder) {
            _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
        } else {
            _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
        }

        return (
            numNftsInOneOrder == makerOrder.constraints[0] &&
                numNftsInOneOrder == totalNftsInManyOrders &&
                _isTimeValid &&
                itemsIntersect &&
                _isPriceValid,
            makerOrderHash
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view returns (bool, bytes32) {
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        // check the constraints of the 'one' maker order
        uint256 numNftsInOneOrder;
        for (uint256 i; i < makerOrder.nfts.length; ) {
            numNftsInOneOrder =
                numNftsInOneOrder +
                makerOrder.nfts[i].tokens.length;
            unchecked {
                ++i;
            }
        }

        // check the constraints of many maker orders
        uint256 totalNftsInManyOrders;
        bool numNftsPerManyOrderValid = true;
        bool isOrdersTimeValid = true;
        bool itemsIntersect = true;
        for (uint256 i; i < manyMakerOrders.length; ) {
            uint256 nftsLength = manyMakerOrders[i].nfts.length;
            uint256 numNftsPerOrder;
            for (uint256 j; j < nftsLength; ) {
                numNftsPerOrder =
                    numNftsPerOrder +
                    manyMakerOrders[i].nfts[j].tokens.length;
                unchecked {
                    ++j;
                }
            }
            numNftsPerManyOrderValid =
                numNftsPerManyOrderValid &&
                manyMakerOrders[i].constraints[0] == numNftsPerOrder;
            totalNftsInManyOrders = totalNftsInManyOrders + numNftsPerOrder;

            isOrdersTimeValid =
                isOrdersTimeValid &&
                manyMakerOrders[i].constraints[3] <= block.timestamp &&
                manyMakerOrders[i].constraints[4] >= block.timestamp;

            itemsIntersect =
                itemsIntersect &&
                doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

            if (!numNftsPerManyOrderValid) {
                return (false, makerOrderHash); // short circuit
            }

            unchecked {
                ++i;
            }
        }

        bool _isTimeValid = isOrdersTimeValid &&
            makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
        uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

        bool _isPriceValid;
        if (makerOrder.isSellOrder) {
            _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
        } else {
            _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
        }

        return (
            numNftsInOneOrder == makerOrder.constraints[0] &&
                numNftsInOneOrder == totalNftsInManyOrders &&
                _isTimeValid &&
                itemsIntersect &&
                _isPriceValid,
            makerOrderHash
        );
    }

    /**
   * @notice Checks whether match orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect
   * @param sell sell order
   * @param buy buy order
   * @param constructedNfts - nfts constructed by the off chain matching engine
   * @return returns whether the order can be execute, orderHashes and the execution price
   */
    function canExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view override returns (bool, bytes32, bytes32, uint256) {
        // check if orders are valid
        (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);

        bytes32 sellOrderHash = _hash(sell);
        bytes32 buyOrderHash = _hash(buy);

        if (trustedExecEnabled) {
            bool trustedExec = sell.constraints.length == 8 &&
                sell.constraints[7] == 1 &&
                buy.constraints.length == 8 &&
                buy.constraints[7] == 1;
            if (trustedExec) {
                bool sigValid = SignatureChecker.verify(
                    sellOrderHash,
                    sell.signer,
                    sell.sig,
                    DOMAIN_SEPARATOR
                ) &&
                    SignatureChecker.verify(
                        buyOrderHash,
                        buy.signer,
                        buy.sig,
                        DOMAIN_SEPARATOR
                    );
                return (sigValid, sellOrderHash, buyOrderHash, execPrice);
            }
        }

        require(
            verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy),
            "order not verified"
        );

        return (
            isTimeValid(sell, buy) &&
                _isPriceValid &&
                areNumMatchItemsValid(sell, buy, constructedNfts) &&
                doItemsIntersect(sell.nfts, constructedNfts) &&
                doItemsIntersect(buy.nfts, constructedNfts),
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view returns (bool, bytes32, bytes32, uint256) {
        // check if orders are valid
        (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);

        bytes32 sellOrderHash = _hash(sell);
        bytes32 buyOrderHash = _hash(buy);

        require(
            verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy),
            "order not verified"
        );

        return (
            isTimeValid(sell, buy) &&
                _isPriceValid &&
                areNumMatchItemsValid(sell, buy, constructedNfts) &&
                doItemsIntersect(sell.nfts, constructedNfts) &&
                doItemsIntersect(buy.nfts, constructedNfts),
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
   * @notice Checks whether one to one taker orders can be executed
   * @dev This function is called by the main exchange to check whether one to one taker orders can be executed.
          It checks whether orders have the right constraints - i.e they have one NFT only and whether time is still valid
   * @param makerOrder the makerOrder
   * @return returns whether the order can be executed and makerOrderHash
   */
    function canExecTakeOneOrder(
        OrderTypes.MakerOrder calldata makerOrder
    ) external view override returns (bool, bytes32) {
        // check if makerOrder is valid
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        bool numItemsValid = makerOrder.constraints[0] == 1 &&
            makerOrder.nfts.length == 1 &&
            makerOrder.nfts[0].tokens.length == 1;
        bool _isTimeValid = makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        return (numItemsValid && _isTimeValid, makerOrderHash);
    }

    /**
   * @notice Checks whether take orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether take orders with a higher level intent can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid
          and whether the nfts intersect
   * @param makerOrder the maker order
   * @param takerItems the taker items specified by the taker
   * @return returns whether order can be executed and the makerOrderHash
   */
    function canExecTakeOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) external view override returns (bool, bytes32) {
        // check if makerOrder is valid
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        return (
            makerOrder.constraints[3] <= block.timestamp &&
                makerOrder.constraints[4] >= block.timestamp &&
                areNumTakerItemsValid(makerOrder, takerItems) &&
                doItemsIntersect(makerOrder.nfts, takerItems),
            makerOrderHash
        );
    }

    // ======================================================= PUBLIC FUNCTIONS ==================================================

    /**
     * @notice Checks whether orders are valid
     * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
     * @param sellOrderHash hash of the sell order
     * @param buyOrderHash hash of the buy order
     * @param sell the sell order
     * @param buy the buy order
     * @return whether orders are valid
     */
    function verifyMatchOneToOneOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        return (sell.isSellOrder &&
            !buy.isSellOrder &&
            sell.execParams[0] == buy.execParams[0] &&
            sell.signer != buy.signer &&
            currenciesMatch &&
            isOrderValid(sell, sellOrderHash) &&
            isOrderValid(buy, buyOrderHash));
    }

    /**
     * @notice Checks whether orders are valid
     * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
     * @param sell the sell order
     * @param buy the buy order
     * @return whether orders are valid and orderHash
     */
    function verifyMatchOneToManyOrders(
        bool verifySellOrder,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view override returns (bool, bytes32) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        bool _orderValid;
        bytes32 orderHash;

        if (verifySellOrder) {
            orderHash = _hash(sell);
            _orderValid = isOrderValid(sell, orderHash);
        } else {
            orderHash = _hash(buy);
            _orderValid = isOrderValid(buy, orderHash);
        }
        return (
            sell.isSellOrder &&
                !buy.isSellOrder &&
                sell.execParams[0] == buy.execParams[0] &&
                sell.signer != buy.signer &&
                currenciesMatch &&
                _orderValid,
            orderHash
        );
    }

    /**
   * @notice Checks whether orders are valid
   * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
          Also checks if the given complication can execute this order
   * @param sellOrderHash hash of the sell order
   * @param buyOrderHash hash of the buy order
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid
   */
    function verifyMatchOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        return (sell.isSellOrder &&
            !buy.isSellOrder &&
            sell.execParams[0] == buy.execParams[0] &&
            sell.signer != buy.signer &&
            currenciesMatch &&
            isOrderValid(sell, sellOrderHash) &&
            isOrderValid(buy, buyOrderHash));
    }

    /**
     * @notice Verifies the validity of the order
     * @dev checks if signature is valid and if the complication and currency are valid
     * @param order the order
     * @param orderHash computed hash of the order
     * @return whether the order is valid
     */
    function isOrderValid(
        OrderTypes.MakerOrder calldata order,
        bytes32 orderHash
    ) public view returns (bool) {
        // Verify the validity of the signature
        bool sigValid = SignatureChecker.verify(
            orderHash,
            order.signer,
            order.sig,
            DOMAIN_SEPARATOR
        );

        return (sigValid &&
            order.execParams[0] == address(this) &&
            _currencies.contains(order.execParams[1]));
    }

    /// @dev checks whether the orders are expired
    function isTimeValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        return
            sell.constraints[3] <= block.timestamp &&
            sell.constraints[4] >= block.timestamp &&
            buy.constraints[3] <= block.timestamp &&
            buy.constraints[4] >= block.timestamp;
    }

    /// @dev checks whether the price is valid; a buy order should always have a higher price than a sell order
    function isPriceValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool, uint256) {
        (uint256 currentSellPrice, uint256 currentBuyPrice) = (
            _getCurrentPrice(sell),
            _getCurrentPrice(buy)
        );
        return (currentBuyPrice >= currentSellPrice, currentSellPrice);
    }

    /// @dev sanity check to make sure the constructed nfts conform to the user signed constraints
    function areNumMatchItemsValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) public pure returns (bool) {
        uint256 numConstructedItems;
        for (uint256 i; i < constructedNfts.length; ) {
            unchecked {
                numConstructedItems =
                    numConstructedItems +
                    constructedNfts[i].tokens.length;
                ++i;
            }
        }
        return
            numConstructedItems >= buy.constraints[0] &&
            numConstructedItems <= sell.constraints[0];
    }

    /// @dev sanity check to make sure that a taker is specifying the right number of items
    function areNumTakerItemsValid(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) public pure returns (bool) {
        uint256 numTakerItems;
        for (uint256 i; i < takerItems.length; ) {
            unchecked {
                numTakerItems = numTakerItems + takerItems[i].tokens.length;
                ++i;
            }
        }
        return makerOrder.constraints[0] == numTakerItems;
    }

    /**
     * @notice Checks whether nfts intersect
     * @dev This function checks whether there are intersecting nfts between two orders
     * @param order1Nfts nfts in the first order
     * @param order2Nfts nfts in the second order
     * @return returns whether items intersect
     */
    function doItemsIntersect(
        OrderTypes.OrderItem[] calldata order1Nfts,
        OrderTypes.OrderItem[] calldata order2Nfts
    ) public pure returns (bool) {
        uint256 order1NftsLength = order1Nfts.length;
        uint256 order2NftsLength = order2Nfts.length;
        // case where maker/taker didn't specify any items
        if (order1NftsLength == 0 || order2NftsLength == 0) {
            return true;
        }

        uint256 numCollsMatched;
        unchecked {
            for (uint256 i; i < order2NftsLength; ) {
                for (uint256 j; j < order1NftsLength; ) {
                    if (order1Nfts[j].collection == order2Nfts[i].collection) {
                        // increment numCollsMatched
                        ++numCollsMatched;
                        // check if tokenIds intersect
                        bool tokenIdsIntersect = doTokenIdsIntersect(
                            order1Nfts[j],
                            order2Nfts[i]
                        );
                        require(tokenIdsIntersect, "tokenIds dont intersect");
                        // short circuit
                        break;
                    }
                    ++j;
                }
                ++i;
            }
        }

        return numCollsMatched == order2NftsLength;
    }

    /**
     * @notice Checks whether tokenIds intersect
     * @dev This function checks whether there are intersecting tokenIds between two order items
     * @param item1 first item
     * @param item2 second item
     * @return returns whether tokenIds intersect
     */
    function doTokenIdsIntersect(
        OrderTypes.OrderItem calldata item1,
        OrderTypes.OrderItem calldata item2
    ) public pure returns (bool) {
        uint256 item1TokensLength = item1.tokens.length;
        uint256 item2TokensLength = item2.tokens.length;
        // case where maker/taker didn't specify any tokenIds for this collection
        if (item1TokensLength == 0 || item2TokensLength == 0) {
            return true;
        }
        uint256 numTokenIdsPerCollMatched;
        unchecked {
            for (uint256 k; k < item2TokensLength; ) {
                // solhint-disable-next-line use-forbidden-name
                for (uint256 l; l < item1TokensLength; ) {
                    if (item1.tokens[l].tokenId == item2.tokens[k].tokenId) {
                        // increment numTokenIdsPerCollMatched
                        ++numTokenIdsPerCollMatched;
                        // short circuit
                        break;
                    }
                    ++l;
                }
                ++k;
            }
        }

        return numTokenIdsPerCollMatched == item2TokensLength;
    }

    // ======================================================= UTILS ============================================================

    /// @dev hashes the given order with the help of _nftsHash and _tokensHash
    function _hash(
        OrderTypes.MakerOrder calldata order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_HASH,
                    order.isSellOrder,
                    order.signer,
                    keccak256(abi.encodePacked(order.constraints)),
                    _nftsHash(order.nfts),
                    keccak256(abi.encodePacked(order.execParams)),
                    keccak256(order.extraParams)
                )
            );
    }

    function _nftsHash(
        OrderTypes.OrderItem[] calldata nfts
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](nfts.length);
        for (uint256 i; i < nfts.length; ) {
            bytes32 hash = keccak256(
                abi.encode(
                    ORDER_ITEM_HASH,
                    nfts[i].collection,
                    _tokensHash(nfts[i].tokens)
                )
            );
            hashes[i] = hash;
            unchecked {
                ++i;
            }
        }
        bytes32 nftsHash = keccak256(abi.encodePacked(hashes));
        return nftsHash;
    }

    function _tokensHash(
        OrderTypes.TokenInfo[] calldata tokens
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](tokens.length);
        for (uint256 i; i < tokens.length; ) {
            bytes32 hash = keccak256(
                abi.encode(
                    TOKEN_INFO_HASH,
                    tokens[i].tokenId,
                    tokens[i].numTokens
                )
            );
            hashes[i] = hash;
            unchecked {
                ++i;
            }
        }
        bytes32 tokensHash = keccak256(abi.encodePacked(hashes));
        return tokensHash;
    }

    /// @dev returns the sum of current order prices; used in match one to many orders
    function _sumCurrentPrices(
        OrderTypes.MakerOrder[] calldata orders
    ) internal view returns (uint256) {
        uint256 sum;
        uint256 ordersLength = orders.length;
        for (uint256 i; i < ordersLength; ) {
            sum = sum + _getCurrentPrice(orders[i]);
            unchecked {
                ++i;
            }
        }
        return sum;
    }

    /// @dev Gets current order price for orders that vary in price over time (dutch and reverse dutch auctions)
    function _getCurrentPrice(
        OrderTypes.MakerOrder calldata order
    ) internal view returns (uint256) {
        (uint256 startPrice, uint256 endPrice) = (
            order.constraints[1],
            order.constraints[2]
        );
        if (startPrice == endPrice) {
            return startPrice;
        }

        uint256 duration = order.constraints[4] - order.constraints[3];
        if (duration == 0) {
            return startPrice;
        }

        uint256 elapsedTime = block.timestamp - order.constraints[3];
        unchecked {
            uint256 portionBps = elapsedTime > duration
                ? PRECISION
                : ((elapsedTime * PRECISION) / duration);
            if (startPrice > endPrice) {
                uint256 priceDiff = ((startPrice - endPrice) * portionBps) /
                    PRECISION;
                return startPrice - priceDiff;
            } else {
                uint256 priceDiff = ((endPrice - startPrice) * portionBps) /
                    PRECISION;
                return startPrice + priceDiff;
            }
        }
    }

    // ======================================================= VIEW FUNCTIONS ============================================================

    /// @notice returns the number of currencies supported by the exchange
    function numCurrencies() external view returns (uint256) {
        return _currencies.length();
    }

    /// @notice returns the currency at the given index
    function getCurrencyAt(uint256 index) external view returns (address) {
        return _currencies.at(index);
    }

    /// @notice returns whether a given currency is valid
    function isValidCurrency(address currency) external view returns (bool) {
        return _currencies.contains(currency);
    }

    // ======================================================= OWNER FUNCTIONS ============================================================

    /// @dev adds a new transaction currency to the exchange
    function addCurrency(address _currency) external onlyOwner {
        _currencies.add(_currency);
        emit CurrencyAdded(_currency);
    }

    /// @dev removes a transaction currency from the exchange
    function removeCurrency(address _currency) external onlyOwner {
        _currencies.remove(_currency);
        emit CurrencyRemoved(_currency);
    }

    /// @dev enables/diables trusted execution
    function setTrustedExecStatus(bool newVal) external onlyOwner {
        bool oldVal = trustedExecEnabled;
        require(oldVal != newVal, "no value change");
        trustedExecEnabled = newVal;
        emit TrustedExecutionChanged(oldVal, newVal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { OrderTypes } from "../libs/OrderTypes.sol";

/**
 * @title IFlowComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication interface that must be implemented by all complications (execution strategies)
 */
interface IFlowComplication {
    function canExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view returns (bool, bytes32, bytes32, uint256);

    function canExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view returns (bool, bytes32);

    function canExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view returns (bool, bytes32, bytes32, uint256);

    function canExecTakeOneOrder(
        OrderTypes.MakerOrder calldata makerOrder
    ) external view returns (bool, bytes32);

    function canExecTakeOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) external view returns (bool, bytes32);

    function verifyMatchOneToManyOrders(
        bool verifySellOrder,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) external view returns (bool, bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { OrderTypes } from "../libs/OrderTypes.sol";

/**
 * @title IFlowExchange
 * @author Joe
 * @notice Exchange interface that must be implemented by the Flow Exchange
 */
interface IFlowExchange {
    function matchOneToOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders1,
        OrderTypes.MakerOrder[] calldata makerOrders2
    ) external;

    function matchOneToManyOrders(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external;

    function matchOrders(
        OrderTypes.MakerOrder[] calldata sells,
        OrderTypes.MakerOrder[] calldata buys,
        OrderTypes.OrderItem[][] calldata constructs
    ) external;

    function takeMultipleOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders
    ) external payable;

    function takeOrders(
        OrderTypes.MakerOrder[] calldata makerOrders,
        OrderTypes.OrderItem[][] calldata takerNfts
    ) external payable;

    function transferMultipleNFTs(
        address to,
        OrderTypes.OrderItem[] calldata items
    ) external;

    function cancelAllOrders(uint256 minNonce) external;

    function cancelMultipleOrders(uint256[] calldata orderNonces) external;

    function isNonceValid(
        address user,
        uint256 nonce
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant OneWord = 0x20;
uint256 constant OneWordShift = 0x5;
uint256 constant ThirtyOneBytes = 0x1f;
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 0x3;
uint256 constant MemoryExpansionCoefficientShift = 0x9;

uint256 constant BulkOrder_Typehash_Height_One = (
    0x25f1d312acdce9bb5f11c5585e941709b8456695fe5aacf9998bd3acadfd7fec
);
uint256 constant BulkOrder_Typehash_Height_Two = (
    0xb7870d22600c57d01e7ff46f87ea8741898e43ce73f7d5bfb269c715ea8d4242
);
uint256 constant BulkOrder_Typehash_Height_Three = (
    0xe9ccc656222762d6d2e94ef74311f23818493f907cde851440e6d8773f56c5fe
);
uint256 constant BulkOrder_Typehash_Height_Four = (
    0x14300c4bb2d1850e661a7bb2347e8ac0fa0736fa434a6d0ae1017cb485ce1a7c
);
uint256 constant BulkOrder_Typehash_Height_Five = (
    0xd2a9fdbc6e34ad83660cd4ad49310a663134bbdaea7c34c7c6a95cf9aa8618b1
);
uint256 constant BulkOrder_Typehash_Height_Six = (
    0x4c2c782f8c9daf12d0ec87e76fc496ffeed835292ca7ff04ac92375bbc0f4cc7
);
uint256 constant BulkOrder_Typehash_Height_Seven = (
    0xab5bd2a739337f6f3d8743b51df07f176805bae22da4b25be5d8cdd688498382
);
uint256 constant BulkOrder_Typehash_Height_Eight = (
    0x96596fb6c680230945bae686c1776a9920c438436a98dba61ca767f370b6ef0c
);
uint256 constant BulkOrder_Typehash_Height_Nine = (
    0x40d250b9c55bcc275a49429cae143a873752d755dfa1072e47e10d5252fb8d3b
);
uint256 constant BulkOrder_Typehash_Height_Ten = (
    0xeaf49b43e05b65ffed9bd664ee39555b22fa8ba157aa058f19fc7fee92d386f4
);
uint256 constant BulkOrder_Typehash_Height_Eleven = (
    0x9d5d1c872408322fe8c431a1b66583d09e5dd77e0ac5f99b55131b3fe8363ffb
);
uint256 constant BulkOrder_Typehash_Height_Twelve = (
    0xdb50e721ad63671fc79a925f372d22d69adfe998243b341129c4ef29a20c7a74
);
uint256 constant BulkOrder_Typehash_Height_Thirteen = (
    0x908c5a945faf8d6b1d5aba44fc097fb8c22cca14f60bf75bf680224813809637
);
uint256 constant BulkOrder_Typehash_Height_Fourteen = (
    0x7968127d641eabf208fbdc9d69f10fed718855c94a809679d41b7bcf18104b74
);
uint256 constant BulkOrder_Typehash_Height_Fifteen = (
    0x814b44e912b2ccd234edcf03da0b9d37c459baf9d512034ed96bc93032c37bab
);
uint256 constant BulkOrder_Typehash_Height_Sixteen = (
    0x3a8ceb52e9851a307cf6bd49c73a2ec0d37712e6c4d68c4dcf84df0ad574f59a
);
uint256 constant BulkOrder_Typehash_Height_Seventeen = (
    0xdd2197b5843051f931afa0a534e25a1d824e11ccb5e100c716e9e40406c68b3a
);
uint256 constant BulkOrder_Typehash_Height_Eighteen = (
    0x84b50d02c0d7ec2a815ec27a71290ad861c7cd3addd94f5f7c0736df33fe1827
);
uint256 constant BulkOrder_Typehash_Height_Nineteen = (
    0xdaa31608975cb535532462ce63bbb075b6d81235cd756da2117e745baed067c1
);
uint256 constant BulkOrder_Typehash_Height_Twenty = (
    0x5089f7eef268ce27189a0f19e64dd8210ecadff4be5176a5bd4fd1f176f483a1
);
uint256 constant BulkOrder_Typehash_Height_TwentyOne = (
    0x907e1899005168c54e8279a0e7fc8f890b1de622a79e1ea1447bde837732da56
);
uint256 constant BulkOrder_Typehash_Height_TwentyTwo = (
    0x73ea6321c43a7d88f2d0f797219c7dd3405b1208e89c6d00c6df5c2cc833aa1d
);
uint256 constant BulkOrder_Typehash_Height_TwentyThree = (
    0xb2036d7869c41d1588416aba4ce6e52b45a330fd934c05995b14653db5db9293
);
uint256 constant BulkOrder_Typehash_Height_TwentyFour = (
    0x99e8d8ff7ddc6198258cce0fe5930c7fe7799405517eca81dbf14c1707c163ad
);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { OrderTypes } from "./OrderTypes.sol";

/**
 * @title FlowMatchExecutorTyoes
 * @author Joe
 * @notice This library contains the match executor types
 */
library FlowMatchExecutorTypes {
    struct Call {
        bytes data;
        uint256 value;
        address payable to;
        bool isPayable;
    }

    struct ExternalFulfillments {
        Call[] calls;
        OrderTypes.OrderItem[] nftsToTransfer;
    }

    enum MatchOrdersType {
        OneToOneSpecific,
        OneToOneUnspecific,
        OneToMany
    }

    struct MatchOrders {
        OrderTypes.MakerOrder[] buys;
        OrderTypes.MakerOrder[] sells;
        OrderTypes.OrderItem[][] constructs;
        MatchOrdersType matchType;
    }

    struct Batch {
        ExternalFulfillments externalFulfillments;
        MatchOrders[] matches;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.14;

import { CostPerWord, ExtraGasBuffer, FreeMemoryPointerSlot, MemoryExpansionCoefficientShift, OneWord, OneWordShift, ThirtyOneBytes } from "./Constants.sol";

/**
 * @title LowLevelHelpers
 * @author 0age
 * @notice LowLevelHelpers contains logic for performing various low-level
 *         operations.
 */
contract LowLevelHelpers {
    /**
     * @dev Internal view function to revert and pass along the revert reason if
     *      data was returned by the last call and that the size of that data
     *      does not exceed the currently allocated memory size.
     */
    function _revertWithReasonIfOneIsReturned() internal view {
        assembly {
            // If it returned a message, bubble it up as long as sufficient gas
            // remains to do so:
            if returndatasize() {
                // Ensure that sufficient gas is available to copy returndata
                // while expanding memory where necessary. Start by computing
                // the word size of returndata and allocated memory.
                let returnDataWords := shr(
                    OneWordShift,
                    add(returndatasize(), ThirtyOneBytes)
                )

                // Note: use the free memory pointer in place of msize() to work
                // around a Yul warning that prevents accessing msize directly
                // when the IR pipeline is activated.
                let msizeWords := shr(
                    OneWordShift,
                    mload(FreeMemoryPointerSlot)
                )

                // Next, compute the cost of the returndatacopy.
                let cost := mul(CostPerWord, returnDataWords)

                // Then, compute cost of new memory allocation.
                if gt(returnDataWords, msizeWords) {
                    cost := add(
                        cost,
                        add(
                            mul(sub(returnDataWords, msizeWords), CostPerWord),
                            shr(
                                MemoryExpansionCoefficientShift,
                                sub(
                                    mul(returnDataWords, returnDataWords),
                                    mul(msizeWords, msizeWords)
                                )
                            )
                        )
                    )
                }

                // Finally, add a small constant and compare to gas remaining;
                // bubble up the revert data if enough gas is still available.
                if lt(add(cost, ExtraGasBuffer), gas()) {
                    // Copy returndata to memory; overwrite existing memory.
                    returndatacopy(0, 0, returndatasize())

                    // Revert, specifying memory region with copied returndata.
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @dev Internal view function to branchlessly select either the caller (if
     *      a supplied recipient is equal to zero) or the supplied recipient (if
     *      that recipient is a nonzero value).
     *
     * @param recipient The supplied recipient.
     *
     * @return updatedRecipient The updated recipient.
     */
    function _substituteCallerForEmptyRecipient(
        address recipient
    ) internal view returns (address updatedRecipient) {
        // Utilize assembly to perform a branchless operation on the recipient.
        assembly {
            // Add caller to recipient if recipient equals 0; otherwise add 0.
            updatedRecipient := add(recipient, mul(iszero(recipient), caller()))
        }
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    /**
     * @dev Internal pure function to compare two addresses without first
     *      masking them. Note that dirty upper bits will cause otherwise equal
     *      addresses to be recognized as unequal.
     *
     * @param a The first address.
     * @param b The second address
     *
     * @return areEqual A boolean representing whether the addresses are equal.
     */
    function _unmaskedAddressComparison(
        address a,
        address b
    ) internal pure returns (bool areEqual) {
        // Utilize assembly to perform the comparison without masking.
        assembly {
            areEqual := eq(a, b)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title OrderTypes
 * @author nneverlander. Twitter @nneverlander
 * @notice This library contains the order types used by the main exchange and complications
 */
library OrderTypes {
    /// @dev the tokenId and numTokens (==1 for ERC721)
    struct TokenInfo {
        uint256 tokenId;
        uint256 numTokens;
    }

    /// @dev an order item is a collection address and tokens from that collection
    struct OrderItem {
        address collection;
        TokenInfo[] tokens;
    }

    struct MakerOrder {
        ///@dev is order sell or buy
        bool isSellOrder;
        ///@dev signer of the order (maker address)
        address signer;
        ///@dev Constraints array contains the order constraints. Total constraints: 7. In order:
        // numItems - min (for buy orders) / max (for sell orders) number of items in the order
        // start price in wei
        // end price in wei
        // start time in block.timestamp
        // end time in block.timestamp
        // nonce of the order
        // max tx.gasprice in wei that a user is willing to pay for gas
        // 1 for trustedExecution, 0 or non-existent for not trustedExecution
        uint256[] constraints;
        ///@dev nfts array contains order items where each item is a collection and its tokenIds
        OrderItem[] nfts;
        ///@dev address of complication for trade execution (e.g. FlowOrderBookComplication), address of the currency (e.g., WETH)
        address[] execParams;
        ///@dev additional parameters like traits for trait orders, private sale buyer for OTC orders etc
        bytes extraParams;
        ///@dev the order signature uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
        bytes sig;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.14;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { EIP2098_allButHighestBitMask,
    OneWord, 
    OneWordShift, 
    BulkOrder_Typehash_Height_One,
    BulkOrder_Typehash_Height_Two,
    BulkOrder_Typehash_Height_Three,
    BulkOrder_Typehash_Height_Four,
    BulkOrder_Typehash_Height_Five,
    BulkOrder_Typehash_Height_Six,
    BulkOrder_Typehash_Height_Seven,
    BulkOrder_Typehash_Height_Eight,
    BulkOrder_Typehash_Height_Nine,
    BulkOrder_Typehash_Height_Ten,
    BulkOrder_Typehash_Height_Eleven,
    BulkOrder_Typehash_Height_Twelve,
    BulkOrder_Typehash_Height_Thirteen,
    BulkOrder_Typehash_Height_Fourteen,
    BulkOrder_Typehash_Height_Fifteen,
    BulkOrder_Typehash_Height_Sixteen,
    BulkOrder_Typehash_Height_Seventeen,
    BulkOrder_Typehash_Height_Eighteen,
    BulkOrder_Typehash_Height_Nineteen,
    BulkOrder_Typehash_Height_Twenty,
    BulkOrder_Typehash_Height_TwentyOne,
    BulkOrder_Typehash_Height_TwentyTwo,
    BulkOrder_Typehash_Height_TwentyThree,
    BulkOrder_Typehash_Height_TwentyFour } from "./Constants.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts
 */
contract SignatureChecker is LowLevelHelpers {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();

    /**
     * @notice Returns whether the signer matches the signed message
     * @param orderHash the hash containing the signed message
     * @param signer the signer address to confirm message validity
     * @param sig the signature
     * @param domainSeparator parameter to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 orderHash,
        address signer,
        bytes calldata sig,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        bytes32 originalDigest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, orderHash)
        );
        bytes32 digest;

        bytes memory extractedSignature;
        if (_isValidBulkOrderSize(sig)) {
            (orderHash, extractedSignature) = _computeBulkOrderProof(
                sig,
                orderHash
            );
            digest = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, orderHash)
            );
        } else {
            digest = originalDigest;
            extractedSignature = sig;
        }

        _assertValidSignature(
            signer,
            digest,
            originalDigest,
            sig,
            extractedSignature
        );

        return true;
    }

    /**
     * @dev Determines whether the specified bulk order size is valid.
     *
     * @param signature The signature of the bulk order to check.
     *
     * @return validLength True if bulk order size is valid, false otherwise.
     */
    function _isValidBulkOrderSize(
        bytes memory signature
    ) internal pure returns (bool validLength) {
        validLength =
            signature.length < 837 &&
            signature.length > 98 &&
            ((signature.length - 67) % 32) < 2;
    }

    /**
     * @dev Computes the bulk order hash for the specified proof and leaf. Note
     *      that if an index that exceeds the number of orders in the bulk order
     *      payload will instead "wrap around" and refer to an earlier index.
     *
     * @param proofAndSignature The proof and signature of the bulk order.
     * @param leaf              The leaf of the bulk order tree.
     *
     * @return bulkOrderHash The bulk order hash.
     * @return signature     The signature of the bulk order.
     */
    function _computeBulkOrderProof(
        bytes memory proofAndSignature,
        bytes32 leaf
    ) internal pure returns (bytes32 bulkOrderHash, bytes memory signature) {
        bytes32 root = leaf;

        // proofAndSignature with odd length is a compact signature (64 bytes).
        uint256 length = proofAndSignature.length % 2 == 0 ? 65 : 64;

        // Create a new array of bytes equal to the length of the signature.
        signature = new bytes(length);

        // Iterate over each byte in the signature.
        for (uint256 i = 0; i < length; ++i) {
            // Assign the byte from the proofAndSignature to the signature.
            signature[i] = proofAndSignature[i];
        }

        // Compute the key by extracting the next three bytes from the
        // proofAndSignature.
        uint256 key = (((uint256(uint8(proofAndSignature[length])) << 16) |
            ((uint256(uint8(proofAndSignature[length + 1]))) << 8)) |
            (uint256(uint8(proofAndSignature[length + 2]))));

        uint256 height = (proofAndSignature.length - length) / 32;

        // Create an array of bytes32 to hold the proof elements.
        bytes32[] memory proofElements = new bytes32[](height);

        // Iterate over each proof element.
        for (uint256 elementIndex = 0; elementIndex < height; ++elementIndex) {
            // Compute the starting index for the current proof element.
            uint256 start = (length + 3) + (elementIndex * 32);

            // Create a new array of bytes to hold the current proof element.
            bytes memory buffer = new bytes(32);

            // Iterate over each byte in the proof element.
            for (uint256 i = 0; i < 32; ++i) {
                // Assign the byte from the proofAndSignature to the buffer.
                buffer[i] = proofAndSignature[start + i];
            }

            // Decode the current proof element from the buffer and assign it to
            // the proofElements array.
            proofElements[elementIndex] = abi.decode(buffer, (bytes32));
        }

        // Iterate over each proof element.
        for (uint256 i = 0; i < proofElements.length; ++i) {
            // Retrieve the proof element.
            bytes32 proofElement = proofElements[i];

            // Check if the current bit of the key is set.
            if ((key >> i) % 2 == 0) {
                // If the current bit is not set, then concatenate the root and
                // the proof element, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(root, proofElement));
            } else {
                // If the current bit is set, then concatenate the proof element
                // and the root, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(proofElement, root));
            }
        }

        // Compute the bulk order hash and return it.
        bulkOrderHash = keccak256(
            abi.encodePacked(_lookupBulkOrderTypehash(height), root)
        );

        // Return the signature.
        return (bulkOrderHash, signature);
    }



    /**
     * @dev Internal pure function to look up one of twenty-four potential bulk
     *      order typehash constants based on the height of the bulk order tree.
     *      Note that values between one and twenty-four are supported, which is
     *      enforced by _isValidBulkOrderSize.
     *
     * @param _treeHeight The height of the bulk order tree. The value must be
     *                    between one and twenty-four.
     *
     * @return _typeHash The EIP-712 typehash for the bulk order type with the
     *                   given height.
     */
    function _lookupBulkOrderTypehash(uint256 _treeHeight)
        internal
        pure
        returns (bytes32 _typeHash)
    {
        // Utilize assembly to efficiently retrieve correct bulk order typehash.
        assembly {
            // Use a Yul function to enable use of the `leave` keyword
            // to stop searching once the appropriate type hash is found.
            function lookupTypeHash(treeHeight) -> typeHash {
                // Handle tree heights one through eight.
                if lt(treeHeight, 9) {
                    // Handle tree heights one through four.
                    if lt(treeHeight, 5) {
                        // Handle tree heights one and two.
                        if lt(treeHeight, 3) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 1),
                                BulkOrder_Typehash_Height_One,
                                BulkOrder_Typehash_Height_Two
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height three and four via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 3),
                            BulkOrder_Typehash_Height_Three,
                            BulkOrder_Typehash_Height_Four
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height five and six.
                    if lt(treeHeight, 7) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 5),
                            BulkOrder_Typehash_Height_Five,
                            BulkOrder_Typehash_Height_Six
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height seven and eight via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 7),
                        BulkOrder_Typehash_Height_Seven,
                        BulkOrder_Typehash_Height_Eight
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height nine through sixteen.
                if lt(treeHeight, 17) {
                    // Handle tree height nine through twelve.
                    if lt(treeHeight, 13) {
                        // Handle tree height nine and ten.
                        if lt(treeHeight, 11) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 9),
                                BulkOrder_Typehash_Height_Nine,
                                BulkOrder_Typehash_Height_Ten
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height eleven and twelve via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 11),
                            BulkOrder_Typehash_Height_Eleven,
                            BulkOrder_Typehash_Height_Twelve
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height thirteen and fourteen.
                    if lt(treeHeight, 15) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 13),
                            BulkOrder_Typehash_Height_Thirteen,
                            BulkOrder_Typehash_Height_Fourteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }
                    // Handle height fifteen and sixteen via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 15),
                        BulkOrder_Typehash_Height_Fifteen,
                        BulkOrder_Typehash_Height_Sixteen
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height seventeen through twenty.
                if lt(treeHeight, 21) {
                    // Handle tree height seventeen and eighteen.
                    if lt(treeHeight, 19) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 17),
                            BulkOrder_Typehash_Height_Seventeen,
                            BulkOrder_Typehash_Height_Eighteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height nineteen and twenty via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 19),
                        BulkOrder_Typehash_Height_Nineteen,
                        BulkOrder_Typehash_Height_Twenty
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height twenty-one and twenty-two.
                if lt(treeHeight, 23) {
                    // Utilize branchless logic to determine typehash.
                    typeHash := ternary(
                        eq(treeHeight, 21),
                        BulkOrder_Typehash_Height_TwentyOne,
                        BulkOrder_Typehash_Height_TwentyTwo
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle height twenty-three & twenty-four w/ branchless logic.
                typeHash := ternary(
                    eq(treeHeight, 23),
                    BulkOrder_Typehash_Height_TwentyThree,
                    BulkOrder_Typehash_Height_TwentyFour
                )

                // Exit the function once typehash has been located.
                leave
            }

            // Implement ternary conditional using branchless logic.
            function ternary(cond, ifTrue, ifFalse) -> c {
                c := xor(ifFalse, mul(cond, xor(ifFalse, ifTrue)))
            }

            // Look up the typehash using the supplied tree height.
            _typeHash := lookupTypeHash(_treeHeight)
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param signer            The signer for the order.
     * @param digest            The digest to verify signature against.
     * @param originalDigest    The original digest to verify signature against.
     * @param originalSignature The original signature.
     * @param signature         A signature from the signer indicating that the
     *                          order has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes32 originalDigest,
        bytes memory originalSignature,
        bytes memory signature
    ) internal view {
        if (signer.code.length > 0) {
            // If signer is a contract, try verification via EIP-1271.
            if (
                IERC1271(signer).isValidSignature(
                    originalDigest,
                    originalSignature
                ) != 0x1626ba7e
            ) {
                revert BadContractSignature();
            }

            // Return early if the ERC-1271 signature check succeeded.
            return;
        } else {
            _assertValidSignatureHelper(signer, digest, signature);
        }
    }

    function _assertValidSignatureHelper(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length == 64) {
            // If signature contains 64 bytes, parse as EIP-2098 sig. (r+s&v)
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            // Decode signature into r, vs.
            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            // Decompose vs into s and v.
            s = vs & EIP2098_allButHighestBitMask;

            // If the highest bit is set, v = 28, otherwise v = 27.
            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
        } else {
            revert InvalidSignature();
        }

        // Attempt to recover signer using the digest and signature parameters.
        address recoveredSigner = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155Reservoir is ERC1155 {
    constructor() ERC1155("https://mock.com") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId, 1, "");
    }

    function mintMany(uint256 tokenId, uint256 amount) external {
        _mint(msg.sender, tokenId, amount, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockERC20", "MCK20") {
        uint256 supply = 1_000_000 * (10 ** decimals());
        _mint(msg.sender, supply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20Reservoir is ERC20 {
    constructor() ERC20("Mock", "MOCK") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC721 is ERC721URIStorage, Ownable {
    uint256 public numMints;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        for (uint256 i = 0; i < 100; i++) {
            _safeMint(msg.sender, numMints++);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721Reservoir is ERC721 {
    constructor() ERC721("Mock", "MOCK") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title FlowStaker
 * @author nneverlander. Twitter @nneverlander
 * @notice The staker contract that allows people to stake tokens and earn voting power to be used in curation and possibly other places
 */
contract FlowStaker is Ownable, Pausable {
    struct StakeAmount {
        uint256 amount;
        uint256 timestamp;
    }

    enum Duration {
        NONE,
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS
    }

    enum StakeLevel {
        NONE,
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    ///@dev Storage variable to keep track of the staker's staked duration and amounts
    mapping(address => mapping(Duration => StakeAmount))
        public userstakedAmounts;

    ///@dev Flow token address
    // solhint-disable var-name-mixedcase
    address public immutable FLOW_TOKEN;

    ///@dev Flow treasury address - will be a EOA/multisig
    address public flowTreasury;

    /**@dev Power levels to reach the specified stake thresholds. Users can reach these levels 
          either by staking the specified number of tokens for no duration or a less number of tokens but with higher durations.
          See getUserStakePower() to see how users can reach these levels.
  */
    uint32 public bronzeStakeThreshold = 1000;
    uint32 public silverStakeThreshold = 5000;
    uint32 public goldStakeThreshold = 10000;
    uint32 public platinumStakeThreshold = 20000;

    ///@dev Penalties if staked tokens are rageQuit early. Example: If 100 tokens are staked for twelve months but rageQuit right away,
    /// the user will get back 100/4 tokens.
    uint32 public threeMonthPenalty = 2;
    uint32 public sixMonthPenalty = 3;
    uint32 public twelveMonthPenalty = 4;

    event Staked(address indexed user, uint256 amount, Duration duration);
    event DurationChanged(
        address indexed user,
        uint256 amount,
        Duration oldDuration,
        Duration newDuration
    );
    event UnStaked(address indexed user, uint256 amount);
    event RageQuit(address indexed user, uint256 totalToUser, uint256 penalty);
    event RageQuitPenaltiesUpdated(
        uint32 threeMonth,
        uint32 sixMonth,
        uint32 twelveMonth
    );
    event StakeLevelThresholdUpdated(StakeLevel stakeLevel, uint32 threshold);

    /**
    @param _tokenAddress The address of the Flow token contract
    @param _flowTreasury The address of the Flow treasury used for sending rageQuit penalties
   */
    constructor(address _tokenAddress, address _flowTreasury) {
        FLOW_TOKEN = _tokenAddress;
        flowTreasury = _flowTreasury;
    }

    // =================================================== USER FUNCTIONS =======================================================

    /**
     * @notice Stake tokens for a specified duration
     * @dev Tokens are transferred from the user to this contract
     * @param amount Amount of tokens to stake
     * @param duration Duration of the stake
     */
    function stake(uint256 amount, Duration duration) external whenNotPaused {
        require(amount != 0, "stake amount cant be 0");
        // update storage
        userstakedAmounts[msg.sender][duration].amount += amount;
        userstakedAmounts[msg.sender][duration].timestamp = block.timestamp;
        // perform transfer; no need for safeTransferFrom since we know the implementation of the token contract
        IERC20(FLOW_TOKEN).transferFrom(msg.sender, address(this), amount);
        // emit event
        emit Staked(msg.sender, amount, duration);
    }

    /**
     * @notice Change duration of staked tokens
     * @dev Duration can be changed from low to high but not from high to low. State updates are performed
     * @param amount Amount of tokens to change duration
     * @param oldDuration Old duration of the stake
     * @param newDuration New duration of the stake
     */
    function changeDuration(
        uint256 amount,
        Duration oldDuration,
        Duration newDuration
    ) external whenNotPaused {
        require(amount != 0, "amount cant be 0");
        require(
            userstakedAmounts[msg.sender][oldDuration].amount >= amount,
            "insuf stake to change duration"
        );
        require(newDuration > oldDuration, "new duration must exceed old");

        // update storage
        userstakedAmounts[msg.sender][oldDuration].amount -= amount;
        userstakedAmounts[msg.sender][newDuration].amount += amount;
        // update timestamp for new duration
        userstakedAmounts[msg.sender][newDuration].timestamp = block.timestamp;
        // only update old duration timestamp if old duration amount is 0
        if (userstakedAmounts[msg.sender][oldDuration].amount == 0) {
            delete userstakedAmounts[msg.sender][oldDuration].timestamp;
        }
        // emit event
        emit DurationChanged(msg.sender, amount, oldDuration, newDuration);
    }

    /**
     * @notice Unstake tokens
     * @dev Storage updates are done for each stake level. See _updateUserStakedAmounts for more details
     * @param amount Amount of tokens to unstake
     */
    function unstake(uint256 amount) external whenNotPaused {
        require(amount != 0, "unstake amount cant be 0");
        uint256 noVesting = userstakedAmounts[msg.sender][Duration.NONE].amount;
        uint256 vestedThreeMonths = getVestedAmount(
            msg.sender,
            Duration.THREE_MONTHS
        );
        uint256 vestedSixMonths = getVestedAmount(
            msg.sender,
            Duration.SIX_MONTHS
        );
        uint256 vestedTwelveMonths = getVestedAmount(
            msg.sender,
            Duration.TWELVE_MONTHS
        );
        uint256 totalVested = noVesting +
            vestedThreeMonths +
            vestedSixMonths +
            vestedTwelveMonths;
        require(totalVested >= amount, "insufficient balance to unstake");

        // update storage
        _updateUserStakedAmounts(
            msg.sender,
            amount,
            noVesting,
            vestedThreeMonths,
            vestedSixMonths,
            vestedTwelveMonths
        );
        // perform transfer
        IERC20(FLOW_TOKEN).transfer(msg.sender, amount);
        // emit event
        emit UnStaked(msg.sender, amount);
    }

    /**
     * @notice Ragequit tokens. Applies penalties for unvested tokens
     */
    function rageQuit() external {
        (uint256 totalToUser, uint256 penalty) = getRageQuitAmounts(msg.sender);
        // update storage
        _clearUserStakedAmounts(msg.sender);
        // perform transfers
        IERC20(FLOW_TOKEN).transfer(msg.sender, totalToUser);
        IERC20(FLOW_TOKEN).transfer(flowTreasury, penalty);
        // emit event
        emit RageQuit(msg.sender, totalToUser, penalty);
    }

    // ====================================================== VIEW FUNCTIONS ======================================================

    /**
     * @notice Get total staked tokens for a user for all durations
     * @param user address of the user
     * @return total amount of tokens staked by the user
     */
    function getUserTotalStaked(address user) external view returns (uint256) {
        return
            userstakedAmounts[user][Duration.NONE].amount +
            userstakedAmounts[user][Duration.THREE_MONTHS].amount +
            userstakedAmounts[user][Duration.SIX_MONTHS].amount +
            userstakedAmounts[user][Duration.TWELVE_MONTHS].amount;
    }

    /**
     * @notice Get total vested tokens for a user for all durations
     * @param user address of the user
     * @return total amount of vested tokens for the user
     */
    function getUserTotalVested(address user) external view returns (uint256) {
        return
            getVestedAmount(user, Duration.NONE) +
            getVestedAmount(user, Duration.THREE_MONTHS) +
            getVestedAmount(user, Duration.SIX_MONTHS) +
            getVestedAmount(user, Duration.TWELVE_MONTHS);
    }

    /**
     * @notice Gets rageQuit amounts for a user after applying penalties
     * @dev Penalty amounts are sent to Flow treasury
     * @param user address of the user
     * @return Total amount to user and penalties
     */
    function getRageQuitAmounts(
        address user
    ) public view returns (uint256, uint256) {
        uint256 noLock = userstakedAmounts[user][Duration.NONE].amount;
        uint256 threeMonthLock = userstakedAmounts[user][Duration.THREE_MONTHS]
            .amount;
        uint256 sixMonthLock = userstakedAmounts[user][Duration.SIX_MONTHS]
            .amount;
        uint256 twelveMonthLock = userstakedAmounts[user][
            Duration.TWELVE_MONTHS
        ].amount;

        uint256 totalStaked = noLock +
            threeMonthLock +
            sixMonthLock +
            twelveMonthLock;
        require(totalStaked != 0, "nothing staked to rage quit");

        uint256 threeMonthVested = getVestedAmount(user, Duration.THREE_MONTHS);
        uint256 sixMonthVested = getVestedAmount(user, Duration.SIX_MONTHS);
        uint256 twelveMonthVested = getVestedAmount(
            user,
            Duration.TWELVE_MONTHS
        );

        uint256 totalVested = noLock +
            threeMonthVested +
            sixMonthVested +
            twelveMonthVested;

        uint256 totalToUser = totalVested +
            ((threeMonthLock - threeMonthVested) / threeMonthPenalty) +
            ((sixMonthLock - sixMonthVested) / sixMonthPenalty) +
            ((twelveMonthLock - twelveMonthVested) / twelveMonthPenalty);

        uint256 penalty = totalStaked - totalToUser;

        return (totalToUser, penalty);
    }

    /**
     * @notice Gets a user's stake level
     * @param user address of the user
     * @return StakeLevel
     */
    function getUserStakeLevel(
        address user
    ) external view returns (StakeLevel) {
        uint256 totalPower = getUserStakePower(user);

        if (totalPower <= bronzeStakeThreshold) {
            return StakeLevel.NONE;
        } else if (totalPower <= silverStakeThreshold) {
            return StakeLevel.BRONZE;
        } else if (totalPower <= goldStakeThreshold) {
            return StakeLevel.SILVER;
        } else if (totalPower <= platinumStakeThreshold) {
            return StakeLevel.GOLD;
        } else {
            return StakeLevel.PLATINUM;
        }
    }

    /**
     * @notice Gets a user stake power. Used to determine voting power in curating collections and possibly other places
     * @dev Tokens staked for higher duration apply a multiplier
     * @param user address of the user
     * @return user stake power
     */
    function getUserStakePower(address user) public view returns (uint256) {
        return
            ((userstakedAmounts[user][Duration.NONE].amount) +
                (userstakedAmounts[user][Duration.THREE_MONTHS].amount * 2) +
                (userstakedAmounts[user][Duration.SIX_MONTHS].amount * 3) +
                (userstakedAmounts[user][Duration.TWELVE_MONTHS].amount * 4)) /
            (1e18);
    }

    /**
     * @notice Returns staking info for a user's staked amounts for different durations
     * @param user address of the user
     * @return Staking amounts for different durations
     */
    function getStakingInfo(
        address user
    ) external view returns (StakeAmount[] memory) {
        StakeAmount[] memory stakingInfo = new StakeAmount[](4);
        stakingInfo[0] = userstakedAmounts[user][Duration.NONE];
        stakingInfo[1] = userstakedAmounts[user][Duration.THREE_MONTHS];
        stakingInfo[2] = userstakedAmounts[user][Duration.SIX_MONTHS];
        stakingInfo[3] = userstakedAmounts[user][Duration.TWELVE_MONTHS];
        return stakingInfo;
    }

    /**
     * @notice Returns vested amount for a user for a given duration
     * @param user address of the user
     * @param duration the duration
     * @return Vested amount for the given duration
     */
    function getVestedAmount(
        address user,
        Duration duration
    ) public view returns (uint256) {
        uint256 timestamp = userstakedAmounts[user][duration].timestamp;
        // short circuit if no vesting for this duration
        if (timestamp == 0) {
            return 0;
        }
        uint256 durationInSeconds = _getDurationInSeconds(duration);
        uint256 secondsSinceStake = block.timestamp - timestamp;
        uint256 amount = userstakedAmounts[user][duration].amount;
        return secondsSinceStake >= durationInSeconds ? amount : 0;
    }

    // ====================================================== INTERNAL FUNCTIONS ================================================

    function _getDurationInSeconds(
        Duration duration
    ) internal pure returns (uint256) {
        if (duration == Duration.THREE_MONTHS) {
            return 90 days;
        } else if (duration == Duration.SIX_MONTHS) {
            return 180 days;
        } else if (duration == Duration.TWELVE_MONTHS) {
            return 360 days;
        } else {
            return 0 seconds;
        }
    }

    /** @notice Update user staked amounts for different duration on unstake
     * @dev A more elegant recursive function is possible but this is more gas efficient
     */
    function _updateUserStakedAmounts(
        address user,
        uint256 amount,
        uint256 noVesting,
        uint256 vestedThreeMonths,
        uint256 vestedSixMonths,
        uint256 vestedTwelveMonths
    ) internal {
        if (amount > noVesting) {
            delete userstakedAmounts[user][Duration.NONE].amount;
            delete userstakedAmounts[user][Duration.NONE].timestamp;
            amount = amount - noVesting;
            if (amount > vestedThreeMonths) {
                if (vestedThreeMonths != 0) {
                    delete userstakedAmounts[user][Duration.THREE_MONTHS]
                        .amount;
                    delete userstakedAmounts[user][Duration.THREE_MONTHS]
                        .timestamp;
                    amount = amount - vestedThreeMonths;
                }
                if (amount > vestedSixMonths) {
                    if (vestedSixMonths != 0) {
                        delete userstakedAmounts[user][Duration.SIX_MONTHS]
                            .amount;
                        delete userstakedAmounts[user][Duration.SIX_MONTHS]
                            .timestamp;
                        amount = amount - vestedSixMonths;
                    }
                    if (amount > vestedTwelveMonths) {
                        revert("should not happen");
                    } else {
                        userstakedAmounts[user][Duration.TWELVE_MONTHS]
                            .amount -= amount;
                        if (
                            userstakedAmounts[user][Duration.TWELVE_MONTHS]
                                .amount == 0
                        ) {
                            delete userstakedAmounts[user][
                                Duration.TWELVE_MONTHS
                            ].timestamp;
                        }
                    }
                } else {
                    userstakedAmounts[user][Duration.SIX_MONTHS]
                        .amount -= amount;
                    if (
                        userstakedAmounts[user][Duration.SIX_MONTHS].amount == 0
                    ) {
                        delete userstakedAmounts[user][Duration.SIX_MONTHS]
                            .timestamp;
                    }
                }
            } else {
                userstakedAmounts[user][Duration.THREE_MONTHS].amount -= amount;
                if (
                    userstakedAmounts[user][Duration.THREE_MONTHS].amount == 0
                ) {
                    delete userstakedAmounts[user][Duration.THREE_MONTHS]
                        .timestamp;
                }
            }
        } else {
            userstakedAmounts[user][Duration.NONE].amount -= amount;
            if (userstakedAmounts[user][Duration.NONE].amount == 0) {
                delete userstakedAmounts[user][Duration.NONE].timestamp;
            }
        }
    }

    /// @dev clears staking info for a user on rageQuit
    function _clearUserStakedAmounts(address user) internal {
        // clear amounts
        delete userstakedAmounts[user][Duration.NONE].amount;
        delete userstakedAmounts[user][Duration.THREE_MONTHS].amount;
        delete userstakedAmounts[user][Duration.SIX_MONTHS].amount;
        delete userstakedAmounts[user][Duration.TWELVE_MONTHS].amount;

        // clear timestamps
        delete userstakedAmounts[user][Duration.NONE].timestamp;
        delete userstakedAmounts[user][Duration.THREE_MONTHS].timestamp;
        delete userstakedAmounts[user][Duration.SIX_MONTHS].timestamp;
        delete userstakedAmounts[user][Duration.TWELVE_MONTHS].timestamp;
    }

    // ====================================================== ADMIN FUNCTIONS ================================================

    /// @dev Admin function to update stake level thresholds
    function updateStakeLevelThreshold(
        StakeLevel stakeLevel,
        uint32 threshold
    ) external onlyOwner {
        if (stakeLevel == StakeLevel.BRONZE) {
            bronzeStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.SILVER) {
            silverStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.GOLD) {
            goldStakeThreshold = threshold;
        } else if (stakeLevel == StakeLevel.PLATINUM) {
            platinumStakeThreshold = threshold;
        }
        emit StakeLevelThresholdUpdated(stakeLevel, threshold);
    }

    /// @dev Admin function to update rageQuit penalties
    function updatePenalties(
        uint32 _threeMonthPenalty,
        uint32 _sixMonthPenalty,
        uint32 _twelveMonthPenalty
    ) external onlyOwner {
        require(
            _threeMonthPenalty > 0 && _threeMonthPenalty < threeMonthPenalty,
            "invalid value"
        );
        require(
            _sixMonthPenalty > 0 && _sixMonthPenalty < sixMonthPenalty,
            "invalid value"
        );
        require(
            _twelveMonthPenalty > 0 && _twelveMonthPenalty < twelveMonthPenalty,
            "invalid value"
        );
        threeMonthPenalty = _threeMonthPenalty;
        sixMonthPenalty = _sixMonthPenalty;
        twelveMonthPenalty = _twelveMonthPenalty;
        emit RageQuitPenaltiesUpdated(
            threeMonthPenalty,
            sixMonthPenalty,
            twelveMonthPenalty
        );
    }

    /// @dev Admin function to update Flow treasury
    function updateFlowTreasury(address _flowTreasury) external onlyOwner {
        require(_flowTreasury != address(0), "invalid address");
        flowTreasury = _flowTreasury;
    }

    /// @dev Admin function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Admin function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time
pragma solidity 0.8.14;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Snapshot } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title FlowTokens
 * @author nneverlander. Twitter @nneverlander
 * @notice The Flow Token ($FLOW).
 */
contract FlowToken is
    ERC20("Flow", "FLOW"),
    ERC20Permit("Flow"),
    ERC20Burnable,
    ERC20Snapshot,
    ERC20Votes
{
    address public admin;

    event AdminChanged(address oldAdmin, address newAdmin);

    /**
    @param _admin The address of the admin who will be sent the minted tokens
    @param supply Initial supply of the token
   */
    constructor(address _admin, uint256 supply) {
        admin = _admin;
        // mint initial supply
        _mint(admin, supply);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    // =============================================== ADMIN FUNCTIONS =========================================================

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "zero address");
        admin = newAdmin;
        emit AdminChanged(admin, newAdmin);
    }

    // =============================================== HOOKS =========================================================

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        ERC20Snapshot._beforeTokenTransfer(from, to, amount);
    }

    // =============================================== REQUIRED OVERRIDES =========================================================
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}