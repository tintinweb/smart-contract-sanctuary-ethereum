// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SuzuPayable {
    // Payable address can receive Ether
    event Transfer(address indexed from, address indexed to, uint256 value);
    address payable public owner;

    // Payable constructor can receive Ether
    constructor(address _owner) payable {
        if (_owner == address(0)) {
            owner = payable(msg.sender);
        } else {
            owner = payable(_owner);
        }
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit(uint256 amount) public payable {
        require(msg.value >=amount, "amount invalid");
        withdraw();
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
        emit Transfer(address(this), owner, amount);
    }
}