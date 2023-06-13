// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amount;
        uint256 deadline;
        uint256 collected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaings = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        string memory _image,
        uint256 _deadline
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaings];

        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future"
        );

        campaign.owner = _owner;
        campaign.description = _description;
        campaign.target = _target;
        campaign.title = _title;
        campaign.deadline = _deadline;
        campaign.collected = 0;
        campaign.image = _image;
        numberOfCampaings++;

        return numberOfCampaings - 1;
    }

    function donateToCampaign(uint256 _campaignID) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_campaignID];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.collected = campaign.collected + amount;
        }
    }

    function getDonators(
        uint256 _campaignID
    ) public view returns (address[] memory, uint256[] memory) {
        return (
            campaigns[_campaignID].donators,
            campaigns[_campaignID].donations
        );
    }

    function getCampaings() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaings = new Campaign[](numberOfCampaings);

        for (uint i = 0; i < numberOfCampaings; i++) {
            Campaign storage item = campaigns[i];
            allCampaings[i] = item;
        }
        return allCampaings;
    }
}