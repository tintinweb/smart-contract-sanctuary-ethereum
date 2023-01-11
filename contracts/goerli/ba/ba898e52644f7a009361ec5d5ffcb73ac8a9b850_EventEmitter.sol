/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

contract EventEmitter {
    // Define the owner of the contract
    address private owner;

    // Define a mapping to store the authorization status of each address for each identifier
    mapping(address => mapping(string => bool)) private isAuthorized;

    // Define the event that will be emitted when the function is called
    event LogArgument(address sender, string identifier, bytes message);

    constructor() public {
        // Set the contract owner to the address that deployed the contract
        owner = msg.sender;
    }

    // Define the function that will emit the event
    function emitEvent(string memory identifier, bytes memory message) public {
        // Only allow authorized addresses to call this function
        require(isAuthorized[msg.sender][identifier], "Unauthorized address");

        // Emit the event with the message sender, identifier, and message passed into the function
        emit LogArgument(msg.sender, identifier, message);
    }

    // Define a function to authorize an address for a specific identifier
    function authorize(string memory identifier, address addr) public {
        // Only allow the owner to authorize addresses
        require(msg.sender == owner, "Only the owner can authorize addresses");

        // Set the authorization status of the address for the given identifier to true
        isAuthorized[addr][identifier] = true;
    }

    // Define a function to remove authorization for an address for a specific identifier
    function removeAuthorization(string memory identifier, address addr) public {
        // Only allow the owner to remove authorization
        require(msg.sender == owner, "Only the owner can remove authorization");

        // Set the authorization status of the address for the given identifier to false
        isAuthorized[addr][identifier] = false;
    }

    // Define a function to transfer ownership of the contract
    function transferOwnership(address newOwner) public {
        // Only allow the owner to transfer ownership
        require(msg.sender == owner, "Only the owner can transfer ownership");

        // Transfer ownership to the new owner
        owner = newOwner;
    }
}