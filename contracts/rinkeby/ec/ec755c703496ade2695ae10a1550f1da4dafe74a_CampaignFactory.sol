/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CampaignFactory {
	address[] public deployedCampaigns;

	function createCampaign(uint minimum) public {
		Campaign newCampaign = new Campaign(minimum, msg.sender);
		deployedCampaigns.push(address(newCampaign));
	}

	function getDeployedCampaigns() public view returns (address[] memory) {
		return deployedCampaigns;
	}
}

contract Campaign {
	struct Request {
		string description;
		uint value;
		address payable recipient;
		bool complete;
		uint approvalCount;
		mapping(address => bool) approvals;
	}

	address public manager;
	uint public minimumContribution;
	// address[] public approvers;
	mapping(address => bool) public approvers;
	uint public approverCount;
	// Request[] public requests;
	uint requestCount;
	mapping(uint => Request) public requests;

	modifier restricted() {
		require(msg.sender == manager);
		_;
	}

	constructor(uint minimum, address creator) {
		manager = creator;
		minimumContribution = minimum;
	}

	function contribute() public payable {
		require(msg.value > minimumContribution);

		if (!approvers[msg.sender])
			approverCount++;
		approvers[msg.sender] = true;
	}

	// function createRequest(string memory description, uint value, address recipient) public restricted {
	//     Request storage newRequest = Request({
	//         description: description,
	//         value: value,
	//         recipient: recipient,
	//         complete: false,
	//         approvalCount: 0
	//     });

	//     // Alternative syntax, but not recommended
	//     // Request(description, value, recipient, false);

	//     requests.push(newRequest);
	// }

	function createRequest(string memory description, uint value, address payable recipient) public restricted {
		Request storage request = requests[requestCount++];
		request.description = description;
		request.value = value;
		request.recipient = recipient;
		request.complete = false;
		request.approvalCount = 0;
	}

	function approveRequest(uint index) public {
		Request storage request = requests[index];

		require(approvers[msg.sender]);
		require(!request.approvals[msg.sender]);

		request.approvals[msg.sender] = true;
		request.approvalCount++;
	}

	function finalizeRequest(uint index) public restricted {
		Request storage request = requests[index];

		require(!request.complete);
		require(request.approvalCount * 2 > approverCount);

		request.recipient.transfer(request.value);
		request.complete = true;
	}
}