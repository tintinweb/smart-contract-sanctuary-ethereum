// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HRTCrowdFunding5 {
    struct Campaign {
        address owner;//Hiral
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        uint256 minContribution;
        bool withdrawalRequestCreated; // Flag to track if a withdrawal request has been created
        
        address[] donators;  // Array to store donators' addresses
        uint256[] donations; // Array to store donation amounts
        
        address[] approvers; // Array to store approvers' addresses
        uint256[] approvals; // Array to store approval amounts

        address[] alldonators; // Array to store all donators' addresses HIRAL
        uint256[] alldonations; // Array to store all donations amounts  HIRAL


    }

    struct WithdrawalRequest {
        uint256 amount;
        string reason;
        address payable payee;
        bool executed;
        address[] approvers;
    }

    mapping(uint256 => Campaign) public campaigns;
    WithdrawalRequest[] public withdrawalRequests;

    uint256 public numberOfCampaigns = 0;

    mapping(address => mapping(uint256 => bool)) public isApprover;
    mapping(address => mapping(uint256 => bool)) public isDonator;

    // Modifier to restrict function access to the campaign owner
    modifier onlyOwner(uint256 _campaignId) {
        require(msg.sender == campaigns[_campaignId].owner, "Only the campaign owner can call this function.");
        _;
    }

    // Create a new campaign
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        uint256 _minContribution
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        // campaign.owner = msg.sender;
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.minContribution = _minContribution;
        campaign.withdrawalRequestCreated = false; // Initialize the withdrawal request flag to false

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    // Contribute to a campaign
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        require(amount > 0, "Donation amount should be greater than zero.");

        campaign.alldonators.push(msg.sender);  //HIRAL
        campaign.alldonations.push(amount);  //HIRAL


        if (amount < campaign.minContribution && !isDonator[msg.sender][_id]) {
            campaign.donators.push(msg.sender);
            campaign.donations.push(amount);
            isDonator[msg.sender][_id] = true;
        }

        if (amount >= campaign.minContribution && !isApprover[msg.sender][_id]) {
            campaign.approvers.push(msg.sender);
            campaign.approvals.push(amount);
            isApprover[msg.sender][_id] = true;
        }

        require(campaign.amountCollected + amount <= campaign.target, "Donation exceeds the campaign target amount.");

        campaign.amountCollected += amount;
    }

    // Create a withdrawal request for a campaign
    function createWithdrawalRequest(
        uint256 _campaignId,
        uint256 _amount,
        string memory _reason,
        address payable _payee
    ) public onlyOwner(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(!_isWithdrawalRequestCreated(_campaignId), "A withdrawal request has already been created.");

        require(_amount <= campaign.amountCollected, "Cannot request more than the amount collected.");

        WithdrawalRequest memory request = WithdrawalRequest(_amount, _reason, _payee, false, new address[](0));
        withdrawalRequests.push(request);

        campaign.withdrawalRequestCreated = true; // Set the withdrawal request flag to true
    }

    // Approve a withdrawal request
    function approveWithdrawalRequest(uint256 _requestIndex) public {
        WithdrawalRequest storage request = withdrawalRequests[_requestIndex];

        require(!request.executed, "The request has already been executed.");
        require(campaigns[_requestIndex].owner != msg.sender, "The campaign owner cannot approve their own withdrawal request.");

        request.approvers.push(msg.sender);
    }

    // Deny a withdrawal request
    function denyWithdrawalRequest(uint256 _requestIndex) public view {
        WithdrawalRequest storage request = withdrawalRequests[_requestIndex];

        require(!request.executed, "The request has already been executed.");
    }

    // Execute a withdrawal request
    function executeWithdrawalRequest(uint256 _requestIndex) public onlyOwner(_requestIndex) {
        WithdrawalRequest storage request = withdrawalRequests[_requestIndex];

        require(!request.executed, "The request has already been executed.");

        uint256 approvalsRequired = campaigns[_requestIndex].approvers.length / 2 + 1;
        require(request.approvers.length >= approvalsRequired, "The request does not have enough approvals.");

        (bool sent, ) = request.payee.call{ value: request.amount }("");
        require(sent, "Failed to transfer funds to the payee.");

        request.executed = true;
    }

    // Get the list of unique donators and their corresponding donation amounts for a campaign HIRAL
    function getUniqueDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // Get the list of approvers and their corresponding approval amounts for a campaign
    function getApprovers(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].approvers, campaigns[_id].approvals);
    }

    // Get the list of all donators and their corresponding donation amounts for a campaign HIRAL
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].alldonators, campaigns[_id].alldonations);
    }

    // Get the total number of unique contributors (donators + approvers) for a campaign
    function getContributorCount(uint256 _id) public view returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        return getUniqueCount(campaign.donators) + getUniqueCount(campaign.approvers);
    }

    // Get the count of approvers who approved the withdrawal request
    function getApproverCount(uint256 _requestIndex) public view returns (uint256) {
        return withdrawalRequests[_requestIndex].approvers.length;
    }

    // Get the list of all campaigns
    function getCampaigns() public view returns (CampaignDetails[] memory) {
        CampaignDetails[] memory allCampaigns = new CampaignDetails[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            allCampaigns[i] = CampaignDetails(
                campaign.owner,
                campaign.title,
                campaign.description,
                campaign.target,
                campaign.deadline,
                campaign.amountCollected,
                campaign.image,
                campaign.minContribution
            );
        }

        return allCampaigns;
    }

    struct CampaignDetails {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        uint256 minContribution;
    }

    // Get the list of all withdrawal requests
    function getWithdrawalRequests() public view returns (WithdrawalRequest[] memory) {
        return withdrawalRequests;
    }

    // Get the details of a campaign
    function getCampaignDetails(uint256 _id) public view returns (
        address,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        string memory,
        uint256,
        bool
    ) {
        Campaign storage campaign = campaigns[_id];

        return (
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.image,
            campaign.minContribution,
            campaign.withdrawalRequestCreated
        );
    }

    // Internal function to check if a withdrawal request has already been created for a campaign
    function _isWithdrawalRequestCreated(uint256 _campaignId) internal view returns (bool) {
        return campaigns[_campaignId].withdrawalRequestCreated;
    }

    // Internal function to calculate the count of unique elements in an array
    function getUniqueCount(address[] memory _array) internal pure returns (uint256) {
        uint256 count = 0;
        address prev;

        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] != prev) {
                prev = _array[i];
                count++;
            }
        }

        return count;
    }
}