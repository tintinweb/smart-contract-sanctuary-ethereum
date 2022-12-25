/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

//SPDX-License-Identifier: UNLICENSED
//specify the version of solidity
pragma solidity ^0.8.1;

// a simple set and get function for mood defined: 
/*
   * @title MoodDiary
   * @dev ContractDescription
   * @custom:dev-run-script contracts/mood.sol
*/
//define the contract
contract MoodDiary{
    
    //create a variable called mood
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