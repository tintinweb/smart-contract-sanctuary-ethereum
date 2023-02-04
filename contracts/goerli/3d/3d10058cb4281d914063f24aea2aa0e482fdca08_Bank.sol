/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Bank {
    event Deposit(uint256 amount);

    function deposit(uint256 amount) public {
        emit Deposit(amount);
    }
}