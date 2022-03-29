/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// wbrasil.eth 1st contract 
pragma solidity ^0.8.7;

contract MoodDiary{

    string mood;

    //create a function that writes a mood to the smart contract
    function setMood(string memory _mood) public{
        mood = _mood;
    }

    //create a function the reads the mood from the smart contract
    function getMood() public view returns(string memory){
        return mood;
    }

}