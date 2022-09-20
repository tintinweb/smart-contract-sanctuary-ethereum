// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// Not enough funds for transfer. Requested `requested`,
/// but only `available` available.
error NotEnoughFunds(uint requested, uint available);

contract Coin {
    mapping(address => uint) balances;

    function transfer(address to, uint amount) public {
        uint balance = balances[msg.sender];
        if (balance < amount) revert NotEnoughFunds(amount, balance);
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}