// SPDX // SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Errors
error Pool__NotOwner();
error Pool__NotEnoughEth();

contract Pool {
    // State variables
    uint256 private immutable i_purchasePrice;
    address payable public i_owner;

    // Events

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Pool__NotOwner();
        _;
    }

    // Constructor (initializing contract)
    constructor(uint256 purchasePrice) {
        i_owner = payable(msg.sender);
        i_purchasePrice = purchasePrice;
    }

    fallback() external payable {
        makePurchase();
    }

    receive() external payable {
        makePurchase();
    }

    // Functions
    // Makes purchase of 1ETH
    function makePurchase() public payable {
        (bool callSuccess, ) = payable(address(this)).call{value: msg.value}(
            ""
        );
        require(callSuccess, "Purchase failed");
    }

    function withdraw() public payable onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Getter Functions
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPurchasePrice() public view returns (uint256) {
        return i_purchasePrice;
    }
}