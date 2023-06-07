// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding
{
    struct Campaign
    {
      address owner;
      string title;
      string description;
      uint256 target_amount;
      uint256 deadline;
      uint256 amount_collected;
      string image;
      address[] donators;
      uint256[] donations;
    }
    mapping (uint256 => Campaign) public campaigns;
    uint256 public no_of_campaigns=0;


    function create_campaign(address _owner,string memory _title,string memory _description,
    uint256 _target,uint256 _deadline,string memory _image) public returns(uint256)
    {
        Campaign storage campaign=campaigns[no_of_campaigns];
        // check for date should be after 
        require(campaign.deadline<block.timestamp,"The deadline should be date in future ");

        // initializing the details of the contract 
        campaign.owner=_owner;
        campaign.title=_title;
        campaign.description=_description;
        campaign.target_amount=_target;
        campaign.deadline=_deadline;
        campaign.amount_collected=0;
        campaign.image=_image;

        no_of_campaigns++;

        return no_of_campaigns-1;  // index of latest created contract

    }

    function donate_to_campaign(uint256 _id)public payable    // payable function means we are allowed to send ethers to this function
    {
       uint256 amount=msg.value; // amount to be donated is equal to the msg value 
       Campaign storage campaign=campaigns[_id];  // getting the campaign to which we wwant to donate

       
       campaign.donators.push(msg.sender);  // adding the donator
       campaign.donations.push(msg.value); // adding the amount the respective donator donated

       (bool sent,)=payable(campaign.owner).call{value:amount}("");
       if(sent)
       campaign.amount_collected+=amount;

    }
    function get_donators(uint256 _id) view public returns(address[] memory,uint256[] memory)
    {
        Campaign storage campaign=campaigns[_id];
        return(campaign.donators,campaign.donations);
       
    }

    function get_campaigns() view public returns(Campaign[] memory)
    {
         Campaign[] memory allcampaigns=new Campaign[](no_of_campaigns);
         for(uint256 i=0;i<no_of_campaigns;i++)
         {
            allcampaigns[i]=campaigns[i];
         }
         return allcampaigns;

    }



}