// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Payments {
    address public owner;

    struct Payment {
        uint amount;
        uint timestamp;
    }

    mapping(address => Payment[]) payments;

    event PaymentEvent(address indexed payer, uint amount, uint timestamp);

    event Withdrawal(uint amount, uint timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        payments[msg.sender].push(Payment({
        amount : msg.value,
        timestamp : block.timestamp
        }));
        emit PaymentEvent(msg.sender, msg.value, block.timestamp);
    }

    function getPayments(address payer) public view returns (Payment[] memory) {
        return payments[payer];
    }

    function withdraw() external onlyOwner() {
        uint amount = address(this).balance;
        (bool success,) = msg.sender.call{value : amount}("");
        emit Withdrawal(amount, block.timestamp);
        require(success, "Transfer failed");
    }
}