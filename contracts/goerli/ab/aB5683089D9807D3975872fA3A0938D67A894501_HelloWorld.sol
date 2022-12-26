/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.17 ;

contract HelloWorld {

    event messagechanged(string oldmsg, string newmsg);

    string public message;

    constructor(string memory firstmessage){
        message = firstmessage;
    }

    function update(string memory newmessage) public {
        string memory oldmsg = message;
        message = newmessage;
        emit messagechanged(oldmsg, newmessage);
    }
    
}