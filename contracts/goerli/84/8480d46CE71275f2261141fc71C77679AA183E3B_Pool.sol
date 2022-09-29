// SPDX // SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Errors
error Pool__NotOwner();

contract Pool {
    // State variables
    uint256 private immutable i_purchasePrice;
    uint256 private contractBalance;
    address private immutable i_owner;

    // Events

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Pool__NotOwner();
        _;
    }

    // Constructor (initializing contract)
    constructor(uint256 purchasePrice) {
        i_owner = msg.sender;
        i_purchasePrice = purchasePrice;
    }

    // Functions
    // Makes purchase of 1ETH
    function makePurchase() public payable {
        require(msg.value >= i_purchasePrice, "Spend more ETH");
        payable(address(this)).transfer(msg.value);
    }

    function withdraw() public payable onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Getter Functions
    function getBalance() public returns (uint256) {
        contractBalance = address(this).balance;
        return contractBalance;
    }
}