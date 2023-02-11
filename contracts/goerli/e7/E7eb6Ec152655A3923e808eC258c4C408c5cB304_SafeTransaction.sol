// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract SafeTransaction{
    address payable public seller;
    address payable public buyer;
    uint public price;

    enum Status {
        Created,
        Locked, 
        Release,
        Inactive
    }

    Status public status;

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    modifier onlyBuyer {
        require(msg.sender == buyer, "You are not buyer");
        _;
    }

    modifier onlySeller {
        require(msg.sender == seller, "You are not seller");
        _;
    }

    modifier inStatus(Status _status) {
        require(status == _status, "Invalid state");
        _;
    }

    constructor () payable
    {
        seller = payable(msg.sender);
        price = msg.value / 2;
    }

    function confirmPurchase() external payable inStatus(Status.Created) {
        require(msg.value == 2 * price, "Pending don't x2 price");
        buyer = payable(msg.sender);
        status = Status.Locked;
    }

    function comfirmRecieved() external inStatus(Status.Locked) onlyBuyer {
        status = Status.Release;
        buyer.transfer(price);
    }

    function paySeller() external  onlySeller inStatus(Status.Release) {
        status = Status.Inactive;
        seller.transfer(3 * price);
    }

    function abort() external onlySeller inStatus(Status.Created) {
        status = Status.Inactive;
        seller.transfer(address(this).balance); 
    }
}