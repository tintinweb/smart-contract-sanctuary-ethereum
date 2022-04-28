// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.0;

contract SenderWithoutHandlingCallReturn {
    function send(address payable receiver) public payable {
        receiver.call.gas(10000000).value(msg.value)("");
    }
}