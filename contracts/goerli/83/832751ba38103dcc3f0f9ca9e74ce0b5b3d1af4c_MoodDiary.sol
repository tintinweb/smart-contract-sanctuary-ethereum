// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.1;

 contract MoodDiary {
     string mood;
      
      function setMood(string memory _mood) public {
     mood = _mood;
 }

 //create a function the reads the mood from the smart contract
 function getMood() public view returns(string memory) {
     return mood;
 }


 }