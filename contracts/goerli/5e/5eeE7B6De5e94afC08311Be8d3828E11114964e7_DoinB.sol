// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDoinB.sol";

// [email protected]: this file implements the Doin Coin(DoinB) for transfering value on ethereum.

// DoinB
// The Doin Coin: Used to exchange value in mobile edge computing.
contract DoinB is IDoinB {
    // Some string type variables to identify the token.
    string public name = "The Doin Coin";
    string public symbol = "DoinB";

    // total supply:    1000000000
    uint256 public totalSupply = 1000000000;

    // A mapping stores each account balance.
    mapping(address => uint256) balances;

    // Send all coins to the contract creator first.
    constructor() {
        balances[msg.sender] = totalSupply;
    }

    // Transfer some balance to another account.
    function transfer(address to, uint256 amount) override external {
        require(balances[msg.sender] >= amount, "Not enough DoinB. ");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    // Query the balance of a given account.
    function balanceOf(address account) override external view returns (uint256) {
        return balances[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDoinB {
    // Transfer some balance to another account.
    function transfer(address to, uint256 amount) external;
    // Query the balance of a given account.
    function balanceOf(address account) external view returns (uint256);
}