/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ESCROW {

    //Enum that Gives the Status of the escrow Order ( it represents in 1 , 2 , 2 )
    enum Status { ORDER_NOT_INITIATED , AWAITING_FOR_PAYMENT , AWAITING_FOR_DELIVERY , ORDER_MARK_COMPLETE }

    Status public currentStatus;   //Variable for enum

    uint private a;

    bool public isBuyerAccept;  //State of Accepting the order (both agree to start the order)
    bool public isSellerAccept;

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
    modifier OrderNotStarted() {
        require(currentStatus == Status.ORDER_NOT_INITIATED);
        _;
    }

    //constructor to set the buyer and seller address also the price of order
    constructor(address _buyer, address _seller, uint _price) {
        buyer = _buyer;
        seller = payable(_seller);
        price = _price;
    }

    //init contract function start the escrow order, once both buyer and seller start it
    function initContract() OrderNotStarted() public {
        if(msg.sender == buyer) {
            isBuyerAccept = true;
        }
        if(msg.sender == seller) {
            isSellerAccept = true;
        }
        if(isBuyerAccept == isSellerAccept) {
            currentStatus = Status.AWAITING_FOR_PAYMENT;
        }
    }

    //buyer needs to deposit the funds in order to start the escrow
    function StartOrder() onlyBuyer public payable {
        require(currentStatus == Status.AWAITING_FOR_PAYMENT,"Already Paid!");
        require(msg.value == price,"Wrong Deposit Amount!");
        currentStatus = Status.AWAITING_FOR_DELIVERY;
    }

    //buyer needs to confirm the delivery to transfer the funds
    function confirmDelivery() onlyBuyer public {
        require(currentStatus == Status.AWAITING_FOR_DELIVERY,"Waiting for Seller To Deliver the Order!!");
        seller.transfer(price);
        currentStatus = Status.ORDER_MARK_COMPLETE;
    }

    //buyer can withdraw funds in order to cancel the order and withdraw their funds
    function cancelOrder() onlyBuyer public { 
        require(currentStatus == Status.AWAITING_FOR_DELIVERY,"Order is Already in Delivery Phase Cannot Withdraw Now!!");
        payable(buyer).transfer(price);
        currentStatus = Status.ORDER_MARK_COMPLETE;
    }


}