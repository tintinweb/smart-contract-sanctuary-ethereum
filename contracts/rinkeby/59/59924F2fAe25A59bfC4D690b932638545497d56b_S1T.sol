/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC1155Metadata_URI {
    function uri(uint256 tokenId) external view returns (string memory);
}

interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC721 is IERC165, IERC721, ERC721Metadata, ERC1155Metadata_URI, ERC721Enumerable {

    mapping(address => uint) _balances; // owner => balance
    mapping(uint => address) _owners; // tokenId => owner
    mapping(string => uint) _nfcUid; // uid => tokenId
    mapping(uint => address) _previousOwner; // tokenId => previousOwner
    mapping(uint => mapping(address => address)) _transfered; //tokenId => (from => to)
    mapping(address => mapping(address => bool)) _operatorApprovals; // owner => (operator => allow)
    mapping(uint => address) _tokenApprovals; // tokenId => operator

    string _name;
    string _symbol;
    mapping (uint => string) _tokenURIs; // token => uri


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public override view returns (string memory) {
        return _name;
    }
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function uri(uint256 tokenId) public override view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public override pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId
        || interfaceId == type(IERC721).interfaceId
        || interfaceId == type(ERC721Metadata).interfaceId
        || interfaceId == type(ERC1155Metadata_URI).interfaceId
        || interfaceId == type(ERC721Enumerable).interfaceId;
    }

    function balanceOf(address owner) public override view returns (uint256){
        require(owner != address(0), "owner is zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "token is not exist");
        return owner;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(msg.sender != operator, "approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "approval status for self");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "caller is not token owner or approval for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_owners[tokenId] != address(0), "token is not exist");
        return _tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from != address(0), "transfer from zero address");
        require(to != address(0), "transfer to zero address");
        
        address owner = ownerOf(tokenId);
        require(owner == from, "transfer from is not token owner");
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approval");

        _balances[from] -= 1;
        //_balances[to] += 1;
        delete _owners[tokenId];
        _owners[tokenId] = address(0);
        _previousOwner[tokenId] = from;
        _transfered[tokenId][from] = to;

        //emit Transfer(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);
        //_addTokenToOwnerEnumeration(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        transferFrom(from, to, tokenId);

        require(_checkOnErc721Received(from, to, tokenId, data), "transfer to non ERC721Receiver Implementor");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId);
    }

    function totalSupply() public override view returns (uint256){
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public override view returns (uint256) {
        require(index < _allTokens.length, "index out of bound");
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256) {
        require(index < _balances[owner], "index out of bound");
        return _ownedTokens[owner][index];
    }

    //======Private or Internal Function=======
    function _approve(address to, uint tokenId) internal {
        _tokenApprovals[tokenId] = to;
        address owner = ownerOf(tokenId);
        emit Approval(owner, to, tokenId);
    }

    function _checkOnErc721Received(address from, address to, uint tokenId, bytes memory data) private returns(bool) {
        if(to.code.length <= 0) return true;

        IERC721TokenReceiver receiver = IERC721TokenReceiver(to);
        try receiver.onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 interfaceId) {
            return interfaceId == type(IERC721TokenReceiver).interfaceId;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("transfer to non ERC721Receiver Implementor");
        }
    }

    function _mint(address to, uint tokenId, string memory uid, string memory uri_) internal {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already mint" );

        _nfcUid[uid] = tokenId;
        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = uri_;

        emit Transfer(address(0), to, tokenId);

        _addTokenToAllEnumeration(tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _safeMint(address to, uint tokenId, string memory uid, string memory uri_, bytes memory data) internal{
        _mint(to, tokenId, uid, uri_);

        require(_checkOnErc721Received(address(0), to, tokenId, data), "mint to non ERC721Receive Implementor");
    }

    function _safeMint(address to, uint tokenId, string memory uid, string memory uri_) internal {
        _safeMint(to, tokenId, uid, uri_, "");
    }

    function _burn(uint tokenId, string memory uid) internal {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approved");

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];
        delete _nfcUid[uid];

        emit Transfer(owner, address(0), tokenId);

        _removeTokenFromAllEnumeration(tokenId);
        _removeTokenFromOwnerEnumeration(owner, tokenId);
    }

    function _getTokenId(string memory uid) internal view returns(uint) {
        require(_nfcUid[uid] != 0, "cannot find Token of this uid");
        return _nfcUid[uid];
    }

    // function _getReceiver(uint tokenId) internal view returns(address) {
    //     address preOwner = _previousOwner[tokenId];
    //     return _transfered[tokenId][preOwner];
    // }

    function _acceptTransfer(string memory uid, address to) internal {
        uint tokenId = _nfcUid[uid];
        address preOwner = _previousOwner[tokenId];
        require(_transfered[tokenId][preOwner] == to);

        _balances[to] += 1;
        _owners[tokenId] = to;
        delete _previousOwner[tokenId];
        delete _transfered[tokenId][preOwner];

        emit Transfer(preOwner, to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _rejectTransfer(string memory uid, address to) internal {
        uint tokenId = _nfcUid[uid];
        address preOwner = _previousOwner[tokenId];
        require(_transfered[tokenId][preOwner] == to, "You are not the receiver of this token");

        _balances[preOwner] += 1;
        _owners[tokenId] = preOwner;
        delete _previousOwner[tokenId];
        delete _transfered[tokenId][preOwner];

        _addTokenToOwnerEnumeration(preOwner, tokenId);
    }

    // All Enumeration
    uint[] _allTokens;
    mapping(uint => uint) _allTokensIndex; //tokenId => index

    function _addTokenToAllEnumeration(uint tokenId) private {
        _allTokens.push(tokenId);
        _allTokensIndex[tokenId] = _allTokens.length -1;
    }

    function _removeTokenFromAllEnumeration(uint tokenId) private {
        uint index = _allTokensIndex[tokenId];
        uint indexLast = _allTokens.length -1;

        if (index < indexLast) {
            uint idLast = _allTokensIndex[indexLast];
            _allTokens[index] = idLast;
            _allTokensIndex[idLast] = index;
        }

        _allTokens.pop();
        delete _allTokensIndex[tokenId];
    }

    // Owner Enumeration
    mapping(address => mapping(uint => uint)) _ownedTokens; // owner => (index => tokenId)
    mapping(uint => uint) _ownedTokensIndex; //tokenId => index 

    function _addTokenToOwnerEnumeration(address owner, uint tokenId) private {
        uint index = _balances[owner] -1;
        _ownedTokens[owner][index] = tokenId;
        _ownedTokensIndex[tokenId] = index;
    }

    function _removeTokenFromOwnerEnumeration(address owner, uint tokenId) private {
        uint index = _ownedTokensIndex[tokenId];
        uint indexLast = _balances[owner];

        if (index < indexLast) {
            uint idLast = _ownedTokens[owner][indexLast];

            _ownedTokens[owner][index] = idLast;
            _ownedTokensIndex[idLast] = index;
        }

        delete _ownedTokens[owner][indexLast];
        delete _ownedTokensIndex[tokenId];
    }
}

contract S1T is ERC721 {
    constructor() ERC721("S1 Token", "S1T") {

    }

    function create(uint tokenId, string memory uid, string memory uri) public {
        _mint(msg.sender, tokenId, uid, uri);
    }

    function burn(uint tokenId, string memory uid) public {
        _burn(tokenId, uid);
    }

    function getTokenId(string memory uid) public view returns(uint) {
        return _getTokenId(uid);
    }

    function acceptTransfer(string memory uid) public {
        _acceptTransfer(uid, msg.sender);
    }

    function rejectTransfer(string memory uid) public {
        _rejectTransfer(uid, msg.sender);
    }

}