// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ProductTrade {
    address public owner;
    address public buyer;
    string public productName;
    uint256 public productPrice;
    uint256 public contractBalance;

    constructor(string memory _productName, uint256 _productPrice) {
        productName = _productName;
        productPrice = _productPrice;
        owner = msg.sender;
    }

    function buyProduct() public payable {
        require(
            msg.value == productPrice,
            "Transaction value does not equal price of product."
        ); // Ensure that the buyer does not purchase the product for the wrong price.
        buyer = msg.sender;
        contractBalance += msg.value;
    }

    function approveReception() private view returns (bool) {
        require(
            msg.sender == owner,
            "Only the buyer can approve the reception of the product."
        );
        return true; // !!! REMEMBER TO CHANGE THIS VALUE ACCORDINGLY !!!
    }

    function approveReturn() private view returns (bool) {
        require(
            msg.sender == buyer,
            "Only the seller can approve the return of the product."
        );
        return true; // !!! REMEMBER TO CHANGE THIS VALUE ACCORDINGLY !!!
    }

    function withdraw() private view returns (bool) {}
}