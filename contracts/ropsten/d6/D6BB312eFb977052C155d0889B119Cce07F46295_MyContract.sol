/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

    string _name;
    uint _balance;

    constructor(string memory n,uint b){
        require(b >= 500,"balance grceeater and eqaul 500");
        _name = n;
        _balance = b;
    }

    function getBalance() public view returns(uint b){
        return _balance;
    } 
    
    function deposite(uint amount) public{
        _balance += amount;
    }

}