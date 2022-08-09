/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

//SPDX-License-Identifier: UNLICENSED
//declare the solidity version 
pragma solidity ^0.8.7;

//declare the contract name, in our instance it's called simpleContract
//a basic contract that would be used to store mood and retrieve
contract simpleContract{
// here we declare mood, ofcourse the mood is of data type string
    string mood;
//we have a function setMood here that collects an input of _mood and store it 
    function setMood(string memory _mood) public {
        mood = _mood;
    }
    function getMood() public view returns(string memory){
        return mood;
    }
}