/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.25;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(
        uint256 minimum,
        string memory School,
        address schoolAddress
    ) public {
        address newCampaign = new Campaign(
            minimum,
            School,
            schoolAddress,
            msg.sender
        );
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    constructor(
        uint256 minimum,
        string memory School,
        address account,
        address creator
    ) public {
        minimumContribution = minimum;
        schoolName = School;
        schoolAddress = account;
        manager = creator;
    }

    struct Request {
        string schoolName;
        string description;
        uint256 value;
        address recipient;
        string url;
        bool complete;
        bool reject;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    uint256 public approversCount;
    string public schoolName;
    address public schoolAddress;

    modifier restricted() {
        require(msg.sender == manager || msg.sender == schoolAddress);
        _;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory description,
        uint256 value,
        address recipient,
        string memory url
    ) public restricted {
        Request memory newRequest = Request({
            description: description,
            schoolName: schoolName,
            value: value,
            recipient: recipient,
            url: url,
            complete: false,
            reject: false,
            approvalCount: 0
        });
        requests.push(newRequest);
    }

    function approveRequest(uint256 index) public restricted {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint256 index) public restricted {
        Request storage request = requests[index];

        require(request.value <= this.balance);
        require(!request.complete);
        require(!request.reject);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function rejectRequest(uint256 index) public restricted {
        Request storage request = requests[index];
        require(!request.reject);
        require(!request.complete);

        request.reject = true;
    }

    function getSummary()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            string calldata,
            address
        )
    {
        return (
            minimumContribution,
            this.balance,
            requests.length,
            approversCount,
            manager,
            schoolName,
            schoolAddress
        );
    }

    function getRequestCount() public view returns (uint256) {
        return requests.length;
    }
}