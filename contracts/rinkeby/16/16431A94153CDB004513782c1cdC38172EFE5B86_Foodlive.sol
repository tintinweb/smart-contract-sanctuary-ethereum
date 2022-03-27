//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Foodlive {
    event PaymentOrder(uint256, uint256);

    function paymentOrder(uint256 _orderId) public payable {
        emit PaymentOrder(_orderId, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}