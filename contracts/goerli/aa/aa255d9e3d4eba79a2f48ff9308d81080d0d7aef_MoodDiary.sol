/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MoodDiary {
    string mood;

    // It writes the mood to the smart contract
    function setMood(string memory _mood) public {
        mood = _mood;
    }

    // It reads the mood from the smart contract
    function getMood() public view returns (string memory) {
        return mood;
    }
}