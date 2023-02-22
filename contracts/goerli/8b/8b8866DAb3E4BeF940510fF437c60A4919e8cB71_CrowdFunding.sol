// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    /* a struct which stores the following information
    1. owner (address) 
    2. title (string)
    3. description (string)
    4. target (uint256)
    5. deadline (uint256)
    6. amountCollected (uint256)
    7. image (string)
    8. donators address[]
    9. donations uint256[]
     **/
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

    // function which creates a campaign
    // returns id of the campaign created
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        // reference to the Compaign instead of copying the campaign
        Campaign storage campaign = campaigns[numberOfCampaigns]; // a new campaign has been created

        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future"
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    // function which donates to a the campaign
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value; // amount which msg.sender sent

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        require(sent, "Transaction failed");

        campaign.amountCollected += amount;
    }

    // function which gets the donators of a campaign
    function getDonators(uint256 _id)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        Campaign memory campaign = campaigns[_id];

        return (campaign.donators, campaign.donations);
    }

    // function which gets all the campaigns which are live
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory campaignsToBeReturned = new Campaign[](
            numberOfCampaigns
        );

        for (uint256 idx; idx < numberOfCampaigns; idx++) {
            campaignsToBeReturned[idx] = campaigns[idx];
        }

        return campaignsToBeReturned;
    }
}