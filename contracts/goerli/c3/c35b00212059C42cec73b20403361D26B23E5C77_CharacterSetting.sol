/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: UNLISENCED

/********************************
**:::::::::::::::::::::::::::::**
**:::::██████████████::::::::::**
**:::██::::::::::::::██::::::::**
**:::██████████████████████::::**
**:::::::::::::::::::::::::::::**
**:::████::████:███:█::████::::**
**:::██:██:███:::██:█::████::::**
**:::████::████::::██::████::::**
**:::::::::::::::::::::::::::::**
********************************/

/// Title    : Character Setting
/// Author   : 0xSumo of @TheCapDevs
/// Feauture : 

pragma solidity ^0.8.0;

abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    mapping(address => bool) public admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    modifier onlyAdmin { require(admin[msg.sender], "Not Admin"); _; }
    function setAdmin(address address_, bool bool_) external onlyOwner { admin[address_] = bool_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

interface IERC721 { 
    function ownerOf(uint16 tokenId) external view returns (address owner); 
}

contract CharacterSetting is OwnControll {

    struct NamesAndBios { string names; string bios; }

    event NameChanged(uint16 tokenId_, string name_);
    event BioChanged(uint16 tokenId_, string bio_);

    mapping(uint16 => string) public Name;
    mapping(uint16 => string) public Bio;

    IERC721 private ERC721;

    function setERC721(address _address) external onlyOwner { 
        ERC721 = IERC721(_address);
    }

    function changeName(uint16 tokenId_, string memory name_) external {
        require(tokenId_ > 0 && tokenId_ < 2223, "Invalid tokenId");
        Name[tokenId_] = name_; 
        emit NameChanged(tokenId_, name_);
    }

    function changeBio(uint16 tokenId_, string memory bio_) external {
        require(tokenId_ > 0 && tokenId_ < 2223, "Invalid tokenId");
        Bio[tokenId_] = bio_;
        emit BioChanged(tokenId_, bio_);
    }
/*
    function changeName2(uint16 tokenId_, string memory name_) external {
        require(tokenId_ > 0 && tokenId_ < 2223, "Invalid tokenId");
        require(ERC721.ownerOf(tokenId_) == msg.sender, "Not Owner");
        Name[tokenId_] = name_; 
        emit NameChanged(tokenId_, name_);
    }

    function changeBio2(uint16 tokenId_, string memory bio_) external {
        require(tokenId_ > 0 && tokenId_ < 2223, "Invalid tokenId");
        require(ERC721.ownerOf(tokenId_) == msg.sender, "Not Owner");
        Bio[tokenId_] = bio_;
        emit BioChanged(tokenId_, bio_);
    }
*/

    function adminChangeName(uint16 tokenId_, string calldata name_) external onlyAdmin {
        Name[tokenId_] = name_; 
        emit NameChanged(tokenId_, name_);
    }
    
    function adminChangeBio(uint16 tokenId_, string calldata bio_) external onlyAdmin {
        Bio[tokenId_] = bio_;
        emit BioChanged(tokenId_, bio_);
    }

    function getAllNamesAndBios() external view returns (NamesAndBios[10] memory) {
        NamesAndBios[10] memory _NamesAndBios;
        for (uint16 i = 1; i <= 10;) {
            string memory _name  = Name[i];
            string memory _bio   = Bio[i];
            _NamesAndBios[i - 1] = NamesAndBios(_name, _bio);
            unchecked { ++i; }
        }
        return _NamesAndBios;
    }
}