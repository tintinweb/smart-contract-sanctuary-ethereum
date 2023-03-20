// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract VitalFund {
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

    uint256 public numberOfCampaingns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        //equivalent of 'new' to create a variable
        //here we create an object of type Campaign
        Campaign storage campaign = campaigns[numberOfCampaingns];

        //require is like try and catch
        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaingns++;

        return numberOfCampaingns-1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value; //taken from frontend

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender); //send donator address
        campaign.donations.push(amount); //send donation amount

        (bool sent,) = payable(campaign.owner).call{value: amount}(""); //checking if paid
        if(sent) { //update total amount collected
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    //returns donators[] and donations[]
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaingns);

        for(uint i = 0; i < numberOfCampaingns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}