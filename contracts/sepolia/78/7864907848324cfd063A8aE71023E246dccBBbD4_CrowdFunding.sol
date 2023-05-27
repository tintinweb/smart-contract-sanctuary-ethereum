// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        uint256 id;
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        uint256 category;
        address[] donators;
        uint256[] donations;
        uint256[] commissions;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        uint256 _category,
        string memory _image
    ) public returns (uint256) {
        uint256 newId = numberOfCampaigns;
        Campaign storage campaign = campaigns[newId];

        require(
            _deadline / 1000 > block.timestamp,
            "The deadline should be a date in the future."
        );
        campaign.id = newId;
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.category = _category;

        numberOfCampaigns++;

        return newId;
    }

    function donateToCampaign(
        uint256 _id,
        address _commissionAddress
    ) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        require(
            campaign.deadline > block.timestamp,
            "The deadline for this campaign has already passed."
        );

        uint256 commission = (amount * 10) / 100; // Calculate 10% commission
        uint256 donationAmount = amount - commission;

        campaign.donators.push(msg.sender);
        campaign.donations.push(donationAmount);
        campaign.commissions.push(commission);

        (bool sent, ) = payable(campaign.owner).call{value: donationAmount}("");

        require(sent, "Failed to send Ether to campaign owner.");

        (bool commissionSent, ) = payable(_commissionAddress).call{
            value: commission
        }("");

        require(commissionSent, "Failed to send commission.");

        campaign.amountCollected += donationAmount;
    }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        Campaign storage campaign = campaigns[_id];
        uint256 numDonators = campaign.donators.length;

        address[] memory donators = new address[](numDonators);
        uint256[] memory donations = new uint256[](numDonators);

        for (uint256 i = 0; i < numDonators; i++) {
            donators[i] = campaign.donators[i];
            donations[i] = campaign.donations[i];
        }

        return (donators, donations);
    }

    function getAllDonationsForCampaigns()
        public
        view
        returns (
            Campaign[] memory,
            address[] memory,
            address[][] memory,
            uint256[][] memory,
            uint256[][] memory
        )
    {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        address[] memory authors = new address[](numberOfCampaigns);
        address[][] memory allDonators = new address[][](numberOfCampaigns);
        uint256[][] memory allDonations = new uint256[][](numberOfCampaigns);
        uint256[][] memory allCommissions = new uint256[][](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];
            uint256 numDonators = campaign.donators.length;

            address[] memory donators = new address[](numDonators);
            uint256[] memory donations = new uint256[](numDonators);
            uint256[] memory commissions = new uint256[](numDonators);

            for (uint256 j = 0; j < numDonators; j++) {
                donators[j] = campaign.donators[j];
                donations[j] = campaign.donations[j];
                commissions[j] = campaign.commissions[j];
            }

            allCampaigns[i] = campaign;
            authors[i] = campaign.owner;
            allDonators[i] = donators;
            allDonations[i] = donations;
            allCommissions[i] = commissions;
        }

        return (
            allCampaigns,
            authors,
            allDonators,
            allDonations,
            allCommissions
        );
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function getCampaignById(
        uint256 _id
    ) public view returns (Campaign memory) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");

        return campaigns[_id];
    }
}