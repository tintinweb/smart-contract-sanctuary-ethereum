/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Lock {
    // State variable to store a number
    uint public count = 0;

    // You need to send a transaction to write to a state variable.
    function add() public {
        count = count + 1;
    }

    // You can read from a state variable without sending a transaction.
    function getCount() public view returns (uint) {
        return count;
    }
}