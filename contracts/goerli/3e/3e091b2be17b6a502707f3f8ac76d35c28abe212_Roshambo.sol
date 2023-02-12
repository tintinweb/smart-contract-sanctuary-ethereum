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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "src/interfaces/IGenerator.sol";
import "src/interfaces/IRoshambo.sol";

contract Generator is IGenerator {
    using Strings for uint256;
    string[] public palettes;

    constructor() {
        palettes = [BLUE, WHITE, GREEN, PURPLE, ORANGE];
    }

    function generateSVG(
        uint256 _gameId,
        Player memory _p1,
        Player memory _p2
    ) external view returns (string memory svg) {
        Choice c1 = _p1.choice;
        Choice c2 = _p2.choice;
        svg = _generateRoot(c1, c2);
        svg = string.concat(svg, _generateFill(_gameId));
        if (
            (c1 == Choice.ROCK || c2 == Choice.ROCK) &&
            (c1 == Choice.PAPER || c2 == Choice.PAPER)
        ) {
            svg = string.concat(svg, _generateRockPaper());
        } else if (
            (c1 == Choice.PAPER || c2 == Choice.PAPER) &&
            (c1 == Choice.SCISSORS || c2 == Choice.SCISSORS)
        ) {
            svg = string.concat(svg, _generatePaperScissors());
        } else if (
            (c1 == Choice.SCISSORS || c2 == Choice.SCISSORS) &&
            (c1 == Choice.ROCK || c2 == Choice.ROCK)
        ) {
            svg = string.concat(svg, _generateScissorsRock());
        } else {
            svg = string.concat(svg, _generateRoshambo());
        }

        svg = string.concat(svg, "</svg>");
    }

    function _generateRoot(Choice _c1, Choice _c2) internal pure returns (string memory) {
        if (
            (_c1 == Choice.PAPER && _c2 == Choice.ROCK) ||
            (_c1 == Choice.SCISSORS && _c2 == Choice.PAPER) ||
            (_c1 == Choice.ROCK && _c2 == Choice.SCISSORS)
        ) {
            return "<svg version='1.1' viewBox='0 0 1200 1200' xmlns='http://www.w3.org/2000/svg' transform='scale (-1, 1)' transform-origin='center'>";
        } else {
            return "<svg version='1.1' viewBox='0 0 1200 1200' xmlns='http://www.w3.org/2000/svg'>";
        }
    }

    function _generateFill(uint256 _gameId) internal view returns (string memory) {
        uint256 index = _gameId % palettes.length;
        string memory fill = palettes[index];
        string[3] memory rect;
        rect[0] = "<rect width='1200' height='1200' fill='";
        rect[1] = fill;
        rect[2] = "'/>";

        return string(abi.encodePacked(rect[0], rect[1], rect[2]));
    }

    function _generateRoshambo() internal pure returns (string memory) {
        return
            "<g><path d='m697.2 548.4c10.801 7.1992 25.199 10.801 39.602 6 19.199-6 32.398-25.199 32.398-45.602v-42c16.801-9.6016 28.801-26.398 31.199-46.801l8.3984-61.199c4.8008-32.398-6-66-27.602-91.199l-54-62.398v-49.199c0-8.3984-6-14.398-14.398-14.398s-14.398 6-14.398 14.398v55.199c0 3.6016 1.1992 7.1992 3.6016 9.6016l57.602 66c16.801 19.199 24 43.199 20.398 68.398l-8.3984 61.199c-2.3984 18-18 31.199-36 30l-74.398-1.1992c-9.6016 0-16.801-7.1992-16.801-16.801 0-4.8008 2.3984-8.3984 4.8008-12 3.6016-3.6016 7.1992-4.8008 12-4.8008l50.398 2.3984c7.1992 0 13.199-4.8008 14.398-12l4.8008-32.398c1.1992-8.3984-4.8008-15.602-12-16.801s-15.602 4.8008-16.801 12l-2.3984 16.801c-50.398-24-46.801-73.199-46.801-75.602 1.1992-8.3984-4.8008-14.398-13.199-15.602h-1.1992c-7.1992 0-13.199 6-14.398 13.199-2.3984 20.398 3.6016 54 28.801 80.398-9.6016 1.1992-19.199 4.8008-26.398 12-3.6016 3.6016-6 7.1992-8.3984 10.801-7.1992-4.8008-15.602-7.1992-25.199-7.1992-14.398 0-27.602 7.1992-36 18-7.1992-6-16.801-8.3984-26.398-8.3984-7.1992 0-13.199 1.1992-19.199 4.8008-7.1992-40.801-8.3984-82.801-8.3984-112.8 0-26.398 14.398-50.398 36-64.801l13.199-8.3984c4.8008-2.3984 7.1992-7.1992 7.1992-12v-57.602c0-8.3984-6-14.398-14.398-14.398s-14.398 6-14.398 14.398v49.199l-2.4141 1.207c-31.199 19.199-49.199 52.801-50.398 88.801 0 37.199 1.1992 91.199 13.199 140.4-1.1992 4.8008-2.3984 9.6016-2.3984 14.398v46.801c0 25.199 20.398 48 45.602 48 10.801 0 19.199-3.6016 27.602-8.3984 8.3984 10.801 21.602 18 36 18 9.6016 0 19.199-3.6016 26.398-8.3984 8.3984 10.801 21.602 19.199 37.199 19.199 14.398-1.2031 27.598-8.4023 35.996-19.203zm8.4023-74.398 28.801 1.1992h4.8008v36c0 9.6016-7.1992 16.801-16.801 16.801-9.6016 0-16.801-7.1992-16.801-16.801zm-153.6 27.602c0 9.6016-7.1992 16.801-16.801 16.801-9.6016 0-16.801-7.1992-16.801-16.801v-49.199c0-9.6016 7.1992-16.801 16.801-16.801 9.6016 0 16.801 7.1992 16.801 16.801zm62.398 8.3984c0 9.6016-7.1992 16.801-16.801 16.801-9.6016 0-16.801-7.1992-16.801-16.801l0.003906-66c0-9.6016 7.1992-16.801 16.801-16.801 9.6016 0 16.801 7.1992 16.801 16.801zm28.801 10.801v-51.602c6 2.3984 12 3.6016 18 4.8008h15.602v46.801c0 9.6016-7.1992 16.801-16.801 16.801s-16.801-7.2031-16.801-16.801z'/><path d='m546 687.6c-10.801-4.8008-24-6-34.801-1.1992l-108 39.602 72-60c19.199-15.602 21.602-45.602 6-64.801-16.801-19.199-45.602-21.602-64.801-6l-128.4 106.8c-16.801-12-39.602-14.398-60-6l-57.602 24c-31.199 13.199-54 38.398-64.801 69.602l-26.398 78-43.199 25.199c-7.1992 3.6016-9.6016 13.199-4.8008 19.199s13.199 9.6016 19.199 4.8008l48-27.602c3.6016-1.1992 4.8008-4.8008 6-8.3984l27.602-82.801c8.3984-24 25.199-43.199 49.199-52.801l57.602-24c16.801-7.1992 34.801 0 44.398 14.398v1.1992l36 64.801c4.8008 8.3984 1.1992 18-6 22.801-3.5977 3.6016-8.3984 3.6016-13.199 2.4023s-8.3984-4.8008-9.6016-8.3984l-24-45.602c-3.6016-6-10.801-9.6016-18-7.1992l-30 12c-7.1992 2.3984-10.801 10.801-8.3984 18 2.3984 7.1992 10.801 10.801 18 8.3984l15.602-6c4.8008 55.199-39.602 76.801-42 78-7.1992 3.6016-10.801 12-7.1992 19.199 0 0 0 1.1992 1.1992 1.1992 3.6016 6 12 9.6016 18 6 18-8.3984 44.398-30 55.199-64.801 6 7.1992 14.398 13.199 24 15.602 4.8008 1.1992 9.6016 2.3984 15.602 1.1992 0 6 0 13.199 2.3984 19.199 1.1992 2.3984 2.3984 4.8008 3.6016 7.1992 6 9.6016 15.602 16.801 25.199 20.398-3.6016 10.805-3.6016 20.406 0 30.004 1.1992 2.3984 2.3984 4.8008 3.6016 7.1992 3.6016 6 8.3984 10.801 13.199 14.398-30 24-62.398 43.199-86.398 57.602-22.801 13.199-50.398 13.199-74.398 1.1992l-14.398-7.1992c-4.8008-2.3984-9.6016-2.3984-14.398 0l-49.207 27.602c-7.1992 3.6016-9.6016 13.199-4.8008 19.199 3.6016 7.1992 13.199 9.6016 19.199 4.8008l43.199-25.199 7.1992 3.6016c32.398 16.801 70.801 16.801 102-1.1992 30-16.801 72-43.199 108-74.398 2.3984 0 3.6016-1.1992 6-1.1992l45.602-16.801c24-8.3984 36-34.801 27.602-58.801-3.6016-9.6016-9.6016-16.801-18-21.602 1.1992-1.1992 2.3984-3.6016 3.6016-4.8008 4.8008-10.801 6-24 1.1992-34.801-2.3984-6-4.8008-10.801-8.3984-14.398l92.398-33.602c12-3.6016 20.398-12 26.398-24 4.8008-10.801 6-24 1.1992-34.801-4.8008-12-13.199-20.398-24-26.398zm-237.6 36s0-1.1992-1.1992-1.1992l126-105.6c7.1992-6 18-4.8008 24 2.3984 1.1992 1.1992 1.1992 1.1992 1.1992 2.3984 3.6016 7.1992 2.3984 16.801-3.6016 21.602l-130.8 109.2zm37.203 151.2c-3.6016-2.3984-7.1992-4.8008-8.3984-9.6016-3.6016-8.3984 1.1992-19.199 9.6016-21.602l62.398-22.801c4.8008-1.1992 8.3984-1.1992 13.199 0 3.6016 1.1992 6 3.6016 7.1992 7.1992 0 1.1992 1.1992 1.1992 1.1992 2.3984 1.1992 4.8008 1.1992 8.3984-1.1992 13.199-2.3984 3.6016-4.8008 7.1992-9.6016 8.3984l-62.398 22.801c-3.6016 2.4062-8.4023 2.4062-12 0.007812zm98.398 31.199c-2.3984 3.6016-4.8008 7.1992-9.6016 8.3984l-45.602 16.801c-4.8008 1.1992-8.3984 1.1992-13.199 0-4.8008-1.1992-7.1992-4.8008-8.3984-9.6016-1.1992-4.8008-1.1992-8.3984 0-13.199 2.3984-3.6016 6-7.1992 9.6016-8.3984l45.602-16.801c8.3984-3.6016 19.199 1.1992 21.602 9.6016 2.3945 4.8008 2.3945 8.3984-0.003906 13.199zm97.199-169.2c-2.3984 3.6016-4.8008 7.1992-9.6016 8.3984l-182.4 66c0-7.1992-1.1992-15.602-4.8008-22.801l-4.8008-9.6016 181.2-66c4.8008-1.1992 8.3984-1.1992 13.199 0 3.6016 2.3984 7.1992 4.8008 8.3984 9.6016 1.207 6 1.207 9.6016-1.1953 14.402z'/><path d='m1162.8 882-42-24-21.602-70.801c-9.6016-33.602-32.398-61.199-63.602-78l-90-48c-21.602-12-48-4.8008-61.199 16.801-1.1992 1.1992-1.1992 3.6016-2.3984 4.8008l-97.199-54c-21.602-12-50.398-4.8008-62.398 16.801-3.6016 6-4.8008 13.199-6 20.398-18-2.3984-36 6-45.602 22.801-9.6016 16.801-7.1992 37.199 3.6016 50.398-6 3.6016-10.801 8.3984-14.398 15.602-12 21.602-4.8008 50.398 16.801 62.398l16.801 9.6016c-4.8008 3.6016-8.3984 8.3984-10.801 13.199-12 21.602-4.8008 50.398 16.801 62.398l61.199 34.801c14.398 8.3984 30 18 46.801 32.398l2.3984 1.1992c38.398 30 139.2 108 212.4 61.199l42 24c7.1992 3.6016 15.602 1.1992 19.199-6 3.6016-7.1992 1.1992-15.602-6-19.199l-49.199-27.602c-4.8008-2.3984-10.801-2.3984-15.602 1.1992-56.398 44.398-150-28.801-186-56.398l-2.3984-1.1992c-18-14.398-34.801-25.199-50.398-33.602l-61.199-34.801c-8.3984-4.8008-10.801-14.398-6-22.801 4.8008-8.3984 15.602-10.801 22.801-6l90 50.398c7.1992 3.6016 15.602 1.1992 19.199-6 3.6016-7.1992 1.1992-15.602-6-19.199l-140.41-82.793c-8.3984-4.8008-10.801-15.602-6-22.801 4.8008-8.3984 14.398-10.801 22.801-6l123.6 69.602c7.1992 3.6016 15.602 1.1992 19.199-4.8008 3.6016-7.1992 1.1992-15.602-6-19.199l-144-81.602c-8.3984-4.8008-10.801-15.602-6-22.801 4.8008-8.3984 15.602-10.801 22.801-6l133.2 75.602c7.1992 3.6016 15.602 1.1992 19.199-6 3.6016-7.1992 1.1992-15.602-6-19.199l-112.8-63.602c-8.3984-4.8008-10.801-15.602-6-22.801 4.8008-8.3984 14.398-10.801 22.801-6l108 61.199c3.6016 12 10.801 22.801 21.602 28.801l31.199 18c-25.199 100.8 54 134.4 55.199 134.4 7.1992 2.3984 14.398 0 18-6 0 0 0-1.1992 1.1992-1.1992 2.3984-7.1992-1.1992-15.602-8.3984-18-2.3984-1.1992-54-22.801-40.801-92.398 3.6016 2.3984 8.3984 6 12 9.6016l7.1992 6c6 4.8008 14.398 4.8008 20.398-1.1992 4.8008-6 4.8008-14.398-1.1992-20.398l-7.1992-6c-7.1992-13.203-15.598-20.402-26.398-25.203l-45.602-26.398c-4.8008-2.3984-7.1992-6-8.3984-10.801s0-9.6016 2.3984-13.199c4.8008-8.3984 15.602-10.801 22.801-6l90 48c24 13.199 42 34.801 50.398 61.199l22.801 76.801c1.1992 3.6016 3.6016 6 7.1992 8.3984l46.801 26.398c7.1992 3.6016 15.602 1.1992 19.199-6 4.8008-7.1992 2.4023-16.797-4.7969-20.398z'/></g>";
    }

    function _generateRockPaper() internal pure returns (string memory) {
        return
            "<g><path d='m511.2 573.6c0-16.801-8.3984-32.398-21.602-42 8.3984-12 12-28.801 7.1992-45.602-7.1992-21.602-28.801-36-51.602-36h-48c-10.801-19.199-30-32.398-52.801-34.801l-69.602-9.6016c-37.199-4.8008-74.398 7.1992-103.2 31.199l-69.602 61.199-55.191 0.003906c-8.3984 0-16.801 7.1992-16.801 16.801 0 9.6016 7.1992 16.801 16.801 16.801h61.199c3.6016 0 7.1992-1.1992 10.801-3.6016l74.398-66c21.602-19.199 49.199-27.602 76.801-24l69.602 9.6016c20.398 2.3984 34.801 20.398 34.801 40.801l-1.1992 84c0 10.801-8.3984 18-19.199 18-4.8008 0-9.6016-2.3984-13.199-6-3.6055-3.6016-4.8047-8.4023-4.8047-14.402l2.3984-57.602c0-8.3984-6-15.602-13.199-16.801l-36-6c-8.3984-1.1992-16.801 4.8008-18 13.199s4.8008 16.801 13.199 18l18 2.3984c-26.398 57.602-82.801 52.801-85.199 52.801-8.3984-1.1992-16.801 6-18 14.398v1.1992c0 8.3984 6 15.602 14.398 15.602 22.801 2.3984 61.199-3.6016 91.199-33.602 1.1992 10.801 6 21.602 14.398 28.801 3.6016 3.6016 7.1992 6 12 9.6016-4.8008 8.3984-8.3984 18-8.3984 28.801 0 16.801 8.3984 31.199 20.398 40.801-6 8.3984-9.6016 19.199-9.6016 30 0 8.3984 2.3984 15.602 4.8008 21.602-45.602 8.3984-93.602 9.6016-128.4 8.3984-30 0-57.602-15.602-73.199-40.801l-9.6016-15.602c-2.3984-4.8008-8.3984-7.1992-13.199-7.1992l-67.195 0.003906c-8.3984 0-16.801 7.1992-16.801 16.801 0 9.6016 7.1992 16.801 16.801 16.801h56.398l4.8008 7.1992c21.602 34.801 60 56.398 100.8 56.398 42 0 103.2-1.1992 158.4-14.398 4.8008 1.1992 10.801 2.3984 15.602 2.3984h52.801c28.801 0 54-22.801 54-51.602 0-12-3.6016-21.602-9.6016-31.199 12-9.6016 20.398-24 20.398-40.801 0-10.801-3.6016-21.602-9.6016-30 12.004-3.5977 20.402-19.199 20.402-35.996zm-103.2-90h40.801c10.801 0 19.199 8.3984 19.199 19.199s-8.3984 19.199-19.199 19.199h-40.801l1.1992-33.602c-1.1992-1.1992-1.1992-3.5977-1.1992-4.7969zm30 252h-55.199c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h55.199c10.801 0 19.199 8.3984 19.199 19.199 0 9.5977-8.3984 19.199-19.199 19.199zm9.6016-72h-75.602c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h75.602c10.801 0 19.199 8.3984 19.199 19.199 1.1992 10.797-8.4023 19.199-19.199 19.199zm12-70.801h-58.801c2.3984-6 4.8008-13.199 4.8008-20.398v-18h54c10.801 0 19.199 8.3984 19.199 19.199 0 10.797-8.4023 19.199-19.199 19.199z'/><path d='m1153.2 696h-64.801c-6 0-12 3.6016-14.398 9.6016-31.199 75.602-164.4 55.199-214.8 48h-2.3984c-26.398-3.6016-48-6-68.398-6h-80.398c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h116.4c8.3984 0 16.801-7.1992 16.801-16.801 0-8.3984-7.1992-15.602-16.801-15.602h-184.8c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h160.8c9.6016 0 16.801-7.1992 16.801-15.602 0-9.6016-7.1992-16.801-16.801-16.801h-187.2c-10.801 0-19.199-8.3984-19.199-19.199s8.3984-19.199 19.199-19.199h172.8c9.6016 0 16.801-7.1992 16.801-16.801 0-8.3984-7.1992-15.602-16.801-15.602h-146.4c-10.801 0-19.199-8.3984-19.199-19.199s8.3984-19.199 19.199-19.199h140.4c9.6016 10.801 24 15.602 38.398 15.602h40.801c30 112.8 128.4 102 129.6 102 8.3984-1.1992 14.398-8.3984 14.398-15.602v-2.3984c-1.1992-8.3984-9.6016-15.602-18-14.398-3.6016 0-66 7.1992-91.199-68.398 6 0 10.801 1.1992 16.801 2.3984l10.801 2.3984c8.3984 2.3984 16.801-3.6016 19.199-12 2.3984-8.3984-3.6016-16.801-12-19.199l-10.801-2.3984c-12-2.3984-25.199-3.6016-38.398-3.6016h-60c-6 0-10.801-2.3984-14.398-6-3.6016-3.6016-6-9.6016-6-14.398 0-10.801 9.6016-19.199 19.199-19.199l115.2-2.3984c31.199-1.1992 60 10.801 82.801 32.398l64.801 62.398c3.6016 2.3984 7.1992 4.8008 10.801 4.8008h61.199c8.3984 0 16.801-7.1992 16.801-16.801-0.003906-9.6055-7.2031-18.004-16.805-18.004h-55.199l-60-57.602c-28.801-27.602-66-42-105.6-40.801l-116.4 2.4023c-27.602 1.1992-50.398 22.801-51.602 50.398v6h-124.8c-27.602 0-51.602 22.801-51.602 51.602 0 8.3984 2.3984 15.602 6 22.801-19.199 7.1992-32.398 26.398-32.398 48 0 21.602 13.199 39.602 32.398 48-3.6016 7.1992-6 14.398-6 22.801 0 28.801 22.801 51.602 51.602 51.602h21.602c-2.3984 6-3.6016 12-3.6016 19.199 0 28.801 22.801 51.602 51.602 51.602h80.398c19.199 0 39.602 1.1992 63.602 4.8008h2.3984c55.199 8.3984 196.8 28.801 243.6-57.602h54c8.3984 0 16.801-7.1992 16.801-16.801-0.003906-7.2031-7.2031-14.402-16.805-14.402z'/></g>";
    }

    function _generatePaperScissors() internal pure returns (string memory) {
        return
            "<g><path d='m1155.6 672h-56.398c-4.8008 0-9.6016 2.3984-12 7.1992l-8.3984 13.199c-14.398 22.801-38.398 36-63.602 36-27.602 0-64.801-1.1992-102-6 2.3984-6 4.8008-12 4.8008-19.199 0-2.3984 0-4.8008-1.1992-8.3984-1.1992-9.6016-6-18-13.199-25.199 7.1992-8.3984 12-19.199 12-30 0-2.3984 0-4.8008-1.1992-8.3984-1.1992-6-3.6016-12-7.1992-18 4.8008-2.3984 8.3984-4.8008 12-8.3984 7.1992-7.1992 10.801-15.602 12-25.199 26.398 25.199 60 31.199 79.199 28.801 7.1992-1.1992 13.199-7.1992 13.199-14.398v-1.1992c-1.1992-7.1992-7.1992-13.199-15.602-13.199-2.3984 0-51.602 3.6016-74.398-45.602l15.602-2.3984c7.1992-1.1992 13.199-8.3984 12-15.602-1.1992-7.1992-8.3984-13.199-15.602-12l-32.398 4.8008c-7.1992 1.1992-12 7.1992-12 14.398l2.3984 50.398c0 4.8008-1.1992 8.3984-4.8008 12-3.6016 3.6016-7.1992 4.8008-12 4.8008-8.3984 0-16.801-7.1992-16.801-16.801l-1.1992-73.199v-1.1992c0-18 13.199-32.398 30-34.801l61.199-8.3984c24-3.6016 49.199 4.8008 67.199 20.398l64.801 57.602c2.3984 2.3984 6 3.6016 9.6016 3.6016h54c8.3984 0 14.398-6 14.398-14.398 0-8.3984-6-14.398-14.398-14.398h-49.199l-61.199-54c-25.199-21.602-57.602-31.199-90-27.602l-61.199 8.3984c-21.602 2.3984-39.602 16.801-48 34.801l-160.8-28.801c-25.199-4.8008-48 12-52.801 37.199-4.8008 24 12 48 37.199 52.801l91.199 15.602-112.8 22.789c-12 2.3984-22.801 8.3984-28.801 19.199-7.1992 9.6016-9.6016 21.602-7.1992 33.602 2.3984 12 8.3984 22.801 18 28.801 9.6016 7.1992 21.602 9.6016 33.602 7.1992l96-16.801c-1.1992 6-1.1992 10.801 0 16.801 2.3984 12 8.3984 22.801 18 28.801 1.1992 1.1992 3.6016 2.3984 4.8008 2.3984-3.6016 8.3984-6 18-3.6016 27.602 4.8008 24 27.602 40.801 52.801 37.199l48-8.3984c2.3984 0 3.6016-1.1992 6-1.1992 46.801 9.6016 96 10.801 129.6 10.801 36 0 68.398-19.199 87.602-49.199l3.6016-6h49.199c8.3984 0 14.398-6 14.398-14.398-0.003906-8.4062-6.0039-14.406-14.402-14.406zm-481.2-165.6c-8.3984-1.1992-14.398-8.3984-14.398-16.801v-2.3984c1.1992-9.6016 10.801-15.602 19.199-13.199l160.8 27.602v1.1992l1.1992 32.398zm-15.598 124.8c-4.8008 1.1992-8.3984 0-12-2.3984-3.6016-2.3984-6-6-7.1992-10.801-1.1992-4.8008 0-9.6016 2.3984-13.199 2.3984-3.6016 6-6 10.801-7.1992l187.2-33.602v10.801c0 8.3984 2.3984 15.602 7.1992 21.602zm128.4 24v-2.3984c0-3.6016 1.1992-7.1992 2.3984-9.6016 2.3984-3.6016 6-6 10.801-7.1992l64.801-12c9.6016-1.1992 18 4.8008 19.199 13.199 1.1992 4.8008 0 8.3984-2.3984 12-2.3984 3.6016-6 6-10.801 7.1992l-64.801 12c-4.8008 1.1992-8.3984 0-12-2.3984-3.5977-3.6016-6-7.1992-7.1992-10.801zm98.402 57.602c-2.3984 3.6016-6 6-10.801 7.1992l-48 8.3984c-4.8008 1.1992-8.3984 0-13.199-2.3984-3.6016-2.3984-6-6-7.1992-10.801-1.1992-9.6016 4.8008-18 13.199-19.199l48-8.3984c4.8008-1.1992 8.3984 0 13.199 2.3984 3.6016 2.3984 6 6 7.1992 10.801 0 3.5977 0 8.3984-2.3984 12z'/><path d='m532.8 547.2c3.6016-6 4.8008-13.199 4.8008-20.398 0-25.199-20.398-45.602-45.602-45.602h-109.2v-4.8008c-1.1992-24-20.398-43.199-44.398-44.398l-100.8-2.3984c-34.801-1.1992-67.199 12-92.398 36l-52.805 50.398h-48c-8.3984 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398h54c3.6016 0 7.1992-1.1992 9.6016-3.6016l57.602-54c19.199-19.199 45.602-28.801 72-27.602l100.8 2.3984c9.6016 0 16.801 7.1992 16.801 16.801 0 4.8008-1.1992 9.6016-4.8008 13.199-3.6016 3.6016-8.3984 6-13.199 6h-51.602c-10.801 0-22.801 1.1992-33.602 3.6016l-9.6016 2.3984c-7.1992 1.1992-12 9.6016-10.801 16.801 1.1992 7.1992 9.6016 12 16.801 10.801l9.6016-2.3984c4.8008-1.1992 9.6016-1.1992 14.398-2.3984-21.602 66-76.801 60-79.199 60-7.1992-1.1992-14.398 4.8008-15.602 12v2.3984c0 7.1992 4.8008 13.199 12 14.398 1.1992 0 86.398 9.6016 112.8-88.801h34.801c13.199 0 24-4.8008 33.602-14.398h122.4c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801l-128.4 0.003906c-8.3984 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398l151.2 0.003906c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801l-164.4-0.003906c-8.3984 0-14.398 6-14.398 14.398 0 7.1992 6 14.398 14.398 14.398h140.4c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801l-160.8 0.003906c-8.3984 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398h102c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801h-69.602c-18 0-37.199 1.1992-60 4.8008h-2.3984c-43.199 6-159.6 24-187.2-42-2.3984-8.3984-7.1992-12-13.199-12h-56.402c-7.1992 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398h48c40.801 75.602 165.6 57.602 213.6 50.398h2.3984c21.602-3.6016 39.602-4.8008 56.398-4.8008h69.602c25.199 0 45.602-20.398 45.602-45.602 0-6-1.1992-12-3.6016-16.801h18c25.199 0 45.602-20.398 45.602-45.602 0-7.1992-2.3984-14.398-4.8008-20.398 16.801-7.1992 28.801-22.801 28.801-42-2.3984-17.992-14.398-34.793-31.199-40.793z'/></g>";
    }

    function _generateScissorsRock() internal pure returns (string memory) {
        return
            "<g><path d='m868.8 459.6 67.199-8.3984c27.602-3.6016 54 4.8008 74.398 22.801l72 63.602c2.3984 2.3984 6 3.6016 10.801 3.6016h60c8.3984 0 15.602-7.1992 15.602-15.602 0-8.3984-7.1992-15.602-15.602-15.602h-54l-68.398-60c-27.602-24-63.602-34.801-99.602-30l-67.199 8.3945c-22.801 2.3984-40.801 15.602-51.602 33.602h-46.801c-22.801 0-43.199 13.199-50.398 34.801-4.8008 16.801-1.1992 32.398 7.1992 44.398-12 9.6016-20.398 24-20.398 40.801s8.3984 31.199 20.398 39.602c-6 8.3984-9.6016 18-9.6016 28.801 0 15.602 7.1992 30 19.199 39.602-6 8.3984-9.6016 18-9.6016 30 0 27.602 25.199 50.398 52.801 50.398l52.805-0.003906c6 0 10.801-1.1992 15.602-2.3984 54 12 112.8 14.398 153.6 14.398 39.602 0 76.801-20.398 97.199-55.199l4.8008-7.1992h54c8.3984 0 15.602-7.1992 15.602-15.602 0-8.3984-7.1992-15.602-15.602-15.602h-63.602c-6 0-10.801 2.3984-13.199 7.1992l-8.4023 13.203c-15.602 25.199-42 39.602-70.801 39.602-33.602 0-79.199-1.1992-123.6-8.3984 3.6016-6 4.8008-13.199 4.8008-21.602 0-10.801-3.6016-21.602-9.6016-30 12-9.6016 19.199-24 19.199-39.602 0-10.801-3.6016-20.398-8.3984-27.602 4.8008-2.3984 8.3984-4.8008 12-8.3984 7.1992-8.3984 12-18 13.199-28.801 28.801 27.602 66 34.801 87.602 32.398 8.3984-1.1992 14.398-7.1992 14.398-15.602l0.003906-1.1953c-1.1992-8.3984-8.3984-14.398-16.801-14.398-2.3984 0-56.398 4.8008-82.801-51.602l18-2.3984c8.3984-1.1992 14.398-9.6016 13.199-18-1.1992-8.3984-9.6016-14.398-18-13.199l-36 4.8008c-8.3984 1.1992-13.199 8.3984-13.199 16.801l2.3984 55.199c0 4.8008-1.1992 9.6016-4.8008 13.199-3.6016 3.6016-8.3984 6-13.199 6-9.6016 0-18-8.3984-18-18l-1.1992-81.602c-1.1992-16.801 13.203-34.801 32.402-37.199zm-104.4 34.797h39.602v6l1.1992 32.398h-39.602c-10.801 0-19.199-8.3984-19.199-19.199-1.1992-10.797 8.4023-19.199 18-19.199zm-30 87.602c0-10.801 8.3984-19.199 19.199-19.199h51.602v18c0 7.1992 2.3984 13.199 4.8008 20.398h-56.398c-10.801-1.1992-19.203-9.5977-19.203-19.199zm93.602 156h-54c-10.801 0-19.199-8.3984-19.199-19.199s8.3984-19.199 19.199-19.199h54c10.801 0 19.199 8.3984 19.199 19.199s-8.3984 19.199-19.199 19.199zm9.6016-105.6c10.801 0 19.199 8.3984 19.199 19.199 0 10.801-8.3984 19.199-19.199 19.199h-73.199c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199z'/><path d='m608.4 574.8-123.6-22.801 100.8-18c27.602-4.8008 45.602-31.199 40.801-57.602-4.8008-27.602-31.199-45.602-58.801-40.801l-178.8 31.199c-9.6016-20.398-30-36-54-38.398l-67.199-8.3984c-36-4.8008-72 6-99.602 30l-68.398 60h-54c-8.3984 0-15.602 7.1992-15.602 15.602 0 8.3984 7.1992 15.602 15.602 15.602h60c3.6016 0 7.1992-1.1992 10.801-3.6016l72-63.602c20.398-18 48-26.398 74.398-22.801l67.199 8.3984c19.199 2.3984 33.602 19.199 33.602 38.398v1.1992l-1.1992 81.602c0 9.6016-8.3984 18-18 18-4.8008 0-9.6016-2.3984-13.199-6-3.6016-3.6016-4.8008-8.3984-4.8008-13.199l2.3984-55.199c0-8.3984-6-15.602-13.199-16.801l-36-4.8008c-8.3984-1.1992-16.801 4.8008-18 13.199-1.1992 8.3984 4.8008 16.801 13.199 18l18 2.3984c-26.398 55.199-80.398 51.602-82.801 51.602-8.3984-1.1992-16.801 6-16.801 14.398v1.1992c0 8.3984 6 14.398 14.398 15.602 21.602 2.3984 58.801-3.6016 87.602-32.398 1.1992 10.801 6 20.398 13.199 27.602 3.6016 3.6016 8.3984 7.1992 13.199 9.6016-3.6016 6-7.1992 12-8.3984 19.199 0 3.6016-1.1992 6-1.1992 8.3984 0 13.199 4.8008 25.199 13.199 33.602-7.1992 7.1992-13.199 16.801-14.398 27.602 0 2.3984-1.1992 6-1.1992 8.3984 0 7.1992 1.1992 14.398 4.8008 21.602-40.801 6-82.801 7.1992-112.8 7.1992-28.801 0-55.199-15.602-70.801-39.602l-9.6016-14.398c-2.3984-4.8008-8.3984-7.1992-13.199-7.1992h-62.398c-8.3984 0-15.602 7.1992-15.602 15.602 0 8.3984 7.1992 15.602 15.602 15.602h54l4.8008 7.1992c21.602 33.602 57.602 54 97.199 55.199 37.199 0 92.398-1.1992 144-12 2.3984 1.1992 3.6016 1.1992 6 1.1992l52.801 9.6016c27.602 4.8008 52.801-13.199 58.801-40.801 2.3984-10.801 0-21.602-4.8008-31.199 2.3984-1.1992 3.6016-2.3984 6-3.6016 10.801-7.1992 18-19.199 20.398-32.398 1.1992-6 1.1992-13.199 0-19.199l105.6 18c13.199 2.3984 26.398 0 37.199-8.3984 10.801-7.1992 18-19.199 20.398-32.398s0-26.398-8.3984-37.199c-6-9.6094-18-16.809-31.203-19.207zm-212.4-76.801 177.6-31.199c9.6016-2.3984 20.398 4.8008 21.602 15.602v3.6016c0 8.3984-6 16.801-15.602 18l-183.6 32.395 1.1992-36c-1.1992-1.1992-1.1992-2.3984-1.1992-2.3984zm37.199 236.4c-1.1992 4.8008-3.6016 9.6016-7.1992 12-3.6016 2.3984-9.6016 3.6016-14.398 3.6016l-52.801-9.6016c-4.8008-1.1992-9.6016-3.6016-12-7.1992-2.3984-3.6016-3.6016-9.6016-3.6016-14.398 1.1992-4.8008 3.6016-9.6016 7.1992-12 3.6016-2.3984 9.6016-3.6016 14.398-3.6016l52.801 9.6016c9.6016 1.1992 16.801 12 15.602 21.598zm21.602-66c-1.1992 4.8008-3.6016 9.6016-7.1992 12-3.6016 2.3984-9.6016 3.6016-14.398 3.6016l-72-13.199c-4.8008-1.1992-9.6016-3.6016-12-7.1992-2.3984-3.6016-3.6016-9.6016-3.6016-14.398 1.1992-9.6016 12-16.801 21.602-15.602l72 13.199c4.8008 1.1992 9.6016 3.6016 12 7.1992 2.3984 3.6016 3.6016 7.1992 3.6016 10.801-0.003907 1.1992-0.003907 2.3984-0.003907 3.5977zm156-28.797c-3.6016 2.3984-9.6016 3.6016-14.398 3.6016l-210-37.199c4.8008-7.1992 7.1992-15.602 7.1992-24v-12l208.8 37.199c4.8008 1.1992 9.6016 3.6016 12 7.1992 2.3984 3.6016 3.6016 9.6016 3.6016 14.398-0.003906 3.5977-3.6055 7.1992-7.2031 10.801z'/></g>";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "src/Generator.sol";
import "src/interfaces/IRoshambo.sol";
import "src/lib/Base64.sol";

/// @notice Just a friendly game of Rock Paper Scissors
contract Roshambo is IRoshambo, ERC721, ERC721Holder, Ownable {
    using Strings for uint160;
    using Strings for uint256;
    /// @dev Interface identifier for royalty standard
    bytes4 constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// @notice Time duration for submitting commit and reveal
    uint256 public constant DURATION = 24 hours;
    /// @dev Address of Generator contract
    uint256 public constant MIN_WAGER = 0.01 ether;
    /// @notice Address of Generator contract
    address public immutable generator;
    /// @notice Current rake fee (2.5%)
    uint256 public rake = 250;
    /// @notice Address of beneficiary
    address public beneficiary;
    /// @notice Current game ID
    uint256 public currentId;
    /// @notice Current supply of NFTs
    uint256 public totalSupply;
    /// @notice List of open games
    uint256[] public lobby;
    /// @notice Mapping of game ID to game info
    mapping(uint256 => Game) public games;
    /// @notice Mapping of player to record info
    mapping(address => Record) public records;
    /// @notice Mapping of player to payout balance
    mapping(address => uint256) public payouts;
    /// @dev Mapping of game ID to lobby index
    mapping(uint256 => uint256) internal indices;

    constructor() payable ERC721("RSPTest", "TEST") {
        beneficiary = owner();
        generator = address(new Generator());
    }

    function newGame() external payable returns (uint256) {
        if (msg.value < MIN_WAGER) revert InsufficientWager();

        Game storage game = games[++currentId];
        Player memory p1 = Player(msg.sender, Choice.NONE, bytes32(0));
        game.p1 = p1;
        game.pot += msg.value;
        game.state = State.PENDING;
        lobby.push(currentId);
        indices[currentId] = lobby.length - 1;

        emit NewGame(currentId, msg.sender, msg.value);
        return currentId;
    }

    function joinGame(uint256 _gameId) external payable {
        Game storage game = _verifyGame(_gameId);
        if (game.state != State.PENDING) revert InvalidState();
        if (msg.sender == game.p1.player) revert InvalidPlayer();
        if (msg.value != game.pot) revert InvalidWager();

        Player memory p2 = Player(msg.sender, Choice.NONE, bytes32(0));
        game.p2 = p2;
        game.pot += msg.value;
        game.state = State.ACTIVE;
        game.stage = Stage.COMMIT;
        game.commit = block.timestamp + DURATION;

        _removePending(_gameId);
        _safeMint(address(this), _gameId);
        ++totalSupply;

        emit JoinGame(_gameId, msg.sender, game.pot);
    }

    function commit(uint256 _gameId, bytes32 _commit) external {
        Game storage game = _verifyGame(_gameId);
        if (game.state != State.ACTIVE) revert InvalidState();
        if (game.stage != Stage.COMMIT) revert InvalidStage();
        if (block.timestamp > game.commit) revert PastDeadline();

        Player storage p1 = game.p1;
        Player storage p2 = game.p2;

        if (p1.player == msg.sender) {
            if (p1.commitment != bytes32(0)) revert AlreadyCommited();
            p1.commitment = _commit;
        } else if (p2.player == msg.sender) {
            if (p2.commitment != bytes32(0)) revert AlreadyCommited();
            p2.commitment = _commit;
        } else {
            revert InvalidPlayer();
        }

        if (p1.commitment != bytes32(0) && p2.commitment != bytes32(0)) {
            game.stage = Stage.REVEAL;
            game.reveal = block.timestamp + DURATION;
        }

        emit Commit(_gameId, msg.sender, _commit, game.stage);
    }

    function reveal(uint256 _gameId, Choice _choice, string memory _secret) external {
        Game storage game = _verifyGame(_gameId);
        if (game.state != State.ACTIVE) revert InvalidState();
        if (game.stage != Stage.REVEAL) revert InvalidStage();
        if (block.timestamp > game.reveal) revert PastDeadline();

        Player storage p1 = game.p1;
        Player storage p2 = game.p2;

        if (p1.player == msg.sender) {
            _verifySecret(msg.sender, _choice, _secret, p1.commitment);
            p1.choice = _choice;
        } else if (p2.player == msg.sender) {
            _verifySecret(msg.sender, _choice, _secret, p2.commitment);
            p2.choice = _choice;
        } else {
            revert InvalidPlayer();
        }

        if (p1.choice != Choice.NONE && p2.choice != Choice.NONE) {
            game.stage = Stage.SETTLE;
        }

        emit Reveal(_gameId, msg.sender, _choice, _secret, game.stage);
    }

    function settle(uint256 _gameId) external {
        Game storage game = _verifyGame(_gameId);
        if (game.state != State.ACTIVE) revert InvalidState();
        if (
            game.stage != Stage.SETTLE ||
            (game.stage == Stage.COMMIT && block.timestamp <= game.commit) ||
            (game.stage == Stage.REVEAL && block.timestamp <= game.reveal)
        ) revert InvalidStage();

        Player storage p1 = game.p1;
        Player storage p2 = game.p2;
        address player1 = p1.player;
        address player2 = p2.player;
        Choice c1 = p1.choice;
        Choice c2 = p2.choice;
        Record storage r1 = records[player1];
        Record storage r2 = records[player2];
        uint256 pot = game.pot;
        uint256 fee = (pot * rake) / DENOMINATOR;

        if (
            (c1 == Choice.ROCK && c2 == Choice.SCISSORS) ||
            (c1 == Choice.PAPER && c2 == Choice.ROCK) ||
            (c1 == Choice.SCISSORS && c2 == Choice.PAPER) ||
            (c1 != Choice.NONE && c2 == Choice.NONE)
        ) {
            _setGame(game, player1, pot, fee);
            _setRecord(_gameId, r1, r2);
            _transferGame(_gameId, player1, c2);
        } else if (
            (c2 == Choice.ROCK && c1 == Choice.SCISSORS) ||
            (c2 == Choice.PAPER && c1 == Choice.ROCK) ||
            (c2 == Choice.SCISSORS && c1 == Choice.PAPER) ||
            (c2 != Choice.NONE && c1 == Choice.NONE)
        ) {
            _setGame(game, player2, pot, fee);
            _setRecord(_gameId, r2, r1);
            _transferGame(_gameId, player2, c1);
        } else {
            game.state = State.DRAW;
            ++r1.ties;
            ++r2.ties;
            payouts[player1] += pot / 2;
            payouts[player2] += pot / 2;
        }

        emit Settle(_gameId, game.winner, c1, c2, game.state);
    }

    function withdraw(address _to) external {
        uint256 balance = payouts[_to];
        if (balance == 0) revert InsufficientBalance();
        delete payouts[_to];

        (bool success, ) = _to.call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    function cancel(uint256 _gameId) external {
        Game storage game = _verifyGame(_gameId);
        uint256 pot = game.pot;
        if (game.state != State.PENDING) revert InvalidState();
        if (msg.sender != game.p1.player) revert InvalidPlayer();
        delete games[_gameId];

        (bool success, ) = msg.sender.call{value: pot}("");
        if (!success) revert TransferFailed();
    }

    function setBeneficiary(address _beneficiary) external payable onlyOwner {
        beneficiary = _beneficiary;
    }

    function setRake(uint256 _rake) external payable onlyOwner {
        rake = _rake;
    }

    function royaltyInfo(
        uint256 /* _tokenId */,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royalty) {
        receiver = owner();
        royalty = (_salePrice * rake) / DENOMINATOR;
    }

    function generateCommit(
        uint256 _gameId,
        address _player,
        Choice _choice,
        string memory _secret
    ) external view returns (bytes32) {
        Game memory game = _verifyGame(_gameId);
        if (_player != game.p1.player && _player != game.p2.player) revert InvalidPlayer();
        if (_choice == Choice.NONE || uint8(_choice) > 3) revert InvalidChoice();
        return keccak256(abi.encodePacked(_player, _choice, _secret));
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        Game memory game = games[_tokenId];
        Player memory p1 = game.p1;
        Player memory p2 = game.p2;
        string memory name = string.concat("RPS #", _tokenId.toString());
        string memory description = "Just a friendly game of Rock Paper Scissors. Shoot!";
        string memory gameTraits = _generateGameTraits(game);
        string memory playerTraits = _generatePlayerTraits(p1, p2);
        string memory image = Base64.encode(
            abi.encodePacked(IGenerator(generator).generateSVG(_tokenId, p1, p2))
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '{"name":"',
                                name,
                            '",',
                            '"description":"',
                                description,
                            '",',
                            '"image": "data:image/svg+xml;base64,',
                                image,
                            '",',
                            '"attributes": [',
                                playerTraits,
                                gameTraits,
                            "]}"
                        )
                    )
                )
            );
    }

    function _removePending(uint256 _gameId) internal {
        uint256 index = indices[_gameId];
        delete lobby[index];
        delete indices[_gameId];
    }

    function _verifyGame(uint256 _gameId) internal view returns (Game storage game) {
        if (_gameId == 0 || _gameId > currentId) revert InvalidGame();
        game = games[_gameId];
    }

    function _verifySecret(
        address _player,
        Choice _choice,
        string memory _secret,
        bytes32 _commitment
    ) internal pure {
        if (keccak256(abi.encodePacked(_player, _choice, _secret)) != _commitment)
            revert InvalidSecret();
    }

    function _setGame(Game storage _game, address _player, uint256 _pot, uint256 _fee) internal {
        _game.state = State.SUCCESS;
        _game.winner = _player;
        payouts[_player] += (_pot - _fee);
        payouts[beneficiary] += _fee;
    }

    function _setRecord(uint256 _gameId, Record storage _winner, Record storage _loser) internal {
        ++_winner.wins;
        ++_winner.rank;
        _winner.gameIds.push(_gameId);

        ++_loser.losses;
        if (_loser.rank > 1) --_loser.rank;
        _loser.gameIds.push(_gameId);
    }

    function _transferGame(uint256 _gameId, address _player, Choice _choice) internal {
        if (_choice != Choice.NONE) {
            _burn(_gameId);
            _safeMint(_player, _gameId);
        }
    }

    function _generateGameTraits(Game memory _game) internal pure returns (string memory) {
        string memory pot = _game.pot.toString();
        string memory stage = _getStage(_game.stage);
        string memory state = _getState(_game.state);
        string memory winner = uint160(_game.winner).toHexString(20);

        return
            string(
                abi.encodePacked(
                    '{"trait_type":"Pot", "value":"',
                        pot,
                    '"},',
                    '{"trait_type":"Stage", "value":"',
                        stage,
                    '"},',
                    '{"trait_type":"State", "value":"',
                        state,
                    '"},',
                    '{"trait_type":"Winner", "value":"',
                        winner,
                    '"}'
                )
            );
    }

    function _generatePlayerTraits(
        Player memory _p1,
        Player memory _p2
    ) internal pure returns (string memory) {
        string memory player1 = uint160(_p1.player).toHexString(20);
        string memory player2 = uint160(_p2.player).toHexString(20);
        string memory choice1 = _getChoice(_p1.choice);
        string memory choice2 = _getChoice(_p2.choice);

        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                        choice1,
                    '", "value":"',
                        player1,
                    '"},',
                    '{"trait_type":"',
                        choice2,
                    '", "value":"',
                        player2,
                    '"},'
                )
            );
    }

    function _getChoice(Choice _choice) internal pure returns (string memory choice) {
        if (_choice == Choice.NONE) {
            choice = "N/A";
        } else if (_choice == Choice.ROCK) {
            choice = "Rock";
        } else if (_choice == Choice.PAPER) {
            choice = "Paper";
        } else if (_choice == Choice.SCISSORS) {
            choice = "Scissors";
        }
    }

    function _getStage(Stage _stage) internal pure returns (string memory stage) {
        if (_stage == Stage.NOT_STARTED) {
            stage = "Not Started";
        } else if (_stage == Stage.COMMIT) {
            stage = "Commit";
        } else if (_stage == Stage.REVEAL) {
            stage = "Reveal";
        } else if (_stage == Stage.SETTLE) {
            stage = "Settle";
        }
    }

    function _getState(State _state) internal pure returns (string memory state) {
        if (_state == State.INACTIVE) {
            state = "Inactive";
        } else if (_state == State.PENDING) {
            state = "Pending";
        } else if (_state == State.ACTIVE) {
            state = "Active";
        } else if (_state == State.SUCCESS) {
            state = "Success";
        } else if (_state == State.DRAW) {
            state = "Draw";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Player} from "src/interfaces/IRoshambo.sol";

string constant BLUE = "#3B6BF9";
string constant GREEN = "#007435";
string constant ORANGE = "#FF824A";
string constant PURPLE = "#C462DD";
string constant WHITE = "#ffffff";

interface IGenerator {
    function generateSVG(
        uint256 _gameId,
        Player memory _p1,
        Player memory _p2
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

uint256 constant DENOMINATOR = 10000;

enum State {
    INACTIVE,
    PENDING,
    ACTIVE,
    SUCCESS,
    DRAW
}

enum Stage {
    NOT_STARTED,
    COMMIT,
    REVEAL,
    SETTLE
}

enum Choice {
    NONE,
    ROCK,
    PAPER,
    SCISSORS
}

struct Game {
    Player p1;
    Player p2;
    uint256 pot;
    State state;
    Stage stage;
    address winner;
    uint256 commit;
    uint256 reveal;
}

struct Player {
    address player;
    Choice choice;
    bytes32 commitment;
}

struct Record {
    uint64 rank;
    uint64 wins;
    uint64 losses;
    uint64 ties;
    uint256[] gameIds;
}

interface IRoshambo {
    error AlreadyCommited();
    error InsufficientBalance();
    error InsufficientWager();
    error InvalidChoice();
    error InvalidGame();
    error InvalidPlayer();
    error InvalidSecret();
    error InvalidStage();
    error InvalidState();
    error InvalidWager();
    error PastDeadline();
    error TransferFailed();

    event NewGame(uint256 indexed _gameId, address indexed _player, uint256 indexed _wager);
    event JoinGame(uint256 indexed _gameId, address indexed _player, uint256 indexed _pot);
    event Commit(uint256 indexed _gameId, address indexed _player, bytes32 _commit, Stage _stage);
    event Reveal(
        uint256 indexed _gameId,
        address indexed _player,
        Choice _choice,
        string _secret,
        Stage _stage
    );
    event Settle(
        uint256 indexed _gameId,
        address indexed _winner,
        Choice _choice1,
        Choice _choice2,
        State _state
    );
    event Cancel(uint256 indexed _gameId, address indexed _player, uint256 indexed _refund);

    function DURATION() external view returns (uint256);

    function MIN_WAGER() external view returns (uint256);

    function beneficiary() external view returns (address);

    function cancel(uint256 _gameId) external;

    function commit(uint256 _gameId, bytes32 _commit) external;

    function currentId() external view returns (uint256);

    function generator() external view returns (address);

    function generateCommit(
        uint256 _gameId,
        address _player,
        Choice _choice,
        string memory _secret
    ) external view returns (bytes32);

    function joinGame(uint256 _gameId) external payable;

    function lobby(uint256) external view returns (uint256);

    function newGame() external payable returns (uint256);

    function payouts(address) external view returns (uint256);

    function rake() external view returns (uint256);

    function reveal(uint256 _gameId, Choice _choice, string memory _secret) external;

    function setBeneficiary(address _beneficiary) external payable;

    function setRake(uint256 _rake) external payable;

    function settle(uint256 _gameId) external;

    function totalSupply() external view returns (uint256);

    function withdraw(address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Base64 {
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) public pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = _TABLE;
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}