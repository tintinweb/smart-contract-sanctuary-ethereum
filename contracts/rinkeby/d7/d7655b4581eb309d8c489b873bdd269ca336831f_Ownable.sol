/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Ownable {
    
    // All veriables will be here
    address owner;

    // constructor is run upon contract being deployed and is only run once
    constructor() {
        owner = msg.sender;
    }

    // Modifiers are used to store a specific parameters that will be called
    // multiple times in a contract. Allowing you to only have to write it once.
    modifier onlyOwner() {
        require(msg.sender == owner, "YOU MUST BE THE OWNER TO DO THAT. SORRY!");
        _;
    }
}