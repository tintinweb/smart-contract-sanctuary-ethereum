/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

//This defines the contract
contract MoodDiary {

    //this creates a string variable named mood
    string mood;

    // This function takes a string input and sets it as the _mood variable
    function setMood(string memory _mood) public {
        mood = _mood;
    }
    //This function returns a string that has previously been set as the mood variable
    function getMood() public view returns (string memory){
        return mood;
    }

}