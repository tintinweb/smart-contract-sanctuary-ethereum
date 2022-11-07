/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract escrow {
    address payable public buyer;
    address payable public seller;
    address public arbiter;
    mapping(address=>uint) deposits;

    enum State {
        AWAITING_PAYMENT,AWAITING_DELIVERY,COMPLETE
    }
    //Declaring the object of the enumerator
    State public state;

    // Defining function modifier instate
    modifier instate(State expected_state){
        require(state == expected_state);
        _;
    }

    modifier onlyBuyer(){
        require(msg.sender == buyer || msg.sender == arbiter);
        _;
    }

    modifier onlySeller(){
        require(msg.sender == seller);
        _;
    }

    constructor(address payable _buyer, address payable _seller) {
        arbiter = msg.sender;
        buyer = _buyer;
        seller = _seller;
        state = State.AWAITING_PAYMENT;
    }

    function deposit() onlyBuyer instate(State.AWAITING_PAYMENT) public payable{
        uint256 amount = msg.value;
        state = State.AWAITING_DELIVERY;
        deposits[seller] = deposits[seller]+amount;
    }


    function confirm_Delivery() onlyBuyer instate(State.AWAITING_DELIVERY) public{
        // seller.transfer(address(this).balance);
        state = State.COMPLETE;
        uint256 payment = deposits[seller];
        deposits[seller] = 0;
        seller.transfer(payment);
    }
}