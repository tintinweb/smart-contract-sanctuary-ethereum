// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Raisefund {
    struct Campaign{
        address owner;
        string title;
        string discription;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations; 

    }

    mapping(uint256 => Campaign) public Campaigns; //accessing Campaign

    uint256 public numberofCampaigns=0; 

    function createCampaign(address owner, string memory title, string memory discription, uint256 target, uint256 deadline, string memory image ) public returns (uint256) {
         Campaign storage Campaign = Campaigns[numberofCampaigns];

         require(Campaign.deadline < block.timestamp,"the deadline should be a date.");
                Campaign.owner=owner;
                Campaign.target=target;
                Campaign.title=title;
                Campaign.deadline=deadline;
                Campaign.amountCollected = 0;
                Campaign.image=image;

                numberofCampaigns++;

                return(numberofCampaigns-1);


    }

    function donateToCampaign(uint256 id) public payable {      //payable=sends crypto currency
           uint256 amount= msg.value;
        Campaign storage Campaign =Campaigns[id];

           Campaign.donators.push(msg.sender); //push address
           Campaign.donations.push(amount);

            (bool sent,) =payable(Campaign.owner).call{value: amount}("");      //payable returns two things
            if(sent){
                Campaign.amountCollected= Campaign.amountCollected+amount;
            }
    }          

    function getDonators(uint256 id) view public returns(address[] memory,uint256[] memory) {
       return(Campaigns[id].donators,Campaigns[id].donations);
    }

    function getCampaign() public view returns(Campaign[] memory){      //no parameters because we want to return all funcitons
             Campaign[] memory allCampaigns = new Campaign[](numberofCampaigns);

            for(uint i=0;i<numberofCampaigns;i++){
                Campaign storage item=Campaigns[i];

                allCampaigns[i]=item;

            }
            return(allCampaigns);

    }

    
}