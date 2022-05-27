/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/MoodContract.sol

pragma solidity 0.8.14;

contract MoodContract {

    string mood;

    function setMood(string memory mymood) public {
        mood = mymood;
    }

    function getMood() public view returns (string memory){
        return mood;
    }
}