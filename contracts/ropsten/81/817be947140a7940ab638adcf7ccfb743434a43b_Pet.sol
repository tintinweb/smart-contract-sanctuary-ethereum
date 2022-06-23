/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
 contract Pet{

    //PetVariable
    string PetName; 
    string PetSpecies;
    bool lost;
    bool leave; 
    address Owner; 
    event Log(address indexed sender, string Msg); 

    constructor (string memory _PetName, string memory _PetSpecies, bool _Lost, bool _Leave){    
        PetName = _PetName; 
        PetSpecies = _PetSpecies; 
        lost = _Lost; 
        leave = _Leave; 
    }

    function getPetName() public view returns (string memory){
        return PetName; 
    }
    function getPetSpecies() public view returns (string memory){
        return PetSpecies; 
    }
    function getLostPet()public view returns(bool){
        return lost; 
    }
    function getLeavePet() public view returns (bool){
        return leave; 
    }
    function getOwner() public view returns (address){
        return Owner; 
    }

    function setPetName(string memory _PetName) public {
        PetName = _PetName; 
    }
    function setPetSpecies(string memory _PetSpecies) public {
        PetSpecies = _PetSpecies; 
    }
    function setLostPet(bool _Lost) public {
        lost = _Lost; 
    }
    function setLeavePet(bool _leave) public {
        leave = _leave; 
        lost = false; 
    }
    function setOwner(address _NewOwner) public {
        Owner = _NewOwner;
        leave = false; 
        lost = false; 
    }


 }