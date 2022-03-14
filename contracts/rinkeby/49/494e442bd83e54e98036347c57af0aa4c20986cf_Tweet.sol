/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Tweet {
    event Msg(address indexed sender, string message);

    function sendTweet(string calldata message) public {
        emit Msg(msg.sender, message);
    }
}