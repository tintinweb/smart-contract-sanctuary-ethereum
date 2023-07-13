// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFund {

    struct Campaign{
        address owner;
        string title;
        string description;
        uint target;
        uint deadline;
        uint amountCollected;
        string image;
        address[] donators;
        uint[] donations;


    }

    mapping(uint => Campaign) public campaigns;

    uint public numberofCampaigns = 0;

    function createCampaign(address _owner,string memory _title,string memory _description
     , uint _target, uint _deadline,string memory _image) public returns(uint) {

        Campaign storage campaign = campaigns[numberofCampaigns];
        require(campaign.deadline < block.timestamp,"Deadline must be a future date");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberofCampaigns++;

        return numberofCampaigns-1;


    }

    function donateToCampaign(uint _id) public payable {
        uint amount = msg.value;
        Campaign storage camp = campaigns[_id];
        camp.donators.push(msg.sender);
        camp.donations.push(amount);

        (bool sent, ) = payable(camp.owner).call{value:amount}("");

        if(sent){
            camp.amountCollected = camp.amountCollected + amount;
        }
    }

    function getDonators(uint _id) public view returns(address[] memory,uint[] memory) {

        return (campaigns[_id].donators , campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory){

        Campaign[] memory allCampains = new Campaign[](numberofCampaigns);

        for(uint i=0;i<numberofCampaigns ;i++)
        {
            Campaign storage item = campaigns[i];
            allCampains[i] = item;
        }

        return allCampains;
    }


     
}