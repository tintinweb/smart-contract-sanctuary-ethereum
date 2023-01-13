/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    string public message;

    // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
    // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
    constructor(string memory initMessage) {
        // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
        message = initMessage;
    }

    // A public function that accepts a string argument and updates the `message` storage variable.
    function update(string memory newMessage) public {
        message = newMessage;
    }
}