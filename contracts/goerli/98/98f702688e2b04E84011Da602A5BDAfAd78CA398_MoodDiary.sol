/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

/**
 *Submitted for verification at Etherscan.io on 2018-11-28
*/

pragma solidity ^0.4.25;

/// a simple set and get function for mood defined: 

contract MoodDiary{
    
    string mood;
    
    function setMood(string _mood) public{
        mood = _mood;
    }
    
    function getMood() public view returns(string){
        return mood;
    }
}