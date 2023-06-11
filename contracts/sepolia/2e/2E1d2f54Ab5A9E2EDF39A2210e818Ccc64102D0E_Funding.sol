// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        uint256 deadline;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public camppaigns;

    uint public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        string memory _image,
        uint256 _deadline,
        uint256 _target
    ) public returns (uint256) {
        Campaign storage campaigne = camppaigns[numberOfCampaigns];
        campaigne.owner = _owner;
        campaigne.title = _title;
        campaigne.description = _description;
        campaigne.target = _target;
        campaigne.deadline = _deadline;
        campaigne.image = _image;
        campaigne.amountCollected = 0;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }


    function donateToCampaign(uint256 _id) public payable {
        uint amount = msg.value;
        Campaign storage campaign = camppaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(camppaigns[_id].owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }


    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (camppaigns[_id].donators, camppaigns[_id].donations);
    }


    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            allCampaigns[i] = camppaigns[i];
        }
        return allCampaigns;
    }
    
}