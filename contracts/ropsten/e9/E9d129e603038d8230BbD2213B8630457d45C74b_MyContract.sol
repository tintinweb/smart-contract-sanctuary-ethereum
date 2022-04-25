/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract{
    //private variable
    string _name;
    uint _balance;

    constructor(string memory name, uint balance){
        require(balance >= 1000, "Balance greater than 1000");
        _name = name;
        _balance = balance;
    }
    function getBallance() public view returns(uint balance){
        return _balance;
    }

    function deposite(uint amount) public{
        _balance += amount;
    }


}