// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.8.10;


contract Money {

    uint money;

    function Deposit(uint _money) public { 
        money = _money;
    }

    function Withdraw() public view returns(uint){
        return money*2;
    }

}