/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.6;

contract Money {
    uint money;

    function Deposit(uint _money) public {
        money = _money;
    }

    function Withdraw() public view returns(uint) {
        return money*2;
    }
}