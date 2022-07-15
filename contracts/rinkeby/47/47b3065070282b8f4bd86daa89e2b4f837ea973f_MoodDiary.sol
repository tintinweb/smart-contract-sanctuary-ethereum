/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MoodDiary{
    string mood;
    function setMood(string memory _mood) public{
        mood = _mood;
    }
    function getMood() public view returns(string memory){
        return mood;
    }
}