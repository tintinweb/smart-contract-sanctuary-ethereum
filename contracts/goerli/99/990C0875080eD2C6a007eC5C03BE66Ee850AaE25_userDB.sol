/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT LICENSE
//contract = 0x990C0875080eD2C6a007eC5C03BE66Ee850AaE25
 
 
pragma solidity ^0.8.0;
 
 
contract userDB {
 
    struct userInfo{
        string RegisatrationNumber;
        string Name;
        string Breed;
        string SEX;
        string Dateofbirth;
        string Color;
        string Sire;
        string Dam;
        string Owner;
    }
 
    mapping (uint256 => mapping(address => userInfo)) public membership;
 
    function addRegisterPet(address wallet, uint256 memId,
    string memory RegisatrationNumber,
    string memory Name,
    string memory Breed,
    string memory SEX,
    string memory Dateofbirth,
    string memory Color,
    string memory Sire,
    string memory Dam,
    string memory Owner) external {
        membership[memId][wallet].RegisatrationNumber = RegisatrationNumber;
        membership[memId][wallet].Name = Name;
        membership[memId][wallet].Breed = Breed;
        membership[memId][wallet].SEX = SEX;
        membership[memId][wallet].Dateofbirth = Dateofbirth;
        membership[memId][wallet].Color = Color;
        membership[memId][wallet].Sire = Sire;
        membership[memId][wallet].Dam = Dam;
        membership[memId][wallet].Owner = Owner;
    }
 
 
    function updateRegisatration(address wallet, uint256 memId, uint256 option, string memory data) external {
        if (option == 0) {
            membership[memId][wallet].RegisatrationNumber = data;
        }
        else if (option == 1) {
            membership[memId][wallet].Name = data;
        }
        else if (option == 2) {
            membership[memId][wallet].Breed = data ;
        }
        else if (option == 3) {
            membership[memId][wallet].SEX = data;
        }
        else if (option == 4) {
            membership[memId][wallet].Dateofbirth = data;
        }
        else if (option == 5) {
            membership[memId][wallet].Color = data ;
        }
        else if (option == 6) {
            membership[memId][wallet].Sire = data;
        }
        else if (option == 7) {
            membership[memId][wallet].Dam = data;
        }
        else if (option == 8) {
            membership[memId][wallet].Owner = data ;
        }
    }
 
     function removeRegisatration(address wallet, uint256 memId) external {
            delete membership[memId][wallet];
    }
 
}