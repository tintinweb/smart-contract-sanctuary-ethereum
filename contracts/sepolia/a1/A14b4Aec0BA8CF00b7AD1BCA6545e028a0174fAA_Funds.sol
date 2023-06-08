// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funds {
   struct Campaign{
    address owner;
    string title;
    string description;
    uint256 target;
    uint256 deadline;
    string image;
    uint256 collectedAmount;
    address[] donators;
    uint256[] donations;
   }

   mapping(uint256=> Campaign) public campaigns;
   uint256 public numberOfCampaigns =0;

   function createCampaign(address _owner ,string memory _title , string memory _description,uint256 _target, string memory _image
    ,uint256 _deadline) public returns(uint256){
       Campaign storage campaign = campaigns[numberOfCampaigns];

       campaign.owner = _owner;
       campaign.title = _title;
       campaign.description = _description;
       campaign.target = _target;
       campaign.deadline = _deadline;
       campaign.collectedAmount = 0;
       campaign.image = _image;

       numberOfCampaigns++;
        return numberOfCampaigns-1;

   }

   function donateToCamapign(uint256 _id) public payable{
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) =payable(campaign.owner).call{value:amount}("");

        if(sent) campaign.collectedAmount = campaign.collectedAmount + amount;
   }

   function getDonators(uint256 _id) view public returns (address[] memory,uint256[] memory){
      return (campaigns[_id].donators , campaigns[_id].donations);
   }

   function getCampaigns() view public returns (Campaign[]memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i=0;i<numberOfCampaigns;i++){
            allCampaigns[i] = campaigns[i];
        } 
        return allCampaigns;
   }
}