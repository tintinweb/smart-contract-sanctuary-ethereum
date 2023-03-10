pragma solidity ^0.8.18;

contract DonationCampaign {
    struct  Campaign{
        uint256 id;
        string name;
        string description;
        uint256 goalAmount;
        uint256 raisedAmount;
        uint256 deadline;
        address creator;
        address[] donors;
        bool isActive;
        string imageUrl;
        uint256 createdAt;
        uint256 updatedAt;
    }

    Campaign[] public campaigns;

    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _goalAmount,
        uint256 _deadline,
        string memory _imageUrl
       
    ) public {
        uint256 campaignId = campaigns.length;
        campaigns.push(Campaign(
            campaignId,
            _name,
            _description,
            _goalAmount,
            0,
            _deadline,
            msg.sender,
            new address[](0),
            true,
            _imageUrl,
            block.timestamp,
            block.timestamp
        ));
    }

    function donateToCampaign(uint256 _campaignId) public payable {
        require(_campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.isActive, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign deadline has passed");
        campaign.raisedAmount += msg.value;
        campaign.donors.push(msg.sender);
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }

    function getDonators(uint256 campaignId) public view returns (address[] memory) {
    require(campaignId < campaigns.length, "Invalid campaign ID");
    
    return campaigns[campaignId].donors;
    }

}