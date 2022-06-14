// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ProductTrade {
    address public owner;
    address public buyer;
    string public productName;
    uint256 public productPrice;
    uint256 public contractBalance;
    bool public receptionApproved;
    bool public returnApproved;

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

    function approveReception() public returns (bool) {
        require(
            msg.sender == buyer,
            "Only the buyer can approve the reception of the product."
        );
        receptionApproved = true;
        return receptionApproved;
    }

    function approveReturn() public returns (bool) {
        require(
            msg.sender == owner,
            "Only the seller can approve the return of the product."
        );
        returnApproved = true;
        return returnApproved;
    }

    function withdraw() public returns (bool) {
        if (returnApproved && msg.sender == buyer) {
            payable(msg.sender).transfer(address(this).balance);
            contractBalance = 0;
            return true;
        } else if (receptionApproved && msg.sender == owner) {
            payable(msg.sender).transfer(address(this).balance);
            contractBalance = 0;
            return true;
        }
        return false;
    }
}