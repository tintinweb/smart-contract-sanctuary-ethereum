/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract SPA{
    //Owner Variables : LastName / FirstName / ID / Strike / Pets
    string OwnerLastName; 
    string OwnerFirstName; 
    uint OwnerID;  
    bool OwnerStrike;

    //PetVariable
    string PetName; 
    string PetSpecies;
    uint PetId;
    bool lost; 

    constructor (string memory _OwnerLastName, string memory _OwnerFirstName, uint _Id, bool _Strike, string memory _PetName, string memory _PetSpecies, uint _PetId, bool _Lost){    
        OwnerLastName = _OwnerLastName; 
        OwnerFirstName = _OwnerFirstName;
        OwnerID = _Id; 
        OwnerStrike = _Strike; 
        PetName = _PetName; 
        PetId = _PetId; 
        PetSpecies = _PetSpecies; 
        lost = _Lost; 
    }

    function getOwnerLastName() public view returns (string memory){
        return  OwnerLastName; 
    }
    function getOwnerFirstName() public view returns (string memory){
        return OwnerFirstName; 
    }
    function getOwnerId() public view returns (uint){
        return OwnerID;
    }
    function getPetName() public view returns (string memory){
        return PetName; 
    }
    function getPetId() public view returns (uint){
        return PetId; 
    }
    function getStriked() public view returns (bool){
        return OwnerStrike; 
    }
    function getPetSpecies() public view returns (string memory){
        return PetSpecies; 
    }
    function getLostPet()public view returns(bool){
        return lost; 
    }

    function setOwnerLastName(string memory _OwnerLastName) public {
        OwnerLastName = _OwnerLastName; 
    }
    function setOwnerFirstName(string memory _OwnerFirstName) public {
        OwnerLastName = _OwnerFirstName; 
    }
    function setOwnerId(uint _OwnerId) public {
        OwnerID = _OwnerId; 
    }
    function setOwnerPetName(string memory _PetName) public {
        PetName = _PetName; 
    }
    function setOwnerPetId(uint _PetId) public {
        PetId = _PetId; 
    }
    function setOwnerStrike(bool _strike) public {
        OwnerStrike = _strike; 
    }
    function setPetSpecies(string memory _PetSpecies) public {
        PetSpecies = _PetSpecies; 
    }
    function setLostPet(bool _Lost) public {
        lost = _Lost; 
    }
}