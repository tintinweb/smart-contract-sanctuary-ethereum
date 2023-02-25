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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: MIT

/*
ApeStake Smart Contract Disclaimer

The ApeStake smart contract (the “Smart Contract”) was developed at the direction of the ApeCoin DAO community pursuant
to a grant by the Ape Foundation.  The grant instructs the development of the Smart Contract and the developer’s user
interface to enable a non-exclusive, user friendly means of access to the rewards program offered to the APE community
by the Ape Foundation pursuant to the specifications set forth in AIPs 21/22. The Smart Contract is made up of free,
public, open-source or source-available software deployed on the Ethereum Blockchain.

Use Disclaimer.
Your use of the Smart Contract involves various risks, including, but not limited to, losses while digital
assets are being supplied and/or removed from the Smart Contract, losses due to the volatility of token price,
risks in connection with your personal wallet access, system failures, opportunity loss while participating in the
Smart Contract, loss of tokens in connection with non-fungible token transfers, risk of cyber attack and/or security
breach, risk of legal uncertainty and/or changes in legal environment, and additional risks which may be based upon
utilization of any third party other than the Smart Contract developer who provides you with access to the Smart
Contract. Before using the Smart Contract, you should review the relevant documentation to make sure you understand
how the Smart Contract works. Additionally, because you may be able to access the Smart Contract through other web or
mobile interfaces than the Smart Contract developer’s user interface provided pursuant to the Ape Foundation grant,
you are responsible for doing your own diligence on those interfaces to understand the fees and risks they present.

THE SMART CONTRACT IS PROVIDED "AS IS", AT YOUR OWN RISK, AND WITHOUT WARRANTIES OF ANY KIND.
The developer was contracted by APE Foundation to develop the initial code to implement AIP 21/22.
The developer does not own or control the staking rewards program, which is run on the Smart Contracts deployed on
the Ethereum blockchain.  Upgrades and modifications will be managed in a community-driven way by holders of the APE
governance token and may be undertaken and/or implemented with no involvement of the developer.

No liability.
No developer or entity involved in creating the Smart Contract or “platform as a service” will be liable for any
claims or damages whatsoever associated with your use, inability to use, or your interaction with the Smart Contract
or the developer’s user interface provided pursuant to the Ape Foundation grant, including any direct, indirect,
incidental, special, exemplary, punitive or consequential damages, or loss of profits, cryptocurrencies, tokens,
or anything else of value.

Access to Third Parties.
Any party who uses or provides access to the Smart Contract to third parties must (a) not provide such access in
violation of any applicable law or regulation, (b) inform such third parties of any and all risks, and (c) is solely
responsible to such third parties for any and all liability, claims or damages relating to such party’s provision of
access to the Smart Contract.
*/
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {DashboardStake,DashboardPair} from "../structs/Structs.sol";
/**
 * @title ApeCoin Staking Contract
 * @notice Stake ApeCoin across four different pools that release hourly rewards
 * @author HorizenLabs
 */
contract GoerliApeCoinStaking is Ownable {

    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice State for ApeCoin, BAYC, MAYC, and Pair Pools
    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    /// @notice Pool rules valid for a given duration of time.
    /// @dev All TimeRange timestamp values must represent whole hours
    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    /// @dev Convenience struct for front-end applications
    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    /// @dev Per address amount and reward tracking
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }
    mapping (address => Position) public addressPosition;

    /// @dev Struct for depositing and withdrawing from the BAYC and MAYC NFT pools
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }
    /// @dev Struct for depositing from the BAKC (Pair) pool
    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    /// @dev Struct for withdrawing from the BAKC (Pair) pool
    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    /// @dev Struct for claiming from an NFT pool
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }
    /// @dev NFT paired status.  Can be used bi-directionally (BAYC/MAYC -> BAKC) or (BAKC -> BAYC/MAYC)
    struct PairingStatus {
        uint248 tokenId;
        bool isPaired;
    }

    // // @dev UI focused payload
    // struct DashboardStake {
    //     uint256 poolId;
    //     uint256 tokenId;
    //     uint256 deposited;
    //     uint256 unclaimed;
    //     uint256 rewards24hr;
    //     DashboardPair pair;
    // }
    // /// @dev Sub struct for DashboardStake
    // struct DashboardPair {
    //     uint256 mainTokenId;
    //     uint256 mainTypePoolId;
    // }
    /// @dev Placeholder for pair status, used by ApeCoin Pool
    DashboardPair private NULL_PAIR = DashboardPair(0, 0);

    /// @notice Internal ApeCoin amount for distributing staking reward claims
    IERC20 public immutable apeCoin;
    uint256 private constant APE_COIN_PRECISION = 1e18;
    uint256 private constant MIN_DEPOSIT = 1 * APE_COIN_PRECISION;
    uint256 private constant SECONDS_PER_HOUR = 3600;
    uint256 private constant SECONDS_PER_MINUTE = 60;

    uint256 constant APECOIN_POOL_ID = 0;
    uint256 constant BAYC_POOL_ID = 1;
    uint256 constant MAYC_POOL_ID = 2;
    uint256 constant BAKC_POOL_ID = 3;
    Pool[4] public pools;

    /// @dev NFT contract mapping per pool
    mapping(uint256 => ERC721Enumerable) public nftContracts;
    /// @dev poolId => tokenId => nft position
    mapping(uint256 => mapping(uint256 => Position)) public nftPosition;
    /// @dev main type pool ID: 1: BAYC 2: MAYC => main token ID => bakc token ID
    mapping(uint256 => mapping(uint256 => PairingStatus)) public mainToBakc;
    /// @dev bakc Token ID => main type pool ID: 1: BAYC 2: MAYC => main token ID
    mapping(uint256 => mapping(uint256 => PairingStatus)) public bakcToMain;

    /** Custom Events */
    event UpdatePool(
        uint256 indexed poolId,
        uint256 lastRewardedBlock,
        uint256 stakedAmount,
        uint256 accumulatedRewardsPerShare
    );
    event Deposit(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event DepositNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 tokenId
    );
    event DepositPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event WithdrawNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        address recipient,
        uint256 tokenId
    );
    event WithdrawPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );
    event ClaimRewards(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event ClaimRewardsNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 tokenId
    );
    event ClaimRewardsPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );

    error DepositMoreThanOneAPE();
    error InvalidPoolId();
    error StartMustBeGreaterThanEnd();
    error StartNotWholeHour();
    error EndNotWholeHour();
    error StartMustEqualLastEnd();
    error CallerNotOwner();
    error MainTokenNotOwnedOrPaired();
    error BAKCNotOwnedOrPaired();
    error BAKCAlreadyPaired();
    error ExceededCapAmount();
    error NotOwnerOfMain();
    error NotOwnerOfBAKC();
    error  ProvidedTokensNotPaired();
    error ExceededStakedAmount();
    error NeitherTokenInPairOwnedByCaller();
    error SplitPairCantPartiallyWithdraw();
    error UncommitWrongParameters();


    /**
     * @notice Construct a new ApeCoinStaking instance
     * @param _apeCoinContractAddress The ApeCoin ERC20 contract address
     * @param _baycContractAddress The BAYC NFT contract address
     * @param _maycContractAddress The MAYC NFT contract address
     * @param _bakcContractAddress The BAKC NFT contract address
     */
    constructor(
        address _apeCoinContractAddress,
        address _baycContractAddress,
        address _maycContractAddress,
        address _bakcContractAddress,
        uint _startTimestamp,
        uint _endTimestamp
    ) {
        apeCoin = IERC20(_apeCoinContractAddress);
        nftContracts[BAYC_POOL_ID] = ERC721Enumerable(_baycContractAddress);
        nftContracts[MAYC_POOL_ID] = ERC721Enumerable(_maycContractAddress);
        nftContracts[BAKC_POOL_ID] = ERC721Enumerable(_bakcContractAddress);
        //1670864400,1678726800,4807692307692307692307,0
        addTimeRange(0, 1678726800, _startTimestamp, _endTimestamp, 0);
        // addTimeRange(0, 1678726800, block.timestamp  , block.timestamp + (365 * 1 days), 0);
 


        // timeRanges[]
    }

    // Deposit/Commit Methods

    /**
     * @notice Deposit ApeCoin to the ApeCoin Pool
     * @param _amount Amount in ApeCoin
     * @param _recipient Address the deposit it stored to
     * @dev ApeCoin deposit must be >= 1 ApeCoin
     */
    function depositApeCoin(uint256 _amount, address _recipient) public {
        if (_amount < MIN_DEPOSIT) revert DepositMoreThanOneAPE();
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[_recipient];
        _deposit(APECOIN_POOL_ID, position, _amount);

        apeCoin.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount, _recipient);
    }

    /**
     * @notice Deposit ApeCoin to the ApeCoin Pool
     * @param _amount Amount in ApeCoin
     * @dev Deposit on behalf of msg.sender. ApeCoin deposit must be >= 1 ApeCoin
     */
    function depositSelfApeCoin(uint256 _amount) external {
        depositApeCoin(_amount, msg.sender);
    }

    /**
     * @notice Deposit ApeCoin to the BAYC Pool
     * @param _nfts Array of SingleNft structs
     * @dev Commits 1 or more BAYC NFTs, each with an ApeCoin amount to the BAYC pool.\
     * Each BAYC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the BAYC pool cap amount.
     */
    function depositBAYC(SingleNft[] calldata _nfts) external {
        _depositNft(BAYC_POOL_ID, _nfts);
    }

    /**
     * @notice Deposit ApeCoin to the MAYC Pool
     * @param _nfts Array of SingleNft structs
     * @dev Commits 1 or more MAYC NFTs, each with an ApeCoin amount to the MAYC pool.\
     * Each MAYC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the MAYC pool cap amount.
     */
    function depositMAYC(SingleNft[] calldata _nfts) external {
        _depositNft(MAYC_POOL_ID, _nfts);
    }

    /**
     * @notice Deposit ApeCoin to the Pair Pool, where Pair = (BAYC + BAKC) or (MAYC + BAKC)
     * @param _baycPairs Array of PairNftDepositWithAmount structs
     * @param _maycPairs Array of PairNftDepositWithAmount structs
     * @dev Commits 1 or more Pairs, each with an ApeCoin amount to the Pair pool.\
     * Each BAKC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the Pair pool cap amount.\
     * Example 1: BAYC + BAKC + 1 ApeCoin:  [[0, 0, "1000000000000000000"],[]]\
     * Example 2: MAYC + BAKC + 1 ApeCoin:  [[], [0, 0, "1000000000000000000"]]\
     * Example 3: (BAYC + BAKC + 1 ApeCoin) and (MAYC + BAKC + 1 ApeCoin): [[0, 0, "1000000000000000000"], [0, 1, "1000000000000000000"]]
     */
    function depositBAKC(PairNftDepositWithAmount[] calldata _baycPairs, PairNftDepositWithAmount[] calldata _maycPairs) external {
        updatePool(BAKC_POOL_ID);
        _depositPairNft(BAYC_POOL_ID, _baycPairs);
        _depositPairNft(MAYC_POOL_ID, _maycPairs);
    }

    // Claim Rewards Methods

    /**
     * @notice Claim rewards for msg.sender and send to recipient
     * @param _recipient Address to send claim reward to
     */
    function claimApeCoin(address _recipient) public {
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[msg.sender];
        uint256 rewardsToBeClaimed = _claim(APECOIN_POOL_ID, position, _recipient);

        emit ClaimRewards(msg.sender, rewardsToBeClaimed, _recipient);
    }

    /// @notice Claim and send rewards
    function claimSelfApeCoin() external {
        claimApeCoin(msg.sender);
    }

    /**
     * @notice Claim rewards for array of BAYC NFTs and send to recipient
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimBAYC(uint256[] calldata _nfts, address _recipient) external {
        _claimNft(BAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Claim rewards for array of BAYC NFTs
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     */
    function claimSelfBAYC(uint256[] calldata _nfts) external {
        _claimNft(BAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Claim rewards for array of MAYC NFTs and send to recipient
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimMAYC(uint256[] calldata _nfts, address _recipient) external {
        _claimNft(MAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Claim rewards for array of MAYC NFTs
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     */
    function claimSelfMAYC(uint256[] calldata _nfts) external {
        _claimNft(MAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Claim rewards for array of Paired NFTs and send to recipient
     * @param _baycPairs Array of Paired BAYC NFTs owned and committed by the msg.sender
     * @param _maycPairs Array of Paired MAYC NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs, address _recipient) public {
        updatePool(BAKC_POOL_ID);
        _claimPairNft(BAYC_POOL_ID, _baycPairs, _recipient);
        _claimPairNft(MAYC_POOL_ID, _maycPairs, _recipient);
    }

    /**
     * @notice Claim rewards for array of Paired NFTs
     * @param _baycPairs Array of Paired BAYC NFTs owned and committed by the msg.sender
     * @param _maycPairs Array of Paired MAYC NFTs owned and committed by the msg.sender
     */
    function claimSelfBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs) external {
        claimBAKC(_baycPairs, _maycPairs, msg.sender);
    }

    // Uncommit/Withdraw Methods

    /**
     * @notice Withdraw staked ApeCoin from the ApeCoin pool.  Performs an automatic claim as part of the withdraw process.
     * @param _amount Amount of ApeCoin
     * @param _recipient Address to send withdraw amount and claim to
     */
    function withdrawApeCoin(uint256 _amount, address _recipient) public {
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[msg.sender];
        if (_amount == position.stakedAmount) {
            uint256 rewardsToBeClaimed = _claim(APECOIN_POOL_ID, position, _recipient);
            emit ClaimRewards(msg.sender, rewardsToBeClaimed, _recipient);
        }
        _withdraw(APECOIN_POOL_ID, position, _amount);

        apeCoin.transfer(_recipient, _amount);

        emit Withdraw(msg.sender, _amount, _recipient);
    }

    /**
     * @notice Withdraw staked ApeCoin from the ApeCoin pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _amount Amount of ApeCoin
     */
    function withdrawSelfApeCoin(uint256 _amount) external {
        withdrawApeCoin(_amount, msg.sender);
    }

    /**
     * @notice Withdraw staked ApeCoin from the BAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of BAYC NFT's with staked amounts
     * @param _recipient Address to send withdraw amount and claim to
     */
    function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external {
        _withdrawNft(BAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Withdraw staked ApeCoin from the BAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of BAYC NFT's with staked amounts
     */
    function withdrawSelfBAYC(SingleNft[] calldata _nfts) external {
        _withdrawNft(BAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Withdraw staked ApeCoin from the MAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of MAYC NFT's with staked amounts
     * @param _recipient Address to send withdraw amount and claim to
     */
    function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external {
        _withdrawNft(MAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Withdraw staked ApeCoin from the MAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of MAYC NFT's with staked amounts
     */
    function withdrawSelfMAYC(SingleNft[] calldata _nfts) external {
        _withdrawNft(MAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Withdraw staked ApeCoin from the Pair pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _baycPairs Array of Paired BAYC NFT's with staked amounts and isUncommit boolean
     * @param _maycPairs Array of Paired MAYC NFT's with staked amounts and isUncommit boolean
     * @dev if pairs have split ownership and BAKC is attempting a withdraw, the withdraw must be for the total staked amount
     */
    function withdrawBAKC(PairNftWithdrawWithAmount[] calldata _baycPairs, PairNftWithdrawWithAmount[] calldata _maycPairs) external {
        updatePool(BAKC_POOL_ID);
        _withdrawPairNft(BAYC_POOL_ID, _baycPairs);
        _withdrawPairNft(MAYC_POOL_ID, _maycPairs);
    }

    // Time Range Methods

    /**
     * @notice Add single time range with a given rewards per hour for a given pool
     * @dev In practice one Time Range will represent one quarter (defined by `_startTimestamp`and `_endTimeStamp` as whole hours)
     * where the rewards per hour is constant for a given pool.
     * @param _poolId Available pool values 0-3
     * @param _amount Total amount of ApeCoin to be distributed over the range
     * @param _startTimestamp Whole hour timestamp representation
     * @param _endTimeStamp Whole hour timestamp representation
     * @param _capPerPosition Per position cap amount determined by poolId
     */
    function addTimeRange(
        uint256 _poolId,
        uint256 _amount,
        uint256 _startTimestamp,
        uint256 _endTimeStamp,
        uint256 _capPerPosition) public onlyOwner
    {
        if (_poolId > BAKC_POOL_ID) revert InvalidPoolId();
        if (_startTimestamp >= _endTimeStamp) revert StartMustBeGreaterThanEnd();
        if (getMinute(_startTimestamp) > 0 || getSecond(_startTimestamp) > 0) revert StartNotWholeHour();
        if (getMinute(_endTimeStamp) > 0 || getSecond(_endTimeStamp) > 0) revert EndNotWholeHour();

        Pool storage pool = pools[_poolId];
        uint256 length = pool.timeRanges.length;
        if (length > 0) {
            if (_startTimestamp != pool.timeRanges[length - 1].endTimestampHour) revert StartMustEqualLastEnd();
        }

        uint256 hoursInSeconds = _endTimeStamp - _startTimestamp;
        uint256 rewardsPerHour = _amount * SECONDS_PER_HOUR / hoursInSeconds;

        TimeRange memory next = TimeRange(_startTimestamp.toUint48(), _endTimeStamp.toUint48(),
            rewardsPerHour.toUint96(), _capPerPosition.toUint96());
        pool.timeRanges.push(next);
    }

    /**
     * @notice Removes the last Time Range for a given pool.
     * @param _poolId Available pool values 0-3
     */
    function removeLastTimeRange(uint256 _poolId) external onlyOwner {
        pools[_poolId].timeRanges.pop();
    }

    /**
     * @notice Lookup method for a TimeRange struct
     * @return TimeRange A Pool's timeRanges struct by index.
     * @param _poolId Available pool values 0-3
     * @param _index Target index in a Pool's timeRanges array
     */
    function getTimeRangeBy(uint256 _poolId, uint256 _index) public view returns (TimeRange memory) {
        return pools[_poolId].timeRanges[_index];
    }

    // Pool Methods

    /**
     * @notice Lookup available rewards for a pool over a given time range
     * @return uint256 The amount of ApeCoin rewards to be distributed by pool for a given time range
     * @return uint256 The amount of time ranges
     * @param _poolId Available pool values 0-3
     * @param _from Whole hour timestamp representation
     * @param _to Whole hour timestamp representation
     */
    function rewardsBy(uint256 _poolId, uint256 _from, uint256 _to) public view returns (uint256, uint256) {
        Pool memory pool = pools[_poolId];

        uint256 currentIndex = pool.lastRewardsRangeIndex;
        if(_to < pool.timeRanges[0].startTimestampHour) return (0, currentIndex);

        while(_from > pool.timeRanges[currentIndex].endTimestampHour && _to > pool.timeRanges[currentIndex].endTimestampHour) {
            unchecked {
                ++currentIndex;
            }
        }

        uint256 rewards;
        TimeRange memory current;
        uint256 startTimestampHour;
        uint256 endTimestampHour;
        uint256 length = pool.timeRanges.length;
        for(uint256 i = currentIndex; i < length;) {
            current = pool.timeRanges[i];
            startTimestampHour = _from <= current.startTimestampHour ? current.startTimestampHour : _from;
            endTimestampHour = _to <= current.endTimestampHour ? _to : current.endTimestampHour;

            rewards = rewards + (endTimestampHour - startTimestampHour) * current.rewardsPerHour / SECONDS_PER_HOUR;

            if(_to <= endTimestampHour) {
                return (rewards, i);
            }
            unchecked {
                ++i;
            }
        }

        return (rewards, length - 1);
    }

    /**
     * @notice Updates reward variables `lastRewardedTimestampHour`, `accumulatedRewardsPerShare` and `lastRewardsRangeIndex`
     * for a given pool.
     * @param _poolId Available pool values 0-3
     */
    function updatePool(uint256 _poolId) public {
        Pool storage pool = pools[_poolId];

        if (block.timestamp < pool.timeRanges[0].startTimestampHour) return;
        if (block.timestamp <= pool.lastRewardedTimestampHour + SECONDS_PER_HOUR) return;

        uint48 lastTimestampHour = pool.timeRanges[pool.timeRanges.length-1].endTimestampHour;
        uint48 previousTimestampHour = getPreviousTimestampHour().toUint48();

        if (pool.stakedAmount == 0) {
            pool.lastRewardedTimestampHour = previousTimestampHour > lastTimestampHour ? lastTimestampHour : previousTimestampHour;
            return;
        }

        (uint256 rewards, uint256 index) = rewardsBy(_poolId, pool.lastRewardedTimestampHour, previousTimestampHour);
        if (pool.lastRewardsRangeIndex != index) {
            pool.lastRewardsRangeIndex = index.toUint16();
        }
        pool.accumulatedRewardsPerShare = (pool.accumulatedRewardsPerShare + (rewards * APE_COIN_PRECISION) / pool.stakedAmount).toUint96();
        pool.lastRewardedTimestampHour = previousTimestampHour > lastTimestampHour ? lastTimestampHour : previousTimestampHour;

        emit UpdatePool(_poolId, pool.lastRewardedTimestampHour, pool.stakedAmount, pool.accumulatedRewardsPerShare);
    }

    // Read Methods

    function getCurrentTimeRangeIndex(Pool memory pool) private view returns (uint256) {
        uint256 current = pool.lastRewardsRangeIndex;

        if (block.timestamp < pool.timeRanges[current].startTimestampHour) return current;
        for(current = pool.lastRewardsRangeIndex; current < pool.timeRanges.length; ++current) {
            TimeRange memory currentTimeRange = pool.timeRanges[current];
            if (currentTimeRange.startTimestampHour <= block.timestamp && block.timestamp <= currentTimeRange.endTimestampHour) return current;
        }
        revert("distribution ended");
    }

    /**
     * @notice Fetches a PoolUI struct (poolId, stakedAmount, currentTimeRange) for each reward pool
     * @return PoolUI for ApeCoin.
     * @return PoolUI for BAYC.
     * @return PoolUI for MAYC.
     * @return PoolUI for BAKC.
     */
    function getPoolsUI() public view returns (PoolUI memory, PoolUI memory, PoolUI memory, PoolUI memory) {
        Pool memory apeCoinPool = pools[0];
        Pool memory baycPool = pools[1];
        Pool memory maycPool = pools[2];
        Pool memory bakcPool = pools[3];
        uint256 current = getCurrentTimeRangeIndex(apeCoinPool);
        return (PoolUI(0,apeCoinPool.stakedAmount, apeCoinPool.timeRanges[current]),
                PoolUI(1,baycPool.stakedAmount, baycPool.timeRanges[current]),
                PoolUI(2,maycPool.stakedAmount, maycPool.timeRanges[current]),
                PoolUI(3,bakcPool.stakedAmount, bakcPool.timeRanges[current]));
    }

    /**
     * @notice Fetches an address total staked amount, used by voting contract
     * @return amount uint256 staked amount for all pools.
     * @param _address An Ethereum address
     */
    function stakedTotal(address _address) external view returns (uint256) {
        uint256 total = addressPosition[_address].stakedAmount;

        total += _stakedTotal(BAYC_POOL_ID, _address);
        total += _stakedTotal(MAYC_POOL_ID, _address);
        total += _stakedTotalPair(_address);

        return total;
    }

    function _stakedTotal(uint256 _poolId, address _addr) private view returns (uint256) {
        uint256 total = 0;
        uint256 nftCount = nftContracts[_poolId].balanceOf(_addr);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 tokenId = nftContracts[_poolId].tokenOfOwnerByIndex(_addr, i);
            total += nftPosition[_poolId][tokenId].stakedAmount;
        }

        return total;
    }

    function _stakedTotalPair(address _addr) private view returns (uint256) {
        uint256 total = 0;

        uint256 nftCount = nftContracts[BAYC_POOL_ID].balanceOf(_addr);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 baycTokenId = nftContracts[BAYC_POOL_ID].tokenOfOwnerByIndex(_addr, i);
            if (mainToBakc[BAYC_POOL_ID][baycTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[BAYC_POOL_ID][baycTokenId].tokenId;
                total += nftPosition[BAKC_POOL_ID][bakcTokenId].stakedAmount;
            }
        }

        nftCount = nftContracts[MAYC_POOL_ID].balanceOf(_addr);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 maycTokenId = nftContracts[MAYC_POOL_ID].tokenOfOwnerByIndex(_addr, i);
            if (mainToBakc[MAYC_POOL_ID][maycTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[MAYC_POOL_ID][maycTokenId].tokenId;
                total += nftPosition[BAKC_POOL_ID][bakcTokenId].stakedAmount;
            }
        }

        return total;
    }

    /**
     * @notice Fetches a DashboardStake = [poolId, tokenId, deposited, unclaimed, rewards24Hrs, paired] \
     * for each pool, for an Ethereum address
     * @return dashboardStakes An array of DashboardStake structs
     * @param _address An Ethereum address
     */
    function getAllStakes(address _address) public view returns (DashboardStake[] memory) {

        DashboardStake memory apeCoinStake = getApeCoinStake(_address);
        DashboardStake[] memory baycStakes = getBaycStakes(_address);
        DashboardStake[] memory maycStakes = getMaycStakes(_address);
        DashboardStake[] memory bakcStakes = getBakcStakes(_address);
        DashboardStake[] memory splitStakes = getSplitStakes(_address);

        uint256 count = (baycStakes.length + maycStakes.length + bakcStakes.length + splitStakes.length + 1);
        DashboardStake[] memory allStakes = new DashboardStake[](count);

        uint256 offset = 0;
        allStakes[offset] = apeCoinStake;
        ++offset;

        for(uint256 i = 0; i < baycStakes.length; ++i) {
            allStakes[offset] = baycStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < maycStakes.length; ++i) {
            allStakes[offset] = maycStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < bakcStakes.length; ++i) {
            allStakes[offset] = bakcStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < splitStakes.length; ++i) {
            allStakes[offset] = splitStakes[i];
            ++offset;
        }

        return allStakes;
    }

    /**
     * @notice Fetches a DashboardStake for the ApeCoin pool
     * @return dashboardStake A dashboardStake struct
     * @param _address An Ethereum address
     */
    function getApeCoinStake(address _address) public view returns (DashboardStake memory) {
        uint256 tokenId = 0;
        uint256 deposited = addressPosition[_address].stakedAmount;
        uint256 unclaimed = deposited > 0 ? this.pendingRewards(0, _address, tokenId) : 0;
        uint256 rewards24Hrs = deposited > 0 ? _estimate24HourRewards(0, _address, 0) : 0;

        return DashboardStake(APECOIN_POOL_ID, tokenId, deposited, unclaimed, rewards24Hrs, NULL_PAIR);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the BAYC pool
     * @return dashboardStakes An array of DashboardStake structs
     */
    function getBaycStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, BAYC_POOL_ID);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the MAYC pool
     * @return dashboardStakes An array of DashboardStake structs
     */
    function getMaycStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, MAYC_POOL_ID);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the BAKC pool
     * @return dashboardStakes An array of DashboardStake structs
     */
    function getBakcStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, BAKC_POOL_ID);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the Pair Pool when ownership is split \
     * ie (BAYC/MAYC) and BAKC in pair pool have different owners.
     * @return dashboardStakes An array of DashboardStake structs
     * @param _address An Ethereum address
     */
    function getSplitStakes(address _address) public view returns (DashboardStake[] memory) {
        uint256 baycSplits = _getSplitStakeCount(nftContracts[BAYC_POOL_ID].balanceOf(_address), _address, BAYC_POOL_ID);
        uint256 maycSplits = _getSplitStakeCount(nftContracts[MAYC_POOL_ID].balanceOf(_address), _address, MAYC_POOL_ID);
        uint256 totalSplits = baycSplits + maycSplits;

        if(totalSplits == 0) {
            return new DashboardStake[](0);
        }

        DashboardStake[] memory baycSplitStakes = _getSplitStakes(baycSplits, _address, BAYC_POOL_ID);
        DashboardStake[] memory maycSplitStakes = _getSplitStakes(maycSplits, _address, MAYC_POOL_ID);

        DashboardStake[] memory splitStakes = new DashboardStake[](totalSplits);
        uint256 offset = 0;
        for(uint256 i = 0; i < baycSplitStakes.length; ++i) {
            splitStakes[offset] = baycSplitStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < maycSplitStakes.length; ++i) {
            splitStakes[offset] = maycSplitStakes[i];
            ++offset;
        }

        return splitStakes;
    }

    function _getSplitStakes(uint256 splits, address _address, uint256 _mainPoolId) private view returns (DashboardStake[] memory) {

        DashboardStake[] memory dashboardStakes = new DashboardStake[](splits);
        uint256 counter;

        for(uint256 i = 0; i < nftContracts[_mainPoolId].balanceOf(_address); ++i) {
            uint256 mainTokenId = nftContracts[_mainPoolId].tokenOfOwnerByIndex(_address, i);
            if(mainToBakc[_mainPoolId][mainTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[_mainPoolId][mainTokenId].tokenId;
                address currentOwner = nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId);

                /* Split Pair Check*/
                if (currentOwner != _address) {
                    uint256 deposited = nftPosition[BAKC_POOL_ID][bakcTokenId].stakedAmount;
                    uint256 unclaimed = deposited > 0 ? this.pendingRewards(BAKC_POOL_ID, currentOwner, bakcTokenId) : 0;
                    uint256 rewards24Hrs = deposited > 0 ? _estimate24HourRewards(BAKC_POOL_ID, currentOwner, bakcTokenId): 0;

                    DashboardPair memory pair = NULL_PAIR;
                    if(bakcToMain[bakcTokenId][_mainPoolId].isPaired) {
                        pair = DashboardPair(bakcToMain[bakcTokenId][_mainPoolId].tokenId, _mainPoolId);
                    }

                    DashboardStake memory dashboardStake = DashboardStake(BAKC_POOL_ID, bakcTokenId, deposited, unclaimed, rewards24Hrs, pair);
                    dashboardStakes[counter] = dashboardStake;
                    ++counter;
                }
            }
        }

        return dashboardStakes;
    }

    function _getSplitStakeCount(uint256 nftCount, address _address, uint256 _mainPoolId) private view returns (uint256) {
        uint256 splitCount;
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 mainTokenId = nftContracts[_mainPoolId].tokenOfOwnerByIndex(_address, i);
            if(mainToBakc[_mainPoolId][mainTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[_mainPoolId][mainTokenId].tokenId;
                address currentOwner = nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId);
                if (currentOwner != _address) {
                    ++splitCount;
                }
            }
        }

        return splitCount;
    }

    function _getStakes(address _address, uint256 _poolId) private view returns (DashboardStake[] memory) {
        uint256 nftCount = nftContracts[_poolId].balanceOf(_address);
        DashboardStake[] memory dashboardStakes = nftCount > 0 ? new DashboardStake[](nftCount) : new DashboardStake[](0);

        if(nftCount == 0) {
            return dashboardStakes;
        }

        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 tokenId = nftContracts[_poolId].tokenOfOwnerByIndex(_address, i);
            uint256 deposited = nftPosition[_poolId][tokenId].stakedAmount;
            uint256 unclaimed = deposited > 0 ? this.pendingRewards(_poolId, _address, tokenId) : 0;
            uint256 rewards24Hrs = deposited > 0 ? _estimate24HourRewards(_poolId, _address, tokenId): 0;

            DashboardPair memory pair = NULL_PAIR;
            if(_poolId == BAKC_POOL_ID) {
                if(bakcToMain[tokenId][BAYC_POOL_ID].isPaired) {
                    pair = DashboardPair(bakcToMain[tokenId][BAYC_POOL_ID].tokenId, BAYC_POOL_ID);
                } else if(bakcToMain[tokenId][MAYC_POOL_ID].isPaired) {
                    pair = DashboardPair(bakcToMain[tokenId][MAYC_POOL_ID].tokenId, MAYC_POOL_ID);
                }
            }

            DashboardStake memory dashboardStake = DashboardStake(_poolId, tokenId, deposited, unclaimed, rewards24Hrs, pair);
            dashboardStakes[i] = dashboardStake;
        }

        return dashboardStakes;
    }

    function _estimate24HourRewards(uint256 _poolId, address _address, uint256 _tokenId) private view returns (uint256) {
        Pool memory pool = pools[_poolId];
        Position memory position = _poolId == 0 ? addressPosition[_address]: nftPosition[_poolId][_tokenId];

        TimeRange memory rewards = getTimeRangeBy(_poolId, pool.lastRewardsRangeIndex);
        return (position.stakedAmount * uint256(rewards.rewardsPerHour) * 24) / uint256(pool.stakedAmount);
    }

    /**
     * @notice Fetches the current amount of claimable ApeCoin rewards for a given position from a given pool.
     * @return uint256 value of pending rewards
     * @param _poolId Available pool values 0-3
     * @param _address Address to lookup Position for
     * @param _tokenId An NFT id
     */
    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256) {
        Pool memory pool = pools[_poolId];
        Position memory position = _poolId == 0 ? addressPosition[_address]: nftPosition[_poolId][_tokenId];

        (uint256 rewardsSinceLastCalculated,) = rewardsBy(_poolId, pool.lastRewardedTimestampHour, getPreviousTimestampHour());
        uint256 accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare;

        if (block.timestamp > pool.lastRewardedTimestampHour + SECONDS_PER_HOUR && pool.stakedAmount != 0) {
            accumulatedRewardsPerShare = accumulatedRewardsPerShare + rewardsSinceLastCalculated * APE_COIN_PRECISION / pool.stakedAmount;
        }
        return ((position.stakedAmount * accumulatedRewardsPerShare).toInt256() - position.rewardsDebt).toUint256() / APE_COIN_PRECISION;
    }

    // Convenience methods for timestamp calculation

    /// @notice the minutes (0 to 59) of a timestamp
    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    /// @notice the seconds (0 to 59) of a timestamp
    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    /// @notice the previous whole hour of a timestamp
    function getPreviousTimestampHour() internal view returns (uint256) {
        return block.timestamp - (getMinute(block.timestamp) * 60 + getSecond(block.timestamp));
    }

    // Private Methods - shared logic
    function _deposit(uint256 _poolId, Position storage _position, uint256 _amount) private {
        Pool storage pool = pools[_poolId];

        _position.stakedAmount += _amount;
        pool.stakedAmount += _amount.toUint96();
        _position.rewardsDebt += (_amount * pool.accumulatedRewardsPerShare).toInt256();
    }

    function _depositNft(uint256 _poolId, SingleNft[] calldata _nfts) private {
        updatePool(_poolId);
        uint256 tokenId;
        uint256 amount;
        Position storage position;
        uint256 length = _nfts.length;
        uint256 totalDeposit;
        for(uint256 i; i < length;) {
            tokenId = _nfts[i].tokenId;
            position = nftPosition[_poolId][tokenId];
            if (position.stakedAmount == 0) {
                if (nftContracts[_poolId].ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
            }
            amount = _nfts[i].amount;
            _depositNftGuard(_poolId, position, amount);
            totalDeposit += amount;
            emit DepositNft(msg.sender, _poolId, amount, tokenId);
            unchecked {
                ++i;
            }
        }
        if (totalDeposit > 0) apeCoin.transferFrom(msg.sender, address(this), totalDeposit);
    }

    function _depositPairNft(uint256 mainTypePoolId, PairNftDepositWithAmount[] calldata _nfts) private {
        uint256 length = _nfts.length;
        uint256 totalDeposit;
        PairNftDepositWithAmount memory pair;
        Position storage position;
        for(uint256 i; i < length;) {
            pair = _nfts[i];
            position = nftPosition[BAKC_POOL_ID][pair.bakcTokenId];

            if(position.stakedAmount == 0) {
                if (nftContracts[mainTypePoolId].ownerOf(pair.mainTokenId) != msg.sender
                    || mainToBakc[mainTypePoolId][pair.mainTokenId].isPaired) revert MainTokenNotOwnedOrPaired();
                if (nftContracts[BAKC_POOL_ID].ownerOf(pair.bakcTokenId) != msg.sender
                    || bakcToMain[pair.bakcTokenId][mainTypePoolId].isPaired) revert BAKCNotOwnedOrPaired();

                mainToBakc[mainTypePoolId][pair.mainTokenId] = PairingStatus(pair.bakcTokenId, true);
                bakcToMain[pair.bakcTokenId][mainTypePoolId] = PairingStatus(pair.mainTokenId, true);
            } else if (pair.mainTokenId != bakcToMain[pair.bakcTokenId][mainTypePoolId].tokenId
                || pair.bakcTokenId != mainToBakc[mainTypePoolId][pair.mainTokenId].tokenId)
                    revert BAKCAlreadyPaired();

            _depositNftGuard(BAKC_POOL_ID, position, pair.amount);
            totalDeposit += pair.amount;
            emit DepositPairNft(msg.sender, pair.amount, mainTypePoolId, pair.mainTokenId, pair.bakcTokenId);
            unchecked {
                ++i;
            }
        }
        if (totalDeposit > 0) apeCoin.transferFrom(msg.sender, address(this), totalDeposit);
    }

    function getTimestampAsNearestHour() internal view returns (uint256) {
        return block.timestamp - (getMinute(block.timestamp) * 60 + getSecond(block.timestamp));
    }
    function hoursToSeconds(uint256 _hours) internal pure returns (uint256) {
        return _hours * SECONDS_PER_HOUR;
    }
    function _depositNftGuard(uint256 _poolId, Position storage _position, uint256 _amount) private {
        if (_amount < MIN_DEPOSIT) revert DepositMoreThanOneAPE();
        if (_amount + _position.stakedAmount > pools[_poolId].timeRanges[pools[_poolId].lastRewardsRangeIndex].capPerPosition)
            revert ExceededCapAmount();

        _deposit(_poolId, _position, _amount);
    }

    function _claim(uint256 _poolId, Position storage _position, address _recipient) private returns (uint256 rewardsToBeClaimed) {
        Pool storage pool = pools[_poolId];

        int256 accumulatedApeCoins = (_position.stakedAmount * uint256(pool.accumulatedRewardsPerShare)).toInt256();
        rewardsToBeClaimed = (accumulatedApeCoins - _position.rewardsDebt).toUint256() / APE_COIN_PRECISION;

        _position.rewardsDebt = accumulatedApeCoins;

        if (rewardsToBeClaimed != 0) {
            apeCoin.transfer(_recipient, rewardsToBeClaimed);
        }
    }

    function _claimNft(uint256 _poolId, uint256[] calldata _nfts, address _recipient) private {
        updatePool(_poolId);
        uint256 tokenId;
        uint256 rewardsToBeClaimed;
        uint256 length = _nfts.length;
        for(uint256 i; i < length;) {
            tokenId = _nfts[i];
            if (nftContracts[_poolId].ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
            Position storage position = nftPosition[_poolId][tokenId];
            rewardsToBeClaimed = _claim(_poolId, position, _recipient);
            emit ClaimRewardsNft(msg.sender, _poolId, rewardsToBeClaimed, tokenId);
            unchecked {
                ++i;
            }
        }
    }

    function _claimPairNft(uint256 mainTypePoolId, PairNft[] calldata _pairs, address _recipient) private {
        uint256 length = _pairs.length;
        uint256 mainTokenId;
        uint256 bakcTokenId;
        Position storage position;
        PairingStatus storage mainToSecond;
        PairingStatus storage secondToMain;
        for(uint256 i; i < length;) {
            mainTokenId = _pairs[i].mainTokenId;
            if (nftContracts[mainTypePoolId].ownerOf(mainTokenId) != msg.sender) revert NotOwnerOfMain();

            bakcTokenId = _pairs[i].bakcTokenId;
            if (nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId) != msg.sender) revert NotOwnerOfBAKC();

            mainToSecond = mainToBakc[mainTypePoolId][mainTokenId];
            secondToMain = bakcToMain[bakcTokenId][mainTypePoolId];

            if (mainToSecond.tokenId != bakcTokenId || !mainToSecond.isPaired
                || secondToMain.tokenId != mainTokenId || !secondToMain.isPaired) revert ProvidedTokensNotPaired();

            position = nftPosition[BAKC_POOL_ID][bakcTokenId];
            uint256 rewardsToBeClaimed = _claim(BAKC_POOL_ID, position, _recipient);
            emit ClaimRewardsPairNft(msg.sender, rewardsToBeClaimed, mainTypePoolId, mainTokenId, bakcTokenId);
            unchecked {
                ++i;
            }
        }
    }

    function _withdraw(uint256 _poolId, Position storage _position, uint256 _amount) private {
        if (_amount > _position.stakedAmount) revert ExceededStakedAmount();

        Pool storage pool = pools[_poolId];

        _position.stakedAmount -= _amount;
        pool.stakedAmount -= _amount.toUint96();
        _position.rewardsDebt -= (_amount * pool.accumulatedRewardsPerShare).toInt256();
    }

    function _withdrawNft(uint256 _poolId, SingleNft[] calldata _nfts, address _recipient) private {
        updatePool(_poolId);
        uint256 tokenId;
        uint256 amount;
        uint256 length = _nfts.length;
        uint256 totalWithdraw;
        Position storage position;
        for(uint256 i; i < length;) {
            tokenId = _nfts[i].tokenId;
            if (nftContracts[_poolId].ownerOf(tokenId) != msg.sender) revert CallerNotOwner();

            amount = _nfts[i].amount;
            position = nftPosition[_poolId][tokenId];
            if (amount == position.stakedAmount) {
                uint256 rewardsToBeClaimed = _claim(_poolId, position, _recipient);
                emit ClaimRewardsNft(msg.sender, _poolId, rewardsToBeClaimed, tokenId);
            }
            _withdraw(_poolId, position, amount);
            totalWithdraw += amount;
            emit WithdrawNft(msg.sender, _poolId, amount, _recipient, tokenId);
            unchecked {
                ++i;
            }
        }
        if (totalWithdraw > 0) apeCoin.transfer(_recipient, totalWithdraw);
    }

    function _withdrawPairNft(uint256 mainTypePoolId, PairNftWithdrawWithAmount[] calldata _nfts) private {
        address mainTokenOwner;
        address bakcOwner;
        PairNftWithdrawWithAmount memory pair;
        PairingStatus storage mainToSecond;
        PairingStatus storage secondToMain;
        Position storage position;
        uint256 length = _nfts.length;
        for(uint256 i; i < length;) {
            pair = _nfts[i];
            mainTokenOwner = nftContracts[mainTypePoolId].ownerOf(pair.mainTokenId);
            bakcOwner = nftContracts[BAKC_POOL_ID].ownerOf(pair.bakcTokenId);

            if (mainTokenOwner != msg.sender) {
                if (bakcOwner != msg.sender) revert NeitherTokenInPairOwnedByCaller();
            }

            mainToSecond = mainToBakc[mainTypePoolId][pair.mainTokenId];
            secondToMain = bakcToMain[pair.bakcTokenId][mainTypePoolId];

            if (mainToSecond.tokenId != pair.bakcTokenId || !mainToSecond.isPaired
                || secondToMain.tokenId != pair.mainTokenId || !secondToMain.isPaired) revert ProvidedTokensNotPaired();

            position = nftPosition[BAKC_POOL_ID][pair.bakcTokenId];
            if(!pair.isUncommit) {
                if(pair.amount == position.stakedAmount) revert UncommitWrongParameters();
            }
            if (mainTokenOwner != bakcOwner) {
                if (!pair.isUncommit) revert SplitPairCantPartiallyWithdraw();
            }

            if (pair.isUncommit) {
                uint256 rewardsToBeClaimed = _claim(BAKC_POOL_ID, position, bakcOwner);
                mainToBakc[mainTypePoolId][pair.mainTokenId] = PairingStatus(0, false);
                bakcToMain[pair.bakcTokenId][mainTypePoolId] = PairingStatus(0, false);
                emit ClaimRewardsPairNft(msg.sender, rewardsToBeClaimed, mainTypePoolId, pair.mainTokenId, pair.bakcTokenId);
            }
            uint256 finalAmountToWithdraw = pair.isUncommit ? position.stakedAmount: pair.amount;
            _withdraw(BAKC_POOL_ID, position, finalAmountToWithdraw);
            apeCoin.transfer(mainTokenOwner, finalAmountToWithdraw);
            emit WithdrawPairNft(msg.sender, finalAmountToWithdraw, mainTypePoolId, pair.mainTokenId, pair.bakcTokenId);
            unchecked {
                ++i;
            }
        }
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct DashboardStake {
    uint256 poolId;
    uint256 tokenId;
    uint256 deposited;
    uint256 unclaimed;
    uint256 rewards24hr;
    DashboardPair pair;
}

struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
}