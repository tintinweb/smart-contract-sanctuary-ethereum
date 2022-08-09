/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

//SPDX-License-Identifier: MIT
pragma solidity^0.8.7;


contract Erscrow{

    enum state{Not_inititated, Awaiting_payment, Awaiting_delivery, Complete}
    state public Curstate;
    bool public isByuerIn;
    bool public IsSellerin;
    uint256 public price;

    address public buyer;
    address payable public seller;

    modifier onlybuyer() {
        require(msg.sender == buyer,"Only buyer can call this function");
        _;
    }
    modifier escrowNotstarted() {
        require(Curstate == state.Not_inititated);
        _;
    }

    constructor(address _buyer, address payable _seller, uint _price) {
        buyer = _buyer;
        seller = _seller;
        price = _price * 1 ether;
     
    }

    function initContract() escrowNotstarted public{
        if(msg.sender == buyer){
            isByuerIn = true ;
        }
        if(msg.sender == seller) {
            IsSellerin = true ;
        }
        if(isByuerIn && isByuerIn) {
            Curstate = state.Awaiting_payment;
        }

    }

    function deposit() onlybuyer public payable {
        require(Curstate == state.Awaiting_payment, "Already paid");
        require(msg.value == price, "Wrong deposit amount");
        Curstate = state.Awaiting_delivery;
        
    }

    function confirmDelivery() onlybuyer payable public{
        require(Curstate == state.Awaiting_delivery, "Cannot confirm delivery");
        seller.transfer(price);
        Curstate = state.Complete;
    }

    function Withdraw() onlybuyer payable public {
        require(Curstate == state.Awaiting_delivery, "Cannot withdraw at this stage");
        payable(msg.sender).transfer(price);
        Curstate = state.Complete; 
        
    }

}