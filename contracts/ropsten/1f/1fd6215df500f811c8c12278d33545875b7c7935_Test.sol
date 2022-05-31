/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    mapping(uint256 => address) public tickets;
    uint256 public totalTickets;

    function getNewTickets() external returns (uint256) {
        totalTickets += 1;
        tickets[totalTickets] = msg.sender;
        return totalTickets;
    }
}