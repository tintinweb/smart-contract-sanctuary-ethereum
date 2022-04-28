/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;


contract SampleContract{

    
    string message = "";


    constructor(){

    }


    function sendMessage(string memory newMessage)public{
        message = newMessage;
    }

    function getMessage() public view returns(string memory msg){
        return message;
    }


}