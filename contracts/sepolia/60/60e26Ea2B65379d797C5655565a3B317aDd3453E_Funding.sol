// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 ammountCollected;
        uint256 deadline;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping (uint256 => Campaign) public campaigns;

    uint public numberofCampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target,uint256 _deadline, string memory _image) public returns (uint256 ){
        Campaign storage campaign =  campaigns[numberofCampaigns];
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.deadline = _deadline;
        campaign.target = _target;
        campaign.image = _image;

        numberofCampaigns++;

        return numberofCampaigns-1;
          
    }
    function donateCampaign(uint256 _id) public payable{
        uint amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaigns[_id].owner).call{value:amount}("");
        if(sent) campaign.ammountCollected += amount;
    

    }

    function getDonators(uint256 _id) view public returns(address[] memory , uint256[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations);

    }

    function getCampaign()view public returns(Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

        for(uint i=0;i<numberofCampaigns;i++){
            allCampaigns[i] = campaigns[i];

        }
        return allCampaigns;

    }

}