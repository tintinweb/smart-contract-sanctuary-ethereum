/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VendingMachine {
    // functionalities:
    // - every user has their own balances of donuts
    // - a function to see total number of donuts available
    // - a function allow owner to restock the machine
    // - a function to purchase donuts, only if the user pays enough ether
    // - a function for the owner to take profit, i.e. withdraw balance

    // similar to EtherBank2
    address public owner;
    mapping(address => uint256) public donutBalances;
    uint256 public etherPerDonut = 2 ether;

    // NEED a constructor (function run at deployment)
    // - to set the owner
    // - to set up the initial stock of the machine
    constructor () {
        owner = msg.sender;
        donutBalances[address(this)] = 100;
        // set the contract to have 100 donuts
    }

    // allow owner to restock the machine
    // input: uint256 amount
    // will change blockchain data -> just public
    function restock(uint256 amount) public {
        // msg.sender must be owner
        require(msg.sender==owner, "Only owner can restock");

        // add amount to this contract's donut balance
        donutBalances[address(this)] += amount;
    }

    // check the stock
    // will not change blockchain data, only view -> public view
    function getStock() public view returns (uint256) {
        return donutBalances[address(this)];
    }

    // purchase donut
    // will change blockchain data -> public
    // will take payment -> payable
    // input: uint256 amount (number of donuts)
    function purchase(uint256 amount) public payable {
        // enough payment
        // msg.value larger than or equal to amount * price
        require(msg.value >= amount * etherPerDonut, "Not enough payment");
        // enough stock
        // donut balance must be larger than or equal to amount
        require(donutBalances[address(this)] >= amount, "Not enough stock");
        // deduct amount from stock
        donutBalances[address(this)] -= amount;
        // add amount to user
        donutBalances[msg.sender] += amount;
    }

    // allow owner to withdraw profit
    function withdraw() public {
        address payable to = payable(owner);
        to.transfer(address(this).balance);
    }

    // gift my donut to someone else
    function gift(address to, uint256 amount) public {
        // make sure the gifter has enough donuts
        require(donutBalances[msg.sender] >= amount, "Not enough to gift");
        // deduct amount from sender
        donutBalances[msg.sender] -= amount;
        // add amount to recipient
        donutBalances[to] += amount;
    }

    // refund function
    // return donut for ether
    function refund(uint256 amount) public {
        require(donutBalances[msg.sender] >= amount, "Not enough to refund");

        // deduct amount from customer
        donutBalances[msg.sender] -= amount;
        // add amount to stock
        donutBalances[address(this)] += amount;

        address payable to = payable(msg.sender);
        to.transfer(amount * etherPerDonut);
        // flaw: what if the contract does not have enough ether?

    }
}