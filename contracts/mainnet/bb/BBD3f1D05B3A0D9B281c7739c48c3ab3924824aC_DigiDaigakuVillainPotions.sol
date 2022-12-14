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

import "./IMintablePotion.sol";
import "limit-break-contracts/contracts/adventures/AdventureNFT.sol";
import "limit-break-contracts/contracts/utils/tokens/SequentialRoleBasedMint.sol";

error BatchSizeMustBeGreaterThanOne();
error InputArrayLengthMismatch();
error UseOfMintEntrypointProhibittedUseMintPotionsBatch();

/**
 * @title DigiDaigakuVillainsPotions
 * @author Limit Break, Inc.
 * @notice An Adventure ERC-721 token that upgrades villains.
 */
contract DigiDaigakuVillainPotions is AdventureNFT, SequentialRoleBasedMint, IMintablePotion {

    uint256 private constant ENTRYPOINT_MINT = 1;
    uint256 private constant ENTRYPOINT_MINT_POTIONS_BATCH = 2;

    uint256 private mintFunctionEntrypoint;

    /// @dev Emitted when a potion is minted
    event MintPotion(address indexed to, uint256 indexed potionId, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId);

    constructor(uint256 maxSupply_, address royaltyReceiver_, uint96 royaltyFeeNumerator_) ERC721("", "") {
        initializeERC721("DigiDaigakuVillainPotions", "DIDVP");
        initializeURI("https://digidaigaku.com/villainpotions/metadata/", ".json");
        initializeAdventureERC721(10);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeMaxSupply(maxSupply_);
        
        mintFunctionEntrypoint = ENTRYPOINT_MINT;
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return
        interfaceId == type(IMaxSupplyInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /// @notice Mints multiple potions crafted with the specified dark spirit and dark hero spirit tokens.
    ///
    /// Throws if `to` address is zero address.
    /// Throws if the quantity is zero.
    /// Throws if the caller is not a whitelisted minter.
    /// Throws if minting would exceed the max supply.
    /// Throws if token id array lengths don't match.
    ///
    /// Postconditions:
    /// ---------------
    /// `quantity` potions have been minted to the specified `to` address, where `quantity` is the length of the token id arrays.
    /// `quantity` MintPotion events has been emitted, where `quantity` is the length of the token id arrays.
    function mintPotionsBatch(address to, uint256[] calldata darkSpiritTokenIds, uint256[] calldata darkHeroSpiritTokenIds) external override {
        if(darkHeroSpiritTokenIds.length != darkSpiritTokenIds.length) {
            revert InputArrayLengthMismatch();
        }

        mintFunctionEntrypoint = ENTRYPOINT_MINT_POTIONS_BATCH;
        (uint256 firstPotionId,) = mint(to, darkSpiritTokenIds.length);
        mintFunctionEntrypoint = ENTRYPOINT_MINT;
        
        unchecked {
            for(uint256 i = 0; i < darkSpiritTokenIds.length; ++i) {
                emit MintPotion(to, firstPotionId + i, darkSpiritTokenIds[i], darkHeroSpiritTokenIds[i]);
            }
        }
    }

    /// @notice Direct use of the mint function is prohibitted in this contract.
    /// Throws if not called from mintPotionsBatch.
    /// Otherwise, functions according to the base contract mint implementation.
    function mint(address to, uint256 quantity) public override returns (uint256 firstTokenId, uint256 lastTokenId) {
        if(mintFunctionEntrypoint == ENTRYPOINT_MINT) {
            revert UseOfMintEntrypointProhibittedUseMintPotionsBatch();
        }

        return super.mint(to, quantity);
    }

    /// @dev Mints a token
    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required interface of mintable potion contracts.
 */
interface IMintablePotion {

    /**
     * @notice Mints multiple potions crafted with the specified dark spirit token ids and dark hero spirit token ids
     */
    function mintPotionsBatch(address to, uint256[] calldata darkSpiritTokenIds, uint256[] calldata darkHeroSpiritTokenIds) external;
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

    /// @notice Specifies whether or not the contract is initialized
    bool private initializedAdventureERC721;

    /// @dev The most simultaneous quests the token may participate in at a time
    uint256 private _maxSimultaneousQuests;

    /// @dev Maps each token id to the number of blocking quests it is currently entered into
    mapping (uint256 => uint256) private blockingQuestCounts;

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
        _transfer(from, to, tokenId);
    }

    /// @notice Safe transfers a player's token if they have opted into an authorized, whitelisted adventure.
    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _safeTransfer(from, to, tokenId, "");
    }

    /// @notice Burns a player's token if they have opted into an authorized, whitelisted adventure.
    function adventureBurn(uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _burn(tokenId);
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

    /// @dev The maximum allowable royalty fee is 10%
    uint96 private constant MAX_ROYALTY_FEE_NUMERATOR = 1000;

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
 * @title IMaxSupplyInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include a maximum supply.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IMaxSupplyInitializer is IERC165 {

    /**
     * @notice Initializes max supply parameters
     */
    function initializeMaxSupply(uint256 maxSupply_) external;
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

import "../access/InitializableOwnable.sol";
import "../../initializable/IMaxSupplyInitializer.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CannotMintToZeroAddress();
error MaxSupplyAlreadyInitialized();
error MaxSupplyCannotBeSetToMaxUint256();
error MaxSupplyCannotBeSetToZero();
error MaxSupplyExceeded(uint256 supplyAfterMint, uint256 maxSupply);
error MintedQuantityMustBeGreaterThanZero();
error MinterAlreadyWhitelisted();
error MinterNotWhitelisted();

/**
 * @title SequentialRoleBasedMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with sequential role-based minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken` and implement EIP-165 support as shown:
 *
 * function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
 *     return
 *     interfaceId == type(IMaxSupplyInitializer).interfaceId ||
 *     super.supportsInterface(interfaceId);
 *  }
 *
 */
abstract contract SequentialRoleBasedMint is InitializableOwnable, IMaxSupplyInitializer {

    /// @dev The next token id that will be minted - if zero, the next minted token id will be 1
    uint256 public nextTokenId;

    /// @dev The maximum token supply
    uint256 private _maxSupply;

    /// @dev Whitelisted minter mapping
    mapping (address => bool) public whitelistedMinters;

    /// @dev Emitted when the minter whitelist is updated
    event MinterWhitelistUpdated(address indexed minter, bool indexed whitelisted);

    /// @dev Initializes parameters of tokens with maximum supplies.
    /// This cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    /// Throws if maxSupply has already been set to a non-zero value.
    /// Throws if specified maxSupply_ is zero.
    /// Throws if specified maxSupply_ is set to max uint256.
    function initializeMaxSupply(uint256 maxSupply_) public override onlyOwner {
        if(_maxSupply > 0) {
            revert MaxSupplyAlreadyInitialized();
        }

        if(maxSupply_ == 0) {
            revert MaxSupplyCannotBeSetToZero();
        }

        if(maxSupply_ == type(uint256).max) {
            revert MaxSupplyCannotBeSetToMaxUint256();
        }

        _maxSupply = maxSupply_;
    }

    /// @notice Whitelists a minter
    function whitelistMinter(address minter) external onlyOwner {
        _requireMinterIsNotWhitelisted(minter);
        whitelistedMinters[minter] = true;
        emit MinterWhitelistUpdated(minter, true);
    }

    /// @notice Removes a minter from the whitelist
    function unwhitelistMinter(address minter) external onlyOwner {
        _requireMinterIsWhitelisted(minter);
        delete whitelistedMinters[minter];
        emit MinterWhitelistUpdated(minter, false);
    }

    function mint(address to, uint256 quantity) public virtual returns (uint256 firstTokenId, uint256 lastTokenId) {
        if(to == address(0)) {
            revert CannotMintToZeroAddress();
        }

        if(quantity == 0) {
            revert MintedQuantityMustBeGreaterThanZero();
        }

        _requireMinterIsWhitelisted(_msgSender());

        uint256 tokenIdToMint = nextTokenId;
        if(tokenIdToMint == 0) {
            tokenIdToMint = 1;
        }

        firstTokenId = tokenIdToMint;
        
        uint256 supplyAfterMint = tokenIdToMint + quantity - 1;
        uint256 maxSupply_ = _maxSupply;
        if(supplyAfterMint > maxSupply_) {
            revert MaxSupplyExceeded(supplyAfterMint, maxSupply_);
        }

        unchecked {
            nextTokenId = tokenIdToMint + quantity;

            for(uint256 i = 0; i < quantity; ++i) {
                _mintToken(to, tokenIdToMint + i);
            }
        }

        lastTokenId = supplyAfterMint;

        return (firstTokenId, lastTokenId);
    }

    /// @notice Returns the maximum mintable supply
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /// @dev Inheriting contracts must implement the token minting logic
    function _mintToken(address to, uint256 tokenId) internal virtual;

    function _requireMinterIsWhitelisted(address minter) private view {
        if(!whitelistedMinters[minter]) {
            revert MinterNotWhitelisted();
        }
    }

    function _requireMinterIsNotWhitelisted(address minter) private view {
        if(whitelistedMinters[minter]) {
            revert MinterAlreadyWhitelisted();
        }
    }
}