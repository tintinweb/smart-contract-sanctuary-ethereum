// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Escrow {
 
	enum State {Not_INITIATED,AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE}

		// #VARIABLES
		State public currentState;

		bool public isBuyerIn;
		bool public isSellerIn;
		uint256 public price;

		address public buyer;
		address payable public seller;

	// #MODIFIERS


		modifier buyerOnly() {
			require(msg.sender == buyer,"only buyer can call this function"); 
			_;
			}
		modifier escrowNotStarted() {
			require(currentState == State.Not_INITIATED);
			_;
			}
	

		constructor (address _buyer, address payable _seller, uint256 _price) {

			buyer = _buyer;
			seller = _seller;
			price = _price *(1 ether);

		}


	function initcontract() escrowNotStarted public {
		if(msg.sender == buyer){
			isBuyerIn = true;
		}
		if(msg.sender == seller){
			isSellerIn = true;
		}
		if(isBuyerIn && isSellerIn){
			currentState = State.AWAITING_PAYMENT;

		}

	}

	function deposit() buyerOnly public payable{
		require(currentState == State.AWAITING_PAYMENT,"Payment already paid");
		require(msg.value == price,"Wrong Deposit Amount");
		currentState = State.AWAITING_DELIVERY;
	}

	function confirmDelvery() buyerOnly payable public {
		require(currentState == State.AWAITING_DELIVERY,"can't confirm delvery");
		seller.transfer(price);
		currentState = State.COMPLETE;

}
	function withdraw() buyerOnly payable public {
	require(currentState == State.AWAITING_DELIVERY,"can't withdraw at this stage");
	payable(msg.sender).transfer(price);
	currentState = State.COMPLETE;

	}


}