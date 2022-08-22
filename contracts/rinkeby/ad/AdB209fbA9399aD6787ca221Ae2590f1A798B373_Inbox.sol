// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Inbox {
    uint256 value;
    string message;

    constructor(uint256 newValue) {
        value = newValue;
    }

    //storage => variable store on blockchain
    //memory => variable store in memory (state variable into memory by memory keyword)
    //calldata => variable store on ram ficked
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function retriew() public view returns (uint256, string memory) {
        return (value, message);
    }
}