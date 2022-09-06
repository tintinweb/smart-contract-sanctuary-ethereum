/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract moodDiary {
string mood;

function setMood(string memory _mood) public {
    mood = _mood;
}

function getMood() public view returns (string memory) {
    return mood;
}
}