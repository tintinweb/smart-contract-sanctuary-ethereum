/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SplitWise {

    struct Expense {
        address to;
        address from;
        uint amount; 
        string note;
        uint expenseType;
    }

    struct Person {
        string nickname;
    }


    mapping(address => Person) people;

    Expense[] public expenses;

    function sendMoney(address to, uint amount , string memory note , uint expenseType ) public {
        // require(people[msg.sender].balance > amount , "Insufficient Funds");
        expenses.push(Expense(to , msg.sender , amount , note , expenseType));
    }

    function getBalance() public view returns (Person memory) {
        // return expenses[msg.sender];
    }


}