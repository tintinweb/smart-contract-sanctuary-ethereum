/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// File: mood.sol

contract Mood{
    string mood;

    function setMood(string memory _mood) public{
        mood = _mood;
    }

    function getMood() public view returns(string memory){
        return mood;
    }
    

}