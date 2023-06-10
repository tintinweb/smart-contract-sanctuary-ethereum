// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        string image;
        uint256 deadline;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256=> Campaign) public campaigns;

    uint public numberOfCampaigns =0;

    function createCampaign(address _owner,string memory _title , string memory _description
    , string memory _image ,uint256 _target, uint256 _deadline)public returns(uint256){
      
      Campaign storage campaign  = campaigns[numberOfCampaigns];
     
      campaign.owner = _owner;
      campaign.title = _title;
      campaign.description = _description;
      campaign.target = _target;
      campaign.deadline = _deadline;
      campaign.amountCollected = 0;
      campaign.image = _image;

      numberOfCampaigns++;
      return numberOfCampaigns -1;    
    }

    function donateToCampaign(uint256 _id)public payable {
      uint amount = msg.value;

      campaigns[_id].donators.push(msg.sender);
      campaigns[_id].donations.push(amount);

      (bool sent,) = payable(campaigns[_id].owner).call{value:amount}(""); 
      if(sent) campaigns[_id].amountCollected = campaigns[_id].amountCollected + amount;
    }

    function getDonators(uint256 _id)view public returns(address[] memory,uint256[] memory){
        return (campaigns[_id].donators , campaigns[_id].donations);
    }

    function getCampaign() view public returns(Campaign[] memory){
      Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

      for(uint i=0;i<numberOfCampaigns;i++){
            allCampaigns[i] = campaigns[i];
      }
      return allCampaigns;

    }
}