/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
// https://www.youtube.com/watch?v=wWAkR7CUwe4

contract VendingMachine {
    address public owner;
    mapping (address => uint) public donutBalances;

    constructor() {
        owner = msg.sender;
        donutBalances[address(this)] = 100;  
        //Any one purchase donuts from the machine gets 100 donuts.
    }

    // public view means cannot modify data, but can read.
    //. can be view. pure won't be able to read.
    function getVendingMachineBalance() public view returns (uint) {
        // return donut count for this address.
        return donutBalances[address(this)];
    }

    // here data on blockchain is modified.
    // require statement: 1 requirements 2 error message
    function restock(uint amount) public {
        // the caller must be owner
        require(msg.sender == owner, "Only the owner can restock this machine.");
        donutBalances[address(this)] += amount;
    }

    // payable is a keyword. 
    // need when sending Ether
    function purchase(uint amount) public payable {
        // msg.value is the transaction level
        // check that sender send this amount
        require(msg.value >= amount * 2 ether, "You must pay at least 2 ether per donut");
        // this is purchase price.

        // check 2: make sure we have enough donuts
        require(donutBalances[address(this)] >= amount, "Not enough donuts in stock to fulfill purchase request");

        // donut balance will decrease 
        donutBalances[address(this)] -= amount;
        donutBalances[msg.sender] += amount;
        // add donut balance to the sender 

        // now need to make sure amount is ok. setting price.
        // this is the require expression above
    }
}