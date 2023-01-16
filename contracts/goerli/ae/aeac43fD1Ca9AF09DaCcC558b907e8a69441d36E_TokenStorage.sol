// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This is a sample, untested contract used for very basic flow testing

// TokenStorage AKA Vault
contract TokenStorage {
    address public owner;
    mapping(address => bool) public custodians;

    constructor(address _owner) {
        owner = _owner;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(msg.sender == owner || custodians[msg.sender], "Only owner or custodians can deposit");
    }

    function withdraw(uint256 _amount) public {
        require(_amount <= address(this).balance, "Insufficient balance");
        require(msg.sender == owner || custodians[msg.sender], "Only owner or custodians can withdraw");
        payable(msg.sender).transfer(_amount);
    }

    function send(address _to, uint256 _amount) public {
        require(_amount <= address(this).balance, "Insufficient balance");
        require(msg.sender == owner || custodians[msg.sender], "Only owner or custodians can send ether");
        require(_to != address(0), "Invalid address");
        payable(_to).transfer(_amount);
    }

    function setCustodian(address _custodian) public {
        require(msg.sender == owner, "Only owner can set custodians");
        custodians[_custodian] = true;
    }

    function unsetCustodian(address _custodian) public {
        require(msg.sender == owner, "Only owner can unset custodians");
        custodians[_custodian] = false;
    }
}

contract VaultDeployer {
    address public owner;
      bool public allowDeployment;

    event VaultDeployed(address newVault);

    constructor() {
        owner = msg.sender;
        allowDeployment = true;
    }

    function deployVault(address _owner) public returns (address) {
        require(allowDeployment, "Deployment is not allowed");
        TokenStorage newVault = new TokenStorage(_owner);
        emit VaultDeployed(address(newVault));
        return address(newVault);
    }

    function changeDeploymentStatus(bool _status) public {
        require(msg.sender == owner, "Only owner can change deployment status");
        allowDeployment = _status;
    }
}