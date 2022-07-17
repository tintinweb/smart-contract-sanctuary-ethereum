/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CampaignFactory {
    address[] public deployedCampaigns;

    event CampaignFactory__CampaignCreated(address newCampaign, uint minimum, address owner);

    function createCampaign(uint minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(address(newCampaign));
        emit CampaignFactory__CampaignCreated(address(newCampaign), minimum, msg.sender);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
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

    // Request[] public requests;
    mapping (uint => Request) public requests;
    uint public numRequests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    mapping(address => uint) public contributers;

    event Campaign__Contribution(address indexed contributer, uint amount, bool indexed IsApprover);
    event Campaign__RequestCreated(uint indexed index, string description, uint value, address indexed recipient);
    event Campaign__RequestApproved(uint indexed index, address indexed approver, uint approvalCount, string description, uint value, address indexed recipient);
    event Campaign__RequestFinalized(uint indexed index, string description, uint value, address indexed recipient, bool completed, uint approvals, uint approvers);

    modifier restricted() {
        require(msg.sender == manager, "You are not allowed to call this function");
        _;
    }

    constructor (uint minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        contributers[msg.sender] += msg.value;
        if((approvers[msg.sender] == false) && (contributers[msg.sender] > minimumContribution)) {
            approvers[msg.sender] = true;
            approversCount++;
        }
        emit Campaign__Contribution(msg.sender, msg.value, approvers[msg.sender]);
    }

    function createRequest(string memory description, uint value, address recipient) public restricted {
        Request storage request = requests[numRequests++];
        request.description = description;
        request.value = value;
        request.recipient = recipient;
        request.complete = false;
        request.approvalCount = 0;

        emit Campaign__RequestCreated(
            numRequests - 1,
            request.description,
            request.value,
            request.recipient
        );
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender], "You are not an authorized approver");
        require(!request.approvals[msg.sender], "You already approved this request");

        request.approvals[msg.sender] = true;
        request.approvalCount++;

        emit Campaign__RequestApproved(
            index,
            msg.sender,
            request.approvalCount, 
            request.description,
            request.value,
            request.recipient
        );
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2), "Not enough approvals");
        require(!request.complete, "Was already completed");

        request.complete = true;
        (bool success, ) = request.recipient.call{value: request.value}("");
        require(success, "Transfer failed");

        emit Campaign__RequestFinalized(
            index, 
            request.description, 
            request.value, 
            request.recipient, 
            request.complete, 
            request.approvalCount, 
            approversCount
        );
    }

    function getSummary() public view returns (uint, uint, uint, uint, address) {
        return (
            minimumContribution,
            address(this).balance,
            numRequests,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return numRequests;
    }
}