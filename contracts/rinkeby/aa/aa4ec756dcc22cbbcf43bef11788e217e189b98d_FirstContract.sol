/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FirstContract {
    string private message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function setMsg(string memory newMessage) public {
        message = newMessage;
    }

    function getMsg() public view returns (string memory) {
        return message;
    }
}