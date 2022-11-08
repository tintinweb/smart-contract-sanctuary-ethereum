/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MoodDiary{
    string mood;
    // set mood
    function setMood(string memory _mood) public{
        mood = _mood;
    }
    // read function
    function getMood() public view returns(string memory){
        return mood;
    }
}