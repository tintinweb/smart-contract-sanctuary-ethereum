/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract Bank{
    int bal;
    constructor() {
          bal = 1;
    }

    function getBalance() view public returns(int){
        return bal;
    }

    function withdraw(int amt) public{
        bal = bal - amt;
    }

    function deposit(int amt) public{
        bal = bal + amt;
    }

}