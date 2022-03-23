/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.8.0;


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

pragma solidity ^0.8.0;


library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
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

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;  
    string private _symbol;    
    mapping (uint256 => address) private _owners; 
    mapping (address => uint256) private _balances;  
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

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
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

pragma solidity ^0.8.0;

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;  
    mapping(uint256 => uint256) private _ownedTokensIndex; 
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

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

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; 
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
}

pragma solidity ^0.8.0;



contract Terrain is ERC721Enumerable, Ownable {

    using Strings for uint256;

    struct Collection {
        uint128 tokenPriceInWei;
        uint32 tokensMinted;
        uint32 maxTokensAvailable;
        uint32 collectionNumber;
        bool created;
        bool locked; 
        bool active; 
        string name;
        string description;
        string baseURI;
    }

    mapping(uint256 => Collection) public collections;

    uint256 constant ONE_MILLION = 1_000_000;
    uint256 public nextCollectionNumber = 1;
    string public customURI;

    constructor(string memory _customURI) ERC721("Terrain", "TNT"){
        customURI = _customURI;
    }

    modifier ifCollectionExists(uint256 _collectionNumber) {
        require(collections[_collectionNumber].created, "Collection has not been created yet");
        _;
    }

    modifier ifCollectionActive(uint256 _collectionNumber) {
        require(collections[_collectionNumber].active, "The collection is not active");
        _;
    }
    
    modifier ifCollectionNotLocked(uint256 _collectionNumber){
        require(!collections[_collectionNumber].locked, "The collection is locked");
        _;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function createCollection(
        string memory _name, 
        string memory _description, 
        string memory _collectionBaseURI, 
        uint128 _tokenPriceInWei, 
        uint32 _maxTokensAvailable,
        uint32 _collectionNumber
        ) public onlyOwner
    {   

        require(!collections[_collectionNumber].created, "A collection with this collection number already exists");
        require(_maxTokensAvailable < ONE_MILLION, "The maximum number of tokens available per collection must be less than 1 million");
        require(_collectionNumber == nextCollectionNumber, "You are trying to create a collection that doesn't match the nextCollectionNumber");
        Collection memory newCollection = Collection({
            name: _name,
            description: _description,
            baseURI: _collectionBaseURI,
            tokenPriceInWei: _tokenPriceInWei,
            maxTokensAvailable: _maxTokensAvailable,
            collectionNumber: _collectionNumber,
            created: true, 
            locked: false,
            active: false,
            tokensMinted: 0
        });
        collections[nextCollectionNumber++] = newCollection;
    }

    function changeName(uint256 _collectionNumber, string memory _name) public onlyOwner ifCollectionExists(_collectionNumber) ifCollectionNotLocked(_collectionNumber)  {
        collections[_collectionNumber].name = _name;
    }

    function changeDescription(uint256 _collectionNumber, string memory _description) public onlyOwner ifCollectionExists(_collectionNumber) ifCollectionNotLocked(_collectionNumber) {
        collections[_collectionNumber].description = _description;
    }

    function changeBaseURI(uint256 _collectionNumber, string memory _collectionBaseURI) public onlyOwner ifCollectionExists(_collectionNumber)  ifCollectionNotLocked(_collectionNumber){
        collections[_collectionNumber].baseURI = _collectionBaseURI;
    }

    function changeTokenPriceInWei(uint256 _collectionNumber, uint128 _tokenPriceInWei) public onlyOwner ifCollectionExists(_collectionNumber) ifCollectionNotLocked(_collectionNumber) {
        collections[_collectionNumber].tokenPriceInWei = _tokenPriceInWei;
    }

    function changeMaxTokensAvailable(uint256 _collectionNumber, uint32 _maxTokensAvailable) public onlyOwner ifCollectionExists(_collectionNumber) ifCollectionNotLocked(_collectionNumber) {
        collections[_collectionNumber].maxTokensAvailable = _maxTokensAvailable;
    }

    function lockCollection(uint256 _collectionNumber) public onlyOwner ifCollectionExists(_collectionNumber) ifCollectionNotLocked(_collectionNumber) {
        collections[_collectionNumber].locked = true;
    }

    function toggleActive(uint256 _collectionNumber) public onlyOwner ifCollectionExists(_collectionNumber) ifCollectionNotLocked(_collectionNumber) {
        collections[_collectionNumber].active = !collections[_collectionNumber].active;
    }

    function purchaseNft(uint256 _collectionNumber, uint256 _quantity)
        public
        payable
        ifCollectionExists(_collectionNumber)
        ifCollectionActive(_collectionNumber)
        ifCollectionNotLocked(_collectionNumber)
    {
        require(_quantity > 0 ,  "Number of tokens to purchase must be greater than 0");
        Collection storage collection = collections[_collectionNumber];

        require(collection.tokensMinted + _quantity <= collection.maxTokensAvailable, "This transaction would exceed the maximum number of tokens in this collection");
        require(msg.value == _quantity * collection.tokenPriceInWei, "You did not send the correct amount of ether");
        for(uint256 i=0; i< _quantity; i++){
            _mintNft(msg.sender, _collectionNumber);
        }
    }
    
    function devMint(uint256 _collectionNumber, address _to, uint256 _quantity)
        public
        onlyOwner
        ifCollectionExists(_collectionNumber)
        ifCollectionNotLocked(_collectionNumber)
    {  
        require(_quantity > 0 ,  "Number of tokens to mint must be greater than 0");
        Collection storage collection = collections[_collectionNumber];
        require(collection.tokensMinted + _quantity <= collection.maxTokensAvailable, "This transaction would exceed the maximum number of tokens in this collection");
        for(uint256 i=0; i< _quantity; i++){
            _mintNft(_to, _collectionNumber);
        }
    }

    function _mintNft(address _to, uint256 _collectionNumber) internal{
        uint256 tokenIdToMint = (_collectionNumber * ONE_MILLION) + (++collections[_collectionNumber].tokensMinted);
        _safeMint(_to, tokenIdToMint);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = collections[_tokenId/ONE_MILLION].baseURI;
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString()))
            : '';
    }

    function changeCustomURI(string memory _newUri) public onlyOwner {
        customURI = _newUri;
    }

    function customTokenURI(uint256 _tokenId) public view returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(customURI).length > 0
            ? string(abi.encodePacked(customURI, _tokenId.toString()))
            : '';
    }

    function getOwnedTokenIds(address _owner) public view returns(uint256[] memory tokenIds) {
        uint256 balanceOfOwner = balanceOf(_owner);

        tokenIds = new uint256[](balanceOfOwner);
            
        for(uint256 index = 0; index < balanceOfOwner; index++){
            tokenIds[index] = tokenOfOwnerByIndex(_owner, index);
        }
    }

    function getTokenIdsInCollection(uint256 _collectionNumber) public view returns(uint256[] memory tokenIds) {

        Collection storage collection = collections[_collectionNumber];
        require(collection.created, "Collection does not exist");

        uint256 totalMinted = collection.tokensMinted;

        tokenIds = new uint256[](totalMinted);

        for(uint256 index=0; index < totalMinted; index++){
            tokenIds[index] = (_collectionNumber * ONE_MILLION) + index + 1;
        }
    }
}