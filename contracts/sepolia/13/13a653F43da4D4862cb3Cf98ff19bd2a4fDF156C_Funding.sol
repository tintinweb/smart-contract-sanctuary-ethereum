// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        uint256 deadline;
        address[] donators;
        uint256[] donations;
        string image;
    }
    mapping(uint256 => Campaign) public campaigns;
    uint public numberOfCampaign = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        string memory image,
        uint256 _deadline,
        uint256 target
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaign];
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.deadline = _deadline;
        campaign.target = target;
        campaign.image = image;
        campaign.amountCollected = 0;
        numberOfCampaign++;
        return numberOfCampaign - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender); // pushed the sender details in donators
        campaign.donations.push(amount); // pushed the sender donation amount in donations

        (bool sent, ) = payable(campaigns[_id].owner).call{value: amount}("");
        if (sent) campaign.amountCollected = campaign.amountCollected + amount; // added amount in amountCollected
    }

    function getDonator(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaign);
        for (uint i = 0; i < numberOfCampaign; i++) {
            allCampaigns[i] = campaigns[i];
        }
        return allCampaigns;
    }
}