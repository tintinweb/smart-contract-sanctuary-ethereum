/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.
contract Challenge{

    address[] public winners;
    bool lock;

    function exploit_me(address winner) public{
        lock = false;

        msg.sender.call("");

        require(lock, "Not Lock!");
        winners.push(winner);
    }

    function lock_me() public{
        lock = true;
    }
}