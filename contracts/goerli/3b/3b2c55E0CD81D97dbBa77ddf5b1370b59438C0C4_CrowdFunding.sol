// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    // counter for the number of campaigns
    // also will be the ID generator for retrieving campaigns
    uint256 public campaignCount;

    // definition of a campaign object
    struct Campaign{
        address   owner;
        string    title;
        string    description;
        uint256   target;
        uint256   deadline;
        uint256   amountCollected;
        string    imageURL;
        address[] donors;
        uint256[] donations;
    }

    // mapping to store all campaigns
    mapping(uint256 => Campaign) public campaignList;    
    
    constructor() {
        campaignCount = 0;
    }

    function createCampaign(address _owner,string memory _title,string memory _description,uint256 _target,uint256 _deadline ,string memory _imageURL) public returns (uint256) {
        // initialize the campaign mapping 
        Campaign storage campaign = campaignList[campaignCount]; 

        // make sur the deadline is in the future
        // require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        // populate the campaign structure
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.imageURL = _imageURL;

        // increment the count so the ID of the next one is different
        campaignCount++;

        return campaignCount - 1;
    }

    function donateToCampaign(uint256 _campaignID) payable public{
        // get campaign
        Campaign storage currenctCampaign = campaignList[_campaignID]; 
        
        //update object with new amount, donor, and donations
        currenctCampaign.amountCollected += msg.value; 
        currenctCampaign.donors.push(msg.sender);
        currenctCampaign.donations.push(msg.value);
    }

    function GetDonators(uint256 _campaignID) external view returns (address[] memory, uint256[] memory ){
        // get campaign
        Campaign memory currenctCampaign = campaignList[_campaignID]; 
        // return donors and donations
        return (currenctCampaign.donors, currenctCampaign.donations);
    }

    function getCampaigns() external view returns (Campaign[] memory){
        // create new campaings arraay of fixed length
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);

        // lopp over the campaign mapping
        for(uint i = 0; i < campaignCount; i++) {
            Campaign storage item = campaignList[i];
            //add campaign to new list
            allCampaigns[i] = item;
        }
    
        return allCampaigns;
    }

}