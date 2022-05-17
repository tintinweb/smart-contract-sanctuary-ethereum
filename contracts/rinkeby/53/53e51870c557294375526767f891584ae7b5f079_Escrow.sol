/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    State public currState;
    address public seller;
    address payable public buyer;
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }
    // constructor(address _seller, address payable _buyer) {
    //     seller = _seller;
    //     buyer = _buyer;
    // }

     function getSeller_Buyer(address payable _buyer, address  _seller) public {
        buyer = _buyer;
        seller = _seller;
    }
    function deposit()  external payable {
       // require(currState == State.AWAITING_PAYMENT, "Already paid");
        currState = State.AWAITING_DELIVERY;
    }
    function confirmDelivery()  external {
      //  require(currState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        buyer.transfer(address(this).balance);
        currState = State.COMPLETE;
    }
}