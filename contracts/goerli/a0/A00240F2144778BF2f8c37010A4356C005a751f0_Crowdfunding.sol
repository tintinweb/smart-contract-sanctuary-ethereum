// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {
    struct  Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 ammountcollected;
        string image;
        address[] donators;
        address[] donations;

    }
    
    mapping(uint256 =>  Campaign) public campaigns;

    uint256 public numberofCampaigns = 0;
     
    function createCampign(address _owner, string memory _title,string memory _description,uint256 _target,
    uint256 _deadline, string memory _image)public returns (uint256){
        
        Campaign storage campaign = campaigns[numberofCampaigns];
        // is everything okay 
        require(campaign.deadline < block.timestamp,"the deadline should be a date in the  future.");
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.ammountcollected =0;
        campaign.image = _image;

        numberofCampaigns++;

        return numberofCampaigns - 1;


    }

    function donatetoCampign(uint256 _id)public payable{
         uint256 amount = msg.value;

         Campaign storage campaign =campaigns[_id];
         
         campaign.donators.push(msg.sender);
         campaign.donations.push();

         (bool sent,) = payable(campaign.owner).call{value: amount}("");

         if(sent){
            campaign.ammountcollected = campaign.ammountcollected + amount;
             
         }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory){
        //return (campaigns[_id].donators, campaigns[_id].donators);
    }

    function getCampaigns()public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

        for (uint i=0; i < numberofCampaigns; i++){
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;

        }
        return allCampaigns;
    }
}