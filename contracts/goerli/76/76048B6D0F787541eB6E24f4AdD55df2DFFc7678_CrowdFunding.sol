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
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image)
    public returns (uint256) {

        Campaign storage campaign = campaigns[numberOfCampaigns];

        // is everything okay? - if deadline is smaller then current time
        // code will no proceed further if this is not sastified
        require(campaign.deadline < block.timestamp, "The dealine should be a date in the future");

        // filling up the campaign
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;  // index of the last created campaign
    }

    function donateToCampaign(uint256 _id) public payable {  // payable specifies that we are going to send crypto currency in this function
        
        uint256 amount = msg.value; // amount sent from the front end 
        Campaign storage campaign = campaigns[_id]; // get the campaign user wants to donate to through its id

        campaign.donators.push(msg.sender);  // push the address of sender into donators array
        campaign.donations.push(amount); // push the amount of sender into donations array

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");  // check if amount sent to the owner

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {

        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() view public returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // creating a new empty array called allCampaigns which is of type Campaign containing as many elements as numberOfCampaigns  
        
        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}