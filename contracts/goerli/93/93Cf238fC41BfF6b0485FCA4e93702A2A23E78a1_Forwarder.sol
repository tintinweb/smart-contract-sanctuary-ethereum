/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Forwarder {
    function forward(address payable to) public payable {
        to.transfer(msg.value);
    }
}