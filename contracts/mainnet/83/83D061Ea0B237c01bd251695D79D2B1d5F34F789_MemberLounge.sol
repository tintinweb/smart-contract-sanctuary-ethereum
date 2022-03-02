// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
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
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
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
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//-----------------------------------------------------------------------------
 /*\_____________________________________________________________   .¿yy¿.   __
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$^^^^/%#//
 MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
 MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
 M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
 M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
   \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
  J$$$^^^^/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
 .$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
 \$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
 o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
 o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
 o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
 /$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
  7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
  `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
 y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
 M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
 MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
 MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
 MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
 MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
 MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
 GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
 CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMM/-/-/-\*/
//-----------------------------------------------------------------------------
// Genetic Chain: Member Lounge
//-----------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//-----------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";

//------------------------------------------------------------------------------
// GeneticChainMetadata
//------------------------------------------------------------------------------

/**
 * @title GeneticChain - MemberLounge
 */
contract MemberLounge is ERC1155, IERC721Receiver,
    Ownable
{

    //-------------------------------------------------------------------------
    // structs
    //-------------------------------------------------------------------------

    struct Token {
        uint16 passList;
        uint56 maxSupply;
        uint56 totalSupply;
        int64 minStakeTime;
        int64 createdTS;
    }

    struct Pass {
        uint8 passId;
        uint16 tokenId;
        int64 stakedTS;
    }

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    /**
     * Emited when a new token is created.
     */
    event TokenCreated(uint256 tokenId, uint16 passList, uint56 maxSupply,
        int64 minStakeTime, int64 createdTS);

    /**
     * Emited when a new pass is staked.
     */
    event Staked(address indexed owner, address pass, uint256 tokenId, int64 stakedTS);

    /**
     * Emited when a new pass is staked.
     */
    event Unstaked(address indexed owner, address pass, uint256 tokenId);

    /**
     * Emited when a reward is claimed.
     */
    event RewardsClaimed(address indexed owner, uint256 tokenId, uint256 amount);

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    address constant kDeadAddy = 0x000000000000000000000000000000000000dEaD;

    // token name/symbol
    string constant private _name   = "Genetic Chain Member Lounge";
    string constant private _symbol = "GCML";

    // contract info
    string public _contractUri;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // track tokens
    Token[] private _tokens;

    // handle token uri overrides
    mapping (uint256 => string) private _ipfsHash;

    // roles
    mapping (address => bool) private _minterAddress;
    mapping (address => bool) private _burnerAddress;

    // staking
    IERC721[] private _passes;
    mapping (address => uint8) private _passIdx;
    mapping (address => Pass[]) private _stakedPasses;

    // claim
    mapping (uint256 => bool) private _claims;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        string memory baseUri,
        string memory contractUri,
        address[] memory passes)
        ERC1155(baseUri)
    {
        // start token index at 1
        _tokens.push();

        // start pass index at 1 else we can't use 0 index to indicate
        //  an invalid pass inside _passIdx
        _passes.push();

        // save contract uri
        _contractUri = contractUri;

        // register passes
        for (uint256 i = 0; i < passes.length; ++i) {
            _registerPassContract(passes[i]);
        }
    }

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(_created(tokenId), "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

	/**
     * Verify caller is authorized minter.
     */
    modifier isMinter() {
        require(_minterAddress[_msgSender()] || owner() == _msgSender(), "caller not minter");
        _;
    }

    //-------------------------------------------------------------------------

	/**
     * Verify caller is authorized burner.
     */
    modifier isBurner() {
        require(_burnerAddress[_msgSender()], "caller not burner");
        _;
    }

    //-------------------------------------------------------------------------
    // internal
    //-------------------------------------------------------------------------

    /**
     * @dev Returns whether the specified token was created.
     */
    function _created(uint256 id)
        internal view
        returns (bool)
    {
        return id < _tokens.length && _tokens[id].createdTS > 0;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Returns whether the specified token has supply.
     */
    function _exists(uint256 id)
        internal view
        returns (bool)
    {
        return id < _tokens.length && _tokens[id].totalSupply > 0;
    }

    //-------------------------------------------------------------------------

    function _registerPassContract(address pass)
        internal
    {
        require(IERC165(pass).supportsInterface(type(IERC721).interfaceId), "not IERC721 compliant");
        _passIdx[pass] = uint8(_passes.length);
        _passes.push(IERC721(pass));
    }

    //-------------------------------------------------------------------------

    function _mkClaimId(address claimee, uint256 tokenId)
        internal pure
        returns(uint256)
    {
        return uint256(uint160(claimee)) << 96 | tokenId;
    }

    //-------------------------------------------------------------------------

    function _inPassList(uint8 passId, uint16 passList)
        internal pure
        returns(bool)
    {
        return passList & uint16(1 << (passId - 1)) != 0;
    }

    //-------------------------------------------------------------------------

    function _calculateRewards(address claimee, uint256 tokenId)
        internal view
        returns(uint256 rewards)
    {
        // token to calculate rewards for
        Token storage token = _tokens[tokenId];

        // claim rewards for passes staked long enough
        uint256 stakedCount = _stakedPasses[claimee].length;
        for (uint256 i = 0; i < stakedCount; ++i) {
            Pass storage stakedPass = _stakedPasses[claimee][i];
            int64 timeElapsed = token.createdTS - stakedPass.stakedTS;
            if (timeElapsed >= token.minStakeTime
                && _inPassList(stakedPass.passId, token.passList))
            {
                rewards += 1;
            }
        }
    }

    //-------------------------------------------------------------------------
    // ERC165
    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public view virtual override(ERC1155)
        returns (bool)
    {
        return interfaceId == type(IERC721Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    //-------------------------------------------------------------------------
    // ERC1155
    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
            address account, uint256 id, uint256 amount, bytes memory data)
        internal virtual override validTokenId(id)
    {
        super._mint(account, id, amount, data);
        _tokens[id].totalSupply += uint56(amount);
        require(_tokens[id].totalSupply <= _tokens[id].maxSupply,
            'amount exceed maxsupply');
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
            address to, uint256[] memory ids, uint256[] memory amounts,
            bytes memory data)
        internal virtual override
    {
        super._mintBatch(to, ids, amounts, data);

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                require(_created(id), 'invalid token');
                _tokens[id].totalSupply += uint56(amounts[i]);
                require(_tokens[id].totalSupply <= _tokens[id].maxSupply,
                    'amount exceed maxsupply');
            }
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(address account, uint256 id, uint256 amount)
        internal virtual override validTokenId(id)
    {
        super._burn(account, id, amount);

        unchecked {
            _tokens[id].totalSupply -= uint56(amount);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
            address account, uint256[] memory ids, uint256[] memory amounts)
        internal virtual override
    {
        super._burnBatch(account, ids, amounts);

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                _tokens[id].totalSupply -= uint56(amounts[i]);
            }
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     *  Each token should have it's own override.
     */
    function uri(uint256 id)
        public view override validTokenId(id)
        returns (string memory)
    {
        // append hash or use base
        return bytes(_ipfsHash[id]).length == 0
            ? super.uri(id)
            : string(abi.encodePacked(super.uri(id), "/", _ipfsHash[id]));
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    /**
     * Authorize minter address.
     */
    function registerMinterAddress(address minter)
        public onlyOwner
    {
        require(!_minterAddress[minter], "address already registered");
        _minterAddress[minter] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove minter address.
     */
    function revokeMinterAddress(address minter)
        public onlyOwner
    {
        require(_minterAddress[minter], "address not registered");
        delete _minterAddress[minter];
    }

    //-------------------------------------------------------------------------

    /**
     * Authorize burner address.
     */
    function registerBurnerAddress(address burner)
        public onlyOwner
    {
        require(!_burnerAddress[burner], "address already registered");
        _burnerAddress[burner] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove burner address.
     */
    function revokeBurnerAddress(address burner)
        public onlyOwner
    {
        require(_burnerAddress[burner], "address not registered");
        delete _burnerAddress[burner];
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Update default tokenUri used for all tokens.
     *
     * Should use the `\{id\}` replace mechanism to load the token id.
     */
    function setURI(string memory tokenUri)
        public onlyOwner
    {
        _setURI(tokenUri);
        emit URI(tokenUri, 0);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's ipfs hash.
     */
    function setTokenIpfsHash(uint256 id, string memory ipfsHash)
        public onlyOwner validTokenId(id)
    {
        _ipfsHash[id] = ipfsHash;
        emit URI(uri(id), id);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's pass list.
     */
    function setTokenPassList(uint256 id, uint16 passList)
        public onlyOwner validTokenId(id)
    {
        _tokens[id].passList = passList;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's max supply.
     */
    function setTokenMaxSupply(uint256 id, uint56 maxSupply)
        public onlyOwner validTokenId(id)
    {
        require(maxSupply >= _tokens[id].totalSupply, 'max must exceed total');
        _tokens[id].maxSupply = maxSupply;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's minimum stake time.
     */
    function setTokenMinStakeTime(uint256 id, int64 minStakeTime)
        public onlyOwner validTokenId(id)
    {
        _tokens[id].minStakeTime = minStakeTime;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's minimum stake time.
     */
    function editToken(uint256 id, uint16 passList, uint56 maxSupply,
            int64 minStakeTime, string memory ipfsHash)
        public onlyOwner validTokenId(id)
    {
        require(maxSupply >= _tokens[id].totalSupply, 'max must exceed total');
        _tokens[id].passList     = passList;
        _tokens[id].maxSupply    = maxSupply;
        _tokens[id].minStakeTime = minStakeTime;

        _ipfsHash[id] = ipfsHash;
        emit URI(uri(id), id);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Create a new token.
     * @param passList uint16 Passes eligible for reward.
     * @param amount uint256 Mint amount tokens to caller.
     * @param minStakeTime int64 Minimum time pass stake required to qualify
     * @param maxSupply uint56 Max mintable supply for this token.
     * @param ipfsHash string Override ipfsHash for newly created token.
     */
    function create(uint16 passList, uint256 amount, uint56 maxSupply,
            int64 minStakeTime, string memory ipfsHash)
        public onlyOwner
    {
        require(amount > 0, 'invalid amount');
        require(bytes(ipfsHash).length > 0, 'invalid ipfshash');

        // grab token id
        uint256 tokenId = _tokens.length;

        // add token
        int64 createdAt    = int64(int256(block.timestamp));
        Token memory token = Token(passList, maxSupply, 0, minStakeTime, createdAt);
        _tokens.push(token);

        // override token's ipfsHash
        _ipfsHash[tokenId] = ipfsHash;
        emit URI(uri(tokenId), tokenId);

        // mint a single token
        _mint(msg.sender, tokenId, amount, "");

        // created event
        emit TokenCreated(tokenId, passList, maxSupply, minStakeTime, createdAt);
    }

    //-------------------------------------------------------------------------

    function mint(address to, uint256 id, uint256 amount)
        public isMinter
    {
        require(amount > 0, 'invalid amount');
        _mint(to, id, amount, "");
    }

    //-------------------------------------------------------------------------

    function mintBatch(address to,
            uint256[] calldata ids, uint256[] calldata amounts)
        external isMinter
    {
        _mintBatch(to, ids, amounts, "");
    }

    //-------------------------------------------------------------------------

    function burn(address to, uint256 id, uint256 amount)
        public isBurner
    {
        require(amount > 0, 'invalid amount');
        _burn(to, id, amount);
    }

    //-------------------------------------------------------------------------

    function burnBatch(address to,
            uint256[] calldata ids, uint256[] calldata amounts)
        external isBurner
    {
        _burnBatch(to, ids, amounts);
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * @dev Conform to {IERC721Metadata-name}.
     */
    function name()
        public pure
        returns (string memory)
    {
        return _name;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Conform to {IERC721Metadata-symbol}.
     */
    function symbol()
        public pure
        returns (string memory)
    {
        return _symbol;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id)
        public view
        returns (uint256)
    {
        return id < _tokens.length
            ? _tokens[id].totalSupply
            : 0;
    }

    //-------------------------------------------------------------------------
    // IERC721Receiver
    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
            address, address, uint256, bytes calldata)
        public pure override
        returns (bytes4)
    {
        return this.onERC721Received.selector ^ 0x23b872dd;
    }

    //-------------------------------------------------------------------------
    // interface
    //-------------------------------------------------------------------------

    /**
     * @dev Return token info.
     */
    function getToken(uint256 id)
        public view validTokenId(id)
        returns (Token memory, string memory)
    {
        return (_tokens[id], _ipfsHash[id]);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return list of all tokens.
     */
    function allTokens()
        public view
        returns (Token[] memory)
    {
        // return empty so all token indecies line up
        return _tokens;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return list of pass contracts.
     */
    function allPassContracts()
        public view
        returns (address[] memory)
    {
        // keep the first empty entry so index lines up with id
        uint256 count = _passes.length;
        address[] memory passes = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            passes[i] = address(_passes[i]);
        }
        return passes;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return list of passes staked by staker.
     */
    function getStakedPasses(address staker)
        public view
        returns (Pass[] memory stakedPasses)
    {
        stakedPasses = _stakedPasses[staker];
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Query pass for owners balance.
     */
    function balanceOfPass(address pass, address owner)
        public
        view
        returns (uint256)
    {
        require(_passIdx[pass] != 0, 'invalid pass address');

        // grab pass
        uint8 passId    = _passIdx[pass];
        IERC721 pass721 = _passes[passId];

        // return pass balance
        return pass721.balanceOf(owner);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Stake single pass.
     */
    function stakePass(address pass, uint256 tokenId)
        public
    {
        require(_passIdx[pass] != 0, 'invalid pass address');

        address sender = _msgSender();

        // grab pass
        uint8 passId    = _passIdx[pass];
        IERC721 pass721 = _passes[passId];

        // verify ownership
        require(pass721.ownerOf(tokenId) == sender, 'not pass owner');

        // transfer here
        pass721.transferFrom(sender, address(this), tokenId);

        // save staked info
        int64 stakedTS = int64(int256(block.timestamp));
        Pass memory stakedPass = Pass(
            passId,
            uint16(tokenId),
            stakedTS);
        _stakedPasses[sender].push(stakedPass);

        // track skate event
        emit Staked(sender, pass, tokenId, stakedTS);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Unstake single pass.
     */
    function unstakePass(address pass, uint256 tokenId)
        public
    {
        require(_passIdx[pass] != 0, 'invalid pass address');

        address sender = _msgSender();

        // grab pass
        uint8 passId    = _passIdx[pass];
        IERC721 pass721 = _passes[passId];

        // find pass
        uint256 stakedCount = _stakedPasses[sender].length;
        for (uint256 i = 0; i < stakedCount; ++i) {
            Pass storage stakedPass = _stakedPasses[sender][i];
            if (stakedPass.passId == passId && stakedPass.tokenId == tokenId) {

                // transfer pass back to owner
                pass721.transferFrom(address(this), sender, tokenId);

                // keep array compact
                uint256 lastIndex = stakedCount - 1;
                if (i != lastIndex) {
                    _stakedPasses[sender][i] = _stakedPasses[sender][lastIndex];
                }

                // cleanup
                _stakedPasses[sender].pop();

                // track unskate event
                emit Unstaked(sender, pass, tokenId);

                // no need to continue
                return;
            }
        }

        // invalid pass
        require(false, 'pass not found');
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Unstake all passes staked in contract.
     */
    function unstakeAllPasses()
        public
    {
        address sender = _msgSender();
        require(_stakedPasses[sender].length > 0, 'no passes staked');

        // unstake all passes
        uint256 stakedCount = _stakedPasses[sender].length;
        for (uint256 i = 0; i < stakedCount; ++i) {
            Pass storage stakedPass = _stakedPasses[sender][i];
            IERC721 pass721         = _passes[stakedPass.passId];

            // transfer pass back to owner
            pass721.transferFrom(address(this), sender, stakedPass.tokenId);

            // track unskate event
            emit Unstaked(sender, address(pass721), stakedPass.tokenId);

            // cleanup
            delete _stakedPasses[sender][i];
        }

        // cleanup
        delete _stakedPasses[sender];
    }

    //-------------------------------------------------------------------------

    /**
     * Calculate rewards available for user for given tokenId.
     */
    function calculateRewards(uint256 tokenId, address user)
        public view validTokenId(tokenId)
        returns(uint256)
    {
        uint256 claimId = _mkClaimId(user, tokenId);
        return _claims[claimId]
            ? 0
            : _calculateRewards(user, tokenId);
    }

    //-------------------------------------------------------------------------

    function calculateRewardsBatch(uint256[] memory tokenIds, address user)
        public view
        returns(uint256[] memory)
    {
        uint256 count = tokenIds.length;
        uint256[] memory rewards = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            rewards[i] = calculateRewards(tokenIds[i], user);
        }
        return rewards;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Claim single token for all passes.
     */
    function claim(uint256 tokenId)
        public validTokenId(tokenId)
    {
        address sender = _msgSender();
        require(_stakedPasses[sender].length > 0, 'no passes staked');

        // check claim
        uint256 claimId = _mkClaimId(sender, tokenId);
        require(!_claims[claimId], 'rewards claimed');

        // process all passes
        uint256 rewards = _calculateRewards(sender, tokenId);
        require(rewards > 0, 'no rewards');

        // mark as claimed
        _claims[claimId] = true;

        // mint token for claimee
        _mint(sender, tokenId, rewards, "");

        // record event
        emit RewardsClaimed(sender, tokenId, rewards);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Claim multiple tokens at once.
     */
    function claimBatch(uint256[] calldata tokenIds)
        public
    {
        require(tokenIds.length > 0, 'no token ids');
        uint256 tokenCount = tokenIds.length;
        for (uint256 i = 0; i < tokenCount; ++i) {
            claim(tokenIds[i]);
        }
    }

    //-------------------------------------------------------------------------

    function setContractURI(string memory contractUri)
        external onlyOwner
    {
        _contractUri = contractUri;
    }

    //-------------------------------------------------------------------------

    function contractURI()
        public view
        returns (string memory)
    {
        return _contractUri;
    }

}