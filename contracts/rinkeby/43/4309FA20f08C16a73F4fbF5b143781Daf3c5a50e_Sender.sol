// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.0;

contract Sender {
    function send(address payable receiver) public payable {
        (bool success,) = receiver.call.gas(10000000).value(msg.value)("");
        require(success, "Failed to send value!");
    }
}