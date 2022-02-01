/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
contract collector {
    address public owner;
    uint256 public balance;
    constructor() {
            owner = msg.sender;

    }
    receive() payable external {
        balance += msg.value;

    }
    function withdraw(uint256 amount, address payable destAddr)public {
            require(msg.sender == owner, "Only Owner can withdraw");
            destAddr.transfer(amount );
            balance -= amount;

    }
}