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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IPool} from "./interfaces/IPool.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/**
 * @notice The IncomeRouter contract is an escrow contract that
 * borrowers can use to share their income.
 */
contract IncomeRouter is Ownable {
    struct NFRData {
        /// The amount of tokens the NFR
        /// holder can withdraw
        uint256 balance;
        /// The original face value the NFR was minted for
        uint256 faceValue;
        /// The maturity date of the NFR
        uint256 maturityDate;
        /// The address of the income source
        address from;
        // The address of the token the nfr loan is denominated in
        address token;
        /// Total Income
        uint256 totalIncome;
        /// The source used to verify income
        bytes32 verificationSource;
    }

    /// @notice This error is thrown whenever the router
    /// does not have enough funds for an address to withdraw
    error InsufficientBalance();

    /// @notice This error is thrown when a NFR with ID 0 is
    /// shared
    error InvalidNFR();

    /// @notice This event is emitted whenever the income in the router
    /// is shared to nfr holders
    /// @param nfrId The ID of the NFR income is being shared to
    /// @param amount The amount of income that is being shared
    event IncomeShared(uint256 nfrId, uint256 amount);

    /// @notice This event is emitted whenever income is withdrawn
    /// from the router
    /// @param recipient The address receiving the funds
    /// @param amount The amount that was withdrawed
    event IncomeClaimed(address recipient, uint256 amount);

    /// @notice Mapping between NFR ID to the shared NFR
    mapping(uint256 => NFRData) private s_nfrs;

    /// @notice Sorted list of NFRs to be paid.  The map
    /// tracks which NFR should be paid next for a token
    mapping(address => mapping(uint256 => uint256)) private s_waterfalls;

    /// @notice The ID of the first NFR to be paid
    uint256 private s_nfrToBePaid;

    constructor() Ownable() {}

    /**
     * @notice Shares the tokens in the router to an NFR holder
     * @param nfrId The ID of the NFR income is being shared to
     * @param from The income source address
     * @param maturityDate The maturity date of the loan
     * @param amount The amount of tokens being shared
     * @param verificationSource The source used to verify income
     * @param totalIncome The total source's income
     * @dev This function can only be executed by the pool
     */
    function share(
        uint256 nfrId,
        address from,
        address token,
        uint256 maturityDate,
        uint256 amount,
        bytes32 verificationSource,
        uint256 totalIncome
    ) external onlyOwner {
        if (nfrId == 0 || maturityDate <= block.timestamp) revert InvalidNFR();

        NFRData memory nfrData = NFRData({
            balance: amount,
            faceValue: amount,
            from: from,
            maturityDate: maturityDate,
            verificationSource: verificationSource,
            totalIncome: totalIncome,
            token: token
        });
        s_nfrs[nfrId] = nfrData;

        if (s_nfrToBePaid == 0) {
            s_nfrToBePaid = nfrId;
        } else {
            uint256 currNFRId = s_nfrToBePaid;

            // If new NFR has a maturity date earlier than the NFR with the earliest maturity date
            // then put the newly minted NFR at the front
            if (maturityDate < s_nfrs[currNFRId].maturityDate) {
                s_nfrToBePaid = nfrId;
            }

            // We acknowledge that there is a risk that the owner will accidentally DDOS
            // the contract by minting too many open NFRs.  We think that the
            // risk for this is low as users will not mint too many open NFRs at any time.
            while (
                s_waterfalls[token][currNFRId] > 0 &&
                s_nfrs[s_waterfalls[token][currNFRId]].maturityDate <=
                maturityDate
            ) {
                currNFRId = s_waterfalls[token][currNFRId];
            }

            // If at the end of the waterfall
            if (s_waterfalls[token][currNFRId] == 0) {
                s_waterfalls[token][currNFRId] = nfrId;
            } else {
                // Reorder waterfall as the new NFR being minted needs to be
                // inserted in the middle.
                s_waterfalls[token][nfrId] = s_waterfalls[token][currNFRId];
                s_waterfalls[token][currNFRId] = nfrId;
            }
        }

        emit IncomeShared(nfrId, amount);
    }

    /**
     * @notice Withdraws tokens from the router using to an NFR owner
     * NFR's balance.
     */
    function withdrawFromLatestNFR(address token) external {
        uint256 latestNFRId = s_nfrToBePaid;

        NFRData storage nfrData = s_nfrs[latestNFRId];
        uint256 withdrawableAmount = getNFRWithdrawableAmount(
            latestNFRId,
            token
        );

        // Update balances
        nfrData.balance -= withdrawableAmount;

        // Allow next nfr to be withdrawn
        if (nfrData.balance == 0) {
            s_nfrToBePaid = s_waterfalls[token][latestNFRId];
        }

        // Transfer withdrawed NFR balance
        address poolAddr = owner(); // Income Router is owned by the pool
        address nfrOwner = IPool(poolAddr).ownerOf(latestNFRId);
        IERC20(token).transfer(nfrOwner, withdrawableAmount);
        emit IncomeClaimed(nfrOwner, withdrawableAmount);
    }

    /**
     * @notice Withdraws tokens from the router using to a recipient
     */
    function withdrawIncome(
        address recipient,
        address token,
        address feeRecipient,
        uint256 feeDenominator
    ) external onlyOwner {
        uint256 ownerWithdrawableAmount = getOwnerWithdrawableAmount(token);
        uint256 feeRepaymentAmount = ownerWithdrawableAmount / feeDenominator;
        IERC20(token).transfer(feeRecipient, feeRepaymentAmount);
        IERC20(token).transfer(
            recipient,
            ownerWithdrawableAmount - feeRepaymentAmount
        );
        emit IncomeClaimed(recipient, ownerWithdrawableAmount);
    }

    function getNFR(uint256 nfrId) external view returns (NFRData memory) {
        NFRData memory nfrData = s_nfrs[nfrId];
        nfrData.balance =
            nfrData.faceValue -
            getNFRWithdrawableAmount(nfrId, nfrData.token);
        return nfrData;
    }

    /**
     * @notice Returns the amount the income router owner can withdraw
     * from the contract
     * @return uint256 The amount the owner can withdraw from the contract
     */
    function getOwnerWithdrawableAmount(
        address token
    ) public view returns (uint256) {
        uint256 currNFRId = s_nfrToBePaid;
        uint256 owedBalance = getNFRWithdrawableAmount(currNFRId, token);
        while (
            s_waterfalls[token][currNFRId] > 0 &&
            s_nfrs[s_waterfalls[token][currNFRId]].maturityDate <=
            block.timestamp
        ) {
            currNFRId = s_waterfalls[token][currNFRId];
            owedBalance += s_nfrs[currNFRId].balance;
        }
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        return tokenBalance < owedBalance ? 0 : tokenBalance - owedBalance;
    }

    /**
     * @notice Returns the amount an NFR can withdraw from the router contract
     * @param nfrId The ID of the NFR being queried
     * @return uint256 The amount the NFR can withdraw
     */
    function getNFRWithdrawableAmount(
        uint256 nfrId,
        address token
    ) public view returns (uint256) {
        if (nfrId != s_nfrToBePaid) return 0;
        NFRData storage nfrData = s_nfrs[nfrId];
        if (nfrData.maturityDate > block.timestamp) return 0;

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        return nfrData.balance > tokenBalance ? tokenBalance : nfrData.balance;
    }

    function getNFRToBePaid() external view returns (uint256) {
        return s_nfrToBePaid;
    }

    function getNFRPriority(
        address token,
        uint256 nfrId
    ) external view returns (uint256) {
        uint256 currId = s_nfrToBePaid;
        uint256 priority;
        while (nfrId != currId) {
            currId = s_waterfalls[token][currId];
            priority++;
        }
        return priority;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IncomeRouter} from "./IncomeRouter.sol";
import {Base64} from "openzeppelin-contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

interface IERC20Symbol {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

library NFRLib {
    function tokenURI(
        IncomeRouter.NFRData memory nfr,
        string memory name,
        address router,
        address token
    ) internal view returns (string memory) {
        string memory nfrStatus = getNFRStatus(nfr);
        bytes memory meta;
        {
            meta = bytes(
                abi.encodePacked(
                    '"name":"',
                    name,
                    '",',
                    '"image":"data:image/svg+xml;base64,',
                    _getImage(nfr, router, token, nfrStatus),
                    '",',
                    '"description":"NFR Loan", "attributes": '
                )
            );
        }

        bytes memory attributes;
        {
            attributes = bytes(
                abi.encodePacked(
                    '[{"trait_type": "Maturity Date","display_type": "date","value":',
                    Strings.toString(nfr.maturityDate),
                    '},{"trait_type": "Token","value":"',
                    Strings.toHexString(token),
                    '"},{"trait_type": "Income Source","value":"',
                    Strings.toHexString(nfr.from),
                    '"},{"trait_type": "Income Verification","value":"',
                    bytes32ToString(nfr.verificationSource),
                    '"},',
                    '{"trait_type": "Status",',
                    '"value":"',
                    bytes(nfrStatus),
                    '"}'
                    "]"
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes.concat(bytes("{"), meta, attributes, bytes("}"))
                    )
                )
            );
    }

    function bytes32ToString(
        bytes32 _bytes32
    ) private pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function getNFRStatus(
        IncomeRouter.NFRData memory nfrData
    ) private view returns (string memory) {
        if (block.timestamp > nfrData.maturityDate) {
            if (nfrData.balance == 0) {
                return "MATURED";
            }
            return "DEFAULTED";
        }
        return "ACTIVE";
    }

    function _getImage(
        IncomeRouter.NFRData memory nfr,
        address router,
        address token,
        string memory nfrStatus
    ) private view returns (string memory) {
        string memory start = '<svg width="3000" height="3000" viewBox="0 0 3000 3000" xmlns="http://www.w3.org/2000/svg" xmlns:xlink= "http://www.w3.org/1999/xlink">'
        "<defs>"
        "<style>"
        ".cls-1, .cls-11, .cls-12, .cls-3, .cls-4, .cls-6, .cls-7 {"
        "fill: #202020;"
        "}"
        ".cls-1, .cls-10, .cls-13, .cls-2, .cls-5, .cls-9 {"
        "fill-rule: evenodd;"
        "}"
        ".cls-13, .cls-14, .cls-2 {"
        "fill: #8ff870;"
        "}"
        ".cls-3 {"
        "font-size: 89.793px;"
        "}"
        ".cls-11, .cls-12, .cls-14, .cls-3, .cls-4, .cls-6, .cls-7, .cls-8 {"
        "font-family: Orbitron;"
        "font-weight: 800;"
        "}"
        ".cls-4 {"
        "font-size: 101px;"
        "}"
        ".cls-12, .cls-4, .cls-6 {"
        "font-variant: small-caps;"
        "}"
        ".cls-5, .cls-9 {"
        "fill: none;"
        "}"
        ".cls-5 {"
        "stroke: #fff;"
        "stroke-width: 6px;"
        "}"
        ".cls-6 {"
        "font-size: 127.714px;"
        "}"
        ".cls-12, .cls-14, .cls-7, .cls-8 {"
        "font-size: 100.029px;"
        "}"
        ".cls-10, .cls-8 {"
        "fill: #fff;"
        "}"
        ".cls-13, .cls-9 {"
        "stroke: #202020;"
        "stroke-width: 3px;"
        "}"
        ".cls-11 {"
        "font-size: 77.78px;"
        "}"
        "</style>"
        "</defs>"
        '<g id="Artboard_1" data-name="Artboard 1">'
        '<path class="cls-1" d="M934.505,525.123H2043.1V2496.9H934.505V525.123Z"/>'
        '<path class="cls-2" d="M874,416v922l633,633v635h597V1052L1468,416H874Z"/>';

        (
            uint256 tokenDecimals,
            string memory tokenSymbol
        ) = getTokenInformation(token);

        bytes memory topDisplays;

        {
            bytes memory balanceDisplay;
            {
                bytes memory balance = bytes(
                    abi.encodePacked(
                        Strings.toString(nfr.balance / 10 ** tokenDecimals)
                    )
                );
                balanceDisplay = bytes.concat(
                    bytes(
                        '<path class="cls-5" d="M964.78,703.931h1050.2V1803.56H964.78V703.931Z"/>'
                    ),
                    bytes(
                        '<text class="cls-6" transform="matrix(0.326, 0, 0, 0.326, 1048.842, 1088.997)">Balance</text>'
                    ),
                    bytes(
                        '<text class="cls-7" transform="matrix(0.899, 0, 0, 0.899, 1050.708, 1046.901)">'
                    ),
                    balance,
                    bytes("</text>")
                );
            }

            bytes memory faceValueDisplay;
            {
                bytes memory faceValue = bytes(
                    abi.encodePacked(
                        Strings.toString(nfr.faceValue / 10 ** tokenDecimals)
                    )
                );
                faceValueDisplay = bytes.concat(
                    bytes(
                        '<text class="cls-6" transform="matrix(0.326, 0, 0, 0.326, 1671.33, 1088.997)">FaceValue</text>'
                    ),
                    bytes(
                        '<text class="cls-7" transform="matrix(0.899, 0, 0, 0.899, 1687.191, 1042.404)">'
                    ),
                    faceValue,
                    bytes("</text>")
                );
            }

            bytes memory tokenDisplay = bytes.concat(
                bytes(
                    '<text class="cls-8" transform="matrix(0.505, 0, 0, 0.506, 1843.77, 592.893)">'
                ),
                bytes(tokenSymbol),
                bytes(
                    '</text><path class="cls-9" d="M1050.97,1285.25h322.35v125.9H1050.97v-125.9Z"/>'
                )
            );

            bytes memory escrowDisplay = bytes.concat(
                bytes(
                    '<text class="cls-11" transform="matrix(0.52, 0, 0, 0.52, 1095.489, 1363.299)">'
                ),
                bytes(getSubstring(Strings.toHexString(nfr.from), 10)),
                bytes("...</text>")
            );

            topDisplays = bytes.concat(
                balanceDisplay,
                faceValueDisplay,
                tokenDisplay,
                escrowDisplay
            );
        }

        bytes memory dtiDisplay;
        {
            bytes memory dti = bytes(
                abi.encodePacked(
                    Strings.toString((100 * nfr.faceValue) / nfr.totalIncome)
                )
            );
            dtiDisplay = bytes.concat(
                bytes(
                    '<text class="cls-14" transform="matrix(0.304, 0, 0, 0.305, 1460.76, 1359.768)">'
                ),
                dti,
                bytes("%</text>")
            );
        }

        bytes memory decor;

        {
            decor = bytes.concat(
                bytes(
                    '<text class="cls-7" transform="matrix(0.304, 0, 0, 0.305, 1438.272, 1411.491)"></text>'
                    '<path class="cls-9" d="M1624.34,1285.25h322.35v125.9H1624.34v-125.9Z"/>'
                    '<text class="cls-11" transform="matrix(0.52, 0, 0, 0.52, 1686.945, 1363.299)">'
                ),
                bytes(getSubstring(Strings.toHexString(router), 10)),
                bytes(
                    "...</text>"
                    '<path class="cls-10" d="M1628.19,1697.9v211.4H1050.22V1697.9h577.97Z"/>'
                    '<text class="cls-12" transform="matrix(0.899, 0, 0, 0.899, 1162.956, 1836.255)">'
                ),
                bytes(nfrStatus),
                bytes(
                    "</text>"
                    '<image x="1374" y="1346" width="250" height="4"/>'
                    '<path class="cls-13" d="M1607.94,1347.71l-27,15.61v-31.21Z"/>'
                    '<path class="cls-13" d="M1425.78,1347.71l-27,15.61v-31.21Z"/>'
                    '<path class="cls-1" d="M1440.41,1317.26h121.43v61.88H1440.41v-61.88Z"/>'
                )
            );
        }

        string memory end = '<path class="cls-1" d="M1087.76,1218.25h35.67l2.51-48.76h-35.67Zm41.86,0h35.67l2.51-48.76h-35.67Zm41.86,0h35.67l2.51-48.76h-35.67Zm41.86,0h35.67l2.51-48.76h-35.67Zm41.86,0h35.67l2.51-48.76h-35.67Zm41.86,0h35.67l2.51-48.76h-35.67Zm41.87,0h35.66l2.51-48.76h-35.67Zm41.86,0h35.66l2.51-48.76H1383.3Zm41.86,0h35.66l2.51-48.76h-35.66Zm41.86,0h35.66l2.51-48.76h-35.66Zm41.86,0h35.66l2.51-48.76h-35.66Z"/>'
        '<path class="cls-9" d="M1051.5,1130.49h893.99v125.02H1051.5V1130.49Z"/>'
        "</g>"
        "</svg>";

        return
            string(
                abi.encodePacked(
                    Base64.encode(
                        bytes.concat(
                            bytes(start),
                            topDisplays,
                            decor,
                            dtiDisplay,
                            bytes(end)
                        )
                    )
                )
            );
    }

    function getTokenInformation(
        address token
    ) private view returns (uint256, string memory) {
        uint256 decimals = IERC20Symbol(token).decimals();
        string memory symbol = IERC20Symbol(token).symbol();
        return (decimals, symbol);
    }

    function getSubstring(
        string memory s,
        uint256 numChars
    ) private pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory res = new bytes(numChars);
        for (uint256 i; i < numChars; i++) {
            res[i] = b[i];
        }
        return string(res);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IPool} from "./interfaces/IPool.sol";
import {IIncomeVerifier} from "./interfaces/IIncomeVerifier.sol";
import {IncomeRouter} from "./IncomeRouter.sol";
import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {NFRLib} from "./NFRLib.sol";

contract Pool is IPool, ERC721, Ownable2Step {
    using NFRLib for IncomeRouter.NFRData;

    /// @notice This error is thrown whenever a zero address is detected
    error ZeroAddress();

    /// @notice This error is thrown whenever an income verifier is not found
    /// @param source The hash of the verifier source
    error VerifierNotFound(bytes32 source);

    /// @notice This error is thrown whenever an income verifier is not approved
    /// @param source The hash of the verifier source
    error VerifierNotApproved(bytes32 source);

    /// @notice This error is thrown when a router is not found
    error RouterNotFound();

    /// @notice This error is thrown whenever an address without access tries
    /// to execute a transaction
    error AccessForbidden();

    /// @notice This error is thrown whenever an address tries to create
    /// a second router
    /// @param owner The owner of the router
    /// @param routerAddress The address of the router that belongs to the
    /// owner
    error RouterAlreadyCreated(address owner, address routerAddress);

    /// @notice This event is emitted whenever a new income router is created
    /// @param owner The income router's owner
    /// @param routerAddr The address of the income router contract
    event RouterCreated(address owner, address routerAddr);

    /// @notice This event is emitted whenever income is shared to an NFR
    /// @param nfrId The ID of the NFR that can claim income
    /// @param verificationSource The hash of the income verification source
    /// @param routerAddr The address of the income router contract
    /// @param faceValue The face value of the NFR
    event IncomeShared(
        uint256 nfrId,
        bytes32 verificationSource,
        address routerAddr,
        uint256 faceValue
    );

    /// @notice This event is emitted whenever a verifier is set for a source
    /// @param source The hash of the source for income verification
    /// @param verifier The address of the verifier contract
    event VerifierSet(bytes32 source, address verifier);

    /// @notice This event is emitted whenever a verifier's approval is set
    /// @param source The hash of the source for income verification
    /// @param isApproved true if the verifier is approved
    event VerifierApprovalSet(bytes32 source, bool isApproved);

    /// @notice The fee that is cut whenever a repayment is made
    /// stored as a denominator.
    /// @dev 1% is stored as 100 as taking 1% is the same as
    /// dividing by 100.
    uint256 private immutable i_feeDenominator;

    /// @notice The protocol's treasury address
    address private immutable i_feeRecipient;

    /// @notice The number of NFRs in the pool
    uint256 private s_numNFRs;

    /// @notice Mapping between the hashed verifier source
    /// and the verifier address.  A verifier source is
    /// the hash of a source name.  The source name can be named
    /// anything as long as it does not exist in the pool yet.
    mapping(bytes32 => address) private s_verifiers;

    /// @notice Mapping of approved verifiers
    mapping(address => bool) private s_approvedVerifiers;

    /// @notice Maps between an NFR ID to a router address
    mapping(uint256 => address) private s_nfrRouters;

    /// @notice Mapping between an owner address to an income router address
    mapping(address => address) private s_ownedRouters;

    constructor(
        string memory name,
        string memory symbol,
        uint256 feeDenominator,
        address feeRecipient
    ) Ownable2Step() ERC721(name, symbol) {
        if (feeRecipient == address(0)) revert ZeroAddress();
        i_feeDenominator = feeDenominator;
        i_feeRecipient = feeRecipient;
    }

    /// @inheritdoc IPool
    function createRouter() external override returns (address) {
        address existingRouterAddress = s_ownedRouters[msg.sender];
        if (existingRouterAddress != address(0))
            revert RouterAlreadyCreated(msg.sender, existingRouterAddress);
        IncomeRouter router = new IncomeRouter();
        s_ownedRouters[msg.sender] = address(router);
        address routerAddress = address(router);
        emit RouterCreated(msg.sender, routerAddress);
        return routerAddress;
    }

    /// @inheritdoc IPool
    function setVerifier(
        bytes32 source,
        address verifier
    ) external override onlyOwner {
        if (verifier == address(0)) revert ZeroAddress();
        s_approvedVerifiers[verifier] = true;
        s_verifiers[source] = verifier;
        emit VerifierSet(source, verifier);
    }

    /// @inheritdoc IPool
    function setVerifierApproval(
        bytes32 source,
        bool isApproved
    ) external override onlyOwner {
        address verifierAddress = s_verifiers[source];
        if (verifierAddress == address(0)) revert ZeroAddress();
        if (s_approvedVerifiers[verifierAddress] != isApproved) {
            s_approvedVerifiers[verifierAddress] = isApproved;
            emit VerifierApprovalSet(source, isApproved);
        }
    }

    /// @inheritdoc IPool
    function getVerifier(
        bytes32 source
    ) external view override returns (address, bool) {
        address verifierAddress = s_verifiers[source];
        return (verifierAddress, s_approvedVerifiers[verifierAddress]);
    }

    /// @inheritdoc IPool
    function requestToMint(
        bytes32 verificationSource,
        address incomeSource,
        address token,
        uint256 maturityDate,
        uint256 faceValue,
        bytes memory data
    ) external override {
        if (incomeSource == address(0)) revert ZeroAddress();
        address routerAddress = s_ownedRouters[msg.sender];
        if (routerAddress == address(0)) revert RouterNotFound();

        address verifierAddr = s_verifiers[verificationSource];
        if (verifierAddr == address(0))
            revert VerifierNotFound(verificationSource);
        if (!s_approvedVerifiers[verifierAddr])
            revert VerifierNotApproved(verificationSource);

        IIncomeVerifier verifier = IIncomeVerifier(verifierAddr);

        // The verify function will call the mint function if it is able to verify future income
        verifier.verify(
            verificationSource,
            routerAddress,
            incomeSource,
            maturityDate,
            faceValue,
            data,
            msg.sender,
            token
        );
    }

    /// @inheritdoc IPool
    /// @dev This function should be called by the verifier to mint new NFRs.
    function mint(
        bytes32 verificationSource,
        address routerAddr,
        address incomeSource,
        uint256 maturityDate,
        uint256 faceValue,
        uint256 totalIncome,
        address owner,
        address token
    ) external override {
        if (!s_approvedVerifiers[msg.sender]) revert AccessForbidden();

        // Start indexing at ID 1
        s_numNFRs++;
        uint256 nfrId = s_numNFRs;
        _safeMint(owner, nfrId);

        s_nfrRouters[nfrId] = routerAddr;

        IncomeRouter(routerAddr).share(
            nfrId,
            incomeSource,
            token,
            maturityDate,
            faceValue,
            verificationSource,
            totalIncome
        );
        emit IncomeShared(nfrId, verificationSource, routerAddr, faceValue);
    }

    /// @inheritdoc IPool
    function withdrawFromLatestNFR(
        address routerAddr,
        address token
    ) external override {
        if (routerAddr == address(0)) revert ZeroAddress();
        IncomeRouter(routerAddr).withdrawFromLatestNFR(token);
    }

    /// @inheritdoc IPool
    function withdrawFromIncomeRouter(address token) external override {
        if (token == address(0)) revert ZeroAddress();
        address routerAddr = s_ownedRouters[msg.sender];
        if (routerAddr == address(0)) revert RouterNotFound();
        IncomeRouter(routerAddr).withdrawIncome(
            msg.sender,
            token,
            i_feeRecipient,
            i_feeDenominator
        );
    }

    /// @inheritdoc IPool
    function getRouter(address owner) external view override returns (address) {
        return s_ownedRouters[owner];
    }

    /**
     * @notice Returns the pool's parameters
     * @return uint256 The fee charged for repayments as the percentage's denominator
     * @return uint256 The number of minted NFRs
     * @return address The address of fee recipient
     */
    function getParams() external view returns (uint256, uint256, address) {
        return (i_feeDenominator, s_numNFRs, i_feeRecipient);
    }

    /// @inheritdoc ERC721
    function tokenURI(
        uint256 nfrId
    ) public view override returns (string memory) {
        _requireMinted(nfrId);
        address router = s_nfrRouters[nfrId];
        IncomeRouter.NFRData memory nfr = IncomeRouter(router).getNFR(nfrId);
        return nfr.tokenURI(ERC721.name(), router, nfr.token);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IIncomeVerifier {
    /// @notice This error is thrown whenever income verification failed
    error VerificationFailed();

    /**
     * @notice Verifies income source.
     * @param verificationSource The source used to verify future income
     * @param routerAddr The address of the income router contract to
     * claim income from
     * @param incomeSource The source of income
     * @param maturityDate The maturity date of this NFR
     * @param faceValue The face value of the NFR
     * @param data Arbitrary data that is used to verify income
     */
    function verify(
        bytes32 verificationSource,
        address routerAddr,
        address incomeSource,
        uint256 maturityDate,
        uint256 faceValue,
        bytes memory data,
        address minter,
        address token
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IPool is IERC721 {
    /**
     * @notice Creates a new router contract
     * @return address The address of the newly created router
     */
    function createRouter() external returns (address);

    /**
     * @notice Sets a new verifier for a source
     * @param source The hash of the verification source
     * @param verifier The address of the verifier contract
     */
    function setVerifier(bytes32 source, address verifier) external;

    /**
     * @notice Sets a new verifier's approval for a source
     * @param source The hash of the verification source
     * @param isApproved True if the verifier is approved
     */
    function setVerifierApproval(bytes32 source, bool isApproved) external;

    /**
     * @notice Returns the address of a verifier
     * @param source The hash of the verification source
     * @return address The address of the verifier
     * @return bool True if verifier is approved
     */
    function getVerifier(bytes32 source) external returns (address, bool);

    /**
     * @notice Returns the owner of a router
     * @param owner The owner address being queried for
     * @return address The address of the router belonging to the owner
     */
    function getRouter(address owner) external view returns (address);

    /**
     * @notice Requests to mint a new NFR to share income
     * @param verificationSource The source used to verify future income
     * @param incomeSource The source of income
     * @param maturityDate The maturity date of this NFR
     * @param faceValue The face value of the NFR
     * @param data Arbitrary data that is used to verify income
     */
    function requestToMint(
        bytes32 verificationSource,
        address incomeSource,
        address token,
        uint256 maturityDate,
        uint256 faceValue,
        bytes memory data
    ) external;

    /**
     * @notice Mints a new NFR to share income
     * @param verificationSource The source used to verify future income
     * @param routerAddr The address of the income router contract to
     * claim income from
     * @param incomeSource The source of income
     * @param maturityDate The maturity date of this NFR
     * @param faceValue The face value of the NFR
     * @param totalIncome The borrower's total income
     * @param owner The original owner of the NFT
     */
    function mint(
        bytes32 verificationSource,
        address routerAddr,
        address incomeSource,
        uint256 maturityDate,
        uint256 faceValue,
        uint256 totalIncome,
        address owner,
        address token
    ) external;

    /**
     * @notice Withdraws income using the router's latest NFR
     * @param routerAddr The address of the income router to withdraw from
     * using an NFR
     * @param token The address of the token to withdraw
     */
    function withdrawFromLatestNFR(address routerAddr, address token) external;

    /**
     * @notice Withdraws income from an income router
     * @param token The address of the token to withdraw
     */
    function withdrawFromIncomeRouter(address token) external;
}