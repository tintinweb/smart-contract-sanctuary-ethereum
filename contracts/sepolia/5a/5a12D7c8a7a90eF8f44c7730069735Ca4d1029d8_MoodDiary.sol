/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17 ;


contract MoodDiary {

    //This is the main solidity contract

    string mood;

    function getmood() public view returns (string memory){
        return mood;

    }

    function setmood(string memory _mood) public {
        mood = _mood;
    }


}