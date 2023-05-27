// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint256 minimum, string memory name, string memory description, string memory image, uint256 target) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender, name, description, image, target);
        deployedCampaigns.push(address(newCampaign));
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
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

    Request[] public requests;
    address public manager;
    uint256 public minimumContribution;
    string public campaignName;
    string public campaignDescription;
    string public imageUrl;
    uint256 public targetToAchieve;
    address[] public contributors;
    mapping(address => bool) public approvers;
    uint256 public approversCount;

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can perform this action.");
        _;
    }

    constructor(uint256 minimum, address creator, string memory name, string memory description, string memory image, uint256 target) {
        manager = creator;
        minimumContribution = minimum;
        campaignName = name;
        campaignDescription = description;
        imageUrl = image;
        targetToAchieve = target;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution, "Contribution must be greater than the minimum contribution.");

        contributors.push(msg.sender);
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(string memory description, uint256 value, address payable recipient) public restricted {
        // Request memory newRequest;
        Request storage newRequest = requests.push();
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;

        // requests.push(newRequest);
    }

    function approveRequest(uint256 index) public {
        require(approvers[msg.sender], "Only approvers can approve requests.");
        require(!requests[index].approvals[msg.sender], "Request has already been approved by this approver.");

        requests[index].approvals[msg.sender] = true;
        requests[index].approvalCount++;
    }

    function finalizeRequest(uint256 index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2), "Approval count must be greater than half of the approvers.");
        require(!request.complete, "Request has already been completed.");

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (uint256, uint256, uint256, uint256, address, string memory, string memory, string memory, uint256) {
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            approversCount,
            manager,
            campaignName,
            campaignDescription,
            imageUrl,
            targetToAchieve
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return requests.length;
    }
}