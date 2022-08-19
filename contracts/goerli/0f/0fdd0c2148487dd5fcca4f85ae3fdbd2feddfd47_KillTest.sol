/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract KillTest {
    event KillMySelf(address indexed from);

    fallback() external payable {}

    // everyone can kill this contract
    function kill() public payable {
        selfdestruct(payable(msg.sender));
        emit KillMySelf(msg.sender);
    }
}