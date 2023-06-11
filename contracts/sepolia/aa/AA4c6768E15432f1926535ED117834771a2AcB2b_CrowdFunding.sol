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

    //memory is a keyword for temporary variables that are erased between
    //external function calls and are used to hold temporary values during
    //function execution.
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future."
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    //the payable modifier allows a function to receive Ether
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        //we push the name and the amount in the corresponding arrays of the Campaign
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        //Here we actually send the amound from the donator to the owner of the campaign
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        //when the operation above is complete we increment the collected amount
        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    //Functions marked as view promise not to modify the state of the contract
    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        //we create an empty array with as many empty elements as there are actual campaigns
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        //then we fill the array with the campaigns from the mapping
        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}