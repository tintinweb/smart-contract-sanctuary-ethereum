// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CitizenFeedback {
    struct Complaint {
        address owner; 
        string title;
        // string description;
        string target;
        uint256 date;
        // uint256 amountCollected;
        string image;
        // address[] donators;
        // uint256[] donations;
    }

    mapping(uint256 => Complaint) public complaints;
    uint public numberOfComplaints = 0;

    function createComplaint(
        address _owner,
        string memory _title,
        // string memory _description,
        string memory target,
        uint256 date,
        string memory _image
    ) public returns (uint256) {
        Complaint storage campaign = complaints[numberOfComplaints];

        // require(
        //     campaign.deadline < block.timestamp,
        //     "The deadline should be a date in the future"
        // );

        campaign.owner = _owner;
        campaign.title = _title;
        // campaign.description = _description;
        campaign.target = target;
        campaign.date = date;
        // campaign.amountCollected = 0;
        campaign.image = _image;
        // campaign.donators = _donators;
        // campaign.donations = _donations;

        numberOfComplaints++;

        return numberOfComplaints - 1;
    }

    

    

    function getComplaints() public view returns (Complaint[] memory) {
        Complaint[] memory allCampaigns = new Complaint[](numberOfComplaints);
        for (uint i = 0; i < numberOfComplaints; i++) {
            Complaint storage item = complaints[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}