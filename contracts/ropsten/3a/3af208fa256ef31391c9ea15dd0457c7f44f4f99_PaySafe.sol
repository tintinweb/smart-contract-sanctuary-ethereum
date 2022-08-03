// SPDX-License-Identifier: MIT
// gabl22 @ github.com

// PaySafe 0x01 03.08.2022

pragma solidity >=0.8.0 <0.9.0;

import "./UncheckedCounter.sol";
import "./CashFlow.sol";

contract PaySafe is CashFlow
(
    CashFlow.Config({
        publicDonations: true,
        publicCharging: false
    })
)
{

    enum PaymentState {
        INDEXED,
        REVOKED,
        PENDING,
        PAID
    }

    struct Payment {
        PaymentState state;
        address from;
        address to;
        uint amount;
        uint bail;
    }

    using UncheckedCounter for UncheckedCounter.Counter;
    UncheckedCounter.Counter private idCounter;

    mapping(uint => Payment) public payments;

    constructor() {

    }

    function createPayment(address to, uint amount, uint bail) public payable cashFlow returns(uint) {
        require(msg.value >= (amount + bail), "Error: Insufficient funds deposited (needs amout + bail)");
        require(msg.sender != to, "Error: You cannot send yourself money");
        uint id = idCounter.current();
        payments[id] = Payment({
            state: PaymentState.INDEXED,
            from: msg.sender,
            to: to,
            amount: amount,
            bail: bail
        });
        idCounter.increment();
        payable(address(tx.origin)).transfer(msg.value - (amount + bail));
        return id;
    }

    function deposit(uint id) public payable cashFlow returns(Payment memory) {
        require(msg.sender == payments[id].to, "Error: No deposit accepted here");
        require(payments[id].state == PaymentState.INDEXED, "Error: You already paid or this payment got revoked");
        require(msg.value >= payments[id].bail, "Error: Insufficient funds deposited");
        Payment memory payment = payments[id];
        payment.state = PaymentState.PENDING;
        payable(address(tx.origin)).transfer(msg.value - payments[id].bail);
        payments[id] = payment;
        return payment;
    }

    function revoke(uint id) public returns(Payment memory) {
        Payment memory payment = payments[id];
        require(msg.sender == payment.from || msg.sender == payment.to, "Error: You are not a part of this payment");
        require(payment.state == PaymentState.INDEXED || payment.state == PaymentState.PENDING, "Error: Payment already completed/revoked");
        if (msg.sender == payment.from) {
            require(payment.state == PaymentState.INDEXED, "Error: Payment in process");
            payment.state = PaymentState.REVOKED;
            payable(address(payment.from)).transfer(payment.amount + payment.bail);
        } else if (msg.sender == payment.to) {
            if(payment.state == PaymentState.PENDING) {
                payable(address(payment.to)).transfer(payment.bail);
            }
            payment.state = PaymentState.REVOKED;
            payable(address(payment.from)).transfer(payment.amount + payment.bail);
        }
        payments[id] = payment;
        return payment;
    }

    function confirm(uint id) public returns(Payment memory) {
        Payment memory payment = payments[id];
        require(msg.sender == payment.from, "Error: You can't confirm this payment");
        require(payment.state == PaymentState.PENDING, "Error: This Payment is not confirmable.");
        payment.state = PaymentState.PAID;
        payable(address(payment.from)).transfer(payments[id].bail);
        payable(address(payment.to)).transfer(payments[id].bail + payments[id].amount);
        payments[id] = payment;
        return payments[id];
    }

    function getPayment(uint id) external view returns(Payment memory) {
        return payments[id];
    }

    function lastID() external view returns(uint) {
        return idCounter.current() - 1;
    }
}