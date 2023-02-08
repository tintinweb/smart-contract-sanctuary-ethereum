// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "github.com/Michealleverton/ownable.sol/blob/main/Ownable.sol";

contract BlockPartyFunding is Ownable {
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

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future");

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
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return(campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    // Only the owner can call this function which will send remaining balance to the owner
    function WithdrawlFunds() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Ownable {
    
    // All veriables will be here
    address owner;

    // constructor is run upon contract being deployed and is only run once
    constructor() {
        owner = msg.sender;
    }

    // Modifiers are used to store a specific parameters that will be called
    // multiple times in a contract. Allowing you to only have to write it once.
    modifier onlyOwner() {
        require(msg.sender == owner, "YOU MUST BE THE OWNER TO DO THAT. SORRY!");
        _;
    }
}