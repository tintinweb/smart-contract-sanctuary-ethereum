// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Funding {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        uint256 deadline;
        string image;
        address[] donators;
        uint[] donations;
    }

    mapping(uint256=>Campaign) public Campaigns;
    uint public numberOfCampaigns=0;

    function createCampaign(address _owner,string memory _title,string memory _description,string memory _image, uint256 _deadline, uint256 _target)public returns(uint256)
    {
        Campaign storage campaign=Campaigns[numberOfCampaigns];

        campaign.owner=_owner;
        campaign.title=_title;
        campaign.description=_description;
        campaign.target=_target;
        campaign.deadline=_deadline;
        campaign.image=_image;
        campaign.amountCollected=0;

        numberOfCampaigns++;

        return numberOfCampaigns-1;
    }
    function donateToCampaign(uint256 _id) public payable {
       uint amount = msg.value;
       Campaign storage campaign=Campaigns[_id];
       campaign.donators.push(msg.sender);
       campaign.donations.push(amount);

       (bool sent,) = payable(Campaigns[_id].owner).call{value:amount}(" ");

       if(sent)campaign.amountCollected=campaign.amountCollected+amount;
    }
    function getDonators(uint256 _id) view public returns(address[] memory,uint256[] memory)
    {
        return (Campaigns[_id].donators,Campaigns[_id].donations);
    }
    function getCampaigns() view public returns(Campaign[]memory){
      Campaign[] memory allCampaigns=new Campaign[](numberOfCampaigns);

      for(uint i=0;i<numberOfCampaigns;i++){
        allCampaigns[i]=Campaigns[i];
      }

      return allCampaigns;
    }
}