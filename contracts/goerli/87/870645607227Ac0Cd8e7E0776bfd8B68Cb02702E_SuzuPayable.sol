// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SuzuPayable {
    // Payable address can receive Ether
    address payable public owner;

    // Payable constructor can receive Ether
    constructor(address _owner) payable {
        owner = payable(_owner);
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {
        withdraw();
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}