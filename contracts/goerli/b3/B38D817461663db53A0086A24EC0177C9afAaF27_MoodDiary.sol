// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MoodDiary {
    string mood;

    // create the function that writes a mood to the smart contract
    function setMood(string memory _mood) public {
        mood = _mood;
    }

    // create the function to show the mood from the smart contract
    function getMood() public view returns (string memory) {
        return mood;
    }
}