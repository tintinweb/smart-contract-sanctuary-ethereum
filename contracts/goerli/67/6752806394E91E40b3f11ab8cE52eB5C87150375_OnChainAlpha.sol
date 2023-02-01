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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
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
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at `_startTokenId()`
 * (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
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
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = _tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library HelperLib {
    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

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

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Normalize4 is Ownable {

	error InvalidCodepoint(uint256 cp);

	uint256 constant STOP = 0x2E;
	uint256 constant EMOJI_STATE_MASK  = 0x07FF; 
	uint256 constant EMOJI_STATE_QUIRK = 0x0800;
	uint256 constant EMOJI_STATE_VALID = 0x1000;
	uint256 constant EMOJI_STATE_SAVE  = 0x2000;
	uint256 constant EMOJI_STATE_CHECK = 0x4000;
	uint256 constant EMOJI_STATE_FE0F  = 0x8000;

	mapping (uint256 => uint256) _emoji;
	mapping (uint256 => uint256) _valid;   // bitmap
	mapping (uint256 => uint256) _ignored; // bitmap
	mapping (uint256 => uint256) _small; // 1-2 cp
	mapping (uint256 => uint256) _large; // 3-6 cp
	mapping (uint256 => uint256) _class;
	mapping (uint256 => uint256) _cm;
	mapping (uint256 => uint256) _recomp;
	mapping (uint256 => uint256) _decomp;

	function normhash(string memory name) public view returns (bytes32 node) {
		string[] memory labels = normalize(name);
		uint256 i = labels.length;
		while (i > 0) {
			bytes32 label = keccak256(bytes(labels[--i]));
			node = keccak256(abi.encodePacked(node, label));
		}
	}

	function normalize(string memory name) public view returns (string[] memory labels) {
        (uint256[] memory values, uint256 label_count) = process(decodeUTF8(bytes(name)), false);
		//n = label_count;
		//v = values;
		values = nfd(values);
		labels = new string[](label_count);
		uint256 prev;
		for (uint256 i; i < label_count; i++) {
			uint256 end = prev;
			while (end < values.length && values[end] != STOP) end++;
			labels[i] = string(post_check_label(values, prev, end));
			prev = end + 1;
		}
	}

	function beautify(string memory name) public view returns (string memory) {
		(uint256[] memory values, ) = process(decodeUTF8(bytes(name)), true);
		return string(nfc(nfd(values)));
	}


	function updateMapping(mapping (uint256 => uint256) storage map, bytes calldata data, uint256 key_bytes) private {
		uint256 i;
		uint256 e;
	    uint256 mask = ~(type(uint256).max << (key_bytes << 3));
		assembly {
			i := data.offset
			e := add(i, data.length)
		}
		while (i < e) {
			uint256 k;
			uint256 v;
			assembly {
				// key-value pairs are packed in reverse 
				// eg. [value1][key1][value2][key2]...
				v := calldataload(i)
				i := add(i, key_bytes)
				k := and(calldataload(i), mask)
				i := add(i, 32)
			}
			map[k] = v;
		}
	}
	
	function updateBatch1(bytes[] calldata data) public onlyOwner {
		updateClass(data[0]);
        updateCM(data[1]);
        updateDecomp(data[2]);
        updateIgnored(data[3]);
        updateLarge(data[4]);
        updateValid(data[5]);
        updateLarge(data[6]);
	}
    
    function updateBatch2(bytes[] calldata data) public onlyOwner {
        updateRecomp(data[0]);
        uploadEmoji(data[1]);
    }

	function uploadEmoji(bytes calldata data) public onlyOwner {
		updateMapping(_emoji, data, 4);
	}
	function updateValid(bytes calldata data) public onlyOwner {
		updateMapping(_valid, data, 2);
	}
	function updateIgnored(bytes calldata data) public onlyOwner {
		updateMapping(_ignored, data, 2);
	}
	function updateSmall(bytes calldata data) public onlyOwner {
		updateMapping(_small, data, 3);
	}
	function updateLarge(bytes calldata data) public onlyOwner {
		updateMapping(_large, data, 3);
	}
	function updateClass(bytes calldata data) public onlyOwner {
		updateMapping(_class, data, 2);
	}
	function updateCM(bytes calldata data) public onlyOwner {
		updateMapping(_cm, data, 2);
	}
	function updateDecomp(bytes calldata data) public onlyOwner {
		updateMapping(_decomp, data, 3);
	}
	function updateRecomp(bytes calldata data) public onlyOwner {
		updateMapping(_recomp, data, 5);
	}

	// bitmaps
	function isCM(uint256 cp) public view returns (bool) {
		return ((_cm[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}
	function isValid(uint256 cp) public view returns (bool) {
		return ((_valid[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}
	function isIgnored(uint256 cp) public view returns (bool) {
		return ((_ignored[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}

 	function getDecomp(uint256 cp) public view returns (uint256) {
        return (_decomp[cp >> 2] >> ((cp & 0x3) << 6)) & 0xFFFFFFFFFFFFFFFF;
    }
	function getRecomp(uint256 a, uint256 b) public view returns (uint256) {
		return (_recomp[(b << 29) | (a >> 3)] >> ((a & 0x7) << 5)) & 0xFFFFFFFF;
	}
	function getClass(uint256 cp) public view returns (uint256) {
		return (_class[cp >> 5] >> ((cp & 0x1F) << 3)) & 0xFF;
	}

	function getSmall(uint256 cp) public view returns (uint256) {
		return (_small[cp >> 2] >> ((cp & 0x3) << 6)) & 0xFFFFFFFFFFFFFFFF;
	}
	function getLarge(uint256 cp) public view returns (uint256) {
		return (_large[cp >> 1] >> ((cp & 0x1) << 7)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	}

	function getEmoji(uint256 s0, uint256 cp) private view returns (uint256) {
		return (_emoji[(s0 << 20) | (cp >> 4)] >> ((cp & 0xF) << 4)) & 0xFFFF;
	}

	
	function debugEmojiState(uint256 s0, uint256 cp) public view returns (uint256 value, bool fe0f, bool check, bool save, bool valid, bool quirk, uint256 s1) {
		// (state0, Floor[cp/16]) => array: uint32[16]
		// array[cp%16] => [flags: (4 bits), state1: (12 bits)]
		value = getEmoji(s0, cp);
		fe0f = (value & EMOJI_STATE_FE0F) != 0;
		check = (value & EMOJI_STATE_CHECK) != 0;
		save = (value & EMOJI_STATE_SAVE) != 0;
		valid = (value & EMOJI_STATE_VALID) != 0;
		quirk = (value & EMOJI_STATE_QUIRK) != 0;
		s1 = value & EMOJI_STATE_MASK; // next state
	}

	function isOneEmoji(string memory s) public view returns (bool) {
		uint256[] memory cps = decodeUTF8(bytes(s));
		uint256[] memory ret = new uint256[](cps.length);
		(uint256 pos, uint256 len) = consumeEmoji(cps, 0, ret, 0, false);
		return pos == cps.length && len > 0;
	}

	// https://www.unicode.org/versions/Unicode14.0.0/ch03.pdf
	uint256 constant S0 = 0xAC00;
	uint256 constant L0 = 0x1100;
	uint256 constant V0 = 0x1161;
	uint256 constant T0 = 0x11A7;
	uint256 constant L_COUNT = 19;
	uint256 constant V_COUNT = 21;
	uint256 constant T_COUNT = 28;
	uint256 constant N_COUNT = V_COUNT * T_COUNT;
	uint256 constant S_COUNT = L_COUNT * N_COUNT;
	uint256 constant S1 = S0 + S_COUNT;
	uint256 constant L1 = L0 + L_COUNT;
	uint256 constant V1 = V0 + V_COUNT;
	uint256 constant T1 = T0 + T_COUNT;
	uint256 constant CP_MASK = 0xFFFFFF;

	function isHangul(uint256 cp) private pure returns (bool) {
		return cp >= S0 && cp < S1;
	}
	function getComposed(uint256 a, uint256 b) private view returns (uint256) {
		if (a >= L0 && a < L1 && b >= V0 && b < V1) { // LV
			return S0 + (a - L0) * N_COUNT + (b - V0) * T_COUNT;
		} else if (isHangul(a) && b > T0 && b < T1 && (a - S0) % T_COUNT == 0) {
			return a + (b - T0);
		} else {
			return getRecomp(a, b);
		}
	}

	function decodeUTF8(bytes memory src) private pure returns (uint256[] memory ret) {
		ret = new uint256[](src.length);
		uint256 ptr;
		assembly {
			ptr := src
		}
		uint256 len;
		uint256 end = ptr + src.length;
		while (ptr < end) {
			(uint256 cp, uint256 step) = readUTF8(ptr);
			ret[len++] = cp;
			ptr += step;
		}
		assembly {
			mstore(ret, len) // truncate
		}
	}

	// read one cp from memory at ptr
	// step is number of encoded bytes (1-4)
	// raw is encoded bytes
	// warning: assumes valid UTF8
	function readUTF8(uint256 ptr) private pure returns (uint256 cp, uint256 step) {
		// 0xxxxxxx => 1 :: 0aaaaaaa ???????? ???????? ???????? =>                   0aaaaaaa
		// 110xxxxx => 2 :: 110aaaaa 10bbbbbb ???????? ???????? =>          00000aaa aabbbbbb
		// 1110xxxx => 3 :: 1110aaaa 10bbbbbb 10cccccc ???????? => 000000aa aaaabbbb bbcccccc
		// 11110xxx => 4 :: 11110aaa 10bbbbbb 10cccccc 10dddddd => 000aaabb bbbbcccc ccdddddd
		uint256 raw;
		assembly {
			raw := and(mload(add(ptr, 4)), 0xFFFFFFFF)
		}
		uint256 upper = raw >> 28;
		if (upper < 0x8) {
			step = 1;
			raw >>= 24;
			cp = raw;
		} else if (upper < 0xE) {
			step = 2;
			raw >>= 16;
			cp = ((raw & 0x1F00) >> 2) | (raw & 0x3F);
		} else if (upper < 0xF) {
			step = 3;
			raw >>= 8;
			cp = ((raw & 0x0F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		} else {
			step = 4;
			cp = ((raw & 0x07000000) >> 6) | ((raw & 0x3F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		}
	}

	function encodeUTF8(uint256[] memory cps) private pure returns (bytes memory ret) {
		ret = new bytes(cps.length << 2);
		uint256 ret_off;
		assembly {
			ret_off := add(ret, 32)
		}
		uint256 ret_end = ret_off;
		for (uint256 i; i < cps.length; i++) {
			ret_end = writeUTF8(ret_end, cps[i] & CP_MASK);
		}
		assembly {
			mstore(ret, sub(ret_end, ret_off))
		}
	}

    function writeUTF8(uint256 ptr, uint256 cp) private pure returns (uint256) {
		if (cp < 0x80) {
            assembly {
                mstore8(ptr, cp)
            }
            return ptr + 1;
		} else if (cp < 0x800) {
            assembly {
                mstore8(ptr,         or(0xC0, shr(6, cp)))
                mstore8(add(ptr, 1), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 2;
		} else if (cp < 0x10000) {
            assembly {
                mstore8(ptr,         or(0xE0, shr(12, cp)))
                mstore8(add(ptr, 1), or(0x80, and(shr(6, cp), 0x3F)))
                mstore8(add(ptr, 2), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 3;
		} else {
            assembly {
                mstore8(ptr,         or(0xF0, shr(18, cp)))
                mstore8(add(ptr, 1), or(0x80, and(shr(12, cp), 0x3F)))
                mstore8(add(ptr, 2), or(0x80, and(shr(6, cp), 0x3F)))
                mstore8(add(ptr, 3), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 4;
		}
	}

	function process(uint256[] memory cps, bool pretty) public view returns (uint256[] memory ret, uint256 label_count) {
		ret = new uint256[](cps.length * 6); // maximum expansion factor
		label_count = 1;
		uint256 len;
		uint256 i;
		while(i < cps.length) {
			(uint256 new_i, uint256 new_len) = consumeEmoji(cps, i, ret, len, pretty);
			if (new_i > i) {
				i = new_i;
				if (pretty && (new_len & VALUE_EMOJI) != 0) {
					len = (new_len ^ VALUE_EMOJI) - 1;
					for (uint256 j = i + 1; j < len; j++) {
						ret[j] = ret[j+1];
					}
				} else {
					len = new_len;
				}
				continue;
			}
			uint256 cp = cps[i++];
			uint256 mapped = getMapped(cp); 
			if (mapped != 0) {
				ret[len++] = mapped;
				continue;
			}
			if (isValid(cp)) {		
				if (cp == STOP) label_count++;		
 				ret[len++] = cp;
				continue;
			}
			if (isIgnored(cp)) { 
				continue;
			}
			mapped = getSmall(cp);
			if (mapped != 0) {
				if (mapped < 0xFFFFFF) {
					ret[len++] = mapped;
				} else {
					ret[len++] = mapped >> 24;
					ret[len++] = mapped & 0xFFFFFF;
				}
				continue;
			}
			mapped = getLarge(cp);
			if (mapped == 0) revert InvalidCodepoint(cp);
			while (mapped != 0) {
				ret[len++] = mapped & 0x1FFFFF;
				mapped >>= 21;
			}
		}
		assembly {
			mstore(ret, len)
		}
	}

    function addClass(uint256 cp) private view returns (uint256) {
        return (getClass(cp) << 24) | cp;
    }
	function nfd(uint256[] memory cps) private view returns (uint256[] memory ret) {
        ret = new uint256[](cps.length * 3); // growth factor
        uint256 len;
        uint256 has_nz_class;
        for (uint256 i; i < cps.length; i++) {
            uint256 buf = cps[i];
            uint256 width = 32;
            while (width != 0) {
                uint256 cp = buf & 0xFFFFFFFF;
                buf >>= 32;
                width -= 32;
                if (cp < 0x80 || cp >= CP_MASK) {
                    ret[len++] = cp;
                } else if (isHangul(cp)) {
                    uint256 s_index = cp - S0;
                    uint256 l_index = s_index / N_COUNT | 0;
                    uint256 v_index = (s_index % N_COUNT) / T_COUNT | 0;
                    uint256 t_index = s_index % T_COUNT;
                    uint256 l_cp = addClass(L0 + l_index);
                    uint256 v_cp = addClass(V0 + v_index);
                    ret[len++] = l_cp;
                    ret[len++] = v_cp;
                    if (has_nz_class == 0 && (l_cp | v_cp) > CP_MASK) has_nz_class = 1;
                    if (t_index != 0) {
                        uint256 t_cp = addClass(T0 + t_index);
                        if (has_nz_class == 0 && t_cp > CP_MASK) has_nz_class = 1;
                        ret[len++] = t_cp;
                    }
                } else {
                    uint256 decomp = getDecomp(cp);
                    if (decomp != 0) {
                        buf |= (decomp << width);
                        width += (decomp >> 32) == 0 ? 32 : 64;
                    } else {
                        uint256 x_cp = addClass(cp);
                        if (has_nz_class == 0 && x_cp > CP_MASK) has_nz_class = 1;
                        ret[len++] = x_cp;
                    }
                }
            }
        }
        if (has_nz_class != 0) {
            uint256 prev = ret[0] >> 24;
            for (uint256 i = 1; i < len; i++) {
                uint256 rank = ret[i] >> 24;
                if (prev == 0 || rank == 0 || prev <= rank) {
                    prev = rank;
                    continue;
                }
                uint256 j = i - 1;
                while (true) {
                    (ret[j+1], ret[j]) = (ret[j], ret[j+1]);
                    if (j == 0) break;
                    prev = ret[--j] >> 24;
                    if (prev <= rank) break;
                }
                prev = ret[i] >> 24;
            }
        }
        assembly {
            mstore(ret, len) // truncate
        }
    }

	
	function nfc(uint256[] memory values) private view returns (bytes memory utf8) {
		utf8 = new bytes(values.length << 4);
		uint256 utf_off;
		assembly {
			utf_off := add(utf8, 32)
		}
		uint256 utf_end = utf_off;
		uint256 prev_cp;
		for (uint256 i; i < values.length; i++) {
			uint256 cp = values[i] & CP_MASK;
			if (prev_cp != 0) {
				if (cp >= 0x80) {
					uint256 composed = getComposed(prev_cp, cp);
					if (composed != 0) {
						prev_cp = composed;
						continue;
					}
				}
				utf_end = writeUTF8(utf_end, prev_cp);	
			}
			prev_cp = cp;	
		}
		if (prev_cp != 0) {
			utf_end = writeUTF8(utf_end, prev_cp);
		}
		assembly {
			mstore(utf8, sub(utf_end, utf_off))
		}
	}


	function post_check_label(uint256[] memory values, uint256 start, uint256 end) private view returns (bytes memory utf8) {
		uint256 len = end - start;
		if (len == 0) return ('');
		uint256 non_ascii;
		uint256 fail_if_underscore;
		uint256 fail_if_cm = 1;
		utf8 = new bytes(len << 4);
		uint256 utf_off;
		assembly {
			utf_off := add(utf8, 32)
		}
		uint256 utf_end = utf_off;
		uint256 prev_cp;
		while (start < end) {
			uint256 value = values[start++];
			uint256 cp = value & 0xFFFFFF;
			if (cp < 0x80) { // ascii
				if (cp == 0x5F) { // underscore
					require(fail_if_underscore == 0, "underscore");
				} else {
					fail_if_underscore = 1;
				}
				if (prev_cp != 0) {
					utf_end = writeUTF8(utf_end, prev_cp);	
				}
				prev_cp = cp;
				fail_if_cm = 0;
				continue;
			}
			non_ascii = 1;
			if (isCM(cp)) {
				require(fail_if_cm == 0, "cm");
				fail_if_cm = 1;
			} else if ((value & VALUE_EMOJI) != 0) {
				fail_if_cm = 1;
			} else {
				fail_if_cm = 0;
			}
			if (prev_cp != 0) {
				uint256 composed = getComposed(prev_cp, cp);
				if (composed != 0) {
					prev_cp = composed;
					continue;
				}
				utf_end = writeUTF8(utf_end, prev_cp);	
			}
			prev_cp = cp;	
		}
		utf_end = writeUTF8(utf_end, prev_cp);	
		// label extension
		if (len >= 4 && non_ascii == 0 && utf8[2] == '-' && utf8[3] == '-') {
			revert("label extension");
		}
		assembly {
			mstore(utf8, sub(utf_end, utf_off))
		}
	}

	uint256 constant VALUE_EMOJI = 0x80000000;

	function consumeEmoji(uint256[] memory cps, uint256 pos, uint256[] memory ret, uint256 len, bool add_fe0f) private view returns (uint256 out_pos, uint256 out_len) {
		uint256 state;
		uint256 saved;
		while (pos < cps.length) {
			uint256 cp = cps[pos++];
			state = getEmoji(state & EMOJI_STATE_MASK, cp);
			if (state == 0) break;
			if ((state & EMOJI_STATE_SAVE) != 0) { 
				saved = cp; 
			} else if ((state & EMOJI_STATE_CHECK) != 0) { 
				if (cp == saved) break;
			}
			ret[len++] = cp | VALUE_EMOJI;
			if ((state & EMOJI_STATE_FE0F) != 0) {
				if (add_fe0f) ret[len++] = 0xFE0F | VALUE_EMOJI;
				if (pos < cps.length && cps[pos] == 0xFE0F) pos++;
			}
			if ((state & EMOJI_STATE_VALID) != 0) {
				out_pos = pos;
				out_len = len;
				if (add_fe0f && (state & EMOJI_STATE_QUIRK) != 0) {
					out_len |= VALUE_EMOJI;
				}			
			}
		}
	}

/*
	function getMapped(uint256 cp) public pure returns (uint256 ret) {
        return 0;
    }*/

	// auto-generated
	function getMapped(uint256 cp) public pure returns (uint256 ret) {
		if (cp <= 0x1D734) {
			if (cp <= 0xFFB3) {
				if (cp <= 0x2099) {
					if (cp <= 0x1CBA) {
						if (cp <= 0x3FF) {
							if (cp <= 0xDE) {
								if (cp >= 0x41 && cp <= 0x5A) { // Mapped11: 26
									ret = cp + 0x20;
								} else if (cp >= 0xC0 && cp <= 0xD6) { // Mapped11: 23
									ret = cp + 0x20;
								} else if (cp >= 0xD8 && cp <= 0xDE) { // Mapped11: 7
									ret = cp + 0x20;
								}
							} else {
								if (cp >= 0x388 && cp <= 0x38A) { // Mapped11: 3
									ret = cp + 0x25;
								} else if (cp >= 0x391 && cp <= 0x3A1) { // Mapped11: 17
									ret = cp + 0x20;
								} else if (cp >= 0x3A3 && cp <= 0x3AB) { // Mapped11: 9
									ret = cp + 0x20;
								} else if (cp >= 0x3FD && cp <= 0x3FF) { // Mapped11: 3
									ret = cp - 0x82;
								}
							}
						} else {
							if (cp <= 0x556) {
								if (cp >= 0x400 && cp <= 0x40F) { // Mapped11: 16
									ret = cp + 0x50;
								} else if (cp >= 0x410 && cp <= 0x42F) { // Mapped11: 32
									ret = cp + 0x20;
								} else if (cp >= 0x531 && cp <= 0x556) { // Mapped11: 38
									ret = cp + 0x30;
								}
							} else {
								if (cp >= 0x6F0 && cp <= 0x6F3) { // Mapped11: 4
									ret = cp - 0x90;
								} else if (cp >= 0x6F7 && cp <= 0x6F9) { // Mapped11: 3
									ret = cp - 0x90;
								} else if (cp >= 0x13F8 && cp <= 0x13FD) { // Mapped11: 6
									ret = cp - 0x8;
								} else if (cp >= 0x1C90 && cp <= 0x1CBA) { // Mapped11: 43
									ret = cp - 0xBC0;
								}
							}
						}
					} else {
						if (cp <= 0x1F0F) {
							if (cp <= 0x1D5F) {
								if (cp >= 0x1CBD && cp <= 0x1CBF) { // Mapped11: 3
									ret = cp - 0xBC0;
								} else if (cp >= 0x1D33 && cp <= 0x1D3A) { // Mapped11: 8
									ret = cp - 0x1CCC;
								} else if (cp >= 0x1D5D && cp <= 0x1D5F) { // Mapped11: 3
									ret = cp - 0x19AB;
								}
							} else {
								if (cp >= 0x1DA4 && cp <= 0x1DA6) { // Mapped11: 3
									ret = cp - 0x1B3C;
								} else if (cp >= 0x1DAE && cp <= 0x1DB1) { // Mapped11: 4
									ret = cp - 0x1B3C;
								} else if (cp >= 0x1DBC && cp <= 0x1DBE) { // Mapped11: 3
									ret = cp - 0x1B2C;
								} else if (cp >= 0x1F08 && cp <= 0x1F0F) { // Mapped11: 8
									ret = cp - 0x8;
								}
							}
						} else {
							if (cp <= 0x1F4D) {
								if (cp >= 0x1F18 && cp <= 0x1F1D) { // Mapped11: 6
									ret = cp - 0x8;
								} else if (cp >= 0x1F28 && cp <= 0x1F2F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x1F38 && cp <= 0x1F3F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x1F48 && cp <= 0x1F4D) { // Mapped11: 6
									ret = cp - 0x8;
								}
							} else {
								if (cp >= 0x1F68 && cp <= 0x1F6F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x2074 && cp <= 0x2079) { // Mapped11: 6
									ret = cp - 0x2040;
								} else if (cp >= 0x2080 && cp <= 0x2089) { // Mapped11: 10
									ret = cp - 0x2050;
								} else if (cp >= 0x2096 && cp <= 0x2099) { // Mapped11: 4
									ret = cp - 0x202B;
								}
							}
						}
					}
				} else {
					if (cp <= 0x32E9) {
						if (cp <= 0x313F) {
							if (cp <= 0x24CF) {
								if (cp >= 0x2135 && cp <= 0x2138) { // Mapped11: 4
									ret = cp - 0x1B65;
								} else if (cp >= 0x2460 && cp <= 0x2468) { // Mapped11: 9
									ret = cp - 0x242F;
								} else if (cp >= 0x24B6 && cp <= 0x24CF) { // Mapped11: 26
									ret = cp - 0x2455;
								}
							} else {
								if (cp >= 0x24D0 && cp <= 0x24E9) { // Mapped11: 26
									ret = cp - 0x246F;
								} else if (cp >= 0x2C00 && cp <= 0x2C2F) { // Mapped11: 48
									ret = cp + 0x30;
								} else if (cp >= 0x3137 && cp <= 0x3139) { // Mapped11: 3
									ret = cp - 0x2034;
								} else if (cp >= 0x313A && cp <= 0x313F) { // Mapped11: 6
									ret = cp - 0x1F8A;
								}
							}
						} else {
							if (cp <= 0x317C) {
								if (cp >= 0x3141 && cp <= 0x3143) { // Mapped11: 3
									ret = cp - 0x203B;
								} else if (cp >= 0x3145 && cp <= 0x314E) { // Mapped11: 10
									ret = cp - 0x203C;
								} else if (cp >= 0x314F && cp <= 0x3163) { // Mapped11: 21
									ret = cp - 0x1FEE;
								} else if (cp >= 0x3178 && cp <= 0x317C) { // Mapped11: 5
									ret = cp - 0x204D;
								}
							} else {
								if (cp >= 0x3184 && cp <= 0x3186) { // Mapped11: 3
									ret = cp - 0x202D;
								} else if (cp >= 0x3263 && cp <= 0x3265) { // Mapped11: 3
									ret = cp - 0x215E;
								} else if (cp >= 0x3269 && cp <= 0x326D) { // Mapped11: 5
									ret = cp - 0x215B;
								} else if (cp >= 0x32E4 && cp <= 0x32E9) { // Mapped11: 6
									ret = cp - 0x21A;
								}
							}
						}
					} else {
						if (cp <= 0xFF19) {
							if (cp <= 0x32FE) {
								if (cp >= 0x32EE && cp <= 0x32F2) { // Mapped11: 5
									ret = cp - 0x210;
								} else if (cp >= 0x32F5 && cp <= 0x32FA) { // Mapped11: 6
									ret = cp - 0x20D;
								} else if (cp >= 0x32FB && cp <= 0x32FE) { // Mapped11: 4
									ret = cp - 0x20C;
								}
							} else {
								if (cp >= 0xAB70 && cp <= 0xABBF) { // Mapped11: 80
									ret = cp - 0x97D0;
								} else if (cp >= 0xFB24 && cp <= 0xFB26) { // Mapped11: 3
									ret = cp - 0xF549;
								} else if (cp >= 0xFE41 && cp <= 0xFE44) { // Mapped11: 4
									ret = cp - 0xCE35;
								} else if (cp >= 0xFF10 && cp <= 0xFF19) { // Mapped11: 10
									ret = cp - 0xFEE0;
								}
							}
						} else {
							if (cp <= 0xFF93) {
								if (cp >= 0xFF21 && cp <= 0xFF3A) { // Mapped11: 26
									ret = cp - 0xFEC0;
								} else if (cp >= 0xFF41 && cp <= 0xFF5A) { // Mapped11: 26
									ret = cp - 0xFEE0;
								} else if (cp >= 0xFF85 && cp <= 0xFF8A) { // Mapped11: 6
									ret = cp - 0xCEBB;
								} else if (cp >= 0xFF8F && cp <= 0xFF93) { // Mapped11: 5
									ret = cp - 0xCEB1;
								}
							} else {
								if (cp >= 0xFF96 && cp <= 0xFF9B) { // Mapped11: 6
									ret = cp - 0xCEAE;
								} else if (cp >= 0xFFA7 && cp <= 0xFFA9) { // Mapped11: 3
									ret = cp - 0xEEA4;
								} else if (cp >= 0xFFAA && cp <= 0xFFAF) { // Mapped11: 6
									ret = cp - 0xEDFA;
								} else if (cp >= 0xFFB1 && cp <= 0xFFB3) { // Mapped11: 3
									ret = cp - 0xEEAB;
								}
							}
						}
					}
				}
			} else {
				if (cp <= 0x1D503) {
					if (cp <= 0x118BF) {
						if (cp <= 0x10427) {
							if (cp <= 0xFFCF) {
								if (cp >= 0xFFB5 && cp <= 0xFFBE) { // Mapped11: 10
									ret = cp - 0xEEAC;
								} else if (cp >= 0xFFC2 && cp <= 0xFFC7) { // Mapped11: 6
									ret = cp - 0xEE61;
								} else if (cp >= 0xFFCA && cp <= 0xFFCF) { // Mapped11: 6
									ret = cp - 0xEE63;
								}
							} else {
								if (cp >= 0xFFD2 && cp <= 0xFFD7) { // Mapped11: 6
									ret = cp - 0xEE65;
								} else if (cp >= 0xFFDA && cp <= 0xFFDC) { // Mapped11: 3
									ret = cp - 0xEE67;
								} else if (cp >= 0xFFE9 && cp <= 0xFFEC) { // Mapped11: 4
									ret = cp - 0xDE59;
								} else if (cp >= 0x10400 && cp <= 0x10427) { // Mapped11: 40
									ret = cp + 0x28;
								}
							}
						} else {
							if (cp <= 0x1058A) {
								if (cp >= 0x104B0 && cp <= 0x104D3) { // Mapped11: 36
									ret = cp + 0x28;
								} else if (cp >= 0x10570 && cp <= 0x1057A) { // Mapped11: 11
									ret = cp + 0x27;
								} else if (cp >= 0x1057C && cp <= 0x1058A) { // Mapped11: 15
									ret = cp + 0x27;
								}
							} else {
								if (cp >= 0x1058C && cp <= 0x10592) { // Mapped11: 7
									ret = cp + 0x27;
								} else if (cp >= 0x107B6 && cp <= 0x107B8) { // Mapped11: 3
									ret = cp - 0x105F6;
								} else if (cp >= 0x10C80 && cp <= 0x10CB2) { // Mapped11: 51
									ret = cp + 0x40;
								} else if (cp >= 0x118A0 && cp <= 0x118BF) { // Mapped11: 32
									ret = cp + 0x20;
								}
							}
						}
					} else {
						if (cp <= 0x1D481) {
							if (cp <= 0x1D433) {
								if (cp >= 0x16E40 && cp <= 0x16E5F) { // Mapped11: 32
									ret = cp + 0x20;
								} else if (cp >= 0x1D400 && cp <= 0x1D419) { // Mapped11: 26
									ret = cp - 0x1D39F;
								} else if (cp >= 0x1D41A && cp <= 0x1D433) { // Mapped11: 26
									ret = cp - 0x1D3B9;
								}
							} else {
								if (cp >= 0x1D434 && cp <= 0x1D44D) { // Mapped11: 26
									ret = cp - 0x1D3D3;
								} else if (cp >= 0x1D44E && cp <= 0x1D454) { // Mapped11: 7
									ret = cp - 0x1D3ED;
								} else if (cp >= 0x1D456 && cp <= 0x1D467) { // Mapped11: 18
									ret = cp - 0x1D3ED;
								} else if (cp >= 0x1D468 && cp <= 0x1D481) { // Mapped11: 26
									ret = cp - 0x1D407;
								}
							}
						} else {
							if (cp <= 0x1D4B9) {
								if (cp >= 0x1D482 && cp <= 0x1D49B) { // Mapped11: 26
									ret = cp - 0x1D421;
								} else if (cp >= 0x1D4A9 && cp <= 0x1D4AC) { // Mapped11: 4
									ret = cp - 0x1D43B;
								} else if (cp >= 0x1D4AE && cp <= 0x1D4B5) { // Mapped11: 8
									ret = cp - 0x1D43B;
								} else if (cp >= 0x1D4B6 && cp <= 0x1D4B9) { // Mapped11: 4
									ret = cp - 0x1D455;
								}
							} else {
								if (cp >= 0x1D4BD && cp <= 0x1D4C3) { // Mapped11: 7
									ret = cp - 0x1D455;
								} else if (cp >= 0x1D4C5 && cp <= 0x1D4CF) { // Mapped11: 11
									ret = cp - 0x1D455;
								} else if (cp >= 0x1D4D0 && cp <= 0x1D4E9) { // Mapped11: 26
									ret = cp - 0x1D46F;
								} else if (cp >= 0x1D4EA && cp <= 0x1D503) { // Mapped11: 26
									ret = cp - 0x1D489;
								}
							}
						}
					}
				} else {
					if (cp <= 0x1D621) {
						if (cp <= 0x1D550) {
							if (cp <= 0x1D51C) {
								if (cp >= 0x1D507 && cp <= 0x1D50A) { // Mapped11: 4
									ret = cp - 0x1D4A3;
								} else if (cp >= 0x1D50D && cp <= 0x1D514) { // Mapped11: 8
									ret = cp - 0x1D4A3;
								} else if (cp >= 0x1D516 && cp <= 0x1D51C) { // Mapped11: 7
									ret = cp - 0x1D4A3;
								}
							} else {
								if (cp >= 0x1D51E && cp <= 0x1D537) { // Mapped11: 26
									ret = cp - 0x1D4BD;
								} else if (cp >= 0x1D53B && cp <= 0x1D53E) { // Mapped11: 4
									ret = cp - 0x1D4D7;
								} else if (cp >= 0x1D540 && cp <= 0x1D544) { // Mapped11: 5
									ret = cp - 0x1D4D7;
								} else if (cp >= 0x1D54A && cp <= 0x1D550) { // Mapped11: 7
									ret = cp - 0x1D4D7;
								}
							}
						} else {
							if (cp <= 0x1D5B9) {
								if (cp >= 0x1D552 && cp <= 0x1D56B) { // Mapped11: 26
									ret = cp - 0x1D4F1;
								} else if (cp >= 0x1D56C && cp <= 0x1D585) { // Mapped11: 26
									ret = cp - 0x1D50B;
								} else if (cp >= 0x1D586 && cp <= 0x1D59F) { // Mapped11: 26
									ret = cp - 0x1D525;
								} else if (cp >= 0x1D5A0 && cp <= 0x1D5B9) { // Mapped11: 26
									ret = cp - 0x1D53F;
								}
							} else {
								if (cp >= 0x1D5BA && cp <= 0x1D5D3) { // Mapped11: 26
									ret = cp - 0x1D559;
								} else if (cp >= 0x1D5D4 && cp <= 0x1D5ED) { // Mapped11: 26
									ret = cp - 0x1D573;
								} else if (cp >= 0x1D5EE && cp <= 0x1D607) { // Mapped11: 26
									ret = cp - 0x1D58D;
								} else if (cp >= 0x1D608 && cp <= 0x1D621) { // Mapped11: 26
									ret = cp - 0x1D5A7;
								}
							}
						}
					} else {
						if (cp <= 0x1D6C0) {
							if (cp <= 0x1D66F) {
								if (cp >= 0x1D622 && cp <= 0x1D63B) { // Mapped11: 26
									ret = cp - 0x1D5C1;
								} else if (cp >= 0x1D63C && cp <= 0x1D655) { // Mapped11: 26
									ret = cp - 0x1D5DB;
								} else if (cp >= 0x1D656 && cp <= 0x1D66F) { // Mapped11: 26
									ret = cp - 0x1D5F5;
								}
							} else {
								if (cp >= 0x1D670 && cp <= 0x1D689) { // Mapped11: 26
									ret = cp - 0x1D60F;
								} else if (cp >= 0x1D68A && cp <= 0x1D6A3) { // Mapped11: 26
									ret = cp - 0x1D629;
								} else if (cp >= 0x1D6A8 && cp <= 0x1D6B8) { // Mapped11: 17
									ret = cp - 0x1D2F7;
								} else if (cp >= 0x1D6BA && cp <= 0x1D6C0) { // Mapped11: 7
									ret = cp - 0x1D2F7;
								}
							}
						} else {
							if (cp <= 0x1D6FA) {
								if (cp >= 0x1D6C2 && cp <= 0x1D6D2) { // Mapped11: 17
									ret = cp - 0x1D311;
								} else if (cp >= 0x1D6D4 && cp <= 0x1D6DA) { // Mapped11: 7
									ret = cp - 0x1D311;
								} else if (cp >= 0x1D6E2 && cp <= 0x1D6F2) { // Mapped11: 17
									ret = cp - 0x1D331;
								} else if (cp >= 0x1D6F4 && cp <= 0x1D6FA) { // Mapped11: 7
									ret = cp - 0x1D331;
								}
							} else {
								if (cp >= 0x1D6FC && cp <= 0x1D70C) { // Mapped11: 17
									ret = cp - 0x1D34B;
								} else if (cp >= 0x1D70E && cp <= 0x1D714) { // Mapped11: 7
									ret = cp - 0x1D34B;
								} else if (cp >= 0x1D71C && cp <= 0x1D72C) { // Mapped11: 17
									ret = cp - 0x1D36B;
								} else if (cp >= 0x1D72E && cp <= 0x1D734) { // Mapped11: 7
									ret = cp - 0x1D36B;
								}
							}
						}
					}
				}
			}
		} else {
			if (cp <= 0xFB69) {
				if (cp <= 0x1DB) {
					if (cp <= 0x1D7F5) {
						if (cp <= 0x1D7A0) {
							if (cp <= 0x1D766) {
								if (cp >= 0x1D736 && cp <= 0x1D746) { // Mapped11: 17
									ret = cp - 0x1D385;
								} else if (cp >= 0x1D748 && cp <= 0x1D74E) { // Mapped11: 7
									ret = cp - 0x1D385;
								} else if (cp >= 0x1D756 && cp <= 0x1D766) { // Mapped11: 17
									ret = cp - 0x1D3A5;
								}
							} else {
								if (cp >= 0x1D768 && cp <= 0x1D76E) { // Mapped11: 7
									ret = cp - 0x1D3A5;
								} else if (cp >= 0x1D770 && cp <= 0x1D780) { // Mapped11: 17
									ret = cp - 0x1D3BF;
								} else if (cp >= 0x1D782 && cp <= 0x1D788) { // Mapped11: 7
									ret = cp - 0x1D3BF;
								} else if (cp >= 0x1D790 && cp <= 0x1D7A0) { // Mapped11: 17
									ret = cp - 0x1D3DF;
								}
							}
						} else {
							if (cp <= 0x1D7C2) {
								if (cp >= 0x1D7A2 && cp <= 0x1D7A8) { // Mapped11: 7
									ret = cp - 0x1D3DF;
								} else if (cp >= 0x1D7AA && cp <= 0x1D7BA) { // Mapped11: 17
									ret = cp - 0x1D3F9;
								} else if (cp >= 0x1D7BC && cp <= 0x1D7C2) { // Mapped11: 7
									ret = cp - 0x1D3F9;
								}
							} else {
								if (cp >= 0x1D7CE && cp <= 0x1D7D7) { // Mapped11: 10
									ret = cp - 0x1D79E;
								} else if (cp >= 0x1D7D8 && cp <= 0x1D7E1) { // Mapped11: 10
									ret = cp - 0x1D7A8;
								} else if (cp >= 0x1D7E2 && cp <= 0x1D7EB) { // Mapped11: 10
									ret = cp - 0x1D7B2;
								} else if (cp >= 0x1D7EC && cp <= 0x1D7F5) { // Mapped11: 10
									ret = cp - 0x1D7BC;
								}
							}
						}
					} else {
						if (cp <= 0x1F149) {
							if (cp <= 0x1EE0D) {
								if (cp >= 0x1D7F6 && cp <= 0x1D7FF) { // Mapped11: 10
									ret = cp - 0x1D7C6;
								} else if (cp >= 0x1E900 && cp <= 0x1E921) { // Mapped11: 34
									ret = cp + 0x22;
								} else if (cp >= 0x1EE0A && cp <= 0x1EE0D) { // Mapped11: 4
									ret = cp - 0x1E7C7;
								}
							} else {
								if (cp >= 0x1EE2A && cp <= 0x1EE2D) { // Mapped11: 4
									ret = cp - 0x1E7E7;
								} else if (cp >= 0x1EE8B && cp <= 0x1EE8D) { // Mapped11: 3
									ret = cp - 0x1E847;
								} else if (cp >= 0x1EEAB && cp <= 0x1EEAD) { // Mapped11: 3
									ret = cp - 0x1E867;
								} else if (cp >= 0x1F130 && cp <= 0x1F149) { // Mapped11: 26
									ret = cp - 0x1F0CF;
								}
							}
						} else {
							if (cp <= 0x147) {
								if (cp >= 0x1FBF0 && cp <= 0x1FBF9) { // Mapped11: 10
									ret = cp - 0x1FBC0;
								} else if (cp >= 0x100 && cp < 0x130 && (cp & 1 == 0)) { // Mapped22: 24
									ret = cp + 1;
								} else if (cp >= 0x139 && cp < 0x13F && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x141 && cp < 0x149 && (cp & 1 == 0)) { // Mapped22: 4
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x14A && cp < 0x178 && (cp & 1 == 0)) { // Mapped22: 23
									ret = cp + 1;
								} else if (cp >= 0x179 && cp < 0x17F && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x1A0 && cp < 0x1A6 && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x1CD && cp < 0x1DD && (cp & 1 == 0)) { // Mapped22: 8
									ret = cp + 1;
								}
							}
						}
					}
				} else {
					if (cp <= 0xA69A) {
						if (cp <= 0x4BE) {
							if (cp <= 0x232) {
								if (cp >= 0x1DE && cp < 0x1F0 && (cp & 1 == 0)) { // Mapped22: 9
									ret = cp + 1;
								} else if (cp >= 0x1F8 && cp < 0x220 && (cp & 1 == 0)) { // Mapped22: 20
									ret = cp + 1;
								} else if (cp >= 0x222 && cp < 0x234 && (cp & 1 == 0)) { // Mapped22: 9
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x246 && cp < 0x250 && (cp & 1 == 0)) { // Mapped22: 5
									ret = cp + 1;
								} else if (cp >= 0x3D8 && cp < 0x3F0 && (cp & 1 == 0)) { // Mapped22: 12
									ret = cp + 1;
								} else if (cp >= 0x460 && cp < 0x482 && (cp & 1 == 0)) { // Mapped22: 17
									ret = cp + 1;
								} else if (cp >= 0x48A && cp < 0x4C0 && (cp & 1 == 0)) { // Mapped22: 27
									ret = cp + 1;
								}
							}
						} else {
							if (cp <= 0x1EFE) {
								if (cp >= 0x4C1 && cp < 0x4CF && (cp & 1 == 0)) { // Mapped22: 7
									ret = cp + 1;
								} else if (cp >= 0x4D0 && cp < 0x530 && (cp & 1 == 0)) { // Mapped22: 48
									ret = cp + 1;
								} else if (cp >= 0x1E00 && cp < 0x1E96 && (cp & 1 == 0)) { // Mapped22: 75
									ret = cp + 1;
								} else if (cp >= 0x1EA0 && cp < 0x1F00 && (cp & 1 == 0)) { // Mapped22: 48
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x2C67 && cp < 0x2C6D && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x2C80 && cp < 0x2CE4 && (cp & 1 == 0)) { // Mapped22: 50
									ret = cp + 1;
								} else if (cp >= 0xA640 && cp < 0xA66E && (cp & 1 == 0)) { // Mapped22: 23
									ret = cp + 1;
								} else if (cp >= 0xA680 && cp < 0xA69C && (cp & 1 == 0)) { // Mapped22: 14
									ret = cp + 1;
								}
							}
						}
					} else {
						if (cp <= 0x210E) {
							if (cp <= 0xA786) {
								if (cp >= 0xA722 && cp < 0xA730 && (cp & 1 == 0)) { // Mapped22: 7
									ret = cp + 1;
								} else if (cp >= 0xA732 && cp < 0xA770 && (cp & 1 == 0)) { // Mapped22: 31
									ret = cp + 1;
								} else if (cp >= 0xA77E && cp < 0xA788 && (cp & 1 == 0)) { // Mapped22: 5
									ret = cp + 1;
								}
							} else {
								if (cp >= 0xA796 && cp < 0xA7AA && (cp & 1 == 0)) { // Mapped22: 10
									ret = cp + 1;
								} else if (cp >= 0xA7B4 && cp < 0xA7C4 && (cp & 1 == 0)) { // Mapped22: 8
									ret = cp + 1;
								} else if (cp >= 0x2010 && cp <= 0x2015) { // Mapped10: 6
									ret = 0x2D;
								} else if (cp >= 0x210B && cp <= 0x210E) { // Mapped10: 4
									ret = 0x68;
								}
							}
						} else {
							if (cp <= 0xFB59) {
								if (cp >= 0x211B && cp <= 0x211D) { // Mapped10: 3
									ret = 0x72;
								} else if (cp >= 0x23BA && cp <= 0x23BD) { // Mapped10: 4
									ret = 0x2D;
								} else if (cp >= 0xFB52 && cp <= 0xFB55) { // Mapped10: 4
									ret = 0x67B;
								} else if (cp >= 0xFB56 && cp <= 0xFB59) { // Mapped10: 4
									ret = 0x67E;
								}
							} else {
								if (cp >= 0xFB5A && cp <= 0xFB5D) { // Mapped10: 4
									ret = 0x680;
								} else if (cp >= 0xFB5E && cp <= 0xFB61) { // Mapped10: 4
									ret = 0x67A;
								} else if (cp >= 0xFB62 && cp <= 0xFB65) { // Mapped10: 4
									ret = 0x67F;
								} else if (cp >= 0xFB66 && cp <= 0xFB69) { // Mapped10: 4
									ret = 0x679;
								}
							}
						}
					}
				}
			} else {
				if (cp <= 0xFECC) {
					if (cp <= 0xFBE7) {
						if (cp <= 0xFB91) {
							if (cp <= 0xFB75) {
								if (cp >= 0xFB6A && cp <= 0xFB6D) { // Mapped10: 4
									ret = 0x6A4;
								} else if (cp >= 0xFB6E && cp <= 0xFB71) { // Mapped10: 4
									ret = 0x6A6;
								} else if (cp >= 0xFB72 && cp <= 0xFB75) { // Mapped10: 4
									ret = 0x684;
								}
							} else {
								if (cp >= 0xFB76 && cp <= 0xFB79) { // Mapped10: 4
									ret = 0x683;
								} else if (cp >= 0xFB7A && cp <= 0xFB7D) { // Mapped10: 4
									ret = 0x686;
								} else if (cp >= 0xFB7E && cp <= 0xFB81) { // Mapped10: 4
									ret = 0x687;
								} else if (cp >= 0xFB8E && cp <= 0xFB91) { // Mapped10: 4
									ret = 0x6A9;
								}
							}
						} else {
							if (cp <= 0xFBA3) {
								if (cp >= 0xFB92 && cp <= 0xFB95) { // Mapped10: 4
									ret = 0x6AF;
								} else if (cp >= 0xFB96 && cp <= 0xFB99) { // Mapped10: 4
									ret = 0x6B3;
								} else if (cp >= 0xFB9A && cp <= 0xFB9D) { // Mapped10: 4
									ret = 0x6B1;
								} else if (cp >= 0xFBA0 && cp <= 0xFBA3) { // Mapped10: 4
									ret = 0x6BB;
								}
							} else {
								if (cp >= 0xFBA6 && cp <= 0xFBA9) { // Mapped10: 4
									ret = 0x6C1;
								} else if (cp >= 0xFBAA && cp <= 0xFBAD) { // Mapped10: 4
									ret = 0x6BE;
								} else if (cp >= 0xFBD3 && cp <= 0xFBD6) { // Mapped10: 4
									ret = 0x6AD;
								} else if (cp >= 0xFBE4 && cp <= 0xFBE7) { // Mapped10: 4
									ret = 0x6D0;
								}
							}
						}
					} else {
						if (cp <= 0xFEA4) {
							if (cp <= 0xFE92) {
								if (cp >= 0xFBFC && cp <= 0xFBFF) { // Mapped10: 4
									ret = 0x6CC;
								} else if (cp >= 0xFE89 && cp <= 0xFE8C) { // Mapped10: 4
									ret = 0x626;
								} else if (cp >= 0xFE8F && cp <= 0xFE92) { // Mapped10: 4
									ret = 0x628;
								}
							} else {
								if (cp >= 0xFE95 && cp <= 0xFE98) { // Mapped10: 4
									ret = 0x62A;
								} else if (cp >= 0xFE99 && cp <= 0xFE9C) { // Mapped10: 4
									ret = 0x62B;
								} else if (cp >= 0xFE9D && cp <= 0xFEA0) { // Mapped10: 4
									ret = 0x62C;
								} else if (cp >= 0xFEA1 && cp <= 0xFEA4) { // Mapped10: 4
									ret = 0x62D;
								}
							}
						} else {
							if (cp <= 0xFEBC) {
								if (cp >= 0xFEA5 && cp <= 0xFEA8) { // Mapped10: 4
									ret = 0x62E;
								} else if (cp >= 0xFEB1 && cp <= 0xFEB4) { // Mapped10: 4
									ret = 0x633;
								} else if (cp >= 0xFEB5 && cp <= 0xFEB8) { // Mapped10: 4
									ret = 0x634;
								} else if (cp >= 0xFEB9 && cp <= 0xFEBC) { // Mapped10: 4
									ret = 0x635;
								}
							} else {
								if (cp >= 0xFEBD && cp <= 0xFEC0) { // Mapped10: 4
									ret = 0x636;
								} else if (cp >= 0xFEC1 && cp <= 0xFEC4) { // Mapped10: 4
									ret = 0x637;
								} else if (cp >= 0xFEC5 && cp <= 0xFEC8) { // Mapped10: 4
									ret = 0x638;
								} else if (cp >= 0xFEC9 && cp <= 0xFECC) { // Mapped10: 4
									ret = 0x639;
								}
							}
						}
					}
				} else {
					if (cp <= 0xD7A3) {
						if (cp <= 0xFEE8) {
							if (cp <= 0xFED8) {
								if (cp >= 0xFECD && cp <= 0xFED0) { // Mapped10: 4
									ret = 0x63A;
								} else if (cp >= 0xFED1 && cp <= 0xFED4) { // Mapped10: 4
									ret = 0x641;
								} else if (cp >= 0xFED5 && cp <= 0xFED8) { // Mapped10: 4
									ret = 0x642;
								}
							} else {
								if (cp >= 0xFED9 && cp <= 0xFEDC) { // Mapped10: 4
									ret = 0x643;
								} else if (cp >= 0xFEDD && cp <= 0xFEE0) { // Mapped10: 4
									ret = 0x644;
								} else if (cp >= 0xFEE1 && cp <= 0xFEE4) { // Mapped10: 4
									ret = 0x645;
								} else if (cp >= 0xFEE5 && cp <= 0xFEE8) { // Mapped10: 4
									ret = 0x646;
								}
							}
						} else {
							if (cp <= 0x167F) {
								if (cp >= 0xFEE9 && cp <= 0xFEEC) { // Mapped10: 4
									ret = 0x647;
								} else if (cp >= 0xFEF1 && cp <= 0xFEF4) { // Mapped10: 4
									ret = 0x64A;
								} else if (cp >= 0x2F831 && cp <= 0x2F833) { // Mapped10: 3
									ret = 0x537F;
								} else if (cp >= 0x1400 && cp <= 0x167F) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x2801 && cp <= 0x2933) { // Valid
									ret = cp;
								} else if (cp >= 0x3400 && cp <= 0xA48C) { // Valid
									ret = cp;
								} else if (cp >= 0xA4D0 && cp <= 0xA62B) { // Valid
									ret = cp;
								} else if (cp >= 0xAC00 && cp <= 0xD7A3) { // Valid
									ret = cp;
								}
							}
						}
					} else {
						if (cp <= 0x18CD5) {
							if (cp <= 0x1342E) {
								if (cp >= 0x10600 && cp <= 0x10736) { // Valid
									ret = cp;
								} else if (cp >= 0x11FFF && cp <= 0x12399) { // Valid
									ret = cp;
								} else if (cp >= 0x13000 && cp <= 0x1342E) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x14400 && cp <= 0x14646) { // Valid
									ret = cp;
								} else if (cp >= 0x16800 && cp <= 0x16A38) { // Valid
									ret = cp;
								} else if (cp >= 0x17000 && cp <= 0x187F7) { // Valid
									ret = cp;
								} else if (cp >= 0x18800 && cp <= 0x18CD5) { // Valid
									ret = cp;
								}
							}
						} else {
							if (cp <= 0x2A6DF) {
								if (cp >= 0x1B000 && cp <= 0x1B122) { // Valid
									ret = cp;
								} else if (cp >= 0x1B170 && cp <= 0x1B2FB) { // Valid
									ret = cp;
								} else if (cp >= 0x1D800 && cp <= 0x1DA8B) { // Valid
									ret = cp;
								} else if (cp >= 0x20000 && cp <= 0x2A6DF) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x2A700 && cp <= 0x2B738) { // Valid
									ret = cp;
								} else if (cp >= 0x2B820 && cp <= 0x2CEA1) { // Valid
									ret = cp;
								} else if (cp >= 0x2CEB0 && cp <= 0x2EBE0) { // Valid
									ret = cp;
								} else if (cp >= 0x30000 && cp <= 0x3134A) { // Valid
									ret = cp;
								}
							}
						}
					}
				}
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

/* SPDX-License-Identifier: MIT

      ********************************
      * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
      * ░░░██████████████████████░░░ *
      * ░░░██░░░░░░██░░░░░░████░░░░░ *
      * ░░░██░░░░░░██░░░░░░██░░░░░░░ *
      * ░░░██████████████████░░░░░░░ *
      * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
      ************************♥tt****/

// onchainAlpha.sol is a fork of IndelibleERC721A.sol by Michael Hirsch
// With modifications by ogkenobi.eth

pragma solidity 0.8.17;

import "./helpers/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./helpers/SSTORE2.sol";
import "./helpers/DynamicBuffer.sol";
import "./helpers/HelperLib.sol";
import "./helpers/Normalize4.sol";

contract OnChainAlpha is ERC721A, IERC721Receiver, ReentrancyGuard, Ownable {
    using HelperLib for uint256;
    using DynamicBuffer for bytes;

    event AttributesUpdated(
        uint256 tokenId,
        string userName,
        string social,
        string website,
        string profileName
    );
    event LabelsValuesUpdated(
        uint256 tokenId,
        uint256 labelId,
        string customLabels,
        string customValues
    );
    event LayersUpdated(uint256 tokenId, bool[] layerIsHidden);
    event LayersRevealed(uint256 tokenId, bool[] layerIsRevealed);
    event ImagePhlipped(uint256 tokenId, bool isPhlipped);
    event bgChanged(uint256 tokenId, string color);

    struct TraitDTO {
        string name;
        string mimetype;
        bytes data;
    }

    struct Trait {
        string name;
        string mimetype;
    }

    struct AlphaToken {
        Profile AlphaProfile;
        mapping(uint => string) labels;
        mapping(uint => string) values;
        uint256 labelcount;
    }

    struct Profile {
        string userName;
        string social;
        string website;
        string profileName;
    }

    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint256 royalties;
        string royaltiesRecipient;
    }

    mapping(uint256 => address[]) internal _traitDataPointers;
    mapping(uint256 => mapping(uint256 => Trait)) internal _traitDetails;
    mapping(uint256 => bool) internal _renderTokenOffChain;
    mapping(uint256 => mapping(uint256 => bool)) internal hideLayer;
    mapping(uint256 => mapping(uint256 => bool)) internal _revealLayer;
    mapping(uint256 => bool) internal _phlipImage;
    mapping(uint256 => AlphaToken) idValues;
    mapping(uint256 => string) bgColor;
    mapping(address => uint256) rebates;
    mapping(uint256 => bool) ogMints;
    mapping(address => uint256) mints;
    Normalize4 public normalizer;

    uint256 private constant NUM_LAYERS = 15;
    uint256 private constant MAX_BATCH_MINT = 10;
    uint256[][NUM_LAYERS] private TIERS;
    string[] private LAYER_NAMES = [
        unicode"Special",
        unicode"-",
        unicode"Mouth Special",
        unicode"-",
        unicode"Headwear",
        unicode"-",
        unicode"Eyewear",
        unicode"-",
        unicode"Eyes",
        unicode"-",
        unicode"Mouth",
        unicode"-",
        unicode"Ears",
        unicode"-",
        unicode"Body"
    ];

    function setLayerNames(string[] memory _names) public onlyOwner {
        LAYER_NAMES = _names;
    }

    // bool public isContractSealed;
    address public reRollDuplicateRole = 0x51A83198deC9EfF470492AE5765aE907dB94F769;
    address public faContract = 0xbD2075e820FD448A3AD7b2A6a593BAC56534a950;
    uint256 public constant maxSupply = 7777;
    uint256 public mintPrice = 0.00005 ether;
    uint256 public rebateAmt = 0.00002 ether;
    string public baseURI = "https://static.flooredApe.io/oca/tokenId/";
    bool public isPublicMintActive = true;

    ContractData public contractData =
        ContractData(
            unicode"On-Chain Alpha",
            unicode"On-Chain Alpha is a collection of 7777 customizable digital identity tokens stored entirely on the Ethereum blockchain. Token holders can visit https://oca.wtf to enable/disable existing traits, change background color, flip the image, enable Twitter hex, and more as well as reveal new trait drops to be released in the future.",
            "url for collection image",
            "url for banner image",
            "https://oca.wtf",
            500,
            "0x957356F9412830c992D465FF8CDb9b0AA023020b"
        );

    constructor() ERC721A("On-Chain Alpha", "OCA") {
        TIERS[0] = [10,25,50,75,100,500,7017]; //special 0
        TIERS[1] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[2] = [50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,1777]; //mouth special 1
        TIERS[3] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[4] = [10,20,40,60,80,100,120,140,160,180,200,220,240,260,280,300,320,340,360,380,400,420,440,460,480,500,520,747]; //headwear 2
        TIERS[5] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[6] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027]; //eyewear 3
        TIERS[7] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[8] = [25,40,80,110,140,170,200,230,260,290,320,350,380,410,440,470,500,530,570,610,650,1002]; //eyes 4
        TIERS[9] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[10] = [100,200,250,300,350,400,450,500,550,600,650,700,750,850,1000,1727]; //mouth 5
        TIERS[11] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[12] = [200,300,400,500,600,700,800,900,1000,1100,1200,1300,1477]; //ears 6
        TIERS[13] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[14] = [75,100,150,200,250,300,350,400,450,500,550,600,700,800,900,1452,0]; //body 7
    }

    function rarityGen(uint256 _randinput, uint256 _rarityTier)
        internal
        view
        returns (uint256)
    {
        uint256 currentLowerBound = 0;
        for (uint256 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint256 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        return TIERS[_rarityTier].length - 1;
    }

    modifier whenMintActive() {
        require(isMintActive());
        _;
    }

    function entropyForExtraData() internal view returns (uint24) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );
        return uint24(randomNumber);
    }

    function reRollDuplicate(uint256 tokenIdA, uint256 tokenIdB)
        public
    {
        require(msg.sender == reRollDuplicateRole);

        uint256 largerTokenId = tokenIdA > tokenIdB ? tokenIdA : tokenIdB;

        _initializeOwnershipAt(largerTokenId);
        if (_exists(largerTokenId + 1)) {
            _initializeOwnershipAt(largerTokenId + 1);
        }

        _setExtraDataAt(largerTokenId, entropyForExtraData());
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        return from == address(0) ? entropyForExtraData() : previousExtraData;
    }

    function tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(_tokenId));
        // This will generate a NUM_LAYERS * 3 character string.
        bytes memory hashBytes = DynamicBuffer.allocate(NUM_LAYERS * 4);

        uint256[] memory hash = new uint256[](NUM_LAYERS);

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 traitIndex = hash[i];
            if(i % 2 > 0 && _revealLayer[_tokenId][i] == false){
                hash[i] = TIERS[i].length - 1;
            // } else if (hideLayer[_tokenId][i] == true) {
            //     hash[i] = TIERS[i].length - 1;
            } else {
                // uint256 tokenExtraData = getTokenSeed(_tokenId);
                uint256 tokenExtraData = uint24(_ownershipOf(_tokenId).extraData);
                uint256 _randinput = uint256(
                    keccak256(
                        abi.encodePacked(
                            tokenExtraData,
                            _tokenId,
                            _tokenId + i
                        )
                    )
                ) % maxSupply;

                traitIndex = rarityGen(_randinput, i);
                hash[i] = traitIndex;

                if (hideLayer[_tokenId][i] == true){
                    if (i == 10 && hash[i] == 10){ //astonished -> blank
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][2] == false){hash[2] = 15;}

                    } else if (i == 14 && hash[i] == 0) {
                        //ghost
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][8] == false){hash[8] = 5;}
                        
                    } else if (i == 14 && hash[i] == 2) {
                        //robot
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 1;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 0;}
                        if(hideLayer[_tokenId][4] == false){hash[4] = 1;}
                        
                    } else if (i == 14 && hash[i] == 3) {
                        //alien
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][8] == false){hash[8] = 6;}
                        
                    } else if (i == 14 && hash[i] == 4) {
                        //skull
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 8;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 9;}

                    } else if (i == 14 && hash[i] == 5) {
                        //vampire
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 6;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 7;}

                    } else if (i == 14 && hash[i] == 6) {
                        //monster
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 7;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 8;}
                        if (hash[6] == 8 && hideLayer[_tokenId][6] == false) {hash[6] = 19;}
                    } else if (i == 14 && hash[i] == 7) {
                        //clown
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 2;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 4;}

                    } else if (i == 14 && hash[i] == 9) {
                        //pepe
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 5;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 1;}

                    } else if (i == 14 && hash[i] == 10) {
                        //doge
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 4;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 2;}

                    } else if (i == 14 && hash[i] == 11) {
                        //cat
                        hash[i] = TIERS[i].length - 1;
                        if(hideLayer[_tokenId][10] == false){hash[10] = 3;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 3;}

                    } else {
                        hash[i] = TIERS[i].length - 1;
                    }
                    
                } else {

                    if (hash[10] == 10){ //astonished -> blank
                        if(hideLayer[_tokenId][2] == false){hash[2] = 15;}
                    }

                    if (hash[14] == 0) {
                        //ghost
                        if(hideLayer[_tokenId][8] == false){hash[8] = 5;}
                    } else if (hash[14] == 2) {
                        //robot
                        if(hideLayer[_tokenId][10] == false){hash[10] = 1;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 0;}
                        if(hideLayer[_tokenId][4] == false){hash[4] = 1;}

                    } else if (hash[14] == 3) {
                        //alien
                        if(hideLayer[_tokenId][8] == false){hash[8] = 6;}

                    } else if (hash[14] == 4) {
                        //skull
                        if(hideLayer[_tokenId][10] == false){hash[10] = 8;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 9;}

                    } else if (hash[14] == 5) {
                        //vampire
                        if(hideLayer[_tokenId][10] == false){hash[10] = 6;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 7;}

                    } else if (hash[14] == 6) {
                        //monster
                        if(hideLayer[_tokenId][10] == false){hash[10] = 7;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 8;}
                        if (hash[6] == 8 && hideLayer[_tokenId][6] == false) {hash[6] = 19;}

                    } else if (hash[14] == 7) {
                        //clown
                        if(hideLayer[_tokenId][10] == false){hash[10] = 2;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 4;}

                    } else if (hash[14] == 9) {
                        //pepe
                        if(hideLayer[_tokenId][10] == false){hash[10] = 5;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 1;}

                    } else if (hash[14] == 10) {
                        //doge
                        if(hideLayer[_tokenId][10] == false){hash[10] = 4;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 2;}

                    } else if (hash[14] == 11) {
                        //cat
                        if(hideLayer[_tokenId][10] == false){hash[10] = 3;}
                        if(hideLayer[_tokenId][8] == false){hash[8] = 3;}

                    }

                }
            }
        }

        for (uint256 i = 0; i < hash.length; i++) {
            if (hash[i] < 10) {
                hashBytes.appendSafe("00");
            } else if (hash[i] < 100) {
                hashBytes.appendSafe("0");
            }
            if (hash[i] > 999) {
                hashBytes.appendSafe("999");
            } else {
                hashBytes.appendSafe(bytes(_toString(hash[i])));
            }
        }

        return string(hashBytes);
    }

    function publicMint(uint256 _count) external payable nonReentrant whenMintActive returns (uint256) {
        uint256 totalMinted = _totalMinted();
        require(mints[msg.sender] + _count <= 100);
        require(_count > 0);
        require(_count <= MAX_BATCH_MINT);
        require(totalMinted + _count <= maxSupply);
        require(msg.sender == tx.origin);

        uint256 disc;
        if (rebates[msg.sender] > 0) {
            if (rebates[msg.sender] <= _count) {
                disc = rebateAmt * rebates[msg.sender];
                require(msg.value >= (_count * mintPrice) - disc);
                rebates[msg.sender] = 0;
            } else {
                disc = rebateAmt * _count;
                require(msg.value >= (_count * mintPrice) - disc);
                rebates[msg.sender] -= _count;
            }
        } else {
            require(msg.value >= _count * mintPrice);
        }

        mints[msg.sender] += _count;

        uint256 batchCount = _count / MAX_BATCH_MINT;
        uint256 remainder = _count % MAX_BATCH_MINT;

        for (uint256 i = 0; i < batchCount; i++) {
            _mint(msg.sender, MAX_BATCH_MINT);
        }

        if (remainder > 0) {
            _mint(msg.sender, remainder);
        }

        return totalMinted;
    }

    function ogMint(uint256 _ogTokenId) external nonReentrant whenMintActive returns (uint256) {
        uint256 totalMinted = _totalMinted();
        require(_ogTokenId <= 1000);
        require(ogMints[_ogTokenId] == false);
        require(msg.sender == ERC721(faContract).ownerOf(_ogTokenId));
        require(totalMinted + 1 <= maxSupply);

        ogMints[_ogTokenId] = true;
        _mint(msg.sender, 1);

        return totalMinted;
    }

    // function ogClaimed(uint256 _ogTokenId) public view returns (bool){
    //     return ogMints[_ogTokenId];
    // }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        require(
            msg.sender == faContract ||
                ERC721(faContract).ownerOf(
                    tokenId
                ) ==
                from
        );

        rebates[from]++;
        return this.onERC721Received.selector;
    }

    function getRebates(address _address) public view returns (uint256) {
        return rebates[_address];
    }

    function hashToSVG(string memory _hash, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        uint256 thisTraitIndex;
        string memory _bgColor = "1C1531";

        if (bytes(bgColor[_tokenId]).length > 0) {
            _bgColor = bgColor[_tokenId];
        }

        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe(
            '<svg width="1600" height="1600" viewBox="0 0 1600 1600" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-color: #'
        );
        svgBytes.appendSafe(
            abi.encodePacked(_bgColor, ";background-image:url(")
        );
        for (uint256 i = 0; i < NUM_LAYERS - 1; i++) {
            thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            svgBytes.appendSafe(
                abi.encodePacked(
                    "data:",
                    _traitDetails[i][thisTraitIndex].mimetype,
                    ";base64,",
                    Base64.encode(
                        SSTORE2.read(_traitDataPointers[i][thisTraitIndex])
                    ),
                    "),url("
                )
            );
        }

        thisTraitIndex = HelperLib.parseInt(
            HelperLib._substring(_hash, (NUM_LAYERS * 3) - 3, NUM_LAYERS * 3)
        );

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                _traitDetails[NUM_LAYERS - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(
                    SSTORE2.read(
                        _traitDataPointers[NUM_LAYERS - 1][thisTraitIndex]
                    )
                ),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svgBytes)
                )
            );
    }

    function hashToMetadata(string memory _hash, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            // if (LibString.runeCount(_traitDetails[i][thisTraitIndex].name) > 1 ) {
            if (bytes(_traitDetails[i][thisTraitIndex].name).length > 2 ) {
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"',
                        LAYER_NAMES[i],
                        '","value":"',
                        _traitDetails[i][thisTraitIndex].name,
                        '"}'
                    )
                );

                if (i == NUM_LAYERS - 1) {
                    metadataBytes.appendSafe("]");
                } else if (i == 13 && hideLayer[_tokenId][14]){
                    metadataBytes.appendSafe("]");
                } else if (i == 12 && (hideLayer[_tokenId][13] && hideLayer[_tokenId][14])){
                    metadataBytes.appendSafe("]");
                } else if (i == 11 && (hideLayer[_tokenId][12] && hideLayer[_tokenId][13] && hideLayer[_tokenId][14])){
                    metadataBytes.appendSafe("]");
                } else if (i == 10 && (hideLayer[_tokenId][11] && hideLayer[_tokenId][12] && hideLayer[_tokenId][13] && hideLayer[_tokenId][14])){
                    metadataBytes.appendSafe("]");
                } else {
                    metadataBytes.appendSafe(",");
                }
            } 
        }

        return string(metadataBytes);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));
        require(_traitDataPointers[0].length > 0);

        string memory tokenHash = tokenIdToHash(_tokenId);

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);
        if (bytes(idValues[_tokenId].AlphaProfile.userName).length > 0) {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    unicode'{"name":"',
                    idValues[_tokenId].AlphaProfile.userName
                )
            );
        } else {
            jsonBytes.appendSafe(unicode'{"name":"OnChainAlpha');
        }

        jsonBytes.appendSafe(
            abi.encodePacked(
                "#",
                _toString(_tokenId),
                '","description":"',
                contractData.description,
                '",'
            )
        );

        if (bytes(baseURI).length > 0 && _renderTokenOffChain[_tokenId]) {
            jsonBytes.appendSafe(
                abi.encodePacked('"image":"', baseURI, _toString(_tokenId))
            );
        } else {
            string memory svgCode = "";
            if (_phlipImage[_tokenId]) {
                string memory svgString = hashToSVG(tokenHash, _tokenId);
                svgCode = string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '<svg width="100%" height="100%" viewBox="0 0 1200 1200" style="display: block; transform: scale(-1,1)" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                svgString,
                                '"></image></svg>'
                            )
                        )
                    )
                );
                jsonBytes.appendSafe(
                    abi.encodePacked('"svg_image_data":"', svgString, '",')
                );
            } else {
                string memory svgString = hashToSVG(tokenHash, _tokenId);
                svgCode = string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                svgString,
                                '"></image></svg>'
                            )
                        )
                    )
                );
                jsonBytes.appendSafe(
                    abi.encodePacked('"svg_image_data":"', svgString, '",')
                );
            }

            jsonBytes.appendSafe(
                abi.encodePacked('"image_data":"', svgCode, '",')
            );
        }

        jsonBytes.appendSafe(
            abi.encodePacked('"attributes":', hashToMetadata(tokenHash, _tokenId), "}")
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(jsonBytes)
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            contractData.name,
                            '","description":"',
                            contractData.description,
                            '","image":"',
                            contractData.image,
                            '","banner":"',
                            contractData.banner,
                            '","external_link":"',
                            contractData.website,
                            '","seller_fee_basis_points":',
                            _toString(contractData.royalties),
                            ',"fee_recipient":"',
                            contractData.royaltiesRecipient,
                            '"}'
                        )
                    )
                )
            );
    }

    function addLayer(uint256 _layerIndex, TraitDTO[] memory traits)
        public
        onlyOwner
    {
        require(TIERS[_layerIndex].length == traits.length);
        address[] memory dataPointers = new address[](traits.length);
        for (uint256 i = 0; i < traits.length; i++) {
            dataPointers[i] = SSTORE2.write(traits[i].data);
            _traitDetails[_layerIndex][i] = Trait(
                traits[i].name,
                traits[i].mimetype
            );
        }
        _traitDataPointers[_layerIndex] = dataPointers;
        return;
    }

    function setRenderOfTokenId(uint256 _tokenId, bool _renderOffChain)
        external
    {
        require(msg.sender == ownerOf(_tokenId));
        _renderTokenOffChain[_tokenId] = _renderOffChain;
    }

    function isMintActive() public view returns (bool) {
        return _totalMinted() < maxSupply && isPublicMintActive;
    }

    function togglePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    //metadata URI
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setContractData(ContractData memory _contractData)
        external
        onlyOwner
    {
        contractData = _contractData;
    }

    //address info
    address private helper = 0x5Cfffb079f1323FE4520786d32402d492e2dbfBA;

    //withdraw to helper address
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        Address.sendValue(payable(helper), balance);
    }

    function setBgColor(string memory _bgColor, uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender);
        bgColor[_tokenId] = _bgColor;

        emit bgChanged(_tokenId, _bgColor);
    }

    function setProfile(
        uint256 _tokenId,
        string memory _username,
        string memory _social,
        string memory _website
    ) external {
        require(ownerOf(_tokenId) == msg.sender);

        _username = normalizer.beautify(_username);

        idValues[_tokenId].AlphaProfile.userName = _username;
        idValues[_tokenId].AlphaProfile.social = _social;
        idValues[_tokenId].AlphaProfile.website = _website;

        // idValues[_tokenId].AlphaProfile.profileName = LibString.concat(
        //     LibString.concat(_username, "#"),
        //     _toString(_tokenId)
        // );
        idValues[_tokenId].AlphaProfile.profileName = string(abi.encodePacked(_username,"#",_tokenId));

        emit AttributesUpdated(
            _tokenId,
            _username,
            _social,
            _website,
            idValues[_tokenId].AlphaProfile.profileName
        );
    }

    function setLabelsValues(uint256 _tokenId, uint _labelNum, string memory _label, string memory _value) external {
        require(msg.sender == ownerOf(_tokenId));

        if(_labelNum > idValues[_tokenId].labelcount){
            _labelNum = idValues[_tokenId].labelcount;
        }

        idValues[_tokenId].labels[_labelNum] = _label;
        idValues[_tokenId].values[_labelNum] = _value;

        if(_labelNum == idValues[_tokenId].labelcount){
            idValues[_tokenId].labelcount++;
        }

        emit LabelsValuesUpdated(_tokenId, _labelNum, _label, _value);
    }

    function toggleLayers(uint256 _tokenId, bool[] memory states) public {
        require(msg.sender == ownerOf(_tokenId));
        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            hideLayer[_tokenId][i] = states[i];
        }

        emit LayersUpdated(_tokenId, states);
    }

    function revealLayers(uint256 _tokenId, bool[] memory _layers) public {
        require(msg.sender == ownerOf(_tokenId));
        for (uint256 i = 0; i < _layers.length; i++) {
            _revealLayer[_tokenId][i] = true;
        }
        emit LayersRevealed(_tokenId, _layers);
    }

    function togglePhlipPFP(uint256 _tokenId, bool _flipped) public {
        require(msg.sender == ownerOf(_tokenId));
        _phlipImage[_tokenId] = _flipped;

        emit ImagePhlipped(_tokenId, _flipped);
    }

    function toggleLayersPhlip(
        uint256 _tokenId,
        bool[] memory states,
        bool _flipped
    ) external {
        toggleLayers(_tokenId, states);
        togglePhlipPFP(_tokenId, _flipped);
    }
}