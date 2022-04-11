/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract messagebox {

    string  message;

    constructor() {
        message = "Hello world!";
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
    function getMessage() public view returns(string memory) {
        return message;
    }

}