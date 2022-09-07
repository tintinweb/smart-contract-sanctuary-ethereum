/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at BscScan.com on 2022-09-07
*/

pragma solidity 0.8.0;

contract Employees {

    uint private totalSupply; // derived data type

    struct User {
        string name;
        uint balance;
    }

    // public => access anywhere
    // private => access within class
    // external => access without inherit
    // internal => access within class or in inhrited class

    mapping  (uint => User) private UserData;

    /* function  register() external {

    } */

    /*
        total supply fetch
        read operation no gas used
    */

    function readTotalSupply() view external returns(uint) {
        return  totalSupply;
    }

    /*
        register user 
        add free token 
        and update total supply
    */

    function register(uint _empCode, string memory _name) external {

        User memory temp;
        temp.name = _name;
        temp.balance = 10;
        UserData[_empCode]= temp;
        totalSupply += 10;
    }

    /*
        check user balance
    */

    function checkBalance(uint _empCode) view public returns (User memory){
        return  UserData[_empCode];
    }

}