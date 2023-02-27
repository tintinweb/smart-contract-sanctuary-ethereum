/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Escrow {
	address public arbiter;
	address public beneficiary;
	address public depositor;
	uint public escrowEndTime;
	bool public isApproved;
	event Approved(uint);
	event TimerEnded(address, uint);

	constructor(address _arbiter, address _beneficiary, uint _approvalTime) payable {
		arbiter = _arbiter;
		beneficiary = _beneficiary;
		depositor = msg.sender;
		escrowEndTime = block.timestamp + _approvalTime;
	}

	function approve() external {
		require(msg.sender == arbiter);
		require(escrowEndTime < block.timestamp);
		uint balance = address(this).balance;
		(bool sent, ) = payable(beneficiary).call{value: balance}("");
 		require(sent, "Failed to send Ether");
		emit Approved(balance);
		isApproved = true;
	}

	function endTimedEscrow() public {
		require(block.timestamp >= escrowEndTime, "Time still left to approve escrow");
		require(msg.sender == depositor, "Caller is not depositor");
		selfdestruct(payable(depositor));
		emit TimerEnded(depositor, escrowEndTime);
	}
}