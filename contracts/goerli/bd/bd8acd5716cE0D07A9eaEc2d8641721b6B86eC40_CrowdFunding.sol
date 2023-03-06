// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        string image;
        uint256 target;
        uint256 amountCollected;
        uint256 deadline;
        address [] donators;
        uint256 [] donations; 
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0; 

    function createCampaign (address _owner, string memory _title, string memory _description, string memory _image, uint256 _target, uint256 _amountCollected, uint256 _deadline) public returns (uint256) {
        
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline > block.timestamp, 'The deadline should be in the future');

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.amountCollected = _amountCollected;
        campaign.deadline = _deadline;
        campaign.description = _description;
        campaign.target = _target;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
}

    function donateToCampaign (uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount; 
        }
    }

    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item; 
        }

        return allCampaigns; 
    }

}