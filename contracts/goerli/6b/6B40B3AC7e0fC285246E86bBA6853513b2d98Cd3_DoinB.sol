// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDoinB.sol";

// 2.0
// [email protected]: this file implements the Doin Coin(DoinB) for transfering value on ethereum.


// The Doin Coin: Used to exchange value in mobile edge computing.
contract DoinB is IDoinB {
    // Some string type variables to identify the token.
    string public name = "The Doin Coin";
    string public symbol = "DoinB";

    // total supply
    uint256 public totalSupply = 1000000000;

    // A mapping stores each account balance.
    mapping(address => uint256) balances;

    // Send all coins to the contract creator first.
    constructor() {
        balances[msg.sender] = totalSupply;
    }

    // transfer some balance to another account.
    function transfer(address to, uint256 amount) override external {
        require(balances[msg.sender] >= amount, "Not enough DoinB. ");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    // query the balance of a given account.
    function balanceOf(address account) override external view returns (uint256) {
        return balances[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// 转账、查看余额
interface IDoinB {
    // transfer some balance to another account.
    function transfer(address to, uint256 amount) external;
    // query the balance of a given account.
    function balanceOf(address account) external view returns (uint256);
}