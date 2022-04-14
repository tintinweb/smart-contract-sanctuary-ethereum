/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MoodDiary
{

    string mood;
    function setMood(string memory _message)public
    {
        mood = _message;
    }

    function getMood()public view returns(string memory)
    {
        return mood;
    }
}