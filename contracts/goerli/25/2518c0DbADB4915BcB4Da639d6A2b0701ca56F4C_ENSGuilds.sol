pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

import "./interfaces/IENSGuilds.sol";
import "../feePolicies/FeePolicy.sol";
import "../tagsAuthPolicies/ITagsAuthPolicy.sol";
import "./mixins/ENSResolver.sol";
import "./mixins/ENSGuildsToken.sol";
import "./mixins/ENSGuildsHumanized.sol";

contract ENSGuilds is IENSGuilds, ENSGuildsHumanized, ENSGuildsToken, ENSResolver, ReentrancyGuard {
    struct GuildInfo {
        address admin;
        FeePolicy feePolicy;
        ITagsAuthPolicy tagsAuthPolicy;
        bool active;
        bool deregistered;
    }

    using ERC165Checker for address;

    /** State */
    ENS public ensRegistry;
    mapping(bytes32 => GuildInfo) public guilds;

    /** Errors */
    error AlreadyRegistered();
    error ENSGuildsIsNotRegisteredOperator();
    error NotDomainOwner();
    error InvalidPolicy(address);
    error GuildNotActive();
    error ClaimUnauthorized();
    error RevokeUnauthorized();
    error GuildAdminOnly();
    error TagAlreadyClaimed();
    error FeeError();

    modifier onlyGuildAdmin(bytes32 guildHash) {
        if (guilds[guildHash].admin != _msgSender()) {
            revert GuildAdminOnly();
        }
        _;
    }

    constructor(string memory defaultTokenMetadataUri, ENS _ensRegistry) ERC1155(defaultTokenMetadataUri) {
        ensRegistry = _ensRegistry;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ENSResolver, ENSGuildsToken, IERC165) returns (bool) {
        return
            interfaceId == type(IENSGuilds).interfaceId ||
            ENSResolver.supportsInterface(interfaceId) ||
            ENSGuildsToken.supportsInterface(interfaceId) ||
            ERC165.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function registerGuild(
        bytes32 ensNode,
        address admin,
        address feePolicy,
        address tagsAuthPolicy
    ) public override(ENSGuildsHumanized, IENSGuilds) {
        // Check caller is owner of domain
        if (ensRegistry.owner(ensNode) != _msgSender()) {
            revert NotDomainOwner();
        }

        // Check guild not yet registered
        if (address(guilds[ensNode].feePolicy) != address(0)) {
            revert AlreadyRegistered();
        }

        // Check ENSGuilds contract has been configured as ENS resolver for the guild
        if (!ensRegistry.isApprovedForAll(_msgSender(), address(this))) {
            revert ENSGuildsIsNotRegisteredOperator();
        }

        // Check for valid fee/tagsAuth policies
        if (!feePolicy.supportsInterface(type(FeePolicy).interfaceId)) {
            revert InvalidPolicy(feePolicy);
        }
        if (!tagsAuthPolicy.supportsInterface(type(ITagsAuthPolicy).interfaceId)) {
            revert InvalidPolicy(tagsAuthPolicy);
        }

        guilds[ensNode] = GuildInfo({
            admin: admin,
            feePolicy: FeePolicy(feePolicy),
            tagsAuthPolicy: ITagsAuthPolicy(tagsAuthPolicy),
            active: true,
            deregistered: false
        });

        emit Registered(ensNode);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function deregisterGuild(bytes32 ensNode) public override(ENSGuildsHumanized, IENSGuilds) onlyGuildAdmin(ensNode) {
        delete guilds[ensNode];
        guilds[ensNode].deregistered = true;
        emit Deregistered(ensNode);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function claimGuildTag(
        bytes32 guildEnsNode,
        bytes32 tagHash,
        address recipient,
        bytes calldata extraClaimArgs
    ) public payable override(ENSGuildsHumanized, IENSGuilds) nonReentrant {
        // assert guild is not frozen
        if (!guilds[guildEnsNode].active) {
            revert GuildNotActive();
        }

        // check tag not already registered
        bytes32 ensNode = keccak256(abi.encodePacked(guildEnsNode, tagHash));
        if (ensRegistry.owner(ensNode) != address(0)) {
            revert TagAlreadyClaimed();
        }

        // check caller is authorized to claim tag
        ITagsAuthPolicy auth = guilds[guildEnsNode].tagsAuthPolicy;
        if (!auth.canClaimTag(guildEnsNode, tagHash, _msgSender(), recipient, extraClaimArgs)) {
            revert ClaimUnauthorized();
        }

        // fees
        (address feeToken, uint256 fee, address feePaidTo) = guilds[guildEnsNode].feePolicy.tagClaimFee(
            guildEnsNode,
            tagHash,
            _msgSender(),
            extraClaimArgs
        );
        if (fee != 0) {
            if (feeToken == address(0)) {
                if (msg.value != fee) {
                    revert FeeError();
                }
                // solhint-disable-next-line avoid-low-level-calls
                (bool sent, ) = feePaidTo.call{ value: msg.value }("");
                if (!sent) revert FeeError();
            } else {
                try IERC20(feeToken).transferFrom(_msgSender(), feePaidTo, fee) returns (bool sent) {
                    if (!sent) revert FeeError();
                } catch {
                    revert FeeError();
                }
            }
        }

        // NFT mint
        _mintNewGuildToken(guildEnsNode, tagHash, recipient);

        // inform auth contract that tag was claimed, then revoke an existing tag if instructed
        bytes32 tagToRevoke = auth.onTagClaimed(guildEnsNode, tagHash, _msgSender(), recipient, extraClaimArgs);
        if (tagToRevoke != bytes32(0)) {
            _revokeTag(guildEnsNode, tagToRevoke);
        }

        // Register this new name in ENS
        ensRegistry.setSubnodeRecord(guildEnsNode, tagHash, address(this), address(this), 0);

        // Set forward record in ENS resolver
        _setEnsForwardRecord(ensNode, recipient);

        emit TagClaimed(guildEnsNode, tagHash, recipient);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function claimGuildTagsBatch(
        bytes32 guildEnsNode,
        bytes32[] calldata tagHashes,
        address[] calldata recipients,
        bytes[] calldata extraClaimArgs
    ) external payable override {
        for (uint i = 0; i < tagHashes.length; i++) {
            claimGuildTag(guildEnsNode, tagHashes[i], recipients[i], extraClaimArgs[i]);
        }
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function guildAdmin(bytes32 guildHash) public view override(ENSGuildsHumanized, IENSGuilds) returns (address) {
        return guilds[guildHash].admin;
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function revokeGuildTag(
        bytes32 guildEnsNode,
        bytes32 tagHash,
        bytes calldata extraData
    ) public override(ENSGuildsHumanized, IENSGuilds) nonReentrant {
        GuildInfo storage guild = guilds[guildEnsNode];

        // revoke authorized?
        ITagsAuthPolicy auth = guilds[guildEnsNode].tagsAuthPolicy;
        if (!guild.deregistered && !auth.tagCanBeRevoked(_msgSender(), guildEnsNode, tagHash, extraData)) {
            revert RevokeUnauthorized();
        }
        _revokeTag(guildEnsNode, tagHash);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function revokeGuildTagsBatch(
        bytes32 guildHash,
        bytes32[] calldata tagHashes,
        bytes[] calldata extraData
    ) external override {
        for (uint i = 0; i < tagHashes.length; i++) {
            revokeGuildTag(guildHash, tagHashes[i], extraData[i]);
        }
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function updateGuildFeePolicy(
        bytes32 guildEnsNode,
        address feePolicy
    ) public override(ENSGuildsHumanized, IENSGuilds) onlyGuildAdmin(guildEnsNode) {
        if (!feePolicy.supportsInterface(type(FeePolicy).interfaceId)) {
            revert InvalidPolicy(feePolicy);
        }
        guilds[guildEnsNode].feePolicy = FeePolicy(feePolicy);
        emit FeePolicyUpdated(guildEnsNode, feePolicy);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function updateGuildTagsAuthPolicy(
        bytes32 guildEnsNode,
        address tagsAuthPolicy
    ) public override(ENSGuildsHumanized, IENSGuilds) onlyGuildAdmin(guildEnsNode) {
        if (!tagsAuthPolicy.supportsInterface(type(ITagsAuthPolicy).interfaceId)) {
            revert InvalidPolicy(tagsAuthPolicy);
        }
        guilds[guildEnsNode].tagsAuthPolicy = ITagsAuthPolicy(tagsAuthPolicy);
        emit TagsAuthPolicyUpdated(guildEnsNode, tagsAuthPolicy);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function transferGuildAdmin(
        bytes32 guildEnsNode,
        address newAdmin
    ) public override(ENSGuildsHumanized, IENSGuilds) onlyGuildAdmin(guildEnsNode) {
        guilds[guildEnsNode].admin = newAdmin;
        emit AdminTransferred(guildEnsNode, newAdmin);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function setGuildTokenUriTemplate(
        bytes32 guildEnsNode,
        string calldata uriTemplate
    ) public override(ENSGuildsHumanized, IENSGuilds) onlyGuildAdmin(guildEnsNode) {
        _setGuildTokenURITemplate(guildEnsNode, uriTemplate);
        emit TokenUriTemplateSet(guildEnsNode, uriTemplate);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function setGuildActive(
        bytes32 guildEnsNode,
        bool active
    ) public override(ENSGuildsHumanized, IENSGuilds) onlyGuildAdmin(guildEnsNode) {
        guilds[guildEnsNode].active = active;
        emit SetActive(guildEnsNode, active);
    }

    /**
     * @inheritdoc IENSGuilds
     */
    function tagOwner(
        bytes32 guildEnsNode,
        bytes32 tagHash
    ) public view override(ENSGuildsHumanized, IENSGuilds) returns (address) {
        bytes32 tagEnsNode = keccak256(abi.encodePacked(guildEnsNode, tagHash));
        // if ENSGuilds is not the owner of the tag's ENS node, then the tag itself is not valid
        // and therefore has no owner
        if (ensRegistry.owner(tagEnsNode) != address(this)) {
            return address(0);
        }
        return addr(tagEnsNode);
    }

    function _revokeTag(bytes32 guildEnsNode, bytes32 tagHash) private {
        address _tagOwner = tagOwner(guildEnsNode, tagHash);

        // check that tag exists
        if (_tagOwner == address(0)) {
            revert RevokeUnauthorized();
        }

        ensRegistry.setSubnodeRecord(guildEnsNode, tagHash, address(0), address(0), 0);
        _burnGuildToken(guildEnsNode, tagHash, _tagOwner);

        emit TagRevoked(guildEnsNode, tagHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol";

interface IENSGuilds is IAddrResolver, IAddressResolver, IERC1155MetadataURI {
    /** Events */
    event Registered(bytes32 indexed guildHash);
    event Deregistered(bytes32 indexed guildHash);
    event TagClaimed(bytes32 indexed guildId, bytes32 indexed tagHash, address recipient);
    event TagRevoked(bytes32 indexed guildId, bytes32 indexed tagHash);
    event FeePolicyUpdated(bytes32 indexed guildId, address feePolicy);
    event TagsAuthPolicyUpdated(bytes32 indexed guildId, address tagsAuthPolicy);
    event AdminTransferred(bytes32 indexed guildId, address newAdmin);
    event SetActive(bytes32 indexed guildId, bool active);
    event TokenUriTemplateSet(bytes32 indexed guildId, string uriTemplate);

    /* Functions */

    /**
     * @notice Registers a new guild from an existing ENS domain.
     * Caller must be the ENS node's owner and ENSGuilds must have been designated an "operator" for the caller.
     * @param guildHash The ENS namehash of the guild's domain
     * @param guildAdmin The address that will administrate this guild
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     * @param tagsAuthPolicy The address of an implementaition of TagsAuthPolicy to use for minting new tags within this guild
     */
    function registerGuild(bytes32 guildHash, address guildAdmin, address feePolicy, address tagsAuthPolicy) external;

    /**
     * @notice Deregisters a registered guild.
     * Designates guild as inactive and marks all tags previously minted for that guild as eligible for revocation.
     * @param guildHash The ENS namehash of the guild's domain
     */
    function deregisterGuild(bytes32 guildHash) external;

    /**
     * @notice Claims a guild tag
     * @param guildHash The namehash of the guild for which the tag should be claimed (e.g. namehash('my-guild.eth'))
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param recipient The address that will receive this guild tag (usually same as the caller)
     * @param extraClaimArgs [Optional] Any additional arguments necessary for guild-specific logic,
     *  such as authorization
     */
    function claimGuildTag(
        bytes32 guildHash,
        bytes32 tagHash,
        address recipient,
        bytes calldata extraClaimArgs
    ) external payable;

    /**
     * @notice Claims multiple tags for a guild at once
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHashes Namehashes of each tag to be claimed
     * @param recipients Recipients of each tag to be claimed
     * @param extraClaimArgs Per-tag extra arguments required for guild-specific logic, such as authorization.
     * Must have same length as array of tagHashes, even if each array element is itself empty bytes
     */
    function claimGuildTagsBatch(
        bytes32 guildHash,
        bytes32[] calldata tagHashes,
        address[] calldata recipients,
        bytes[] calldata extraClaimArgs
    ) external payable;

    /**
     * @notice Returns the current owner of the given guild tag.
     * Returns address(0) if no such guild or tag exists, or if the guild has been deregistered.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag (e.g. keccak256('foo') for foo.my-guild.eth)
     */
    function tagOwner(bytes32 guildHash, bytes32 tagHash) external view returns (address);

    /**
     * @notice Attempts to revoke an existing guild tag, if authorized by the guild's AuthPolicy.
     * Deregistered guilds will bypass auth checks for revocation of all tags.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param extraData [Optional] Any additional arguments necessary for assessing whether a tag may be revoked
     */
    function revokeGuildTag(bytes32 guildHash, bytes32 tagHash, bytes calldata extraData) external;

    /**
     * @notice Attempts to revoke multiple guild tags
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHashes ENS namehashes of all tags to revoke
     * @param extraData Additional arguments necessary for assessing whether a tag may be revoked
     */
    function revokeGuildTagsBatch(bytes32 guildHash, bytes32[] calldata tagHashes, bytes[] calldata extraData) external;

    /**
     * @notice Updates the FeePolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     */
    function updateGuildFeePolicy(bytes32 guildHash, address feePolicy) external;

    /**
     * @notice Updates the TagsAuthPolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagsAuthPolicy The address of an implementaition of TagsAuthPolicy to use for minting new tags within this guild
     */
    function updateGuildTagsAuthPolicy(bytes32 guildHash, address tagsAuthPolicy) external;

    /**
     * @notice Sets the metadata URI template string for fetching metadata for a guild's tag NFTs.
     * May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param uriTemplate The ERC1155 metadata URL template
     */
    function setGuildTokenUriTemplate(bytes32 guildHash, string calldata uriTemplate) external;

    /**
     * @notice Sets a guild as active or inactive. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param active The new status
     */
    function setGuildActive(bytes32 guildHash, bool active) external;

    /**
     * @notice Returns the current admin registered for the given guild.
     * @param guildHash The ENS namehash of the guild's domain
     */
    function guildAdmin(bytes32 guildHash) external view returns (address);

    /**
     * @notice Transfers the role of guild admin to the given address. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param newAdmin The new admin
     */
    function transferGuildAdmin(bytes32 guildHash, address newAdmin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IENSGuildsHumanized {
    function registerGuild(
        string memory ensName,
        address guildAdmin,
        address feePolicy,
        address tagsAuthPolicy
    ) external;

    function deregisterGuild(string memory guildEnsName) external;

    function claimGuildTag(
        string memory guildEnsName,
        string memory tag,
        address recipient,
        bytes calldata extraClaimArgs
    ) external payable;

    function tagOwner(string memory guildEnsName, string memory tag) external view returns (address);

    function revokeGuildTag(string memory guildEnsName, string memory tag, bytes calldata extraData) external;

    function updateGuildFeePolicy(string memory guildEnsName, address feePolicy) external;

    function updateGuildTagsAuthPolicy(string memory guildEnsName, address tagsAuthPolicy) external;

    function setGuildTokenUriTemplate(string memory guildEnsName, string calldata uriTemplate) external;

    function setGuildActive(string memory guildEnsName, bool active) external;

    function guildAdmin(string memory guildEnsName) external view returns (address);

    function transferGuildAdmin(string memory guildEnsName, address newAdmin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IENSGuilds.sol";
import "../interfaces/IENSGuildsHumanized.sol";
import "../../libraries/ENSNamehash.sol";

abstract contract ENSGuildsHumanized is IENSGuildsHumanized {
    using ENSNamehash for bytes;

    // Humanized versions

    /**
     * @notice Registers a new guild from an existing ENS domain.
     * Caller must be the ENS node's owner and ENSGuilds must have been designated an "operator" for the caller.
     * @param ensName The guild's full domain name (e.g. 'my-guild.eth')
     * @param admin The address that will administrate this guild
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     * @param tagsAuthPolicy The address of an implementaition of TagsAuthPolicy to use for minting new tags within this guild
     */
    function registerGuild(
        string memory ensName,
        address admin,
        address feePolicy,
        address tagsAuthPolicy
    ) external override {
        bytes32 ensNode = bytes(ensName).namehash();
        registerGuild(ensNode, admin, feePolicy, tagsAuthPolicy);
    }

    /**
     * @notice Deregisters a registered guild.
     * Designates guild as inactive and marks all tags previously minted for that guild as eligible for revocation.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     */
    function deregisterGuild(string memory guildEnsName) external {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        deregisterGuild(guildEnsNode);
    }

    /**
     * @notice Claims a guild tag
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param tag The tag to claim (e.g. 'foobar')
     * @param recipient The address that will receive this guild tag (usually same as the caller)
     * @param extraClaimArgs [Optional] Any additional arguments necessary for guild-specific logic,
     *  such as authorization
     */
    function claimGuildTag(
        string memory guildEnsName,
        string memory tag,
        address recipient,
        bytes calldata extraClaimArgs
    ) external payable override {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        bytes32 tagHash = keccak256(bytes(tag));
        claimGuildTag(guildEnsNode, tagHash, recipient, extraClaimArgs);
    }

    /**
     * @notice Attempts to revoke an existing guild tag, if authorized by the guild's AuthPolicy.
     * Deregistered guilds will bypass auth checks for revocation of all tags.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param tag The tag to revoke (e.g. 'foobar')
     * @param extraData [Optional] Any additional arguments necessary for assessing whether a tag may be revoked
     */
    function revokeGuildTag(string memory guildEnsName, string memory tag, bytes calldata extraData) external {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        bytes32 tagHash = keccak256(bytes(tag));
        revokeGuildTag(guildEnsNode, tagHash, extraData);
    }

    /**
     * @notice Returns the current owner of the given guild tag.
     * Returns address(0) if no such guild or tag exists, or if the guild has been deregistered.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param tag The tag (e.g. 'foobar')
     */
    function tagOwner(string memory guildEnsName, string memory tag) external view returns (address) {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        bytes32 tagHash = keccak256(bytes(tag));
        return tagOwner(guildEnsNode, tagHash);
    }

    /**
     * @notice Updates the FeePolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     */
    function updateGuildFeePolicy(string memory guildEnsName, address feePolicy) external {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        updateGuildFeePolicy(guildEnsNode, feePolicy);
    }

    /**
     * @notice Updates the TagsAuthPolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param tagsAuthPolicy The address of an implementaition of TagsAuthPolicy to use for minting new tags within this guild
     */
    function updateGuildTagsAuthPolicy(string memory guildEnsName, address tagsAuthPolicy) external {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        updateGuildTagsAuthPolicy(guildEnsNode, tagsAuthPolicy);
    }

    /**
     * @notice Sets the metadata URI template string for fetching metadata for a guild's tag NFTs.
     * May only be called by the guild's registered admin.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param uriTemplate The ERC1155 metadata URL template
     */
    function setGuildTokenUriTemplate(string memory guildEnsName, string calldata uriTemplate) external {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        setGuildTokenUriTemplate(guildEnsNode, uriTemplate);
    }

    /**
     * @notice Sets a guild as active or inactive. May only be called by the guild's registered admin.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param active The new status
     */
    function setGuildActive(string memory guildEnsName, bool active) external {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        setGuildActive(guildEnsNode, active);
    }

    /**
     * @notice Returns the current admin registered for the given guild.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     */
    function guildAdmin(string memory guildEnsName) external view returns (address) {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        return guildAdmin(guildEnsNode);
    }

    /**
     * @notice Transfers the role of guild admin to the given address. May only be called by the guild's registered admin.
     * @param guildEnsName The guild's full domain name (e.g. 'my-guild.eth')
     * @param newAdmin The new admin
     */
    function transferGuildAdmin(string memory guildEnsName, address newAdmin) external {
        bytes32 guildEnsNode = bytes(guildEnsName).namehash();
        transferGuildAdmin(guildEnsNode, newAdmin);
    }

    // Original versions

    function registerGuild(bytes32, address, address, address) public virtual;

    function deregisterGuild(bytes32) public virtual;

    function claimGuildTag(bytes32, bytes32, address, bytes calldata) public payable virtual;

    function revokeGuildTag(bytes32, bytes32, bytes calldata) public virtual;

    function tagOwner(bytes32, bytes32) public view virtual returns (address);

    function updateGuildFeePolicy(bytes32, address) public virtual;

    function updateGuildTagsAuthPolicy(bytes32, address) public virtual;

    function setGuildTokenUriTemplate(bytes32, string calldata) public virtual;

    function setGuildActive(bytes32, bool) public virtual;

    function guildAdmin(bytes32) public view virtual returns (address);

    function transferGuildAdmin(bytes32, address) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract ENSGuildsToken is ERC1155 {
    using Counters for Counters.Counter;

    error GuildsTokenTransferNotAllowed();

    uint256 internal constant GUILD_ID_MASK = uint256(~uint128(0)) << 128;

    struct GuildTokenInfo {
        Counters.Counter tokenIdTracker;
        string templateURI;
        mapping(bytes32 => uint256) guildTagsToTokenIds;
    }

    // maps the top 128 bits of each guild's GuildID (ensNode) to its metadataURI and token ID counter
    mapping(bytes16 => GuildTokenInfo) private guilds;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return ERC1155.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     * @param tokenId The token whose URI is returned
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        // calculate truncated guildHash from first 128 bits of tokenId
        uint256 truncatedGuildHashUint = tokenId & GUILD_ID_MASK;
        bytes16 truncatedGuildHash = bytes16(bytes32(truncatedGuildHashUint));

        // return guild-specific URI if exists
        string storage guildTemplateURI = guilds[truncatedGuildHash].templateURI;
        if (bytes(guildTemplateURI).length != 0) {
            return guildTemplateURI;
        }

        // return default URI shared by all guilds
        return ERC1155.uri(tokenId);
    }

    function _mintNewGuildToken(bytes32 guildHash, bytes32 tagHash, address to) internal {
        bytes16 truncatedGuildHash = bytes16(guildHash);

        uint256 tokenCounterCurrent = guilds[truncatedGuildHash].tokenIdTracker.current();
        require(tokenCounterCurrent < type(uint128).max, "tokenCounterOverflow");

        guilds[truncatedGuildHash].tokenIdTracker.increment();

        uint256 truncatedGuildHashUint = uint256(guildHash) & GUILD_ID_MASK;
        uint256 fullTokenId = truncatedGuildHashUint + tokenCounterCurrent;

        bytes memory emptyData;
        _mint(to, fullTokenId, 1, emptyData);

        guilds[truncatedGuildHash].guildTagsToTokenIds[tagHash] = fullTokenId;
    }

    function _burnGuildToken(bytes32 guildHash, bytes32 tagHash, address tagOwner) internal {
        bytes16 truncatedGuildHash = bytes16(guildHash);
        uint256 tokenId = guilds[truncatedGuildHash].guildTagsToTokenIds[tagHash];

        _burn(tagOwner, tokenId, 1);
    }

    function _setGuildTokenURITemplate(bytes32 guildHash, string calldata templateURI) internal {
        bytes16 truncatedGuildHash = bytes16(guildHash);
        guilds[truncatedGuildHash].templateURI = templateURI;
    }

    /**
     * @dev ENSGuilds NFTs are non-transferrable and may only be directly minted and burned
     * with their corresonding guild tags.
     */
    function safeTransferFrom(address, address, uint256, uint256, bytes memory) public virtual override {
        revert GuildsTokenTransferNotAllowed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ENSResolver is IAddrResolver, IAddressResolver, ERC165 {
    uint256 private constant COIN_TYPE_ETH = 60;

    mapping(bytes32 => address) public addresses;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by descendants of this contract
     */
    function _setEnsForwardRecord(bytes32 node, address a) internal {
        addresses[node] = a;
        emit AddrChanged(node, a);
        emit AddressChanged(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * @notice Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view override returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    /**
     * @notice Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @param coinType The coin type
     * @return The associated address.
     */
    function addr(bytes32 node, uint256 coinType) public view override returns (bytes memory) {
        bytes memory emptyBytes;

        if (coinType != COIN_TYPE_ETH) {
            return emptyBytes;
        }

        address a = addresses[node];
        if (a == address(0)) {
            return emptyBytes;
        }
        return addressToBytes(a);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165) returns (bool) {
        return
            interfaceID == type(IAddrResolver).interfaceId ||
            interfaceID == type(IAddressResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    // solhint-disable
    // Source: https://github.com/ensdomains/ens-contracts/blob/340a6d05cd00d078ae40edbc58c139eb7048189a/contracts/resolvers/profiles/AddrResolver.sol#L85
    function bytesToAddress(bytes memory b) internal pure returns (address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12)) // cspell:disable-line
        }
    }

    // Source: https://github.com/ensdomains/ens-contracts/blob/340a6d05cd00d078ae40edbc58c139eb7048189a/contracts/resolvers/profiles/AddrResolver.sol#L96
    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12))) // cspell:disable-line
        }
    }
    // solhint-enable
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title FeePolicy
 * @notice An interface for Guilds to implement that will specify how fees must be paid for guild tag mints
 */
abstract contract FeePolicy is ERC165 {
    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165) returns (bool) {
        return interfaceID == type(FeePolicy).interfaceId || super.supportsInterface(interfaceID);
    }

    /**
     * @notice Returns the fee required to mint the given guild tag by the given minter
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param claimant The address attempting to claim the tag (not necessarily the address that will receive it)
     * @param extraClaimArgs Any additional arguments that would be passed by the minter to the claimGuildTag() function
     * @return tokenContract The token contract the fee must be paid in (if any). Address(0) designates native Ether.
     * @return fee The amount (in base unit) that must be paid
     * @return feePaidTo The address that should receive payment of the fee
     */
    function tagClaimFee(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        bytes calldata extraClaimArgs
    ) external view virtual returns (address tokenContract, uint256 fee, address feePaidTo);
}

// SPDX-License-Identifier: MIT
// Source: https://github.com/JonahGroendal/ens-namehash/blob/master/contracts/ENSNamehash.sol

pragma solidity ^0.8.4;

/*
 * @dev Solidity implementation of the ENS namehash algorithm.
 *
 * Warning! Does not normalize or validate names before hashing.
 */
library ENSNamehash {
    function namehash(bytes memory domain) internal pure returns (bytes32) {
        return namehash(domain, 0);
    }

    function namehash(bytes memory domain, uint i) internal pure returns (bytes32) {
        if (domain.length <= i) return 0x0000000000000000000000000000000000000000000000000000000000000000;

        uint len = LabelLength(domain, i);

        return keccak256(abi.encodePacked(namehash(domain, i + len + 1), keccak(domain, i, len)));
    }

    function LabelLength(bytes memory domain, uint i) private pure returns (uint) {
        uint len;
        while (i + len != domain.length && domain[i + len] != 0x2e) {
            len++;
        }
        return len;
    }

    function keccak(bytes memory data, uint offset, uint len) private pure returns (bytes32 ret) {
        require(offset + len <= data.length);
        assembly {
            ret := keccak256(add(add(data, 32), offset), len)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title TagsAuthPolicy
 * @notice An interface for Guilds to implement that will control authorization for minting tags within that guild
 */
interface ITagsAuthPolicy is IERC165 {
    /**
     * @notice Checks whether a certain address (claimant) may claim a given guild tag
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param claimant The address attempting to claim the tag (not necessarily the address that will receive it)
     * @param recipient The address that would receive the tag
     * @param extraClaimArgs [Optional] Any guild-specific additional arguments required
     */
    function canClaimTag(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external returns (bool);

    /**
     * @dev Called by ENSGuilds once a tag has been claimed.
     * Provided for auth policies to update local state, such as erasing an address from an allowlist after that
     * address has successfully minted a tag.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param claimant The address that claimed the tag (not necessarily the address that received it)
     * @param recipient The address that received receive the tag
     * @param extraClaimArgs [Optional] Any guild-specific additional arguments required
     */
    function onTagClaimed(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external returns (bytes32 tagToRevoke);

    /**
     * @notice Checks whether a given guild tag is elligible to be revoked
     * @param revokedBy The address that would attempt to revoke it
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param extraRevokeArgs Any additional arguments necessary for assessing whether a tag may be revoked
     */
    function tagCanBeRevoked(
        address revokedBy,
        bytes32 guildHash,
        bytes32 tagHash,
        bytes calldata extraRevokeArgs
    ) external returns (bool);
}