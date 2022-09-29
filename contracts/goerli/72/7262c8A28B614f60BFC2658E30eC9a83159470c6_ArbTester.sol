//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.11;

contract ArbTester {
    address payable owner;

    constructor() public {
        owner = msg.sender;
    }

    function deposit() external payable {
        if (msg.sender != owner) {
            revert();
        }
    }

    // test if msg.sender.call works for some value larger than balance
    function withdraw() external {
        if (msg.sender != owner) {
            revert();
        }

        //
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH_TRANSFER_FAIL");
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}