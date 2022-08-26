// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'RetailerRole' to manage this role - add, remove, check
contract RetailerRole {
    using Roles for Roles.Role;
    
    /// @dev Define a struct 'farmers' by inheriting from 'Roles' library, struct Role
    Roles.Role private _retailers;

    /// @dev Event for Adding
    /// @param farmers Address of the farmers added to the contract
    event RetailerAdded (address farmers);

    /// @dev Event for Removing
    /// @param farmers Address of the farmers removed from the contract
    event RetailerRemoved (address farmers); 

    // In the constructor make the address that deploys this contract the 1st farmer
    constructor() {
        _addRetailer(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyRetailer() {
        require(isRetailer(msg.sender), "Sender is not a valid retailer");
        _;
    }

    // Define a function 'isRetailer' to check this role
    function isRetailer(address account) public view returns (bool) {
        return _retailers.has(account);
    }

    // Define a function 'addRetailer' that adds this role
    function addRetailer(address account) public onlyRetailer {
        _addRetailer(account);
    }

    // Define a function 'renounceRetailer' to renounce this role
    function renounceRetailer() public {
        _removeRetailer(msg.sender);
    }

    // Define an internal function '_addRetailer' to add this role, called by 'addRetailer'
    function _addRetailer(address account) internal {
        _retailers.add(account);
        emit RetailerAdded(account);
    }

    // Define an internal function '_removeRetailer' to remove this role, called by 'removeRetailer'
    function _removeRetailer(address account) internal {
        _retailers.remove(account);
        emit RetailerRemoved(account);
    }
}