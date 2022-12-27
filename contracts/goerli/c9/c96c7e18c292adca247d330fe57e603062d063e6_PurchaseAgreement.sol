/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PurchaseAgreement {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State{
        Created,
        Locked,
        Release,
        Inactive}
    State public state;
    
    constructor() payable {
        seller = payable(msg.sender); // sender is deloper
        value = msg.value / 2;
    }
    
    /// The function cannot be called at the current state.
    error InvalidState();
    /// Only the buyer can call this function
    error OnlyBuyer();
    /// Only the seller can call this function
    error OnlySeller();

    modifier inState(State state_) {
        if(state != state_) {
            revert InvalidState();
        }
        _;
    }

    modifier onlyBuyer(){
        if(msg.sender != buyer){
            revert OnlyBuyer();
        }
        _;
    }

    modifier onlySeller(){
        if(msg.sender != seller){
            revert OnlySeller();
        }
        _;
    }

    function confirmPurchase() external inState(State.Created) payable{ // receive money
        require(msg.value == (2 * value), "Please send in 2x the purchase amount"); // error message
        buyer = payable(msg.sender); // sender is buyer
        state = State.Locked;
    }

    function confirmReceived() external onlyBuyer() inState(State.Locked) { // send money
        state = State.Release;
        buyer.transfer(value); // return to buyer
    }

    function paySeller() external onlySeller() inState(State.Release){
        state = State.Inactive;
        seller.transfer(3 * value);
    }

    function abort() external onlySeller inState(State.Created){ // abort transaction before buyer purchase
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }
}