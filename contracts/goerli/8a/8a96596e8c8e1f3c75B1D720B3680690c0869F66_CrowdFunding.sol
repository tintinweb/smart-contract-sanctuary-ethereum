// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    error CrowdFunding__DeadlineMustBeInTheFuture();

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

    // Create a new campaign and return its id
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadLine,
        string memory _image
    ) public returns (uint256) {
        // Create a new campaign and store it in the array
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // Check that the deadline is in the future
        if (campaign.deadline > block.timestamp) {
            revert CrowdFunding__DeadlineMustBeInTheFuture();
        }

        // Save the campaign's details
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadLine;
        campaign.amountCollected = 0;
        campaign.image = _image;

        // Increment the number of campaigns
        numberOfCampaigns++;

        // Return the campaign's id (index of most recent campaign)
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value; // Capture the amount of Ether sent with the transaction

        Campaign storage campaign = campaigns[_id]; // Load the campaign from the storage

        campaign.donators.push(msg.sender); // Add the address of the caller to the donators array
        campaign.donations.push(amount); // Add the amount sent to the donations array

        (bool sent, ) = payable(campaign.owner).call{value: amount}(""); // Send the amount to the campaign owner

        if (sent) {
            // campaign.amountCollected = campaign.amountCollected + amount;
            campaign.amountCollected += amount; // Increment the campaign amountCollected variable
        }
    }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // Return a list of all campaigns created
    // @return Array of Campaigns
    function getCampaigns() public view returns (Campaign[] memory) {
        // Create a new array with the number of campaigns
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        // Loop through the array
        for (uint i = 0; i < numberOfCampaigns; i++) {
            // Set the Campaign struct from the campaigns array to the array to return
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}