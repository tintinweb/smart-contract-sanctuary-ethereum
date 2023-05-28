// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string causeTitle;
        string description;
        uint256 targetAmount;
        uint256 deadline;
        uint256 collectedAmount;
        string image;
        address[] donators;
        uint256[] donations;
    }
    
    uint256 public noOfCampaigns = 0;
    mapping(uint256 => Campaign) public campaigns;

    function createCampaign(address _owner, string memory _title, string memory _desc, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[noOfCampaigns];
        noOfCampaigns++;

        // require(campaign.deadline<block.timestamp, "The deadline should be a date in the future!");
        require(_deadline < block.timestamp, "The deadline should be a date in the future!");
        campaign.owner = _owner;
        campaign.causeTitle = _title;
        campaign.description = _desc;
        campaign.targetAmount = _target;
        campaign.deadline = _deadline;
        campaign.collectedAmount = 0;
        campaign.image = _image;

        return noOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        
        Campaign storage campaign = campaigns[_id];
        uint256 amount = msg.value;
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");      //csdcsd

        if(sent){
            campaign.collectedAmount += amount;
        }
    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](noOfCampaigns);

        for(uint i = 0; i<noOfCampaigns; i++)
        {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
    
}

//private key: 599dd0a6c04f0b83cffa88661ccc7d6619527aeff0b492dd840138d08d386876