// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrownFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 dealine;
        uint256 amountCollected;
        string image;
        address[] donator;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign (address _owner, string memory _title, string memory _description , uint256 _target,
    uint _dealine ,uint256 _amountCollected,string memory _image) public returns(uint256) { 
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.dealine > block.timestamp , "The dealine should be in the future");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.dealine = _dealine;
        campaign.amountCollected = _amountCollected;
        campaign.image = _image;
      
        numberOfCampaigns++;
      return  numberOfCampaigns -1;
    }

    
    function donateToCampaign (uint256 _id )public   payable   {
        uint256  amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donator.push(msg.sender);
         campaign.donations.push(amount);
         (bool sent, ) = payable(campaign.owner).call{value : amount}(""); 
         if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;

         }
        
    }

    
    function getDonators (uint256 _id) view public returns (address[] memory , uint256[] memory) {
        return (campaigns[_id].donator , campaigns[_id].donations);
    }

    
    function getCampaigns ()  public view returns (Campaign[] memory ) {
        Campaign[] memory allCampains = new Campaign[](numberOfCampaigns);
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item  = campaigns[i];
            allCampains[i] = item;
        }
        return allCampains;
    }
}