// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'ConsumerRole' to manage this role - add, remove, check
contract ConsumerRole {
    using Roles for Roles.Role;

    /// @dev Define a struct 'consumers' by inheriting from 'Roles' library, struct Role
    Roles.Role private _consumers;

    /// @dev Event for Adding
    /// @param consumer Address of the consumer added to the contract
    event ConsumerAdded (address consumer);

    /// @dev Event for Removing
    /// @param consumer Address of the consmer removed from the contract
    event ConsumerRemoved (address consumer); 

    /// @dev Constructor of the contract. The address that deploys this contract is the 1st consumer
    constructor() {
        _consumers.add(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyConsumer() {
        require(isConsumer(msg.sender), "Sender is not a valid consumer");
        _;
    }

    // Define a function 'isConsumer' to check this role
    function isConsumer(address account) public view returns (bool) {
        return _consumers.has(account);
    }

    // Define a function 'addConsumer' that adds this role
    function addConsumer(address account) public onlyConsumer {
        _addConsumer(account);
    }

    // Define a function 'renounceConsumer' to renounce this role
    function renounceConsumer() public {
        _removeConsumer(msg.sender);
    }

    // Define an internal function '_addConsumer' to add this role, called by 'addConsumer'
    function _addConsumer(address account) internal {
        _consumers.add(account);
        emit ConsumerAdded(account);
    }

    // Define an internal function '_removeConsumer' to remove this role, called by 'removeConsumer'
    function _removeConsumer(address account) internal {
        _consumers.remove(account); 
        emit ConsumerRemoved(account);       
    }
}