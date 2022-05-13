/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract myCountract {
    /*
        - only off-chain can read event data
        - on-chain can't read this data
        - can use 3 indexeds in event, no more
        - it cost less. So, if you don't need to use this data on-chain, you can use event
    */

    event NewTrade(
        uint256 indexed date,
        address indexed from, // easy to find data in event but cost more gas to store data
        address indexed to,
        uint256 amount
    );

    function trade(address to, uint256 amount) external {
        emit NewTrade(block.timestamp, msg.sender, to, amount);
    }
}