// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        bool isActive;
        address[] donators;
        uint256[] donations;
    }

    uint256 public numberOfCampaigns = 0;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreate(
        uint256 id,
        address owner,
        string title,
        uint256 target
    );
    event CampaignDonation(uint256 campaignId, address donator, uint256 amount);
    event FundsWithdraw(uint256 campaignId, address owner, uint256 amount);
    event CampaignRefund(uint256 campaignId, address owner, uint256 amount);

    function createCampaign(
        address _owner,
        string calldata _title,
        string calldata _description,
        uint256 _target,
        uint256 _deadline,
        string calldata _image
    ) external returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_target > 0, "Target amount must be greater than zero.");

        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future."
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.isActive = true;

        numberOfCampaigns++;

        emit CampaignCreate(numberOfCampaigns, _owner, _title, _target);

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) external payable {
        uint256 amount = msg.value;
        address donator = msg.sender;

        require(_id < numberOfCampaigns, "Requied campaign does not exists.");
        require(amount > 0, "Donation amount must be greater than zero.");

        Campaign storage campaign = campaigns[_id];

        require(campaign.isActive, "Campaign is inactive.");

        campaign.donators.push(donator);
        campaign.donations.push(amount);

        emit CampaignDonation(_id, donator, amount);
        campaign.amountCollected += amount;
    }

    function withdrawFunds(uint256 _id) external {
        require(_id < numberOfCampaigns, "Requied campaign does not exists.");

        Campaign storage campaign = campaigns[_id];

        require(campaign.isActive, "Campaign is inactive.");
        require(
            msg.sender == campaign.owner,
            "Only campaign creator can withdraw funds."
        );
        require(
            campaign.amountCollected == campaign.target,
            "Funds can only be withdrawn after target completion."
        );

        bool sent = payable(campaign.owner).send(campaign.target);

        if (sent) {
            emit FundsWithdraw(_id, campaign.owner, campaign.target);
            campaign.isActive = false;
        }
    }

    function refundDonators(uint256 _id) external {
        require(_id < numberOfCampaigns, "Requied campaign does not exists.");

        Campaign storage campaign = campaigns[_id];

        require(
            msg.sender == campaign.owner,
            "Only campaign creator can initiate refunds."
        );
        require(campaign.isActive, "Campaign is inactive.");

        for (uint256 i = 0; i < campaign.donators.length; i++) {
            payable(campaign.donators[i]).transfer(campaign.donations[i]);
        }

        campaign.isActive = false;
        emit CampaignRefund(_id, campaign.owner, campaign.amountCollected);
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
}