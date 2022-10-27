/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 contract Mod {

     constructor () {

     }

    string public mood;

     function setMod(string memory _mod) public {
         mood = _mod;
     }

     function getMood() public view returns (string memory) {
         return mood;
     }
 }