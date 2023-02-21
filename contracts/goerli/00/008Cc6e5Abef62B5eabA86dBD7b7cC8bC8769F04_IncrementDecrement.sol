/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IncrementDecrement {
    uint public count;

    event eventDetails(uint newValue, string message);

    function increment() public {
        count++;
        emit eventDetails(count, "increment");
    }

    function decrement() public {
        require(count > 0, "Cannot decrement below zero");
        count--;
        emit eventDetails(count, "decrement");
    }
}