/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract MedRecipes {
    MedRecipe[] public medRecipes;
    
    struct MedRecipe {
        string recipe;
        string patient;
        string doctor;
        string data;
        string date;
    }

    function addMedRecipe(string memory _recipe, string memory _patient, string memory _doctor, string memory _data, string memory _date) public {
        MedRecipe memory medRecipe = MedRecipe(_recipe ,_patient, _doctor, _data, _date);
        medRecipes.push(medRecipe);
    }

    function getMedRecipes() view public returns(MedRecipe[] memory) {
        return medRecipes;
    }

    function getMedRecipesByPatient(string calldata patient) view public returns(MedRecipe[] memory) {
        uint recipesCount = medRecipes.length; 
        uint count = 0;
        uint j = 0;

         for (uint256 i = 0; i < recipesCount; i++) {
            if ( keccak256(abi.encodePacked(medRecipes[i].patient)) == keccak256(abi.encodePacked(patient)) ) {
                count += 1;
            }
        }

        MedRecipe[] memory meds = new MedRecipe[](count);

        for (uint256 i = 0; i < recipesCount; i++) {
            if ( keccak256(abi.encodePacked(medRecipes[i].patient)) == keccak256(abi.encodePacked(patient)) ) {
                meds[j] = medRecipes[i];
                j += 1;
            }
        }
        return meds;
    } 
}