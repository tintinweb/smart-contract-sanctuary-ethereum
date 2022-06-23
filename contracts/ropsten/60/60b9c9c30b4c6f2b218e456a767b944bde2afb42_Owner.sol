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
 contract Owner{

    //Owner Variables : LastName / FirstName / ID / Strike / Pets
    string OwnerLastName; 
    string OwnerFirstName;   
    bool OwnerStrike;
    address[] PetsID; 

    constructor (string memory _OwnerLastName, string memory _OwnerFirstName, bool _Strike){    
        OwnerLastName = _OwnerLastName; 
        OwnerFirstName = _OwnerFirstName; 
        OwnerStrike = _Strike;
    }

    function getOwnerLastName() public view returns (string memory){
        return  OwnerLastName; 
    }
    function getOwnerFirstName() public view returns (string memory){
        return OwnerFirstName; 
    }
    function getStrike() public view returns (bool){
        return OwnerStrike; 
    }
    function getAllOwnerPet() public view returns(address[] memory){
        return PetsID; 
    }

    function setOwnerLastName(string memory _OwnerLastName) public {
        OwnerLastName = _OwnerLastName; 
    }
    function setOwnerFirstName(string memory _OwnerFirstName) public {
        OwnerLastName = _OwnerFirstName; 
    }
    function SetOwnerStrike(bool _Strike) public {
        OwnerStrike = _Strike; 
    }
    function AddPet(address NewPet) public {
        PetsID.push(NewPet); 
    }


 }