// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFund {
    struct Compaign {
        string title;
        string description;
        uint256 amountCollected;
        address  owner;
        uint256 target;
        uint256 deadline;
        string image;
        address[] donators;
        uint256[] donation;
    }

    mapping(uint256 => Compaign) public compaigns;

    uint256 public numberOfCompaigns = 0;

    function createCompaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory image) public returns(uint256) {
        Compaign storage campaign = compaigns[numberOfCompaigns];

        require(campaign.deadline < block.timestamp, "Deadline must be in the future");

        campaign.title = _title;
        campaign.description = _description;
        campaign.amountCollected = 0;
        campaign.owner = _owner;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = image;

        numberOfCompaigns++;

        return numberOfCompaigns -1;

    }


    function donateToCompaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Compaign storage campaign = compaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donation.push(amount);

        (bool sent,) = campaign.owner.call{value: amount}("");

        if(sent) {
            campaign.amountCollected += amount;
        }

    }


    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        Compaign storage campaign = compaigns[_id];

        return (campaign.donators, campaign.donation);
    }


    function getCompaign() public view returns(Compaign[] memory) {
        Compaign[] memory allCampaigns = new Compaign[](numberOfCompaigns);

        for(uint256 i = 0; i < numberOfCompaigns; i++) {
            allCampaigns[i] = compaigns[i];
        }

        return allCampaigns;
    }

}