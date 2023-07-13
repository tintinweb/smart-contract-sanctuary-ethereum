// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Charity {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint expected_amt;
        uint deadline;
        uint amountCollected;
        string image;
        address[] donators;
        uint[] donations;
    }
    mapping(uint => Campaign) public campaigns;

    uint public numberofCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint _expectedAmt,
        uint _deadline,
        string memory _image
    ) public returns (uint) {
        Campaign storage campaign = campaigns[numberofCampaigns];
        require(campaign.deadline < block.timestamp, "incorrect time");
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.expected_amt = _expectedAmt;
        campaign.deadline = _deadline;
        campaign.image = _image;

        numberofCampaigns++;
        return numberofCampaigns - 1;
    }

    function donateToCampaign(uint _id) public payable {
        uint amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function donatorsList(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);
        for (uint i = 0; i < numberofCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}