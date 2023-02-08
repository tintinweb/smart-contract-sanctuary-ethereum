/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MoodDiary{

    string mood;
    uint num_calls;

    //function to set mood
    function setmood(string memory _mood) public{
        num_calls += 1;
        mood = _mood;
    }

    function getmood() public view returns(string memory){
        return mood;
    }

    function getnumsets() public view returns(uint){
        return num_calls;
    }
}