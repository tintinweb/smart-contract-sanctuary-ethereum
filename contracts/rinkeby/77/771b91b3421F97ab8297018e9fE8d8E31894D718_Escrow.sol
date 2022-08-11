/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// File: hack/escrow_1.sol


// same as escrow.sol with native rinkeby tokens
// we are now transfering the balance

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

    // Two vaidation functions
    function confirmPayment() buyerOnly inState(State.AWAITING_PAYMENT) public payable {
        currentState = State.AWATING_DELIVERY;
    }

    function confirmDelivery() buyerOnly inState(State.AWATING_DELIVERY) public payable {
        seller.transfer(address(this).balance);
        currentState = State.COMPLETE;
    }

}

// testing with addresses:
// seller = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
// buyer = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2

// new seller: 0x60bc7228A90024Bb0D387eEc3b9761eE47dC4E2d
// new buyer: 0xcA43B69099C8875c6eb4aAa5a3d4Ec91B52a913c
// test rinjkeby: 0x0eaB1cd163C1CE45BC0077F8b3dc0009df4fF414
// test mumbai: 0xA476DE217824B00f6D25be70023675ee4D1478eB