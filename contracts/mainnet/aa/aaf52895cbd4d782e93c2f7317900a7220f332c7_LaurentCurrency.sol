/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract LaurentCurrency {
    mapping (address => uint) public balances;
    event Sent(address from, address to, uint amount);

    constructor() {
        balances[msg.sender] += 10000000 * 1000000; // 1 million microLC = 1 LC
    }

    error InsufficientBalance(uint requested, uint available);

    function send(address receiver, uint amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}