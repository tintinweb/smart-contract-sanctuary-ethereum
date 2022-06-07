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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
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
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
//import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
    uint256 public totalUnveiled = 0;
    uint256 public constant maximumPieces = 1;

    event Unveiled(uint256 tokenId, address receiver);

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    function remaining() public view returns (uint256 _remaining) {
        if (maximumPieces > totalUnveiled) {
          return maximumPieces - totalUnveiled;
        } else {
          return 0;
        }
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) internal {
        require(remaining()>0, "Supply limit reached");
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
        totalUnveiled += 1;
        emit Unveiled(newTokenId, _to);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function baseTokenURI() virtual public pure returns (string memory);

    //function tokenURI(uint256 _tokenId) virtual public view returns (string memory);

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

     /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Yazo
/// @author: Yazo
//  https://yazo.fun

import "./ERC721Tradable.sol";
import "./strings.sol";
import "./base64.sol";
contract SolarSystem is ERC721Tradable {
    using strings for *;
    bool private _lockData = false;
    uint constant SECONDS = 24 * 60 * 60;
   // string private MASK = 'stop-color="#,A|radialGradient,B|gradientTransform="translate(,C|fill="url(#,D|transform="translate(,E|stroke-width="0.5669",F|spreadMethod="pad",G|repeatCount="indefinite"/>,H|keyTimes="0;1" calcMode="linear",I|<ellipse rx=",4|stop id=",L|offset=",M|animateMotion keyPoints="1;0",N|stroke="#808080",O|path=",P|animation-delay:,Q|transform,R|<circle,S|000,T|linear infinite reverse,U|scale(,V|animation:,Z|mask,X|<g id=",Y|</g>,W|s" begin=",2|fill=",0|stop-color="rgba(,1';
    string private HTML_CODE = '<svg xmlns="http://www.w3.org/2|T|/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1920 1920" shape-rendering="geometricPrecision"><style>svg{background:black;}@keyframes pt { 0% {|R|: |V|0.8)}25% {|R|: |V|0.6)}50% {|R|: |V|0.8)}75% {|R|: |V|1)}100% {|R|: |V|0.8)}}#my {|Z| pt 7603200s |U|; |Q|-$MERCURYs}#vy {|Z| pt 1944|T|0s |U|; |Q|-$VENUSs}#ey {|Z| pt 31536|T|s |U|; |Q|-$EARTHs;}#may {|Z| pt 59356800s |U|; |Q|-$MARSs;}#j_2y {|Z| pt 374371200s |U|; |Q|-$JUPITERs;}#s_2y {|Z| pt 929577600s |U|; |Q|-$SATURNs;}#ny {|Z| pt 2144448|T|s |U|; |Q|-$NEPTUNEs;}#uy {|Z| pt 2144448|T|s |U|; |Q|-$URANUSs;}#sy {|Z| pt 929577600s |U|; |Q|-$SATURNs;}#jy {|Z| pt 374371200s |U|; |Q|-$JUPITERs;}#j {|Z| j2 374371200s |U|; |Q|-$JUPITERs;}@keyframes j2 { 0% {opacity: 1}40% {opacity: 1}40.01% {opacity: 0}100% {opacity: 0}}#ma_2y {|Z| pt 59356800s |U|; |Q|-$MARSs;}#ma_2 {|Z| j2 59356800s |U|; |Q|-$MARSs;}</style><defs><rect id="rg6" width="354" height="190" rx="0" ry="0"/><rect id="rg7" width="85" height="42" rx="0" ry="0"/><|B| id="rg8-f" cx="0" cy="0" r="0.5" |G| |C|0.5 0.5)"><|L|rg8x0" |M|0%" |A|ffc200"/><|L|rg8x1" |M|12.79%" |A|ffbd00"/><|L|rg8x2" |M|26.9%" |A|ffb|T|"/><|L|rg8x3" |M|41.59%" |A|ff9a00"/><|L|rg8x4" |M|54.3%" |A|ff8100"/><|L|rg8x5" |M|59.63%" |A|ff7d00"/><|L|rg8x6" |M|65.12%" |A|ff7100"/><|L|rg8x7" |M|70.67%" |A|ff5c00"/><|L|rg8x8" |M|76.28%" |A|ff3f00"/><|L|rg8x9" |M|81.86%" |A|ff1a00"/><|L|rg8x10" |M|85.28%" |A|f00"/><|L|rg8x11" |M|88.39%" |A|b7|T|0"/><|L|rg8x12" |M|91.51%" |A|76|T|0"/><|L|rg8x13" |M|94.33%" |A|43|T|0"/><|L|rg8x14" |M|96.77%" |A|1f|T|0"/><|L|rg8x15" |M|98.74%" |A|08|T|0"/><|L|rg8x16" |M|100%" |A||T|"/></|B|><|B| id="m-f" cx="0" cy="0" r="0.643805" |G| |C|0.374494 0.360573)"><|L|mx0" |M|0%" |A|e7d6c3"/><|L|mx1" |M|15.35%" |A|e5d3be"/><|L|mx2" |M|33.28%" |A|dfc9b0"/><|L|mx3" |M|52.49%" |A|d6b999"/><|L|mx4" |M|72.5%" |A|c9a378"/><|L|mx5" |M|75.7%" |A|c79f72"/><|L|mx6" |M|80.26%" |A|a78560"/><|L|mx7" |M|90.18%" |A|564531"/><|L|mx8" |M|100%" |A||T|"/></|B|><|B| id="v-f" cx="0" cy="0" r="0.592685" |G| |C|0.441241 0.422507)"><|L|vx0" |M|0%" |A|f8cfdf"/><|L|vx1" |M|18.43%" |A|f7cadc"/><|L|vx2" |M|39.95%" |A|f5bcd2"/><|L|vx3" |M|62.93%" |A|f2a5c3"/><|L|vx4" |M|77.42%" |A|ef92b6"/><|L|vx5" |M|98.39%" |A|110a0d"/><|L|vx6" |M|99.93%" |A||T|"/></|B|><|B| id="e-f" cx="0" cy="0" r="0.646556" |G| |C|0.416105 0.388832)"><|L|ex0" |M|0.658138%" |A|13a737"/><|L|ex1" |M|10.13%" |A|14a63c"/><|L|ex2" |M|21.2%" |A|16a44a"/><|L|ex3" |M|33.08%" |A|19a062"/><|L|ex4" |M|45.51%" |A|1d9b82"/><|L|ex5" |M|58.4%" |A|2394ad"/><|L|ex6" |M|71.46%" |A|2a8ce0"/><|L|ex7" |M|76.89%" |A|2d88f7"/><|L|ex8" |M|100%" |A||T|"/></|B|><|B| id="ma-f" cx="0" cy="0" r="0.594128" |G| |C|0.434342 0.412538)"><|L|max0" |M|0%" |A|ff6822"/><|L|max1" |M|17.73%" |A|fb6023"/><|L|max2" |M|45.53%" |A|ee4925"/><|L|max3" |M|79.75%" |A|da2529"/><|L|max4" |M|81.64%" |A|d92329"/><|L|max5" |M|100%" |A||T|"/></|B|><|B| id="j_2-f" cx="0" cy="0" r="0.64023" |G| |C|0.424619 0.420335)"><|L|j_2x0" |M|0%" |A|fce3c5"/><|L|j_2x1" |M|16.38%" |A|fce0bd"/><|L|j_2x2" |M|42.06%" |A|fbd6a7"/><|L|j_2x3" |M|73.67%" |A|f9c783"/><|L|j_2x4" |M|79.59%" |A|f9c47b"/><|L|j_2x5" |M|82.82%" |A|bc945d"/><|L|j_2x6" |M|86.18%" |A|836741"/><|L|j_2x7" |M|89.45%" |A|54422a"/><|L|j_2x8" |M|92.55%" |A|302518"/><|L|j_2x9" |M|95.42%" |A|15110b"/><|L|j_2x10" |M|97.99%" |A|060403"/><|L|j_2x11" |M|100%" |A||T|"/></|B|><|B| id="rg64-f" cx="0" cy="0" r="0.624269" |G| |C|0.447805 0.438193)"><|L|rg64x0" |M|0%" |A|ffefad"/><|L|rg64x1" |M|16.53%" |A|ffeea5"/><|L|rg64x2" |M|42.43%" |A|ffe98e"/><|L|rg64x3" |M|74.33%" |A|ffe26a"/><|L|rg64x4" |M|75.19%" |A|ffe269"/><|L|rg64x5" |M|79.9%" |A|bfa94f"/><|L|rg64x6" |M|85.34%" |A|7c6e33"/><|L|rg64x7" |M|90.27%" |A|463e1d"/><|L|rg64x8" |M|94.5%" |A|201c0d"/><|L|rg64x9" |M|97.89%" |A|090804"/><|L|rg64x10" |M|100%" |A||T|"/></|B|><|B| id="rg68-f" cx="0" cy="0" r="0.624269" |G| gradient|R|="matrix(1 0 0 0.998043 0.447805 0.438193)"><|L|rg68x0" |M|0%" |A|ffefad"/><|L|rg68x1" |M|16.53%" |A|ffeea5"/><|L|rg68x2" |M|42.43%" |A|ffe98e"/><|L|rg68x3" |M|74.33%" |A|ffe26a"/><|L|rg68x4" |M|75.19%" |A|ffe269"/><|L|rg68x5" |M|79.9%" |A|bfa94f"/><|L|rg68x6" |M|85.34%" |A|7c6e33"/><|L|rg68x7" |M|90.27%" |A|463e1d"/><|L|rg68x8" |M|94.5%" |A|201c0d"/><|L|rg68x9" |M|97.89%" |A|090804"/><|L|rg68x10" |M|100%" |A||T|"/></|B|><|B| id="n-f" cx="0" cy="0" r="0.624949" |G| |C|0.408083 0.379986)"><|L|nx0" |M|0.514633%" |A|7c7cb6"/><|L|nx1" |M|20.07%" |A|7474b1"/><|L|nx2" |M|50.72%" |A|5e5ea4"/><|L|nx3" |M|83.37%" |A|3f3f93"/><|L|nx4" |M|100%" |A||T|"/></|B|><|B| id="u-f" cx="0" cy="0" r="0.605597" |G| |C|0.448986 0.421851)"><|L|ux0" |M|0.694444%" |A|caefee"/><|L|ux1" |M|18.11%" |A|c2edeb"/><|L|ux2" |M|45.4%" |A|abe6e4"/><|L|ux3" |M|79%" |A|87dbd8"/><|L|ux4" |M|79.83%" |A|86dbd8"/><|L|ux5" |M|85.39%" |A|58908e"/><|L|ux6" |M|90.48%" |A|325251"/><|L|ux7" |M|94.76%" |A|172625"/><|L|ux8" |M|98.07%" |A|060a0a"/><|L|ux9" |M|100%" |A||T|"/></|B|><|B| id="rg-f" cx="0" cy="0" r="0.624269" |G| |C|0.447805 0.438193)"><|L|rgx0" |M|0%" |A|ffefad"/><|L|rgx1" |M|16.53%" |A|ffeea5"/><|L|rgx2" |M|42.43%" |A|ffe98e"/><|L|rgx3" |M|74.33%" |A|ffe26a"/><|L|rgx4" |M|75.19%" |A|ffe269"/><|L|rgx5" |M|79.9%" |A|bfa94f"/><|L|rgx6" |M|85.34%" |A|7c6e33"/><|L|rgx7" |M|90.27%" |A|463e1d"/><|L|rgx8" |M|94.5%" |A|201c0d"/><|L|rgx9" |M|97.89%" |A|090804"/><|L|rgx10" |M|100%" |A||T|"/></|B|><|B| id="rg2-f" cx="0" cy="0" r="0.624269" |G| gradient|R|="matrix(1 0 0 0.998043 0.447805 0.438193)"><|L|rg2x0" |M|0%" |A|ffefad"/><|L|rg2x1" |M|16.53%" |A|ffeea5"/><|L|rg2x2" |M|42.43%" |A|ffe98e"/><|L|rg2x3" |M|74.33%" |A|ffe26a"/><|L|rg2x4" |M|75.19%" |A|ffe269"/><|L|rg2x5" |M|79.9%" |A|bfa94f"/><|L|rg2x6" |M|85.34%" |A|7c6e33"/><|L|rg2x7" |M|90.27%" |A|463e1d"/><|L|rg2x8" |M|94.5%" |A|201c0d"/><|L|rg2x9" |M|97.89%" |A|090804"/><|L|rg2x10" |M|100%" |A||T|"/></|B|><|B| id="j-f" cx="0" cy="0" r="0.64023" |G| |C|0.424619 0.420335)"><|L|jx0" |M|0%" |A|fce3c5"/><|L|jx1" |M|16.38%" |A|fce0bd"/><|L|jx2" |M|42.06%" |A|fbd6a7"/><|L|jx3" |M|73.67%" |A|f9c783"/><|L|jx4" |M|79.59%" |A|f9c47b"/><|L|jx5" |M|82.82%" |A|bc945d"/><|L|jx6" |M|86.18%" |A|836741"/><|L|jx7" |M|89.45%" |A|54422a"/><|L|jx8" |M|92.55%" |A|302518"/><|L|jx9" |M|95.42%" |A|15110b"/><|L|jx10" |M|97.99%" |A|060403"/><|L|jx11" |M|100%" |A||T|"/></|B|><|B| id="ma_2-f" cx="0" cy="0" r="0.594128" |G| |C|0.434342 0.412538)"><|L|ma_2x0" |M|0%" |A|ff6822"/><|L|ma_2x1" |M|17.73%" |A|fb6023"/><|L|ma_2x2" |M|45.53%" |A|ee4925"/><|L|ma_2x3" |M|79.75%" |A|da2529"/><|L|ma_2x4" |M|81.64%" |A|d92329"/><|L|ma_2x5" |M|100%" |A||T|"/></|B|><|B| id="rg3-f" cx="0" cy="0" r="0.500915" |G| gradient|R|="matrix(0.998174 0 0 1 0.5 0.5)"><|L|rg3x0" |M|0%" |A|ffc200"/><|L|rg3x1" |M|12.79%" |A|ffbd00"/><|L|rg3x2" |M|26.9%" |A|ffb|T|"/><|L|rg3x3" |M|41.59%" |A|ff9a00"/><|L|rg3x4" |M|54.3%" |A|ff8100"/><|L|rg3x5" |M|59.63%" |A|ff7d00"/><|L|rg3x6" |M|65.12%" |A|ff7100"/><|L|rg3x7" |M|70.67%" |A|ff5c00"/><|L|rg3x8" |M|76.28%" |A|ff3f00"/><|L|rg3x9" |M|81.86%" |A|ff1a00"/><|L|rg3x10" |M|85.28%" |A|f00"/><|L|rg3x11" |M|88.39%" |1|183,0,0,0.47)"/><|L|rg3x12" |M|91.51%" |1|118,0,0,0.46)"/><|L|rg3x13" |M|94%" |1|67,0,0,0)"/><|L|rg3x14" |M|97%" |1|31,0,0,0)"/><|L|rg3x15" |M|98.74%" |1|8,0,0,0)"/><|L|rg3x16" |M|100%" |1|0,0,0,0)"/></|B|></defs><g><g><g><rect width="1920" height="1920" rx="0" ry="0"/>|W|<g |E|36 583.852985)">|S| r="153" |E|923 275)" |D|rg8-f)"/>|4|237" ry="98.5" |E|923 275.5)" |0|none" |O| |F|/>|4|326.5" ry="135.5" |E|923.5 287.5)" |0|none" |O| |F|/>|4|412" ry="171" |E|923 296)" |0|none" |O| |F|/>|4|502.5" ry="208.5" |E|923.5 308.5)" |0|none" |O| |F|/>|4|597" ry="247.5" |E|923 321.5)" |0|none" |O| |F|/>|4|708.5" ry="294" |E|923.5 344)" |0|none" |O| |F|/>|4|819.5" ry="340" |E|922.5 363)" |0|none" |O| |F|/>|4|923.5" ry="383" |E|923.5 383)" |0|none" |O| |F|/>|Y|m_to"><|N| |I| |P|M686,275.5C695.5,190.682418,876.735172,177,923.098,177C995.520242,177,1153.078191,199.796028,1160,275.5C1160.78828,328.871632,1042.196346,378.197017,922.5,374C821.567753,375.852786,688.752424,339.512965,686,275.5" dur="7603200|2|-$MERCURY" |H||Y|my" |R|="|V|0.8)">|S| r="9.5" |E|0,0)" |D|m-f)"/>|W||W||Y|v_to"><|N| |I| |P|M597,287.5C594.69812,210.500722,766.673452,147.598129,923.5,152C1041.331639,152,1245.102651,189.118302,1250,287.5C1251.288173,369.182006,1085.844724,423.553884,922.5,423C783.155745,423,607.081764,383.5,597,287.5" dur="1944|T|0|2|-$VENUSs" |H||Y|vy" |R|="|V|0.8)">|S| r="16.5" |E|0,0)" |D|v-f)"/>|W||W||Y|e_to"><|N| |I| |P|M511,296C503.109551,209.699813,686,125,922.5,122.073C1182.741756,132.893448,1341.929438,215.309766,1335,296C1340.290831,373.006854,1174.149765,468.311046,923.5,467C704.049721,467,512.308044,390.877469,511,296" dur="31536|T||2|-$EARTHs" |H||Y|ey" |R|="|V|0.8)">|S| r="16.5" |E|0,0)" |D|e-f)"/>|W||W||Y|ma_to"><|N| |I| |P|M421,308.5C422.338761,190.738633,648.125662,99.615581,922.5,100C1153.605104,97.068532,1430.798726,184.837256,1426,308C1429.109025,440.82037,1147.187956,522.412707,922.5,517C667.657138,521.795949,417.299429,421.538393,421,309.5" dur="59356800|2|-$MARSs" |H||Y|may" |R|="|V|0.8)">|S| r="13.5" |E|0,0)" |D|ma-f)"/>|W||W||Y|j_2_to"><|N| |I| |P|M326,321.5C338.729096,154.197491,675.861149,69.582133,923.5,74C1076,74,1499.998503,122.073,1520,321.5C1520.231902,479.917026,1185.91972,575.56143,922.5,569C624.125234,579.590297,317.573179,459.969431,326,321.5" dur="374371200|2|-$JUPITERs" |H||Y|j_2y" |R|="|V|0.8)">|S| r="40" |E|0,0)" |D|j_2-f)"/>|W||W||Y|s_2_to"><|N| |I| |P|M214.570538,344C190.462117,202.753146,556.266853,40.173264,922.5,54.147015C1249.444555,43.434056,1631.454971,170.835995,1632,344C1627.293153,537.358396,1227.337372,644.608484,922.5,638C433.663648,630.718834,207.516889,463.935385,215,344" dur="929577600|2|-$SATURNs" |H||Y|s_2y" |R|="|V|0.8)"><g |E|-247.5,-246.758301)">|S| r="34" |E|248 247)" |D|rg64-f)"/><path d="M247.5,231c-33.391346,0-60.5,6.92803-60.5,15.5s27.108654,15.5,60.5,15.5s60.5-6.92803,60.5-15.5-27.108654-15.5-60.5-15.5Zm0,25.598485c-21.756731,0-39.325-4.462121-39.325-10.098485s17.568269-10.098485,39.325-10.098485s39.325,4.462121,39.325,10.098485-17.568269,10.098485-39.325,10.098485Z" |0|#d8ae66"/><g |E|203 204)"><g |X|="url(#rg69)">|4|34" ry="34.0667" |E|44.8288 42.5833)" |D|rg68-f)"/><|X| id="rg69" |X|-type="luminance"><use xlink:href="#rg7" |0|#fff"/></|X|>|W||W||W||W||W||Y|n_to"><|N| |I| |P|M0,383.5C15.420054,121.424755,543.648307,1.640704,922.374868,0C1436.98444,0,1851.297965,175.396001,1847,383C1835.380223,627.36293,1326.045739,780.53835,922.5,766C481.16655,780.911326,-7.667502,605.394609,0,383" dur="2144448|T||2|-$NEPTUNEs" |H||Y|ny" |R|="|V|0.8)">|S| r="20.5" |E|0,0)" |D|n-f)"/>|W||W||Y|u_to"><|N| |I| |P|M103,363C89.559814,195.905938,467.885708,21.572957,922.374868,23C1366.102465,22.699244,1742,177,1742,363C1740.235509,594.880932,1265.846672,699.742095,923.5,703C563.336662,714.541593,108.547526,580.04011,103,362.5" dur="2144448|T||2|-$URANUSs" |H||Y|uy" |R|="|V|1)">|S| r="20.5" |E|0,0)" |D|u-f)"/>|W||W||Y|s_to"><|N| |I| |P|M214.570538,344C190.462117,202.753146,556.266853,40.173264,922.5,54.147015C1249.444555,43.434056,1631.454971,170.835995,1632,344C1627.293153,537.358396,1227.337372,644.608484,922.5,638C433.663648,630.718834,207.516889,463.935385,215,344" dur="929577600|2|-$SATURNs" |H||Y|sy" |R|="|V|0.8)"><g |E|-247.5,-246.758301)">|S| r="34" |E|248 247)" |D|rg-f)"/><path d="M247.5,231c-33.391346,0-60.5,6.92803-60.5,15.5s27.108654,15.5,60.5,15.5s60.5-6.92803,60.5-15.5-27.108654-15.5-60.5-15.5Zm0,25.598485c-21.756731,0-39.325-4.462121-39.325-10.098485s17.568269-10.098485,39.325-10.098485s39.325,4.462121,39.325,10.098485-17.568269,10.098485-39.325,10.098485Z" |0|#d8ae66"/><g |E|203 204)"><g |X|="url(#rg4)">|4|34" ry="34.0667" |E|44.8288 42.5833)" |D|rg2-f)"/><|X| id="rg4" |X|-type="luminance"><use xlink:href="#rg7" |0|#fff"/></|X|>|W||W||W||W||W||Y|j_to"><|N| |I| |P|M326,321.5C338.729096,154.197491,675.861149,69.582133,923.5,74C1076,74,1499.998503,122.073,1520,321.5C1520.231902,479.917026,1185.91972,575.56143,922.5,569C624.125234,579.590297,317.573179,459.969431,326,321.5" dur="374371200|2|-$JUPITERs" |H||Y|jy" |R|="|V|0.8)">|S| id="j" r="40" |E|0,0)" |D|j-f)"/>|W||W||Y|ma_2_to"><|N| |I| |P|M421,308.5C422.338761,190.738633,648.125662,99.615581,922.5,100C1153.605104,97.068532,1430.798726,184.837256,1426,308C1429.109025,440.82037,1147.187956,522.412707,922.5,517C667.657138,521.795949,417.299429,421.538393,421,309.5" dur="59356800|2|-$MARSs" |H||Y|ma_2y" |R|="|V|0.8)">|S| id="ma_2" r="13.5" |E|0,0)" |D|ma_2-f)"/>|W||W|<g |E|749 85)"><g |X|="url(#rg5)">|4|153.207" ry="152.927" |E|174.098 190)" |D|rg3-f)"/><|X| id="rg5" |X|-type="luminance"><use xlink:href="#rg6" |0|#fff"/></|X|>|W||W||W||W||W|</svg>';
    //string constant HTML_CODE = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1920 1920" shape-rendering="geometricPrecision"><style>svg{background:black;}@keyframes pt { 0% {transform: scale(0.8)}25% {transform: scale(0.6)}50% {transform: scale(0.8)}75% {transform: scale(1)}100% {transform: scale(0.8)}}#my {animation: pt 7603200s linear infinite reverse; animation-delay:-$MERCURYs}#vy {animation: pt 19440000s linear infinite reverse; animation-delay:-$VENUSs}#ey {animation: pt 31536000s linear infinite reverse; animation-delay:-$EARTHs;}#may {animation: pt 59356800s linear infinite reverse; animation-delay:-$MARSs;}#j_2y {animation: pt 374371200s linear infinite reverse; animation-delay:-$JUPITERs;}#s_2y {animation: pt 929577600s linear infinite reverse; animation-delay:-$SATURNs;}#ny {animation: pt 2144448000s linear infinite reverse; animation-delay:-$NEPTUNEs;}#uy {animation: pt 2144448000s linear infinite reverse; animation-delay:-$URANUSs;}#sy {animation: pt 929577600s linear infinite reverse; animation-delay:-$SATURNs;}#jy {animation: pt 374371200s linear infinite reverse; animation-delay:-$JUPITERs;}#j {animation: j2 374371200s linear infinite reverse; animation-delay:-$JUPITERs;}@keyframes j2 { 0% {opacity: 1}40% {opacity: 1}40.01% {opacity: 0}100% {opacity: 0}}#ma_2y {animation: pt 59356800s linear infinite reverse; animation-delay:-$MARSs;}#ma_2 {animation: j2 59356800s linear infinite reverse; animation-delay:-$MARSs;}</style><defs><rect id="rg6" width="354" height="190" rx="0" ry="0"/><rect id="rg7" width="85" height="42" rx="0" ry="0"/><radialGradient id="rg8-f" cx="0" cy="0" r="0.5" spreadMethod="pad" gradientTransform="translate(0.5 0.5)"><stop id="rg8x0" offset="0%" stop-color="#ffc200"/><stop id="rg8x1" offset="12.79%" stop-color="#ffbd00"/><stop id="rg8x2" offset="26.9%" stop-color="#ffb000"/><stop id="rg8x3" offset="41.59%" stop-color="#ff9a00"/><stop id="rg8x4" offset="54.3%" stop-color="#ff8100"/><stop id="rg8x5" offset="59.63%" stop-color="#ff7d00"/><stop id="rg8x6" offset="65.12%" stop-color="#ff7100"/><stop id="rg8x7" offset="70.67%" stop-color="#ff5c00"/><stop id="rg8x8" offset="76.28%" stop-color="#ff3f00"/><stop id="rg8x9" offset="81.86%" stop-color="#ff1a00"/><stop id="rg8x10" offset="85.28%" stop-color="#f00"/><stop id="rg8x11" offset="88.39%" stop-color="#b70000"/><stop id="rg8x12" offset="91.51%" stop-color="#760000"/><stop id="rg8x13" offset="94.33%" stop-color="#430000"/><stop id="rg8x14" offset="96.77%" stop-color="#1f0000"/><stop id="rg8x15" offset="98.74%" stop-color="#080000"/><stop id="rg8x16" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="m-f" cx="0" cy="0" r="0.643805" spreadMethod="pad" gradientTransform="translate(0.374494 0.360573)"><stop id="mx0" offset="0%" stop-color="#e7d6c3"/><stop id="mx1" offset="15.35%" stop-color="#e5d3be"/><stop id="mx2" offset="33.28%" stop-color="#dfc9b0"/><stop id="mx3" offset="52.49%" stop-color="#d6b999"/><stop id="mx4" offset="72.5%" stop-color="#c9a378"/><stop id="mx5" offset="75.7%" stop-color="#c79f72"/><stop id="mx6" offset="80.26%" stop-color="#a78560"/><stop id="mx7" offset="90.18%" stop-color="#564531"/><stop id="mx8" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="v-f" cx="0" cy="0" r="0.592685" spreadMethod="pad" gradientTransform="translate(0.441241 0.422507)"><stop id="vx0" offset="0%" stop-color="#f8cfdf"/><stop id="vx1" offset="18.43%" stop-color="#f7cadc"/><stop id="vx2" offset="39.95%" stop-color="#f5bcd2"/><stop id="vx3" offset="62.93%" stop-color="#f2a5c3"/><stop id="vx4" offset="77.42%" stop-color="#ef92b6"/><stop id="vx5" offset="98.39%" stop-color="#110a0d"/><stop id="vx6" offset="99.93%" stop-color="#000"/></radialGradient><radialGradient id="e-f" cx="0" cy="0" r="0.646556" spreadMethod="pad" gradientTransform="translate(0.416105 0.388832)"><stop id="ex0" offset="0.658138%" stop-color="#13a737"/><stop id="ex1" offset="10.13%" stop-color="#14a63c"/><stop id="ex2" offset="21.2%" stop-color="#16a44a"/><stop id="ex3" offset="33.08%" stop-color="#19a062"/><stop id="ex4" offset="45.51%" stop-color="#1d9b82"/><stop id="ex5" offset="58.4%" stop-color="#2394ad"/><stop id="ex6" offset="71.46%" stop-color="#2a8ce0"/><stop id="ex7" offset="76.89%" stop-color="#2d88f7"/><stop id="ex8" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="ma-f" cx="0" cy="0" r="0.594128" spreadMethod="pad" gradientTransform="translate(0.434342 0.412538)"><stop id="max0" offset="0%" stop-color="#ff6822"/><stop id="max1" offset="17.73%" stop-color="#fb6023"/><stop id="max2" offset="45.53%" stop-color="#ee4925"/><stop id="max3" offset="79.75%" stop-color="#da2529"/><stop id="max4" offset="81.64%" stop-color="#d92329"/><stop id="max5" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="j_2-f" cx="0" cy="0" r="0.64023" spreadMethod="pad" gradientTransform="translate(0.424619 0.420335)"><stop id="j_2x0" offset="0%" stop-color="#fce3c5"/><stop id="j_2x1" offset="16.38%" stop-color="#fce0bd"/><stop id="j_2x2" offset="42.06%" stop-color="#fbd6a7"/><stop id="j_2x3" offset="73.67%" stop-color="#f9c783"/><stop id="j_2x4" offset="79.59%" stop-color="#f9c47b"/><stop id="j_2x5" offset="82.82%" stop-color="#bc945d"/><stop id="j_2x6" offset="86.18%" stop-color="#836741"/><stop id="j_2x7" offset="89.45%" stop-color="#54422a"/><stop id="j_2x8" offset="92.55%" stop-color="#302518"/><stop id="j_2x9" offset="95.42%" stop-color="#15110b"/><stop id="j_2x10" offset="97.99%" stop-color="#060403"/><stop id="j_2x11" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="rg64-f" cx="0" cy="0" r="0.624269" spreadMethod="pad" gradientTransform="translate(0.447805 0.438193)"><stop id="rg64x0" offset="0%" stop-color="#ffefad"/><stop id="rg64x1" offset="16.53%" stop-color="#ffeea5"/><stop id="rg64x2" offset="42.43%" stop-color="#ffe98e"/><stop id="rg64x3" offset="74.33%" stop-color="#ffe26a"/><stop id="rg64x4" offset="75.19%" stop-color="#ffe269"/><stop id="rg64x5" offset="79.9%" stop-color="#bfa94f"/><stop id="rg64x6" offset="85.34%" stop-color="#7c6e33"/><stop id="rg64x7" offset="90.27%" stop-color="#463e1d"/><stop id="rg64x8" offset="94.5%" stop-color="#201c0d"/><stop id="rg64x9" offset="97.89%" stop-color="#090804"/><stop id="rg64x10" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="rg68-f" cx="0" cy="0" r="0.624269" spreadMethod="pad" gradientTransform="matrix(1 0 0 0.998043 0.447805 0.438193)"><stop id="rg68x0" offset="0%" stop-color="#ffefad"/><stop id="rg68x1" offset="16.53%" stop-color="#ffeea5"/><stop id="rg68x2" offset="42.43%" stop-color="#ffe98e"/><stop id="rg68x3" offset="74.33%" stop-color="#ffe26a"/><stop id="rg68x4" offset="75.19%" stop-color="#ffe269"/><stop id="rg68x5" offset="79.9%" stop-color="#bfa94f"/><stop id="rg68x6" offset="85.34%" stop-color="#7c6e33"/><stop id="rg68x7" offset="90.27%" stop-color="#463e1d"/><stop id="rg68x8" offset="94.5%" stop-color="#201c0d"/><stop id="rg68x9" offset="97.89%" stop-color="#090804"/><stop id="rg68x10" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="n-f" cx="0" cy="0" r="0.624949" spreadMethod="pad" gradientTransform="translate(0.408083 0.379986)"><stop id="nx0" offset="0.514633%" stop-color="#7c7cb6"/><stop id="nx1" offset="20.07%" stop-color="#7474b1"/><stop id="nx2" offset="50.72%" stop-color="#5e5ea4"/><stop id="nx3" offset="83.37%" stop-color="#3f3f93"/><stop id="nx4" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="u-f" cx="0" cy="0" r="0.605597" spreadMethod="pad" gradientTransform="translate(0.448986 0.421851)"><stop id="ux0" offset="0.694444%" stop-color="#caefee"/><stop id="ux1" offset="18.11%" stop-color="#c2edeb"/><stop id="ux2" offset="45.4%" stop-color="#abe6e4"/><stop id="ux3" offset="79%" stop-color="#87dbd8"/><stop id="ux4" offset="79.83%" stop-color="#86dbd8"/><stop id="ux5" offset="85.39%" stop-color="#58908e"/><stop id="ux6" offset="90.48%" stop-color="#325251"/><stop id="ux7" offset="94.76%" stop-color="#172625"/><stop id="ux8" offset="98.07%" stop-color="#060a0a"/><stop id="ux9" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="rg-f" cx="0" cy="0" r="0.624269" spreadMethod="pad" gradientTransform="translate(0.447805 0.438193)"><stop id="rgx0" offset="0%" stop-color="#ffefad"/><stop id="rgx1" offset="16.53%" stop-color="#ffeea5"/><stop id="rgx2" offset="42.43%" stop-color="#ffe98e"/><stop id="rgx3" offset="74.33%" stop-color="#ffe26a"/><stop id="rgx4" offset="75.19%" stop-color="#ffe269"/><stop id="rgx5" offset="79.9%" stop-color="#bfa94f"/><stop id="rgx6" offset="85.34%" stop-color="#7c6e33"/><stop id="rgx7" offset="90.27%" stop-color="#463e1d"/><stop id="rgx8" offset="94.5%" stop-color="#201c0d"/><stop id="rgx9" offset="97.89%" stop-color="#090804"/><stop id="rgx10" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="rg2-f" cx="0" cy="0" r="0.624269" spreadMethod="pad" gradientTransform="matrix(1 0 0 0.998043 0.447805 0.438193)"><stop id="rg2x0" offset="0%" stop-color="#ffefad"/><stop id="rg2x1" offset="16.53%" stop-color="#ffeea5"/><stop id="rg2x2" offset="42.43%" stop-color="#ffe98e"/><stop id="rg2x3" offset="74.33%" stop-color="#ffe26a"/><stop id="rg2x4" offset="75.19%" stop-color="#ffe269"/><stop id="rg2x5" offset="79.9%" stop-color="#bfa94f"/><stop id="rg2x6" offset="85.34%" stop-color="#7c6e33"/><stop id="rg2x7" offset="90.27%" stop-color="#463e1d"/><stop id="rg2x8" offset="94.5%" stop-color="#201c0d"/><stop id="rg2x9" offset="97.89%" stop-color="#090804"/><stop id="rg2x10" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="j-f" cx="0" cy="0" r="0.64023" spreadMethod="pad" gradientTransform="translate(0.424619 0.420335)"><stop id="jx0" offset="0%" stop-color="#fce3c5"/><stop id="jx1" offset="16.38%" stop-color="#fce0bd"/><stop id="jx2" offset="42.06%" stop-color="#fbd6a7"/><stop id="jx3" offset="73.67%" stop-color="#f9c783"/><stop id="jx4" offset="79.59%" stop-color="#f9c47b"/><stop id="jx5" offset="82.82%" stop-color="#bc945d"/><stop id="jx6" offset="86.18%" stop-color="#836741"/><stop id="jx7" offset="89.45%" stop-color="#54422a"/><stop id="jx8" offset="92.55%" stop-color="#302518"/><stop id="jx9" offset="95.42%" stop-color="#15110b"/><stop id="jx10" offset="97.99%" stop-color="#060403"/><stop id="jx11" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="ma_2-f" cx="0" cy="0" r="0.594128" spreadMethod="pad" gradientTransform="translate(0.434342 0.412538)"><stop id="ma_2x0" offset="0%" stop-color="#ff6822"/><stop id="ma_2x1" offset="17.73%" stop-color="#fb6023"/><stop id="ma_2x2" offset="45.53%" stop-color="#ee4925"/><stop id="ma_2x3" offset="79.75%" stop-color="#da2529"/><stop id="ma_2x4" offset="81.64%" stop-color="#d92329"/><stop id="ma_2x5" offset="100%" stop-color="#000"/></radialGradient><radialGradient id="rg3-f" cx="0" cy="0" r="0.500915" spreadMethod="pad" gradientTransform="matrix(0.998174 0 0 1 0.5 0.5)"><stop id="rg3x0" offset="0%" stop-color="#ffc200"/><stop id="rg3x1" offset="12.79%" stop-color="#ffbd00"/><stop id="rg3x2" offset="26.9%" stop-color="#ffb000"/><stop id="rg3x3" offset="41.59%" stop-color="#ff9a00"/><stop id="rg3x4" offset="54.3%" stop-color="#ff8100"/><stop id="rg3x5" offset="59.63%" stop-color="#ff7d00"/><stop id="rg3x6" offset="65.12%" stop-color="#ff7100"/><stop id="rg3x7" offset="70.67%" stop-color="#ff5c00"/><stop id="rg3x8" offset="76.28%" stop-color="#ff3f00"/><stop id="rg3x9" offset="81.86%" stop-color="#ff1a00"/><stop id="rg3x10" offset="85.28%" stop-color="#f00"/><stop id="rg3x11" offset="88.39%" stop-color="rgba(183,0,0,0.47)"/><stop id="rg3x12" offset="91.51%" stop-color="rgba(118,0,0,0.46)"/><stop id="rg3x13" offset="94%" stop-color="rgba(67,0,0,0)"/><stop id="rg3x14" offset="97%" stop-color="rgba(31,0,0,0)"/><stop id="rg3x15" offset="98.74%" stop-color="rgba(8,0,0,0)"/><stop id="rg3x16" offset="100%" stop-color="rgba(0,0,0,0)"/></radialGradient></defs><g><g><g><rect width="1920" height="1920" rx="0" ry="0"/></g><g transform="translate(36 583.852985)"><circle r="153" transform="translate(923 275)" fill="url(#rg8-f)"/><ellipse rx="237" ry="98.5" transform="translate(923 275.5)" fill="none" stroke="#808080" stroke-width="0.5669"/><ellipse rx="326.5" ry="135.5" transform="translate(923.5 287.5)" fill="none" stroke="#808080" stroke-width="0.5669"/><ellipse rx="412" ry="171" transform="translate(923 296)" fill="none" stroke="#808080" stroke-width="0.5669"/><ellipse rx="502.5" ry="208.5" transform="translate(923.5 308.5)" fill="none" stroke="#808080" stroke-width="0.5669"/><ellipse rx="597" ry="247.5" transform="translate(923 321.5)" fill="none" stroke="#808080" stroke-width="0.5669"/><ellipse rx="708.5" ry="294" transform="translate(923.5 344)" fill="none" stroke="#808080" stroke-width="0.5669"/><ellipse rx="819.5" ry="340" transform="translate(922.5 363)" fill="none" stroke="#808080" stroke-width="0.5669"/><ellipse rx="923.5" ry="383" transform="translate(923.5 383)" fill="none" stroke="#808080" stroke-width="0.5669"/><g id="m_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M686,275.5C695.5,190.682418,876.735172,177,923.098,177C995.520242,177,1153.078191,199.796028,1160,275.5C1160.78828,328.871632,1042.196346,378.197017,922.5,374C821.567753,375.852786,688.752424,339.512965,686,275.5" dur="7603200s" begin="-$MERCURY" repeatCount="indefinite"/><g id="my" transform="scale(0.8)"><circle r="9.5" transform="translate(0,0)" fill="url(#m-f)"/></g></g><g id="v_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M597,287.5C594.69812,210.500722,766.673452,147.598129,923.5,152C1041.331639,152,1245.102651,189.118302,1250,287.5C1251.288173,369.182006,1085.844724,423.553884,922.5,423C783.155745,423,607.081764,383.5,597,287.5" dur="19440000s" begin="-$VENUSs" repeatCount="indefinite"/><g id="vy" transform="scale(0.8)"><circle r="16.5" transform="translate(0,0)" fill="url(#v-f)"/></g></g><g id="e_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M511,296C503.109551,209.699813,686,125,922.5,122.073C1182.741756,132.893448,1341.929438,215.309766,1335,296C1340.290831,373.006854,1174.149765,468.311046,923.5,467C704.049721,467,512.308044,390.877469,511,296" dur="31536000s" begin="-$EARTHs" repeatCount="indefinite"/><g id="ey" transform="scale(0.8)"><circle r="16.5" transform="translate(0,0)" fill="url(#e-f)"/></g></g><g id="ma_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M421,308.5C422.338761,190.738633,648.125662,99.615581,922.5,100C1153.605104,97.068532,1430.798726,184.837256,1426,308C1429.109025,440.82037,1147.187956,522.412707,922.5,517C667.657138,521.795949,417.299429,421.538393,421,309.5" dur="59356800s" begin="-$MARSs" repeatCount="indefinite"/><g id="may" transform="scale(0.8)"><circle r="13.5" transform="translate(0,0)" fill="url(#ma-f)"/></g></g><g id="j_2_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M326,321.5C338.729096,154.197491,675.861149,69.582133,923.5,74C1076,74,1499.998503,122.073,1520,321.5C1520.231902,479.917026,1185.91972,575.56143,922.5,569C624.125234,579.590297,317.573179,459.969431,326,321.5" dur="374371200s" begin="-$JUPITERs" repeatCount="indefinite"/><g id="j_2y" transform="scale(0.8)"><circle r="40" transform="translate(0,0)" fill="url(#j_2-f)"/></g></g><g id="s_2_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M214.570538,344C190.462117,202.753146,556.266853,40.173264,922.5,54.147015C1249.444555,43.434056,1631.454971,170.835995,1632,344C1627.293153,537.358396,1227.337372,644.608484,922.5,638C433.663648,630.718834,207.516889,463.935385,215,344" dur="929577600s" begin="-$SATURNs" repeatCount="indefinite"/><g id="s_2y" transform="scale(0.8)"><g transform="translate(-247.5,-246.758301)"><circle r="34" transform="translate(248 247)" fill="url(#rg64-f)"/><path d="M247.5,231c-33.391346,0-60.5,6.92803-60.5,15.5s27.108654,15.5,60.5,15.5s60.5-6.92803,60.5-15.5-27.108654-15.5-60.5-15.5Zm0,25.598485c-21.756731,0-39.325-4.462121-39.325-10.098485s17.568269-10.098485,39.325-10.098485s39.325,4.462121,39.325,10.098485-17.568269,10.098485-39.325,10.098485Z" fill="#d8ae66"/><g transform="translate(203 204)"><g mask="url(#rg69)"><ellipse rx="34" ry="34.0667" transform="translate(44.8288 42.5833)" fill="url(#rg68-f)"/><mask id="rg69" mask-type="luminance"><use xlink:href="#rg7" fill="#fff"/></mask></g></g></g></g></g><g id="n_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M0,383.5C15.420054,121.424755,543.648307,1.640704,922.374868,0C1436.98444,0,1851.297965,175.396001,1847,383C1835.380223,627.36293,1326.045739,780.53835,922.5,766C481.16655,780.911326,-7.667502,605.394609,0,383" dur="2144448000s" begin="-$NEPTUNEs" repeatCount="indefinite"/><g id="ny" transform="scale(0.8)"><circle r="20.5" transform="translate(0,0)" fill="url(#n-f)"/></g></g><g id="u_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M103,363C89.559814,195.905938,467.885708,21.572957,922.374868,23C1366.102465,22.699244,1742,177,1742,363C1740.235509,594.880932,1265.846672,699.742095,923.5,703C563.336662,714.541593,108.547526,580.04011,103,362.5" dur="2144448000s" begin="-$URANUSs" repeatCount="indefinite"/><g id="uy" transform="scale(1)"><circle r="20.5" transform="translate(0,0)" fill="url(#u-f)"/></g></g><g id="s_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M214.570538,344C190.462117,202.753146,556.266853,40.173264,922.5,54.147015C1249.444555,43.434056,1631.454971,170.835995,1632,344C1627.293153,537.358396,1227.337372,644.608484,922.5,638C433.663648,630.718834,207.516889,463.935385,215,344" dur="929577600s" begin="-$SATURNs" repeatCount="indefinite"/><g id="sy" transform="scale(0.8)"><g transform="translate(-247.5,-246.758301)"><circle r="34" transform="translate(248 247)" fill="url(#rg-f)"/><path d="M247.5,231c-33.391346,0-60.5,6.92803-60.5,15.5s27.108654,15.5,60.5,15.5s60.5-6.92803,60.5-15.5-27.108654-15.5-60.5-15.5Zm0,25.598485c-21.756731,0-39.325-4.462121-39.325-10.098485s17.568269-10.098485,39.325-10.098485s39.325,4.462121,39.325,10.098485-17.568269,10.098485-39.325,10.098485Z" fill="#d8ae66"/><g transform="translate(203 204)"><g mask="url(#rg4)"><ellipse rx="34" ry="34.0667" transform="translate(44.8288 42.5833)" fill="url(#rg2-f)"/><mask id="rg4" mask-type="luminance"><use xlink:href="#rg7" fill="#fff"/></mask></g></g></g></g></g><g id="j_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M326,321.5C338.729096,154.197491,675.861149,69.582133,923.5,74C1076,74,1499.998503,122.073,1520,321.5C1520.231902,479.917026,1185.91972,575.56143,922.5,569C624.125234,579.590297,317.573179,459.969431,326,321.5" dur="374371200s" begin="-$JUPITERs" repeatCount="indefinite"/><g id="jy" transform="scale(0.8)"><circle id="j" r="40" transform="translate(0,0)" fill="url(#j-f)"/></g></g><g id="ma_2_to"><animateMotion keyPoints="1;0" keyTimes="0;1" calcMode="linear" path="M421,308.5C422.338761,190.738633,648.125662,99.615581,922.5,100C1153.605104,97.068532,1430.798726,184.837256,1426,308C1429.109025,440.82037,1147.187956,522.412707,922.5,517C667.657138,521.795949,417.299429,421.538393,421,309.5" dur="59356800s" begin="-$MARSs" repeatCount="indefinite"/><g id="ma_2y" transform="scale(0.8)"><circle id="ma_2" r="13.5" transform="translate(0,0)" fill="url(#ma_2-f)"/></g></g><g transform="translate(749 85)"><g mask="url(#rg5)"><ellipse rx="153.207" ry="152.927" transform="translate(174.098 190)" fill="url(#rg3-f)"/><mask id="rg5" mask-type="luminance"><use xlink:href="#rg6" fill="#fff"/></mask></g></g></g></g></g></svg>';
    string[] private FIND_REPLACE = ["$MERCURY", "$VENUS", "$EARTH", "$MARS", "$JUPITER", "$SATURN","$URANUS","$NEPTUNE"];
    mapping (uint => mapping (string => int)) VALUES;
    mapping (string => string) parts;
    constructor(address _proxyRegistryAddress) ERC721Tradable("SolarSystem", "Solar", _proxyRegistryAddress) {        

        //MERCURY
        VALUES[0]["ecc"] = 2056;
        VALUES[0]["per"] = 88;
        VALUES[0]["dev_per"] = 88;
        VALUES[0]["start"] = 1490227200;
        VALUES[0]["deg"] = 73;
        VALUES[0]["occ"] = 2;

        //VENUS
        VALUES[1]["ecc"] = 68;
        VALUES[1]["per"] = 225;
        VALUES[1]["dev_per"] = 225;
        VALUES[1]["start"] = 1487548800;
        VALUES[1]["deg"] = 130;
        VALUES[1]["occ"] = 2;

        //EARTH
        VALUES[2]["ecc"] = 167;
        VALUES[2]["per"] = 365;
        VALUES[2]["dev_per"] = 365;
        VALUES[2]["start"] = 1483488000;
        VALUES[2]["deg"] = 104;
        VALUES[2]["occ"] = 2;

        //MARS
        VALUES[3]["ecc"] = 934;
        VALUES[3]["per"] = 686;
        VALUES[3]["dev_per"] = 686;
        VALUES[3]["start"] = 1477440000;
        VALUES[3]["deg"] = 334;
        VALUES[3]["occ"] = 5;

        //JUPITER
        VALUES[4]["ecc"] = 484;
        VALUES[4]["per"] = 4329;
        VALUES[4]["dev_per"] = 4329;
        VALUES[4]["start"] = 1300320000;
        VALUES[4]["deg"] = 14;
        VALUES[4]["occ"] = 5;

        //SATURN
        VALUES[5]["ecc"] = 541;
        VALUES[5]["per"] = 10753;
        VALUES[5]["dev_per"] = 10753;
        VALUES[5]["start"] = 1059264000;
        VALUES[5]["deg"] = 94;
        VALUES[5]["occ"] = 4;

        //URANUS
        VALUES[6]["ecc"] = 472;
        VALUES[6]["per"] = 30664;
        VALUES[6]["dev_per"] = 24820;
        VALUES[6]["start"] = -113097600;
        VALUES[6]["deg"] = 169;
        VALUES[6]["occ"] = 2;

        //NEPTUNE
        VALUES[7]["ecc"] = 86;
        VALUES[7]["per"] = 60148;
        VALUES[7]["dev_per"] = 24820;
        VALUES[7]["start"] = -2805753600;
        VALUES[7]["deg"] = 45;
        VALUES[7]["occ"] = 2;


        parts['A'] = 'stop-color="#';
        parts['B'] = 'radialGradient';
        parts['C'] = 'gradientTransform="translate(';
        parts['D'] = 'fill="url(#';
        parts['E'] = 'transform="translate(';
        parts['F'] = 'stroke-width="0.5669"';
        parts['G'] = 'spreadMethod="pad"';
        parts['H'] = 'repeatCount="indefinite"/>';
        parts['I'] = 'keyTimes="0;1" calcMode="linear"';
        parts['4'] = '<ellipse rx="';
        parts['L'] = 'stop id="';
        parts['M'] = 'offset="';
        parts['N'] = 'animateMotion keyPoints="1;0"';
        parts['O'] = 'stroke="#808080"';
        parts['P'] = 'path="';
        parts['Q'] = 'animation-delay:';
        parts['R'] = 'transform';
        parts['S'] = '<circle';
        parts['T'] = '000';
        parts['U'] = 'linear infinite reverse';
        parts['V'] = 'scale(';
        parts['Z'] = 'animation:';
        parts['X'] = 'mask';
        parts['Y'] = '<g id="';
        parts['W'] = '</g>';
        parts['2'] = 's" begin="';
        parts['0'] = 'fill="';
        parts['1'] = 'stop-color="rgba(';
    }

   function decompress(string memory text) public view returns (string memory) {
       string memory HTML = "";
       strings.slice memory text_slice = text.toSlice();
       strings.slice memory delim = "|".toSlice();
       strings.slice memory mapping_tot;
       uint count = text_slice.count(delim) + 1;
       for(uint i = 0; i < count;i++) {
            mapping_tot = text_slice.split(delim);
            string memory map_tot = mapping_tot.toString();
            if(parts[map_tot].toSlice().len() > 0)
                HTML = HTML.toSlice().concat(parts[map_tot].toSlice());
            else
                HTML = HTML.toSlice().concat(mapping_tot);
       }
       return HTML;
   }


    function f( uint x, uint e, uint k) public pure returns (int) {
        return int(x) - (int(e)*sin(x))/10000 - int(k);
    }

    function f1( uint x, uint e) public pure returns (int) {
        return int(TWO_PI) - int(e) * cos(x)/10000;
    }

    function mean_anomaly(uint planet,uint t, uint offset) public view returns (uint) {
        uint e    = uint(VALUES[planet]["ecc"]);
        uint T    = uint(VALUES[planet]["per"]);
        uint deg  = uint(VALUES[planet]["deg"]);
        int  t0   = VALUES[planet]["start"];
        uint M    = TWO_PI / T * uint( uint((int(t)-t0) )%(T*SECONDS)) / SECONDS;
        uint E    = eccentric_anomaly_from_mean_anomaly(M,e) * 360 / TWO_PI;
        uint ME   = (offset + deg + E)%360;
        return ME;
    }

    function eccentric_anomaly_from_mean_anomaly(uint M, uint e) public pure returns (uint) {
        uint i = 0;
        uint x = M; 
        while ( i < 5 ) {
            x = uint(int(x) - f(x,e,M) * int(TWO_PI) / f1(x,e)) ;
            i ++;
        }
        return x;
    }

    //remove tokenID
    function tokenURI(uint _tokenId) override public view returns (string memory) {
        uint t = block.timestamp;
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',"Solar System"'", "image":"',getTOKEN(t),'"}'
                        )
                    )
                )
            )
        );
    }

   function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        '{"name":"r","description":"recursive","image":"","external_link":"https://yazo.fun/","seller_fee_basis_points":0,"fee_recipient":""}'
                    )
                )
            ));
      
    }
    function getTOKEN(uint t) public view returns (string memory) {
       string memory HTML = decompress(HTML_CODE);//decompress(HTML_CODE);
       uint length = FIND_REPLACE.length;
       for (uint i=0; i<length;) {
          uint devT = uint(VALUES[i]["dev_per"]);
          string memory offset = Strings.toString(devT*SECONDS*(mean_anomaly(i,t,180)*100/360)/100);
          for (uint it=0; it < uint(VALUES[i]["occ"]);) {
            HTML = findReplace(FIND_REPLACE[i],offset,HTML);
            unchecked { it++; }
          }
          unchecked { i++; }
       }
       return string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(bytes(HTML))));
    }
    function lockData() public onlyOwner {
        _lockData = true;
    }
    function setTokenData(string memory HTML) public onlyOwner {
        require(!_lockData);
        HTML_CODE = HTML;
    }

    function findReplace(string memory search, string memory replace, string memory subject) internal pure returns (string memory) {
        strings.slice memory _slice1 = subject.toSlice();
        return _slice1.split(search.toSlice()).concat(replace.toSlice()).toSlice().concat(_slice1);
    } 

    function withdraw(address payable recipient, uint amount) external onlyOwner {
        recipient.transfer(amount);
    }
    function premine() external onlyOwner {
        mintTo(msg.sender);
    }
    function baseTokenURI() override public pure returns (string memory) {
        return "";
    }
    function st2num(string memory numString) public pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
    
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }

  uint constant INDEX_WIDTH         = 8;
  uint constant INTERP_WIDTH        = 16;
  uint constant INDEX_OFFSET        = 28 - INDEX_WIDTH;
  uint constant INTERP_OFFSET       = INDEX_OFFSET - INTERP_WIDTH;
  uint  constant ANGLES_IN_CYCLE    = 1073741824;
  uint  constant QUADRANT_HIGH_MASK = 536870912;
  uint  constant QUADRANT_LOW_MASK  = 268435456;
  uint constant SINE_TABLE_SIZE     = 256;
  uint constant PI          = 3141592653589793238;
  uint constant TWO_PI      = 2 * PI;
  uint constant PI_OVER_TWO = PI / 2;
  uint8   constant entry_bytes = 4; 
  uint constant entry_mask  = ((1 << 8*entry_bytes) - 1); 
  bytes   constant sin_table   = hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";
  function sin(uint _angle) public pure returns (int256) {
    unchecked {
      _angle = ANGLES_IN_CYCLE * (_angle % TWO_PI) / TWO_PI;
      uint interp = (_angle >> INTERP_OFFSET) & ((1 << INTERP_WIDTH) - 1);
      uint index  = (_angle >> INDEX_OFFSET)  & ((1 << INDEX_WIDTH)  - 1);
      bool is_odd_quadrant      = (_angle & QUADRANT_LOW_MASK)  == 0;
      bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;
      if (!is_odd_quadrant) {
        index = SINE_TABLE_SIZE - 1 - index;
      }
      bytes memory table = sin_table;
      uint offset1_2 = (index + 2) * entry_bytes;
      uint x1_2; assembly {
        x1_2 := mload(add(table, offset1_2))
      }
      uint x1 = x1_2 >> 8*entry_bytes & entry_mask;
      uint x2 = x1_2 & entry_mask;
      uint approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
      int256 sine = is_odd_quadrant ? int256(x1) + int256(approximation) : int256(x2) - int256(approximation);
      if (is_negative_quadrant) {
        sine *= -1;
      }
      return sine * 1e18 / 2_147_483_647;
    }
  }
  function cos(uint _angle) public pure returns (int256) {
    unchecked {
      return sin(_angle + PI_OVER_TWO);
    }
  }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE_ENCODE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");
        bytes memory table = TABLE_DECODE;
        uint256 decodedLen = (data.length / 4) * 3;
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }
            mstore(result, decodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len_) private pure {
        for(; len_ >= 32; len_ -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = type(uint).max;
        if (len_ > 0) {
            mask = 256 ** (32 - len_) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                uint mask = type(uint).max; 
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}