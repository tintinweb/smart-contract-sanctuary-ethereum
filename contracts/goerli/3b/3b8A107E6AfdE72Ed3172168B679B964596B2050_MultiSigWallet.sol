/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";

contract MultiSigWallet {
	// `approvers` is a list of people who are allowed to create and approve transfers
	address[] public approvers; // we set approvers list on constructor call of the contract
	uint256 public quorum; // we set the quorum value on constructor call of the contract
	struct Transfer {
		uint256 id;
		uint256 amount;
		address payable to;
		uint256 approvals; // no. of approvals received
		bool sent; // to check if transfer has sent already or not
	}
	mapping(uint256 => Transfer) public transfers;
	uint256 public nextId;
	mapping(address => mapping(uint256 => bool)) public approvals; // mapping to know who has approved what?

	constructor(address[] memory _approvers, uint256 _quorum) {
		approvers = _approvers;
		quorum = _quorum;
	}

	// solidity only returns specific elements on the array from the public function created by it so in order to fetch all items of address[] we need to:
	function getApprovers() external view returns (address[] memory) {
		return approvers;
	}

	// we need to have `getApprovers()` external fn bcoz solidity only returns individual items of the array and not the whole array.
	function getTransfers() external view returns (Transfer[] memory) {
		// return transfers; // this throws error somewhat related to ref
		// Below code from:
		Transfer[] memory transfersMem = new Transfer[](nextId);
		for (uint256 i = 0; i < nextId; i++) {
			Transfer storage transferMem = transfers[i];
			transfersMem[i] = transferMem;
		}
		return transfersMem;
	}

	function createTransfer(uint256 amount, address payable to) external onlyApprover {
		transfers[nextId] = Transfer(nextId, amount, to, 0, false);
		nextId++;
	}

	function approveTransfer(uint256 id) external onlyApprover {
		require(transfers[id].sent == false, 'transfer has already been sent');
		require(approvals[msg.sender][id] == false, 'you cannot approve transfer twice');

		approvals[msg.sender][id] = true;
		transfers[id].approvals++;

		// console.log('(transfers[id].approvals:?', transfers[id].approvals);
		// console.log('quorum:?', quorum);

		if (transfers[id].approvals >= quorum) {
			// console.log('CONTROL GOES HERE:?');
			transfers[id].sent = true;
			address payable to = transfers[id].to; // making the address payable so we can transfer funds to it
			to.transfer(transfers[id].amount); // Learn: .transfer is a method that's attahed to every payable address
		}
	}

	// we can transfer via a function like below but there is more native way of doing this using a builtin receive function
	// function sendEther() external payable{}

	// We just need to send a transaction to the address of the contract with some ether in it but without targeting any function and below fn will be triggered automatically. Learn: We don't need fn body such receive fn
	receive() external payable {}

	modifier onlyApprover() {
		bool allowed = false;
		for (uint256 i = 0; i < approvers.length; i++) {
			if (approvers[i] == msg.sender) {
				allowed = true;
				break; // ~I added break to stop checking for rest of the addresses after one found (optimization)
			}
		}
		require(allowed == true, 'only approvers allowed');
		_;
	}

	// ~Sahil - Get balance of this contract: https://ethereum.stackexchange.com/a/21449/106687
	function balance() external view returns (uint256) {
		return address(this).balance;
	}
}