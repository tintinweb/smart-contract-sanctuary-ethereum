/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract MoodDiary{
    
    //create a variable called mood
    string mood;
    
    //create a function that writes a mood to the smart contract
    function setMood(string memory _mood) public{
        mood = _mood;
    }
    
    //create a function the reads the mood from the smart contract
    function getMood() public view returns(string memory){
        return mood;
    }
}