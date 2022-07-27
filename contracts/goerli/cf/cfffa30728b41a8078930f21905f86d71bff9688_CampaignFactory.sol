/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract CampaignFactory {
    Campaign[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (Campaign[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint256 value;
        address payable recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    uint256 public approversCount;

    uint256 numRequests;
    mapping(uint256 => Request) public requests;

    constructor(uint256 minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(
            msg.value >= minimumContribution,
            "A minumum contribution is required."
        );
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory description,
        uint256 value,
        address payable recipient
    ) public onlyManager {
        Request storage r = requests[numRequests++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;
    }

    function approveRequest(uint256 index) public {
        Request storage request = requests[index];
        require(
            approvers[msg.sender],
            "Only contributors can approve a specific payment request"
        );
        require(
            !request.approvals[msg.sender],
            "You have already voted to approve this request"
        );

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint256 index) public onlyManager {
        Request storage request = requests[index];
        require(
            request.approvalCount > (approversCount / 2),
            "This request needs more approvals before it can be finalized"
        );
        require(!(request.complete), "This request has already been finalized");

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            minimumContribution,
            address(this).balance,
            numRequests,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return numRequests;
    }

    modifier onlyManager() {
        require(
            msg.sender == manager,
            "Only the campaign manager can call this function."
        );
        _;
    }
}