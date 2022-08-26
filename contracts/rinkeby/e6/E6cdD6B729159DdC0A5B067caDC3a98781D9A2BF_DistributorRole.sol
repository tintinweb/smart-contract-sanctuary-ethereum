// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'DistributorRole' to manage this role - add, remove, check
contract DistributorRole {
    using Roles for Roles.Role;

    /// @dev Define a struct 'distributors' by inheriting from 'Roles' library, struct Role
    Roles.Role private _distributors;

    /// @dev Event for Adding
    /// @param distributor Address of the distributor added to the contract
    event DistributorAdded (address distributor);

    /// @dev Event for Removing
    /// @param distributor Address of the distributor removed from the contract
    event DistributorRemoved (address distributor); 

    /// @dev Constructor of the contract. The address that deploys this contract is the 1st distributor
    constructor() {
        _distributors.add(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyDistributor() {
        require(isDistributor(msg.sender), "Sender is not a valid distributor");
        _;
    }

    // Define a function 'isDistributor' to check this role
    function isDistributor(address account) public view returns (bool) {
        return _distributors.has(account);
    }

    // Define a function 'addDistributor' that adds this role
    function addDistributor(address account) public onlyDistributor {
        _addDistributor(account);
    }

    // Define a function 'renounceDistributor' to renounce this role
    function renounceDistributor() public {
        _removeDistributor(msg.sender);
    }

    // Define an internal function '_addDistributor' to add this role, called by 'addDistributor'
    function _addDistributor(address account) internal {
        _distributors.add(account);
        emit DistributorAdded(account);
    }

    // Define an internal function '_removeDistributor' to remove this role, called by 'removeDistributor'
    function _removeDistributor(address account) internal {
        _distributors.remove(account);        
        emit DistributorRemoved(account);
    }
}