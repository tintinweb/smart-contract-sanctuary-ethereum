/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

contract EscrowSystem{


    struct Escrow {
        address payable buyer;
        address payable seller;
        uint256 amount;
        bool buyerAgreed;
        bool sellerDelivered;
        bool resolved;
        bool disputed;
    } 
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public escrowCount;

    event EscrowCreated(uint256 escrowId, address buyer, address seller, uint256 amount);
    event SellerDelivered(uint256 escrowId, address seller);
    event BuyerAgreed(uint256 escrowId, address buyer);
    event DisputeResolved(uint256 escrowId, bool buyerWin);
    event BuyerDisputed(uint256 escrowId, address buyer);
    event SellerDisputed(uint256 escrowId, address seller);


    function createEscrow(address payable _seller) public payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(msg.sender != _seller, "Buyer and seller cannot be the same");
        escrowCount += 1;
        escrows[escrowCount] = Escrow(payable(msg.sender), _seller, msg.value, false, false, false, false);
        emit EscrowCreated(escrowCount, msg.sender, _seller, msg.value);
    }
    function sellerDelivered(uint256 _escrowId) public {
        require(msg.sender == escrows[_escrowId].seller, "Only the seller can deliver");
        require(escrows[_escrowId].sellerDelivered == false, "Seller has already delivered");
        escrows[_escrowId].sellerDelivered = true;
        emit SellerDelivered(_escrowId, escrows[_escrowId].seller);
    }
    function sellerDispute(uint256 _escrowId) public {
        require(msg.sender == escrows[_escrowId].seller, "Only the seller can dispute");
        require(escrows[_escrowId].sellerDelivered == true, "Seller has not delivered");
        require(escrows[_escrowId].buyerAgreed == false, "Buyer has already agreed");
        require(escrows[_escrowId].resolved == false, "Escrow has already been resolved");
        escrows[_escrowId].disputed = true;
        emit SellerDisputed(_escrowId, escrows[_escrowId].seller);
    }
    function buyerCancel(uint256 _escrowId) public {
        require(msg.sender == escrows[_escrowId].buyer, "Only the buyer can cancel");
        require(escrows[_escrowId].sellerDelivered == false, "Seller has already delivered");
        require(escrows[_escrowId].buyerAgreed == false, "Buyer has already agreed");
        require(escrows[_escrowId].resolved == false, "Escrow has already been resolved");
        escrows[_escrowId].buyer.transfer(escrows[_escrowId].amount);
        escrows[_escrowId].resolved = true;
        emit BuyerAgreed(_escrowId, escrows[_escrowId].buyer);
    }
    function buyerDispute(uint256 _escrowId) public {
        require(msg.sender == escrows[_escrowId].buyer, "Only the buyer can dispute");
        require(escrows[_escrowId].buyerAgreed == false, "Buyer has already agreed");
        require(escrows[_escrowId].sellerDelivered == true, "Seller has not delivered");
        require(escrows[_escrowId].resolved == false, "Escrow has already been resolved");
        escrows[_escrowId].disputed = true;
        emit BuyerDisputed(_escrowId, escrows[_escrowId].buyer);
    }
    function resolveDispute(uint256 _escrowId, bool _buyerWin) public {
        require(msg.sender == owner, "Only the owner can resolve");
        require(escrows[_escrowId].disputed == true, "Escrow is not disputed");
        require(escrows[_escrowId].resolved == false, "Escrow is already resolved");
        escrows[_escrowId].resolved = true;
        if (_buyerWin) {
            escrows[_escrowId].buyer.transfer(escrows[_escrowId].amount);
        } else {
            escrows[_escrowId].seller.transfer(escrows[_escrowId].amount);
        }
        emit DisputeResolved(_escrowId, _buyerWin);
    }
    function buyerAgree(uint256 _escrowId) public{
        require(msg.sender == escrows[_escrowId].buyer, "Only the buyer can agree");
        require(escrows[_escrowId].resolved == false, "Escrow is already resolved");
        require(escrows[_escrowId].sellerDelivered == true, "Seller has not delivered");
        require(escrows[_escrowId].buyerAgreed == false, "Buyer has already agreed");
        escrows[_escrowId].buyerAgreed = true;
        escrows[_escrowId].seller.transfer(escrows[_escrowId].amount);
        escrows[_escrowId].resolved = true;
        emit BuyerAgreed(_escrowId, escrows[_escrowId].buyer);
    }

    function getEscrow(uint256 _escrowId) public view returns(Escrow memory) {
        require(msg.sender == escrows[_escrowId].buyer || msg.sender == escrows[_escrowId].seller || msg.sender == owner, "Only the buyer or seller can view this escrow");
        return escrows[_escrowId];
    }
    function getDisputedEscrows() public view returns(Escrow[] memory) {
        Escrow[] memory disputedEscrows = new Escrow[](escrowCount);
        uint256 count = 0;
        for(uint256 i = 1; i <= escrowCount; i++) {
            if(escrows[i].disputed == true && escrows[i].resolved == false) {
                disputedEscrows[count] = escrows[i];
                count++;
            }
        }
        return disputedEscrows;
    }
}