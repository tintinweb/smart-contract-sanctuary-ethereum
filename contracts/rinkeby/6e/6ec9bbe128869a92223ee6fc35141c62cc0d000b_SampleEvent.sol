/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract SampleEvent {
    event HelloMessage(address sender, string message, uint256 timestamp);

    function emitEvent() public {
        emit HelloMessage(msg.sender, "Hello World!", block.timestamp);
        emit HelloMessage(msg.sender, "Hello The Meetup 110!", block.timestamp);
    }
}