/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract CoffeManager {
    // The keyword "public" makes variables
    // accessible from other contracts
    mapping (address => uint) public coffee;

    // Events allow clients to react to specific
    // contract changes you declare
    event CoffeeChanged(address addr, uint amount);

    // Constructor code is only run when the contract
    // is created
    constructor() {
        
    }

    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator
    function make() public {
        coffee[msg.sender] += 1;
        emit CoffeeChanged(msg.sender, coffee[msg.sender]);
    }

    function give(address addr) public {
        require(coffee[msg.sender] >= 1);
        coffee[addr] += 1;
        coffee[msg.sender] -= 1;
        emit CoffeeChanged(msg.sender, coffee[msg.sender]);
    }

    function drink() public {
        require(coffee[msg.sender] >= 1);
        coffee[msg.sender] -= 1;
        emit CoffeeChanged(msg.sender, coffee[msg.sender]);
    }
}