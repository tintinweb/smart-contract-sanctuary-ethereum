// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target; // target amount we want to raise
        uint256 deadline; // deadline for the campaign
        uint256 amountCollected; // amount raised so far
        string image; // image url
        address[] donators;
        uint256[] donations;
    }
    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future."
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donanumberOfCampaignsteToCampaign(uint256 _CampaignId)
        public
        payable
    {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_CampaignId];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        (bool success, ) = payable(campaign.owner).call{value: amount}("");

        if (success) {
            campaign.amountCollected += amount;
        }
    }

    function getDonators(uint256 _CampaignId)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        Campaign storage campaign = campaigns[_CampaignId];
        return (campaign.donators, campaign.donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // getting an [{} ,{}, {}...n]

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }
}