// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract crowdFunding {
    struct Compaign{
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
    mapping(uint256 => Compaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCompaign(address owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns(uint256)
    {
        Compaign storage compaign = campaigns[numberOfCampaigns];
        require(compaign.deadline < block.timestamp, "Deadline must be greater than current time");
        compaign.owner = owner;
        compaign.title = _title;
        compaign.description = _description;
        compaign.target = _target;
        compaign.deadline = _deadline;
        compaign.image = _image;
        compaign.amountCollected = 0;
        numberOfCampaigns++;
        return numberOfCampaigns -1;
    } // create a compaign
    function donateToCompaign( uint256 _id ) public payable{
        uint256 amount = msg.value;
        Compaign storage compaign = campaigns[_id];
        require(compaign.deadline > block.timestamp, "Deadline must be greater than current time");
        
        compaign.donators.push(msg.sender);
        compaign.donations.push(amount);

        (bool sent, ) = payable(compaign.owner).call{value: amount}("");
        if(!sent){
            revert("Failed to send Ether");
        }
        compaign.amountCollected += amount;
    } // donate to a compaign
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations);
    } // get all donators of a compaign
    function getCampaigns() public view returns(Compaign[] memory)
    {
        Compaign[] memory allCampaigns = new Compaign[](numberOfCampaigns);
        for(uint256 i = 0; i < numberOfCampaigns; i++){
            allCampaigns[i] = campaigns[i];
        }
        return allCampaigns;
    } // get all campaigns
}