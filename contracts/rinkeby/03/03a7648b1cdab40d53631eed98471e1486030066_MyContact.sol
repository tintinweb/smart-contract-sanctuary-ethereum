/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//simulate like bank account
contract MyContact{

    //private default
    string _name;
    uint _balance;

    //initial executed (once) likely function
    constructor(string memory name,uint balance){
        require(balance>=500 , "balance must be greater or equal 500");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint){
        return _balance;
    }
    
}