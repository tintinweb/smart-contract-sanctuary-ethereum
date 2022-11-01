/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mycontract {
    // private 
    string _name;
    uint _balance;

    // gas 
    constructor(string memory name, uint balance) {
        _name = name;
        _balance = balance;
    }

    // no gas views only 
    function getbalance() public view returns(uint balance) {
        return _balance;
    }
    
    // pay gas
    // function deposit(uint amount) public {
    //     _balance += amount;
    // }
}