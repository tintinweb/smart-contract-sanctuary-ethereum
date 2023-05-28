/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract MyContract {

    // Data Type
    // boolean
    // integer - Int, uint (positive num only)
    // string
    // struck ** 
    // array
    // mapping ** <key, value>

    // declare variable
    // type access_monifier name
    // uint public Hello = 100;
    // string public  World = "World";

    // private
    // _name conventional start with _ will be private var
    // string _foo;
    // uint _bar;
    // int _amount = 100;    
    // bool _status = false;

    // constructor

    string _name;
    uint _balance;

    // execute first time only 
    constructor(string memory name, uint balance) {
        // validation/rules
        require(balance > 0, "balance greater 0");
        _name = name;
        _balance = balance;
    }
    

    // require
    
    // function
    // - Pure
    // - View
    // - Payable
    function getName() public view returns(string memory name) {
        return _name;
    }

    function getBalance() public  view returns(uint balance){
        return _balance;// get balance from storage
    }

    function deposite(uint amount) public {
        _balance += amount;
    } 

}