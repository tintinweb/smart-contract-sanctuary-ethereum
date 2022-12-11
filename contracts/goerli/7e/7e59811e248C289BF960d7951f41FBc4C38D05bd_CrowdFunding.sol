// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    constructor() {}

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 cap;
        uint256 deadline;
        uint256  amountRaised;
        string img;
        address[] fundRaisers;
        uint256[] NumberOfDonation;
    }

    uint256 public NumberOfCampaigns;
    mapping(uint256 => Campaign) public campaigns;

    function createCampaign(address _owner, string memory _title, string memory _description, uint _cap, uint _deadline, string memory _img) public returns (uint256){
        Campaign storage campaign = campaigns[NumberOfCampaigns];
        require(campaign.deadline < block.timestamp, 'campaign is over');
        campaign.owner = _owner;
        campaign.title= _title;
        campaign.description = _description;
        campaign.cap = _cap;
        campaign.deadline = _deadline;
        campaign.img = _img;
        campaign.amountRaised = 0;

        NumberOfCampaigns++;

        return NumberOfCampaigns -1;
    }

    function purchaseForCampaign(uint _id) public payable{
        uint amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.fundRaisers.push(msg.sender);
        campaign.NumberOfDonation.push(amount);
        (bool success,) = payable(campaign.owner).call{value: amount}('');
        if(success) {
            campaign.amountRaised = campaign.amountRaised + amount;
        }
    }
    function getFundRaisers(uint256 _id) public view returns (address[] memory, uint256[] memory){
        return (campaigns[_id].fundRaisers, campaigns[_id].NumberOfDonation);
    }
    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](NumberOfCampaigns);

        for(uint i = 0; i < NumberOfCampaigns; i++){
            allCampaigns[i] = campaigns[i];
        }
        return allCampaigns;
    }


}