// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donaters;
        uint256[] donations;

    }
    mapping(uint256 =>Campaign) public campaigns;
    uint256 public numberOfCampaigns =0;
    function createCampaign(address _owner,string memory _title,string memory _description,uint256 _target,uint256 _deadline,string memory _image) public returns (uint256){
        //creating comapaigns
        Campaign storage campaign = campaigns[numberOfCampaigns];
        //is everything okay?
        require(campaign.deadline<block.timestamp,"the deadline should be a date in the future.");
        campaign.owner =_owner;
        campaign.title =_title;
        campaign.description =_description;
        campaign.target =_target;
        campaign.deadline =_deadline;
        campaign.amountCollected =0;
       campaign.image = _image;
       numberOfCampaigns++;
    }
   function donateCampaign(uint256 _id)public payable{
   uint256 amount = msg.value;
   Campaign storage  campaign = campaigns[_id];
  campaign.donaters.push(msg.sender);
  campaign.donations.push(amount);
  (bool sent,)=payable(campaign.owner).call{value:amount}("");
 if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }
    function getDonaters(uint256 _id) view public returns(address[] memory,uint256[] memory){
        return (campaigns[_id].donaters,campaigns[_id].donations);
    }
    function getCampaign() public view returns (Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        for(uint i=0;i<numberOfCampaigns;i++){
            Campaign storage item = campaigns[i];
            allCampaigns[i]=item;
        }
        return allCampaigns;
    }
}