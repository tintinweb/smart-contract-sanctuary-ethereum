/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract test {
    string public message = "fred";

    // constructor(string memory _message) {
    //     message = _message;
    // }

    // function setMessage(string memory newMessage) public {
    //     message = newMessage;
    // }

    function getMessage() public view returns (string memory) {
        return message;
    }
}