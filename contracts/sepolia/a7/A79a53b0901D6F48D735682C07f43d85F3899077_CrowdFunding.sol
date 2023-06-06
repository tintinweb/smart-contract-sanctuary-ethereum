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

    function CreateCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns]; // initially empty
        // is everything okay
        require(campaign.deadline < block.timestamp, "You can't create a campaign in the past");
        // if everything is okay
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns-1;
    }

    function donateToCampaign(uint256 _id) public payable {
        // be extra cautious in payable functions.
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        // I don't have any idea what below code is supposed to do
        (bool sent,) = payable(campaign.owner).call{value: amount}(""); // may be it is inbuilt check for if someone has paid or not   and it will return 2 values together with the  amount.
        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }

    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        // this means that we are creating an empty array in memory that have as many empty campaigns as the number of Campaigns present.
        for(uint i = 0; i< numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];  // basically copying the array.
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}