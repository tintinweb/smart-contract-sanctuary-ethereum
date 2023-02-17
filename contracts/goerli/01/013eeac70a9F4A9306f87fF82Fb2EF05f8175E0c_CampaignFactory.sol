/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(address(newCampaign));
    }

    function getDeployedCampaigns() public view returns(address[] memory) {
        return deployedCampaigns;
    }

}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    modifier restricted() {
        require(msg.sender == manager, "Invalid user");
        _;
    }

    // Request[] public requests;
    uint private numRequests;
    mapping(uint => Request) public requests;

    address public manager;
    uint public minimumContribution;
    // address[] public approvers;
    mapping(address => bool) public approvers;
    uint public approversCount;

    constructor(uint minum, address creator) {
        manager = creator;
        minimumContribution = minum;
    }

    function contribute() external payable {
        require(msg.value > minimumContribution, "Not meet minimum ether to send.");
        // approvers.push(msg.sender);
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory description,
        uint value,
        address recipient
    ) external restricted {
        Request storage r = requests[numRequests++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;
    }

    function approveRequest(uint index) external {
        Request storage request = requests[index];

        require(approvers[msg.sender], "Not contributor!");
        require(!request.approvals[msg.sender], "Already approvered!");

        request.approvals[msg.sender] = true;
        request.approvalCount++;

    }

    function finalizeRequest(uint index) external restricted {
        Request storage request = requests[index];
        require(!request.complete, "Request has already been completed!");
        require(request.approvalCount > (approversCount / 2), "No enough approvals.");
        payable(request.recipient).transfer(request.value);
        request.complete = true;

    }

}