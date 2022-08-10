/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Escrow {
    // state machine in order to follow specific excution order
    enum State {AWAITING_PAYMENT, AWATING_DELIVERY, COMPLETE}
    State public currentState;

    address payable seller;
    address public buyer;

    // defining modifiers for requirements
    modifier buyerOnly() { require(msg.sender == buyer); _; }
    modifier inState(State state) { require(currentState == state); _; }

    constructor(address payable _seller, address _buyer) {
        seller = _seller; 
        buyer = _buyer;

    }

    // Two contracts
    function confirmPayment() buyerOnly inState(State.AWAITING_PAYMENT) public payable {
        currentState = State.AWATING_DELIVERY;
    }

    function confirmDelivery() buyerOnly inState(State.AWATING_DELIVERY) public payable {
        seller.transfer(address(this).balance);
        currentState = State.COMPLETE;
    }

}