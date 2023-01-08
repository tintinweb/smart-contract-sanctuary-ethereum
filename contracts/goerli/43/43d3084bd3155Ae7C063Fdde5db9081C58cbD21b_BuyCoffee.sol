// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BuyCoffee {
    address payable public owner;


    struct Coffee {
        string name;
        string message;
    }

    uint public numCoffess;
    Coffee[] public coffees;

    constructor() {
        owner = payable(msg.sender);
    }

    function buy(string memory name, string memory message) public payable {
        require(msg.value >= 0.1 ether, "not enough money to transact");
        numCoffess++;
        Coffee memory c = Coffee(name, message);
        coffees.push(c);
        owner.transfer(msg.value);
    }
}