// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign{
        address payable owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public campaignCount=0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 deadline, string memory _image) public returns(uint256){
        Campaign storage campaign = campaigns[campaignCount];

        require(campaign.deadline > block.timestamp, "The campaign must be a date in the future");

        campaign.owner = payable(_owner);
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = deadline;
        campaign.image = _image;

        campaignCount++;

        return campaignCount-1;
    }

    function donateToCampaign(uint256 _id) public payable{
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donations.push(amount);
        campaign.donators.push(msg.sender);
        (bool sent,)= payable(campaign.owner).call{value: amount}("");

        if(sent){
            campaign.amountCollected += amount;
        }

    }

    function getDonators(uint256 _id) public view returns(address[] memory, uint256[] memory){
        return(campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);

        for(uint256 i=0; i<campaignCount; i++){
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}