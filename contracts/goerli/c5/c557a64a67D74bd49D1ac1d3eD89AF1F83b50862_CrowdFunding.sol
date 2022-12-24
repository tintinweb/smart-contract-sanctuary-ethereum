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

    mapping(uint256 => Campaign) public campaigns;
    uint256 public NumberOfCampaigns = 0;

    function createCampaign(address _owner,string memory _title, string memory _description,
        uint256 _target, uint256 _deadline,string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[NumberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline must be in the future");
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        NumberOfCampaigns++;
        return NumberOfCampaigns - 1;

    }
    function donateToCampaign(uint256 campaignId) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[campaignId];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value : amount}("");

        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }
    function getDonators(uint256 campaignId) view public returns (address[] memory, uint256[] memory){
        return(campaigns[campaignId].donators,campaigns[campaignId].donations);

    }
    function getCampaigns() public view returns(Campaign[] memory){
       Campaign[] memory allCampaigns = new Campaign[](NumberOfCampaigns);
        for(uint i =0; i<NumberOfCampaigns; i++){
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}