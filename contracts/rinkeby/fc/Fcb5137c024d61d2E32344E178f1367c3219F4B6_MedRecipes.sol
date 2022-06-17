/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract MedRecipes {
    MedRecipe[] public medRecipes;
    
    struct MedRecipe {
        string patient;
        string doctor;
        string data;
        string date;
    }

    function addMedRecipe(string memory _patient, string memory _doctor, string memory _data, string memory _date) public {
        MedRecipe memory medRecipe = MedRecipe(_patient, _doctor, _data, _date);
        medRecipes.push(medRecipe);
    }

    function getMedRecipes() view public returns(MedRecipe[] memory) {
        return medRecipes;
    }

    function getMedRecipesByPatient(string calldata patient) view public returns(MedRecipe[] memory) {
        uint recipesCount = medRecipes.length; 
        MedRecipe[] memory meds = new MedRecipe[](5);
        uint count = 0;

         for (uint256 i = 0; i < recipesCount; i++) {
            if ( keccak256(abi.encodePacked(medRecipes[i].patient)) == keccak256(abi.encodePacked(patient)) ) {
                count += 1;
            }
        }

        for (uint256 i = 0; i < recipesCount; i++) {
            if ( keccak256(abi.encodePacked(medRecipes[i].patient)) == keccak256(abi.encodePacked(patient)) ) {
                uint j = meds.length - count;
                meds[j] = medRecipes[i];
                count -= 1;
            }
        }
        return meds;
    } 
}