/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.4.19;

contract HelloWorld {

    string public message;

    function setMessage(string memory _message) public {
        message = _message;
    } 

    function viewMessage() public view returns(string memory) {
        return message;
    }
}