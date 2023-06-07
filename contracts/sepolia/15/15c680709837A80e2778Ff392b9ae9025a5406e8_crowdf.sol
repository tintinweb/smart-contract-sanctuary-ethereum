// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract crowdf {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    struct Campaign {
        uint id;
        string name;
        address payable creator;
        string description;
        string image;
        uint goal;
        uint deadline;
        uint extendedDeadline; // New field to track the extended deadline
        
        uint raisedAmount;
        uint numRequests;
        bool complete;
        address[] contributors;
        mapping(uint => Request) requests;
        mapping(address => uint) contributions;
    }

    Campaign[] public campaigns;

    uint256 public numberOfCampaigns = 0;

    struct CampaignDetails {
        uint id;
        string name;
        address creator;
        string description;
        string image;
        uint goal;
        uint deadline;
        uint extendedDeadline; // New field to include in CampaignDetails
        Contributor[] contributors;
        uint raisedAmount;
        uint numRequests;
        bool complete;
    }

    struct Contributor {
        address contributorAddress;
        uint contributionAmount;
    }

    struct RequestDetails {
    string description;
    uint value;
    address payable recipient;
    bool complete;
    uint approvalCount;
    uint raisedAmount;
    string campaignName;
    bool createdByContributor;
}

    function getAllCampaigns() public view returns (CampaignDetails[] memory) {
        CampaignDetails[] memory campaignsDetails = new CampaignDetails[](campaigns.length);
        for (uint i = 0; i < campaigns.length; i++) {
            campaignsDetails[i] = getCampaignDetails(i);
        }
        return campaignsDetails;
    }

    function getCampaignDetails(uint _campaignId) public view returns (CampaignDetails memory) {
        Campaign storage campaign = campaigns[_campaignId];
        Contributor[] memory contributors = new Contributor[](campaign.contributors.length);
        for (uint i = 0; i < campaign.contributors.length; i++) {
            address contributorAddress = campaign.contributors[i];
            uint contributionAmount = campaign.contributions[contributorAddress];
            contributors[i] = Contributor(contributorAddress, contributionAmount);
        }
        return CampaignDetails(
            campaign.id,
            campaign.name,
            campaign.creator,
            campaign.description,
            campaign.image,
            campaign.goal,
            campaign.deadline,
            campaign.extendedDeadline,
            contributors,
            campaign.raisedAmount,
            campaign.numRequests,
            campaign.complete
        );
    }

    function createCampaign(
        string memory _name,
        string memory _description,
        string memory _image,
        uint _goal,
        uint _deadline
    ) public {
        Campaign storage newCampaign = campaigns.push();
        newCampaign.id = campaigns.length - 1;
        newCampaign.name = _name;
        newCampaign.creator = payable(msg.sender);
        newCampaign.description = _description;
        newCampaign.image = _image;
        newCampaign.goal = _goal;
        newCampaign.deadline = _deadline;
        newCampaign.extendedDeadline = 0; // Initialize extended deadline to 0
        
        newCampaign.raisedAmount = 0;
        newCampaign.numRequests = 0;
        newCampaign.complete = false;

        numberOfCampaigns++;
    }

    function extendDeadline(uint _campaignId, uint _newDeadline) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only the campaign creator can extend the deadline.");
        require(campaign.complete == true , "Cannot extend the deadline as the campaign is already completed.");

        campaign.extendedDeadline = _newDeadline;
    }

    
  

    function contribute(uint _campaignId) public payable {
    Campaign storage campaign = campaigns[_campaignId];
    campaign.raisedAmount += msg.value;
    campaign.contributions[msg.sender] += msg.value;
    if (campaign.contributions[msg.sender] > 0) {
        campaign.contributors.push(msg.sender);
    }
}


    function createRequest(uint _campaignId, string memory _description, uint _value, address payable _recipient) public {
    Campaign storage campaign = campaigns[_campaignId];
    require(msg.sender == campaign.creator, "Only the campaign creator can create requests.");
    require(campaign.raisedAmount > 0, "There is no fund to request.");
    require(_value <= campaign.raisedAmount, "Requested value is greater than the raised amount.");
    uint newRequestId = campaign.numRequests;
    Request storage newRequest = campaign.requests[newRequestId];
    newRequest.description = _description;
    newRequest.value = _value;
    newRequest.recipient = _recipient;
    newRequest.complete = false;
    newRequest.approvalCount = 0;
    campaign.numRequests++;
}


    function voteRequest(uint _campaignId, uint _requestId) public {
    Campaign storage campaign = campaigns[_campaignId];
    Request storage request = campaign.requests[_requestId];
    
    require(request.complete == false, "The request has already been processed.");
    require(campaign.contributions[msg.sender] > 0, "Only campaign contributors can vote on requests.");
    require(request.approvals[msg.sender] == false, "You have already voted for this request.");
    
    request.approvals[msg.sender] = true;
    request.approvalCount++;
}

    function makePayment(uint _campaignId, uint _requestId) public {
        Campaign storage campaign = campaigns[_campaignId];
        Request storage request = campaign.requests[_requestId];
        require(request.complete == false, "The request has already been processed.");
        require(request.approvalCount > (campaign.numRequests / 2), "The request needs more approvals.");
        request.recipient.transfer(request.value);
        request.complete = true;
    }


   function getContributedCampaigns(address _contributor) public view returns (CampaignDetails[] memory) {
    uint contributedCount = 0;
    // First, loop through all campaigns to count the number of campaigns that the _contributor has contributed to
    for (uint i = 0; i < campaigns.length; i++) {
        if (campaigns[i].contributions[_contributor] > 0) {
            contributedCount++;
        }
    }
    // If the _contributor has not contributed to any campaigns, return an empty array
    if (contributedCount == 0) {
        return new CampaignDetails[](0);
    }
    // Otherwise, initialize an array with length equal to the number of campaigns the _contributor has contributed to
    CampaignDetails[] memory contributedCampaigns = new CampaignDetails[](contributedCount);
    uint count = 0;
    // Loop through campaigns again to populate the contributedCampaigns array
    for (uint i = 0; i < campaigns.length; i++) {
        Campaign storage campaign = campaigns[i];
        if (campaign.contributions[_contributor] > 0) {
            uint contributorCount = 0;
            Contributor[] memory contributors = new Contributor[](campaign.contributors.length);
            for (uint j = 0; j < campaign.contributors.length; j++) {
                address contributor = campaign.contributors[j];
                uint contributionAmount = campaign.contributions[contributor];
                if (contributionAmount > 0) {
                    contributors[contributorCount] = Contributor(contributor, contributionAmount);
                    contributorCount++;
                }
            }
            contributedCampaigns[count] = CampaignDetails(
                campaign.id,
                campaign.name,
                campaign.creator,
                campaign.description,
                campaign.image,
                campaign.goal,
                campaign.deadline,
                campaign.extendedDeadline,
                contributors,
                campaign.raisedAmount,
                campaign.numRequests,
                campaign.complete
            );
            count++;
        }
    }
    return contributedCampaigns;
}



    function withdraw(uint _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.raisedAmount >= campaign.goal, "The goal has not been reached yet.");
        
        payable(campaign.creator).transfer(campaign.raisedAmount);
        campaign.complete = true;
    }

    

function getRequestDetails(uint _campaignId) public view returns (RequestDetails[] memory) {
        Campaign storage campaign = campaigns[_campaignId];
        uint requestCount = campaign.numRequests;
        RequestDetails[] memory requestDetails = new RequestDetails[](requestCount);
        
        for (uint i = 0; i < requestCount; i++) {
            Request storage request = campaign.requests[i];
            
            requestDetails[i] = RequestDetails(
                request.description,
                request.value,
                request.recipient,
                request.complete,
                request.approvalCount,
                campaign.raisedAmount,
                campaign.name,
                campaign.contributions[msg.sender] > 0
            );
        }
        
        return requestDetails;
    }


   function getAllContributors(uint _campaignId) public view returns (address[] memory) {
    Campaign storage campaign = campaigns[_campaignId];
    return campaign.contributors;
}
}