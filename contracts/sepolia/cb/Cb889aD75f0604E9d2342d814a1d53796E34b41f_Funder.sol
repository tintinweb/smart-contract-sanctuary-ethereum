// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funder {
    struct Campaign{
      address owner;
      string title;
      string desciption;
      uint256 target;
      uint256 amountCollected;
      uint256 deadline;
      string image;
      address[] donators;
      uint256[] donations;  
    }

 mapping(uint256 => Campaign) public campaigns;

 uint public numberOfCampaigns;

 function createCampaign(address _owner , string memory _title , string memory _description ,string memory _image,uint _target,
 uint _deadline ) public returns(uint256){
   Campaign storage campaign = campaigns[numberOfCampaigns];

   campaign.owner = _owner;
   campaign.title = _title;
   campaign.desciption = _description;
   campaign.target = _target;
   campaign.deadline = _deadline;
   campaign.image = _image;
   campaign.amountCollected = 0;

   numberOfCampaigns++;

   return numberOfCampaigns-1;
 }

 function donateToCampaign(uint256 _id) public payable{
  uint amount = msg.value;
  Campaign storage campaign = campaigns[_id];
  campaign.donators.push(msg.sender);
  campaign.donations.push(amount);

  (bool sent,) =payable(campaign.owner).call{value:amount}("");
  if(sent) campaign.amountCollected = campaign.amountCollected + amount;
 }

 function getDonators(uint256 _id)view public returns(address[] memory, uint256[] memory){
    return (campaigns[_id].donators , campaigns[_id].donations);
 }

 function getCampaign()view public returns(Campaign[] memory){
  Campaign[] memory allcampaigns = new Campaign[](numberOfCampaigns);
  for(uint i=0;i<numberOfCampaigns;i++){
    allcampaigns[i] = campaigns[i];
  }

  return allcampaigns;
 }

}