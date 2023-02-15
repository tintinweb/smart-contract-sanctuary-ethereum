/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChainEscrow {
    
    address payable public buyer;
    address payable public seller;
    address public arbitrator;
    
    uint public price;
    bool public buyerApproved;
    bool public sellerApproved;
    
    enum State {
        Created,
        Funded,
        Completed,
        Disputed,
        Resolved
    }
    
    State public currentState;
    
    constructor(address payable _buyer, address payable _seller, address _arbitrator, uint _price) {
        require(_buyer != address(0), "Invalid buyer address");
        require(_seller != address(0), "Invalid seller address");
        require(_arbitrator != address(0), "Invalid arbitrator address");
        require(_price > 0, "Price must be greater than zero");
        
        buyer = _buyer;
        seller = _seller;
        arbitrator = _arbitrator;
        price = _price;
        currentState = State.Created;
    }
    
    function fund() public payable {
        require(msg.sender == buyer, "Only buyer can fund the escrow");
        require(msg.value == price, "Amount sent must be equal to price");
        require(currentState == State.Created, "Escrow must be in Created state");
        
        currentState = State.Funded;
    }
    
    function approve() public {
        require(currentState == State.Funded, "Escrow must be in Funded state");
        
        if (msg.sender == buyer) {
            require(!buyerApproved, "Buyer has already approved the transaction");
            buyerApproved = true;
        } else if (msg.sender == seller) {
            require(!sellerApproved, "Seller has already approved the transaction");
            sellerApproved = true;
        }
        
        if (buyerApproved && sellerApproved) {
            seller.transfer(price);
            currentState = State.Completed;
        }
    }
    
    function dispute() public {
        require(currentState == State.Funded, "Escrow must be in Funded state");
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can initiate dispute");
        
        currentState = State.Disputed;
    }
    
    function resolve() public {
        require(currentState == State.Disputed, "Escrow must be in Disputed state");
        require(msg.sender == arbitrator, "Only arbitrator can resolve the dispute");
        
        if (buyerApproved) {
            buyer.transfer(price);
        } else if (sellerApproved) {
            seller.transfer(price);
        }
        
        currentState = State.Resolved;
    }
    
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
}