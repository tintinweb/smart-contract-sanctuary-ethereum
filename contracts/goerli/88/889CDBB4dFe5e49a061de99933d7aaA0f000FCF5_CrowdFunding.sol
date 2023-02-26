// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {

    // Campaign struct
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

    // map campaigns
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, 
                            string memory _title, 
                            string memory _description, 
                            uint256 _target, 
                            uint256 _deadline, 
                            string memory _image
                            ) public returns (uint256) {

        // initialize campaigns                        
        Campaign storage campaign = campaigns[numberOfCampaigns];

        // check if campaign passed
        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        // initialize campaign
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        
        // add numbers of campaigns
        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {

        // amount
        uint256 amount = msg.value;

        // find campaign with _id
        Campaign storage campaign = campaigns[_id];

        // add donator and donation
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        // initialize sent
        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            // add amount to collected amount
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) public view returns(address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

}