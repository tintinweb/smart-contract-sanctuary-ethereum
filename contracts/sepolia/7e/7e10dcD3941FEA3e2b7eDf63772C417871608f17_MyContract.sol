// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountcollected;
        string image;
        address[]donators;
        uint256[]donations;
    }
     
          mapping(uint256=>Campaign) public campaigns;
          uint256 public  numberofCampaigns =0;// to keep track of number of campaigns initially it is zero\
          function createCampaign(address _owner,string memory _title,string memory _description,uint256 _target,string memory _image,uint256 _deadline)public returns(uint256){
            // this will return id's of the specific contract
          // create an campaign array to store it
          Campaign storage campaign=campaigns[numberofCampaigns];
           // check that is every thing is okay
           require(campaign.deadline<block.timestamp,"deadline should update");
           // block.timestamp is current time
           // meaning is if date of deadline is before or in past then we will post it as error
           // now else
            campaign.owner=_owner;
            campaign.title=_title;
            campaign.description=_description;
            campaign.target=_target;
            campaign.deadline=_deadline;
            campaign.amountcollected=0;
            campaign.image=_image;
            // wee can increment no.of campaign
            numberofCampaigns++;
            // if everything got as is should been then we will return the index of most recent camapign
            return numberofCampaigns-1;

          }

          function  donateToCampaign(uint256 _id)public payable {
            uint256 amount=msg.value;//frontend
            // now add campaign we want to donate it to
            Campaign storage campaign=campaigns[_id];
            campaign.donators.push(msg.sender);
            campaign.donations.push(amount);
              
              // now transaction
              (bool sent,)=payable(campaign.owner).call{value:amount}(" ");
              if(sent)
              {
                campaign.amountcollected=campaign.amountcollected+amount;

              }

          }

          function getDonators(uint256 _id) view public returns(address[]memory,uint256[]memory) {
            return(campaigns[_id].donators,campaigns[_id].donations);
          }

          function getCampaigns() public view returns (Campaign[]memory) {
            Campaign[] memory allCampaigns=new Campaign[](numberofCampaigns);
            for(uint i=0;i<numberofCampaigns;i++)
            {
              Campaign storage item=campaigns[i];
              allCampaigns[i]=item;
            }
            return allCampaigns;
          }



          
    }