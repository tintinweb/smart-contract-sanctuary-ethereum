/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CallTestContract {

    event NewTrade(
        string message,
        uint indexed date,
        address indexed from,
        address indexed to, // Only three indexed variables are allowed in an event
        uint amount,
        uint transaction
    );
    function Trade(string calldata _message, address to, uint amount) external payable{
        emit NewTrade(_message, block.timestamp, msg.sender, to, amount, msg.value);
    }
}