/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Mood {
    string public mood = "";


    function getMood() public view returns (string memory) {
        return mood;
    }

    function setMount(string memory _mood) public {
        mood = _mood;
    }

}