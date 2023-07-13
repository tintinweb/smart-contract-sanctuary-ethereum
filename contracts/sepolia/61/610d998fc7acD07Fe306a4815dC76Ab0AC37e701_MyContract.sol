// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amount_collected;
        string image;
        address[] donators;
        uint256[] donation;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numbers_of_compaigns = 0;

    function create_campaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage campaign = campaigns[numbers_of_compaigns]; //mapping
        campaign.deadline = _deadline;
        require(
            campaign.deadline < block.timestamp,
            "the deadline should be a date in the future."
        );
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.amount_collected = 0;
        campaign.image = _image;

        numbers_of_compaigns++;

        return numbers_of_compaigns - 1;
    }

    function donate_to_campaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donation.push(amount);

        (bool send, ) = payable(campaign.owner).call{value: amount}("");
        if (send) {
            campaign.amount_collected = campaign.amount_collected + amount;
        } else {
            revert("!! transaction_failed !!");
        }
    }

    function get_Donators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donation);
    }

    function get_Campaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allcampaigns = new Campaign[](numbers_of_compaigns);

        for (uint i = 0; i < numbers_of_compaigns; i++) {
            Campaign storage item = campaigns[i];

            allcampaigns[i] = item;
        }
        return allcampaigns;
    }
}