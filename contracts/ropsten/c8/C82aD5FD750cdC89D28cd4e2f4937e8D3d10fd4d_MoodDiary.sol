/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MoodDiary {
    string public mood;
    function setMood(string memory newMood) public {
        mood = newMood;
    }
    function getMood() public view returns (string memory) {
        return mood;
    }
}