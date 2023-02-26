// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CrowdFunding{
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

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
         address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    )public returns(uint256){
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future."
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable{
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.amountCollected = campaign.amountCollected + amount;
    }

    function withdraw(uint256 _id) public{
        Campaign storage campaign = campaigns[_id];

        require(
            campaign.owner == msg.sender,
            "Only the owner of the campaign can withdraw the funds."
        );
        require(
            campaign.amountCollected >= campaign.target,
            "The campaign has not reached its target yet."
        );

        require(
            campaign.deadline < block.timestamp,
            "The deadline has not passed yet."
        );
        (bool sent, ) = payable(campaign.owner).call{value: campaign.amountCollected}("");

        if (sent) {
            campaign.amountCollected = 0;
        }
    }

    function getCampaign(uint256 id) public view returns(
        address,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        string memory
    )
    {
        Campaign memory campaign = campaigns[id];
        return(
        campaign.owner,
        campaign.title,
        campaign.description,
        campaign.target,
        campaign.deadline,
        campaign.amountCollected,
        campaign.image
        );

    }
}