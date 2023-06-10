// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FundraiserApp {
    struct Campaign {
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
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_target > 0, "Target amount must be greater than zero");
        require(campaign.deadline < block.timestamp);

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

    function donateToCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];

        require(
            campaign.amountCollected < campaign.target &&
                block.timestamp <= campaign.deadline,
            "Donations are closed for this campaign"
        );
        uint256 amount = msg.value;
        require(
            campaign.amountCollected + amount <= campaign.target,
            "The donation exceeds the campaign target"
        );

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.amountCollected += amount;
    }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    function withdrawFunds(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];

        require(
            msg.sender == campaign.owner,
            "Only the campaign owner can withdraw funds"
        );

        require(
            campaign.amountCollected >= campaign.target ||
                campaign.deadline < block.timestamp,
            "Cannot withdraw funds at this time"
        );

        uint256 amountToWithdraw = campaign.amountCollected;

        campaign.amountCollected = 0;

        payable(campaign.owner).transfer(amountToWithdraw);
    }
}