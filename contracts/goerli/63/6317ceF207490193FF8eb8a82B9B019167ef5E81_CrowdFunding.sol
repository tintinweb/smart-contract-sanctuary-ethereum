// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected; // fixed typo in variable name
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns; // fixed typo in variable name

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) { // fixed typos in function parameters
        Campaign storage campaign = campaigns[numberOfCampaigns];
        // is everything  ok?
        require(campaign.deadline > block.timestamp, "The deadline should be a date in future."); // fixed logic error in deadline check

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

    function donateToCampaign(uint256 _id) public payable { // fixed typo in function name and parameter name
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");
        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) { // fixed typo in parameter name and return value type
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() view public returns (Campaign[] memory) { // fixed return value type and function body
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}