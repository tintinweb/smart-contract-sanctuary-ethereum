// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {

    struct Campaign{
        address owner;
        string title;
        string description;
        string image;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        address[] donators;
        uint256[] donations;
  }
  

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberofCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory image) public returns(uint256) {
        Campaign storage campaign = campaigns[numberofCampaigns];

        //is everything okay!
        require(_deadline < block.timestamp, "Deadline should be in the future");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.image = image;
        campaign.deadline = _deadline;
        campaign.target = _target;
        numberofCampaigns++;
    }


    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent){
        campaign.amountCollected += amount;   
        }

    }
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);

    }

    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

        for(uint i =0; i< numberofCampaigns;i++){
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item; 
        }

        return allCampaigns;
    } 

}