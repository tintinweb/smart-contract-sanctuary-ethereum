// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.0;

contract Sender {
    event Debug(bool success);

    function send(address payable receiver) public payable {
        (bool success,) = receiver.call.gas(10000000).value(msg.value)("");
        emit Debug(success);
    }
}