// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract crowdfunding {
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
    mapping(uint256 => Campaign) public campaigns;

 uint256 public numberofCampaigns = 0;

function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline , string memory _image) public returns (uint256){
  
  require(_deadline > block.timestamp, "The deadline should be a date in the future.");

  Campaign storage campaign = campaigns[numberofCampaigns];

  campaign.owner = _owner;
  campaign.title = _title;
  campaign.description = _description;
  campaign.target = _target;
  campaign.deadline = _deadline;
  campaign.amountCollected = 0;
  campaign.image = _image;

  numberofCampaigns++;
   
   return numberofCampaigns - 1;
}

function donateToCampaign(uint256 _id) public payable {
    uint256 amount = msg.value;

    Campaign storage campaign = campaigns[_id];

    campaign.donators.push(msg.sender);
    campaign.donations.push(amount);

    (bool sent,) = payable(campaign.owner).call{value: amount}("");

    if (sent){
        campaign.amountCollected += amount;
    }
}

function getCampaignDonators(uint256 _id) public view returns(address[] memory, uint256[] memory) {

    Campaign storage campaign = campaigns[_id];

    return (campaign.donators, campaign.donations);
}

function getAllCampaigns() public view returns (Campaign[] memory)
{
    Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

    for (uint i= 0; i< numberofCampaigns; i++)
    {
        Campaign storage item = campaigns[i];

        allCampaigns[i] = item;
    }
    return allCampaigns;
}

    
}