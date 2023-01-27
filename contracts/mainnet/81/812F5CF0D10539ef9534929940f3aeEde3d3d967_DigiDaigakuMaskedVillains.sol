// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        address owner = _owners[tokenId];
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
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "limit-break-contracts/contracts/presets/BlacklistedTransferAdventureNFT.sol";
import "limit-break-contracts/contracts/utils/tokens/ClaimableHolderMint.sol";
import "limit-break-contracts/contracts/utils/tokens/MerkleWhitelistMint.sol";
import "limit-break-contracts/contracts/utils/tokens/SignedApprovalMint.sol";

contract DigiDaigakuMaskedVillains is BlacklistedTransferAdventureNFT, ClaimableHolderMint, MerkleWhitelistMint, SignedApprovalMint {

    constructor(address royaltyReceiver_, uint96 royaltyFeeNumerator_) ERC721("", "") EIP712("DigiDaigakuMaskedVillains", "1")  {
        initializeERC721("DigiDaigakuMaskedVillains", "DIDMV");
        initializeURI("https://digidaigaku.com/masked-villains/metadata/", ".json");
        initializeAdventureERC721(100);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeOperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return
        interfaceId == type(ISignedApprovalInitializer).interfaceId ||
        interfaceId == type(IRootCollectionInitializer).interfaceId ||
        interfaceId == type(IMerkleRootInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function _safeMintToken(address to, uint256 tokenId) internal virtual override(ClaimableHolderMint, MerkleWhitelistMint, SignedApprovalMint) {
        _safeMint(to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAdventurous.sol";
import "./AdventureWhitelist.sol";
import "../initializable/IAdventureERC721Initializer.sol";
import "../utils/tokens/InitializableERC721.sol";

error AdventureApprovalToCaller();
error AlreadyInitializedAdventureERC721();
error AlreadyOnQuest();
error AnActiveQuestIsPreventingTransfers();
error CallerNotApprovedForAdventure();
error CallerNotTokenOwner();
error MaxSimultaneousQuestsCannotBeZero();
error MaxSimultaneousQuestsExceeded();
error NotOnQuest();
error QuestIdOutOfRange();
error TooManyActiveQuests();

/**
 * @title AdventureERC721
 * @author Limit Break, Inc.
 * @notice Implements the {IAdventurous} token standard for ERC721-compliant tokens.
 * Includes a user approval mechanism specific to {IAdventurous} functionality.
 * @dev Inherits {InitializableERC721} to provide the option to support EIP-1167.
 */
abstract contract AdventureERC721 is InitializableERC721, AdventureWhitelist, IAdventurous, IAdventureERC721Initializer {

    /// @notice Specifies an upper bound for the maximum number of simultaneous quests per adventure.
    uint256 private constant MAX_CONCURRENT_QUESTS = 100;

    /// @dev A value denoting a transfer originating from transferFrom or safeTransferFrom
    uint256 internal constant TRANSFERRING_VIA_ERC721 = 1;

    /// @dev A value denoting a transfer originating from adventureTransferFrom or adventureSafeTransferFrom
    uint256 internal constant TRANSFERRING_VIA_ADVENTURE = 2;

    /// @notice Specifies whether or not the contract is initialized
    bool private initializedAdventureERC721;

    /// @dev Specifies the type of transfer that is actively being used
    uint256 internal transferType;

    /// @dev The most simultaneous quests the token may participate in at a time
    uint256 private _maxSimultaneousQuests;

    /// @dev Maps each token id to the number of blocking quests it is currently entered into
    mapping (uint256 => uint256) internal blockingQuestCounts;

    /// @dev Mapping from owner to operator approvals for special gameplay behavior
    mapping (address => mapping (address => bool)) private operatorAdventureApprovals;

    /// @dev Maps each token id to a mapping that can enumerate all active quests within an adventure
    mapping (uint256 => mapping (address => uint32[])) public activeQuestList;

    /// @dev Maps each token id to a mapping from adventure address to a mapping of quest ids to quest details
    mapping (uint256 => mapping (address => mapping (uint32 => Quest))) public activeQuestLookup;

    /// @dev Initializes parameters of AdventureERC721 tokens.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeAdventureERC721(uint256 maxSimultaneousQuests_) public override onlyOwner {
        if(initializedAdventureERC721) {
            revert AlreadyInitializedAdventureERC721();
        }

        _validateMaxSimultaneousQuests(maxSimultaneousQuests_);
        _maxSimultaneousQuests = maxSimultaneousQuests_;

        initializedAdventureERC721 = true;
        transferType = TRANSFERRING_VIA_ERC721;
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override (InitializableERC721, IERC165) returns (bool) {
        return 
        interfaceId == type(IAdventurous).interfaceId || 
        interfaceId == type(IAdventureERC721Initializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /// @notice Transfers a player's token if they have opted into an authorized, whitelisted adventure.
    function adventureTransferFrom(address from, address to, uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        transferType = TRANSFERRING_VIA_ADVENTURE;
        _transfer(from, to, tokenId);
        transferType = TRANSFERRING_VIA_ERC721;
    }

    /// @notice Safe transfers a player's token if they have opted into an authorized, whitelisted adventure.
    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        transferType = TRANSFERRING_VIA_ADVENTURE;
        _safeTransfer(from, to, tokenId, "");
        transferType = TRANSFERRING_VIA_ERC721;
    }

    /// @notice Burns a player's token if they have opted into an authorized, whitelisted adventure.
    function adventureBurn(uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        transferType = TRANSFERRING_VIA_ADVENTURE;
        _burn(tokenId);
        transferType = TRANSFERRING_VIA_ERC721;
    }

    /// @notice Enters a player's token into a quest if they have opted into an authorized, whitelisted adventure.
    function enterQuest(uint256 tokenId, uint256 questId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _enterQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Exits a player's token from a quest if they have opted into an authorized, whitelisted adventure.
    /// For developers of adventure contracts that perform adventure burns, be aware that the adventure must exitQuest
    /// before the adventure burn occurs, as _exitQuest emits the owner of the token, which would revert after burning.
    function exitQuest(uint256 tokenId, uint256 questId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _exitQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Admin-only ability to boot a token from all quests on an adventure.
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function bootFromAllQuests(uint256 tokenId, address adventure) external onlyOwner {
        _requireAdventureRemovedFromWhitelist(adventure);
        _exitAllQuests(tokenId, adventure, true);
    }

    /// @notice Gives the player the ability to exit a quest without interacting directly with the approved, whitelisted adventure
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function userExitQuest(uint256 tokenId, address adventure, uint256 questId) external {
        _requireAdventureRemovedFromWhitelist(adventure);
        _requireCallerOwnsToken(tokenId);
        _exitQuest(tokenId, adventure, questId);
    }

    /// @notice Gives the player the ability to exit all quests on an adventure without interacting directly with the approved, whitelisted adventure
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function userExitAllQuests(uint256 tokenId, address adventure) external {
        _requireAdventureRemovedFromWhitelist(adventure);
        _requireCallerOwnsToken(tokenId);
        _exitAllQuests(tokenId, adventure, false);
    }

    /// @notice Similar to {IERC721-setApprovalForAll}, but for special in-game adventures only
    function setAdventuresApprovedForAll(address operator, bool approved) external {
        address tokenOwner = _msgSender();

        if(tokenOwner == operator) {
            revert AdventureApprovalToCaller();
        }
        operatorAdventureApprovals[tokenOwner][operator] = approved;
        emit AdventureApprovalForAll(tokenOwner, operator, approved);
    }

    /// @notice Similar to {IERC721-isApprovedForAll}, but for special in-game adventures only
    function areAdventuresApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorAdventureApprovals[owner][operator];
    }    
    
    /// @notice Returns the number of quests a token is actively participating in for a specified adventure
    function getQuestCount(uint256 tokenId, address adventure) public override view returns (uint256) {
        return activeQuestList[tokenId][adventure].length;
    }

    /// @notice Returns the amount of time a token has been participating in the specified quest
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId) public override view returns (uint256) {
        (bool participatingInQuest, uint256 startTimestamp,) = isParticipatingInQuest(tokenId, adventure, questId);
        return participatingInQuest ? (block.timestamp - startTimestamp) : 0;
    } 

    /// @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
    function isParticipatingInQuest(uint256 tokenId, address adventure, uint256 questId) public override view returns (bool participatingInQuest, uint256 startTimestamp, uint256 index) {
        if(questId > type(uint32).max) {
            revert QuestIdOutOfRange();
        }

        Quest storage quest = activeQuestLookup[tokenId][adventure][uint32(questId)];
        participatingInQuest = quest.isActive;
        startTimestamp = quest.startTimestamp;
        index = quest.arrayIndex;
        return (participatingInQuest, startTimestamp, index);
    }

    /// @notice Returns a list of all active quests for the specified token id and adventure
    function getActiveQuests(uint256 tokenId, address adventure) public override view returns (Quest[] memory activeQuests) {
        uint256 questCount = getQuestCount(tokenId, adventure);
        activeQuests = new Quest[](questCount);
        uint32[] memory activeQuestIdList = activeQuestList[tokenId][adventure];

        for(uint256 i = 0; i < questCount; ++i) {
            activeQuests[i] = activeQuestLookup[tokenId][adventure][activeQuestIdList[i]];
        }

        return activeQuests;
    }

    /// @notice Returns the maximum number of simultaneous quests the token can be in per adventure.
    function maxSimultaneousQuests() public view returns (uint256) {
        return _maxSimultaneousQuests;
    }

    /// @dev Enters the specified quest for a token id.
    /// Throws if the token is already participating in the specified quest.
    /// Throws if the number of active quests exceeds the max allowable for the given adventure.
    /// Emits a QuestUpdated event for off-chain processing.
    function _enterQuest(uint256 tokenId, address adventure, uint256 questId) internal {
        (bool participatingInQuest,,) = isParticipatingInQuest(tokenId, adventure, questId);
        if(participatingInQuest) {
            revert AlreadyOnQuest();
        }

        uint256 currentQuestCount = getQuestCount(tokenId, adventure);
        if(currentQuestCount >= _maxSimultaneousQuests) {
            revert TooManyActiveQuests();
        }

        uint32 castedQuestId = uint32(questId);
        activeQuestList[tokenId][adventure].push(castedQuestId);
        activeQuestLookup[tokenId][adventure][castedQuestId].isActive = true;
        activeQuestLookup[tokenId][adventure][castedQuestId].startTimestamp = uint64(block.timestamp);
        activeQuestLookup[tokenId][adventure][castedQuestId].questId = castedQuestId;
        activeQuestLookup[tokenId][adventure][castedQuestId].arrayIndex = uint32(currentQuestCount);

        address ownerOfToken = ownerOf(tokenId);
        emit QuestUpdated(tokenId, ownerOfToken, adventure, questId, true, false);

        if(IAdventure(adventure).questsLockTokens()) {
            unchecked {
                ++blockingQuestCounts[tokenId];
            }
        }

        // Invoke callback to the adventure to facilitate state synchronization as needed
        IAdventure(adventure).onQuestEntered(ownerOfToken, tokenId, questId);
    }

    /// @dev Exits the specified quest for a token id.
    /// Throws if the token is not currently participating on the specified quest.
    /// Emits a QuestUpdated event for off-chain processing.
    function _exitQuest(uint256 tokenId, address adventure, uint256 questId) internal {
        (bool participatingInQuest, uint256 startTimestamp, uint256 index) = isParticipatingInQuest(tokenId, adventure, questId);
        if(!participatingInQuest) {
            revert NotOnQuest();
        }

        uint32 castedQuestId = uint32(questId);
        uint256 lastArrayIndex = getQuestCount(tokenId, adventure) - 1;
        if(index != lastArrayIndex) {
            activeQuestList[tokenId][adventure][index] = activeQuestList[tokenId][adventure][lastArrayIndex];
            activeQuestLookup[tokenId][adventure][activeQuestList[tokenId][adventure][lastArrayIndex]].arrayIndex = uint32(index);
        }

        activeQuestList[tokenId][adventure].pop();
        delete activeQuestLookup[tokenId][adventure][castedQuestId];

        address ownerOfToken = ownerOf(tokenId);
        emit QuestUpdated(tokenId, ownerOfToken, adventure, questId, false, false);

        if(IAdventure(adventure).questsLockTokens()) {
            --blockingQuestCounts[tokenId];
        }

        // Invoke callback to the adventure to facilitate state synchronization as needed
        IAdventure(adventure).onQuestExited(ownerOfToken, tokenId, questId, startTimestamp);
    }

    /// @dev Removes the specified token id from all quests on the specified adventure
    function _exitAllQuests(uint256 tokenId, address adventure, bool booted) internal {
        address tokenOwner = ownerOf(tokenId);
        uint256 questCount = getQuestCount(tokenId, adventure);

        if(IAdventure(adventure).questsLockTokens()) {
            blockingQuestCounts[tokenId] -= questCount;
        }

        for(uint256 i = 0; i < questCount;) {
            uint32 questId = activeQuestList[tokenId][adventure][i];

            Quest memory quest = activeQuestLookup[tokenId][adventure][questId];
            uint256 startTimestamp = quest.startTimestamp;

            emit QuestUpdated(tokenId, tokenOwner, adventure, questId, false, booted);
            delete activeQuestLookup[tokenId][adventure][questId];
            
            // Invoke callback to the adventure to facilitate state synchronization as needed
            IAdventure(adventure).onQuestExited(tokenOwner, tokenId, questId, startTimestamp);

            unchecked {
                ++i;
            }
        }

        delete activeQuestList[tokenId][adventure];
    }

    /// @dev By default, tokens that are participating in quests are transferrable.  However, if a token is participating
    /// in a quest on an adventure that was designated as a token locker, the transfer will revert and keep the token
    /// locked.
    function _beforeTokenTransfer(address /*from*/, address /*to*/, uint256 tokenId) internal virtual override {
        if(blockingQuestCounts[tokenId] > 0) {
            revert AnActiveQuestIsPreventingTransfers();
        }
    }

    /// @dev Validates that the caller is approved for adventure on the specified token id
    /// Throws when the caller has not been approved by the user.
    function _requireCallerApprovedForAdventure(uint256 tokenId) internal view {
        if(!areAdventuresApprovedForAll(ownerOf(tokenId), _msgSender())) {
            revert CallerNotApprovedForAdventure();
        }
    }

    /// @dev Validates that the caller owns the specified token
    /// Throws when the caller does not own the specified token.
    function _requireCallerOwnsToken(uint256 tokenId) internal view {
        if(ownerOf(tokenId) != _msgSender()) {
            revert CallerNotTokenOwner();
        }
    }

    /// @dev Validates that the specified value of max simultaneous quests is in range [1-MAX_CONCURRENT_QUESTS]
    /// Throws when `maxSimultaneousQuests_` is zero.
    /// Throws when `maxSimultaneousQuests_` is more than MAX_CONCURRENT_QUESTS.
    function _validateMaxSimultaneousQuests(uint256 maxSimultaneousQuests_) internal pure {
        if(maxSimultaneousQuests_ == 0) {
            revert MaxSimultaneousQuestsCannotBeZero();
        }

        if(maxSimultaneousQuests_ > MAX_CONCURRENT_QUESTS) {
            revert MaxSimultaneousQuestsExceeded();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AdventureERC721.sol";
import "../initializable/IRoyaltiesInitializer.sol";
import "../initializable/IURIInitializer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error AlreadyInitializedRoyalties();
error AlreadyInitializedURI();
error ExceedsMaxRoyaltyFee();
error NonexistentToken();

/**
 * @title AdventureNFT
 * @author Limit Break, Inc.
 * @notice Standardizes commonly shared boilerplate code that adds base/suffix URI and EIP-2981 royalties to {AdventureERC721} contracts.
 */
abstract contract AdventureNFT is AdventureERC721, ERC2981, IRoyaltiesInitializer, IURIInitializer {
    using Strings for uint256;

    /// @dev The maximum allowable royalty fee is 100%
    uint96 private constant MAX_ROYALTY_FEE_NUMERATOR = 10000;

    /// @notice Specifies whether or not the contract is initialized
    bool private initializedRoyalties;

    /// @notice Specifies whether or not the contract is initialized
    bool private initializedURI;

    /// @dev Base token uri
    string public baseTokenURI;

    /// @dev Token uri suffix/extension
    string public suffixURI = ".json";

    /// @dev Emitted when base URI is set.
    event BaseURISet(string baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string suffixURI);

    /// @dev Emitted when royalty is set.
    event RoyaltySet(address receiver, uint96 feeNumerator);

    /// @dev Initializes parameters of tokens with royalties.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeRoyalties(address receiver, uint96 feeNumerator) public override onlyOwner {
        if(initializedRoyalties) {
            revert AlreadyInitializedRoyalties();
        }

        setRoyaltyInfo(receiver, feeNumerator);

        initializedRoyalties = true;
    }

    /// @dev Initializes parameters of tokens with uri values.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeURI(string memory baseURI_, string memory suffixURI_) public override onlyOwner {
        if(initializedURI) {
            revert AlreadyInitializedURI();
        }

        setBaseURI(baseURI_);
        setSuffixURI(suffixURI_);

        initializedURI = true;
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Sets base URI
    function setBaseURI(string memory baseTokenURI_) public onlyOwner {
        baseTokenURI = baseTokenURI_;

        emit BaseURISet(baseTokenURI_);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string memory suffixURI_) public onlyOwner {
        suffixURI = suffixURI_;

        emit SuffixURISet(suffixURI_);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
        if(feeNumerator > MAX_ROYALTY_FEE_NUMERATOR) {
            revert ExceedsMaxRoyaltyFee();
        }
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltySet(receiver, feeNumerator);
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) {
            revert NonexistentToken();
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AdventureERC721, ERC2981, IERC165) returns (bool) {
        return
        interfaceId == type(IRoyaltiesInitializer).interfaceId ||
        interfaceId == type(IURIInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAdventure.sol";
import "../utils/access/InitializableOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error AdventureIsStillWhitelisted();
error AlreadyWhitelisted();
error ArrayIndexOverflowsUint128();
error CallerNotAWhitelistedAdventure();
error InvalidAdventureContract();
error NotWhitelisted();

/**
 * @title AdventureWhitelist
 * @author Limit Break, Inc.
 * @notice Implements the basic security features of the {IAdventurous} token standard for ERC721-compliant tokens.
 * This includes a whitelist for trusted Adventure contracts designed to interoperate with this token.
 */
abstract contract AdventureWhitelist is InitializableOwnable {

    struct AdventureDetails {
        bool isWhitelisted;
        uint128 arrayIndex;
    }

    /// @dev Emitted when the adventure whitelist is updated
    event AdventureWhitelistUpdated(address indexed adventure, bool whitelisted);
    
    /// @dev Whitelist array for iteration
    address[] public whitelistedAdventureList;

    /// @dev Whitelist mapping
    mapping (address => AdventureDetails) public whitelistedAdventures;

    /// @notice Returns whether the specified account is a whitelisted adventure
    function isAdventureWhitelisted(address account) public view returns (bool) {
        return whitelistedAdventures[account].isWhitelisted;
    }

    /// @notice Whitelists an adventure and specifies whether or not the quests in that adventure lock token transfers
    /// Throws when the adventure is already in the whitelist.
    /// Throws when the specified address does not implement the IAdventure interface.
    ///
    /// Postconditions:
    /// The specified adventure contract is in the whitelist.
    /// An `AdventureWhitelistUpdate` event has been emitted.
    function whitelistAdventure(address adventure) external onlyOwner {
        if(isAdventureWhitelisted(adventure)) {
            revert AlreadyWhitelisted();
        }

        if(!IERC165(adventure).supportsInterface(type(IAdventure).interfaceId)) {
            revert InvalidAdventureContract();
        }

        uint256 arrayIndex = whitelistedAdventureList.length;
        if(arrayIndex > type(uint128).max) {
            revert ArrayIndexOverflowsUint128();
        }

        whitelistedAdventures[adventure].isWhitelisted = true;
        whitelistedAdventures[adventure].arrayIndex = uint128(arrayIndex);
        whitelistedAdventureList.push(adventure);

        emit AdventureWhitelistUpdated(adventure, true);
    }

    /// @notice Removes an adventure from the whitelist
    /// Throws when the adventure is not in the whitelist.
    ///
    /// Postconditions:
    /// The specified adventure contract is no longer in the whitelist.
    /// An `AdventureWhitelistUpdate` event has been emitted.
    function unwhitelistAdventure(address adventure) external onlyOwner {
        if(!isAdventureWhitelisted(adventure)) {
            revert NotWhitelisted();
        }
        
        uint128 itemPositionToDelete = whitelistedAdventures[adventure].arrayIndex;
        uint256 arrayEndIndex = whitelistedAdventureList.length - 1;
        if(itemPositionToDelete != arrayEndIndex) {
            whitelistedAdventureList[itemPositionToDelete] = whitelistedAdventureList[arrayEndIndex];
            whitelistedAdventures[whitelistedAdventureList[itemPositionToDelete]].arrayIndex = itemPositionToDelete;
        }

        whitelistedAdventureList.pop();
        delete whitelistedAdventures[adventure];

        emit AdventureWhitelistUpdated(adventure, false);
    }

    /// @dev Validates that the caller is a whitelisted adventure
    /// Throws when the caller is not in the adventure whitelist.
    function _requireCallerIsWhitelistedAdventure() internal view {
        if(!isAdventureWhitelisted(_msgSender())) {
            revert CallerNotAWhitelistedAdventure();
        }
    }

    /// @dev Validates that the specified adventure has been removed from the whitelist
    /// to prevent early backdoor exiting from adventures.
    /// Throws when specified adventure is still whitelisted.
    function _requireAdventureRemovedFromWhitelist(address adventure) internal view {
        if(isAdventureWhitelisted(adventure)) {
            revert AdventureIsStillWhitelisted();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IAdventure
 * @author Limit Break, Inc.
 * @notice The base interface that all `Adventure` contracts must conform to.
 * @dev All contracts that implement the adventure/quest system and interact with an {IAdventurous} token are required to implement this interface.
 */
interface IAdventure is IERC165 {

    /**
     * @dev Returns whether or not quests on this adventure lock tokens.
     * Developers of adventure contract should ensure that this is immutable 
     * after deployment of the adventure contract.  Failure to do so
     * can lead to error that deadlock token transfers.
     */
    function questsLockTokens() external view returns (bool);

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestEntered(address adventurer, uint256 tokenId, uint256 questId) external;

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestExited(address adventurer, uint256 tokenId, uint256 questId, uint256 questStartTimestamp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Quest.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IAdventurous
 * @author Limit Break, Inc.
 * @notice The base interface that all `Adventurous` token contracts must conform to in order to support adventures and quests.
 * @dev All contracts that support adventures and quests are required to implement this interface.
 */
interface IAdventurous is IERC165 {

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets, for special in-game adventures.
     */ 
    event AdventureApprovalForAll(address indexed tokenOwner, address indexed operator, bool approved);

    /**
     * @dev Emitted when a token enters or exits a quest
     */
    event QuestUpdated(uint256 indexed tokenId, address indexed tokenOwner, address indexed adventure, uint256 questId, bool active, bool booted);

    /**
     * @notice Transfers a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Safe transfers a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Burns a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureBurn(uint256 tokenId) external;

    /**
     * @notice Enters a player's token into a quest if they have opted into an authorized, whitelisted adventure.
     */
    function enterQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Exits a player's token from a quest if they have opted into an authorized, whitelisted adventure.
     */
    function exitQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Returns the number of quests a token is actively participating in for a specified adventure
     */
    function getQuestCount(uint256 tokenId, address adventure) external view returns (uint256);

    /**
     * @notice Returns the amount of time a token has been participating in the specified quest
     */
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId) external view returns (uint256);

    /**
     * @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
     */
    function isParticipatingInQuest(uint256 tokenId, address adventure, uint256 questId) external view returns (bool participatingInQuest, uint256 startTimestamp, uint256 index);

    /**
     * @notice Returns a list of all active quests for the specified token id and adventure
     */
    function getActiveQuests(uint256 tokenId, address adventure) external view returns (Quest[] memory activeQuests);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Quest
 * @author Limit Break, Inc.
 * @notice Quest data structure for {IAdventurous} contracts.
 */
struct Quest {
    bool isActive;
    uint32 questId;
    uint64 startTimestamp;
    uint32 arrayIndex;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IAdventureERC721Initializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include Adventure ERC721 functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IAdventureERC721Initializer is IERC165 {

    /**
     * @notice Initializes parameters of {AdventureERC721} contracts
     */
    function initializeAdventureERC721(uint256 maxSimultaneousQuests_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IERC721Initializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenZeppelin ERC721 functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IERC721Initializer is IERC721 {

    /**
     * @notice Initializes parameters of {ERC721} contracts
     */
    function initializeERC721(string memory name_, string memory symbol_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IMerkleRootInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include a merkle root.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IMerkleRootInitializer is IERC165 {

    /**
     * @notice Initializes root collection parameters
     */
    function initializeMerkleRoot(bytes32 merkleRoot_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IOperatorFiltererInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenSea's OperatorFilterer functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IOperatorFiltererInitializer {

    /**
     * @notice Initializes parameters of OperatorFilterer contracts
     */
    function initializeOperatorFilterer(address subscriptionOrRegistrantToCopy, bool subscribe) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IOwnableInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenZeppelin Ownable functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IOwnableInitializer is IERC165 {

    /**
     * @notice Initializes the contract owner to the specified address
     */
    function initializeOwner(address owner_) external;

    /**
     * @notice Transfers ownership of the contract to the specified owner
     */
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRootCollectionInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to be tied to a root ERC-721 collection.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IRootCollectionInitializer is IERC165 {

    /**
     * @notice Initializes root collection parameters
     */
    function initializeRootCollections(address[] memory rootCollection_, uint256[] memory rootCollectionMaxSupply_, uint256[] memory tokensPerClaim_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRoyaltiesInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenZeppelin ERC2981 functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IRoyaltiesInitializer is IERC165 {

    /**
     * @notice Initializes royalty parameters
     */
    function initializeRoyalties(address receiver, uint96 feeNumerator) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ISignedApprovalInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to be assigned an approver to sign transactions allowing mints.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface ISignedApprovalInitializer is IERC165 {

    /**
     * @notice Initializes approver.
     */
    function initializeSigner(address signer, uint256 maxQuantity) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IURIInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include a base uri and suffix uri.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IURIInitializer is IERC165 {

    /**
     * @notice Initializes uri parameters
     */
    function initializeURI(string memory baseURI_, string memory suffixURI_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {InitializableOperatorFilterer} from "./InitializableOperatorFilterer.sol";

/**
 * @title  InitializableDefaultOperatorFilterer
 * @notice Inherits from InitializableOperatorFilterer and automatically subscribes to the default OpenSea subscription during initialization.
 */
abstract contract InitializableDefaultOperatorFilterer is InitializableOperatorFilterer {
    
    /// @dev The default subscription address
    address internal constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    /// @dev The parameters are ignored, and the default subscription values are used instead.
    function initializeOperatorFilterer(address /*subscriptionOrRegistrantToCopy*/, bool /*subscribe*/) public virtual override {
        super.initializeOperatorFilterer(DEFAULT_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {IOperatorFiltererInitializer} from "../../initializable/IOperatorFiltererInitializer.sol";

/**
 * @title  InitializableOperatorFilterer
 * @notice Abstract contract whose initializer function automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         This is safe for use in EIP-1167 clones
 */
abstract contract InitializableOperatorFilterer is IOperatorFiltererInitializer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function initializeOperatorFilterer(address subscriptionOrRegistrantToCopy, bool subscribe) public virtual override {
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

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

import "../adventures/AdventureNFT.sol";
import "../opensea/operator-filter-registry/InitializableDefaultOperatorFilterer.sol";

/**
 * @title BlacklistedTransferAdventureNFT
 * @author Limit Break, Inc.
 * @notice Extends AdventureNFT, adding whitelisted transfer mechanisms.
 */
abstract contract BlacklistedTransferAdventureNFT is AdventureNFT, InitializableDefaultOperatorFilterer {

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../initializable/IOwnableInitializer.sol";
import "@openzeppelin/contracts/utils/Context.sol";

error CallerIsNotTheContractOwner();
error NewOwnerIsTheZeroAddress();
error OwnerAlreadyInitialized();

/**
 * @title InitializableOwnable
 * @author Limit Break, Inc. and OpenZeppelin
 * @notice A tailored version of the {Ownable}  permissions component from OpenZeppelin that is compatible with EIP-1167.
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * Based on OpenZeppelin contracts commit hash 3dac7bbed7b4c0dbf504180c33e8ed8e350b93eb.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * This version adds an `initializeOwner` call for use with EIP-1167, 
 * as the constructor will not be called during an EIP-1167 operation.
 * Because initializeOwner should only be called once and requires that 
 * the owner is not assigned, the `renounceOwnership` function has been removed to avoid
 * a scenario where a contract could be left without an owner to perform admin protected functions.
 */
abstract contract InitializableOwnable is Context, IOwnableInitializer {
    address private _owner;

    /// @dev Emitted when contract ownership has been transferred.
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
     * @dev When EIP-1167 is used to clone a contract that inherits Ownable permissions,
     * this is required to assign the initial contract owner, as the constructor is
     * not called during the cloning process.
     */
    function initializeOwner(address owner_) public override {
      if(_owner != address(0)) {
          revert OwnerAlreadyInitialized();
      }

      _transferOwnership(owner_);
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
        if(owner() != _msgSender()) {
            revert CallerIsNotTheContractOwner();
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if(newOwner == address(0)) {
            revert NewOwnerIsTheZeroAddress();
        }

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
pragma solidity ^0.8.4;

import "./SequentialMintBase.sol";
import "./ClaimPeriodBase.sol";
import "../access/InitializableOwnable.sol";
import "../../initializable/IRootCollectionInitializer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CallerDoesNotOwnRootTokenId();
error CollectionAddressIsNotAnERC721Token();
error InputArrayLengthMismatch();
error InvalidRootCollectionAddress();
error InvalidRootCollectionTokenId();
error MaxSupplyOfRootTokenCannotBeZero();
error MustSpecifyAtLeastOneRootCollection();
error RootCollectionsAlreadyInitialized();
error RootCollectionHasNotBeenInitialized();
error TokenIdAlreadyClaimed();
error TokensPerClaimMustBeBetweenOneAndTen();
error MaxNumberOfRootCollectionsExceeded();
error BatchSizeMustBeGreaterThanZero();
error BatchSizeGreaterThanMaximum();

/**
 * @title ClaimableHolderMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with sequential role-based minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken` and implement EIP-165 support as shown:
 *
 * function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
 *     return
 *     interfaceId == type(IRootCollectionInitializer).interfaceId ||
 *     super.supportsInterface(interfaceId);
 *  }
 *
 */
abstract contract ClaimableHolderMint is InitializableOwnable, ClaimPeriodBase, SequentialMintBase, ReentrancyGuard, IRootCollectionInitializer {

    struct ClaimableRootCollection {
        /// @dev Indicates whether or not this is a root collection
        bool isRootCollection;

        /// @dev This is the root ERC-721 contract from which claims can be made
        IERC721 rootCollection;

        /// @dev Max supply of the root collection
        uint256 maxSupply;

        /// @dev Number of tokens each user should get per token id claim
        uint256 tokensPerClaim;

        /// @dev Bitmap that helps determine if a token was ever claimed previously
        uint256[] claimedTokenTracker;
    }

    /// @dev The maximum amount of minted tokens from one batch submission.
    uint256 private constant MAX_MINTS_PER_TRANSACTION = 300;

    /// @dev The maximum amount of Root Collections permitted
    uint256 private constant MAX_ROOT_COLLECTIONS = 25;

    /// @dev True if root collections have been initialized, false otherwise.
    bool private initializedRootCollections;

    /// @dev Mapping from root collection address to claim details
    mapping (address => ClaimableRootCollection) private rootCollectionLookup;

    /// @dev Emitted when a holder claims a mint
    event ClaimMinted(address indexed rootCollection, uint256 indexed rootCollectionTokenId, uint256 startTokenId, uint256 endTokenId);

    /// @dev Initializes root collection parameters that determine how the claims will work.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    /// Params are memory to allow for initialization within constructors.
    /// The sum of all root collections max supplies cannot exceed 256,000 tokens.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the root collection has already been initialized.
    /// Throws when the specified root collection is not an ERC721 token.
    /// Throws when the number of tokens per claim is not between 1 and 10.
    function initializeRootCollections(address[] memory rootCollections_, uint256[] memory rootCollectionMaxSupplies_, uint256[] memory tokensPerClaimArray_) public override onlyOwner {
        if(initializedRootCollections) {
            revert RootCollectionsAlreadyInitialized();
        }

        uint256 rootCollectionsArrayLength = rootCollections_.length;

        _requireInputArrayLengthsMatch(rootCollectionsArrayLength, rootCollectionMaxSupplies_.length);
        _requireInputArrayLengthsMatch(rootCollectionsArrayLength, tokensPerClaimArray_.length);

        if(rootCollectionsArrayLength == 0) {
            revert MustSpecifyAtLeastOneRootCollection();
        }
        if(rootCollectionsArrayLength > MAX_ROOT_COLLECTIONS) {
            revert MaxNumberOfRootCollectionsExceeded();
        }

        for(uint256 i = 0; i < rootCollectionsArrayLength;) {
            address rootCollection_ = rootCollections_[i];
            uint256 rootCollectionMaxSupply_ = rootCollectionMaxSupplies_[i];
            uint256 tokensPerClaim_ = tokensPerClaimArray_[i];
            if(!IERC165(rootCollection_).supportsInterface(type(IERC721).interfaceId)) {
                revert CollectionAddressIsNotAnERC721Token();
            }

            if(tokensPerClaim_ == 0 || tokensPerClaim_ > 10) {
                revert TokensPerClaimMustBeBetweenOneAndTen();
            }

            if(rootCollectionMaxSupply_ == 0) {
                revert MaxSupplyOfRootTokenCannotBeZero();
            }

            rootCollectionLookup[rootCollection_].isRootCollection = true;
            rootCollectionLookup[rootCollection_].rootCollection = IERC721(rootCollection_);
            rootCollectionLookup[rootCollection_].maxSupply = rootCollectionMaxSupply_;
            rootCollectionLookup[rootCollection_].tokensPerClaim = tokensPerClaim_;

            unchecked {
                // Initialize memory to use for tracking token ids that have been minted
                // The bit corresponding to token id defaults to 1 when unminted,
                // and will be set to 0 upon mint.
                uint256 numberOfTokenTrackerSlots = _getNumberOfTokenTrackerSlots(rootCollectionMaxSupply_);
                for(uint256 j = 0; j < numberOfTokenTrackerSlots; ++j) {
                    rootCollectionLookup[rootCollection_].claimedTokenTracker.push(type(uint256).max);
                }

                ++i;
            }
        }

        _initializeNextTokenIdCounter();
        initializedRootCollections = true;
    }

    /// @notice Allows a user to claim/mint one or more tokens pegged to their ownership of a list of specified token ids
    ///
    /// Throws when an empty array of root collection token ids is provided.
    /// Throws when the amount of claimed tokens exceeds the max claimable amount.
    /// Throws when the claim period has not opened.
    /// Throws when the claim period has closed.
    /// Throws when the caller does not own the specified token id from the root collection.
    /// Throws when the root token id has already been claimed.
    /// Throws if safe mint receiver is not an EOA or a contract that can receive tokens.
    /// Postconditions:
    /// ---------------
    /// The root collection and token ID combinations are marked as claimed in the root collection's claimed token tracker.
    /// `quantity` tokens are minted to the msg.sender, where `quantity` is the amount of tokens per claim * length of the rootCollectionTokenIds array.
    /// `quantity` ClaimMinted events have been emitted, where `quantity` is the amount of tokens per claim * length of the rootCollectionTokenIds array.
    function claimBatch(address rootCollectionAddress, uint256[] calldata rootCollectionTokenIds) external nonReentrant {
        _requireClaimsOpen();

        if(!initializedRootCollections) {
            revert RootCollectionHasNotBeenInitialized();
        }

        if (rootCollectionTokenIds.length == 0) {
            revert BatchSizeMustBeGreaterThanZero();
        }

        ClaimableRootCollection storage rootCollectionDetails = _getRootCollectionDetailsSafe(rootCollectionAddress);

        uint256 maxBatchSize = MAX_MINTS_PER_TRANSACTION / rootCollectionDetails.tokensPerClaim;

        if (rootCollectionTokenIds.length > maxBatchSize) {
            revert BatchSizeGreaterThanMaximum();
        }

        for(uint256 i = 0; i < rootCollectionTokenIds.length;) {
            _claim(rootCollectionDetails, rootCollectionTokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Processes a claim for a Root Collection + Root Collection Token ID Combination
    ///
    /// Throws when the caller does not own the specified token id from the root collection.
    /// Throws when the root token id has already been claimed.
    /// Throws if safe mint receiver is not an EOA or a contract that can receive tokens.
    /// Postconditions:
    /// ---------------
    /// The root collection and tokenID combination are marked as claimed in the root collection's claimed token tracker.
    /// `quantity` tokens are minted to the msg.sender, where `quantity` is the amount of tokens per claim.
    /// The nextTokenId counter is advanced by the `quantity` of tokens minted.
    /// `quantity` ClaimMinted events have been emitted, where `quantity` is the amount of tokens per claim.
    function _claim(ClaimableRootCollection storage rootCollectionDetails, uint256 rootCollectionTokenId) internal {
        if(rootCollectionDetails.rootCollection.ownerOf(rootCollectionTokenId) != _msgSender()) {
            revert CallerDoesNotOwnRootTokenId();
        }

        (bool claimed, uint256 slot, uint256 offset, uint256 slotValue) = _isClaimed(rootCollectionDetails, rootCollectionTokenId);
        if(claimed) {
            revert TokenIdAlreadyClaimed();
        }

        uint256 claimedTokenId = getNextTokenId();
        uint256 tokensPerClaim_ = rootCollectionDetails.tokensPerClaim;
        emit ClaimMinted(address(rootCollectionDetails.rootCollection), rootCollectionTokenId, claimedTokenId, claimedTokenId + tokensPerClaim_ - 1);

        rootCollectionDetails.claimedTokenTracker[slot] = slotValue & ~(uint256(1) << offset);

        unchecked {
            _advanceNextTokenIdCounter(tokensPerClaim_);

            for(uint256 i = 0; i < tokensPerClaim_; ++i) {
                _safeMintToken(_msgSender(), claimedTokenId + i);
            }
        }
    }

    /// @notice Returns true if the specified token id has been claimed
    function isClaimed(address rootCollectionAddress, uint256 tokenId) public view returns (bool) {
        ClaimableRootCollection storage rootCollectionDetails = _getRootCollectionDetailsSafe(rootCollectionAddress);
        
        if(tokenId > rootCollectionDetails.maxSupply) {
            revert InvalidRootCollectionTokenId();
        }

        (bool claimed,,,) = _isClaimed(rootCollectionDetails, tokenId);
        return claimed;
    }

    /// @dev Returns whether or not the specified token id has been claimed/minted as well as the bitmap slot/offset/slot value of the token id
    function _isClaimed(ClaimableRootCollection storage rootCollectionDetails, uint256 tokenId) internal view returns (bool claimed, uint256 slot, uint256 offset, uint256 slotValue) {
        unchecked {
            slot = tokenId / 256;
            offset = tokenId % 256;
            slotValue = rootCollectionDetails.claimedTokenTracker[slot];
            claimed = ((slotValue >> offset) & uint256(1)) == 0;
        }
        
        return (claimed, slot, offset, slotValue);
    }

    /// @dev Determines number of slots required to track minted tokens across the max supply
    function _getNumberOfTokenTrackerSlots(uint256 maxSupply_) internal pure returns (uint256 tokenTrackerSlotsRequired) {
        unchecked {
            // Add 1 because we are starting valid token id range at 1 instead of 0
            uint256 maxSupplyPlusOne = 1 + maxSupply_;
            tokenTrackerSlotsRequired = maxSupplyPlusOne / 256;
            if(maxSupplyPlusOne % 256 > 0) {
                ++tokenTrackerSlotsRequired;
            }
        }

        return tokenTrackerSlotsRequired;
    }

    /// @dev Validates that the length of two input arrays matched.
    /// Throws if the array lengths are mismatched.
    function _requireInputArrayLengthsMatch(uint256 inputArray1Length, uint256 inputArray2Length) internal pure {
        if(inputArray1Length != inputArray2Length) {
            revert InputArrayLengthMismatch();
        }
    }

    /// @dev Inheriting contracts must implement the token minting logic - inheriting contract should use safe mint, or something equivalent
    /// The minting function should throw if `to` is address(0) or `to` is a contract that does not implement IERC721Receiver.
    function _safeMintToken(address to, uint256 tokenId) internal virtual;

    /// @dev Safely gets a storage pointer to the details of a root collection.  Performs validation and throws if the value is not present in the mapping, preventing
    /// the possibility of overwriting an unexpected storage slot.
    ///
    /// Throws when the specified root collection address has not been explicitly set as a key in the mapping.
    function _getRootCollectionDetailsSafe(address rootCollectionAddress) private view returns (ClaimableRootCollection storage) {
        ClaimableRootCollection storage rootCollectionDetails = rootCollectionLookup[rootCollectionAddress];

        if(!rootCollectionDetails.isRootCollection) {
            revert InvalidRootCollectionAddress();
        }

        return rootCollectionDetails;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/InitializableOwnable.sol";


error ClaimsMustBeClosedToReopen();
error ClaimPeriodAlreadyInitialized();
error ClaimPeriodIsNotOpen();
error ClaimPeriodMustBeClosedInTheFuture();
error ClaimPeriodMustBeInitialized();

/**
 * @title ClaimPeriodController
 * @author Limit Break, Inc.
 * @notice In order to support multiple contracts with enforced claim periods, the claim period has been moved to this base contract.
 *
 */
abstract contract ClaimPeriodBase is InitializableOwnable {

    /// @dev True if claims have been initalized, false otherwise.
    bool private claimPeriodInitialized;

    /// @dev The timestamp when the claim period closes - when this value is zero and claims are open, the claim period is open indefinitely
    uint256 private claimPeriodClosingTimestamp;

    /// @dev Emitted when a claim period is scheduled to be closed.
    event ClaimPeriodClosing(uint256 claimPeriodClosingTimestamp);

    /// @dev Emitted when a claim period is scheduled to be opened.
    event ClaimPeriodOpened(uint256 claimPeriodClosingTimestamp);

    /// @dev Opens the claim period.  Claims can be closed with a custom amount of warning time using the closeClaims function.
    /// Accepts a claimPeriodClosingTimestamp_ timestamp which will open the period ending at that time (in seconds)
    /// NOTE: Use as high a window as possible to prevent gas wars for claiming
    /// For an unbounded claim window, pass in type(uint256).max
    function openClaims(uint256 claimPeriodClosingTimestamp_) external onlyOwner {
        if(claimPeriodClosingTimestamp_ <= block.timestamp) {
            revert ClaimPeriodMustBeClosedInTheFuture();
        }

        if(claimPeriodInitialized) {
            if(block.timestamp < claimPeriodClosingTimestamp) {
                revert ClaimsMustBeClosedToReopen();
            }
        } else {
            claimPeriodInitialized = true;
        }

        claimPeriodClosingTimestamp = claimPeriodClosingTimestamp_;

        emit ClaimPeriodOpened(claimPeriodClosingTimestamp_);
    }

    /// @dev Closes claims at a specified timestamp.
    ///
    /// Throws when the specified timestamp is not in the future.
    function closeClaims(uint256 claimPeriodClosingTimestamp_) external onlyOwner {
        _requireClaimsOpen();

        if(claimPeriodClosingTimestamp_ <= block.timestamp) {
            revert ClaimPeriodMustBeClosedInTheFuture();
        }

        claimPeriodClosingTimestamp = claimPeriodClosingTimestamp_;
        
        emit ClaimPeriodClosing(claimPeriodClosingTimestamp_);
    }

    /// @dev Returns the Claim Period Timestamp
    function getClaimPeriodClosingTimestamp() external view returns (uint256) {
        return claimPeriodClosingTimestamp;
    }

    /// @notice Returns true if the claim period has been opened, false otherwise
    function isClaimPeriodOpen() external view returns (bool) {
        return _isClaimPeriodOpen();
    }

    /// @dev Returns true if claim period is open, false otherwise.
    function _isClaimPeriodOpen() internal view returns (bool) {
        return claimPeriodInitialized && block.timestamp < claimPeriodClosingTimestamp;
    }

    /// @dev Validates that the claim period is open.
    /// Throws if claims are not open.
    function _requireClaimsOpen() internal view {
        if(!_isClaimPeriodOpen()) {
            revert ClaimPeriodIsNotOpen();
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../access/InitializableOwnable.sol";
import "../../initializable/IERC721Initializer.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error AlreadyInitializedERC721();

/**
 * @title InitializableERC721
 * @author Limit Break, Inc.
 * @notice Wraps OpenZeppelin ERC721 implementation and makes it compatible with EIP-1167.
 * @dev Because OpenZeppelin's `_name` and `_symbol` storage variables are private and inaccessible, 
 * this contract defines two new storage variables `_contractName` and `_contractSymbol` and returns them
 * from the `name()` and `symbol()` functions instead.
 */
abstract contract InitializableERC721 is InitializableOwnable, ERC721, IERC721Initializer {

    /// @notice Specifies whether or not the contract is initialized
    bool private initializedERC721;

    // Token name
    string internal _contractName;

    // Token symbol
    string internal _contractSymbol;

    /// @dev Initializes parameters of ERC721 tokens.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeERC721(string memory name_, string memory symbol_) public override onlyOwner {
        if(initializedERC721) {
            revert AlreadyInitializedERC721();
        }

        _contractName = name_;
        _contractSymbol = symbol_;

        initializedERC721 = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Initializer).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _contractName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _contractSymbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SequentialMintBase.sol";
import "./ClaimPeriodBase.sol";
import "../access/InitializableOwnable.sol";
import "../../initializable/IMerkleRootInitializer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AddressHasAlreadyClaimed();
error InvalidProof();
error MerkleRootAlreadyInitialized();
error MerkleRootHasNotBeenInitialized();
error MerkleRootCannotBeZero();
error MintedQuantityMustBeGreaterThanZero();

/**
 * @title MerkleWhitelistMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with merkle-proof based whitelist minting capabilities.
 * @dev Inheriting contracts must implement `_safeMintToken` and implement EIP-165 support as shown:
 *
 * function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
 *     return
 *     interfaceId == type(IMerkleRootInitializer).interfaceId ||
 *     super.supportsInterface(interfaceId);
 *  }
 *
 */
abstract contract MerkleWhitelistMint is InitializableOwnable, ClaimPeriodBase, SequentialMintBase, ReentrancyGuard, IMerkleRootInitializer {

    /// @dev This is the root ERC-721 contract from which claims can be made
    bytes32 private merkleRoot;

    /// @dev Mapping that tracks whether or not an address has claimed their whitelist mint
    mapping (address => bool) private whitelistClaimed;

    /// @dev Initializes the merkle root containing the whitelist.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the merkle root has already been initialized.
    /// Throws when the specified merkle root is zero.
    function initializeMerkleRoot(bytes32 merkleRoot_) public override onlyOwner {
        if(merkleRoot != bytes32(0)) {
            revert MerkleRootAlreadyInitialized();
        }

        if(merkleRoot_ == bytes32(0)) {
            revert MerkleRootCannotBeZero();
        }

        merkleRoot = merkleRoot_;
        _initializeNextTokenIdCounter();
    }

    /// @notice Mints the specified quantity to the calling address if the submitted merkle proof successfully verifies the reserved quantity for the caller in the whitelist.
    ///
    /// Throws when the claim period has not opened.
    /// Throws when the claim period has closed.
    /// Throws if a merkle root has not been set.
    /// Throws if the caller has already successfully claimed.
    /// Throws if the submitted merkle proof does not successfully verify the reserved quantity for the caller.
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof_) external nonReentrant {
        _requireClaimsOpen();

        bytes32 merkleRootCache = merkleRoot;

        if(merkleRootCache == bytes32(0)) {
            revert MerkleRootHasNotBeenInitialized();
        }

        if(whitelistClaimed[_msgSender()]) {
            revert AddressHasAlreadyClaimed();
        }

        if(!MerkleProof.verify(merkleProof_, merkleRootCache, keccak256(abi.encodePacked(_msgSender(), quantity)))) {
            revert InvalidProof();
        }

        whitelistClaimed[_msgSender()] = true;
        _mintBatch(_msgSender(), quantity);
    }

    /// @notice Returns the merkle root
    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    /// @notice Returns true if the account already claimed their whitelist mint, false otherwise
    function isWhitelistClaimed(address account) external view returns (bool) {
        return whitelistClaimed[account];
    }

    /// @dev Batch mints the specified quantity to the specified address.
    /// Throws if quantity is zero.
    /// Throws if `to` is a smart contract that does not implement IERC721 receiver.
    function _mintBatch(address to, uint256 quantity) private {

        if(quantity == 0) {
            revert MintedQuantityMustBeGreaterThanZero();
        }

        uint256 tokenIdToMint = getNextTokenId();
        unchecked {
            _advanceNextTokenIdCounter(quantity);

            for(uint256 i = 0; i < quantity; ++i) {
                _safeMintToken(to, tokenIdToMint + i);
            }
        }
    }

    /// @dev Inheriting contracts must implement the token minting logic - inheriting contract should use safe mint, or something equivalent
    /// The minting function should throw if `to` is address(0) or `to` is a contract that does not implement IERC721Receiver.
    function _safeMintToken(address to, uint256 tokenId) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/InitializableOwnable.sol";
import "../../initializable/IRootCollectionInitializer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title SequentialMintBase
 * @author Limit Break, Inc.
 * @dev In order to support multiple sequential mint mix-ins in a single contract, the token id counter has been moved to this based contract.
 */
abstract contract SequentialMintBase {

    /// @dev The next token id that will be minted - if zero, the next minted token id will be 1
    uint256 private nextTokenIdCounter;

    /// @dev Minting mixins must use this function to advance the next token id counter.
    function _initializeNextTokenIdCounter() internal {
        if(nextTokenIdCounter == 0) {
            nextTokenIdCounter = 1;
        }
    }

    /// @dev Minting mixins must use this function to advance the next token id counter.
    function _advanceNextTokenIdCounter(uint256 amount) internal {
        nextTokenIdCounter += amount;
    }

    /// @dev Returns the next token id counter value
    function getNextTokenId() public view returns (uint256) {
        return nextTokenIdCounter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SequentialMintBase.sol";
import "../access/InitializableOwnable.sol";
import "../../initializable/ISignedApprovalInitializer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error AddressAlreadyMinted();
error InvalidSignature();
error MaxQuantityMustBeGreaterThanZero();
error MintExceedsMaximumAmountBySignedApproval();
error SignedClaimsAreDecommissioned();
error SignerAlreadyInitialized();
error SignerCannotBeInitializedAsAddressZero();
error SignerIsAddressZero();


/**
* @title SignedApprovalMint
* @author Limit Break, Inc.
* @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with Signed Approval minting capabilities, allowing an approved signer to issue a limited amount of mints.
* @dev Inheriting contracts must implement `_mintToken` and implement EIP-165 support as shown:
*
* function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
*     return
*     interfaceId == type(ISignedApproverInitializer).interfaceId ||
*     super.supportsInterface(interfaceId);
*  }
*
*/
abstract contract SignedApprovalMint is InitializableOwnable, SequentialMintBase, ReentrancyGuard, EIP712, ISignedApprovalInitializer {

    /// @dev Returns true if signed claims have been decommissioned, false otherwise.
    bool private _signedClaimsDecommissioned;

    /// @dev The address of the signer for approved mints.
    address private _approvalSigner;

    /// @dev The maximum amount of mints done by the approval signer
    /// NOTE: This is an aggregate of all signers, updating signer will not reset or modify this amount.
    uint256 private _maxQuantityMintable;

    /// @dev The amount minted by all signers.
    /// NOTE: This is an aggregate of all signers, updating signer will not reset or modify this amount.
    uint256 private _mintedAmount;

    /// @dev Mapping of addresses who have already minted 
    mapping(address => bool) private addressMinted;

    /// @dev Emitted when signatures are decommissioned
    event SignedClaimsDecommissioned();

    /// @dev Emitted when a signer is updated
    event SignerUpdated(address oldSigner, address newSigner); 

    /// @notice Allows a user to claim/mint one or more tokens as approved by the approved signer
    ///
    /// Throws when a signature is invalid.
    /// Throws when the quantity provided does not match the quantity on the signature provided.
    /// Throws when the address has already claimed a token.
    /// Throws if safe mint receiver is not an EOA or a contract that can receive tokens.
    function claimSignedMint(bytes calldata signature, uint256 quantity) external nonReentrant {
        if (addressMinted[_msgSender()]) {
            revert AddressAlreadyMinted();
        }

        if (_approvalSigner == address(0)) { 
            revert SignerIsAddressZero();
        }

        _requireSignedClaimsActive();

        uint256 newTotal = _mintedAmount + quantity;
        if (newTotal > _maxQuantityMintable) {
            revert MintExceedsMaximumAmountBySignedApproval();
        }

        _mintedAmount = newTotal;

        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Approved(address wallet,uint256 quantity)"),
                    _msgSender(),
                    quantity
                )
            )
        );

        if (_approvalSigner != ECDSA.recover(hash, signature)) {
            revert InvalidSignature();
        }

        addressMinted[_msgSender()] = true;

        uint256 tokenIdToMint = getNextTokenId();
        unchecked {
            _advanceNextTokenIdCounter(quantity);

            for(uint256 i = 0; i < quantity; ++i) {
                _safeMintToken(_msgSender(), tokenIdToMint + i);
            }
        }
    }

    /// @notice Decommissions signed approvals
    /// This is a permanent decommissioning, once this is set, no further signatures can be claimed
    ///
    /// Throws if caller is not owner
    /// Throws if already decommissioned
    function decommissionSignedApprovals() external onlyOwner {
        _requireSignedClaimsActive();
        _signedClaimsDecommissioned = true;
        emit SignedClaimsDecommissioned();
    }

    /// @dev Initializes the signer address for signed approvals
    /// This cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the signer has already been initialized.
    /// Throws when the provided signer is address(0).
    /// Throws when maxQuantity = 0
    function initializeSigner(address signer, uint256 maxQuantity) public override onlyOwner {
        if(_approvalSigner != address(0)) {
            revert SignerAlreadyInitialized();
        }
        if(signer == address(0)) {
            revert SignerCannotBeInitializedAsAddressZero();
        }
        if(maxQuantity == 0) {
            revert MaxQuantityMustBeGreaterThanZero();
        }
        _initializeNextTokenIdCounter();
        _approvalSigner = signer;
        _maxQuantityMintable = maxQuantity;
    }

    /// @dev Allows signer to update the signer address
    /// This allows the signer to set new signer to address(0) to prevent future allowed mints
    /// NOTE: Setting signer to address(0) is irreversible - approvals will be disabled permanently and all outstanding signatures will be invalid.
    ///
    /// Throws when caller is not owner
    /// Throws when current signer is address(0)
    function setSigner(address newSigner) public onlyOwner {
        if(_signedClaimsDecommissioned) {
            revert SignedClaimsAreDecommissioned();
        }

        emit SignerUpdated(_approvalSigner, newSigner);
        _approvalSigner = newSigner;
    }

    /// @notice Returns true if the provided account has already minted, false otherwise
    function hasMintedBySignedApproval(address account) public view returns (bool) {
        return addressMinted[account];
    }

    /// @notice Returns the address of the approved signer
    function approvalSigner() public view returns (address) {
        return _approvalSigner;
    }

    /// @notice Returns the maximum amount mintable by approved signers
    function maxQuantityMintable() public view returns (uint256) {
        return _maxQuantityMintable;
    }

    /// @notice Returns the current amount minted by approved signers
    function mintedAmount() public view returns (uint256) {
        return _mintedAmount;
    }

    /// @notice Returns true if signed claims have been decommissioned, false otherwise
    function signedClaimsDecommissioned() public view returns (bool) {
        return _signedClaimsDecommissioned;
    }

    /// @dev Internal function used to revert if signed claims are decommissioned.
    function _requireSignedClaimsActive() internal view {
        if(_signedClaimsDecommissioned) {
            revert SignedClaimsAreDecommissioned();
        }
    }

    /// @dev Inheriting contracts must implement the token minting logic - inheriting contract should use safe mint, or something equivalent
    /// The minting function should throw if `to` is address(0) or `to` is a contract that does not implement IERC721Receiver.
    function _safeMintToken(address to, uint256 tokenId) internal virtual;
}