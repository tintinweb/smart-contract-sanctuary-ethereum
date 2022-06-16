/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract MedRecipes {
    MedRecipe[] public medRecipes;
    
    struct MedRecipe {
        string data;
    }

    function addMedRecipe(string memory _data) public {
        MedRecipe memory medRecipe = MedRecipe(_data);
        medRecipes.push(medRecipe);
    }

    function getMedRecipes() view public returns(MedRecipe[] memory) {
        return medRecipes;
    }
}