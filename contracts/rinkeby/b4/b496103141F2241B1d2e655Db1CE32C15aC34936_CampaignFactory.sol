//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Campaign {
    address public campaignOwner;
    uint public minimumContribution;
    uint public balance;
    mapping(address => uint) public contributors;
    bool public isFundingRequestOpen;
    uint public contributorsCount;
    uint public withdrawnAmount;

    struct Request {
        string description;
        uint value;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    uint numRequests;
    mapping (uint => Request) public requests;

    event ContributedAmount(uint indexed amount, address indexed contributor);
    event RequestCreated(uint indexed requestId, string indexed description, uint indexed value);
    event RequestApprovedByAContributor(uint indexed requestId, address indexed approver);
    event RequestVotingFulfilled(uint indexed requestId);
    event RequestFulfilled(uint indexed requestId);

    modifier onlyCampaignOwner {
        require(msg.sender == campaignOwner, "Caller is not campaign owner");
        _;
    }

    constructor(uint _minimumContribution, address _campaignOwner) {
        campaignOwner = _campaignOwner;
        minimumContribution = _minimumContribution;
        isFundingRequestOpen = false;
        contributorsCount = 0;
        numRequests = 0;
        withdrawnAmount = 0;
    }

    function contribute() public payable {
        require(msg.value >= minimumContribution, "Contribution is less than minimum set by the owner");
        balance += msg.value;
        contributors[msg.sender] += msg.value;
        contributorsCount++;

        emit ContributedAmount(msg.value, msg.sender);
    }

    function createFundsRequest(uint _amount, string memory _description) public onlyCampaignOwner {
        require(balance >= _amount, "Amount must be less than or equal to the balance");
        require(isFundingRequestOpen == false, "Funding request is already open");
        isFundingRequestOpen = true;

        Request storage r = requests[numRequests++];
        r.description = _description;
        r.value = _amount;
        r.complete = false;
        r.approvalCount = 0;

        emit RequestCreated(numRequests - 1, _description, _amount);
    }

    function approveRequest(uint index) public {
        require(index >= numRequests, "Request index is out of bounds");
        require(isFundingRequestOpen == true, "Funding request is not open");
        Request storage request = requests[index];
        require(contributors[msg.sender] > 0, "You are not a contributor");
        require(!request.approvals[msg.sender], "You have already approved this request");
        request.approvals[msg.sender] = true;
        request.approvalCount++;

        emit RequestApprovedByAContributor(index, msg.sender);

        if(request.approvalCount > (contributorsCount / 2)) {
            emit RequestVotingFulfilled(index);
        }

    }

    function finalizeRequest(uint index) public onlyCampaignOwner {
        require(index >= numRequests, "Request index is out of bounds");
        require(isFundingRequestOpen == true, "Funding request is not open");
        Request storage request = requests[index];
        
        require(request.approvalCount > (contributorsCount / 2));
        require(!request.complete);
        
        payable(campaignOwner).transfer(request.value);
        request.complete = true;
        balance -= request.value;
        withdrawnAmount += request.value;
        isFundingRequestOpen = false;

        emit RequestFulfilled(index);
    }

    function withdrawContribution() public {
        require(contributors[msg.sender] > 0, "You are not a contributor");

        uint totalBalance = balance + withdrawnAmount;
        uint amountToWithdraw = (balance * contributors[msg.sender]) / totalBalance;
        payable(msg.sender).transfer(amountToWithdraw);
        balance -= amountToWithdraw;
    }

}

contract CampaignFactory {
    address public owner;
    address[] public deployedCampaigns;

    event CampaignCreated(address indexed campaign);

    constructor() {
        owner = msg.sender;
    }

    function createCampaign(uint256 _minimumContribution) public {
        require(_minimumContribution > 0);
        address newCampaign = address(new Campaign(_minimumContribution, msg.sender));
        deployedCampaigns.push(newCampaign);

        emit CampaignCreated(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }

}