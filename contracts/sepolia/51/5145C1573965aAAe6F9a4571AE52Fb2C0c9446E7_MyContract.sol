// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    struct Campaign {
        address owner;
        string name;
        string email;
        string website;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        string[] donorName;
        string[] donorMessage;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

   function createCampaign(address _owner, string memory _name, string memory _email, string memory _website, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256){
    Campaign storage campaign = campaigns[numberOfCampaigns];


    require(campaign.deadline < block.timestamp, "Deadline error!");
    campaign.owner = _owner;
    campaign.name = _name;
    campaign.email = _email;
    campaign.website = _website;
    campaign.title = _title;
    campaign.description = _description;
    campaign.target = _target;
    campaign.deadline = _deadline;
    campaign.amountCollected = 0;
    campaign.image = _image;

    numberOfCampaigns++;

    return numberOfCampaigns - 1;
   }

    function donateCampaign(uint256 _id, string memory _donorName, string memory _donorMessage) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donorName.push(_donorName);
        campaign.donorMessage.push(_donorMessage);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory, string[] memory, string[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations, campaigns[_id].donorName, campaigns[_id].donorMessage);
    }    

    function getCampaigns() public view returns (Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++){
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}