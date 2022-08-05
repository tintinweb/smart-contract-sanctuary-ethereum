/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract escrowSystem {

    //Enum that Gives the Status of the escrow Order ( it represents in 1 , 2 , 2 )
    enum State { NOT_INITIATED , AWAITING_PAYMENT , AWAITING_DELIVERY , COMPLETE }

    State public currentStatus;   //Variable for enum

    bool public isBuyerIn;  //State of Accepting the order (both agree to start the order)
    bool public isSellerIn;

    uint public price;   //price of the work

    address public buyer;   //address of buyer
    address payable public seller;  //address of seller


    //modifier that check the condition to call the function, only buyer can call the function 
    //attached with onlyBuyer modifier
    modifier onlyBuyer() {
        require(msg.sender == buyer,"Caller Must be Buyer!");
        _;
    }

    //check if the escrow started or not
    modifier escrowNotStarted() {
        require(currentStatus == State.NOT_INITIATED);
        _;
    }

    //constructor to set the buyer and seller address also the price of order
    constructor(address _buyer, address _seller, uint _price) {
        buyer = _buyer;
        seller = payable(_seller);
        price = _price;
    }

    //init contract function start the escrow order, once both buyer and seller start it
    function initContract() escrowNotStarted() public {
        if(msg.sender == buyer) {
            isBuyerIn = true;
        }
        if(msg.sender == seller) {
            isSellerIn = true;
        }
        if(isBuyerIn == isSellerIn) {
            currentStatus = State.AWAITING_PAYMENT;
        }
    }

    //buyer needs to deposit the funds in order to start the escrow
    function deposit() onlyBuyer public payable {
        require(currentStatus == State.AWAITING_PAYMENT,"Already Paid!");
        require(msg.value == price,"Wrong Deposit Amount!");
        currentStatus = State.AWAITING_DELIVERY;
    }

    //buyer needs to confirm the delivery to transfer the funds
    function confirmDelivery() onlyBuyer public {
        require(currentStatus == State.AWAITING_DELIVERY,"Waiting for Seller To Deliver the Order!!");
        seller.transfer(price);
        currentStatus = State.COMPLETE;
    }

    //buyer can withdraw funds in order to cancel the order and withdraw their funds
    function withdraw() onlyBuyer public { 
        require(currentStatus == State.AWAITING_DELIVERY,"Order is Already in Delivery Phase Cannot Withdraw Now!!");
        payable(seller).transfer(price);
        currentStatus = State.COMPLETE;
    }


}