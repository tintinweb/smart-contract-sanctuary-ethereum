/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;
contract mooddairy{
    string  mood;
    function setmood(string memory _mood) public{
        mood=_mood;

    }
    function getmood() public view returns(string memory){
        return mood;
    }
}