// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title Crowdfunding Contract
/// @notice A smart contract for creating and managing crowdfunding campaigns.
contract Crowdfunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 balance;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    /// @notice Creates a new crowdfunding campaign.
    /// @param _owner The address of the campaign owner.
    /// @param _title The title of the campaign.
    /// @param _description The description of the campaign.
    /// @param _goal The fundraising goal of the campaign.
    /// @param _deadline The deadline of the campaign.
    /// @param _image The image URL of the campaign.
    /// @return The ID of the newly created campaign.
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _goal, uint256 _deadline, string memory _image) public returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.goal = _goal;
        campaign.deadline = _deadline;
        campaign.balance = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    /// @notice Donates funds to a crowdfunding campaign.
    /// @param _id The ID of the campaign.
    function donate(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.balance = campaign.balance + amount;
        }
    }

    /// @notice Retrieves the list of donators and their corresponding donations for a campaign.
    /// @param _id The ID of the campaign.
    /// @return An array of donator addresses and an array of donation amounts.
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    /// @notice Retrieves all the crowdfunding campaigns.
    /// @return An array of all campaigns.
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        Campaign storage item;

        for(uint i = 0; i < numberOfCampaigns; i++) {
            item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}