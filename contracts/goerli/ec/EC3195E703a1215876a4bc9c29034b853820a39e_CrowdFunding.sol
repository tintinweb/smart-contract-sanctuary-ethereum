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
        address[] donator;
        uint256[] donation;
    }
    // mapping the structure campaign
    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberofCampaigns = 0; // public variable

    // To initailize a new Campaign
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberofCampaigns];

        // checking if the deadline is valid
        require(
            campaign.deadline < block.timestamp,
            "Deadline should be in future!"
        );
        // only run if the deadline is in future
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        //now inc no of campaigns
        numberofCampaigns++;

        // index of the created campaign
        return numberofCampaigns - 1;
    }

    //to donate amount to a particular campaign
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value; // amount recieved

        Campaign storage campaign = campaigns[_id];

        campaign.donator.push(msg.sender); // storing donator address
        campaign.donation.push(amount); // storing donated amount

        // wether amount is sent
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        // inc amount collected
        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    // to get a list of all the listed campaign
    function getCampaign() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

        for (uint256 i = 0; i < numberofCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    // to get a list of all the donators
    function getDonators(uint256 _id)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (campaigns[_id].donator, campaigns[_id].donation);
    }
}