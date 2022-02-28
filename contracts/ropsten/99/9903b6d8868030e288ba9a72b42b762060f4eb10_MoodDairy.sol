/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MoodDairy {
    string mood;

    function getMood() public view returns (string memory) {
        return mood;
    }

    function setMood(string memory _mood) public {
        mood = _mood;
    }
}