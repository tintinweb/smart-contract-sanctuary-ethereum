/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

//SPDX-License-Identifier: UNLICENSED;

pragma solidity > 0.8.0;

contract Mood {
    string public mood;

    event MoodChanged(string oldMood, string newMood);
    
    constructor(string memory _mood){
        mood = _mood;
    }

    function setMood(string memory _mood) public {
        string memory oldMood = mood;
        mood = _mood;
        emit MoodChanged(oldMood,mood);
    }

    function getMood() public view returns(string memory){
        return mood;
    }
}