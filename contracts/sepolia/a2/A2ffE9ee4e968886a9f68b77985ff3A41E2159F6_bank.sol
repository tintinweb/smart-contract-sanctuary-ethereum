/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract bank{
    int bal;
    constructor() {
        bal=1;
    }
    function getbal() public view returns(int){
        return bal;
    }
    function withdraw(int amt) public
    {
      
        bal=bal-amt;
    }
    function deposit(int amt) public{
        bal=bal+amt;
    }
}