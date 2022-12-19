/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: UNLISENCED

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface IOPSC {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ICHANCO {
    function burnFrom(address from_, uint256 amount_) external;
}

contract SumoSetting is Ownable {

    mapping (uint256 => string) public name;
    mapping (uint256 => string) public bios;

    IOPSC public OPSC = IOPSC(0xd2b14f166Daeb1Ec73a4901745DBE2199Db6B40C);
    ICHANCO public CHANCO = ICHANCO(0xbBEf6C4D5c23351C0A1C23528F547985B25dD366);

    uint256 public changeNamePrice = 150 ether;
    uint256 public changeBioPrice = 300 ether;

    bool public ChangeNameable = true;
    bool public ChangeBioable = true;

    function setChangeNamePrice(uint256 price_) external onlyOwner { 
        changeNamePrice = price_; 
    }

    function setChangeBioPrice(uint256 price_) external onlyOwner {
        changeBioPrice = price_; 
    }

    function setOPSC(address _address) external onlyOwner {
        OPSC = IOPSC(_address);
    }

    function setCHANCO(address _address) external onlyOwner {
        CHANCO = ICHANCO(_address);
    }

    function setChangeNameable(bool bool_) external onlyOwner { 
        ChangeNameable = bool_; 
    }

    function setChangeBioable(bool bool_) external onlyOwner { 
        ChangeBioable = bool_; 
    }

    function changeName(uint256 tokenId, string memory newName) public {
        require(ChangeNameable, "Characters not namable!");
        require(msg.sender == OPSC.ownerOf(tokenId), "You don't own this token");
        require(validateName(newName) == true, "Not a valid new name");
        require(20 >= bytes(newName).length, "Name can only contain 20 characters max!");

        CHANCO.burnFrom(msg.sender, changeNamePrice);
        name[tokenId] = newName;
    }

    function changeBio(uint256 tokenId, string memory newBio) public {
        require(ChangeBioable, "Characters not bio changable!");
        require(msg.sender == OPSC.ownerOf(tokenId), "You don't own this token");
        require(validateName(newBio) == true, "Not a valid new name");

        CHANCO.burnFrom(msg.sender, changeBioPrice);
        bios[tokenId] = newBio;
    }

    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }
}