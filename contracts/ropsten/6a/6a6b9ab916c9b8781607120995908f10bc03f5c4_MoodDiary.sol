/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

//specify the version of solidity
pragma solidity ^0.4.24;

/// a simple set and get function for mood defined: 

//define the contract
contract MoodDiary{
    
    //create a variable called mood
    string mood;
    
    //create a function that writes a mood to the smart contract
    function setMood(string _mood) public{
        mood = _mood;
    }
    
    //create a function the reads the mood from the smart contract
    function getMood() public view returns(string){
        return mood;
    }
}