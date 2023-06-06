// SPDX-License-Identifier: UNLICENSED

// Audited by ZachXBT

pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./Math.sol";

contract NetworkController is Ownable {
	struct BulkWithdraw {
		address destination;
		uint256 amount;
	}

	// Current sending mode
	bool public forwarding;

	// Receives donations when mode == Forwarding
	address public beneficiary;

	// Mapping of people who are approved to withdraw
	mapping(address => bool) withdrawApprovals;

	constructor(address _beneficiary, bool _forwarding) {
		forwarding = _forwarding;
		beneficiary = _beneficiary;
	}

	/*
	 * @dev Checks if a user is allowed to withdraw
	 */
	modifier allowedToWithdraw() {
		require(
			msg.sender == owner() || withdrawApprovals[msg.sender],
			"WITHDRAW APPROVED ONLY!"
		);
		_;
	}

	/*
	 * @dev Changes between Holding and Forwarding mode
	 */
	function setForwarding(bool _forwarding) external onlyOwner {
		require(_forwarding != forwarding, "SAME MODE!");

		forwarding = _forwarding;
	}

	/*
	 * @dev Sets the beneficiary for Forward mode
	 */
	function setBeneficiary(address newBeneficiary) external onlyOwner {
		beneficiary = newBeneficiary;
	}

	/*
	 * @dev Approves or revokes permissions to call withdraw functions
	 */
	function approveWithdraw(address member, bool allowed) external onlyOwner {
		withdrawApprovals[member] = allowed;
	}

	/*
	 * @dev Takes in multiple withdraw calls
	 */
	function withdrawToBulk(
		BulkWithdraw[] calldata withdraws
	) external allowedToWithdraw {
		for (uint8 i = 0; i < withdraws.length; ++i) {
			(bool sent, ) = withdraws[i].destination.call{
				value: withdraws[i].amount
			}("");

			require(sent, "FAILURE");
		}
	}

	/*
	 * @dev Withdraws to a specific destination
	 */
	function withdrawTo(
		address destination,
		uint256 amount
	) external allowedToWithdraw {
		uint256 amountToWithdraw = Math.min(amount, address(this).balance);

		(bool sent, ) = destination.call{value: amountToWithdraw}("");
		require(sent, "FAILURE");
	}

	/*
	 * @dev Withdraws total balance to approved caller
	 */
	function withdraw() external allowedToWithdraw {
		(bool sent, ) = msg.sender.call{value: address(this).balance}("");
		require(sent, "FAILURE");
	}

	/*
	 * @dev Called upon recieving ETH
	 */
	function _mergeAction() internal {
		if (forwarding) {
			(bool sent, ) = beneficiary.call{value: msg.value}("");
			require(sent, "FAILURE");
		}
	}

	/*
	 * @dev Called on ETH sends with data
	 */
	fallback() external payable {
		_mergeAction();
	}

	/*
	 * @dev Called on ETH sends with no data
	 */
	receive() external payable {
		_mergeAction();
	}
}