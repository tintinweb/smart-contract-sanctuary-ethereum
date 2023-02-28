// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    // Creating Structs for Campaign
    struct Campaign {
        address creator;
        string name;
        string description;
        uint goal;
        uint createdAt;
        uint deadline;
        uint amountCollected;
        string image;
        address[] pledgers;
        uint[] pledges;
    }

    mapping(uint => Campaign) public campaigns;

    // Number of campaigns
    uint public campaignCounts = 0;

    // Adding new campaign to the blockchain network
    function newCampaign(
        address _creator,
        string memory _name,
        string memory _description,
        uint _goal,
        uint _created_at,
        uint _deadline,
        string memory _image
    ) public returns (uint) {
        Campaign storage campaign = campaigns[campaignCounts];
        // Validate few fields
        //require(campaign.createdAt > block.timestamp,"Created time is less than current Block Timestamp");
        // require(campaign.deadline < campaign.createdAt,"Deadline is less than Start time");
        require(
            campaign.deadline < block.timestamp, "Deadline time is invalid, should be latter time."
        );

        campaign.creator = _creator;
        campaign.name = _name;
        campaign.description = _description;
        campaign.goal = _goal;
        campaign.createdAt = _created_at;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        campaignCounts++;
        return campaignCounts - 1;
    }

    // Pledge to a campaign
    function pledge(
        uint _id
    ) public payable {
        uint amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        // Validate fields..
//        require(
//            block.timestamp >= campaign.createdAt, "Campaign has not Started yet"
//        );
        require(
            block.timestamp <= campaign.deadline, "Campaign has already ended"
        );

        campaign.pledgers.push(msg.sender);
        campaign.pledges.push(amount);
        (bool pledged,) = payable(campaign.creator).call{value: amount}("");
        // User has pledged an amount
        if(pledged) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    // Get Campaign pledgers.
    function getPledgers(
        uint _id
    ) view public returns (
        address[] memory,
        uint[] memory
    ) {
        return (
        campaigns[_id].pledgers,
        campaigns[_id].pledges
        );
    }

    // Return all campaign records for the blockchain.
    function getCampaigns() public view returns (
        Campaign[] memory
    ) {
         // Get campaigns..
        Campaign[] memory Campaigns = new Campaign[](campaignCounts);
        for(uint i = 0; i < campaignCounts; i++) {
            Campaign storage item = campaigns[i];
            Campaigns[i] = item;
        }
        return Campaigns;
    }
}