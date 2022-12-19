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

library Strings {
    function onlyAllowedCharacters(string memory string_) public pure returns (bool) {
        bytes memory _strBytes = bytes(string_);
        for (uint i = 0; i < _strBytes.length; i++) {
            if (_strBytes[i] < 0x20 || _strBytes[i] > 0x7A || _strBytes[i] == 0x26 || _strBytes[i] == 0x22 || _strBytes[i] == 0x3C || _strBytes[i] == 0x3E) {
                return false;
            }     
        }
        return true;
    }
}

contract SumoChange is Ownable {

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
        require(Strings.onlyAllowedCharacters(newName), "Name contains unallowed characters!");
        require(20 >= bytes(newName).length, "Name can only contain 20 characters max!");

        CHANCO.burnFrom(msg.sender, changeNamePrice);
        name[tokenId] = newName;
    }

    function changeBio(uint256 tokenId, string memory newBio) public {
        require(ChangeBioable, "Characters not bio changable!");
        require(msg.sender == OPSC.ownerOf(tokenId), "You don't own this token");
        require(Strings.onlyAllowedCharacters(newBio), "Name contains unallowed characters!");

        CHANCO.burnFrom(msg.sender, changeBioPrice);
        bios[tokenId] = newBio;
    }
}