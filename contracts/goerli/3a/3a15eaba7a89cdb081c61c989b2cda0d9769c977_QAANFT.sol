// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract QAANFT {
    using Strings for uint256;
    // owner of token
    address private _owner;
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Send locker
    bool private _locked;
    // link to object
    string private _baseURI;
    // extension for tokenURI;
    string private _baseExtension;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    constructor (string memory name_, string memory symbol_, string memory baseURI_) {
        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _locked = false;
        _baseExtension = ".json";
    }
    function balanceOf(address tokenOwner) public view virtual returns (uint256) {
        require(tokenOwner != address(0), "ERC721: balance query for the zero address");
        if(_owner == tokenOwner)
            return 1;
        else
            return 0;
    }
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _owner;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function locked() public view virtual returns (bool) {
        return _locked;
    }
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
       require(tokenId==1, "Only one element in the collection");
       return string(abi.encodePacked(_baseURI, tokenId.toString(), _baseExtension));
    }
    function baseURI() public view virtual returns (string memory) {
       return _baseURI;
    }
    function totalSupply() public view virtual returns (uint256) {
       return 10000;
    }    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual  {
        require(_owner == from, "Wrong owner");
        require(_locked==false, "NFT locked, sheh <3");
        require(to != address(0), "ERC721: transfer to the zero address");
        emit Transfer(from, to, tokenId);
        _owner=to;
        _locked=true;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        //bytes4 _INTERFACE_ID_ERC721 = 0x80ac58cd;
        //return interfaceId==_INTERFACE_ID_ERC721;
        return true;
    }
    fallback() external payable virtual {
    }
    receive() external payable virtual {
    }
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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