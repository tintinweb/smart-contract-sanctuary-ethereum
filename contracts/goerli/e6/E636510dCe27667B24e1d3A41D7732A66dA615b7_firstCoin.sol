/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract firstCoin {
    uint balance;
    constructor()
    {
        balance=0;
    }

    //deposit
    function deposit(uint amount)public
    {
        
        balance +=amount;
    }

    //widdraw
    function withdraw(uint amount)public
    {
        require(balance>amount,"Not enough funds");
        balance -=amount;
    }

    //getbalance
    function getBalance()public view returns(uint)
    {
        return balance;
    }

}