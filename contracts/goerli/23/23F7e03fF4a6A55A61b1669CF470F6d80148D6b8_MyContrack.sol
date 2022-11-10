/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContrack {
    //private variable
    uint _balance;    
    string _name;

    constructor(string memory name,uint balance) {
        require(balance>=500,"balance equal and greator more than 500");
        _name = name;
        _balance = balance;
    }
    function getBalance() public view returns(uint balance) {
        return _balance;
        
    }
}