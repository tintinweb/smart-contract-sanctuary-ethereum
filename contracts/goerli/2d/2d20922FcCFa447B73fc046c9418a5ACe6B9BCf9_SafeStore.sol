// SPDX-License-Identifier: MIT

// This contract is an updated version of EtherStore
// It prevents re-entrancy attacks by 1.) updating the balance of the caller
// before executing the withdraw function
// and 2.) adding a modifier that locks the function while it is being called,
// preventing the function being called again during its execution.

pragma solidity ^0.8.13;

contract SafeStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    bool internal locked;
    // this modifier allows only one function to be executed at a time
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function withdraw(uint256 _amount) public noReentrant {
        uint256 bal = balances[msg.sender];
        require(bal >= _amount);
        balances[msg.sender] -= _amount; // change state of variable before function is called
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send ether");
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}