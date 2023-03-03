/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Escrow {
	address public arbiter;
	address payable public beneficiary;
	address public depositor;
	bool public isApproved;

	event Approved(uint balance);

	constructor(address _arbiter, address payable _beneficiary) payable {
		arbiter = _arbiter;
		beneficiary = _beneficiary;
		depositor = msg.sender;
	}
	function approve() external {
		require(arbiter == msg.sender, "Not Allowed");
		uint balance = address(this).balance;
		(bool sent, ) = beneficiary.call{ value: balance }("");
		require(sent, "Failed to send Ether");
		emit Approved(balance);
		isApproved = true;
		
	}

}