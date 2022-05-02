/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

contract WrapperRegistry is Authorizable {
    address[] public wrappers;

    /// @notice Constructs this contract and stores needed data
    /// @param _owner The contract owner authorized to validate addresses
    constructor(address _owner) {
        // authorize the owner address to be able to execute the validations
        _authorize(_owner);
    }

    /// @notice adds a vault + wrapper pair of addresses to state array
    /// @param wrapper the wrapped position contract address
    function registerWrapper(address wrapper) external onlyAuthorized {
        wrappers.push(wrapper);
    }

    /// @notice shows the entire array of vault/wrapper pairs
    /// @return the entire array of struct pairs
    function viewRegistry() external view returns (address[] memory) {
        return wrappers;
    }
}