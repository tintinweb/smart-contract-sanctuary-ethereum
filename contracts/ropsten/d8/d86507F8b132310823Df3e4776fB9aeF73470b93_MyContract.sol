/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {
// Comment
/* Comment */
    string _name = "test";
    uint _balance = 1000;

    constructor(string memory name, uint balance){
        require(balance > 0, "balance greater zero (balance > 0)");
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