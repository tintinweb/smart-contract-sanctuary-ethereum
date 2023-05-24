// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {

    struct Campaign{
        address owner;
        string title;
        string description;
        string image;
        uint256 targetAmount;
        uint256 amountCollected;
        uint256 deadline;
        uint256[] donations;
        address[] donars;
    }

    Campaign[] public Campaigns;
    uint256 public campaignCount = 0;

    function createCampaign(address __owner, string memory __title, string memory __description, string memory __image, uint256 __targetAmount, uint256 __deadline) public returns (uint256) {

        require(__deadline > block.timestamp, "The deadline should be somewhere in the future.");

        address[] memory initialDonars;
        uint256[] memory initialDonations;

        Campaigns[campaignCount] = Campaign({
            owner: __owner,
            title: __title,
            description: __description,
            image: __image,
            targetAmount: __targetAmount,   
            deadline: __deadline,
            amountCollected: 0,
            donations: initialDonations,
            donars: initialDonars
        });

        campaignCount++;
        return campaignCount - 1;
    }

    function donateToCampaign(uint256 __id) public payable returns (bool) {
        Campaigns[__id].donations.push(uint256(msg.value));
        Campaigns[__id].donars.push(msg.sender);

        bool sent = payable(Campaigns[__id].owner).send(uint256(msg.value));
        if(sent){
            Campaigns[__id].amountCollected += uint256(msg.value);
        }
        return sent;
    }

    function getAllCampaigns() view public returns (Campaign[] memory) {
        return Campaigns;
    }

    function getAllDonars(uint256 __id) view public returns (address[] memory, uint256[] memory) {
        return (
            Campaigns[__id].donars,
            Campaigns[__id].donations
        );
    }
}