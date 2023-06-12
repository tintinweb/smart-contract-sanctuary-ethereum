// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract KickStarter {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        mapping(address => uint256) donations;
        address[] donators;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];
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

    function donateToCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline > block.timestamp, "The campaign deadline has passed.");

        uint256 amount = msg.value;
        campaign.donators.push(msg.sender);
        campaign.donations[msg.sender] += amount;

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");
        require(sent, "Failed to send funds to the campaign owner.");

        campaign.amountCollected += amount;
    }

    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        Campaign storage campaign = campaigns[_id];
        address[] memory donators = new address[](campaign.donators.length);
        uint256[] memory donations = new uint256[](campaign.donators.length);

        for (uint256 i = 0; i < campaign.donators.length; i++) {
            donators[i] = campaign.donators[i];
            donations[i] = campaign.donations[campaign.donators[i]];
        }

        return (donators, donations);
    }

    function getCampaigns() public view returns (
        address[] memory,
        string [] memory,
        string [] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        string [] memory
        ) 
    {
        address[] memory owners = new address          [](numberOfCampaigns);
        string [] memory titles = new string           [](numberOfCampaigns);
        string [] memory descriptions = new string     [](numberOfCampaigns);
        uint256[] memory targets = new uint256         [](numberOfCampaigns);
        uint256[] memory deadlines = new uint256       [](numberOfCampaigns);
        uint256[] memory amountsCollected = new uint256[](numberOfCampaigns);
        string [] memory images = new string           [](numberOfCampaigns);

    for (uint256 i = 0; i < numberOfCampaigns; i++) {
        Campaign storage item = campaigns[i];

        owners[i] = item.owner;
        titles[i] = item.title;
        descriptions[i] = item.description;
        targets[i] = item.target;
        deadlines[i] = item.deadline;
        amountsCollected[i] = item.amountCollected;
        images[i] = item.image;
        }

    return (owners, titles, descriptions, targets, deadlines, amountsCollected, images);
    }
    
    function deleteCampaign(uint256 _id) public {
      Campaign storage campaign = campaigns[_id];
      require(campaign.owner == msg.sender, "Only the owner can delete this campaign.");

      delete campaigns[_id];
      numberOfCampaigns--;
    }
}