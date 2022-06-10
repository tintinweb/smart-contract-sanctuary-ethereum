/**
 *Submitted for verification at Etherscan.io on 2022-06-10
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

    mapping(uint256 => address) public idToOwner;
    mapping(address => uint256) public ownerToNFTokenCount;
    mapping(uint256 => string) public idToUri;
    mapping(uint256 => address) public idToApproval;

    mapping(bytes4 => bool) internal supportedInterfaces;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
        _;
    }
    
    constructor() payable {
        nftName = 'can change name?';
        nftSymbol = 'SYN';
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
    }

    function _mint(address _to, uint256 _tokenId, string memory _uri) public payable{
        require(_to != address(0), ZERO_ADDRESS);
        require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

        _addNFToken(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
        _setTokenUri(_tokenId, _uri);
    }

    function autoMint() public {
        _mint(address(0xa66FB6B795B479c521D608C83E6De1C2E822C2C9),1,'https://gateway.pinata.cloud/ipfs/QmaTka3A2YVQhD4AaoEAhZ49CFM3DgXijYAgjSBBfEfTdg');
    }

    function _addNFToken(address _to, uint256 _tokenId) internal virtual {
        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] += 1;
    }

    function _setTokenUri(uint256 _tokenId, string memory _uri) internal validNFToken(_tokenId) {
        idToUri[_tokenId] = _uri;
    }

    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), NOT_VALID_NFT);
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

    function Name() external view returns (string memory _Name) {
        _Name = nftName;
    }

    function Symbol() external view returns (string memory _Symbol) {
        _Symbol = nftSymbol;
    }

    function _clearApproval(uint256 _tokenId) private {
        delete idToApproval[_tokenId];
    }

    function _transfer(address _to, uint256 _tokenId) external {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == _from, NOT_OWNER);
        ownerToNFTokenCount[_from] -= 1;
        delete idToOwner[_tokenId];
    }

    function changeName(string calldata name) external {
        nftName = name;
    }
}