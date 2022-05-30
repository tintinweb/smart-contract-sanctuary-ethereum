/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    // Define varicble
    /* 
    type access_modifier name;
     */
    
    // default access_modifier = private
    
    // private
    string _name;
    uint _balance;
    
    // public
    int _amount = 100;

    constructor(string memory name, uint balance) {
        require(balance > 0, "balance must greater than 0");
        _name = name;
        _balance = balance;
    }
    // view
    function getBalance() public view returns(uint balance) {
        return _balance;
    }
    // pure
    function getBalancePure() public pure returns(uint balance) {
        return 100;
    }

    function deposite(uint amount) public {
        _balance += amount;
    }
    
}