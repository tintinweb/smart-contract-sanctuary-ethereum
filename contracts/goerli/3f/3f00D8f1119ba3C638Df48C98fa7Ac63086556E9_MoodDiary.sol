/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
  
 pragma solidity ^0.8.18;

   contract MoodDiary{

       string mood;


       function setMood(string memory _mood) public{
           mood = _mood;
        }

       function getMood() public view returns(string memory){
           return mood;

        }


}