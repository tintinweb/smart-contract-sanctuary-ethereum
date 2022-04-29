/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

contract SenderWithoutHandlingCallReturn {
    function send(address payable receiver) public payable {
        receiver.call.gas(20000000).value(msg.value)("");
    }
}