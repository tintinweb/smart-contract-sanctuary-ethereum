/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract helloworld{
    string message = "Hello World!!";

    constructor () {

    }

    function setMessage(string memory _message) public {  // memory, storage
        message = _message;
    }

    function getMessage() public view returns (string memory){
        return message;
    }
}