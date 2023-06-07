// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract CrowdFundingV1 {
    struct Campaign {
        address owner;
        string title;
        string description;
        string category;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        uint256 campaignId;
    }

    //Mapping
    mapping(uint256 => Campaign) public campaigns;

    //Number of campaigns
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        string memory _category,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(
            campaign.deadline > block.timestamp,
            "Deadline must be in the future"
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.category = _category;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.campaignId = numberOfCampaigns;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    //Getters

    function getNumberOfCampaigns() public view returns (uint256) {
        return numberOfCampaigns;
    }

    function getCampaign(
        uint256 _id
    )
        public
        view
        returns (
            address,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            string memory,
            address[] memory,
            uint256[] memory
        )
    {
        Campaign storage campaign = campaigns[_id];

        return (
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.category,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.image,
            campaign.donators,
            campaign.donations
        );
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory _campaigns = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            _campaigns[i] = campaigns[i];
        }

        return _campaigns;
    }
}