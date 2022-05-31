/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Hello {
    string private message;
    constructor(string memory _message){
        message = _message;
    }
    function getMessage() public view returns (string memory) {
        return message;
    }
    function setMessage(string memory _message) public {
        message = _message;
    }
}