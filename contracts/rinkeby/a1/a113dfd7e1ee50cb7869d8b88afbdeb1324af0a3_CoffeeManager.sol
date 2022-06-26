/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract CoffeeManager {
    // The keyword "public" makes variables
    // accessible from other contracts
    mapping (address => uint) public coffee;
    mapping (address => uint) public ownerIndex;
    
    uint256 public index;

    // Events allow clients to react to specific
    // contract changes you declare
    event CoffeeChanged(uint256 id, address addr, uint amount);

    // Constructor code is only run when the contract
    // is created
    constructor() {
        
    }

    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator
    function make() public {
        uint256 id;
        if(ownerIndex[msg.sender] == 0) {
            index = index + 1;
            id = index;
            ownerIndex[msg.sender] = id;
        } else {
            id = ownerIndex[msg.sender];
        }
        coffee[msg.sender] += 1;
        emit CoffeeChanged(id, msg.sender, coffee[msg.sender]);
    }

    function give(address addr) public {
        require(coffee[msg.sender] >= 1);
        if(ownerIndex[addr] == 0) {
            index = index + 1;
            ownerIndex[addr] = index;
            emit CoffeeChanged(index, addr, 1);
        }
        uint256 id = ownerIndex[msg.sender];
        coffee[addr] += 1;
        coffee[msg.sender] -= 1;
        emit CoffeeChanged(id, msg.sender, coffee[msg.sender]);
    }

    function drink() public {
        require(coffee[msg.sender] >= 1);
        uint256 id = ownerIndex[msg.sender];
        coffee[msg.sender] -= 1;
        emit CoffeeChanged(id, msg.sender, coffee[msg.sender]);
    }
}