/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MoodDiary{

    string Mood = "Happy";

    function setMood(string memory _mood) public{
        Mood = _mood;
    }

    function getMood() public view returns(string memory){
        return Mood;
    }

}