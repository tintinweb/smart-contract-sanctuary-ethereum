/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract MoodDiary{

    string mood;
    
    function setMood(string memory _mood) public {
        mood = _mood;
    }
    
    function getMood() public view returns (string memory) {
        return mood;
    }
}