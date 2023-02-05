// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amount_collected;
        string image;
        address[] donators;
        uint256[] donations;
    }
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberofCampaigns =0;

    function createCampaign(address _owner, string memory _title,string memory _description, 
    uint256 _target, uint256 _deadline,string memory _image)public returns(uint256){
        Campaign storage campaign = campaigns[numberofCampaigns];

        require(campaign.deadline < block.timestamp,"Invalid Deadline: Please enter a future date");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amount_collected =0;
        campaign.image = _image;

        numberofCampaigns++;

        return numberofCampaigns -1;
    }

    function donateCampaign(uint256 _id) public payable{
        uint256 amount=msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent){
            campaign.amount_collected = campaign.amount_collected + amount;
        }

    }

    function getDonators(uint256 _id) view public returns(address[] memory,uint256[] memory){
        return (campaigns[_id].donators,campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allcampaigns = new Campaign[](numberofCampaigns);

        for(uint i=0;i<numberofCampaigns;i++){
            Campaign storage item= campaigns[i];

            allcampaigns[i]=item;
        }

        return allcampaigns;
    }
}