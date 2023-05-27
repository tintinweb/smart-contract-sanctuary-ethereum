// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Dashboard - https://thirdweb.com/sepolia/0x21a557902fe687B340e36C2C912782C18e64BB2D/explorer

contract CrowdFunding {
    struct Campaign {
        address owner;
        string ownerName;
        string title;
        string description;
        string image;
        uint256 targetAmount;
        uint256 amountCollected;
        uint256 deadline;
        uint256[] donations;
        address[] donors;
    }

    Campaign[] public campaigns;
    uint256 public campaignCount;

    constructor() {
        campaignCount = 0;
    }

    function createCampaign(
        address _owner,
        string memory _ownerName,
        string memory _title,
        string memory _description,
        string memory _image,
        uint256 _targetAmount,
        uint256 _deadline
    ) public returns (uint256) {
        Campaign memory newCampaign = Campaign({
            owner: _owner,
            ownerName: _ownerName,
            title: _title,
            description: _description,
            image: _image,
            targetAmount: _targetAmount,
            deadline: _deadline,
            amountCollected: 0,
            donations: new uint256[](0),
            donors: new address[](0)
        });

        campaigns.push(newCampaign);
        campaignCount++;
        return campaignCount - 1;
    }

    function donateToCampaign(uint256 _id) public payable returns (bool) {
        Campaign storage campaign = campaigns[_id];
        campaign.donations.push(msg.value);
        campaign.donors.push(msg.sender);

        bool sent = payable(campaign.owner).send(msg.value);
        if (sent) {
            campaign.amountCollected += msg.value;
        }
        return sent;
    }

    function deleteCampaign(uint256 _id) public {
        for(uint i = _id; i<campaignCount-1; i++){
            campaigns[i] = campaigns[i+1];
        }
        campaignCount--;
        campaigns.pop();
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }

    function getCampaignDonors(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        Campaign storage campaign = campaigns[_id];
        return (campaign.donors, campaign.donations);
    }
}