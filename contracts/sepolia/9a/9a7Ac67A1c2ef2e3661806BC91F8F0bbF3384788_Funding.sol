// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funding {
    struct Campaign{ // struct == class
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

    mapping(uint256=>Campaign) public campaigns;
    uint public numberOfCampaigns = 0;

    function createCampaign(address _owner,string memory _title,string memory _description,uint256 _target,uint256 _deadline,string memory _image) public returns(uint256){
        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = _owner;
        campaign.amountCollected = 0;
        campaign.deadline = _deadline;
        campaign.description = _description;
        campaign.image = _image;
        campaign.target = _target;
        campaign.title = _title;

        numberOfCampaigns++;

        return numberOfCampaigns-1;
    }

    function donateToCampaign(uint256 _id) public payable{
        uint amount = msg.value; //msg me current calling user ka data aaye ga
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value:amount}("");
        if(sent) campaign.amountCollected  = campaign.amountCollected + amount;
    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory){
        return(campaigns[_id].donators,campaigns[_id].donations);
    }

    function getCampaigns()view public returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            allCampaigns[i] = campaigns[i];
        }
        return allCampaigns;
    }

}