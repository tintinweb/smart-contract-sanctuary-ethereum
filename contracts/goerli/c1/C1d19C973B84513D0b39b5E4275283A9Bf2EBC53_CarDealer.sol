// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CarDealer {
    address payable public carSeller;
    address payable public carBuyer;
    uint public carPrice;

    enum State {
        CREATED,
        LOCKED,
        RELEASED,
        CLOSED
    }

    State public state;

    constructor() payable {
        carSeller = payable(msg.sender);
        carPrice = msg.value / 3;
    }

    error OnlySeller();
    error OnlyBuyer();
    error InvalidState();

    modifier onlySeller() {
        if (msg.sender != carSeller) revert OnlySeller();
        _;
    }
    modifier onlyBuyer() {
        if (msg.sender != carBuyer) revert OnlyBuyer();
        _;
    }

    modifier correctState(State _state) {
        if (state != _state) revert InvalidState();
        _;
    }

    function purchase() external payable correctState(State.CREATED) {
        require(msg.value == carPrice, "Not Enough Wei");
        carBuyer = payable(msg.sender);
        state = State.LOCKED;
    }

    function confirmation() external onlyBuyer correctState(State.LOCKED) {
        state = State.RELEASED;
    }

    function refund() external onlySeller correctState(State.RELEASED) {
        state = State.CLOSED;
        carSeller.transfer(address(this).balance);
    }

    function suspend() external onlySeller correctState(State.CREATED) {
        state = State.CLOSED;
        carSeller.transfer(address(this).balance);
    }
}