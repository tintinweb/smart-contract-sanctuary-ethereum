//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestMessage {

    event Message (address indexed sender, string message, uint256 timestamp);


    function fireMessage (string calldata _message) public {

        emit Message (msg.sender, _message, block.timestamp);
    }
}