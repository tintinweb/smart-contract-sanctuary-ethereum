// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 targetAmount;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donaters;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _tragetAmount,
        uint256 _deadline,
        string memory _image

    ) public returns(uint256) {

        uint256 campaignId = numberOfCampaigns;

        Campaign storage campaign = campaigns[campaignId];

        require(campaign.deadline < block.timestamp, "Deadline is not valid");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.targetAmount = _tragetAmount;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return campaignId;
    }

    function donateToCampaign(uint256 _campaignId) public payable {
        
        uint256 amount = msg.value;
        
        Campaign storage campaign = campaigns[_campaignId];

        campaign.donaters.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent){
            campaign.amountCollected += amount;
        }
    }

    function getDonators(uint256 _campaignId) public view returns(address[] memory, uint256[] memory) {
        return (campaigns[_campaignId].donaters, campaigns[_campaignId].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i=0; i < numberOfCampaigns; i++){
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }
}