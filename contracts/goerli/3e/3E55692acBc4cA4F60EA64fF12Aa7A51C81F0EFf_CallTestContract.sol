/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract CallTestContract {
    uint a;

    event NewTrade(
        uint indexed date,
        address indexed from,
        address indexed to, // Only three indexed variables are allowed in an event
        uint amount
    );
    function Trade(address to, uint amount) external{
        emit NewTrade(block.timestamp, msg.sender, to, amount);
        a++;
    }
}