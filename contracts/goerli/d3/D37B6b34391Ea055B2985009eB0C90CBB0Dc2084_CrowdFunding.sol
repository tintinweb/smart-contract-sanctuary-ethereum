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
        address[] donators;
        uint256[] donations;
     }

     mapping(uint256 => Campaign) public campaings;
     uint256 public numberOfCampaings = 0;

     function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target,
     uint256 _deadline, string memory _image)public returns (uint256){
        Campaign storage campaign =campaings[numberOfCampaings];
        // to check if everything is okay !
        require(campaign.deadline < block.timestamp,"The deadline should be a future date.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaings++;

        return numberOfCampaings -1;

     }

     function donateToCampaign (uint256 _id)public payable{
        uint256 amount = msg.value;

        Campaign storage campaign = campaings[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value:amount}("");

        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
        }
        
         }

     function getDonators(uint256 _id)view public returns(address[] memory, uint256[]memory){
        return (campaings[_id].donators, campaings[_id].donations);
     }

     function getCampaigns()public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaings);

        for(uint i = 0; i< numberOfCampaings; i++){
            Campaign storage item = campaings[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
     }
}