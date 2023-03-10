// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract crowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        string image;
        uint256 target;
        uint256 deadline;
        uint256 collected;
        address[] contributors;
        uint256[] contributions;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public campaignCount = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, string memory _image, uint256 _target, uint256 _deadline) public returns (uint256) {
        
        Campaign storage campaign = campaigns[campaignCount];

        require(campaign.deadline > block.timestamp, "Deadline must be greater than current time");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.image = _image;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.collected = 0;

        campaignCount++;

        return campaignCount-1;

    }

    function contribute(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];

        campaign.contributors.push(msg.sender);
        campaign.contributions.push(msg.value);

        campaign.collected += msg.value;
        
        (bool sent,) = payable(campaign.owner).call{value: msg.value}("");

        if (sent){
            campaign.collected += msg.value;
        }
    }

    function getContributors(uint256 _campaignId) public view returns (address[] memory , uint256[] memory) {
        return (campaigns[_campaignId].contributors , campaigns[_campaignId].contributions);
    }

   function getCampaign() public view returns (Campaign[] memory)  {
        Campaign[] memory _allCampaigns = new Campaign[](campaignCount);

        for (uint256 i = 0; i < campaignCount; i++) {
            Campaign storage campaign = campaigns[i];
            _allCampaigns[i] = campaign;

        }

        return _allCampaigns;
   }

}