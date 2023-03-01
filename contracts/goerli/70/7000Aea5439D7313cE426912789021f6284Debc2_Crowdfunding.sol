// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {

    // defining the Campaign struct to create a new campaign
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    // defining the mapping to store the campaigns
    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaing(
        address _owner, 
        string memory _title, 
        string memory _description, 
        uint256 _target, 
        uint256 _deadline, 
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // check to see if everything is good
        require(campaign.deadline < block.timestamp, "Deadline must be in the future");

        // set the values
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;

        // return index of the newly added campaign
        return numberOfCampaigns++;
    }

    function donateToCampaign(
        uint256 _campaignId
    ) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_campaignId];

        // record the donation
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        // send the money to the owner
        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected += amount;
        }
    }

    function getDonators(
        uint256 _campaignId
    ) public view returns (address[] memory,  uint256[] memory) {
        Campaign memory campaign = campaigns[_campaignId];
        return (campaign.donators, campaign.donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        // empty array to store the campaigns
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        // populate the array
        for(uint256 i = 0; i < numberOfCampaigns; i++) {
            allCampaigns[i] = campaigns[i];
        }

        // return result
        return allCampaigns;
    }
}