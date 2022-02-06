// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract ExSafePurchase {
    uint256 public cost;
    address payable public seller;
    address payable public buyer;

    enum State {Created, Locked, Released, Inactive}
    State public postate;


    error CostNotEven();
    error OnlySeller();
    error OnlyBuyer();
    error InvalidState();
    error NotEnoughPayment();

    modifier onlySeller(){
        if( msg.sender != seller){
            revert OnlySeller();
        }
        _;
    }

    modifier onlyBuyer() {
        if( msg.sender != buyer){
            revert OnlyBuyer();
        }
        _;
    }

    modifier enoughMoney( uint256 payment){
        if( payment < cost * 2){
            revert NotEnoughPayment();
        }
        _;
    }

    modifier checkState( State expectedState){
        if( postate != expectedState){
            revert InvalidState();
        }
        _;
    }

    event Aborted();
    event Locked();
    event Released();
    event PaymentDone();
    

    // send initial cost
    constructor() payable {
        seller = payable(msg.sender);
                
        cost = msg.value / 2;
        if( 2 * cost != msg.value)
            revert CostNotEven();

        postate = State.Created;    
    }


    function abort( ) external onlySeller() checkState(State.Created){        
        postate = State.Inactive;
        seller.transfer( address(this).balance);
        emit Aborted();
    }

    function confirmPurchase() external payable enoughMoney(msg.value) checkState(State.Created){
        buyer = payable(msg.sender);
        postate = State.Locked;
        emit Locked();
    }

    function confirmDelivered() external onlyBuyer() checkState(State.Locked){
        postate = State.Released;
        buyer.transfer(cost);
        emit Released();
    }

    function paySeller() external onlySeller() checkState(State.Released){
        postate = State.Inactive;
        seller.transfer( cost * 3);        
        emit PaymentDone();        
    }


}