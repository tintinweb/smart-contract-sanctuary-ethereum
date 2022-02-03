// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface Moloch {
    function checkMembership(address _member) external view returns (bool);
}

contract Proxy {

    // Governance DAO contract for checking membership
    Moloch public moloch;

    // address of the platorm manager
    address public platform;

    mapping(string => address) public resourceContractAddress;
    mapping(string => bool) public enabled;

    // owners for each resourceId
    mapping(string => address) public owners;

    event ResourceRegistered(address indexed resource, string resourceId);
    event ResourceModified(
        string indexed resourceId,
        address indexed currentAddress,
        address indexed newAddress
    );
    event ResourceEnabled(string indexed resourceContractAddress);
    event ResourceDisabled(string indexed resourceContractAddress);

    constructor(address _moloch) {
        platform = msg.sender;
        moloch = Moloch(_moloch);
    }

    modifier onlyMembers {
        require(moloch.checkMembership(msg.sender), "Not a member");
        _;
    }

    modifier onlyOwners(string memory resourceId) {
        require(owners[resourceId] == msg.sender || platform == msg.sender, "Operation not allowed");
        _;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function registerResource(string memory resourceId, address contractAddress) external onlyMembers {
        require(resourceContractAddress[resourceId] == address(0));
        resourceContractAddress[resourceId] = contractAddress;
        enabled[resourceId] = true;
        owners[resourceId] = msg.sender;
        emit ResourceRegistered(contractAddress, resourceId);
    }

    
    function enable(string memory resourceId) external onlyOwners(resourceId) {
        enabled[resourceId] = true;
        emit ResourceEnabled(resourceId);
    }

    function isEnabled(string memory resourceId) external view onlyOwners(resourceId) returns (bool) {
        return enabled[resourceId];
    }

    
    function disable(string memory resourceId) external onlyOwners(resourceId) {
        enabled[resourceId] = false;
        emit ResourceDisabled(resourceId);
    }

    
    function modifyResource(string memory resourceId, address newResourceContractAddress)
        external onlyOwners(resourceId)
    {
        require(resourceContractAddress[resourceId] != address(0) && newResourceContractAddress != address(0), "Wrong parameter value");
        address currentAddress = resourceContractAddress[resourceId];
        resourceContractAddress[resourceId] = newResourceContractAddress;
        emit ResourceModified(resourceId, currentAddress, newResourceContractAddress);
    }

    function deleteResource(string memory resourceId) external onlyOwners(resourceId) {
        
        enabled[resourceId] = false;
        resourceContractAddress[resourceId] = address(0);
    }
}