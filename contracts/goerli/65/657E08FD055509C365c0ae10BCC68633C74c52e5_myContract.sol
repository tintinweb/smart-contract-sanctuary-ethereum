/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract myContract{
    
    string _name;
    uint _balance;

    constructor (string memory name,uint balance){
        require (balance>1000,"balance must be more than 1000");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint balacne){
           return _balance;
    }
}