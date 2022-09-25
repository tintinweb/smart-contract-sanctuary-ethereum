/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
  uint public value;
  address payable public seller;
  address payable public buyer;
  enum State{Created , Locked, Released, Inactive}
  State public state;

  constructor () payable {
      seller = payable(msg.sender); 
      value = msg.value/2;
  }

 /// The function can't be called
  error InvalidState();

   /// Only Buyer can call the function
  error OnlyBuyer();

   /// Only Seller can call the function
  error OnlySeller();

  modifier inState(State  state_){
      if(state != state_)
      {
          revert InvalidState();
      }
      _;
  }
   modifier onlyBuyer(){
      if(msg.sender != buyer)
      {
          revert OnlyBuyer();
      }
      _;
  }
     modifier onlySeller(){
      if(msg.sender != seller)
      {
          revert OnlySeller();
      }
      _;
  }

  function confirmPurchase() external inState(State.Created) payable {
      require(msg.value == (2 * value), "Insufficient Balance");
      buyer = payable(msg.sender);
      state = State.Locked;

  }
    function confirmReceived() external onlyBuyer inState(State.Locked) {      
        state = State.Released;
        buyer.transfer(value);
    }

    function paySeller() external onlySeller inState(State.Released) {
    state = State.Inactive;
    seller.transfer(3 * value);
    }

    function abort () external onlySeller inState(State.Created){
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }
}