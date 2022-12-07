/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract MoodDiary{
    
    string mood;
    string [] public Moods;


    
    function setMood(string memory _mood) public{
        mood = _mood;
        Moods.push(mood);
    } 
    

    function getMood() public view returns(string memory){
        return mood;
    }


}