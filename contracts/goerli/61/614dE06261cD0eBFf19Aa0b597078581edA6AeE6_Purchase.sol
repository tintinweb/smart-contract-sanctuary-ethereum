/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract Purchase {
    uint256 public price;
    address payable public seller;
    address payable public buyer;


    enum State { Created, Locked, Release, Inactive }
    State public state;

    constructor() payable {
        seller = payable(msg.sender);
        price = msg.value / 2;
    }

    /// The function cannot be called at the current state.
    error InvalidState();

    /// Only the buyer can call this function.
    error OnlyBuyer();

    /// Only the seller can call this function.
    error OnlySeller();



    modifier inState(State state_) {
        if (state != state_) revert InvalidState();
        _;
    }

    modifier onlyBuyer() {
        if (msg.sender != buyer) revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller) revert OnlySeller();
        _;
    }


    function confirmPurchase() external inState(State.Created) payable {
        require(msg.value == (2 * price), "Please send in 2x the purchase amount.");
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    function confirmReceived() external onlyBuyer inState(State.Locked) {
        state = State.Release;
        buyer.transfer(price);
        
    }

    function paySeller() external onlySeller inState(State.Release) {
        state = State.Inactive;
        seller.transfer(3 * price);
    }

    function abort() external onlySeller inState(State.Created) {
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

   

    receive() external payable {}
}