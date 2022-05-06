/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PurchaseAgreement {
    event ContractDeployed(address indexed Deployer, uint indexed Value);
    event OrderCancelled(address indexed Canceller, uint indexed Timestamp);
    event OrderConfirmed(address indexed Buyer, uint indexed PriceSent);
    event ProductReceived(uint blockTimeStamp);

    uint public price;
    address payable public seller;
    address payable public buyer;

    enum TradeState {Created, Locked, Received, Inactive}
    TradeState public Trade;

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only Buyer can call this method");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only Seller can call this method");
        _;
    }

    modifier inState(TradeState _trade) {
        require(Trade == _trade, "Inappropirate State");
        _;
    }

    constructor() payable {
        seller = payable(msg.sender);
        price = msg.value / 2;
        Trade = TradeState.Created;
        emit ContractDeployed(seller, price);
    }

    function confirmOrder() external inState(TradeState.Created) payable {
        require(msg.value >= 2 * price, "Please send twice the amount of the product's price");
        buyer = payable(msg.sender);
        Trade = TradeState.Locked;
        emit OrderConfirmed(buyer, msg.value / 2);
    }

    function confirmReceived() external onlyBuyer inState(TradeState.Locked) {
        Trade = TradeState.Received;
        buyer.transfer(price);
        emit ProductReceived(block.timestamp);
    }

    function ReleaseFunds() external onlySeller inState(TradeState.Received) returns (uint) {
        Trade = TradeState.Inactive;
        seller.transfer(3 * price);
        return seller.balance;
    }

    function cancelOrder() external onlySeller inState(TradeState.Created) {
        Trade = TradeState.Inactive;
        seller.transfer(address(this).balance);
        emit OrderCancelled(seller, block.timestamp);
    }

 }