/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.1;

 contract MoodDiary{
     string mood;
     //function to set a mood in the smart contract
     function setMood(string memory _mood) public {
         mood = _mood;
     }

    //function to get mood from the smart contract
    function getMood() public view returns(string memory){
        return mood;
    }
 }