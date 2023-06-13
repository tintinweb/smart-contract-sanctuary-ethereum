// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funding{
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        uint256 deadline;
        string image;
        address[] donators;
        uint256[] donations;


    }

    mapping(uint256 => Campaign) public campaigns;
    uint public numberOfCampaigs = 0;

    function createCampaign(address _owner , string memory _title , string memory _description , string memory _image , 
    uint256 _deadline , uint256 _target) public returns(uint256) {
      
      Campaign storage campaign = campaigns[numberOfCampaigs];

       campaign.owner = _owner ;
       campaign.title = _title;
       campaign.description = _description;
       campaign.target = _target;
       campaign.deadline = _deadline;
       campaign.image = _image;
       campaign.amountCollected = 0; 
       numberOfCampaigs++;
       return numberOfCampaigs-1;
    }
    function donateToCampaign(uint _id) public payable{
        uint amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        (bool sent,) = payable(campaigns[_id].owner).call{value:amount}("");
        if(sent) campaign.amountCollected = campaign.amountCollected+amount;
         

    }
    function getDonators(uint256 _id) view public returns(address [] memory , uint256[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations);
       
    }
    function getCampaigns() view public returns(Campaign[] memory){
        Campaign [] memory allCampaigns = new Campaign[](numberOfCampaigs);
        for(uint i = 0; i<numberOfCampaigs ; i++){
            allCampaigns[i] = campaigns[i];

        }
        return allCampaigns;
    }

}