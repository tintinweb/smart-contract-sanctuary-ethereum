// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract FundRaiser {
    struct Campaign{
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

    mapping(uint256 => Campaign) public campaigns; // campaigns[0] = {structure values}

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256){
        Campaign storage campaign =  campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;
        campaign.amountCollected = 0;

        numberOfCampaigns++;

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future");  //block.timestamp returns current time of the block in the blockchain

        return numberOfCampaigns-1;  //As the Id of the campaign
    }

    function donateToCampaign(uint256 _id) payable public{
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        //Paying the owner of the campaign

        (bool sent,) = payable(campaign.owner).call{value: amount}("");  //To send ether

        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory){
        Campaign storage campaign = campaigns[_id];
        return (campaign.donators,campaign.donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
    Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // A new array called allCampaigns in initialized with the same size as numberOfCampaigns

    for(uint i = 0; i < numberOfCampaigns; i++) {
        Campaign storage item = campaigns[i];
        allCampaigns[i] = item;
    }

    return allCampaigns;
}
}