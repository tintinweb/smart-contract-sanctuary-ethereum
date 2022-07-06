/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

contract Escrow {

    enum State {AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE}

    State public currentState;

    address public buyer;
    address payable seller;
  


  modifier buyerOnly() {
      require(msg.sender == buyer);
      _;
  }

  modifier inState(State expectedState) {
      require(currentState == expectedState);
      _;
  }

    constructor (address _buyer, address _seller) public  {
        buyer  =  _buyer;
        
        seller =  payable(_seller);
       
        
        
    }


    function confirmPayment()public buyerOnly inState(State.AWAITING_PAYMENT) payable {
       
   
        currentState = State.AWAITING_DELIVERY;
    }

    function confirmDelivery() buyerOnly inState(State.AWAITING_DELIVERY) public {
      
       
        seller.transfer(address(this).balance);
        currentState = State.COMPLETE;
        
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

}