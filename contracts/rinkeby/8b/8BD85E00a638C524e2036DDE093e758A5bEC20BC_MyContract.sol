/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

    bool _status;
    string _name;
    int _amount;
    uint _balance;

    constructor(string memory name, uint balance){
        require(balance >= 500, "balance >= 500");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint balance){
        return _balance;
    }

    function deposit(uint amount) public{
        _balance += amount;
    }

    // function getBalance() public pure returns(uint balance){
    //     return 49;
    // }

}