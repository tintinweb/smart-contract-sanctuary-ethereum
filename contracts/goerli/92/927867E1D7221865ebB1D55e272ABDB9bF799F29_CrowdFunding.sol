// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 adharNum;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(address => uint256) public Adhar;
   


    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description,uint256 _adharNum, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");
        require(Adhar[msg.sender] == _adharNum , "do kyc verification first");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.adharNum = _adharNum;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function getValidation()public view {
       require(Adhar[msg.sender] != 0,"Not Completed"); 
    
    }

    function getAdhar()public view returns(uint256) {
       return Adhar[msg.sender];
    }

    function AdharVerification(uint256 num)public returns(bool)
    {
        require(Adhar[msg.sender] == 0,"You have already completed the KYC verification");
        Adhar[msg.sender] = num;
        return true; 
        
    }
   
    function donateToCampaign(uint256 _id) public payable {
         require((campaigns[_id].target-campaigns[_id].amountCollected) > 0,"Taget achieved");
         require((campaigns[_id].target-campaigns[_id].amountCollected) >= msg.value,"plz check the target value");

         uint256 amount = msg.value;
         Campaign storage campaign = campaigns[_id];
         campaign.donators.push(msg.sender);
         campaign.donations.push(amount);
         (bool sent,) = payable(campaign.owner).call{value: amount}("");
         if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
         }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
         Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

         for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
         }

         return allCampaigns;
    }
}