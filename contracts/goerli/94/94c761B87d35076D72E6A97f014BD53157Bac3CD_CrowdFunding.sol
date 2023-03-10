// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {

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

    uint256 public numberOfCompaigns = 0;

    function createCampaign(address _owner, string memory _title,string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns(uint256){

        require(_deadline < block.timestamp, "The deadline should be in future.");

        Campaign storage campaign = campaigns[numberOfCompaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;
        campaign.amountCollected = 0;

        numberOfCompaigns++;
        return numberOfCompaigns - 1;

    }

    function donateToCompaign(uint256 _id) public payable{
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        (bool sent,) = payable(campaign.owner).call{value: amount}("");
        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
            campaign.donators.push(msg.sender);
            campaign.donations.push(amount);
        }

 
    }

    function getDonators(uint256 _id) view public returns (address [] memory,uint256[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaign() view public returns(Campaign[] memory){
        Campaign[] memory allCampaign = new Campaign[](numberOfCompaigns);

        for(uint256 i=0 ; i < numberOfCompaigns; i++){
            Campaign storage item = campaigns[i];
            allCampaign[i] = item;
        }
        return allCampaign;
    }




}