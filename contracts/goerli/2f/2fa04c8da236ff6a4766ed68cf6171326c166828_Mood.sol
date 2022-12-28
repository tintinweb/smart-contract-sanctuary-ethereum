/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Mood
{   
    string mood;

    constructor(string memory _mood)
    {
        mood=_mood;
    }

    function setMood(string memory _newMood) public 
    {
        mood=_newMood;
    }

    function getMood() public view returns(string memory)
    {
        return mood;
    }
}