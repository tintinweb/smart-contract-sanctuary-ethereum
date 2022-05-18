/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Escrow {

    //VARIABLES
    enum State { NOT_INITIATED, AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }

    State public currentState;

    bool public isBuyerIn;
    bool public isSellerIn;

    uint public price;

    address public buyer;
    address payable public seller;


    //MODIFIERS
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier escrowNotStarted() {
        require(currentState == State.NOT_INITIATED);
        _;
    }

    //FUNCTIONS
    constructor(address _buyer, address payable _seller, uint _price) {
        buyer = _buyer;
        seller = _seller;
        price = _price * (1 ether);
    }

    function initContract() escrowNotStarted public{
        if(msg.sender == buyer) {
            isBuyerIn = true;
        }
        if(msg.sender == seller) {
            isSellerIn = true;
        }
        if (isBuyerIn && isSellerIn) {
            currentState = State.AWAITING_PAYMENT;
        }
    }

    function deposit() onlyBuyer public payable{
        require(currentState == State.AWAITING_PAYMENT, "Already paid!");
        require(msg.value == price, "Wrong deposit amount!");
        currentState = State.AWAITING_DELIVERY;
    }

    function confirmDelivery() onlyBuyer payable public{
        require(currentState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        seller.transfer(price);
        currentState = State.COMPLETE;

    }

    function withdraw() onlyBuyer payable public{
        require(currentState == State.AWAITING_DELIVERY, "Cannot Withdraw at this stage");
        payable(msg.sender).transfer(price);
        currentState = State.COMPLETE;

    }

}