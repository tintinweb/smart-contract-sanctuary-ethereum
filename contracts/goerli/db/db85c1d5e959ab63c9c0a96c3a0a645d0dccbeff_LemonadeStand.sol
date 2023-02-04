// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Bank.sol";

contract LemonadeStand {
    event Order();
    Bank public bank;

    constructor(address _bank) {
        bank = Bank(_bank);
    }

    function placeOrder() public {
        emit Order();
        bank.deposit(10);
    }
}