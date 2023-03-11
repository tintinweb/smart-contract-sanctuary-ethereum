// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdfundingContract 
{
    struct Campaign
    {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountcollected;
        string image;
        address[] doners;
        uint256[] donations;
    }
    
    mapping (uint256 => Campaign) public campaings;

    uint256 public noOfCampaings = 0; 

    function createCampaign(address _owner, string memory _title, string memory _description, 
    uint256 _target, uint256 _deadline, string memory _image) public returns (uint256)
    {
        Campaign storage campaign = campaings[noOfCampaings];

        require(campaign.deadline < block.timestamp, "The deadline date should be future date.");

        campaign.owner = _owner;
        campaign.deadline = _deadline;
        campaign.description = _description;
        campaign.title = _title;
        campaign.amountcollected = 0;

        noOfCampaings++;

        //returns noOfCampaings-1;
        //returns 1; 
    }

    
}