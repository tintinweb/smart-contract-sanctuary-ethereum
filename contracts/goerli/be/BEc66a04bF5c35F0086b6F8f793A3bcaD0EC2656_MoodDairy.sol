/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MoodDairy {
    string mood;

    // function to write mood to contract
    function setMood(string memory _mood) public {
        mood = _mood;
    }

    // function to get mood from contract
    function getMood() public view returns(string memory) {
        return mood;
    }

}