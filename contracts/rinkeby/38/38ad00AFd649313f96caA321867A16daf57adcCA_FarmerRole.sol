// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'FarmerRole' to manage this role - add, remove, check
contract FarmerRole {
  using Roles for Roles.Role;

    /// @dev Define a struct 'farmers' by inheriting from 'Roles' library, struct Role
    Roles.Role private _farmers;

    /// @dev Event for Adding
    /// @param farmers Address of the farmers added to the contract
    event FarmerAdded (address farmers);

    /// @dev Event for Removing
    /// @param farmers Address of the farmers removed from the contract
    event FarmerRemoved (address farmers); 

    // In the constructor make the address that deploys this contract the 1st farmer
    constructor() {
        _addFarmer(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyFarmer() {
        require(isFarmer(msg.sender), "Sender is not a valid farmer");
        _;
    }

    // Define a function 'isFarmer' to check this role
    function isFarmer(address account) public view returns (bool) {
        return _farmers.has(account);
    }

    // Define a function 'addFarmer' that adds this role
    function addFarmer(address account) public onlyFarmer {
        _addFarmer(account);
    }

    // Define a function 'renounceFarmer' to renounce this role
    function renounceFarmer() public {
        _removeFarmer(msg.sender);
    }

    // Define an internal function '_addFarmer' to add this role, called by 'addFarmer'
    function _addFarmer(address account) internal {
        _farmers.add(account);
        emit FarmerAdded(account);
    }

    // Define an internal function '_removeFarmer' to remove this role, called by 'removeFarmer'
    function _removeFarmer(address account) internal {
        _farmers.remove(account);
        emit FarmerRemoved(account);
    }
}