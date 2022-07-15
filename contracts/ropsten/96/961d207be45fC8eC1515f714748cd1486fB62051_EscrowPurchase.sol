/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

contract EscrowPurchase{
    address payable public buyer;
    address payable public seller;
    uint value;

    enum State {Created, Locked, Released, Expired}

    State public state;

    /// Value should be even to make it simple
    error NotEven();
    /// Only buyer can call this function
    error OnlyBuyer();
    /// Only seller can call this function
    error OnlySeller();
    /// State is incorrect
    error NotInCorrectState();

    event Purchased();
    event Received();
    event RefundedToSeller();
    event Aborted();

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

    modifier condition(bool _condition){
        require(_condition);
        _;
    }

    modifier inState(State _state){
        if(state != _state){
            revert NotInCorrectState();
        }
        _;
    }

    constructor() payable{
        seller = payable(msg.sender);
        value = msg.value / 2;
        if(2 * value != msg.value){
            revert NotEven();
        }
    }

    function confirmPurchase() external condition(msg.value == (2 * value)) inState(State.Created) payable{
        buyer = payable(msg.sender);
        state = State.Locked;
        emit Purchased();
    }

    function confirmReceived() external onlyBuyer inState(State.Locked){
        state = State.Released;
        buyer.transfer(value);
        emit Received();
    }

    function refundSeller() external onlySeller inState(State.Released){
        state = State.Expired;
        seller.transfer(3 * value);
        emit RefundedToSeller();
    }

    function abort() external onlySeller inState(State.Created){
        state = State.Expired;
        seller.transfer(address(this).balance);
        emit Aborted();
    }

}