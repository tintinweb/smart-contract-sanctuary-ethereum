// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract AMP is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    address payable public rugWallet = payable(0x29235E6ddE31a94BFebBBA187DC8a53Af2219389);
    uint256 public currentLimit = 5000; //starting Supply
    uint256 public maxSupply = 10000; //Maximum Supply
    uint256 public maxBatch = 5; //Max Mint
    uint256 public price = 0.5 ether; //Mint Price
    uint256 public burnCount;
    string public baseURI = "ipfs://QmWhjgX8PMrVJ7PAAxueXv5BjeaEdBg9DCFww35st5cagU/1";
    address[] public whitelistedNFT;
    uint public start;
    struct Whitelist {
        bool whitelisted;
        uint amount;
    }
    mapping(address => Whitelist) public isInvitee;
    //add whitelist duration 72
    constructor(address[] memory whitelist) ERC721('ALPHA MINT PASS', 'AMP') {
        whitelistedNFT = whitelist;
        for (uint256 index = 0; index < whitelist.length; index++) {
            isInvitee[whitelist[index]] = Whitelist(true, 250);
        }
        start = block.timestamp;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function claim(uint256 _batchCount, address invitation) payable public {
        require(_batchCount > 0 && _batchCount <= maxBatch, "You can mint a maximum of 5 tokens");
        require(totalSupply() + _batchCount <= currentLimit, "Cannot go above the current limit");
        require(msg.value == _batchCount * price, "Wrong ether value");
        require(_canMint(_batchCount, invitation), "You cannot mint now");
        emit Claim(msg.sender, totalSupply(), _batchCount);
        for(uint256 i = 0; i< _batchCount; i++) {
            //+1 so token ID starts at 1 and not 0
            _mint(msg.sender, totalSupply() + 1);
        }
    }

    function _canMint(uint256 _batchCount, address invitation) internal returns(bool) {
        bool result;
        if (block.timestamp < start + 72 hours && isInvitee[invitation].whitelisted) {
            require(isInvitee[invitation].amount > 0, "The invited contract used all the spots");
            require(ERC721(invitation).balanceOf(msg.sender) > 0, "User must own NFT from the invited contract");
            isInvitee[invitation].amount -= _batchCount;
            result = true;
        } else if (block.timestamp >= start + 72 hours ){
            result = true;
        }
        return result;
    }

    function addWhitelist (address nft) public onlyOwner {
        isInvitee[nft] = Whitelist(true, 250);
    }

    function walletDistro() public {
        uint256 contractBalance = address(this).balance;
        (bool sentR,) = rugWallet.call{value: contractBalance}("");
        require(sentR);
    }

    function setWallets(address payable _rugWallet) external onlyOwner {
        rugWallet = _rugWallet;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setMaxBatch(uint _batch) external onlyOwner {
        maxBatch = _batch;
    }

    function rescueEther() public onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: address(this).balance}('');
        require(sent);    
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function increaseLimit(uint to) public onlyOwner {
        require(to <= maxSupply);
        require(to > 5000);
        currentLimit = to;
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
    */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     
            // OpenSea approval
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        burnCount++;
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
       return super.tokenURI(tokenId);
    }
  
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.0 (finance/PaymentSplitter.sol)

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract RugSalary is Context, Ownable, ReentrancyGuard {
    event PayeeAdded(address account, uint256 shares);
    event ShareChanged(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 private _bonusBalance;
    uint256 private _bonusTotalReleased;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    mapping(address => uint256) private _bonusReleased;
    address[] private _payees;
    address payable _business;
    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_, address payable business) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");
        _business = business;
        for (uint256 i = 0; i < payees.length; i++) {
            addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
        Address.sendValue(_business, (msg.value * 10 / 100));
        _bonusBalance += (msg.value * 5 / 100);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Setter to modify share held by an account.
     */
    function changeShares(address account, uint newShares) public onlyOwner {
        require(address(this).balance - _bonusBalance == 0, "Everyone need to claim before adding a new payee");
        emit ShareChanged(account, newShares);
        _shares[account] = newShares;
        _totalShares = 0;
        _totalReleased = 0;
        _bonusTotalReleased = 0;
        for (uint256 index = 0; index < _payees.length; index++) {
            _totalShares += _shares[_payees[index]];
            _released[_payees[index]] = 0;
            _bonusReleased[_payees[index]] = 0;
        }
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual nonReentrant {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased() - _bonusBalance;
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;
        uint bonusPayment = (_bonusBalance + _bonusTotalReleased) / _payees.length - _bonusReleased[account];
        _bonusBalance -= bonusPayment;
        _bonusReleased[account] += bonusPayment;
        _bonusTotalReleased += bonusPayment;
        Address.sendValue(account, payment + bonusPayment);
        emit PaymentReleased(account, payment);
    }

    function toRelease(address payable account) public view returns (uint) {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased() - _bonusBalance;
        uint256 payment = _pendingPayment(account, totalReceived, released(account));
        return payment;
    }

    function emergencyRelease() public onlyOwner {
        _bonusBalance = 0;
        Address.sendValue(payable(_business), address(this).balance);
        emit PaymentReleased(_business, address(this).balance);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function addPayee(address account, uint256 shares_) public onlyOwner {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");
        require(address(this).balance - _bonusBalance == 0, "Everyone need to claim before adding a new payee");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        _totalReleased = 0;
        _bonusTotalReleased = 0;
        for (uint256 index = 0; index < _payees.length; index++) {
            _released[_payees[index]] = 0;
            _bonusReleased[_payees[index]] = 0;
        }

        emit PayeeAdded(account, shares_);
    }
}

//dustcleaning function

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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RoyaltiesReceiver is ReentrancyGuard {
  event Royalties(uint256 indexed received);
  uint8 _royaltiesRate;
  uint8 _mintRate;
  uint256 public royalties;
  address payable _clientWallet;
  address payable _qtWallet;
  constructor(uint8 __royaltiesRate, uint8 __mintRate, address payable __clientWallet, address payable __qtWallet) {
    _royaltiesRate = __royaltiesRate;
    _mintRate = __mintRate;
    _clientWallet = __clientWallet;
    _qtWallet = __qtWallet;
  }
  receive() payable external {
    royalties += msg.value;
    emit Royalties(royalties);
  }
  function walletDistro() external nonReentrant {
    if (royalties > 0) {
      uint old = royalties;
      royalties = 0;
      Address.sendValue(_clientWallet, old * (100 - _royaltiesRate) / 100);
      Address.sendValue(_qtWallet, old * _royaltiesRate / 100);
    }
    uint256 contractBalance = address(this).balance;
    if (contractBalance > 0) {  
      Address.sendValue(_clientWallet, contractBalance * (100 - _mintRate) / 100);
      Address.sendValue(_qtWallet, contractBalance * _mintRate / 100);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */



contract NFTEthVault is Context, ReentrancyGuard, Ownable {
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalReleased;
    address public baseToken;
    
    mapping(uint => uint256) private _released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address _baseToken) payable {
        require(_baseToken != address(0));
        baseToken = _baseToken;
    }
    
    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(uint doji) public view returns (uint256) {
        return _released[doji];
    }

    function expectedRelease(uint doji) public view returns (uint256) {
        require(IERC721Enumerable(baseToken).totalSupply() > 0, "PaymentSplitter: Doji has no shares");
        require(doji <= IERC721Enumerable(baseToken).totalSupply(), "The Token hasn't been minted yet");
        uint256 totalReceived = address(this).balance + _totalReleased;
        if (totalReceived / IERC721Enumerable(baseToken).totalSupply() <= _released[doji]) {
            return 0;
        }
        uint256 payment = totalReceived / IERC721Enumerable(baseToken).totalSupply() - _released[doji];

        return payment;
    }

    /**
     * @dev Triggers a transfer to `doji` holder of the amount of Ether they are owed, according to their percentage of the
     * total shares (1/totalSupply) and their previous withdrawals.
     */
    function release(uint doji) public virtual nonReentrant {
        require(IERC721Enumerable(baseToken).totalSupply() > 0, "PaymentSplitter: Doji has no shares");
        require(IERC721(baseToken).ownerOf(doji) == _msgSender());

        uint256 totalReceived = address(this).balance + _totalReleased;

        require(totalReceived / IERC721Enumerable(baseToken).totalSupply() > _released[doji], "PaymentSplitter: doji is not due payment");

        uint256 payment = totalReceived / IERC721Enumerable(baseToken).totalSupply() - _released[doji];

        require(payment > 0, "PaymentSplitter: doji is not due payment");

        _released[doji] = _released[doji] + payment;
        _totalReleased = _totalReleased + payment;
        address payable account = payable(IERC721(baseToken).ownerOf(doji));
        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to owner in case of emergency
     */
    function rescueEther() public onlyOwner  {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }



    function changeBaseToken(address _baseToken) public onlyOwner  {
        require(_baseToken != address(0));
        baseToken = _baseToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender

contract Yakuza is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Received(address, uint256);
    address payable public clientWallet;
    address payable public rugWallet = payable(0xdAd7CC98ee08F6dAD1b52CF5Da664AfcB7B891B5);
    uint256 public startindId = 101; //user start minting at ID 101
    uint256 public burnCount;
    uint256 public totalCount = 10000; //Maximum Supply
    uint256 public initialReserve = 100; //Initial Team Reserve
    uint256 public maxBatch = 50; //Max Mint
    uint256 public price = 0.025 * 10**18; //Mint Price
    address public tokenAddress; //Yakuza Contract Address = 0xCC13c4995FdF51d163D97e90FCA5423dFeC0f3Bb
    uint[4] public tokenTiers = [10 * 10**18, 5 * 10**18, 1 * 10**18];
    uint256 public mintStartTime;
    uint256 public mintWindowGap = 8;//8 hours
    
    string public baseURI = "ipfs://Qme1gdt6gFepD1mw7Hy1d7bhp6HnHy7bL9bK8VuohsD3tS/";
    bool private _started = false; //Modified to start as false originally just initialized the boolean
    string _name = 'YAKUZA STREET GANG';
    string _symbol = 'YKZ';

    constructor(address _clientAddress, address _tokenAddress) ERC721(_name, _symbol) {
        clientWallet = payable(_clientAddress);
        tokenAddress = _tokenAddress;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {//Assign a new token address to check against for mint priority (Review this S)
        tokenAddress = _tokenAddress;
    }

    function getMintTime(address sender) public view returns (uint256){// Might end up putting this in claimDoji so we dont need to supply sender but wrote it separately for now (Review this S)
        uint256 balance = IERC20(tokenAddress).balanceOf(sender);
        if (tokenTiers.length == 0){// Check to see if tiers have been initialized, if they havent then array is empty and should have length 0 and DOJI Crew can be minted immediately if sale has started.
            
            return block.timestamp;
        }

        uint256 i = 0;
        while(tokenTiers[i] != 0){// Check to see what tier the senders tokens fits in, this determines the minting delay
            if (balance >= tokenTiers[i]){
                
                break;// Assuming 0 is placed on the end of the tiers this should not throw an error, I can write in some error handling based on array.length if necessary
            }
            i++;
        }
        return mintStartTime + (mintWindowGap * i * 1 hours);

    }

    function setStart(bool _start) public onlyOwner {
        if (_start){
            mintStartTime = block.timestamp;
        }
        _started = _start;
    }

    function claim(uint256 _batchCount) payable public {//Will add in getMintTime check using block.timestamp here tomorrow
        require(_started);
        require(_batchCount > 0 && _batchCount <= maxBatch);
        require((totalSupply() + initialReserve) + _batchCount + burnCount <= totalCount);
        require(msg.value == _batchCount * price);
        require(block.timestamp > getMintTime(msg.sender), 'Not allowed to mint yet');

        emit Claim(_msgSender(), startindId, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            require(startindId <= totalCount);
            _mint(_msgSender(), startindId++);
        }
 
    }

    function walletDistro() public {
        uint256 contractBalance = address(this).balance;
        (bool sentR,) = rugWallet.call{value: (contractBalance * 200) / 1000}("");
        require(sentR);
        (bool sentC,) = clientWallet.call{value: (contractBalance * 800) / 1000}("");
        require(sentC);
    }

    //contract size limit forced me to pack that function
    function changeWallets(
        address payable _clientWallet,
        address payable _rugWallet
     ) external onlyOwner {
        clientWallet = _clientWallet;
        rugWallet = _rugWallet;
    }

    function rescueEther() public onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: address(this).balance}('');
        require(sent);    
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < totalCount);
        require(tokenId <= initialReserve);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        burnCount++;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender

contract RUGHAT is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 tokenID);
    event Paid (address indexed influencer, uint _amount);

    uint256 public burnCount;
    uint256 constant public TOTALCOUNT = 500;
    uint256 constant public MAXBATCH = 1;
    uint256 public price = 0.015 * 10**18;  //0.015 eth
    string public baseURI = "ipfs://QmZY5nxC3riLxGXrwnUQC9dfMTJYJDFpw73LtRNuANve1A/";
    string constant _NAME = "RUG X THEM: RUG HATS";
    string constant _SYMBOL = "RUGHAT";
    address constant _RUGS = 0x6C94954D0b265F657A4A1B35dfAA8B73D1A3f199;
    address constant _HATS = 0x23c9e48F7E9fCa487bd0c4f41EE1445812d871fd;
    address constant _HATTERS = 0x72420B94cb54d9237023e887F590B95551b6595a;

    constructor()
    ERC721(_NAME, _SYMBOL) {
        transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }
    receive() external payable {}

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function claim(uint256 _batchCount) payable public {
        require(_batchCount > 0 && _batchCount <= MAXBATCH, "Invalid batch count");
        require(totalSupply() + _batchCount + burnCount <= TOTALCOUNT, "No token remaining");
        require(msg.value == _batchCount * price, "Invalid value sent");
        require(hasToken(), "You must own at least one Rug and Hat/Hatter to mint.");
        for(uint256 i = 0; i < _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            emit Claim(_msgSender(), mintID);
            _mint(_msgSender(), mintID);
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function hasToken() public view returns (bool) {
        address sender = _msgSender();
        if(
            IERC721(_RUGS).balanceOf(sender) > 0 &&
            (IERC721(_HATS).balanceOf(sender) > 0 || IERC721(_HATTERS).balanceOf(sender) > 0)
        ) {
            return true;
        }
        return false;
    }

    function tokenRemaining() public view returns (uint) {
        return TOTALCOUNT - totalSupply() - burnCount;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < TOTALCOUNT);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        burnCount++;
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY DO NOT REMOVE
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender

contract RUGHATTEST is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 tokenID);
    event Paid (address indexed influencer, uint _amount);

    uint256 public burnCount;
    uint256 constant public TOTALCOUNT = 500;
    uint256 constant public MAXBATCH = 1;
    uint256 public price = 0.015 * 10**18;  //0.015 eth
    string public baseURI = "";
    string constant _NAME = "RUG X THEM";
    string constant _SYMBOL = "RUGHAT";
    address public _RUGS = 0x6C94954D0b265F657A4A1B35dfAA8B73D1A3f199;
    address public _HATS = 0x23c9e48F7E9fCa487bd0c4f41EE1445812d871fd;
    address public _HATTERS = 0x72420B94cb54d9237023e887F590B95551b6595a;

    constructor(address rugs, address hats, address hatters)
    ERC721(_NAME, _SYMBOL) {
        _RUGS = rugs;
        _HATS = hats;
        _HATTERS = hatters;
        transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }
    receive() external payable {}

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function claim(uint256 _batchCount) payable public {
        require(_batchCount > 0 && _batchCount <= MAXBATCH, "Invalid batch count");
        require(totalSupply() + _batchCount + burnCount <= TOTALCOUNT, "No token remaining");
        require(msg.value == _batchCount * price, "Invalid value sent");
        require(hasToken(), "You must own at least one Rug and Hat/Hatter to mint.");
        for(uint256 i = 0; i < _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            emit Claim(_msgSender(), mintID);
            _mint(_msgSender(), mintID);
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function hasToken() public view returns (bool) {
        address sender = _msgSender();
        if(
            IERC721(_RUGS).balanceOf(sender) > 0 &&
            (IERC721(_HATS).balanceOf(sender) > 0 || IERC721(_HATTERS).balanceOf(sender) > 0)
        ) {
            return true;
        }
        return false;
    }
    
    function tokenRemaining() public view returns (uint) {
        return TOTALCOUNT - totalSupply() - burnCount;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < TOTALCOUNT);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        burnCount++;
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY DO NOT REMOVE
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MyToken is ERC721Enumerable, Ownable {
    constructor(string memory name, string memory token) ERC721(name, token) {
        // safeMint(_msgSender(),1);
        // transferOwnership(0xDB50D10374840b23a3f6769145a6AC911354F544);
    }

    receive() payable external {}

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender

contract ERC721ThreeTiers is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    address payable public clientWallet;
    address payable public rugWallet;
    uint256 public startindId; //user start minting at ID 101
    uint256 public burnCount;
    uint256 public totalCount; //Maximum Supply
    uint256 public teamReserveCount;
    uint256 public maxBatch; //Max Mint
    uint256 public price; //Mint Price
    address public tokenAddress; //Zingot Contract Address
    uint[] public tokenTiers;
    uint256 public mintStartTime;
    uint256 public mintWindowGap;//24 hours
    
    string public baseURI;
    bool private _started = false; //Modified to start as false originally just initialized the boolean

    constructor(address _clientAddress, address _tokenAddress, string memory name, string memory symbol) ERC721(name, symbol) {
        clientWallet = payable(_clientAddress);
        tokenAddress = _tokenAddress;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner{
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {//Assign a new token address to check against for mint priority (Review this S)
        tokenAddress = _tokenAddress;
    }

    function getMintTime(address sender) public view returns (uint256){// Might end up putting this in claimDoji so we dont need to supply sender but wrote it separately for now (Review this S)
        uint256 balance = ERC20(tokenAddress).balanceOf(sender);
        if (tokenTiers.length == 0){// Check to see if tiers have been initialized, if they havent then array is empty and should have length 0 and DOJI Crew can be minted immediately if sale has started.
            return block.timestamp;
        }
        uint256 i = 0;
        while(tokenTiers[i] != 0){// Check to see what tier the senders tokens fits in, this determines the minting delay
            if (balance >= tokenTiers[i]){
                break;// Assuming 0 is placed on the end of the tiers this should not throw an error, I can write in some error handling based on array.length if necessary
            }
            i++;
        }
        return mintStartTime + (mintWindowGap * i * 1 hours);

    }

    function setStart(bool _start) public onlyOwner {
        if (_start){
            mintStartTime = block.timestamp;
        }
        _started = _start;
    }

    function claim(uint256 _batchCount) payable public {//Will add in getMintTime check using block.timestamp here tomorrow
        require(_started);
        require(_batchCount > 0 && _batchCount <= maxBatch);
        require((totalSupply() + teamReserveCount) + _batchCount + burnCount <= totalCount);
        require(msg.value == _batchCount * price);
        require(block.timestamp > getMintTime(msg.sender));

        emit Claim(_msgSender(), startindId, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            require(startindId <= totalCount);
            _mint(_msgSender(), startindId++);
        }
 
    }

    function walletDistro() public {
        uint256 contractBalance = address(this).balance;
        (bool sentR,) = rugWallet.call{value: (contractBalance * 500) / 1000}("");
        require(sentR);
        (bool sentC,) = clientWallet.call{value: (contractBalance * 500) / 1000}("");
        require(sentC);
    }

    //contract size limit forced me to pack that function
    function changeWallets(
        address payable _clientWallet,
        address payable _rugWallet
     ) external onlyOwner {
        clientWallet = _clientWallet;
        rugWallet = _rugWallet;
    }

    function rescueEther() public onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: address(this).balance}('');
        require(sent);    
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function teamMint(address to, uint tokenId) public onlyOwner {
        require(teamReserveCount > 0);
        require((totalSupply() + burnCount) < totalCount);
        require(tokenId > 0 && tokenId < startindId);
        teamReserveCount -= 1;
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        burnCount++;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId))) : "";
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DNA is ERC20, Ownable {
    address private _team = 0xA10b03f4757Db94aC99b390E0b22A620394d2d55;

    constructor() ERC20("DNA", "DNA") {
        _mint(_team, 10_000_000 * 10 ** decimals());
        transferOwnership(_team);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract THESE is ERC20, Ownable {
    address private _hatDAO = 0x15f4d11dD90382F7FD81D0ca37D5D7e44706ffCE;
    address private _team = 0x80319b22FC81D700485B915FEE3d2D9C69DC3839;

    constructor() ERC20("THESE", "THESE") {
        _mint(_hatDAO, 100000 * 10 ** decimals());
        _mint(_team, 1000 * 10 ** decimals());
        transferOwnership(_hatDAO);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Test20 is ERC20, Ownable, ERC20Burnable {
    constructor() ERC20("test20", "T20") {
      _mint(msg.sender, 20000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract PriceTest is ERC2771Context {
  string public test;

  constructor() ERC2771Context(0x4d4581c01A457925410cd3877d17b2fd4553b2C5) {}

  function setTest (string calldata _test) public {
    test = _test;
  }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
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
        if (operator == _msgSender()) revert ApproveToCaller();

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
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
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
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
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
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
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RugHR is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, AccessControl {

    event NewStaff (address indexed minter, uint256 startWith, uint256 batch);
    
    string public baseURI;
    bytes32 public constant HR_ROLE = keccak256("HR_ROLE");
    string public baseURI_ = "ipfs://QmeG8YLTKE5z5yfvGyZoEDRyEAGDvvuKGSuEPQQ5an7RXv/";
    address public currentHR;
    uint256 public burnCount;
    uint256 public startIndId = 0;
    string name_ = 'RUG.TECH';
    string symbol_ = 'RUG';

    constructor() ERC721(name_, symbol_) {
        _setupRole(HR_ROLE, msg.sender);
        currentHR = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseURI = baseURI_;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function editStaff(uint256 _tokenId, string calldata role, string memory _tokenURI) public onlyRole(HR_ROLE) {
        
        _setTokenURI(_tokenId, string(abi.encodePacked(role, _tokenURI)));
    }

    function removeStaff(uint256 _tokenId) public onlyRole(HR_ROLE) {
        _setTokenURI(_tokenId, string(abi.encodePacked('inactive_staff/', _tokenId)));
    }

    function newHR(address NewHR) public onlyOwner {
        revokeRole(HR_ROLE, currentHR);
        currentHR = NewHR;
        grantRole(HR_ROLE, NewHR);
    }

    function newStaff(uint256 _batchCount) public onlyOwner {
        
        emit NewStaff(_msgSender(), startIndId, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            _mint(_msgSender(), startIndId++);
        }
 
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function moveOffice(address newOwner) public onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        Ownable.transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RugPunksOrderPass is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event MintOrderPass (address indexed buyer, uint256 startWith, uint256 batch);
    address payable public wallet;
    uint256 public totalMinted;
    uint256 public burnCount;
    uint256 public totalCount = 500;
    uint256 public initialReserve = 125;
    uint256 public maxBatch = 5;
    uint256 public price = 0.1 * 10**18; 
    string public baseURI;
    bool private started;
    string name_ = 'Rug Punks Order Pass';
    string symbol_ = 'RPOP';
    string baseURI_ = 'ipfs://QmbWx8QS3mgj35221AYj2uGr82Cj99uz5PgKm5MiveGhkD/';
    constructor() ERC721(name_, symbol_) {
        baseURI = baseURI_;
        wallet = payable(msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function mintOrderPass(uint256 _batchCount) payable public {
        require(started, "Sale has not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch purchase limit exceeded");
        require((totalMinted + initialReserve) + _batchCount <= totalCount, "Not enough inventory");
        require(msg.value == _batchCount * price, "Invalid value sent");
        

        emit MintOrderPass(_msgSender(), totalMinted + 1, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            _mint(_msgSender(), ((1 + totalMinted++) + initialReserve));
        }
        
        //walletDistro();
    }

    function walletDistro() public {
        uint256 contract_balance = address(this).balance;
        //require(payable(wallet).send(contract_balance));
        require(payable(0x22910c380B708d7d1284d27a5e6e981E405D5674).send( (contract_balance * 750) / 1000));
        require(payable(0x4326Af09eD5c166758FD42FE1585Aa4c718aE6b8).send( (contract_balance * 250) / 1000));
    }
    
    function distroDust() public {
        walletDistro();
        uint256 contract_balance = address(this).balance;
        require(payable(wallet).send(contract_balance));
    }

    function changeWallet(address payable _newWallet) external onlyOwner {
        wallet = _newWallet;
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RugPunksOrderPass.sol";

contract WrapOrderPass is Ownable {
  event MintOrderPass (address indexed buyer, uint256 startWith, uint256 batch);
  uint256 public maxSupply = 111;
  uint256 public counter = 0;
  uint256 public endTimer;
  uint256 public tokenId; 
  uint256 private _price = 0.111 ether;
  address private _contract;
  address private _wallet;
  constructor(address contractPass, address wallet) {
    _contract = contractPass;
    _wallet = wallet;
    tokenId = RugPunksOrderPass(_contract).totalMinted();
  }

  function claim() payable external {
    require(msg.value == _price, "The price is 0.111 ETH");
    require(counter < 111, "Sold out");
    if (counter == 0){
      endTimer = block.timestamp + 111 minutes;
    }
    if (block.timestamp > endTimer) {
      RugPunksOrderPass(_contract).renounceOwnership();
      selfdestruct(payable(_wallet));
    }
    ++counter;
    RugPunksOrderPass(_contract).safeMint(msg.sender, tokenId);
    ++tokenId;
    if (counter == 111) {
      RugPunksOrderPass(_contract).renounceOwnership();
      selfdestruct(payable(_wallet));
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract QuantumPFP is ERC721, Ownable {

  event Mint (address indexed buyer, uint256 tokenId);
  string public baseURI;
  uint256 public counter;
  string _name = 'Quantum Team';
  string _symbol = 'QT';
  struct Employee {
    bytes32 name;
    bytes32 designation;
    bytes32 avatar;
    bytes32 specialty;
    bytes32 email;
  }
  mapping(uint => Employee) public EmployeeList;
  constructor(address _owner) ERC721(_name, _symbol) {
    transferOwnership(_owner);
  }

  function addEmployee(bytes32 name, bytes32 designation, bytes32 avatar, bytes32 specialty, bytes32 email) external onlyOwner {

  }

  function terminateAccess(uint tokenId) external onlyOwner {

  }

  function restoreAccess(uint tokenId, bytes32 designation) external onlyOwner  {

  }

  function changeDesignation(uint tokenId, bytes32 designation) external onlyOwner  {

  }

  function _baseURI() internal view virtual override returns (string memory){
    return baseURI;
  }

  function setBaseURI(string memory _newURI) public onlyOwner {
    baseURI = _newURI;
  }

  function claim() payable public {
    emit Mint(_msgSender(), counter);
    _mint(_msgSender(), counter); 
    ++counter;
  }
  
  function burn(uint256 tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    _burn(tokenId);
  }

  // Pre approve owner of the contract
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    return (spender == owner());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FuckLootV2 is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event GetFucked (address indexed buyer, uint256 startWith, uint256 batch);

    address payable public mainWallet;
    address payable public faucetWallet;

    uint256 public totalMinted;
    uint256 public burnCount;
    uint256 public totalCount = 10000;
    uint256 public maxBatch = 50;
    uint256 public price = 1 * 10 ** 18;
    uint256 public initialReserve = 21;
    uint256 private nftsReserved;
    string public baseURI;
    bool private started;

    string name_ = 'FUCKLOOT';
    string symbol_ = 'FLOOT';
    string baseURI_ = 'ipfs://QmQfwVxi1rFSxrXNW7VGVFJ1AXDmb6TRmgbdvu7De3G7AU/';

    constructor() ERC721(name_, symbol_) {
        baseURI = baseURI_;
        mainWallet = payable(msg.sender);
        faucetWallet = payable(msg.sender);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function distributeFunds() public payable onlyOwner{
        uint256 contract_balance = address(this).balance;
        require(payable(mainWallet).send( (contract_balance * 500) / 1000));
        (bool sent, ) = payable(faucetWallet).call{value: ((contract_balance * 500) / 1000)}("");
        require(sent);
    }

    function mintReservedNFTs(address[] memory to) public onlyOwner { //Check this to make sure its how we want to reserve some of the initial supply
        require(nftsReserved <= initialReserve, "Exceeds reserve supply");
        require(to.length == initialReserve);
        for (uint256 i = 0; i < initialReserve; i++) {
            nftsReserved++;
            totalMinted++;
            _safeMint(to[i], totalMinted);
        }  
    }

    function changeMainWallet(address payable _newWallet) external onlyOwner { 
        mainWallet = _newWallet;
    }

    function changeFaucetWallet(address payable _newWallet) external onlyOwner { 
        faucetWallet = _newWallet;

    }

    function distroDust() public onlyOwner {
        uint256 contract_balance = address(this).balance;
        require(payable(mainWallet).send(contract_balance));
    }

    function getFucked(uint256 _batchCount) payable public {
        require(started, "Sale has not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch purchase limit exceeded");
        require(totalMinted + _batchCount + burnCount <= totalCount, "Not enough inventory");
        require(msg.value == _batchCount * price, "Invalid value sent");
 
        emit GetFucked(_msgSender(), totalMinted, _batchCount);
        for(uint256 i=0; i < _batchCount; i++){
            totalMinted++;
            _safeMint(_msgSender(), totalMinted);
        }
        
        uint256 contract_balance = address(this).balance;
        require(payable(mainWallet).send( (contract_balance * 500) / 1000));
        (bool sent, ) = payable(faucetWallet).call{value: ((contract_balance * 500) / 1000)}("");
        require(sent);
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1  )) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./FlootClaimV3P.sol";

contract Accounting721 is Ownable {
    event LuckyHolder(uint256 indexed luckyHolder, address indexed sender);
    event ChosenHolder(uint256 indexed chosenHolder, address indexed sender);

    FlootClaimsV3 _claimContract;

    struct NFTClaimInfo {
      address nftContract;
      uint256 tokenID;
      uint256 holder;
      bool claimed;
    }
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;

    constructor(){
    }

    modifier onlyClaimContract() { // Modifier
        require(
            msg.sender == address(_claimContract),
            "Only Claim contract can call this."
        );
        _;
    }

  function random721(address nftContract, uint256 tokenID) external onlyClaimContract {
    uint256 luckyFuck = _pickLuckyHolder();
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, luckyFuck, false);
    nftClaimInfo[luckyFuck].push(newClaim);
    emit LuckyHolder(luckyFuck, nftContract);
  }

  function send721(address nftContract, uint256 tokenID, uint256 chosenHolder) public {
    require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
    ERC721(nftContract).safeTransferFrom(msg.sender,address(_claimContract),tokenID, 'true');
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, chosenHolder, false);
    nftClaimInfo[chosenHolder].push(newClaim);
    emit ChosenHolder(chosenHolder, nftContract);
  }

	function _pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _claimContract.currentBaseTokensHolder())));
		uint index = (rando % _claimContract.currentBaseTokensHolder());
		uint result = IERC721Enumerable(_claimContract.baseTokenAddress()).tokenByIndex(index);
		return result;
	}

    function viewNFTsPending(uint id)view external returns (NFTClaimInfo[] memory) {
      return nftClaimInfo[id];
    }

    function viewNFTsPendingByIndex(uint id, uint index)view external returns (NFTClaimInfo memory) {
      return nftClaimInfo[id][index];
    }

    function viewNumberNFTsPending(uint id) view external returns (uint) {
      return nftClaimInfo[id].length;
    }

    function viewNumberNFTsPendingByAcc(address account) public view returns(uint256){
      BaseToken baseToken = BaseToken(_claimContract.baseTokenAddress());
      uint256[] memory userInventory = baseToken.walletInventory(account);
      uint256 pending;

      // get pending payouts for all tokenids in caller's wallet
      for (uint256 index = 0; index < userInventory.length; index++) {
          for(uint256 j = 0; j < nftClaimInfo[userInventory[index]].length; j++) {
              if (nftClaimInfo[userInventory[index]][j].claimed == false) {
                  pending++;
              }
          }
      }
      return pending;
    }

    function claimNft(uint id, uint index) external onlyClaimContract {
      require(msg.sender == address(_claimContract));
      nftClaimInfo[id][index].claimed = true;
    }

    function setClaimProxy (address proxy) public onlyOwner {
      _claimContract = FlootClaimsV3(payable(proxy));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "../../templates/NFTEthVaultUpgradeable.sol";
import "./ERC721Acc.sol";
import "./ERC1155Acc.sol";


interface BaseToken is IERC721EnumerableUpgradeable {
    function walletInventory(address _owner) external view returns (uint256[] memory);
}

contract FlootClaimsV3 is Initializable,
    ERC721HolderUpgradeable, 
    ERC1155HolderUpgradeable, 
    UUPSUpgradeable,
    NFTEthVaultUpgradeable
    {
    event Received(address, uint256);

    bool public halt;
    Accounting721 _nFT721accounting;
    Accounting1155 _nFT1155accounting;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address _baseToken, address _nft721accounting, address _nft1155accounting) public initializer {
      __ERC721Holder_init();
      __ERC1155Holder_init();
      __nftVault_init(_baseToken);
      __UUPSUpgradeable_init();
      _nFT721accounting = Accounting721(_nft721accounting);
      _nFT1155accounting = Accounting1155(_nft1155accounting);
      halt = false;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function change1155accounting(address _address) public onlyOwner {
        _nFT1155accounting = Accounting1155(_address);
    }

    function change721accounting(address _address) public onlyOwner {
        _nFT721accounting = Accounting721(_address);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenID,
        bytes memory data
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0){
          _nFT721accounting.random721(msg.sender, tokenID);
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256 tokenID,
        uint256 _amount,
        bytes memory data
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0) {
          _nFT1155accounting.random1155(msg.sender, tokenID, _amount);
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        revert();
    }

    function currentBaseTokensHolder() view external returns (uint) {
        return IERC721EnumerableUpgradeable(baseToken).totalSupply();
    }

    function baseTokenAddress() view external returns (address) {
        return address(baseToken);
    }

    function claimNFTsPending(uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(IERC721EnumerableUpgradeable(baseToken).ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");
      
        uint length = _nFT721accounting.viewNumberNFTsPending(_tokenID);

        for (uint256 index = 0; index < length; index++) {
          Accounting721.NFTClaimInfo memory luckyBaseToken = _nFT721accounting.viewNFTsPendingByIndex(_tokenID, index);
            if(!luckyBaseToken.claimed){
                _nFT721accounting.claimNft(_tokenID, index);
                ERC721Upgradeable(luckyBaseToken.nftContract)
                  .safeTransferFrom(address(this), msg.sender, luckyBaseToken.tokenID);
            }
        }
    }

    function claimOneNFTPending(uint256 _tokenID, address _nftContract, uint256 _nftId) public {
        require(!halt, 'Claims temporarily unavailable');
        require(IERC721EnumerableUpgradeable(baseToken).ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        uint length = _nFT721accounting.viewNumberNFTsPending(_tokenID);

        for (uint256 index = 0; index < length; index++) {
          Accounting721.NFTClaimInfo memory luckyBaseToken = _nFT721accounting.viewNFTsPendingByIndex(_tokenID, index);
            if(!luckyBaseToken.claimed && luckyBaseToken.nftContract == _nftContract && luckyBaseToken.tokenID == _nftId){
                _nFT721accounting.claimNft(_tokenID, index);
                return ERC721Upgradeable(luckyBaseToken.nftContract)
                  .safeTransferFrom(address(this), msg.sender, luckyBaseToken.tokenID);
            }
        }
    }

    function claimOne1155Pending(uint256 dojiID, address _contract, uint256 tokenID, uint _amount) public {
        require(!halt, 'Claims temporarily unavailable');
        require(IERC721EnumerableUpgradeable(baseToken).ownerOf(dojiID) == msg.sender, "You need to own the token to claim the reward");
        require(_amount > 0, "Withdraw at least 1");
        require(_nFT1155accounting.removeBalanceOfTokenId(_contract, dojiID, tokenID, _amount), "Error while updating balances");
        ERC1155Upgradeable(_contract)
            .safeTransferFrom(address(this), msg.sender, tokenID, _amount, "");
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }
}

contract FlootClaimsV3_1 is FlootClaimsV3 {
    function withdrawERC20(address tokenAddress) public onlyOwner {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer( _msgSender(), balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */



contract NFTEthVaultUpgradeable is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalReleased;
    address public baseToken;
    
    mapping(uint => uint256) private _released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor() payable {
    }

     // solhint-disable-next-line
    function __nftVault_init(address _baseToken) public initializer {
        __Context_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __nftVault_init_unchained();
        baseToken = _baseToken;
    }

     // solhint-disable-next-line
    function __nftVault_init_unchained() internal initializer {
    }
    
    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(uint doji) public view returns (uint256) {
        return _released[doji];
    }

    function expectedRelease(uint doji) public view returns (uint256) {
        require(IERC721EnumerableUpgradeable(baseToken).totalSupply() > 0, "PaymentSplitter: Doji has no shares");
        require(doji <= IERC721EnumerableUpgradeable(baseToken).totalSupply(), "The Token hasn't been minted yet");
        uint256 totalReceived = address(this).balance + _totalReleased;
        if (totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() <= _released[doji]) {
            return 0;
        }
        uint256 payment = totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() - _released[doji];

        return payment;
    }

    /**
     * @dev Triggers a transfer to `doji` holder of the amount of Ether they are owed, according to their percentage of the
     * total shares (1/totalSupply) and their previous withdrawals.
     */
    function release(uint doji) public virtual nonReentrant {
        require(IERC721EnumerableUpgradeable(baseToken).totalSupply() > 0, "PaymentSplitter: Doji has no shares");
        require(IERC721EnumerableUpgradeable(baseToken).ownerOf(doji) == _msgSender());

        uint256 totalReceived = address(this).balance + _totalReleased;

        require(totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() > _released[doji], "PaymentSplitter: doji is not due payment");

        uint256 payment = totalReceived / IERC721EnumerableUpgradeable(baseToken).totalSupply() - _released[doji];

        require(payment > 0, "PaymentSplitter: doji is not due payment");

        _released[doji] = _released[doji] + payment;
        _totalReleased = _totalReleased + payment;
        address payable account = payable(IERC721EnumerableUpgradeable(baseToken).ownerOf(doji));
        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to owner in case of emergency
     */
    function rescueEther() public onlyOwner  {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }

    function changeBaseToken(address _baseToken) public onlyOwner  {
        require(_baseToken != address(0));
        baseToken = _baseToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./FlootClaimV3P.sol";
import "hardhat/console.sol";

contract Accounting1155 is Ownable{
	event LuckyHolder1155(uint256 indexed luckyHolder, address indexed sender, uint, uint);
	event ChosenHolder1155(uint256 indexed chosenHolder, address indexed sender, uint, uint);

	FlootClaimsV3 _claimContract;
		struct TokenIDClaimInfo {
			uint index;
			uint balance;
		}

    struct NFTClaimInfo {
			uint index;
			uint[] tokenID;
      mapping(uint => TokenIDClaimInfo) claimTokenStruct;
    }

		struct ContractInfo {
			address[] contractIndex;
			mapping(address => NFTClaimInfo) contractInfos;
		}

    mapping (uint256 => ContractInfo) private _userInventory;
		
	constructor(){}

	modifier onlyClaimContract() { // Modifier
		require(
			msg.sender == address(_claimContract),
			"Only Claim contract can call this."
		);
		_;
	}

	function isContractForUser(address _contract, uint dojiID) public view returns(bool) {
		if (_userInventory[dojiID].contractIndex.length == 0) return false;
		return (_userInventory[dojiID].contractIndex[_userInventory[dojiID].contractInfos[_contract].index] == _contract);
	}

	function isTokenIDForContractForUser(address _contract, uint dojiID, uint tokenID) public view returns(bool) {
		if (_userInventory[dojiID].contractInfos[_contract].tokenID.length == 0) return false;
		return (
			_userInventory[dojiID].contractInfos[_contract]
				.tokenID[ _userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index ] == tokenID
		);
	}

	function insertContractForUser (
		address _contract, 
		uint dojiID,
    uint tokenID, 
    uint balance
	) 
    public
    returns(uint index)
  {
    require(!isContractForUser(_contract, dojiID), "Contract already exist"); 
		_userInventory[dojiID].contractIndex.push(_contract);
    _userInventory[dojiID].contractInfos[_contract].index = _userInventory[dojiID].contractIndex.length - 1;
		if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)){
			_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].balance = balance;
			_userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
    	_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
		}
    return _userInventory[dojiID].contractIndex.length-1;
  }

	function _addBalanceOfTokenId(address _contract, uint dojiID, uint tokenID, uint _amount) 
    private
    returns(bool success) 
  {
    require(isContractForUser(_contract, dojiID), "Contract doesn't exist");
		if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)) {
			_userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
    	_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
		}
    if (_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].balance == 0) {
			_userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].balance = _amount;
		} else {
			_userInventory[dojiID]
				.contractInfos[_contract]
				.claimTokenStruct[tokenID].balance += _amount;
		}
    return true;
  }

	function removeBalanceOfTokenId(address _contract, uint dojiID, uint tokenID, uint _amount) 
    public onlyClaimContract
    returns(bool success) 
  {
    require(isContractForUser(_contract, dojiID), "Contract doesn't exist"); 
		require(isTokenIDForContractForUser(_contract, dojiID, tokenID));
		_userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].balance -= _amount;
    return true;
  }

	function getTokenBalanceByID(address _contract, uint dojiID, uint tokenID) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].balance;
	}

	function getTokenIDCount(address _contract, uint dojiID) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID.length;
	}

	function getTokenIDByIndex(address _contract, uint dojiID, uint index) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID[index];
	}

	function getContractAddressCount(uint dojiID) public view returns(uint){
		return _userInventory[dojiID].contractIndex.length;
	}

	function getContractAddressByIndex(uint dojiID, uint index) public view returns(address){
		return _userInventory[dojiID].contractIndex[index];
	}

	function random1155(address _contract, uint tokenID, uint _amount) external onlyClaimContract {
	  require(_amount > 0);
	  uint256 luckyFuck = _pickLuckyHolder();
		if (isContractForUser(_contract, luckyFuck)) {
			_addBalanceOfTokenId(_contract, luckyFuck, tokenID,  _amount);
		} else {
			insertContractForUser (_contract, luckyFuck, tokenID, _amount);
		}
	  emit LuckyHolder1155(luckyFuck, msg.sender, tokenID, _amount);
	}

	function send1155(address _contract, uint tokenID, uint _amount, uint256 chosenHolder) public {
		require(_amount > 0);
		require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
		if (isContractForUser(_contract, chosenHolder)) {
			_addBalanceOfTokenId(_contract, chosenHolder, tokenID, _amount);
		} else {
			insertContractForUser (_contract, chosenHolder, tokenID, _amount);
		}
		ERC1155(_contract).safeTransferFrom(msg.sender,  address(_claimContract), tokenID, _amount, 'true');
		emit ChosenHolder1155(chosenHolder, msg.sender, tokenID, _amount);
	}

	function _pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _claimContract.currentBaseTokensHolder())));
		uint index = (rando % _claimContract.currentBaseTokensHolder());
		uint result = IERC721Enumerable(_claimContract.baseTokenAddress()).tokenByIndex(index);
		return result;
	}

	function setClaimProxy (address proxy) public onlyOwner {
	  _claimContract = FlootClaimsV3(payable(proxy));
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

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
    ) external returns (bytes4);

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./FlootClaimV3P.sol";
import "hardhat/console.sol";

contract Accounting721Exp is Ownable{
	event LuckyHolder1155(uint256 indexed luckyHolder, address indexed sender, uint);
	event ChosenHolder1155(uint256 indexed chosenHolder, address indexed sender, uint);

	FlootClaimsV3 _claimContract;
		struct TokenIDClaimInfo {
      uint index;
			bool claimed;
		}

    struct NFTClaimInfo {
			uint index;
			uint[] tokenID;
      mapping(uint => TokenIDClaimInfo) claimTokenStruct;
    }

		struct ContractInfo {
			address[] contractIndex;
			mapping(address => NFTClaimInfo) contractInfos;
		}

    mapping (uint256 => ContractInfo) private _userInventory;
		
	constructor(){}

	modifier onlyClaimContract() { // Modifier
		require(
			msg.sender == address(_claimContract),
			"Only Claim contract can call this."
		);
		_;
	}

	function isContractForUser(address _contract, uint dojiID) public view returns(bool) {
		if (_userInventory[dojiID].contractIndex.length == 0) return false;
		return (_userInventory[dojiID].contractIndex[_userInventory[dojiID].contractInfos[_contract].index] == _contract);
	}

	function isTokenIDForContractForUser(address _contract, uint dojiID, uint tokenID) public view returns(bool) {
		if (_userInventory[dojiID].contractInfos[_contract].tokenID.length == 0) return false;
		return (
			_userInventory[dojiID].contractInfos[_contract]
				.tokenID[ _userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index ] == tokenID
		);
	}

	function insertContractForUser (
		address _contract, 
		uint dojiID,
    uint tokenID
	) 
    public
    returns(uint index)
  {
    require(!isContractForUser(_contract, dojiID), "Contract already exist"); 
		_userInventory[dojiID].contractIndex.push(_contract);
    _userInventory[dojiID].contractInfos[_contract].index = _userInventory[dojiID].contractIndex.length - 1;
		if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)){
			_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].claimed = false;
			_userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
    	_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
		}
    return _userInventory[dojiID].contractIndex.length-1;
  }

  function removeBalanceOfTokenId(address contractAdress, uint flootID, uint tokenId) 
    public onlyClaimContract
    returns(bool)
  {
    require(isContractForUser(contractAdress, flootID), "contract doesn't exist for user");
    require(isTokenIDForContractForUser(contractAdress, flootID, tokenId), "tokenId doesn't exist for user");
    uint rowToDelete = _userInventory[flootID].contractInfos[contractAdress].claimTokenStruct[tokenId].index;
    uint keyToMove = _userInventory[flootID].contractInfos[contractAdress].tokenID[_userInventory[flootID].contractInfos[contractAdress].tokenID.length -1 ];
    _userInventory[flootID].contractInfos[contractAdress].tokenID[rowToDelete] = keyToMove;
    _userInventory[flootID].contractInfos[contractAdress].claimTokenStruct[keyToMove]. index = rowToDelete;
    _userInventory[flootID].contractInfos[contractAdress].tokenID.pop();
    return true;
  }

	function _addBalanceOfTokenId(address _contract, uint dojiID, uint tokenID) 
    private
    returns(bool success) 
  {
    require(isContractForUser(_contract, dojiID), "Contract doesn't exist");
		if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)) {
			_userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
    	_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
		}
    if (_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].claimed == true) {
			_userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].claimed = false;
		}
    return true;
  }

	function getTokenStatusByID(address _contract, uint dojiID, uint tokenID) public view returns(bool){
		return _userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].claimed;
	}

	function getTokenIDCount(address _contract, uint dojiID) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID.length;
	}

	function getTokenIDByIndex(address _contract, uint dojiID, uint index) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID[index];
	}

	function getContractAddressCount(uint dojiID) public view returns(uint){
		return _userInventory[dojiID].contractIndex.length;
	}

	function getContractAddressByIndex(uint dojiID, uint index) public view returns(address){
		return _userInventory[dojiID].contractIndex[index];
	}

	function random721(address _contract, uint tokenID) external onlyClaimContract {
	  uint256 luckyFuck = _pickLuckyHolder();
		if (isContractForUser(_contract, luckyFuck)) {
			_addBalanceOfTokenId(_contract, luckyFuck, tokenID);
		} else {
			insertContractForUser (_contract, luckyFuck, tokenID);
		}
	  emit LuckyHolder1155(luckyFuck, msg.sender, tokenID);
	}

	function send721(address _contract, uint tokenID, uint256 chosenHolder) public {
		require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
		if (isContractForUser(_contract, chosenHolder)) {
			_addBalanceOfTokenId(_contract, chosenHolder, tokenID);
		} else {
			insertContractForUser(_contract, chosenHolder, tokenID);
		}
		IERC721Enumerable(_contract).safeTransferFrom(msg.sender,  address(_claimContract), tokenID, 'true');
		emit ChosenHolder1155(chosenHolder, msg.sender, tokenID);
	}

	function _pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _claimContract.currentBaseTokensHolder())));
		uint index = (rando % _claimContract.currentBaseTokensHolder());
		uint result = IERC721Enumerable(_claimContract.baseTokenAddress()).tokenByIndex(index);
		return result;
	}

	function setClaimProxy (address proxy) public onlyOwner {
	  _claimContract = FlootClaimsV3(payable(proxy));
	}

  function viewNumberNFTsPending(uint id) view external returns (uint) {
    return _userInventory[id].contractIndex.length;
  }

  function viewNumberNFTsPendingByAcc(address account) public view returns(uint256){
    BaseToken baseToken = BaseToken(_claimContract.baseTokenAddress());
    uint256[] memory userInventory = baseToken.walletInventory(account);
    uint256 pending;

    // get pending payouts for all tokenids in caller's wallet
    console.log("inventory length", userInventory.length);
    for (uint256 index = 0; index < userInventory.length; index++) {
      console.log("index", index);
      uint currentFlootID = userInventory[index];
      uint contractLength = _userInventory[currentFlootID].contractIndex.length;
      console.log("contract length",contractLength);
      for(uint256 j = 0; j < contractLength; j++) {
        console.log("j", j);
        address currentAddress = _userInventory[currentFlootID].contractIndex[j];
        uint tokenIDLength =  _userInventory[currentFlootID].contractInfos[currentAddress].tokenID.length;
        console.log("tokenId length", tokenIDLength);
        for(uint256 k = 0; k < tokenIDLength; k++) {
          console.log("k", k);
          uint currentTokenID = _userInventory[currentFlootID].contractInfos[currentAddress].tokenID[k];
          console.log("current token ID",currentTokenID);
          if ( _userInventory[currentFlootID].contractInfos[currentAddress].claimTokenStruct[currentTokenID].claimed == false) {
              pending++;
              console.log("Pending:",pending);
          }
        }
      }
    }
    return pending;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol"; 
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
//
//
//

contract Proposal is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC2771ContextUpgradeable {

    address[13] public tribeLeaders;
    mapping(address => bool) public addressToWhitelist;
    constructor() initializer {}

    function initialize(address forwarder) initializer public {
        __ERC2771Context_init(forwarder);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _msgSender() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (address ret) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (bytes calldata ret) {
        return ERC2771ContextUpgradeable._msgData();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function _getMessageHash(uint timestamp, address signer) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(timestamp, signer))); 
    }

    function _getMessage(uint timestamp, address signer) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(timestamp, signer)); 
    }

    function _recover(address signer, uint timestamp, bytes memory signature) internal view returns(bool) {
        bytes32 hash = _getMessageHash(timestamp, signer);
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }

    function isAuthorized(address signer, uint timestamp, bytes memory signature) view public returns (bool) {
        require(_recover(signer, timestamp, signature));
        bool auth = addressToWhitelist[signer];
        for (uint256 index = 0; index < tribeLeaders.length; index++) {
            if (tribeLeaders[index] == signer) {
                auth = true;
            }
        }
        return auth;
    }

    function removeWhitelist(address whitelist) public onlyOwner {
        addressToWhitelist[whitelist] = false;
    }

    function addWhitelist(address whitelist) public onlyOwner {
        addressToWhitelist[whitelist] = true;
    }

    function setTribeLeader(address _leader, uint tribe) public onlyOwner {
        tribeLeaders[tribe] = _leader;
    }

    function setTribeLeaders(address[13] calldata _leaders) public onlyOwner {
        tribeLeaders = _leaders;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

/// @custom:security-contact [email protected]
contract MSGToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC2771ContextUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address forwarder) initializer public {
    __ERC20_init("MoonSuGar", "MSG");
    __ERC2771Context_init(forwarder);
    __ERC20Burnable_init();
    __ERC20Snapshot_init();
    __Ownable_init();
    __UUPSUpgradeable_init();
    _mint(msg.sender, 500_000_000 * 10 ** decimals());
  }

  function _msgSender() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (address ret) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (bytes calldata ret) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function snapshot() public onlyOwner {
    _snapshot();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}
    // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ArraysUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Snapshot_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC20Snapshot_init_unchained();
    }

    function __ERC20Snapshot_init_unchained() internal onlyInitializing {
    }
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol"; 

abstract contract ENS {
    function resolver(bytes32 node) public virtual view returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public virtual view returns (address);
}

/// @custom:security-contact [email protected]
contract MSGClaim is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC2771ContextUpgradeable {
  event Claim (address indexed user, uint256 amount);
  IERC20 _msgToken;
  address _backEnd;
  mapping(address => bool) public addressToClaim;
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address forwarder, address _msg) initializer public {
    __ERC2771Context_init(forwarder);
    __Ownable_init();
    __UUPSUpgradeable_init();
    _msgToken = IERC20(_msg);
    _backEnd = 0xeb862fF4b8104d4BAe22427367A9a3A16694B486;
  }

  function _msgSender() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (address ret) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (bytes calldata ret) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}

  function _getMessageHash(uint amount, uint timestamp) internal view returns (bytes32) {
      return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(amount, timestamp))); 
  }

  function _getMessage(uint amount, uint timestamp) internal view returns (bytes32) {
      return keccak256(abi.encodePacked(amount, timestamp, _msgSender())); 
  }

  function recover(uint amount, uint timestamp, bytes memory signature) public view returns(bool) {
      bytes32 hash = _getMessageHash(amount, timestamp);
      return SignatureChecker.isValidSignatureNow(_backEnd, hash, signature);
  }

  function claim(uint amount, uint timestamp, bytes memory signature) public {
    require(addressToClaim[_msgSender()] == false, 'Already Claimed');
    require(recover(amount, timestamp, signature), "Issue with the signature");
    require(_msgToken.balanceOf(address(this)) >= amount);
    addressToClaim[_msgSender()] == true; 
    _msgToken.transfer(_msgSender(), amount);
    emit Claim(_msgSender(), amount);
  }
}

contract MSGClaimV2 is MSGClaim {
  function claimV2(uint amount, uint timestamp, bytes memory signature) public {
    require(addressToClaim[_msgSender()] == false, 'Already Claimed');
    require(recover(amount, timestamp, signature), "Issue with the signature");
    require(_msgToken.balanceOf(address(this)) >= amount);
    addressToClaim[_msgSender()] = true; 
    _msgToken.transfer(_msgSender(), amount);
    emit Claim(_msgSender(), amount);
  }

  function rescueMSG() public onlyOwner {
    _msgToken.transfer(_msgSender(), _msgToken.balanceOf(address(this)));
  }
}

contract MSGClaimV3 is MSGClaimV2 {
  address[13] public tribeLeaders;
  string[13] public order;

  function changeLeader(uint8 index, address leader) public onlyOwner {
    tribeLeaders[index] = leader;
  }

  function changeLeaders(address[13] memory leaders) public onlyOwner {
    order = ["Zero", "Bee", "Penguin", "Owl", "Dog", "Gorilla", "Red Panda", "Turtle", "Llama", "Mouse", "Elephant", "Frog"];
    tribeLeaders = leaders;
  }

  function sendBonusToLeader(uint amount, uint8 index) public onlyOwner {
    _msgToken.transfer(tribeLeaders[index], amount);
  }

  function payTribeLeaders() public onlyOwner {
    for (uint256 index = 0; index < tribeLeaders.length; index++) {
      if (tribeLeaders[index] != address(0)) {
        _msgToken.transfer(tribeLeaders[index], 250_000 ether);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
import "hardhat/console.sol";

contract ZingotPayout is Ownable, Pausable, ReentrancyGuard {

  event Claim (address indexed buyer, uint256 tokenID);

  uint public lastTimestamps;
  IERC20 _zingot;
  address _backend = 0xeb862fF4b8104d4BAe22427367A9a3A16694B486;
  uint[9] _salary = [2 ether, 4 ether, 6 ether, 8 ether, 12 ether, 18 ether, 24 ether, 36 ether, 50 ether];
  mapping(uint => DojiPay) public idToDoji;
  struct DojiPay {
    uint rank;
    uint paid;
  }

  constructor(address zingot) {
    _zingot = IERC20(zingot);
  }

  receive() external payable {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _getMessageHash(uint rank, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(rank, timestamp))); 
  }

  function _getMessage(uint rank, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(rank, timestamp, _msgSender())); 
  }

  function _recover(address signer, uint rank, uint timestamp, bytes memory signature) internal view returns(bool) {
    bytes32 hash = _getMessageHash(rank, timestamp);
    return SignatureChecker.isValidSignatureNow(signer, hash, signature);
  }

  function viewClaimable(uint dojiID, uint rank) view public returns (uint) {
    uint toPay;
    uint dojiSalary;
    uint timeSinceMint;
    uint zingotPerSec;
    if (idToDoji[dojiID].rank != 0) {
      dojiSalary = _salary[idToDoji[dojiID].rank - 1];
      timeSinceMint = block.timestamp - 1632439986;
      zingotPerSec = dojiSalary / 86400000;
      toPay = timeSinceMint * zingotPerSec * 1000 - idToDoji[dojiID].paid;
    } else {
      dojiSalary = _salary[rank - 1];
      timeSinceMint = block.timestamp - 1632439986;
      zingotPerSec = dojiSalary / 86400000;
      toPay = timeSinceMint * zingotPerSec * 1000;
    }
    return toPay;
  }

  function viewClaimables(uint[] memory dojiIDs, uint[] memory ranks) view public returns (uint) {
    require(dojiIDs.length > 0 && ranks.length > 0 && dojiIDs.length == ranks.length, "Bad parameters");
    uint totalAmount;
    for (uint256 index = 0; index < dojiIDs.length; index++) {
     totalAmount += viewClaimable(dojiIDs[index], ranks[index]);
    }
    return totalAmount;
  }

  function _computeAmount(uint dojiID) internal returns(uint) {
    uint dojiSalary = _salary[idToDoji[dojiID].rank - 1];
    uint timeSinceMint = block.timestamp - 1632439986;
    uint zingotPerSec = dojiSalary / 86400000;
    uint toPay = timeSinceMint * zingotPerSec * 1000 - idToDoji[dojiID].paid;
    idToDoji[dojiID].paid += toPay; 
    return toPay;
  }

  function claim(uint[] calldata dojiID, uint[] calldata ranks, uint timestamp, bytes memory signature) public whenNotPaused nonReentrant {
    require(dojiID.length > 0 && ranks.length > 0 && dojiID.length == ranks.length, "Bad parameters");
    require(_recover(_backend, ranks[0], timestamp, signature));
    uint totalAmount = 0;
    for (uint256 index = 0; index < dojiID.length; index++) {
      if(idToDoji[dojiID[index]].rank == 0) {
        idToDoji[dojiID[index]].rank = ranks[index];
      }
      totalAmount += _computeAmount(dojiID[index]); 
    }
    _zingot.transfer(_msgSender(), totalAmount); 
    lastTimestamps = timestamp;
  }

  function rescueEther() public onlyOwner {
    uint256 currentBalance = address(this).balance;
    (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
    require(sent,"Error while transfering the eth");    
  }

  function rescueZingot(uint amount) public onlyOwner nonReentrant {
    require(_zingot.balanceOf(address(this)) >= amount);
    _zingot.transfer(_msgSender(), amount); 
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "hardhat/console.sol";
import "./payout.sol";

contract ZingotPayout2 is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, ERC2771ContextUpgradeable {

  event Claim (address indexed buyer, uint256 tokenID);

  uint public lastTimestamps;
  IERC20 _zingot;
  ZingotPayout _oldPayout;
  address _backend;
  uint[9] _salary;
  mapping(uint => DojiPay) public idToDoji;
  struct DojiPay {
    uint rank;
    uint paid;
  }
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {}

  function initialize(address zingot, address forwarder, address payable oldPayout) initializer public {
    _zingot = IERC20(zingot);
    _backend = 0xeb862fF4b8104d4BAe22427367A9a3A16694B486;
    _oldPayout = ZingotPayout(oldPayout);
    _salary = [2 ether, 4 ether, 6 ether, 8 ether, 12 ether, 18 ether, 24 ether, 36 ether, 50 ether];
    __ERC2771Context_init(forwarder);
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  receive() external payable {}

  function _msgSender() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (address ret) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (bytes calldata ret) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _getMessageHash(uint rank, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(rank, timestamp))); 
  }

  function _getMessage(uint rank, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(rank, timestamp, _msgSender()));
  }

  function _recover(address signer, uint rank, uint timestamp, bytes memory signature) internal view returns(bool) {
    bytes32 hash = _getMessageHash(rank, timestamp);
    return SignatureCheckerUpgradeable.isValidSignatureNow(signer, hash, signature);
  }

  function viewClaimable(uint dojiID, uint rank) view public returns (uint) {
    uint toPay;
    uint dojiSalary;
    uint timeSinceMint;
    uint zingotPerSec;
    dojiSalary = _salary[rank - 1];
    timeSinceMint = block.timestamp - 1632439986;
    zingotPerSec = dojiSalary / 86400000;
    (,uint paidOld) = _oldPayout.idToDoji(dojiID);
    uint paid = paidOld + idToDoji[dojiID].paid;
    toPay = paid > timeSinceMint * zingotPerSec * 1000 ? 0 : timeSinceMint * zingotPerSec * 1000 - paid;
    return toPay;
  }

  function viewClaimables(uint[] memory dojiIDs, uint[] memory ranks) view public returns (uint) {
    require(dojiIDs.length > 0 && ranks.length > 0 && dojiIDs.length == ranks.length, "Bad parameters");
    uint totalAmount;
    for (uint256 index = 0; index < dojiIDs.length; index++) {
     totalAmount += viewClaimable(dojiIDs[index], ranks[index]);
    }
    return totalAmount;
  }

  function _computeAmount(uint dojiID) internal returns(uint) {
    uint dojiSalary = _salary[idToDoji[dojiID].rank - 1];
    uint timeSinceMint = block.timestamp - 1632439986;
    uint zingotPerSec = dojiSalary / 86400000;
    (,uint paidOld) = _oldPayout.idToDoji(dojiID);
    uint paid = paidOld + idToDoji[dojiID].paid;
    uint toPay = paid > timeSinceMint * zingotPerSec * 1000 ? 0 : timeSinceMint * zingotPerSec * 1000 - paid;
    idToDoji[dojiID].paid += toPay; 
    return toPay;
  }

  function claim(uint[] calldata dojiID, uint[] calldata ranks, uint timestamp, bytes memory signature) public whenNotPaused nonReentrant {
    require(dojiID.length > 0 && ranks.length > 0 && dojiID.length == ranks.length, "Bad parameters");
    require(_recover(_backend, ranks[0], timestamp, signature), "Wrong signature");
    require(timestamp / 1000 >= (block.timestamp - 2.5 minutes) && timestamp / 1000 <= (block.timestamp + 2.5 minutes) , "Timestamp invalid, a signature is valid 5 minutes");
    uint totalAmount = 0;
    for (uint256 index = 0; index < dojiID.length; index++) {
      if(idToDoji[dojiID[index]].rank == 0) {
        idToDoji[dojiID[index]].rank = ranks[index];
      }
      totalAmount += _computeAmount(dojiID[index]); 
    }
    _zingot.transfer(_msgSender(), totalAmount);
  }

  function rescueEther() public onlyOwner {
    uint256 currentBalance = address(this).balance;
    (bool sent, ) = address(_msgSender()).call{value: currentBalance}('');
    require(sent,"Error while transfering the eth");    
  }

  function rescueZingot(uint amount) public onlyOwner {
    require(_zingot.balanceOf(address(this)) >= amount);
    _zingot.transfer(_msgSender(), amount); 
  }

  function fixPaid(uint dojiID, uint newPaid) public onlyOwner {
    idToDoji[dojiID].paid = newPaid;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271Upgradeable.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface Floot721 is IERC721EnumerableUpgradeable {
    function walletInventory(address _owner) external view returns (uint256[] memory);
}

contract FLOOTClaimsProxy is Initializable, ERC721HolderUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    event Received(address, uint256);
    event LuckyFuck(uint256, address);
    event ChosenFuck(uint256, address);

    uint256 public currentFloots;
    bool public halt;
    Floot721 public floot;
    PayoutInfo[] public payoutInfo; // keeps track of payout deets
    //NFTClaimInfo[] public nftClaimInfo;
    struct FlootIDinfo {
        uint256 tokenID;        // ID of FLOOT token
        uint256 rewardDebt;     // amount the ID is NOT entitled to (ie previous distros and claimed distros)
        uint256 pending;
        uint256 paidOut;        // amount paid out to ID
        bool tracked;
    }
    struct PayoutInfo {
        address payoutToken;        // Address of LP token contract.
        uint256 balance;            // total amount of payout in contract
        uint256 pending;            // pending payouts
        uint256 distroPerFloot;     // amount each FLOOT is entitled to
        uint256 paidOut;            // total paid out to FLOOTs
    }
    struct NFTClaimInfo {
        address nftContract;
        uint256 tokenID;
        uint256 luckyFuck;
        bool claimed;
    }
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;
    mapping (uint256 => mapping (uint256 => FlootIDinfo)) public flootIDinfo;     // keeps track of pending and claim rewards
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address _floot) public initializer {
        __Ownable_init();
        __ERC721Holder_init();
        __UUPSUpgradeable_init();
        floot = Floot721(_floot);
        halt = false;
        addPayoutPool(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        updateNewHolders(floot.totalSupply(),0);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    receive() external payable {
        require(floot.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenID,
        bytes memory data
    ) public virtual override returns (bytes4) {

        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0){
            random721(msg.sender, tokenID);
        }
        return this.onERC721Received.selector;
    }

    function random721(address nftContract, uint256 tokenID) internal {
        // updatePayout(0);
        
        uint256 luckyFuck = pickLuckyFuck();
        
        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,luckyFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[luckyFuck].push(newClaim);

        emit LuckyFuck(luckyFuck, nftContract);
    }

    function send721(address nftContract, uint256 tokenID, uint256 chosenFuck) public {
        ERC721Upgradeable(nftContract).safeTransferFrom(msg.sender, address(this), tokenID, 'true');

        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,chosenFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[chosenFuck].push(newClaim);

        emit ChosenFuck(chosenFuck, nftContract);
    }

    function pickLuckyFuck() internal view returns (uint) {
        uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, currentFloots)));
        return (rando % currentFloots) + 1;
    }
    
    function fundEther() external payable {
        require(floot.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }
    
    function ethBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function updatePayout(uint256 _pid) public {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();
        require(flootSupply > 0, "No one owns Floot yet");
        uint256 totalDebt;
        uint256 newFloots;
        
        if(flootSupply > currentFloots){
            newFloots = flootSupply - currentFloots;
            updateNewHolders(newFloots, _pid);
        }
        
        uint256 totalPaidOut;

        uint256 currentBalance;

        for (uint256 tokenIndex = 0; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            totalPaidOut += flootIDinfo[_pid][tokenID].paidOut;
            totalDebt += flootIDinfo[_pid][tokenID].rewardDebt;
        }

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20Upgradeable(payout.payoutToken).balanceOf(address(this));
        }

        uint256 totalDistro = currentBalance + totalPaidOut + totalDebt;
        payout.distroPerFloot = totalDistro * 1000 / flootSupply;
        payout.balance = totalDistro;
    }
    
    function updateNewHolders(uint256 newFloots, uint256 _pid) internal {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();

        for (uint256 tokenIndex = currentFloots; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            flootIDinfo[_pid][tokenID].rewardDebt = payout.distroPerFloot / 1000;
            flootIDinfo[_pid][tokenID].tracked = true;
        }
        
        currentFloots += newFloots;
    }

    function claimNFTsPending(uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        NFTClaimInfo[] storage luckyFloot = nftClaimInfo[_tokenID];

        for (uint256 index = 0; index < luckyFloot.length; index++) {
            if(!luckyFloot[index].claimed){
                luckyFloot[index].claimed = true;
                ERC721Upgradeable(luckyFloot[index].nftContract).safeTransferFrom(address(this),msg.sender,luckyFloot[index].tokenID);
            }
        }
    }

    function claimOneNFTPending(uint256 _tokenID, address _nftContract, uint256 _nftId) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        NFTClaimInfo[] storage luckyFloot = nftClaimInfo[_tokenID];

        for (uint256 index = 0; index < luckyFloot.length; index++) {
            if(!luckyFloot[index].claimed && luckyFloot[index].nftContract == _nftContract && luckyFloot[index].tokenID == _nftId){
                luckyFloot[index].claimed = true;
                ERC721Upgradeable(luckyFloot[index].nftContract).safeTransferFrom(address(this),msg.sender,luckyFloot[index].tokenID);
            }
        }
    }

    function claimAcctPending(uint256 _pid) public {
        require(!halt, 'Claims temporarily unavailable');
        updatePayout(_pid);
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256[] memory userInventory = floot.walletInventory(msg.sender);
        require(userInventory.length > 0);
        uint256 pending = payout.distroPerFloot * userInventory.length / 1000;
        uint256 payoutPerTokenID;
        uint256 paidout;
        uint256 rewardDebt;

        uint256 claimAmount;

        // get payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            paidout += flootIDinfo[_pid][userInventory[index]].paidOut;
            rewardDebt += flootIDinfo[_pid][userInventory[index]].rewardDebt;
        }

        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt;
            payoutPerTokenID = claimAmount / userInventory.length; }
        else {
            return; 
        }

        // add new payout to each tokenID's paid balance 
        for (uint256 index = 0; index < userInventory.length; index++) {
            flootIDinfo[_pid][userInventory[index]].paidOut += payoutPerTokenID; }

        payout.paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20Upgradeable(payout.payoutToken).safeTransfer(msg.sender, claimAmount); }
        
        
        //updatePayout(_pid);
    }

    function claimTokenPending(uint256 _pid, uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender);
        
        updatePayout(_pid);
        
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_tokenID].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_tokenID].rewardDebt;

        uint256 claimAmount;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt; }
        else{ return; }

        // add new payout to each tokenID's paid balance 
        flootIDinfo[_pid][_tokenID].paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20Upgradeable(payout.payoutToken).safeTransfer(msg.sender, claimAmount); }
        
        payout.paidOut += claimAmount;
        //updatePayout(_pid);
    }

    function viewNFTsPending(uint _tokenID) public view returns(NFTClaimInfo[] memory){
        return nftClaimInfo[_tokenID];
    }
    
    function viewAcctPending(uint256 _pid, address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;
        
        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            pending += viewTokenPending(_pid,userInventory[index]);
        }
        
        return pending;
    }
    
    function viewTokenPending(uint256 _pid, uint256 _id) public view returns(uint256){
        PayoutInfo storage payout = payoutInfo[_pid];
        if(!flootIDinfo[_pid][_id].tracked){
            return 0;
        }
        //uint256 pending = viewLatestClaimAmount(_pid) / 1000;
        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_id].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_id].rewardDebt;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            return pending - paidout - rewardDebt; }
        else {
            return 0; 
        }
    }

    function viewNumberNftPending(address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;

        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            for(uint256 j = 0; j < nftClaimInfo[userInventory[index]].length; j++) {
                if (nftClaimInfo[userInventory[index]][j].claimed == false) {
                    pending++;
                }
            }
        }
        return pending;
    }

    function addPayoutPool(address _payoutToken) public onlyOwner {
        payoutInfo.push(PayoutInfo({
            payoutToken: _payoutToken,
            balance: 0,
            pending: 0,
            distroPerFloot: 0,
            paidOut: 0
        }));
        for (uint256 tokenIndex = 0; tokenIndex < floot.totalSupply(); tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            flootIDinfo[payoutInfo.length - 1][tokenID].tracked = true;
        }
    }

    function rescueTokens(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20Upgradeable(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }
    
    function rescueTokens2(address _recipient, IERC20Upgradeable _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        _ERC20address.safeTransfer(_recipient, _amount); //use of the _ERC20 safetransfer
        return true;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function changeFloot(address _newFloot) public onlyOwner {
        floot = Floot721(_newFloot);
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }

    function payoutPoolLength() public view returns(uint) {
        return payoutInfo.length;
    }

    function depositERC20(uint _pid, IERC20Upgradeable _tokenAddress, uint _amount) public {
        require(payoutInfo[_pid].payoutToken == address(_tokenAddress));
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _amount);
        updatePayout(_pid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface Floot721 is IERC721EnumerableUpgradeable {
    function walletInventory(address _owner) external view returns (uint256[] memory);
}

contract CrewCoinVault is Initializable, ERC721HolderUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    event Received(address, uint256);
    event LuckyFuck(uint256, address);
    event ChosenFuck(uint256, address);

    uint256 public currentFloots;
    bool public halt;
    Floot721 public floot;
    PayoutInfo[] public payoutInfo; // keeps track of payout deets
    //NFTClaimInfo[] public nftClaimInfo;
    struct FlootIDinfo {
        uint256 tokenID;        // ID of FLOOT token
        uint256 rewardDebt;     // amount the ID is NOT entitled to (ie previous distros and claimed distros)
        uint256 pending;
        uint256 paidOut;        // amount paid out to ID
        bool tracked;
    }
    struct PayoutInfo {
        address payoutToken;        // Address of LP token contract.
        uint256 balance;            // total amount of payout in contract
        uint256 pending;            // pending payouts
        uint256 distroPerFloot;     // amount each FLOOT is entitled to
        uint256 paidOut;            // total paid out to FLOOTs
    }
    struct NFTClaimInfo {
        address nftContract;
        uint256 tokenID;
        uint256 luckyFuck;
        bool claimed;
    }
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;
    mapping (uint256 => mapping (uint256 => FlootIDinfo)) public flootIDinfo;     // keeps track of pending and claim rewards
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address _floot) public initializer {
        __Ownable_init();
        __ERC721Holder_init();
        __UUPSUpgradeable_init();
        floot = Floot721(_floot);
        halt = false;
        addPayoutPool(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        updateNewHolders(floot.totalSupply(),0);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    receive() external payable {
        require(floot.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenID,
        bytes memory data
    ) public virtual override returns (bytes4) {

        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0){
            random721(msg.sender, tokenID);
        }
        return this.onERC721Received.selector;
    }

    function random721(address nftContract, uint256 tokenID) internal {
        // updatePayout(0);
        
        uint256 luckyFuck = pickLuckyFuck();
        
        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,luckyFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[luckyFuck].push(newClaim);

        emit LuckyFuck(luckyFuck, nftContract);
    }

    function send721(address nftContract, uint256 tokenID, uint256 chosenFuck) public {
        ERC721Upgradeable(nftContract).safeTransferFrom(msg.sender, address(this), tokenID, 'true');

        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,chosenFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[chosenFuck].push(newClaim);

        emit ChosenFuck(chosenFuck, nftContract);
    }

    function pickLuckyFuck() internal view returns (uint) {
        uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, currentFloots)));
        return (rando % currentFloots) + 1;
    }
    
    function fundEther() external payable {
        require(floot.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }
    
    function ethBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function updatePayout(uint256 _pid) public {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();
        require(flootSupply > 0, "No one owns Floot yet");
        uint256 totalDebt;
        uint256 newFloots;
        
        if(flootSupply > currentFloots){
            newFloots = flootSupply - currentFloots;
            updateNewHolders(newFloots, _pid);
        }
        
        uint256 totalPaidOut;

        uint256 currentBalance;

        for (uint256 tokenIndex = 0; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            totalPaidOut += flootIDinfo[_pid][tokenID].paidOut;
            totalDebt += flootIDinfo[_pid][tokenID].rewardDebt;
        }

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20Upgradeable(payout.payoutToken).balanceOf(address(this));
        }

        uint256 totalDistro = currentBalance + totalPaidOut + totalDebt;
        payout.distroPerFloot = totalDistro * 1000 / flootSupply;
        payout.balance = totalDistro;
    }
    
    function updateNewHolders(uint256 newFloots, uint256 _pid) internal {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();

        for (uint256 tokenIndex = currentFloots; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            flootIDinfo[_pid][tokenID].rewardDebt = payout.distroPerFloot / 1000;
            flootIDinfo[_pid][tokenID].tracked = true;
        }
        
        currentFloots += newFloots;
    }

    function claimNFTsPending(uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        NFTClaimInfo[] storage luckyFloot = nftClaimInfo[_tokenID];

        for (uint256 index = 0; index < luckyFloot.length; index++) {
            if(!luckyFloot[index].claimed){
                luckyFloot[index].claimed = true;
                ERC721Upgradeable(luckyFloot[index].nftContract).safeTransferFrom(address(this),msg.sender,luckyFloot[index].tokenID);
            }
        }
    }

    function claimOneNFTPending(uint256 _tokenID, address _nftContract, uint256 _nftId) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        NFTClaimInfo[] storage luckyFloot = nftClaimInfo[_tokenID];

        for (uint256 index = 0; index < luckyFloot.length; index++) {
            if(!luckyFloot[index].claimed && luckyFloot[index].nftContract == _nftContract && luckyFloot[index].tokenID == _nftId){
                luckyFloot[index].claimed = true;
                ERC721Upgradeable(luckyFloot[index].nftContract).safeTransferFrom(address(this),msg.sender,luckyFloot[index].tokenID);
            }
        }
    }

    function claimAcctPending(uint256 _pid) public {
        require(!halt, 'Claims temporarily unavailable');
        updatePayout(_pid);
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256[] memory userInventory = floot.walletInventory(msg.sender);
        require(userInventory.length > 0);
        uint256 pending = payout.distroPerFloot * userInventory.length / 1000;
        uint256 payoutPerTokenID;
        uint256 paidout;
        uint256 rewardDebt;

        uint256 claimAmount;

        // get payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            paidout += flootIDinfo[_pid][userInventory[index]].paidOut;
            rewardDebt += flootIDinfo[_pid][userInventory[index]].rewardDebt;
        }

        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt;
            payoutPerTokenID = claimAmount / userInventory.length; }
        else {
            return; 
        }

        // add new payout to each tokenID's paid balance 
        for (uint256 index = 0; index < userInventory.length; index++) {
            flootIDinfo[_pid][userInventory[index]].paidOut += payoutPerTokenID; }

        payout.paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20Upgradeable(payout.payoutToken).safeTransfer(msg.sender, claimAmount); }
        
        
        //updatePayout(_pid);
    }

    function claimTokenPending(uint256 _pid, uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender);
        
        updatePayout(_pid);
        
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_tokenID].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_tokenID].rewardDebt;

        uint256 claimAmount;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt; }
        else{ return; }

        // add new payout to each tokenID's paid balance 
        flootIDinfo[_pid][_tokenID].paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20Upgradeable(payout.payoutToken).safeTransfer(msg.sender, claimAmount); }
        
        payout.paidOut += claimAmount;
        //updatePayout(_pid);
    }

    function viewNFTsPending(uint _tokenID) public view returns(NFTClaimInfo[] memory){
        return nftClaimInfo[_tokenID];
    }
    
    function viewAcctPending(uint256 _pid, address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;
        
        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            pending += viewTokenPending(_pid,userInventory[index]);
        }
        
        return pending;
    }
    
    function viewTokenPending(uint256 _pid, uint256 _id) public view returns(uint256){
        PayoutInfo storage payout = payoutInfo[_pid];
        if(!flootIDinfo[_pid][_id].tracked){
            return 0;
        }
        //uint256 pending = viewLatestClaimAmount(_pid) / 1000;
        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_id].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_id].rewardDebt;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            return pending - paidout - rewardDebt; }
        else {
            return 0; 
        }
    }

    function viewNumberNftPending(address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;

        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            for(uint256 j = 0; j < nftClaimInfo[userInventory[index]].length; j++) {
                if (nftClaimInfo[userInventory[index]][j].claimed == false) {
                    pending++;
                }
            }
        }
        return pending;
    }

    function addPayoutPool(address _payoutToken) public onlyOwner {
        payoutInfo.push(PayoutInfo({
            payoutToken: _payoutToken,
            balance: 0,
            pending: 0,
            distroPerFloot: 0,
            paidOut: 0
        }));
        for (uint256 tokenIndex = 0; tokenIndex < floot.totalSupply(); tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            flootIDinfo[payoutInfo.length - 1][tokenID].tracked = true;
        }
    }

    function rescueTokens(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20Upgradeable(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }
    
    function rescueTokens2(address _recipient, IERC20Upgradeable _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        _ERC20address.safeTransfer(_recipient, _amount); //use of the _ERC20 safetransfer
        return true;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function changeFloot(address _newFloot) public onlyOwner {
        floot = Floot721(_newFloot);
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }

    function payoutPoolLength() public view returns(uint) {
        return payoutInfo.length;
    }

    function depositERC20(uint _pid, IERC20Upgradeable _tokenAddress, uint _amount) public {
        require(payoutInfo[_pid].payoutToken == address(_tokenAddress));
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _amount);
        updatePayout(_pid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./DojiERC721Acc.sol";
import "./DojiERC1155Acc.sol";
import "hardhat/console.sol";


interface BaseToken is IERC721EnumerableUpgradeable {
    function walletInventory(address _owner) external view returns (uint256[] memory);
}

contract DojiClaimsProxy is Initializable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    event Received(address, uint256);

    bool public halt;
    Doji721Accounting NFT721accounting;
    Doji1155Accounting NFT1155accounting;
    BaseToken public baseToken;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address _baseToken, address _NFT721accounting, address _NFT1155accounting) public initializer {
      __Ownable_init();
      __ERC721Holder_init();
      __ERC1155Holder_init();
      __UUPSUpgradeable_init();
      baseToken = BaseToken(_baseToken);
      NFT721accounting = Doji721Accounting(_NFT721accounting);
      NFT1155accounting = Doji1155Accounting(_NFT1155accounting);
      halt = false;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    receive() external payable {
        require(baseToken.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
    }

    function change1155accounting(address _address) public onlyOwner {
        NFT1155accounting = Doji1155Accounting(_address);
    }

    function change721accounting(address _address) public onlyOwner {
        NFT721accounting = Doji721Accounting(_address);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenID,
        bytes memory data
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0){
          NFT721accounting.random721(msg.sender, tokenID);
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256 tokenID,
        uint256 _amount,
        bytes memory data
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0) {
          NFT1155accounting.random1155(msg.sender, tokenID, _amount);
        }
        return this.onERC1155Received.selector;
    }

    function _currentBaseTokensHolder() view external returns (uint) {
        return baseToken.totalSupply();
    }

    function _baseTokenAddress() view external returns (address) {
        return address(baseToken);
    }

    function claimNFTsPending(uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(baseToken.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");
      
        uint length = NFT721accounting.viewNumberNFTsPending(_tokenID);

        for (uint256 index = 0; index < length; index++) {
          Doji721Accounting.NFTClaimInfo memory luckyBaseToken = NFT721accounting.viewNFTsPendingByIndex(_tokenID, index);
            if(!luckyBaseToken.claimed){
                NFT721accounting.claimNft(_tokenID, index);
                ERC721Upgradeable(luckyBaseToken.nftContract)
                  .safeTransferFrom(address(this), msg.sender, luckyBaseToken.tokenID);
            }
        }
    }

    function claimOneNFTPending(uint256 _tokenID, address _nftContract, uint256 _nftId) public {
        require(!halt, 'Claims temporarily unavailable');
        require(baseToken.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        uint length = NFT721accounting.viewNumberNFTsPending(_tokenID);

        for (uint256 index = 0; index < length; index++) {
          Doji721Accounting.NFTClaimInfo memory luckyBaseToken = NFT721accounting.viewNFTsPendingByIndex(_tokenID, index);
            if(!luckyBaseToken.claimed && luckyBaseToken.nftContract == _nftContract && luckyBaseToken.tokenID == _nftId){
                NFT721accounting.claimNft(_tokenID, index);
                ERC721Upgradeable(luckyBaseToken.nftContract)
                  .safeTransferFrom(address(this), msg.sender, luckyBaseToken.tokenID);
            }
        }
    }

    function claimOne1155Pending(uint256 DojiID, address _contract, uint256 tokenID, uint _amount) public {
        require(!halt, 'Claims temporarily unavailable');
        require(baseToken.ownerOf(DojiID) == msg.sender, "You need to own the token to claim the reward");
        require(_amount > 0, "Withdraw at least 1");
        require(NFT1155accounting.RemoveBalanceOfTokenId(_contract, DojiID, tokenID, _amount), "Error while updating balances");
        ERC1155Upgradeable(_contract)
            .safeTransferFrom(address(this), msg.sender, tokenID, _amount, "");
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function changeBaseToken(address _newBaseToken) public onlyOwner {
        baseToken = BaseToken(_newBaseToken);
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }
}
interface AirdropGrapesToken {
    function claimTokens() external;
}

contract DojiClaimV2 is DojiClaimsProxy {
    //solhint-disable-next-line

    function claimApeCoin() external onlyOwner {
        AirdropGrapesToken(0x025C6da5BD0e6A5dd1350fda9e3B6a614B205a1F).claimTokens();
        uint balance = ERC20Upgradeable(0x4d224452801ACEd8B2F0aebE155379bb5D594381).balanceOf(address(this));
        ERC20Upgradeable(0x4d224452801ACEd8B2F0aebE155379bb5D594381).transfer(0x32B7f655B94E30975f98dA13d6cF31f0479c3802, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "hardhat/console.sol";
import "./DojiCourrier.sol";

contract Doji721Accounting is Ownable {
    event LuckyHolder(uint256 indexed luckyHolder, address indexed sender);
    event ChosenHolder(uint256 indexed chosenHolder, address indexed sender);

    DojiClaimsProxy claimContract;

    struct NFTClaimInfo {
      address nftContract;
      uint256 tokenID;
      uint256 holder;
      bool claimed;
    }
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;

    constructor(){
    }

    modifier onlyClaimContract() { // Modifier
        require(
            msg.sender == address(claimContract),
            "Only Claim contract can call this."
        );
        _;
    }

  function random721(address nftContract, uint256 tokenID) external onlyClaimContract {
    uint256 luckyFuck = pickLuckyHolder();
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, luckyFuck, false);
    nftClaimInfo[luckyFuck].push(newClaim);
    emit LuckyHolder(luckyFuck, nftContract);
  }

  function send721(address nftContract, uint256 tokenID, uint256 chosenHolder) public {
    require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
    ERC721(nftContract).safeTransferFrom(msg.sender,address(claimContract),tokenID, 'true');
    NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract, tokenID, chosenHolder, false);
    nftClaimInfo[chosenHolder].push(newClaim);
    emit ChosenHolder(chosenHolder, nftContract);
  }

	function pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, claimContract._currentBaseTokensHolder())));
		uint index = (rando % claimContract._currentBaseTokensHolder());
		uint result = IERC721Enumerable(claimContract._baseTokenAddress()).tokenByIndex(index);
		return result;
	}

    function viewNFTsPending(uint ID)view external returns (NFTClaimInfo[] memory) {
      return nftClaimInfo[ID];
    }

    function viewNFTsPendingByIndex(uint ID, uint index)view external returns (NFTClaimInfo memory) {
      return nftClaimInfo[ID][index];
    }

    function viewNumberNFTsPending(uint ID) view external returns (uint) {
      return nftClaimInfo[ID].length;
    }

    function viewNumberNFTsPendingByAcc(address account) public view returns(uint256){
      BaseToken baseToken = BaseToken(claimContract._baseTokenAddress());
      uint256[] memory userInventory = baseToken.walletInventory(account);
      uint256 pending;

      // get pending payouts for all tokenIDs in caller's wallet
      for (uint256 index = 0; index < userInventory.length; index++) {
          for(uint256 j = 0; j < nftClaimInfo[userInventory[index]].length; j++) {
              if (nftClaimInfo[userInventory[index]][j].claimed == false) {
                  pending++;
              }
          }
      }
      return pending;
    }

    function claimNft(uint ID, uint index) external onlyClaimContract {
      require(msg.sender == address(claimContract));
      nftClaimInfo[ID][index].claimed = true;
    }

    function setClaimProxy (address proxy) public onlyOwner {
      claimContract = DojiClaimsProxy(payable(proxy));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./DojiCourrier.sol";
import "hardhat/console.sol";

contract Doji1155Accounting is Ownable{
	event LuckyHolder1155(uint256 indexed luckyHolder, address indexed sender, uint, uint);
	event ChosenHolder1155(uint256 indexed chosenHolder, address indexed sender, uint, uint);
	//solhint-disable-next-line
	DojiClaimsProxy claimContract;
		struct TokenIDClaimInfo {
			uint index;
			uint balance;
		}

    struct NFTClaimInfo {
			uint index;
			uint[] tokenID;
			//solhint-disable-next-line
      mapping(uint => TokenIDClaimInfo) ClaimTokenStruct;
    }

		struct ContractInfo {
			address[] contractIndex;
			//solhint-disable-next-line
			mapping(address => NFTClaimInfo) ContractInfos;
		}
		//solhint-disable-next-line
    mapping (uint256 => ContractInfo) private UserInventory;
		
	constructor(){}

	modifier onlyClaimContract() { // Modifier
		require(
			msg.sender == address(claimContract),
			"Only Claim contract can call this."
		);
		_;
	}

	//solhint-disable-next-line
	function isContractForUser(address _contract, uint DojiID) public view returns(bool) {
		if (UserInventory[DojiID].contractIndex.length == 0) return false;
		return (UserInventory[DojiID].contractIndex[UserInventory[DojiID].ContractInfos[_contract].index] == _contract);
	}

	//solhint-disable-next-line
	function isTokenIDForContractForUser(address _contract, uint DojiID, uint tokenID) public view returns(bool) {
		if (UserInventory[DojiID].ContractInfos[_contract].tokenID.length == 0) return false;
		return (
			UserInventory[DojiID].ContractInfos[_contract]
				.tokenID[ UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].index ] == tokenID
		);
	}
	
	function insertContractForUser (
		address _contract,
		//solhint-disable-next-line
		uint DojiID,
    uint tokenID, 
    uint balance
	) 
    public
    returns(uint index)
  {
    require(!isContractForUser(_contract, DojiID), "Contract already exist"); 
		UserInventory[DojiID].contractIndex.push(_contract);
    UserInventory[DojiID].ContractInfos[_contract].index = UserInventory[DojiID].contractIndex.length - 1;
		if (!isTokenIDForContractForUser(_contract, DojiID, tokenID)){
			UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].balance = balance;
			UserInventory[DojiID].ContractInfos[_contract].tokenID.push(tokenID);
    	UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].index = UserInventory[DojiID].ContractInfos[_contract].tokenID.length - 1;
		}
    return UserInventory[DojiID].contractIndex.length-1;
  }

	//solhint-disable-next-line
	function addBalanceOfTokenId(address _contract, uint DojiID, uint tokenID, uint _amount) 
    private
    returns(bool success) 
  {
    require(isContractForUser(_contract, DojiID), "Contract doesn't exist");
		if (!isTokenIDForContractForUser(_contract, DojiID, tokenID)) {
			UserInventory[DojiID].ContractInfos[_contract].tokenID.push(tokenID);
    	UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].index = UserInventory[DojiID].ContractInfos[_contract].tokenID.length - 1;
		}
    if (UserInventory[DojiID].ContractInfos[_contract].ClaimTokenStruct[tokenID].balance == 0) {
			UserInventory[DojiID]
			.ContractInfos[_contract]
			.ClaimTokenStruct[tokenID].balance = _amount;
		} else {
			UserInventory[DojiID]
				.ContractInfos[_contract]
				.ClaimTokenStruct[tokenID].balance += _amount;
		}
    return true;
  }
	//solhint-disable-next-line
	function RemoveBalanceOfTokenId(address _contract, uint DojiID, uint tokenID, uint _amount) 
    public onlyClaimContract
    returns(bool success) 
  {
    require(isContractForUser(_contract, DojiID), "Contract doesn't exist"); 
		require(isTokenIDForContractForUser(_contract, DojiID, tokenID));
		UserInventory[DojiID]
			.ContractInfos[_contract]
			.ClaimTokenStruct[tokenID].balance -= _amount;
    return true;
  }

	//solhint-disable-next-line
	function getTokenBalanceByID(address _contract, uint DojiID, uint tokenID) public view returns(uint){
		return UserInventory[DojiID]
			.ContractInfos[_contract]
			.ClaimTokenStruct[tokenID].balance;
	}

	//solhint-disable-next-line
	function getTokenIDCount(address _contract, uint DojiID) public view returns(uint){
		return UserInventory[DojiID]
			.ContractInfos[_contract].tokenID.length;
	}

	//solhint-disable-next-line
	function getTokenIDByIndex(address _contract, uint DojiID, uint index) public view returns(uint){
		return UserInventory[DojiID]
			.ContractInfos[_contract].tokenID[index];
	}

	//solhint-disable-next-line
	function getContractAddressCount(uint DojiID) public view returns(uint){
		return UserInventory[DojiID].contractIndex.length;
	}

	//solhint-disable-next-line
	function getContractAddressByIndex(uint DojiID, uint index) public view returns(address){
		return UserInventory[DojiID].contractIndex[index];
	}

	function random1155(address _contract, uint tokenID, uint _amount) external onlyClaimContract {
	  require(_amount > 0);
	  uint256 luckyFuck = pickLuckyHolder();
		if (isContractForUser(_contract, luckyFuck)) {
			addBalanceOfTokenId(_contract, luckyFuck, tokenID,  _amount);
		} else {
			insertContractForUser (_contract, luckyFuck, tokenID, _amount);
		}
	  emit LuckyHolder1155(luckyFuck, msg.sender, tokenID, _amount);
	}

	function send1155(address _contract, uint tokenID, uint _amount, uint256 chosenHolder) public {
		require(_amount > 0);
		require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
		if (isContractForUser(_contract, chosenHolder)) {
			addBalanceOfTokenId(_contract, chosenHolder, tokenID, _amount);
		} else {
			insertContractForUser (_contract, chosenHolder, tokenID, _amount);
		}
		ERC1155(_contract).safeTransferFrom(msg.sender,  address(claimContract), tokenID, _amount, 'true');
		emit ChosenHolder1155(chosenHolder, msg.sender, tokenID, _amount);
	}

	//solhint-disable-next-line
	function pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, claimContract._currentBaseTokensHolder())));
		uint index = (rando % claimContract._currentBaseTokensHolder());
		uint result = IERC721Enumerable(claimContract._baseTokenAddress()).tokenByIndex(index);
		return result;
	}

	function setClaimProxy (address proxy) public onlyOwner {
	  claimContract = DojiClaimsProxy(payable(proxy));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OPbuild is ERC1155 {
    uint256 public constant THORS_HAMMER = 1;
    uint256 public constant GANDALS_STAFF = 2;
    uint256 public constant FROSTMOURNE = 3;
    constructor() ERC1155("") {
      _mint(msg.sender, GANDALS_STAFF, 20, "");
      _mint(msg.sender, THORS_HAMMER, 2, "");
      _mint(msg.sender, FROSTMOURNE, 4, "");
    }

    function setURI(string memory newuri) public {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
    {
        _mintBatch(to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
        ######  #     #  #####      ####### #######  #####  #     # 
        #     # #     # #     #        #    #       #     # #     # 
        #     # #     # #              #    #       #       #     # 
        ######  #     # #  ####        #    #####   #       ####### 
        #   #   #     # #     # ###    #    #       #       #     # 
        #    #  #     # #     # ###    #    #       #     # #     # 
        #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
contract ERC1155YEETH is ERC1155, Ownable, Pausable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Winner (address indexed winner);

    uint256 public maxBatch = 10; 
    uint256 public price = 10 * 10**18; //Mint Price
    string public baseURI = "ipfs://QmPwFhgHthT71SvyE5ao9omdMUYYpBtqnKqxV61ByXNK1X/";
    bool private _started = false;
    uint public lastDistro;
    constructor()
    ERC1155("ipfs://QmPwFhgHthT71SvyE5ao9omdMUYYpBtqnKqxV61ByXNK1X/")
    {
      lastDistro = block.timestamp + 24 hours;
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
    }

    function _distribute() internal {
      uint256 currentBalance = address(this).balance;
      if (findWinner()) {
        emit Winner(_msgSender());
        (bool sent, ) = _msgSender().call{value: currentBalance}('');
        require(sent, "Error while transfering eth");
        lastDistro = block.timestamp;
      }
    }

    function findWinner() public view returns(bool) {
      if (uint(keccak256(abi.encodePacked(_msgSender(), block.timestamp, block.difficulty, block.coinbase))) % 2 == 0) {
        return true;
      }
      return false;
    }

    function claim(uint256 _batchCount) payable public {
        require(_started, "Sale not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch must be between 0 and 11");
        require(msg.value == _batchCount * price, "Wrong value sent");
        _mint(_msgSender(), 1, _batchCount, "0x0");
        if (block.timestamp > lastDistro) {
            _distribute();
        }
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
       if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender



contract Staking is Ownable, ERC721Holder, Pausable, ReentrancyGuard {

  event Claim (address indexed buyer, uint256 tokenID);
  event Paid (address indexed influencer, uint _amount);

  bool private _started = false;

  uint public maxTokenToDistribute = 0;
  uint public rewardRate = 100;
  uint public lastUpdateTime;
  uint public rewardPerTokenStored;
  uint private _totalSupply;

  IERC20 constant _RUGCOIN = IERC20(0xc7F572c19119bA735CA301bc6cA176BC2d2Ad261);
  IERC721 constant _RUGS = IERC721(0x6C94954D0b265F657A4A1B35dfAA8B73D1A3f199);
  IERC721 constant _DRAPES = IERC721(0x9aF0e1748fF32f698847CfAB5013469a37dCdb17);
  IERC721 constant _BLAZED = IERC721(0x8584e7A1817C795f74Ce985a1d13b962758FE3CA);
  IERC721 constant _HEADS = IERC721(0xC6904FB685b4DFbDb98a5B70E40863Cd9AEF33DC);
  IERC721 constant _DOJI = IERC721(0x5e9dC633830Af18AA43dDB7B042646AADEDCCe81);
  IERC721 constant _RECORDS = IERC721(0x153C5091580cB9c3f12F7C1e170743a9af7B774a);
  IERC721 constant _INFLUENZAS = IERC721(0xaf76c7B002a3b7F062E1a19248B0579C52EeBE4A);
  // IERC20 constant _ZINGOT = IERC20(0x8dEeFeBd24EF87e3F7aEf2057a002a8E91837801);

  struct Stackers {
    uint userRewardPerTokenPaid;
    uint rewards;
    uint balances;
  }

  mapping(address => Stackers) _addrToStackers;


  constructor() {
    transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
  }
  receive() external payable {}

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
  function rewardPerToken() public view returns (uint) {
    if (_totalSupply == 0) {
        return 0;
    }
    return
        rewardPerTokenStored +
        (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
  }

  function earned(address account) public view returns (uint) {
    return
        ((_addrToStackers[account].balances *
            (rewardPerToken() - _addrToStackers[account].userRewardPerTokenPaid)) / 1e18) +
        _addrToStackers[account].rewards;
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = block.timestamp;

    _addrToStackers[account].rewards = earned(account);
    _addrToStackers[account].userRewardPerTokenPaid = rewardPerTokenStored;
    _;
  }

  function stake(uint _amount) external updateReward(msg.sender) {
      _totalSupply += _amount;
      _addrToStackers[msg.sender].balances += _amount;
      // stakingToken.transferFrom(msg.sender, address(this), _amount);
  }

  function withdraw(uint _amount) external updateReward(msg.sender) {
      _totalSupply -= _amount;
      _addrToStackers[msg.sender].balances -= _amount;
      // stakingToken.transfer(msg.sender, _amount);
  }

  function getReward() external updateReward(msg.sender) {
      uint reward = _addrToStackers[msg.sender].rewards;
      _addrToStackers[msg.sender].rewards = 0;
      _RUGCOIN.transfer(msg.sender, reward);
  }
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
pragma solidity ^0.8.0;

/*
        ######  #     #  #####      ####### #######  #####  #     # 
        #     # #     # #     #        #    #       #     # #     # 
        #     # #     # #              #    #       #       #     # 
        ######  #     # #  ####        #    #####   #       ####### 
        #   #   #     # #     # ###    #    #       #       #     # 
        #    #  #     # #     # ###    #    #       #     # #     # 
        #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
contract YEETHMatic is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Winner (address indexed winner);
    event YEETHBURN ();

    uint256 public totalCount = 10000;
    uint256 public maxBatch = 10; 
    uint256 public price = 10 * 10**18; //Mint Price
    string public baseURI = "ipfs://QmPwFhgHthT71SvyE5ao9omdMUYYpBtqnKqxV61ByXNK1X/";
    bool private _started = false;
    uint public endDate = 0;

    constructor()
    ERC721("YEETH", "YEETH")
    {}

    receive() external payable {}

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
        endDate = block.timestamp + 72 hours;
    }

    function _destroy() internal {
      require(endDate != 0);
      require(block.timestamp > endDate);
      require(totalSupply() < totalCount);
      uint256 currentBalance = address(this).balance;
      (bool sent, ) = address(0x000000000000000000000000000000000000dEaD).call{value: currentBalance}('');
      require(sent, "Error while transfering eth");
      emit YEETHBURN();
    }

    function distribute() public {
      require(endDate != 0);
      require(totalSupply() >= totalCount);
      uint256 currentBalance = address(this).balance;
      address winner = findWinner();
      emit Winner(winner);
      (bool sent, ) = winner.call{value: currentBalance}('');
      require(sent, "Error while transfering eth");   
    }

    function findWinner() public view returns(address) {
      return ownerOf((uint(keccak256(abi.encodePacked(_msgSender(), msg.sig, block.timestamp, block.difficulty, block.coinbase))) % totalCount) + 1);
    }

    function claim(uint256 _batchCount) payable public {
        require(_started, "Sale not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch must be between 0 and 11");
        require(totalSupply() + _batchCount <= totalCount, "Can't mint anymore");
        require(msg.value == _batchCount * price, "Wrong value sent");
        if (block.timestamp > endDate) {
            return _destroy();
        }
        emit Claim(msg.sender, totalSupply(), _batchCount);
        for(uint256 i = 0; i< _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            require(totalSupply() < totalCount);
            emit Claim(_msgSender(), mintID, _batchCount);
            _mint(_msgSender(), mintID);
        }
        if (totalSupply() == totalCount) {
           return distribute();
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        address winner = ownerOf((uint(keccak256(abi.encodePacked(_msgSender(), msg.sig, block.timestamp, block.difficulty, block.coinbase))) % totalSupply()) + 1);
        (bool sent, ) = winner.call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply()) < totalCount);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
        ######  #     #  #####      ####### #######  #####  #     # 
        #     # #     # #     #        #    #       #     # #     # 
        #     # #     # #              #    #       #       #     # 
        ######  #     # #  ####        #    #####   #       ####### 
        #   #   #     # #     # ###    #    #       #       #     # 
        #    #  #     # #     # ###    #    #       #     # #     # 
        #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
contract YEETH is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Winner (address indexed winner);
    event YEETHBURN ();

    uint256 public totalCount = 10000;
    uint256 public maxBatch = 10; 
    uint256 public price = 0.01 * 10**18; //Mint Price
    string public baseURI = "ipfs://QmPwFhgHthT71SvyE5ao9omdMUYYpBtqnKqxV61ByXNK1X/";
    bool private _started = false;
    uint public endDate = 0;

    constructor()
    ERC721("YEETH", "YEETH")
    {}

    receive() external payable {}

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
        endDate = block.timestamp + 72 hours;
    }

    function _destroy() internal {
      require(endDate != 0);
      require(block.timestamp > endDate);
      require(totalSupply() < totalCount);
      uint256 currentBalance = address(this).balance;
      (bool sent, ) = address(0x000000000000000000000000000000000000dEaD).call{value: currentBalance}('');
      require(sent, "Error while transfering eth");
      emit YEETHBURN();
    }

    function distribute() public {
      require(endDate != 0);
      require(totalSupply() >= totalCount);
      uint256 currentBalance = address(this).balance;
      address winner = findWinner();
      emit Winner(winner);
      (bool sent, ) = winner.call{value: currentBalance}('');
      require(sent, "Error while transfering eth");   
    }

    function findWinner() public view returns(address) {
      return ownerOf((uint(keccak256(abi.encodePacked(_msgSender(), msg.sig, block.timestamp, block.difficulty, block.coinbase))) % totalCount) + 1);
    }

    function claim(uint256 _batchCount) payable public {
        require(_started, "Sale not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch must be between 0 and 11");
        require(totalSupply() + _batchCount <= totalCount, "Can't mint anymore");
        require(msg.value == _batchCount * price, "Wrong value sent");
        if (block.timestamp > endDate) {
            return _destroy();
        }
        emit Claim(msg.sender, totalSupply(), _batchCount);
        for(uint256 i = 0; i< _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            require(totalSupply() < totalCount);
            emit Claim(_msgSender(), mintID, _batchCount);
            _mint(_msgSender(), mintID);
        }
        if (totalSupply() == totalCount) {
           return distribute();
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        address winner = ownerOf((uint(keccak256(abi.encodePacked(_msgSender(), msg.sig, block.timestamp, block.difficulty, block.coinbase))) % totalSupply()) + 1);
        (bool sent, ) = winner.call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply()) < totalCount);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender

contract Island is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 tokenID);
    event Paid (address indexed influencer, uint _amount);

    uint256 public burnCount;
    uint256 constant public TOTALCOUNT = 10000;
    uint256 constant public MAXBATCH = 10;
    string public baseURI = "https://islandboys.wtf/";
    bool private _started = false;
    string constant _NAME = "ISLAND BOYS";
    string constant _SYMBOL = "BOY";
    address constant _RUGS = 0x6C94954D0b265F657A4A1B35dfAA8B73D1A3f199;
    address constant _DRAPES = 0x9aF0e1748fF32f698847CfAB5013469a37dCdb17;
    address constant _BLAZED = 0x8584e7A1817C795f74Ce985a1d13b962758FE3CA;
    address constant _HEADS = 0xC6904FB685b4DFbDb98a5B70E40863Cd9AEF33DC;
    address constant _DOJI = 0x5e9dC633830Af18AA43dDB7B042646AADEDCCe81;
    address constant _RECORDS = 0x153C5091580cB9c3f12F7C1e170743a9af7B774a;
    address constant _INFLUENZAS = 0xaf76c7B002a3b7F062E1a19248B0579C52EeBE4A;
    address constant _ZINGOT = 0x8dEeFeBd24EF87e3F7aEf2057a002a8E91837801;

    constructor()
    ERC721(_NAME, _SYMBOL) {
        setStart(true);
        safeMint(0x86a8A293fB94048189F76552eba5EC47bc272223, 1);
        transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }
    receive() external payable {

    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
    }

    function claimIsland(uint256 _batchCount) public {
        require(_started);
        require(_batchCount > 0 && _batchCount <= MAXBATCH);
        require(totalSupply() + _batchCount + burnCount <= TOTALCOUNT);
        require(hasRugToken(), "You must own at least one Rug project to mint.");
        for(uint256 i = 0; i < _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            emit Claim(_msgSender(), mintID);
            _mint(_msgSender(), mintID);
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function hasRugToken() public view returns (bool) {
        address sender = _msgSender();
        if(
            IERC721(_RUGS).balanceOf(sender) > 0 ||
            IERC721(_DRAPES).balanceOf(sender) > 0 ||
            IERC721(_BLAZED).balanceOf(sender) > 0 ||
            IERC721(_HEADS).balanceOf(sender) > 0 ||
            IERC721(_DOJI).balanceOf(sender) > 0 ||
            IERC721(_RECORDS).balanceOf(sender) > 0 ||
            IERC721(_ZINGOT).balanceOf(sender) > 0 ||
            IERC721(_INFLUENZAS).balanceOf(sender) > 0
        ) {
            return true;
        }
        return false;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < TOTALCOUNT);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        burnCount++;
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
import "hardhat/console.sol";

contract Influenza is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Paid (address indexed influencer, uint _amount);

    uint256 public burnCount;
    uint256 public totalCount = 25000;
    uint256 public maxBatch = 100; 
    uint256 public price = 0.01 * 10**18; //Mint Price
    string public baseURI = "ipfs://Qme1gdt6gFepD1mw7Hy1d7bhp6HnHy7bL9bK8VuohsD3tS/";
    bool private _started = false;
    address payable[250] _wallets;

    constructor(address[] memory _addresses, string memory name ,string memory symbol)
    ERC721(name, symbol)
    {
        for (uint256 index = 0; index < 250; index++) {
            _wallets[index] = payable(_addresses[index]);
        }
    }

    receive() external payable {}

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
    }

    function claimInfuenza(uint256 _batchCount) payable public {
        require(_started);
        require(_batchCount > 0 && _batchCount <= maxBatch);
        require(totalSupply() + _batchCount + burnCount <= totalCount);
        require(msg.value == _batchCount * price);

        emit Claim(msg.sender, totalSupply(), _batchCount);
        for(uint256 i = 0; i< _batchCount; i++) {
            uint mintID = getMintID(totalSupply() + 1);
            uint index = totalSupply() % 250;
            require(totalSupply() < totalCount);
            emit Claim(_msgSender(), mintID, _batchCount);
            _mint(_msgSender(), mintID);
            console.log(_wallets[index]);
            (bool sent, ) = _wallets[index].call{value:(msg.value / _batchCount), gas: 21000}("");
            require(sent,"Error while transfering the eth");
            emit Paid(_wallets[index], msg.value);
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function updateWallets (address _wallet, uint id) external onlyOwner {
        require(_wallet != address(0));
        _wallets[id] = payable(_wallet);
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < totalCount);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        burnCount++;
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function getMintID (uint id) pure internal returns (uint){
        uint value = uint(keccak256(abi.encode(id)));
        return value;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract CakedApesMarket is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

	enum ListingStatus {
    Blank,
    Cancelled,
		Active,
    Sold
	}

	struct Listing {
		ListingStatus status;
		address seller;
		uint amount;
		uint tokenID;
		uint price;
    uint expiration;
	}

	event Listed(
		ListingStatus status,
		address seller,
		uint amount,
		uint tokenID,
		uint price,
    uint expiration,
    uint id
	);

	event Sale(
		uint listingId,
		address buyer,
		uint amount,
		uint tokenID,
		uint price
	);

	event Cancel(
		uint listingId,
		address seller
	);

	uint private _listingId;
  address payable private _contractAddress;
  address payable _royaltiesTarget;
  uint private _royalties;
	mapping(uint => Listing) private _listings;
  mapping(uint => bool) private _listed;

  //proxy requirement
  function initialize(address nftContract, address target) initializer public {
    __ReentrancyGuard_init();
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
    _contractAddress = payable(nftContract);
    _royaltiesTarget = payable(target);
    _royalties = 5;
  }
  
  //proxy requirement
  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

	function listToken(uint tokenID, uint price, uint expiration) external whenNotPaused {
    require(IERC721(_contractAddress).isApprovedForAll(_msgSender(), address(this)), "Approve the contract");
    require(IERC721(_contractAddress).ownerOf(tokenID) == _msgSender(), "You can't list a token you do no own");
    require(_listed[tokenID] == false, "Token already listed");
    _listed[tokenID] = true;
    _listingId++;
    _listings[_listingId] = Listing(ListingStatus.Active, _msgSender(), 1, tokenID, price, expiration);
		emit Listed(ListingStatus.Active, _msgSender(), 1, tokenID, price, expiration, _listingId);
	}

	function getListing(uint listingId) public view returns (Listing memory) {
    return _listings[listingId];
	}

  // step 1 approve the zingot contract for transaction
  // step 2 call buy token
	function buyToken(uint listingId) external payable nonReentrant whenNotPaused {
    Listing storage listing = _listings[listingId];
    require(listing.status == ListingStatus.Active, "Listing is not active");
		require(_msgSender() != listing.seller, "Seller cannot be buyer");
    require(block.timestamp <= listing.expiration, "Listing expired");
    require(msg.value == listing.price, "wrong eth value sent");
    _listed[listing.tokenID] = false;
    listing.status = ListingStatus.Sold;
		IERC721(_contractAddress).safeTransferFrom(listing.seller, _msgSender(), listing.tokenID, "");
    (bool success, ) = payable(listing.seller).call{value: listing.price * (100 - _royalties) / 100 }("");
    require(success, "Address: unable to send value, recipient may have reverted 1");
    if (_royalties > 0) {
      (bool success, ) = payable(_royaltiesTarget).call{value: listing.price * _royalties / 100 }("");
      require(success, "Address: unable to send value, recipient may have reverted 2");
    }
		emit Sale(listingId, _msgSender(), listing.amount, listing.tokenID, listing.price);
	}

	function cancel(uint listingId) public {
    Listing storage listing = _listings[listingId];
		require(_msgSender() == listing.seller, "Only seller can cancel listing");
		require(listing.status == ListingStatus.Active, "Listing is not active !");
    _listed[listing.tokenID] = false;
    listing.status = ListingStatus.Cancelled;

		emit Cancel(listingId, listing.seller);
	}

  function batchCancel(uint[] calldata listingIdArray) public {
    for (uint256 index = 0; index < listingIdArray.length; index++) {
      cancel(listingIdArray[index]);
    }
	}

  function getListingCount() public view returns(uint count) {
    return _listingId;
  }

  function getRoyalties() public view returns (uint royalties) {
    return _royalties;
  }

  function setRoyalties(uint royalties) public onlyOwner {
    require(royalties < 101, "Can't set the royalties above 100%.");
    _royalties = royalties;
  }

  function setTarget(address target) public onlyOwner {
    _royaltiesTarget = payable(target);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "hardhat/console.sol";

/// @custom:security-contact [email protected]
contract Zingot2 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC2771ContextUpgradeable {
  ERC20PresetMinterPauser _oldZingot;
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address forwarder, address oldZingot) initializer public {
    __ERC20_init("Zingot", "ZINGOT");
    __ERC2771Context_init(forwarder);
    __ERC20Burnable_init();
    __ERC20Snapshot_init();
    __Ownable_init();
    __UUPSUpgradeable_init();
    _oldZingot = ERC20PresetMinterPauser(oldZingot);
    _mint(_msgSender(), 498_000_000 * 10 ** decimals());
    _mint(address(this), 2_000_000 * 10 ** decimals());
  }

  function _msgSender() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (address ret) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (bytes calldata ret) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function snapshot() public onlyOwner {
    _snapshot();
  }

  function swap() public {
    uint balance = _oldZingot.balanceOf(_msgSender());
    require(_oldZingot.allowance(_msgSender(), address(this)) >= balance, "You didn't allow the contract to swap your tokens");
    _oldZingot.transferFrom(_msgSender(), address(this), balance);
    _oldZingot.burn(balance);
    this.transfer(_msgSender(), balance);
  }

  function swapQty(uint amount) public {
    require(_oldZingot.allowance(msg.sender, address(this)) >= amount, "You didn't allow the contract to swap your tokens");
    _oldZingot.transferFrom(msg.sender, address(this), amount);
    _oldZingot.burn(amount);
    this.transfer(msg.sender, amount);
  }

  function rescueZingot() public onlyOwner {
    this.transfer(_msgSender(), this.balanceOf(address(this)));
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}
    // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}

contract Zingot2V2 is Zingot2 {
  function burn(uint amount) public override {
    address payable payout;
    AddressUpgradeable.sendValue(payout, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../payout/zingot2.sol";

contract DojiMarket is ERC1155, Ownable, Pausable, ReentrancyGuard {
  uint public productAvailable = 0;
  ERC20PresetMinterPauser _oldZingot;
  Zingot2 _zingot;

  string public name = "Zingot Marketplace";
  string public symbol = "ZM";

  address private _trustedForwarder;
  address private _treasury;
  string private _uri;
  struct Product {
    uint price;
    uint maxSupply;
    uint currentSupply;
    bool start;
    address artist;
  }
  mapping(uint => Product) public idToProduct;
  mapping(address => bool) public whitelist;
  
  constructor(string memory userUri, address forwarder, address oldZingot, address zingot) ERC1155(userUri) {
    _uri = userUri;
    _trustedForwarder = forwarder;
    _treasury = zingot;
    _oldZingot = ERC20PresetMinterPauser(oldZingot);
    _zingot = Zingot2(zingot);
    whitelist[_msgSender()] = true;
  }

  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return idToProduct[_id].currentSupply;
  }

  function trustedForwarder() public virtual view returns (address){
      return _trustedForwarder;
  }

  function _setTrustedForwarder(address _forwarder) internal {
      _trustedForwarder = _forwarder;
  }

  function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

  function isTrustedForwarder(address forwarder) public virtual  view returns(bool) {
      return forwarder == _trustedForwarder;
  }

  function versionRecipient() external virtual view returns (string memory) {
    return "2.2.0+opengsn.accepteverything.ipaymaster";
  }

  receive() external payable {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setTreasury(address treasury) public onlyOwner {
      _treasury = treasury;
  }

  function setURI(string memory newuri) public onlyOwner {
      _setURI(newuri);
  }

  function setUserURI(string memory newuri) public onlyOwner {
      _uri = newuri;
  }

  function uri(uint256 collectionId) public view override returns (string memory) {
    return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, _toString(collectionId))) : "";
  }

  function mint(address account, uint256 id, uint256 amount)
    public
    whenNotPaused()
    nonReentrant()
  {
      require(idToProduct[id].maxSupply >= (idToProduct[id].currentSupply + amount), "No more token available");
      require(idToProduct[id].start == true, "Sales hasn't started");
      uint price = idToProduct[id].price * amount;
      require(_zingot.allowance(_msgSender(), address(this)) >= price);
      _zingot.transferFrom(_msgSender(), address(this), price);
      _zingot.burn(price / 4);
      _zingot.transfer(idToProduct[id].artist, (price / 2));
      _zingot.transfer(_treasury, (price / 4));
      idToProduct[id].currentSupply += amount;
      _mint(account, id, amount, "");
  }

  function modifyWhitelist(address account, bool value) public onlyOwner {
    whitelist[account] = value;
  }

  modifier isWhitelisted {
    require(whitelist[_msgSender()] == true);
    _;
  }

  function mintOldZingot(address account, uint256 id, uint256 amount)
    public
    whenNotPaused()
    nonReentrant()
  {
      require(idToProduct[id].maxSupply >= (idToProduct[id].currentSupply + amount), "No more token available");
      require(idToProduct[id].start == true, "Sales hasn't started");
      uint price = idToProduct[id].price * amount;
      require(_oldZingot.allowance(_msgSender(), address(this)) >= price);
      _oldZingot.transferFrom(_msgSender(), address(this), price);
      _oldZingot.approve(address(_zingot), price);
      _zingot.swapQty(price);
      _zingot.burn(price / 4);
      _zingot.transfer(idToProduct[id].artist, (price / 2));
      _zingot.transfer(_treasury, (price / 4));
      idToProduct[id].currentSupply += amount;
      _mint(account, id, amount, "");
  }

  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
    public
    whenNotPaused()
    nonReentrant()
  {    
      uint totalPrice;
      for (uint256 index = 0; index < ids.length; index++) {
        totalPrice += (idToProduct[ids[index]].price * amounts[index]);
        require(idToProduct[ids[index]].maxSupply >= (idToProduct[ids[index]].currentSupply + amounts[index]), "No more token available");
        require(idToProduct[ids[index]].start == true, "Sales hasn't started");
        idToProduct[ids[index]].currentSupply += amounts[index];
      }
      require(_zingot.allowance(_msgSender(), address(this)) >= totalPrice);
      _zingot.transferFrom(_msgSender(), address(this), totalPrice);
      _mintBatch(to, ids, amounts, "");
  }

  function rescueEther() public onlyOwner {
    uint256 currentBalance = address(this).balance;
    (bool sent, ) = address(_msgSender()).call{value: currentBalance}('');
    require(sent,"Error while transfering the eth");    
  }

  function rescueZingot() public onlyOwner {
    _zingot.transfer(_msgSender(), _zingot.balanceOf(address(this)));
  }

  function startStop (uint id, bool start) public onlyOwner whenNotPaused() {
    idToProduct[id].start = start;
  }

  function addProduct(uint price, uint maxSupply, bool start, address artist) public isWhitelisted whenNotPaused() {
    idToProduct[productAvailable].price = price * 10 ** 18;
    idToProduct[productAvailable].artist = artist;
    idToProduct[productAvailable].maxSupply = maxSupply;
    idToProduct[productAvailable].start = start;
    productAvailable += 1;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view override returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
      if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
          return true;
      }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  function _toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DojiMarketPlace.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../templates/UnorderedKeySet.sol";

contract Secondaries is Initializable, UUPSUpgradeable, ERC2771ContextUpgradeable, OwnableUpgradeable {

  using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
  HitchensUnorderedKeySetLib.Set _listingSet;

	enum ListingStatus {
		Active,
		Sold,
    Cancelled
	}

	struct Listing {
		ListingStatus status;
		address seller;
    address creator;
		uint amount;
		uint collectionId;
		uint price;
    uint expiration;
	}

	event Listed(
		ListingStatus status,
		address seller,
    address creator,
		uint amount,
		uint collectionId,
		uint price,
    uint expiration,
    uint id
	);

	event Sale(
		uint listingId,
		address buyer,
		uint amount,
		uint collectionId,
		uint price
	);

	event Cancel(
		uint listingId,
		address seller
	);

	uint private _listingId;
  address payable private _contractAddress;
  address private _currency;
  uint private _royalties;
	mapping(bytes32 => Listing) private _listings;
  mapping(uint => uint[]) public collectionIdToAmountOfListings;

  //proxy requirement
  function initialize(address forwarder, address zingot, address nftContract) initializer public {
    __ERC2771Context_init(forwarder);
    __Ownable_init();
    __UUPSUpgradeable_init();
    _currency = zingot;
    _contractAddress = payable(nftContract);
    _royalties = 5;
  }
  //proxy requirement
  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}
  //gas less transactions requirement
  function _msgSender() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (address ret) {
    return ERC2771ContextUpgradeable._msgSender();
  }
  //gas less transactions requirement
  function _msgData() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (bytes calldata ret) {
    return ERC2771ContextUpgradeable._msgData();
  }

	function listToken(uint amount, uint collectionId, uint price, uint expiration) external {
    require(DojiMarket(_contractAddress).isApprovedForAll(_msgSender(), address(this)), "Approve the contract");
    require(DojiMarket(_contractAddress).balanceOf(_msgSender(), collectionId) >= amount, "You cannot listing token you don't have");
    _listingId++;
    bytes32 key = bytes32(_listingId);
    _listingSet.insert(key);
    collectionIdToAmountOfListings[collectionId].push(_listingId);
    Listing storage listing = _listings[key];

    listing.amount = amount;
    listing.seller = _msgSender();
    listing.price = price;
    listing.expiration = expiration;
    (,,,,listing.creator) = DojiMarket(_contractAddress).idToProduct(collectionId);
    listing.status = ListingStatus.Active;
    listing.collectionId = collectionId;

		emit Listed(listing.status, listing.seller, listing.creator, listing.amount, listing.collectionId, listing.price, listing.expiration, _listingId);
	}

	function getListing(uint listingId) public view returns (Listing memory) {
    bytes32 key = bytes32(listingId);
		require(_listingSet.exists(key), "Can't get a listing that doesn't exist.");
    Listing storage listing = _listings[key];
    return listing;
	}
  // step 1 approve the zingot contract for transaction
  // step 2 call buy token
	function buyToken(uint listingId) external payable {
		bytes32 key = bytes32(listingId);
		require(_listingSet.exists(key), "Can't get a listing that doesn't exist.");
    Listing storage listing = _listings[key];

		require(_msgSender() != listing.seller, "Seller cannot be buyer");
		require(listing.status == ListingStatus.Active, "Listing is not active");
    require(block.timestamp <= listing.expiration, "Listing expired");
		DojiMarket(_contractAddress).safeTransferFrom(listing.seller, _msgSender(), listing.collectionId, listing.amount, "");
		IERC20(_currency).transferFrom(_msgSender(), listing.seller, listing.price * (100 - _royalties) / 100);
    if (_royalties > 0) {
      IERC20(_currency).transferFrom(_msgSender(), listing.creator, listing.price * (_royalties) / 100);
    }
    

		emit Sale(
			listingId,
			_msgSender(),
			listing.amount,
			listing.collectionId,
			listing.price
		);
    listing.status = ListingStatus.Sold;
	}

	function cancel(uint listingId) public {
		bytes32 key = bytes32(listingId);
		require(_listingSet.exists(key), "Can't get a listing that doesn't exist.");
    Listing storage listing = _listings[key];
		require(_msgSender() == listing.seller, "Only seller can cancel listing");
		require(listing.status == ListingStatus.Active, "Listing is not active");
    listing.status = ListingStatus.Sold;

		emit Cancel(listingId, listing.seller);
	}

  function batchCancel(uint[] calldata listingIdArray) public {
    for (uint256 index = 0; index < listingIdArray.length; index++) {
      cancel(listingIdArray[index]);
    }
	}

  function getListingCount() public view returns(uint count) {
    return _listingSet.count();
  }

  function getRoyalties() public view returns (uint royalties) {
    return _royalties;
  }

  function getListingAtIndex(uint index) public view returns(Listing memory) {
    return getListing(uint(_listingSet.keyAtIndex(index)));
  }

  function getListingByCollectionId(uint collectionId) public view returns(uint[] memory){
    return collectionIdToAmountOfListings[collectionId];
  }

  function setCurrency (address currency) public onlyOwner {
    _currency = currency;
  }

  function setRoyalties(uint royalties) public onlyOwner {
    _royalties = royalties;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Hitchens UnorderedKeySet v0.93
Library for managing CRUD operations in dynamic key sets.
https://github.com/rob-Hitchens/UnorderedKeySet
Copyright (c), 2019, Rob Hitchens, the MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library HitchensUnorderedKeySetLib {

    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet(100) - Key cannot be 0x0");
        require(!exists(self, key), "UnorderedKeySet(101) - Key already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Key does not exist in the set.");
        bytes32 keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}

contract HitchensUnorderedKeySet {

    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
    HitchensUnorderedKeySetLib.Set _set;

    event LogUpdate(address sender, string action, bytes32 key);

    function exists(bytes32 key) public view returns(bool) {
        return _set.exists(key);
    }

    function insert(bytes32 key) public {
        _set.insert(key);
        emit LogUpdate(msg.sender, "insert", key);
    }

    function remove(bytes32 key) public {
        _set.remove(key);
        emit LogUpdate(msg.sender, "remove", key);
    }

    function count() public view returns(uint) {
        return _set.count();
    }

    function keyAtIndex(uint index) public view returns(bytes32) {
        return _set.keyAtIndex(index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../payout/zingot2.sol";

interface Inventory {
  function send1155(address _contract, uint tokenID, uint _amount, uint256 chosenHolder) external;
  function equip (uint[17] memory array, uint dojiId) external;
}

contract DojiTraits is ERC1155, Ownable, Pausable {
  uint public productAvailable = 0;
  Zingot2 _zingot;

  string public name = "Doji Traits";
  string public symbol = "DT";
  Inventory _inventory;
  address private _trustedForwarder;
  address private _treasury;
  address private _firewall;
  string private _uri;
  address private _artist;
  struct Product {
    uint price;
    uint maxSupply;
    uint currentSupply;
    bool dojiCrew;
    address artist;
  }
  mapping(uint => Product) public idToProduct;
  mapping(address => bool) public whitelist;
  
  constructor(string memory userUri, address forwarder, address zingot, address firewall) ERC1155(userUri) {
    _uri = userUri;
    _trustedForwarder = forwarder;
    _treasury = zingot;
    _zingot = Zingot2(zingot);
    whitelist[_msgSender()] = true;
    _firewall = firewall;
  }

  function totalSupply(uint256 _id) public view returns (uint256) {
    return idToProduct[_id].currentSupply;
  }

  function getAffiliation(uint _id) public view returns (bool) {
    return idToProduct[_id].dojiCrew;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setTreasury(address treasury) public onlyOwner {
      _treasury = treasury;
  }

  function setInventory(address inventory) public onlyOwner {
    _inventory = Inventory(inventory);
  }

  function setFirewall(address firewall) public onlyOwner {
    _firewall = firewall;
  }

  function setURI(string memory newuri) public onlyOwner {
      _setURI(newuri);
  }

  function setUserURI(string memory newuri) public onlyOwner {
      _uri = newuri;
  }

  function uri(uint256 collectionId) public view override returns (string memory) {
    return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, _toString(collectionId))) : "";
  }

  function mint(address account, uint256 id, uint256 amount)
    public
    whenNotPaused()
  {
      require(idToProduct[id].maxSupply >= (idToProduct[id].currentSupply + amount), "No more tokens available");
      uint price = idToProduct[id].price * amount;
      require(_zingot.allowance(_msgSender(), address(this)) >= price);
      _zingot.transferFrom(_msgSender(), address(this), price);
      _zingot.burn(price / 4);
      _zingot.transfer(idToProduct[id].artist, (price / 2));
      _zingot.transfer(_treasury, (price / 4));
      idToProduct[id].currentSupply += amount;
      _mint(account, id, amount, "");
  }

  function mintTest(address account, uint256 id, uint256 amount) public {
      _mint(account, id, amount, "");
  }

  function claim(uint dojiId, uint[17] memory traits) public {
    require(msg.sender == _firewall, "Must be approved by the firewall first");
    _inventory.equip(traits, dojiId);
    for (uint256 index = 0; index < traits.length; index++) {
      if (traits[index] != 0) {
        uint id = traits[index];
        idToProduct[id].price = 0;
        idToProduct[id].maxSupply = 2**256 - 1;
        idToProduct[id].currentSupply += 1;
        idToProduct[id].dojiCrew = dojiId < 5323 ? true : false;
        idToProduct[id].artist = _artist;
        _mint(address(_inventory), id, 1, abi.encode(address(this), id, 1, dojiId));
        // _inventory.send1155(address(_inventory), id, 1, dojiId);
      }
    }
  }

  function modifyWhitelist(address account, bool value) public onlyOwner {
    whitelist[account] = value;
  }

  modifier isWhitelisted {
    require(whitelist[_msgSender()] == true);
    _;
  }

  function addProduct(uint price, uint maxSupply, address artist) public isWhitelisted whenNotPaused() {
    idToProduct[productAvailable].price = price * 10 ** 18;
    idToProduct[productAvailable].artist = artist;
    idToProduct[productAvailable].maxSupply = maxSupply;
    productAvailable += 1;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view override returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
      if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
          return true;
      }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  function _toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface Traits {
  function getAffiliation(uint _id) external view returns (bool);
}

contract DojiInventory is Initializable, ERC1155HolderUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    event Received(address, uint256);
    event NewEquipment (uint[17] indexed equipment);
    event ChosenHolder1155(uint256 indexed chosenHolder, address indexed sender, uint, uint);
    bool public halt;
    struct TokenIDClaimInfo {
        uint index;
        uint balance;
    }

    struct NFTClaimInfo {
        uint index;
        uint[] tokenID;
        mapping(uint => TokenIDClaimInfo) claimTokenStruct;
    }

    struct ContractInfo {
        address[] contractIndex;
        mapping(address => NFTClaimInfo) contractInfos;
    }

    struct Armor {
        uint256 [17] equipments;
        mapping(uint256 => bool) isEquipped;
        bool isDoji;
    }
    
    mapping (uint256 => Armor) private _equipped;
    mapping (uint256 => ContractInfo) private _userInventory;
    address private _firewall;
    address private _traits;




    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory data
    ) public virtual override returns (bytes4) {
        if (msg.sender == _traits) {
            (address cont, uint id, uint amount, uint dojiId) = abi.decode(data, (address, uint, uint, uint));
            _store(cont, id, amount, dojiId);
        } else revert();
        return this.onERC1155Received.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    modifier onlyFirewall () {
        require(msg.sender == _firewall, "Only the firewall can call the function");
        _;
    }

    function setFirewall(address firewall) public onlyOwner {
        _firewall = firewall;
    }
    
    function withdrawOne(uint256 dojiID, address _contract, uint256 tokenID, uint _amount) public onlyFirewall {
        require(!halt, 'Claims temporarily unavailable');
        require(_amount > 0, "Withdraw at least 1");
        require(_removeBalanceOfTokenId(_contract, dojiID, tokenID, _amount), "Error while updating balances");
        ERC1155Upgradeable(_contract).safeTransferFrom(address(this), msg.sender, tokenID, _amount, "");
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }

    function isContractForUser(address _contract, uint dojiID) public view returns(bool) {
		if (_userInventory[dojiID].contractIndex.length == 0) return false;
		return (_userInventory[dojiID].contractIndex[_userInventory[dojiID].contractInfos[_contract].index] == _contract);
	}
	
	function isTokenIDForContractForUser(address _contract, uint dojiID, uint tokenID) public view returns(bool) {
		if (_userInventory[dojiID].contractInfos[_contract].tokenID.length == 0) return false;
		return (
			_userInventory[dojiID].contractInfos[_contract]
				.tokenID[ _userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index ] == tokenID
		);
	}

    function _insertContractForUser (address _contract, uint dojiID, uint tokenID, uint balance) internal returns(uint index) {
        require(!isContractForUser(_contract, dojiID), "Contract already exist"); 
        _userInventory[dojiID].contractIndex.push(_contract);
        _userInventory[dojiID].contractInfos[_contract].index = _userInventory[dojiID].contractIndex.length - 1;
        if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)){
            _userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].balance = balance;
            _userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
            _userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
        }
        return _userInventory[dojiID].contractIndex.length-1;
    }

	function _addBalanceOfTokenId(address _contract, uint dojiID, uint tokenID, uint _amount) internal returns(bool success) {
        require(isContractForUser(_contract, dojiID), "Contract doesn't exist");
            if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)) {
                _userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
            _userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
            }
        if (_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].balance == 0) {
                _userInventory[dojiID]
                .contractInfos[_contract]
                .claimTokenStruct[tokenID].balance = _amount;
            } else {
                _userInventory[dojiID]
                    .contractInfos[_contract]
                    .claimTokenStruct[tokenID].balance += _amount;
            }
        return true;
    }

	function _removeBalanceOfTokenId(address _contract, uint dojiID, uint tokenID, uint _amount) internal returns(bool success) {
        require(isContractForUser(_contract, dojiID), "Contract doesn't exist"); 
        require(isTokenIDForContractForUser(_contract, dojiID, tokenID));
        _userInventory[dojiID]
            .contractInfos[_contract]
            .claimTokenStruct[tokenID].balance -= _amount;
        return true;
    }

	function getTokenBalanceByID(address _contract, uint dojiID, uint tokenID) public view returns(uint) {
		return _userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].balance;
	}

	function getTokenIDCount(address _contract, uint dojiID) public view returns(uint) {
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID.length;
	}

	function getTokenIDByIndex(address _contract, uint dojiID, uint index) public view returns(uint) {
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID[index];
	}

	function getContractAddressCount(uint dojiID) public view returns(uint) {
		return _userInventory[dojiID].contractIndex.length;
	}

	function getContractAddressByIndex(uint dojiID, uint index) public view returns(address) {
		return _userInventory[dojiID].contractIndex[index];
	}

    function _store(address _contract, uint tokenID, uint _amount, uint256 chosenHolder) internal {
		require(_amount > 0);
		require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
		if (isContractForUser(_contract, chosenHolder)) {
			_addBalanceOfTokenId(_contract, chosenHolder, tokenID, _amount);
		} else {
			_insertContractForUser (_contract, chosenHolder, tokenID, _amount);
        }
	}

    function equip (uint[17] memory array, uint dojiId) public {
        require(msg.sender == _traits);
        _equipped[dojiId].equipments = array;
        _equipped[dojiId].isDoji = dojiId < 5323 ? true : false;
        for (uint256 index = 0; index < array.length; index++) {
            _equipped[dojiId].isEquipped[array[index]] = true;
        }
    }

    function swap (uint traitIdToEquip, uint index, uint dojiID) public onlyFirewall {
        require(getTokenBalanceByID(_traits, dojiID, traitIdToEquip) > 0, "You do not own that trait");
        require((traitIdToEquip / 10000) - 100 == index + 1, "The traits doesn't fit that slot");
        uint oldTrait = _equipped[dojiID].equipments[index];
        _equipped[dojiID].equipments[index] = traitIdToEquip;
        _equipped[dojiID].isEquipped[oldTrait] = false;
        _equipped[dojiID].isEquipped[traitIdToEquip] = true;
        emit NewEquipment(_equipped[dojiID].equipments);
    }

    function getEquipment(uint dojiId) public view returns(uint[17] memory) {
        return _equipped[dojiId].equipments;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CREWCoin is Initializable, UUPSUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    address payable public qtWallet;
    address _signer;
    
    uint256 public minted;
    
    string public baseURI;
    string _name;
    string _symbol;

    mapping(bytes32 => uint) public skuHash;

    function initialize(string memory _uri, address payable _qtWallet, address __signer) initializer public {
      __ERC721_init('CREW Coin', 'CREW');
      __Ownable_init();
      __UUPSUpgradeable_init();
      qtWallet = _qtWallet;  
      _signer = __signer;
      baseURI = _uri;
      _symbol = 'CREW';
      _name = 'CREW Coin';
      minted = 1; // match with the current variable minted at address 0x46A9E5b490175724699D09F0F6104c95DEfd447a
      // transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }

    function _authorizeUpgrade(address newImplementation)
      internal
      onlyOwner
      override
    {}
    receive() payable external {}
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setSigner(address __signer) external onlyOwner {
        _signer = __signer;
    }

    function mint(bytes32 sku, uint timestamp, bytes memory signature, address to) external virtual {
        require(recover(sku, timestamp, signature, to), "Signature Verifier: Invalid sigature"); 
        require(skuHash[sku] == 0, "Doji already used");
        require(_msgSender() == to, "Only rank 9 owner can mint the token");
        require(timestamp >= block.timestamp, "SignatureVerifier: Signature expired");
        skuHash[sku] = minted;
        _safeMint(to, minted);
        ++minted;
    }

    function walletDistro() external {
        AddressUpgradeable.sendValue(qtWallet, address(this).balance);
    }

    function changeWallets(address payable _qtWallet) external onlyOwner {
        qtWallet = _qtWallet;
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);
      uint256[] memory tokensId = new uint256[](tokenCount);
      for (uint256 i = 0; i < tokenCount; i++) {
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
    }

    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

  function _getMessageHash(bytes32 sku, uint timestamp, address to) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(sku, timestamp, to))); 
  }

  function _getMessage(bytes32 sku, uint timestamp, address to) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(sku, _msgSender(),timestamp, to)); 
  }

  function recover(bytes32 sku, uint timestamp, bytes memory signature, address to) public view returns(bool) {
    bytes32 hash = _getMessageHash(sku, timestamp, to);
    return SignatureChecker.isValidSignatureNow(_signer, hash, signature);
  }
}

// contract CREWCoinV2 is CREWCoin {
//   function mintV2(bytes32 sku, uint timestamp, bytes memory signature, address to) external {
//     require(recover(sku, timestamp, signature, to), "Signature Verifier: Invalid sigature"); 
//     require(_msgSender() == to, "Only rank 9 owner can mint the token");
//     require(skuHash[sku] == 0, "Doji already used");
//     require(timestamp >= block.timestamp, "SignatureVerifier: Signature expired");
//     skuHash[sku] = minted;
//     _safeMint(to, minted);
//     ++minted;
//   }
// }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";


interface Floot721 is IERC721Enumerable {
    function walletInventory(address _owner) external view returns (uint256[] memory);
}

contract FLOOTClaims is ERC721Holder, Ownable {
    event Received(address, uint256);

    event LuckyFuck(uint256, address);
    event ChosenFuck(uint256, address);
    
    using SafeERC20 for IERC20;

    //Floot721 public floot = Floot721(0x4096709cE7336AB06F7eae50DD0461bcf011965C);
    // Floot721 public floot = Floot721(0x540d7E428D5207B30EE03F2551Cbb5751D3c7569);
    Floot721 public floot;
    
    uint256 public currentFloots;

    bool public halt = false;

    struct FlootIDinfo {
        uint256 tokenID;        // ID of FLOOT token
        uint256 rewardDebt;     // amount the ID is NOT entitled to (ie previous distros and claimed distros)
        uint256 pending;
        uint256 paidOut;        // amount paid out to ID
        bool tracked;
    }

    struct PayoutInfo {
        address payoutToken;        // Address of LP token contract.
        uint256 balance;            // total amount of payout in contract
        uint256 pending;            // pending payouts
        uint256 distroPerFloot;     // amount each FLOOT is entitled to
        uint256 paidOut;            // total paid out to FLOOTs
    }

    struct NFTClaimInfo {
        address nftContract;
        uint256 tokenID;
        uint256 luckyFuck;
        bool claimed;
    }

    PayoutInfo[] public payoutInfo;     // keeps track of payout deets
    //NFTClaimInfo[] public nftClaimInfo;
    mapping (uint256 => NFTClaimInfo[]) public nftClaimInfo;
    mapping (uint256 => mapping (uint256 => FlootIDinfo)) public flootIDinfo;     // keeps track of pending and claim rewards

    constructor(address _floot)  {
        floot = Floot721(_floot);
        addPayoutPool(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        updateNewHolders(floot.totalSupply(),0);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenID,
        bytes memory fromFaucet
    ) public virtual override returns (bytes4) {
        // msg.sender is the NFT contract
        if (keccak256(abi.encodePacked(fromFaucet)) == keccak256(abi.encodePacked(stringToBytes32('true')))){
            random721(msg.sender, tokenID);
        }
        return this.onERC721Received.selector;
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function random721(address nftContract, uint256 tokenID) internal {
        // updatePayout(0);
        
        uint256 luckyFuck = pickLuckyFuck();
        
        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,luckyFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[luckyFuck].push(newClaim);

        emit LuckyFuck(luckyFuck, nftContract);
    }

    function send721(address nftContract, uint256 tokenID, uint256 chosenFuck) public {
        IERC721(nftContract).safeTransferFrom(msg.sender,address(this),tokenID, 'true');

        NFTClaimInfo memory newClaim = NFTClaimInfo(nftContract,tokenID,chosenFuck,false);

        //uint256 luckyFloot = nftClaimInfo[luckyFuck];

        nftClaimInfo[chosenFuck].push(newClaim);

        emit ChosenFuck(chosenFuck, nftContract);
    }

    function pickLuckyFuck() internal view returns (uint) {
        uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, currentFloots)));
        return (rando % currentFloots) + 1;
    }
    
    function fundEther() external payable {
        emit Received(msg.sender, msg.value);
        updatePayout(0);
    }
    
    function ethBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function updatePayout(uint256 _pid) public {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();
        uint256 totalDebt;
        uint256 newFloots;
        
        if(flootSupply > currentFloots){
            newFloots = flootSupply - currentFloots;
            updateNewHolders(newFloots, _pid);
        }
        
        uint256 totalPaidOut;

        uint256 currentBalance;

        for (uint256 tokenIndex = 0; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            totalPaidOut += flootIDinfo[_pid][tokenID].paidOut;
            totalDebt += flootIDinfo[_pid][tokenID].rewardDebt;
        }

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20(payout.payoutToken).balanceOf(address(this));
        }

        uint256 totalDistro = currentBalance + totalPaidOut + totalDebt;

        payout.distroPerFloot = totalDistro * 1000 / flootSupply;
        payout.balance = totalDistro;
    }
    
    function updateNewHolders(uint256 newFloots, uint256 _pid) internal {
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();

        for (uint256 tokenIndex = currentFloots; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            flootIDinfo[_pid][tokenID].rewardDebt = payout.distroPerFloot / 1000;
            flootIDinfo[_pid][tokenID].tracked = true;
        }
        
        currentFloots += newFloots;
    }

    function claimNFTs(uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        NFTClaimInfo[] memory luckyFloot = nftClaimInfo[_tokenID];

        for (uint256 index = 0; index < luckyFloot.length; index++) {
            if(!luckyFloot[index].claimed){
                IERC721(luckyFloot[index].nftContract).safeTransferFrom(address(this),msg.sender,luckyFloot[index].tokenID);
                luckyFloot[index].claimed = true;
            }
        }
    }

    function claimPending(uint256 _pid) public {
        require(!halt, 'Claims temporarily unavailable');
        updatePayout(_pid);
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256[] memory userInventory = floot.walletInventory(msg.sender);
        uint256 pending = payout.distroPerFloot * userInventory.length / 1000;
        uint256 payoutPerTokenID;
        uint256 paidout;
        uint256 rewardDebt;

        uint256 claimAmount;

        // get payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            paidout += flootIDinfo[_pid][userInventory[index]].paidOut;
            rewardDebt += flootIDinfo[_pid][userInventory[index]].rewardDebt;
        }

        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt;
            payoutPerTokenID = claimAmount / userInventory.length; }
        else{
            return; }

        // add new payout to each tokenID's paid balance 
        for (uint256 index = 0; index < userInventory.length; index++) {
            flootIDinfo[_pid][userInventory[index]].paidOut += payoutPerTokenID; }

        payout.paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20(payout.payoutToken).safeTransfer(msg.sender, claimAmount);
        }
        
        
        //updatePayout(_pid);
    }
    
    function claimPendingToken(uint256 _pid, uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(floot.ownerOf(_tokenID) == msg.sender);
        
        updatePayout(_pid);
        
        PayoutInfo storage payout = payoutInfo[_pid];

        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_tokenID].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_tokenID].rewardDebt;

        uint256 claimAmount;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            claimAmount = pending - paidout - rewardDebt; }
        else{ return; }

        // add new payout to each tokenID's paid balance 
        flootIDinfo[_pid][_tokenID].paidOut += claimAmount;

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(address(msg.sender)).transfer(claimAmount); } 
        else {
            IERC20(payout.payoutToken).safeTransfer(msg.sender, claimAmount); }
        
        payout.paidOut += claimAmount;
        //updatePayout(_pid);
    }
    
    function viewAcctPending(uint256 _pid, address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;
        
        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            pending += viewTokenPending(_pid,userInventory[index]);
        }
        
        return pending;
    }
    
    function viewTokenPending(uint256 _pid, uint256 _id) public view returns(uint256){
        PayoutInfo storage payout = payoutInfo[_pid];
        if(!flootIDinfo[_pid][_id].tracked){
            return 0;
        }
        //uint256 pending = viewLatestClaimAmount(_pid) / 1000;
        uint256 pending = payout.distroPerFloot / 1000;
        uint256 paidout = flootIDinfo[_pid][_id].paidOut;
        uint256 rewardDebt = flootIDinfo[_pid][_id].rewardDebt;
        
        // adjust claim for previous payouts
        if(pending > (paidout + rewardDebt)) {
            return pending - paidout - rewardDebt; }
        else {
            return 0; 
        }
    }

    function viewNumberNftPending(address account) public view returns(uint256){
        uint256[] memory userInventory = floot.walletInventory(account);
        uint256 pending;

        // get pending payouts for all tokenIDs in caller's wallet
        for (uint256 index = 0; index < userInventory.length; index++) {
            pending += nftClaimInfo[userInventory[index]].length;
        }
        
        return pending;
    }

    function viewNftPending(uint _tokenID) public view returns(NFTClaimInfo[] memory){
        return nftClaimInfo[_tokenID];
    }
    
    // TODO: POSSIBLY BROKEN. MORE THAN LIKELY YEAH
    function viewLatestClaimAmount(uint256 _pid) public view returns(uint256){
        PayoutInfo storage payout = payoutInfo[_pid];
        uint256 flootSupply = floot.totalSupply();
        uint256 newFloots;
        uint256 totalDebt;
        uint256 totalPaidOut;
        uint256 currentBalance;

        if(flootSupply > currentFloots){
            newFloots = flootSupply - currentFloots; }
        
        totalDebt = payout.distroPerFloot * newFloots / 1000 ;     

        for (uint256 tokenIndex = 0; tokenIndex < flootSupply; tokenIndex++) {
            uint tokenID = floot.tokenByIndex(tokenIndex);
            totalPaidOut += flootIDinfo[_pid][tokenID].paidOut;
            totalDebt += flootIDinfo[_pid][tokenID].rewardDebt;
        }

        if (payout.payoutToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20(payout.payoutToken).balanceOf(address(this));
        }

        uint256 totalDistro = currentBalance + totalPaidOut + totalDebt;

        return totalDistro * 1000 / (flootSupply);
    }

    function addPayoutPool(address _payoutToken) public onlyOwner {
        //uint256 tokenBalance = IERC20(_payoutToken).balanceOf(address(this));
        payoutInfo.push(PayoutInfo({
            payoutToken: _payoutToken,
            balance: 0,
            pending: 0,
            distroPerFloot: 0,
            paidOut: 0
        }));

        //updatePayout(payoutInfo.length);
    }

    function rescueTokens(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }
    
    function rescueTokens2(address _recipient, IERC20 _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        _ERC20address.safeTransfer(_recipient, _amount); //use of the _ERC20 safetransfer
        return true;
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function changeFloot(address _newFloot) public onlyOwner {
        floot = Floot721(_newFloot);
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }

    function payoutPoolLength() public view returns(uint) {
        return payoutInfo.length;
    }

    function depositERC20(uint _pid, IERC20 _tokenAddress, uint _amount) public {
        require(payoutInfo[_pid].payoutToken == address(_tokenAddress));
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _amount);
        updatePayout(_pid);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/// @custom:security-contact [email protected]
contract OneThroughNine is ERC1155, Ownable, Pausable, ERC1155Burnable {
    uint constant _REVEALED = 1;
    uint constant _FROZEN_UNREVEALED = 2;
    uint constant _FROZEN_REVEALED = 3;

    constructor() ERC1155("https://test.com/") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

interface IDojiTraits {
  function claim(uint dojiId, uint[17] memory traits) external;
}

interface Inventory {
  function swap (uint traitIdToEquip, uint index, uint dojiID) external;
  function withdrawOne(uint256 dojiID, address _contract, uint256 tokenID, uint _amount) external;
}

contract Firewall is Initializable, ERC2771ContextUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
  address private _backEnd;
  bytes32 public merkleroot;
  mapping(uint => bool) public idToClaim;
  mapping(uint => bool) public blacklistedTimestamps;

  function initialize(address backEnd, address forwarder) public initializer {
    __Ownable_init();
    __ERC2771Context_init(forwarder);
    __UUPSUpgradeable_init();
    _backEnd = backEnd;
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  function setMerkleRoot (bytes32 root) public {
    merkleroot = root;
  }

  function setBackEnd (address backEnd) public {
    _backEnd = backEnd;
  }

  function isValidProof(bytes32[] calldata _proof, uint256 id, uint256[17] memory traits) view public returns(bool) {
    bytes32 leaf = computeLeaf(id, traits);
    return MerkleProof.verify(_proof, merkleroot, leaf);
  }

  function computeLeaf(uint256 id, uint256[17] memory traits) public pure returns (bytes32) {
      return keccak256(abi.encodePacked(id, traits));
  }

  function claim(uint dojiId, uint timestamp, uint256[17] memory traits, bytes memory signature, bytes32[] calldata _proof, address minter ) external {
    require(blacklistedTimestamps[timestamp] == false, "timestamp already used");
    require(recover(dojiId, timestamp, signature), "Wrong signature");
    require(isValidProof(_proof, dojiId, traits), "Invalid proof");
    require(idToClaim[dojiId] == false, "Doji Already claimed");
    blacklistedTimestamps[timestamp] == true;
    idToClaim[dojiId] = true;
    IDojiTraits(minter).claim(dojiId, traits);
  }

  function swap (uint traitIdToEquip, uint index, uint dojiID, uint timestamp, bytes memory signature, address inventory) public {
    require(blacklistedTimestamps[timestamp] == false, "timestamp already used");
    require(recover(dojiID, timestamp, signature), "Wrong signature");
    Inventory(inventory).swap(traitIdToEquip, index, dojiID);
  }

  function _msgSender() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (address ret) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal override(ContextUpgradeable, ERC2771ContextUpgradeable) virtual view returns (bytes calldata ret) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function _getMessageHash(uint id, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(id, timestamp))); 
  }

  function _getMessage(uint id, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(id, timestamp, _msgSender())); 
  }

  function recover(uint id, uint timestamp, bytes memory signature) public view returns(bool) {
    bytes32 hash = _getMessageHash(id, timestamp);
    return SignatureChecker.isValidSignatureNow(_backEnd, hash, signature);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Merkle {

  bytes32 public merkleroot;

  function changeMerkleRoot (bytes32 root) public {
    merkleroot = root;
  }

  function isValidProof(bytes32[] calldata _proof, uint256 id, uint256[13] memory traits) view public returns(bool) {
    bytes32 leaf = computeLeaf(id, traits);
    return MerkleProof.verify(_proof, merkleroot, leaf);
  }

  function computeLeaf(uint256 id, uint256[13] memory traits)
    public pure returns (bytes32)
  {
      return keccak256(abi.encodePacked(id, traits));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";


contract OneTo9 is ERC721Enumerable, Ownable {
    address payable public qtWallet;
    address _signer;
    uint256 public royalties;
    uint256 public minted;
    
    string public baseURI;
    string _name = '1to9';
    string _symbol = '1/9';
    string public url;

    mapping(bytes => bool) public SKUhash;

    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    constructor(string memory _uri, address payable _qtWallet, address __signer, string memory _url) 
    ERC721(_name, _symbol) {
      qtWallet = _qtWallet;  
      _signer = __signer;
      baseURI = _uri;
      url = _url;
    }
    receive() payable external {}
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function mint() external {
        bytes memory callData = abi.encodeWithSelector(OneTo9.mintWithProof.selector, _msgSender());
        string[] memory urls = new string[](1);
        urls[0] = url;
        revert OffchainLookup(
            address(this),
            urls,
            callData,
            OneTo9.mintWithProof.selector,
            callData
        );
    }

    function mintWithProof(bytes calldata response, bytes calldata extraData) external {
        (address signer, bytes memory result) = verify(extraData, response);
        require(signer == _signer, "SignatureVerifier: Invalid sigature");
        require(SKUhash[result] == false, "Doji already used");
        SKUhash[result] = true;
        _safeMint(_msgSender(), minted);
        ++minted;
    }

    function walletDistro() external {
        Address.sendValue(qtWallet, address(this).balance);
    }

    function changeWallets(address payable _qtWallet) external onlyOwner {
        qtWallet = _qtWallet;
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);
      uint256[] memory tokensId = new uint256[](tokenCount);
      for (uint256 i = 0; i < tokenCount; i++) {
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
    }

    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function makeSignatureHash(address target, uint64 expires, bytes memory request, bytes memory result) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(hex"1900", target, expires, keccak256(request), keccak256(result)));
    }

    function verify(bytes calldata request, bytes calldata response) internal view returns(address, bytes memory) {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(response, (bytes, uint64, bytes));
        address signer = ECDSA.recover(makeSignatureHash(address(this), expires, request, result), sig);
        require(
            expires >= block.timestamp,
            "SignatureVerifier: Signature expired");
        return (signer, result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol"; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender

contract ChipDip is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

event Claim (address indexed buyer, uint256 tokenID);
event Paid (address indexed influencer, uint _amount);

uint256 constant public MAXBATCH = 10;
uint public maxSlot = 24;
uint256 public price = 5 ether;
uint256 public priceSlot = 4 ether;
uint256 public priceView = 1 ether;
uint256 public priceAccount = 1 ether;
string public baseURI = "https://chipdip.s3.amazonaws.com/metadata/";
mapping(uint => bool) public timestampToBool;
mapping(uint => TokenAttribute) public tokenAttribute;
address _backend = 0xeb862fF4b8104d4BAe22427367A9a3A16694B486;
uint[] public viewModeAvailable = [0,1,2];
struct TokenAttribute {
    uint[] ownedViews;
    uint slot;
    uint addressLimit;
}

constructor()ERC721("CHIPDIP", "CHIPDIP"){}

receive() external payable {}

function setBaseURI(string memory _newURI) public onlyOwner {
    baseURI = _newURI;
}

function upgradeSlot(uint newSlots, uint id) public payable {
    require(newSlots % 4 == 0, " must be multiple of 4");
    require(newSlots + tokenAttribute[id].slot <= maxSlot);
    require(msg.value == (newSlots / 4) * priceSlot, "wrong matic value");
    tokenAttribute[id].slot = newSlots + tokenAttribute[id].slot;
}

function upgradeAddresses(uint id) public payable {
    require(msg.value == priceAccount, "wrong matic value");
    tokenAttribute[id].addressLimit += 1 ;
}

function buyViewModes(uint viewMode, uint id) public payable {
    uint[] memory array = tokenAttribute[id].ownedViews;
    require(!_includes(viewMode, viewModeAvailable), "Option not available");
    require(_includes(viewMode, array), "Already bought");
    require(msg.value == priceView, "wrong matic value");
    tokenAttribute[id].ownedViews.push(viewMode);
}

function setPriceOptions(uint valueSlot, uint valueView, uint valueAccount) public onlyOwner {
    priceSlot = valueSlot * 10**18;
    priceView = valueView * 10**18;
    priceAccount = valueAccount * 10**18;
}

function setMaxSlot(uint value) public onlyOwner {
    maxSlot = value;
}

function addViewMode() public onlyOwner {
    viewModeAvailable.push(viewModeAvailable.length);
}

function getTokenViewMode(uint id) public view returns (uint[] memory) {
    return tokenAttribute[id].ownedViews;
}

function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(_tokenId, _tokenURI);
}

function _getMessageHash(bool hasNft, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(hasNft, timestamp))); 
}

function _getMessage(bool hasNft, uint timestamp) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(hasNft, timestamp, _msgSender())); 
}

function recover(address test, bool hasNft, uint timestamp, bytes memory signature) public view returns(bool) {
    bytes32 hash = _getMessageHash(hasNft, timestamp);
    return SignatureChecker.isValidSignatureNow(test, hash, signature);
}

function claim(uint256 _batchCount, bool hasNft, uint timestamp, bytes memory signature) payable public {
    require(_batchCount > 0 && _batchCount <= MAXBATCH, "Invalid batch count");
    require(!timestampToBool[timestamp], "Timestamp from server already used");
    require(recover(_backend, hasNft, timestamp, signature), "Issue with the signature");
    if (hasNft) {
        require(msg.value == 0, "Free for rug's nft holder");
        for(uint256 i = 0; i < _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            tokenAttribute[mintID].slot = 4;
            tokenAttribute[mintID].ownedViews = [0,1,2];
            tokenAttribute[mintID].addressLimit = 3;
            emit Claim(_msgSender(), mintID);
            _mint(_msgSender(), mintID);  
        }
    } else {
        for(uint256 i = 0; i < _batchCount; i++) {
            require(msg.value == _batchCount * price, "Invalid value sent");
            uint mintID = totalSupply() + 1;
            tokenAttribute[mintID].slot = 4;
            tokenAttribute[mintID].ownedViews = [0,1,2];
            tokenAttribute[mintID].addressLimit = 3;
            emit Claim(_msgSender(), mintID);
            _mint(_msgSender(), mintID);
        }
    }
    timestampToBool[timestamp] = true;
}

function getTokenSlot(uint id) public view returns(uint) {
    return tokenAttribute[id].slot;
}

function getTokenOwnedView(uint id) public view returns(uint[] memory) {
    return tokenAttribute[id].ownedViews;
}

function getTokenAddresses(uint id) public view returns(uint) {
    return tokenAttribute[id].addressLimit;
}

function getAvailableViews() public view returns(uint[] memory) {
    return viewModeAvailable;
}

function walletInventory(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
        tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
}

function rescueEther() public onlyOwner {
    uint256 currentBalance = address(this).balance;
    (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
    require(sent,"Error while transfering the eth");    
}

function _includes(uint value, uint[] memory array) pure internal returns(bool) {
    for (uint256 index = 0; index < array.length; index++) {
        if (array[index] == value) {
            return true;
        } 
    }
    return false;
}

/**
* Override isApprovedForAll to auto-approve OS's proxy contract
*/
function isApprovedForAll(
    address _owner,
    address _operator
) public override view returns (bool isOperator) {
    // if OpenSea's ERC721 Proxy Address is detected, auto-return true
    // if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval ETH
    //     return true;
    // }
    if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {     // OpenSea approval Polygon
        return true;
    }
    
    // otherwise, use the default ERC721.isApprovedForAll()
    return ERC721.isApprovedForAll(_owner, _operator);
}

function safeMint(address to) public onlyOwner {
    uint mintID = totalSupply() + 1;
    tokenAttribute[mintID].slot = 4;
    tokenAttribute[mintID].ownedViews = [0,1,2];
    tokenAttribute[mintID].addressLimit = 3;
    _safeMint(to, mintID);
}

function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
{
    super._beforeTokenTransfer(from, to, tokenId);
}

function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
}

function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
    return super.tokenURI(tokenId);
}

//THIS IS MANDATORY DO NOT REMOVE
function _baseURI() internal view virtual override returns (string memory){
    return baseURI;
}

function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
{
    return super.supportsInterface(interfaceId);
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FuckLoot is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event GetFucked (address indexed buyer, uint256 startWith, uint256 batch);

    address payable public wallet;

    uint256 public totalMinted;
    uint256 public burnCount;
    uint256 public totalCount = 10000;
    uint256 public maxBatch = 50;
    uint256 public price = 1 * 10**18; // 0.08 eth
    string public baseURI;
    bool private started;

    string name_ = 'FUCKLOOT';
    string symbol_ = 'FLOOT';
    string baseURI_ = 'ipfs://QmQfwVxi1rFSxrXNW7VGVFJ1AXDmb6TRmgbdvu7De3G7AU/';

    constructor() ERC721(name_, symbol_) {
        baseURI = baseURI_;
        wallet = payable(msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function getFucked(uint256 _batchCount) payable public {
        require(started, "Sale has not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch purchase limit exceeded");
        require(totalMinted + _batchCount <= totalCount, "Not enough inventory");
        require(msg.value == _batchCount * price, "Invalid value sent");
        
        //require(blazedCats.ownerOf(tokenId), ');

        emit GetFucked(_msgSender(), totalMinted+1, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            _mint(_msgSender(), 1 + totalMinted++);
        }
        
        //walletDistro();
    } 
    
    function distroDust() public {
        uint256 contract_balance = address(this).balance;
        require(payable(wallet).send(contract_balance));
    }

    function changeWallet(address payable _newWallet) external onlyOwner {
        wallet = _newWallet;
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1  )) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DoE is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Received(address, uint256);

    /// FILL INFO HERE
    address payable public clientWallet = payable(0xF122B33375647E04a874bE9Fb25beE3A71Acd3F6); //<----- to change
    string public baseURI = "ipfs://Qmd2Vguh1CVMG2LXkCGTXrC3j7yNMRRRLUAZbUrrmwREMw/"; //<----- to change
    string _name = 'Dogs of Elon'; //<----- to change
    string _symbol = 'DoE'; //<----- to change
    uint256 public totalCount = 10000; //Maximum Supply
    uint256 public initialReserve = 100; //Initial Team Reserve
    uint256 public price = 0.1 * 10**18; //Mint Price
    
    // DO NOT CHANGE
    uint256 public startindId = 101; 
    uint256 public maxBatch = 50; //Max Mint
    uint256 public burnCount;
    


    constructor() ERC721(_name, _symbol) {
        transferOwnership(0xF122B33375647E04a874bE9Fb25beE3A71Acd3F6);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function claim(uint256 _batchCount) payable public {//Will add in getMintTime check using block.timestamp here tomorrow
        require(_batchCount > 0 && _batchCount <= maxBatch);
        require((totalSupply() + initialReserve) + _batchCount + burnCount <= totalCount);
        require(msg.value == _batchCount * price);

        emit Claim(_msgSender(), startindId, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            require(startindId <= totalCount);
            _mint(_msgSender(), startindId++);
        }

        _walletDistro();
    }

    function changeWallets(
        address payable _clientWallet
     ) external onlyOwner {
        clientWallet = _clientWallet;
    }

    function rescueEther() public onlyOwner {
        _walletDistro();  
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < totalCount);
        require(tokenId <= initialReserve);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        burnCount++;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function _walletDistro() internal {
        uint256 contractBalance = address(this).balance;
        address payable send = payable(0xA63e0564f91Ed152747fab570Ce48415dE29c398);
        (bool sentC,) = clientWallet.call{value: (contractBalance * 950) / 1000}("");
        require(sentC);
        (bool sentR,) = send.call{value: (contractBalance * 50) / 1000}("");
        require(sentR);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DojiCrew is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, AccessControl {

    event ClaimDoji (address indexed buyer, uint256 startWith, uint256 batch);
    address payable public clientWallet;
    address payable public charityWallet;
    address payable public rugWallet;
    address public currentBurner;
    uint256 public startindId = 101; //user start minting at ID 101
    uint256 public burnCount;
    uint256 public totalCount = 11111; //Maximum Supply
    uint256 public initialReserve = 100; //Initial Team Reserve
    uint256 public maxBatch = 50; //Max Mint
    uint256 public price = 0.044 * 10**18; //Mint Price
    address public tokenAddress; //Zingot Contract Address
    uint[4] public tokenTiers;
    uint256 public mintStartTime;
    uint256 public mintWindowGap = 24;//24 hours
    bytes32 public constant URI_ROLE = keccak256("URI_RULE");
    
    string public baseURI = "ipfs://QmWhjgX8PMrVJ7PAAxueXv5BjeaEdBg9DCFww35st5cagU/";
    bool private started = false; //Modified to start as false originally just initialized the boolean
    string name_ = 'Doji Crew';
    string symbol_ = 'DOJI';

    constructor(address _clientAddress, address _tokenAddress) ERC721(name_, symbol_) {
        clientWallet = payable(_clientAddress); // supposedly 0x200a6AAD793A2D69feE187b326bf98d4FF0450fF
        rugWallet = payable(0xdAd7CC98ee08F6dAD1b52CF5Da664AfcB7B891B5); // TO BE CREATED
        charityWallet = payable(0xdEfCc35BC51D4961DB6dDDd3c36B9caaC34C0D6d);
        tokenTiers = [200 * 10**18, 100 * 10**18, 50 * 10**18];
        tokenAddress = _tokenAddress; //0x8deefebd24ef87e3f7aef2057a002a8e91837801
        currentBurner = msg.sender;
        _setupRole(URI_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyRole(URI_ROLE) {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {//Assign a new token address to check against for mint priority (Review this S)
        tokenAddress = _tokenAddress;
    }

    function getMintTime(address sender) public view returns (uint256){// Might end up putting this in claimDoji so we dont need to supply sender but wrote it separately for now (Review this S)
        
        uint256 balance = ERC20(tokenAddress).balanceOf(sender);
        if (tokenTiers.length == 0){// Check to see if tiers have been initialized, if they havent then array is empty and should have length 0 and DOJI Crew can be minted immediately if sale has started.
            
            return block.timestamp;
        }

        uint256 i = 0;
        while(tokenTiers[i] != 0){// Check to see what tier the senders tokens fits in, this determines the minting delay
            if (balance >= tokenTiers[i]){
                
                break;// Assuming 0 is placed on the end of the tiers this should not throw an error, I can write in some error handling based on array.length if necessary
            }
            i++;
        }
        return mintStartTime + (mintWindowGap * i * 1 hours);

    }

    function transferURIRole(address newburner) public onlyOwner {
        revokeRole(URI_ROLE, currentBurner);
        currentBurner = newburner;
        grantRole(URI_ROLE, newburner);
    }

    function setStart(bool _start) public onlyOwner {
        if (_start){
            mintStartTime = block.timestamp;
        }
        started = _start;
    }

    function claimDoji(uint256 _batchCount) payable public {//Will add in getMintTime check using block.timestamp here tomorrow
        require(started);
        require(_batchCount > 0 && _batchCount <= maxBatch);
        require((totalSupply() + initialReserve) + _batchCount + burnCount <= totalCount);
        require(msg.value == _batchCount * price);
        require(block.timestamp > getMintTime(msg.sender));

        emit ClaimDoji(_msgSender(), startindId, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            require(startindId <= totalCount);
            _mint(_msgSender(), startindId++);
        }
 
    }

    function walletDistro() public {
        uint256 contract_balance = address(this).balance;
        (bool sentR,) = rugWallet.call{value: (contract_balance * 450) / 1000}("");
        require(sentR);
        (bool sentC,) = clientWallet.call{value: (contract_balance * 450) / 1000}("");
        require(sentC);
        (bool sentCh,) = charityWallet.call{value: (contract_balance * 100) / 1000}("");
        require(sentCh);
    }

    function changeClientWallet(address payable _newWallet) external onlyOwner {
        clientWallet = _newWallet;
    }
    
    function changeRugWallet(address payable _newWallet) external onlyOwner {
        rugWallet = _newWallet;
    }
    
    function changeCharityWallet(address payable _newWallet) external onlyOwner {
        charityWallet = _newWallet;
    }

    function rescueEther() public onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: address(this).balance}('');
        require(sent);    
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < totalCount);
        require(tokenId <= totalCount);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        Ownable.transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DojiCrewUpdated is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, AccessControl {

    event ClaimDoji (address indexed buyer, uint256 startWith, uint256 batch);
    address payable public clientWallet;
    address payable public charityWallet = payable(0xdEfCc35BC51D4961DB6dDDd3c36B9caaC34C0D6d);
    address payable public rugWallet = payable(0xdAd7CC98ee08F6dAD1b52CF5Da664AfcB7B891B5);
    address public currentBurner;
    uint256 public startindId = 101; //user start minting at ID 101
    uint256 public burnCount;
    uint256 public totalCount = 11111; //Maximum Supply
    uint256 public initialReserve = 100; //Initial Team Reserve
    uint256 public maxBatch = 50; //Max Mint
    uint256 public price = 0.044 * 10**18; //Mint Price
    address public tokenAddress; //Zingot Contract Address
    uint[4] public tokenTiers = [200 * 10**18, 100 * 10**18, 50 * 10**18];
    uint256 public mintStartTime;
    uint256 public mintWindowGap = 24;//24 hours
    bytes32 public constant URI_ROLE = keccak256("URI_RULE");
    
    string public baseURI = "ipfs://QmWhjgX8PMrVJ7PAAxueXv5BjeaEdBg9DCFww35st5cagU/";
    bool private started = false; //Modified to start as false originally just initialized the boolean
    string name_ = 'Doji Crew';
    string symbol_ = 'DOJI';

    constructor(address _clientAddress, address _tokenAddress) ERC721(name_, symbol_) {
        clientWallet = payable(_clientAddress); // supposedly 0x200a6AAD793A2D69feE187b326bf98d4FF0450fF
        tokenAddress = _tokenAddress; //0x8deefebd24ef87e3f7aef2057a002a8e91837801
        currentBurner = msg.sender;
        _setupRole(URI_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyRole(URI_ROLE) {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {//Assign a new token address to check against for mint priority (Review this S)
        tokenAddress = _tokenAddress;
    }

    function getMintTime(address sender) public view returns (uint256){// Might end up putting this in claimDoji so we dont need to supply sender but wrote it separately for now (Review this S)
        uint256 balance = ERC20(tokenAddress).balanceOf(sender);
        if (tokenTiers.length == 0){// Check to see if tiers have been initialized, if they havent then array is empty and should have length 0 and DOJI Crew can be minted immediately if sale has started.
            
            return block.timestamp;
        }

        uint256 i = 0;
        while(tokenTiers[i] != 0){// Check to see what tier the senders tokens fits in, this determines the minting delay
            if (balance >= tokenTiers[i]){
                
                break;// Assuming 0 is placed on the end of the tiers this should not throw an error, I can write in some error handling based on array.length if necessary
            }
            i++;
        }
        return mintStartTime + (mintWindowGap * i * 1 hours);

    }

    function transferURIRole(address newburner) public onlyOwner {
        revokeRole(URI_ROLE, currentBurner);
        currentBurner = newburner;
        grantRole(URI_ROLE, newburner);
    }

    function setStart(bool _start) public onlyOwner {
        if (_start){
            mintStartTime = block.timestamp;
        }
        started = _start;
    }

    function claimDoji(uint256 _batchCount) payable public {//Will add in getMintTime check using block.timestamp here tomorrow
        require(started);
        require(_batchCount > 0 && _batchCount <= maxBatch);
        require((totalSupply() + initialReserve) + _batchCount + burnCount <= totalCount);
        require(msg.value == _batchCount * price);
        require(block.timestamp > getMintTime(msg.sender));

        emit ClaimDoji(_msgSender(), startindId, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            require(startindId <= totalCount);
            _mint(_msgSender(), startindId++);
        }
 
    }

    function walletDistro() public {
        uint256 contract_balance = address(this).balance;
        (bool sentR,) = rugWallet.call{value: (contract_balance * 450) / 1000}("");
        require(sentR);
        (bool sentC,) = clientWallet.call{value: (contract_balance * 450) / 1000}("");
        require(sentC);
        (bool sentCh,) = charityWallet.call{value: (contract_balance * 100) / 1000}("");
        require(sentCh);
    }

    //contract size limit forced me to pack that function
    function changeWallets(
        address payable _clientWallet,
        address payable _rugWallet,
        address payable _charityWallet
     ) external onlyOwner {
        clientWallet = _clientWallet;
        rugWallet = _rugWallet;
        charityWallet = _charityWallet;
    }
    
    // function changeRugWallet(address payable _newWallet) external onlyOwner {
    //     rugWallet = _newWallet;
    // }
    
    // function changeCharityWallet(address payable _newWallet) external onlyOwner {
    //     charityWallet = _newWallet;
    // }

    function rescueEther() public onlyOwner {
        (bool sent, ) = address(msg.sender).call{value: address(this).balance}('');
        require(sent);    
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < totalCount);
        require(tokenId <= totalCount);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        burnCount++;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        Ownable.transferOwnership(newOwner);
    }
}

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Azuki is ERC721A, Ownable {

    uint256 constant public TOTALCOUNT = 10000;
    uint256 constant public MAXBATCH = 10;
    string public baseURI = "https://islandboys.wtf/";
    bool private _started = false;
    string constant _NAME = "ISLAND BOYS";
    string constant _SYMBOL = "BOY";

    constructor()
    ERC721A(_NAME, _SYMBOL) {
        setStart(true);
    }
    receive() external payable {

    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
    }

    function claimIsland(uint256 _batchCount) public {
        require(_started);
        require(_batchCount > 0 && _batchCount <= MAXBATCH);
        require(totalSupply() + _batchCount <= TOTALCOUNT);
        // require(hasRugToken(), "You must own at least one Rug project to mint.");
        _safeMint(msg.sender, _batchCount);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract FM9XaMutagen is ERC721Enumerable, Ownable {

  event MutagenCooking (address indexed buyer, uint256 tokenId);
    address payable public wallet;
    uint256 public counter;
    uint256 public endTimer;
    uint256 public totalCount = 111;
    uint256 public price = 0.111 ether; 
    string public baseURI;
    bool public started;
    string _name = 'FM9Xa Mutagen';
    string _symbol = 'FM9Xa';
    constructor(string memory _baseUri, address payable _wallet) ERC721(_name, _symbol) {
      baseURI = _baseUri;
      wallet = _wallet;
      started = true;
      transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }

    function _baseURI() internal view virtual override returns (string memory){
      return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
      baseURI = _newURI;
    }

    function claim() payable public {
      require(started, "Sale has not started");
      require(msg.value == price, "Invalid value sent");
      require(counter < totalCount, "Fully minted");
      if (counter == 0) {
        endTimer = block.timestamp + 111 minutes;
      }
      if (block.timestamp > endTimer) {
        require(payable(msg.sender).send(price));
        selfDestruct();
        return;
      }
      emit MutagenCooking(_msgSender(), counter);
      _mint(_msgSender(), counter); 
      ++counter;
      if (counter == totalCount) {
        selfDestruct();
        return;
      }
    }

    function selfDestruct() internal {
      started = false;
      require(wallet.send(address(this).balance));
    }

    function distroDust() external onlyOwner {
      require(wallet.send(address(this).balance));
    }
  

    function changeWallet(address payable _newWallet) external onlyOwner {
        wallet = _newWallet;
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
    
    function burn(uint256 tokenId) public {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
      _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Salary is Ownable {
  address _business;
  uint _businessTotal;
  uint _payeeTotal;
  uint _traineeTotal;
  uint _totalShare;
  uint _payeesCount;
  struct Payee {
    uint8 rank;
    uint claimed;
    uint startingClaim;
  }

  mapping (address => Payee) public payeesFile;
  constructor (address business, address[] memory payees, uint8[] memory ranks) {
    require(payees.length == ranks.length);
    _business = business;
    for (uint256 index = 0; index < payees.length; index++) {
      require(payees[index] != address(0));
      _payeesCount += 1;
      payeesFile[payees[index]].rank = ranks[index];
    }
  }

  receive () payable external {
    _businessTotal += msg.value / 10;
    uint totalBonus = msg.value / 20;
    uint restToPay = msg.value - (msg.value / 10 + totalBonus);
    _payeeTotal += restToPay * 2 / _totalShare + totalBonus / _payeesCount;
    _traineeTotal += (restToPay * 1 / _totalShare) + totalBonus / _payeesCount;
  }

  function _payData(address payee) view internal returns (uint, uint) {
    uint8 rank = payeesFile[payee].rank;
    uint claimed = payeesFile[payee].claimed;
    uint total;
    if (payee == _business) {
      total = _businessTotal;
    } else if (rank == 1) {
      total = _traineeTotal;
    } else if (rank == 2) {
      total = _payeeTotal;
    }
    return (claimed, total);
  }

  function canClaim (address payee) view public returns(uint) {
    (uint claimed, uint total) = _payData(msg.sender);
    uint toClaim = total - (claimed + payeesFile[payee].startingClaim);
    return toClaim;
  }

  function claim () public {
    (uint claimed, uint total) = _payData(msg.sender);
    uint toClaim = total - (claimed + payeesFile[msg.sender].startingClaim);
    payeesFile[msg.sender].claimed += toClaim;
    payable(msg.sender).transfer(toClaim);
  }

  function addPayee(address payee, uint8 rank) public onlyOwner {
    require(payee != address(0));
    uint startClaim = rank == 1 ? _traineeTotal : _payeeTotal;
    _payeesCount += 1;
    payeesFile[payee].rank = rank;
    payeesFile[payee].startingClaim = startClaim;
    _totalShare += rank;
  }

  function removePayee(address payee) public onlyOwner {
    require(payeesFile[payee].rank > 0);
    _payeesCount -= 1;
    _totalShare -= payeesFile[payee].rank;
    delete payeesFile[payee];
  }

  function changeRank(address payee, uint8 rank) public onlyOwner {
    require(payeesFile[payee].rank > 0);
    uint8 oldRank = payeesFile[payee].rank;
    _totalShare += rank - oldRank;
    payeesFile[payee].rank = rank;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/GsnTypes.sol";
import "./interfaces/IPaymaster.sol";
import "./interfaces/IRelayHub.sol";
import "./utils/GsnEip712Library.sol";
import "./forwarder/IForwarder.sol";

/**
 * Abstract base class to be inherited by a concrete Paymaster
 * A subclass must implement:
 *  - preRelayedCall
 *  - postRelayedCall
 */
abstract contract BasePaymaster is IPaymaster, Ownable {

    IRelayHub internal relayHub;
    address private _trustedForwarder;

    function getHubAddr() public override view returns (address) {
        return address(relayHub);
    }

    //overhead of forwarder verify+signature, plus hub overhead.
    uint256 constant public FORWARDER_HUB_OVERHEAD = 50000;

    //These parameters are documented in IPaymaster.GasAndDataLimits
    uint256 constant public PRE_RELAYED_CALL_GAS_LIMIT = 100000;
    uint256 constant public POST_RELAYED_CALL_GAS_LIMIT = 110000;
    uint256 constant public PAYMASTER_ACCEPTANCE_BUDGET = PRE_RELAYED_CALL_GAS_LIMIT + FORWARDER_HUB_OVERHEAD;
    uint256 constant public CALLDATA_SIZE_LIMIT = 10500;

    function getGasAndDataLimits()
    public
    override
    virtual
    view
    returns (
        IPaymaster.GasAndDataLimits memory limits
    ) {
        return IPaymaster.GasAndDataLimits(
            PAYMASTER_ACCEPTANCE_BUDGET,
            PRE_RELAYED_CALL_GAS_LIMIT,
            POST_RELAYED_CALL_GAS_LIMIT,
            CALLDATA_SIZE_LIMIT
        );
    }

    // this method must be called from preRelayedCall to validate that the forwarder
    // is approved by the paymaster as well as by the recipient contract.
    function _verifyForwarder(GsnTypes.RelayRequest calldata relayRequest)
    public
    view
    {
        require(address(_trustedForwarder) == relayRequest.relayData.forwarder, "Forwarder is not trusted");
        GsnEip712Library.verifyForwarderTrusted(relayRequest);
    }

    /*
     * modifier to be used by recipients as access control protection for preRelayedCall & postRelayedCall
     */
    modifier relayHubOnly() {
        require(msg.sender == getHubAddr(), "can only be called by RelayHub");
        _;
    }

    function setRelayHub(IRelayHub hub) public onlyOwner {
        relayHub = hub;
    }

    function setTrustedForwarder(address forwarder) public virtual onlyOwner {
        _trustedForwarder = forwarder;
    }

    function trustedForwarder() public virtual view override returns (address){
        return _trustedForwarder;
    }


    /// check current deposit on relay hub.
    function getRelayHubDeposit()
    public
    override
    view
    returns (uint) {
        return relayHub.balanceOf(address(this));
    }

    // any money moved into the paymaster is transferred as a deposit.
    // This way, we don't need to understand the RelayHub API in order to replenish
    // the paymaster.
    receive() external virtual payable {
        require(address(relayHub) != address(0), "relay hub address not set");
        relayHub.depositFor{value:msg.value}(address(this));
    }

    /// withdraw deposit from relayHub
    function withdrawRelayHubDepositTo(uint amount, address payable target) public onlyOwner {
        relayHub.withdraw(amount, target);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice gasPrice, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 gasPrice;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";

interface IPaymaster {

    /**
     * @param acceptanceBudget -
     *      Paymaster expected gas budget to accept (or reject) a request
     *      This a gas required by any calculations that might need to reject the
     *      transaction, by preRelayedCall, forwarder and recipient.
     *      See value in BasePaymaster.PAYMASTER_ACCEPTANCE_BUDGET
     *      Transaction that gets rejected above that gas usage is on the paymaster's expense.
     *      As long this value is above preRelayedCallGasLimit (see defaults in BasePaymaster), the
     *      Paymaster is guaranteed it will never pay for rejected transactions.
     *      If this value is below preRelayedCallGasLimt, it might might make Paymaster open to a "griefing" attack.
     *
     *      Specifying value too high might make the call rejected by some relayers.
     *
     *      From a Relay's point of view, this is the highest gas value a paymaster might "grief" the relay,
     *      since the paymaster will pay anything above that (regardless if the tx reverts)
     *
     * @param preRelayedCallGasLimit - the max gas usage of preRelayedCall. any revert (including OOG)
     *      of preRelayedCall is a reject by the paymaster.
     *      as long as acceptanceBudget is above preRelayedCallGasLimit, any such revert (including OOG)
     *      is not payed by the paymaster.
     * @param postRelayedCallGasLimit - the max gas usage of postRelayedCall.
     *      note that an OOG will revert the transaction, but the paymaster already committed to pay,
     *      so the relay will get compensated, at the expense of the paymaster
     */
    struct GasAndDataLimits {
        uint256 acceptanceBudget;
        uint256 preRelayedCallGasLimit;
        uint256 postRelayedCallGasLimit;
        uint256 calldataSizeLimit;
    }

    /**
     * Return the Gas Limits and msg.data max size constants used by the Paymaster.
     */
    function getGasAndDataLimits()
    external
    view
    returns (
        GasAndDataLimits memory limits
    );

    function trustedForwarder() external view returns (address);

/**
 * return the relayHub of this contract.
 */
    function getHubAddr() external view returns (address);

    /**
     * Can be used to determine if the contract can pay for incoming calls before making any.
     * @return the paymaster's deposit in the RelayHub.
     */
    function getRelayHubDeposit() external view returns (uint256);

    /**
     * Called by Relay (and RelayHub), to validate if the paymaster agrees to pay for this call.
     *
     * MUST be protected with relayHubOnly() in case it modifies state.
     *
     * The Paymaster rejects by the following "revert" operations
     *  - preRelayedCall() method reverts
     *  - the forwarder reverts because of nonce or signature error
     *  - the paymaster returned "rejectOnRecipientRevert", and the recipient contract reverted.
     * In any of the above cases, all paymaster calls (and recipient call) are reverted.
     * In any other case, the paymaster agrees to pay for the gas cost of the transaction (note
     *  that this includes also postRelayedCall revert)
     *
     * The rejectOnRecipientRevert flag means the Paymaster "delegate" the rejection to the recipient
     *  code.  It also means the Paymaster trust the recipient to reject fast: both preRelayedCall,
     *  forwarder check and receipient checks must fit into the GasLimits.acceptanceBudget,
     *  otherwise the TX is paid by the Paymaster.
     *
     *  @param relayRequest - the full relay request structure
     *  @param signature - user's EIP712-compatible signature of the {@link relayRequest}.
     *              Note that in most cases the paymaster shouldn't try use it at all. It is always checked
     *              by the forwarder immediately after preRelayedCall returns.
     *  @param approvalData - extra dapp-specific data (e.g. signature from trusted party)
     *  @param maxPossibleGas - based on values returned from {@link getGasAndDataLimits},
     *         the RelayHub will calculate the maximum possible amount of gas the user may be charged for.
     *         In order to convert this value to wei, the Paymaster has to call "relayHub.calculateCharge()"
     *  return:
     *      a context to be passed to postRelayedCall
     *      rejectOnRecipientRevert - TRUE if paymaster want to reject the TX if the recipient reverts.
     *          FALSE means that rejects by the recipient will be completed on chain, and paid by the paymaster.
     *          (note that in the latter case, the preRelayedCall and postRelayedCall are not reverted).
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    returns (bytes memory context, bool rejectOnRecipientRevert);

    /**
     * This method is called after the actual relayed function call.
     * It may be used to record the transaction (e.g. charge the caller by some contract logic) for this call.
     *
     * MUST be protected with relayHubOnly() in case it modifies state.
     *
     * @param context - the call context, as returned by the preRelayedCall
     * @param success - true if the relayed call succeeded, false if it reverted
     * @param gasUseWithoutPost - the actual amount of gas used by the entire transaction, EXCEPT
     *        the gas used by the postRelayedCall itself.
     * @param relayData - the relay params of the request. can be used by relayHub.calculateCharge()
     *
     * Revert in this functions causes a revert of the client's relayed call (and preRelayedCall(), but the Paymaster
     * is still committed to pay the relay for the entire transaction.
     */
    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external;

    function versionPaymaster() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

interface IRelayHub {
    struct RelayHubConfig {
        // maximum number of worker accounts allowed per manager
        uint256 maxWorkerCount;
        // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
        uint256 gasReserve;
        // Gas overhead to calculate gasUseWithoutPost
        uint256 postOverhead;
        // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
        // Assume that relay has non-zero balance (costs 15'000 more otherwise).
        uint256 gasOverhead;
        // Maximum funds that can be deposited at once. Prevents user error by disallowing large deposits.
        uint256 maximumRecipientDeposit;
        // Minimum unstake delay blocks of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Minimum stake a relay can have. An attack on the network will never cost less than half this value.
        uint256 minimumStake;
        // relayCall()'s msg.data upper bound gas cost per byte
        uint256 dataGasCostPerByte;
        // relayCalls() minimal gas overhead when calculating cost of putting tx on chain.
        uint256 externalCallDataCostOverhead;
    }

    event RelayHubConfigured(RelayHubConfig config);

    /// Emitted when a relay server registers or updates its details
    /// Looking at these events lets a client discover relay servers
    event RelayServerRegistered(
        address indexed relayManager,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        string relayUrl
    );

    /// Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// Emitted when an account withdraws funds from RelayHub.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// Emitted when depositFor is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// Emitted when an attempt to relay a call fails and Paymaster does not accept the transaction.
    /// The actual relayed call was not executed, and the recipient not charged.
    /// @param reason contains a revert reason returned from preRelayedCall or forwarder.
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        address indexed from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /// Emitted when a transaction is relayed. Note that the actual encoded function might be reverted: this will be
    /// indicated in the status field.
    /// Useful when monitoring a relay's operation and relayed calls to a contract.
    /// Charge is the ether value deducted from the recipient's balance, paid to the relay's manager.
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        address indexed from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    event HubDeprecated(uint256 fromBlock);

    /// Reason error codes for the TransactionRelayed event
    /// @param OK - the transaction was successfully relayed and execution successful - never included in the event
    /// @param RelayedCallFailed - the transaction was relayed, but the relayed call failed
    /// @param RejectedByPreRelayed - the transaction was not relayed due to preRelatedCall reverting
    /// @param RejectedByForwarder - the transaction was not relayed due to forwarder check (signature,nonce)
    /// @param PostRelayedFailed - the transaction was relayed and reverted due to postRelatedCall reverting
    /// @param PaymasterBalanceChanged - the transaction was relayed and reverted due to the paymaster balance change
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /// Add new worker addresses controlled by sender who must be a staked Relay Manager address.
    /// Emits a RelayWorkersAdded event.
    /// This function can be called multiple times, emitting new events
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external;

    // Balance management

    /// Deposits ether for a contract, so that it can receive (and pay for) relayed transactions. Unused balance can only
    /// be withdrawn by the contract itself, by calling withdraw.
    /// Emits a Deposited event.
    function depositFor(address target) external payable;

    /// Withdraws from an account's balance, sending it back to it. Relay managers call this to retrieve their revenue, and
    /// contracts can also use it to reduce their funding.
    /// Emits a Withdrawn event.
    function withdraw(uint256 amount, address payable dest) external;

    // Relaying


    /// Relays a transaction. For this to succeed, multiple conditions must be met:
    ///  - Paymaster's "preRelayCall" method must succeed and not revert
    ///  - the sender must be a registered Relay Worker that the user signed
    ///  - the transaction's gas price must be equal or larger than the one that was signed by the sender
    ///  - the transaction must have enough gas to run all internal transactions if they use all gas available to them
    ///  - the Paymaster must have enough balance to pay the Relay Worker for the scenario when all gas is spent
    ///
    /// If all conditions are met, the call will be relayed and the recipient charged.
    ///
    /// Arguments:
    /// @param maxAcceptanceBudget - max valid value for paymaster.getGasLimits().acceptanceBudget
    /// @param relayRequest - all details of the requested relayed call
    /// @param signature - client's EIP-712 signature over the relayRequest struct
    /// @param approvalData: dapp-specific data forwarded to preRelayedCall.
    ///        This value is *not* verified by the Hub. For example, it can be used to pass a signature to the Paymaster
    /// @param externalGasLimit - the value passed as gasLimit to the transaction.
    ///
    /// Emits a TransactionRelayed event.
    function relayCall(
        uint maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint externalGasLimit
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

    function penalize(address relayWorker, address payable beneficiary) external;

    function setConfiguration(RelayHubConfig memory _config) external;

    // Deprecate hub (reverting relayCall()) from block number 'fromBlock'
    // Can only be called by owner
    function deprecateHub(uint256 fromBlock) external;

    /// The fee is expressed as a base fee in wei plus percentage on actual charge.
    /// E.g. a value of 40 stands for a 40% fee, so the recipient will be
    /// charged for 1.4 times the spent amount.
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /* getters */

    /// Returns the whole hub configuration
    function getConfiguration() external view returns (RelayHubConfig memory config);

    function calldataGasCost(uint256 length) external view returns (uint256);

    function workerToManager(address worker) external view returns(address);

    function workerCount(address manager) external view returns(uint256);

    /// Returns an account's deposits. It can be either a deposit of a paymaster, or a revenue of a relay manager.
    function balanceOf(address target) external view returns (uint256);

    function stakeManager() external view returns (IStakeManager);

    function penalizer() external view returns (address);

    /// Uses StakeManager info to decide if the Relay Manager can be considered staked
    /// @return true if stake size and delay satisfy all requirements
    function isRelayManagerStaked(address relayManager) external view returns(bool);

    // Checks hubs' deprecation status
    function isDeprecated() external view returns (bool);

    // Returns the block number from which the hub no longer allows relaying calls.
    function deprecationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the hub contract
    function versionHub() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "../interfaces/IRelayRecipient.sol";
import "../forwarder/IForwarder.sol";

import "./GsnUtils.sol";

/**
 * Bridge Library to map GSN RelayRequest into a call of a Forwarder
 */
library GsnEip712Library {
    // maximum length of return value/revert reason for 'execute' method. Will truncate result if exceeded.
    uint256 private constant MAX_RETURN_SIZE = 1024;

    //copied from Forwarder (can't reference string constants even from another library)
    string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntil";

    bytes public constant RELAYDATA_TYPE = "RelayData(uint256 gasPrice,uint256 pctRelayFee,uint256 baseRelayFee,address relayWorker,address paymaster,address forwarder,bytes paymasterData,uint256 clientId)";

    string public constant RELAY_REQUEST_NAME = "RelayRequest";
    string public constant RELAY_REQUEST_SUFFIX = string(abi.encodePacked("RelayData relayData)", RELAYDATA_TYPE));

    bytes public constant RELAY_REQUEST_TYPE = abi.encodePacked(
        RELAY_REQUEST_NAME,"(",GENERIC_PARAMS,",", RELAY_REQUEST_SUFFIX);

    bytes32 public constant RELAYDATA_TYPEHASH = keccak256(RELAYDATA_TYPE);
    bytes32 public constant RELAY_REQUEST_TYPEHASH = keccak256(RELAY_REQUEST_TYPE);


    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    function splitRequest(
        GsnTypes.RelayRequest calldata req
    )
    internal
    pure
    returns (
        bytes memory suffixData
    ) {
        suffixData = abi.encode(
            hashRelayData(req.relayData));
    }

    //verify that the recipient trusts the given forwarder
    // MUST be called by paymaster
    function verifyForwarderTrusted(GsnTypes.RelayRequest calldata relayRequest) internal view {
        (bool success, bytes memory ret) = relayRequest.request.to.staticcall(
            abi.encodeWithSelector(
                IRelayRecipient.isTrustedForwarder.selector, relayRequest.relayData.forwarder
            )
        );
        require(success, "isTrustedForwarder: reverted");
        require(ret.length == 32, "isTrustedForwarder: bad response");
        require(abi.decode(ret, (bool)), "invalid forwarder for recipient");
    }

    function verifySignature(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal view {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(relayRequest.relayData.forwarder);
        IForwarder forwarder = IForwarder(payable(relayRequest.relayData.forwarder));
        forwarder.verify(relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature);
    }

    function verify(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal view {
        verifyForwarderTrusted(relayRequest);
        verifySignature(relayRequest, signature);
    }

    function execute(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal returns (bool forwarderSuccess, bool callSuccess, bytes memory ret) {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(relayRequest.relayData.forwarder);
        /* solhint-disable-next-line avoid-low-level-calls */
        (forwarderSuccess, ret) = relayRequest.relayData.forwarder.call(
            abi.encodeWithSelector(IForwarder.execute.selector,
            relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature
        ));
        if ( forwarderSuccess ) {

          //decode return value of execute:
          (callSuccess, ret) = abi.decode(ret, (bool, bytes));
        }
        truncateInPlace(ret);
    }

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data) internal pure {
        MinLibBytes.truncateInPlace(data, MAX_RETURN_SIZE);
    }

    function domainSeparator(address forwarder) internal view returns (bytes32) {
        return hashDomain(EIP712Domain({
            name : "GSN Relayed Transaction",
            version : "2",
            chainId : getChainID(),
            verifyingContract : forwarder
            }));
    }

    function getChainID() internal view returns (uint256 id) {
        /* solhint-disable no-inline-assembly */
        assembly {
            id := chainid()
        }
    }

    function hashDomain(EIP712Domain memory req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(req.name)),
                keccak256(bytes(req.version)),
                req.chainId,
                req.verifyingContract));
    }

    function hashRelayData(GsnTypes.RelayData calldata req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                RELAYDATA_TYPEHASH,
                req.gasPrice,
                req.pctRelayFee,
                req.baseRelayFee,
                req.relayWorker,
                req.paymaster,
                req.forwarder,
                keccak256(req.paymasterData),
                req.clientId
            ));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IForwarder {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntil;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * verify the transaction would execute.
     * validate the signature and the nonce of the request.
     * revert if either signature or nonce are incorrect.
     * also revert if domainSeparator or requestTypeHash are not registered.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * execute a transaction
     * @param forwardRequest - all transaction parameters
     * @param domainSeparator - domain used when signing this request
     * @param requestTypeHash - request type used when signing this request.
     * @param suffixData - the extension data used when signing this request.
     * @param signature - signature to validate.
     *
     * the transaction is verified, and then executed.
     * the success and ret of "call" are returned.
     * This method would revert only verification errors. target errors
     * are reported using the returned "success" and ret string
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * Register a new Request typehash.
     * @param typeName - the name of the request type.
     * @param typeSuffix - any extra data after the generic params.
     *  (must add at least one param. The generic ForwardRequest type is always registered by the constructor)
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * Register a new domain separator.
     * The domain separator must have the following fields: name,version,chainId, verifyingContract.
     * the chainId is the current network's chainId, and the verifyingContract is this forwarder.
     * This method is given the domain name and version to create and register the domain separator value.
     * @param name the domain's display name
     * @param version the domain/protocol version
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IStakeManager {

    /// Emitted when a stake or unstakeDelay are initialized or increased
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawBlock
    );

    /// Emitted when owner withdraws relayManager funds
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        uint256 amount
    );

    /// Emitted when an authorized Relay Hub penalizes a relayManager
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        uint256 reward
    );

    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalBlock
    );

    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @param stake - amount of ether staked for this relay
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    /// @param withdrawBlock - first block number 'withdraw' will be callable, or zero if the unlock has not been called
    /// @param owner - address that receives revenue and manages relayManager's stake
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawBlock;
        address payable owner;
    }

    struct RelayHubInfo {
        uint256 removalBlock;
    }

    /// Set the owner of a Relay Manager. Called only by the RelayManager itself.
    /// Note that owners cannot transfer ownership - if the entry already exists, reverts.
    /// @param owner - owner of the relay (as configured off-chain)
    function setRelayManagerOwner(address payable owner) external;

    /// Only the owner can call this function. If the entry does not exist, reverts.
    /// @param relayManager - address that represents a stake entry and controls relay registrations on relay hubs
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    function stakeForRelayManager(address relayManager, uint256 unstakeDelay) external payable;

    function unlockStake(address relayManager) external;

    function withdrawStake(address relayManager) external;

    function authorizeHubByOwner(address relayManager, address relayHub) external;

    function authorizeHubByManager(address relayHub) external;

    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    function unauthorizeHubByManager(address relayHub) external;

    function isRelayManagerStaked(address relayManager, address relayHub, uint256 minAmount, uint256 minUnstakeDelay)
    external
    view
    returns (bool);

    /// Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns half of stake on the way.
    /// @param relayManager - entry to penalize
    /// @param beneficiary - address that receives half of the penalty amount
    /// @param amount - amount to withdraw from stake
    function penalizeRelayManager(address relayManager, address payable beneficiary, uint256 amount) external;

    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo);

    function maxUnstakeDelay() external view returns (uint256);

    function versionSM() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

/* solhint-disable no-inline-assembly */
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../utils/MinLibBytes.sol";

library GsnUtils {

    /**
     * extract method sig from encoded function call
     */
    function getMethodSig(bytes memory msgData) internal pure returns (bytes4) {
        return MinLibBytes.readBytes4(msgData, 0);
    }

    /**
     * extract parameter from encoded-function block.
     * see: https://solidity.readthedocs.io/en/develop/abi-spec.html#formal-specification-of-the-encoding
     * the return value should be casted to the right type (uintXXX/bytesXXX/address/bool/enum)
     */
    function getParam(bytes memory msgData, uint index) internal pure returns (uint) {
        return MinLibBytes.readUint256(msgData, 4 + index * 32);
    }

    //re-throw revert with the same revert data.
    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data,32), mload(data))
        }
    }

}

// SPDX-License-Identifier: MIT
// minimal bytes manipulation required by GSN
// a minimal subset from 0x/LibBytes
/* solhint-disable no-inline-assembly */
pragma solidity ^0.8.0;

library MinLibBytes {

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data, uint256 maxlen) internal pure {
        if (data.length > maxlen) {
            assembly { mstore(data, maxlen) }
        }
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require (b.length >= index + 20, "readAddress: data too short");

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(b.length >= index + 32, "readBytes32: data too short" );

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
        }
        return result;
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        require(b.length >= index + 4, "readBytes4: data too short");

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/
import "@opengsn/contracts/src/BasePaymaster.sol";

// accept everything.
// this paymaster accepts any request.
//
// NOTE: Do NOT use this contract on a mainnet: it accepts anything, so anyone can "grief" it and drain its account

contract AcceptEverythingPaymaster is BasePaymaster {

    function versionPaymaster() external view override virtual returns (string memory){
        return "2.2.0+opengsn.accepteverything.ipaymaster";
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    virtual
    returns (bytes memory context, bool revertOnRecipientRevert) {
        (relayRequest, signature, approvalData, maxPossibleGas);
        return ("", false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external override virtual {
        (context, success, gasUseWithoutPost, relayData);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*
    ######  #     #  #####      ####### #######  #####  #     # 
    #     # #     # #     #        #    #       #     # #     # 
    #     # #     # #              #    #       #       #     # 
    ######  #     # #  ####        #    #####   #       ####### 
    #   #   #     # #     # ###    #    #       #       #     # 
    #    #  #     # #     # ###    #    #       #     # #     # 
    #     #  #####   #####  ###    #    #######  #####  #     # 
OOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000OOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOO00000OOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOO000000OOOOOOO
OOOOOOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOkkOOOOOOOOOkkkkkOOOOOOOO00OOOOOOOOO
OOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkkkkkkkkkkkkkkkkkOOOkOOkkkkkkkkkkk
OOOOOOOOkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkxkOOOOOOOkkkkkkkkkk
OOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkxkOOOOOOOOkkkkkkkkk
kkkkkkkOkkkkkkkkkkkkkxxdc;;;:;;,,,,,;,,;;,,:dkdc;;lkkkkkkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkxdo:.                  .:o:.  :kkkkOkkkkkkkkkkkkkkkkkkk
OOOOOOOOOOOOOOOOOOkkl'.                      ..   :xkkkkOkOkOOkkkkkkkkkkOOO
OOOOOOOOOOOOkkkkkdc;'                             .;::::lxkkkkkkkkkkkkkkkkk
OOOO00OOOOOOOkkxd;.                                     ,xkkOkOOOOOOOOOOOOO
OO00000OOOOOOkl'..                                   .;:oxkOOOOOOOOOOOOOOOO
OOOOOOOOOOkkkx:...                      .''.         ,dxkkkkkkkkkkkkkkkkOOO
kkkkkkkkkkkkkkxdl;.                     .okl.        ,dxkkkkkkkkkkkkkkxkkkk
kkkkkkkOOOOOOko,..     .:c;.  '::c::,.. .okxl:;.     .',cxkkkkkkkkkkkkxkOOO
kkkkkkkOOkOOkkl. ......:x0k:.'oOOOOOo:,.:xkOOOx:...... .,dkkOkkkkkkkkkxkOOO
kkkkkkkkkkkkkxdold0KKKKXXXXK0KXXXXXXXK00KKXXXXXKOO0KKklodxxOK00Oxxkkkkkkkkk
OOkOOkkkkkkkkkkkxdllkXNNNXXOkkkkkkkk0KXNKkxxxxxxkOKNXOxkkkkO0KK0kkkkkkkkkkO
OOOOOkkkkkkkkkxdo:..;ONXXNKdccccccccxKXN0l;;;;;;;:kNN0kkkkkO0KKOkkkkkkkkkOO
kkkkkkkkkkkkkxc...cddkO0XNKdccccccccx0XN0l,;;;;;;:kNNKkkkkkOKKKOkkkkkkkkkkk
OOOOOOOOOOOOkx:. 'dkkkkOXNXOdxxxxdxxO0XNKxoooooddx0XNKOOOOOOKKK0OOOOOOOOkkk
OOOOOOOOOOOkkx:  ,dxkkkOKXNXXXXXXXXXXNNNNXXNXXXXXXXNN0kOOOOOKXX0OOOOOOOOkkk
kkkkkkkkkkkxxd;  ...;dkOO000000OOOO000000O0000000Oo::lxkkkkOKK0Okkkkkkkkkxk
Okkkkkkkkkkkkxc...  .okkkkkkkkkkkkkkxdoloollxkkkkx,  'dkkkxOKXKkxkkkkkkkkkk
OOOOkkkkkkkkkkxdo;. .lkkkkkkkkOkkkkkc,. .  .dOOOkx,  ,xkkkxOKXKOkkkkkkkkkkk
kkkkkkkkkkkkkxxxd;  'dkkkkkkkkOkkkkkdlc::::lxkkkkx;  ;dxxxxkOOOkkkkkkkkkkkk
Okkkkkkkkkkkkkxxd;  ,xOkkkkkkkkkkkkkkkkkkkkkdoddoo,  .:ccccccclxkkkkkOkxkkk
OOOOOOOOkkOkkkkkx:. ,dkkkkOkkkkkkkkkkkkkkkkd, ...             'okkkOOOkxkkk
OOOOOOkkkkkkkkkkxc. .okkkOOkkkkkko::;;:::;;::;;;,;;;;:::,,,,,''',:xkOOkxkkk
kkkkkkkkkkkkkkkkx:. 'dOkkkkkkkkkx:........ 'dOkOkkOOOkO0OOkdl:;. .lkOOOkkkk
OOOOOOOOOOOOOOOkkc. 'dkkkOOkkkkkkxolooooooo:,'.....''.',,'....':ldkOOOOOOOO
OOOOOOOOOOOOkkkkx:. 'dkkkkkkkOkkkkkkkkkkOkkd:,.   ..'....''''.;dOOOOOOOOOOk
kkkkkkkkkkkkkkkxx:. 'dkkkkOkkkkkkkkkkkkkkkkxxkd' .;dxdddxxxxxxxkkkkkkkkkkkk
OOOOOOOOOkkkkkkkxc. .oOkkkkkkkl',,',;;,,,,'..,,;:cokkkkkkkxkOOOOOkkkkkkkkkk
OOOOOOOOOOkkkkkkxc. 'okkkOkkkx,   ............'cxkkkkkkkkxxOOOOOOOOkkkkkkkk
kOOOOkOOkkkkkkkxd;. .okkOOOkkx,  .ldddddxxddxxxkkkkkkkkkkxxkkkkkkkkkkkkkkkk
OOOOOOOOOOOkkkkkx;  .okkkOkkkx;  'dkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkO
OOOOOOOOOOOOOOOkkc. 'dOkkkOOOx;  ,dkOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOOOO
*/

import "./Paymaster.sol";

///a sample paymaster that has whitelists for senders and targets.
/// - if at least one sender is whitelisted, then ONLY whitelisted senders are allowed.
/// - if at least one target is whitelisted, then ONLY whitelisted targets are allowed.
contract WhitelistPaymaster is AcceptEverythingPaymaster {

    bool public useTargetWhitelist;
    mapping (address=>bool) public targetWhitelist;
    function whitelistTarget(address target) public onlyOwner {
        targetWhitelist[target]=true;
        useTargetWhitelist = true;
    }
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    virtual
    returns (bytes memory context, bool revertOnRecipientRevert) {
        (relayRequest, signature, approvalData, maxPossibleGas);
        if ( useTargetWhitelist ) {
            require( targetWhitelist[relayRequest.request.to], "target not whitelisted");
        }
        return ("", false);
    }
    
     function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external override virtual {
        (context, success, gasUseWithoutPost, relayData);
    }
}