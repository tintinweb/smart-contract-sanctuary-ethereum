// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForwardPayment {
    address payable public recipient;

    constructor(address payable _recipient) {
        require(_recipient != address(0), "Invalid recipient address");
        recipient = _recipient;
    }

    function sendPayment(string calldata a, string calldata b, string calldata c) external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "Payment forwarding failed");

    }
}