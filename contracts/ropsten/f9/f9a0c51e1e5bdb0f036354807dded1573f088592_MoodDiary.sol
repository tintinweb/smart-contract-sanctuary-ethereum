/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.7;

contract MoodDiary{
    string mood;

    //create a function that writes a mood to the smart contract
    function setMood(string memory _mood) public{
        mood = _mood;
    }
    function getMood() public{ }
 }