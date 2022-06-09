// File: contracts/minERC721.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

contract newNFT {
    string constant ZERO_ADDRESS = '003001';
    string constant NFT_ALREADY_EXISTS = '003006';
    string constant NOT_VALID_NFT = '003002';

    string internal nftName;
    string internal nftSymbol;

    mapping(uint256 => address) public idToOwner;
    mapping(address => uint256) public ownerToNFTokenCount;
    mapping(uint256 => string) public idToUri;
    mapping(bytes4 => bool) internal supportedInterfaces;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
        _;
    }

    constructor() {
        nftName = 'how open sea show nft';
        nftSymbol = 'SYN';
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
    }

    function _mint(address _to, uint256 _tokenId, string calldata _uri) public {
        require(_to != address(0), ZERO_ADDRESS);
        require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

        _addNFToken(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
        _setTokenUri(_tokenId, _uri);
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

    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

}