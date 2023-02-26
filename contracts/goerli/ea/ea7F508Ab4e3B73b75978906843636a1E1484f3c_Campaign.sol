// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract CampaignFactory {
    address payable[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        address newCampaign = address(new Campaign(minimum, msg.sender));
        deployedCampaigns.push(payable(newCampaign));
    }

    function getDeployedCampaigns()
        public
        view
        returns (address payable[] memory)
    {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        //describes why the request is being created
        string description;
        //amount of money that the manager wants to send to the vendor
        uint256 value;
        //address that the money will be sent to
        address recipient;
        //true if the request has already been processes
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    uint256 public approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint256 minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    //called when someone wants to donate money to the campaign
    //and become an 'approver'
    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

    //called by the manager to create a new 'spending request'
    function createRequest(
        string memory description,
        uint256 value,
        address recipient
    ) public restricted {
        Request storage newRequest = requests.push();
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
    }

    //called by each contributor to approve a spending request
    function approveRequest(uint256 index) public {
        //manipulate the Request struct in storage
        Request storage request = requests[index];
        //require that inside the approvers mapping we should receive a true result
        //the person approving the request has in fact contributed
        require(approvers[msg.sender]);
        //require that the person approving hasn't approved before, no double counts
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        //how many people have joined contract
        request.approvalCount++;
    }

    //after a request has gotten enough approvals, the manager can call this to get money sent to the vendor
    function finalizeRequest(uint256 index) public restricted {
        Request storage request = requests[index];

        //greater than 50% of people must approve before funds released
        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);
        //recipient receives funds
        payable(request.recipient).transfer(request.value);
        //when funds are paid, flag is flipped
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
            requests.length,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return requests.length;
    }
}