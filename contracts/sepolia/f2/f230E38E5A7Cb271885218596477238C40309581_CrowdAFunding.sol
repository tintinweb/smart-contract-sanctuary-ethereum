// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdAFunding {
    // creating a smart contract
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        // image url
        string image;
        // array of address of donator
        address[] donators;
        // array of amount of donation received
        uint256[] donations;
    }

    // creating a mapping
    // by creating a mapping we can use campaigns[0], in js we can directly do this but in solidity we have to create a mapping
    mapping(uint256 => Campaign) public campaigns;

    // to track number of campaigns
    uint256 public numberOfCampaigns = 0;

    // in solidity we have to define that function is only internal or can be called form the frontend so here we can write public and also we need to specity the return type
    // _ before variable specify that the variable is private to this function
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage Campaign = campaigns[numberOfCampaigns];

        // like a check to see is everything is okay?
        require(Campaign.deadline < block.timestamp, "Deadline should be in the future!");

        // populating

        Campaign.owner = _owner;
        Campaign.title = _title;
        Campaign.description = _description;
        Campaign.deadline = _deadline;
        Campaign.target = _target;
        Campaign.amountCollected = 0;
        Campaign.image = _image;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function dotateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage Campaign = campaigns[_id];

        Campaign.donators.push(msg.sender);
        Campaign.donations.push(amount);

        // making a transaction

        // transfer of funds is initiated in this way
        // payable return 2 different things hence a comma
        (bool sent,) = payable(Campaign.owner).call{value: amount}("");
        

        if(sent) {
            Campaign.amountCollected += amount;
        }
        
    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() view public returns (Campaign[] memory) {
        // creating an empty array of structs of numberOfCampaigns
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        // Populating the allCampaigns array

        for(uint i = 0; i < numberOfCampaigns; i++)
        {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}