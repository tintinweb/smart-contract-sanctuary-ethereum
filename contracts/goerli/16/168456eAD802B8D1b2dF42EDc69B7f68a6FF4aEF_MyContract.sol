/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract MyContract{
    string _name;
    uint _balance;

    constructor(string memory name, uint balance){
        require(balance >= 100000, "Require balance atleast 100000");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint balance){
        return _balance;
    }
}