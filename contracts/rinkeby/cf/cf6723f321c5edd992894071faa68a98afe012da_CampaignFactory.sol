/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15.0;

contract CampaignFactory {
    address private manager;
    address[] private deployedCampaigns;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You're not a manager");
        _;
    }

    function createCampaign(
        string memory campaignTitle,
        string memory campaignDescription,
        uint campaignMinimumContribution
    ) public {
        address newCampaign = address(
            new Campaign(
                campaignTitle,
                campaignDescription,
                campaignMinimumContribution,
                msg.sender,
                manager
            )
        );

        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view onlyManager returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        bool created;
        string title;
        string description;
        uint amount;
        address recipient;
        mapping(address => bool) approvals;
        uint approvalCount;
        bool complete;
    }

    address private owner;
    address private manager;
    uint private minimumContribution;
    string private title;
    string private description;
    uint private numContributors = 0;
    uint private numRequests = 0;

    mapping(address => uint) public approvers;
    mapping(uint => Request) public requests;

    constructor(
        string memory campaignTitle,
        string memory campaignDescription,
        uint defaultMinimumContribution,
        address managerAddress,
        address ownerAddress
    ) {
        title = campaignTitle;
        description = campaignDescription;
        minimumContribution = defaultMinimumContribution;
        manager = managerAddress;
        owner = ownerAddress;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You're not a manager");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not a owner");
        _;
    }

    function getManager() public view onlyOwner returns (address) {
        return manager;
    }

    function getNumContributors() public view onlyOwner returns (uint) {
        return numContributors;
    }

    function getNumRequests() public view onlyOwner returns (uint) {
        return numRequests;
    }

    function getMinimumContribution() public view onlyOwner returns (uint256) {
        return minimumContribution;
    }

    function getSummary() public view onlyOwner returns (
        string memory,
        string memory,
        uint,
        uint,
        uint,
        uint,
        address
    ) {
        return (
        title,
        description,
        minimumContribution,
        address(this).balance,
        numRequests,
        numContributors,
        manager
        );
    }

    function contribute() public payable {
        require(msg.sender != manager, "Managers are not allowed to participate");
        require(msg.value >= minimumContribution, "Minimal contribution not reached");

        approvers[msg.sender] = ++approvers[msg.sender];
        ++numContributors;
    }

    function createRequest(string memory requestTitle, string memory requestDescription, uint amount, address recipient)
    public payable
    onlyManager {
        require(address(this).balance >= amount, "There is not enough contributed yet");
        require(bytes(requestDescription).length > 10, "The description is to short");

        Request storage newRequest = requests[numRequests];
        newRequest.created = true;
        newRequest.title = requestTitle;
        newRequest.description = requestDescription;
        newRequest.amount = amount;
        newRequest.recipient = recipient;
        newRequest.approvalCount = 0;
        newRequest.complete = false;

        ++numRequests;
    }

    function getRequestSummary(uint requestIndex) public view onlyOwner returns (
        string memory,
        string memory,
        uint,
        address,
        uint,
        bool
    ) {
        Request storage currentRequest = requests[requestIndex];

        require(currentRequest.created, "This request doesn't exists");

        return (
        currentRequest.title,
        currentRequest.description,
        currentRequest.amount,
        currentRequest.recipient,
        currentRequest.approvalCount,
        currentRequest.complete
        );
    }

    function approveRequest(uint requestIndex) public payable {
        require(msg.sender != owner, "Owners are not allowed to participate");
        require(msg.sender != manager, "Managers are not allowed to participate");

        Request storage currentRequest = requests[requestIndex];

        require(currentRequest.created, "This request doesn't exists");
        require(!currentRequest.complete, "This request is already completed");
        require(approvers[msg.sender] > 0, "You need to contribute first");
        require(!currentRequest.approvals[msg.sender], "You already have voted");

        currentRequest.approvals[msg.sender] = true;
        ++currentRequest.approvalCount;
    }

    function finalizeRequest(uint requestIndex) public onlyManager {
        Request storage currentRequest = requests[requestIndex];

        require(currentRequest.created, "This request doesn't exists");
        require(!currentRequest.complete, "This request is already completed");
        require(address(this).balance >= currentRequest.amount, "This request is already completed");
        require(currentRequest.approvalCount >= (numContributors / 2), "You already have voted");

        (bool success,) = currentRequest.recipient.call{value : currentRequest.amount}("");
        require(success, "Couldn't transfer money to recipient.");

        currentRequest.complete = true;
    }
}