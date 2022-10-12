/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: UNLICENSED
 
pragma solidity ^0.8.4;
 
contract HelloWorld {
    //events
    //states
    //functions
 
    event messagechanged(string oldmsg, string newmsg);
 
    string public message;
 
    constructor(string memory firstmessage) {
        message = firstmessage;   
    }
 
    function update(string memory newmesssage) public {
        string memory oldmsg = message;
        message = newmesssage;
 
        emit messagechanged(oldmsg, newmesssage);
     }
}