/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

contract HelloWorld {
    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}