/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MoodDiary {
  string mood;

  function setMood(string memory _mood) public {
    mood = _mood;
  }

  function getMood() public view returns(string memory) {
    return mood;
  }
}