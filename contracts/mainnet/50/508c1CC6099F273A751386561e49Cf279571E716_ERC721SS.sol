/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ERC721SS (ERC721 Sumo Soul)
 * @author 0xSumo
 */

interface IRender {
    function tokenURI(uint256 id_) external view returns (string memory); 
}

contract ERC721SS {

    address public owner;
    address public render;
    string public constant name = "SUMO MUNCH"; 
    string public constant symbol = "MUNCH";
    mapping(address => bool) public admin;
    mapping(uint256 => address) public tokenOwners;
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);

    constructor() { owner = msg.sender; }

    modifier onlyAdmin { require(admin[msg.sender], "Not Admin");_; }
    modifier onlyOwner { require(msg.sender == owner, "Not Owner");_; }

    function setAdmin(address address_, bool bool_) external onlyOwner { admin[address_] = bool_; }
    function changeOwner(address newOwner) external onlyOwner { emit OwnerChanged(owner, newOwner); owner = newOwner; }

    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        address _owner = tokenOwners[tokenId_];
        require(_owner != address(0), "Owner not exist");
        return _owner;
    }

    function mint(uint256 tokenId_, address to_) external onlyAdmin {
        require(tokenOwners[tokenId_] == address(0), "Token exists");
        _transfer(address(0), to_, tokenId_);
    }

    function burn(uint256 tokenId_) external onlyAdmin {
        require(msg.sender == ownerOf(tokenId_), "Not Owner");
        _transfer(msg.sender, address(0), tokenId_);
    }

    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual { 
        tokenOwners[tokenId_] = to_;
        emit Transfer(from_, to_, tokenId_);
    }

    function setRender(address _address) external onlyOwner { 
        render = _address;
    }

    function supportsInterface(bytes4 interfaceId_) public virtual view returns (bool) {
        return  interfaceId_ == 0x01ffc9a7 || interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f;
    }

    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {
         return IRender(render).tokenURI(tokenId_);
    }
}