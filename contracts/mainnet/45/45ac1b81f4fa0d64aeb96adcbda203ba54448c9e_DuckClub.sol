/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: UNLICENSED
// Most of this contract has been created with Chat-GPT with minor modifications to restrict edits to the message and prevent griefing

pragma solidity ^0.8.13;

contract DuckClub {
    string public message;
    address private owner;

    constructor() {
        // You don't need a visibility modifier for the constructor
        message = "has anyone created a smart contract with chat-gpt yet";
        owner = msg.sender;
    }

    function setMessage(string memory _message) public {
        require(owner == msg.sender, "Must be contract owner to modify");
        message = _message;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}