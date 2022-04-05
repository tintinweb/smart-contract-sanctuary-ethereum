/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract MoodDiary {
    string mood;

    function setMood(string calldata _mood) public {
        mood = _mood;
    }

    function getMood() public view returns (string memory) {
        return  mood;
    }
}