// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';


contract PureJsonAvif is ERC721Enumerable
{
	struct Card {
		string beast;
		string action;
		string rare;
	}

	mapping(string => string) internal store;

	mapping(uint256 => Card) private tokenToCard;
	uint256 private tokenIdCounter;

	constructor() ERC721('PureJsonAvif', 'PJA') {
		store['buffalo'] = 'data:image/avif;base64,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';
	}


	function mint(string calldata _beast, string calldata _action, string calldata _rare) external {
		Card memory card = Card(_beast, _action, _rare);
		unchecked {
			tokenIdCounter += 1;
		}
		uint256 tokenId = tokenIdCounter;
		tokenToCard[tokenId] = card;
		_safeMint(msg.sender, tokenId);
	}

	function tokenURI(uint256 tokenId) public view override returns(string memory) {
		_requireMinted(tokenId);

		Card memory card = tokenToCard[tokenId];
		return string.concat(
			'data:application/json,{"name":"PureJsonAvif","description":"practicing to return a not encoded json string (with an avif base64 encoded image) from the tokenURI method call","external_url":"https://austingriffith.com/portfolio/paintings/","image":"',
			store[card.beast],
			'","attributes":[{"trait_type":"Beast","value":"',
			card.beast,
			'"},{"trait_type":"Action","value":"',
			card.action,
			'"},{"trait_type":"Rare","value":"',
			card.rare,
			'"}]}'
		);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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