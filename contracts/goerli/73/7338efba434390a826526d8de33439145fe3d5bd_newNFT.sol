/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract newNFT {
    string constant ZERO_ADDRESS = '003001';
    string constant NFT_ALREADY_EXISTS = '003006';
    string constant NOT_VALID_NFT = '003002';
    string constant NOT_OWNER = '003007';

    string internal nftName;
    string internal nftSymbol;

    mapping(uint256 => address) private idToOwner;
    mapping(address => uint256) public ownerToNFTokenCount;
    mapping(uint256 => string) private idToUri;
    mapping(uint256 => address) public idToApproval;
    mapping(string => bool) public tokenURIToUsed; //判断某个tokenURI是否使用过
    mapping (address => uint) pendingWithdrawals;
    int public total;
    uint256 public tokenId;
    mapping(bytes4 => bool) internal supportedInterfaces;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Log(string);
    event Log(uint256);
    event Log(address);
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), 'NOT_VALID_NFT');
        _;
    }

    constructor() {
        nftName = 'unique tokenURI and max amount';
        nftSymbol = 'SYN';
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        total = 0;
        tokenId = 0;
    }
    function autoMint20(uint i) public{
        uint _i = 0;
        while(_i <= i){
            _i++;
            autoMint();
        }
    }
    function _mint(address _to, string memory _uri) public{
        require(_to != address(0), ZERO_ADDRESS);
        require(idToOwner[tokenId] == address(0), 'NFT_ALREADY_EXISTS');
        total++;
        // require(total <= 2, "total must < 500");
        _addNFToken(_to, tokenId);

        emit Transfer(address(0), _to, tokenId);
        _setTokenUri(tokenId, _uri);
        tokenId++;
    }

    function autoMint() public {
        emit Log(msg.sender);
        _mint(msg.sender,'https://gateway.pinata.cloud/ipfs/QmaTka3A2YVQhD4AaoEAhZ49CFM3DgXijYAgjSBBfEfTdg');
    }

    function _addNFToken(address _to, uint256 _tokenId) internal virtual {
        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] += 1;
    }

    function _setTokenUri(uint256 _tokenId, string memory _uri) internal validNFToken(_tokenId) {
        // if(tokenURIToUsed[_uri] == true){
        //     revert('tokenURI has already exist');
        // }
        // require(tokenURIToUsed[_uri] == false,"tokenURI has already exist");
        tokenURIToUsed[_uri] = true;
        idToUri[_tokenId] = _uri;
    }

    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), 'this id has no owner');
    }

    function _tokenURI(uint256 _tokenId) internal view virtual returns (string memory) {
        return idToUri[_tokenId];
    }

    function tokenURI(uint256 _tokenId) external view  validNFToken(_tokenId) returns (string memory) {
        return _tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    function symbol() internal view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    function _clearApproval(uint256 _tokenId) private {
        delete idToApproval[_tokenId];
    }

    function _transfer(address _to, uint256 _tokenId) public {
        

        address from = idToOwner[_tokenId];
        require(_to == msg.sender,'msg.sender is not _to');

        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function buy(uint256 _tokenId)  external payable{
        require(msg.sender != idToOwner[_tokenId],'you cant buy your nft');
        require(msg.value >= 10,'wei is not enough');
        pendingWithdrawals[idToOwner[_tokenId]] += msg.value;
        _transfer(msg.sender,_tokenId);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == _from, NOT_OWNER);
        ownerToNFTokenCount[_from] -= 1;
        delete idToOwner[_tokenId];
    }

    function changeName(string calldata name) external {
        nftName = name;
    }

function burn(uint256 _tokenId) external validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);

    delete idToUri[_tokenId];
}


function contractBalance() external view returns (uint){
    return address(this).balance;
}

function withdraw() external {
     uint value = pendingWithdrawals[msg.sender]; //账户待提现余额
     require(value > 0, 'your have no money can withdraw'); //可提现余额必须大于0
     pendingWithdrawals[msg.sender] = 0; //可提现余额清0
     payable(msg.sender).transfer(value); //将金额转至对方账户
}
}