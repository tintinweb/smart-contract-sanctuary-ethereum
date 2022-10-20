/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Kickstarter {
	uint public _requiredWeiToStartProject;
	address public immutable _projectAuthor;
	uint public immutable _minContributorWei;
	address[] public _contributors;
	ExpenseRequest[] public _expenseRequests;

	struct ExpenseRequest {
		string id;
		uint value;
		address payable to;
		address[] approvers;
		bool executed;
	}

	constructor(uint requiredWeiToStartProject, uint minContributorWei) {
		_projectAuthor = msg.sender;
        _requiredWeiToStartProject = requiredWeiToStartProject;
		_minContributorWei = minContributorWei;
	}

	receive() external payable {
		require(msg.sender != _projectAuthor);
		require(msg.value >= _minContributorWei);
		_contributors.push(msg.sender);
	}

	function createExpenseRequest (string calldata id, uint value, address payable to) external {
		require(msg.sender == _projectAuthor);
		require(to != _projectAuthor);
		require(address(this).balance >= _requiredWeiToStartProject);
		_expenseRequests.push(ExpenseRequest(
			id,
			value,
			to,
			new address[](0),
			false
		));
	}

	function approveExpenseRequest (string calldata id) external {
		require(msg.sender != _projectAuthor);
		ExpenseRequest storage req = getExpenseRequest(id);

		require(!isApproved(req.approvers, msg.sender));
		req.approvers.push(msg.sender);
	}

	function executeExpenseRequest(string calldata id) external {
		require(msg.sender == _projectAuthor);
		ExpenseRequest storage request = getExpenseRequest(id);

		require(request.executed == false);
		require(request.approvers.length > 0);
		require(request.approvers.length * 10 > _contributors.length * 10 / 2);	// Scale up fixed-point division
		request.to.transfer(request.value);
		request.executed = true;
	}

	function getBalance() external view returns(uint) {
		return address(this).balance;
	}

	function isApproved(address[] storage approvers, address approver) private view returns(bool) {
		for (uint idx = 0; idx < approvers.length; idx++) {
			if (approvers[idx] == approver) {
				return true;
			}
		}
		return false;
	}

	function getExpenseRequest(string calldata id) private view returns(ExpenseRequest storage) {
		for (uint i = 0; i < _expenseRequests.length; i++) {
			ExpenseRequest storage req = _expenseRequests[i];
			bool isMatch = keccak256(bytes(req.id)) == keccak256(bytes(id));
			if (isMatch) {
				return req;
			}
		}
		revert("Expense request id not found");
	}
}