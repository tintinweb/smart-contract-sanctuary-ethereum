/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    // type access_modifier(default = private) variable_name;
    string _name;
    uint _balance;
    
    // Gas consumation
    constructor(string memory name, uint balance) {
        require(balance >= 500, "Balance needs to have at least 500");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint balance) {
        return _balance;
    }

    function deposit(uint amount) public {
        _balance += amount;
    }
}