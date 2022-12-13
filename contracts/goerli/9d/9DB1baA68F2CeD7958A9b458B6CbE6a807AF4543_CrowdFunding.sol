// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error CrowdFunding__IncreaseDeadlineTime();
error CrowdFunding__DonationMustNotBeZero();

/// @author Rohit Kumar Suman. Connect with me on `Twitter ? "@SumanRohitK7" : "Github => @RohitKS7"`
/// @title Contract to CrowdFund for any cause
contract CrowdFunding {
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

    /// @dev Creating a Campagin which returns the ID of the campagin
    function createCampagin(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        if (campaign.deadline < block.timestamp) {
            revert CrowdFunding__IncreaseDeadlineTime();
        }

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        // Returns most newly created campagin
        return numberOfCampaigns - 1;
    }

    /// @dev Donate to listed campaigns
    function donateToCampagin(uint256 _id) public payable {
        uint256 amount = msg.value;

        if (amount <= 0) {
            revert CrowdFunding__DonationMustNotBeZero();
        }

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        // Paying to the campaign owner
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        // Getting all the campaigns in "allCampaigns" variable by creating a new Campaign array as long as the numberOfCampaigns.
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        // looping over the allCampaigns array
        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}