// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
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
    mapping (uint256=>Campaign)public campaigns;
    uint256 public numberOfCampaigns=0;


    //this function helps you to create campaings take all the necessary param and return numbner of campaign
    function createCampaign(address _owner,string memory _title,string memory _description, uint256 _target,uint256 _deadline,string memory _image) public returns (uint256){
        Campaign storage campaign=campaigns[numberOfCampaigns];
        
        //checking is everything ok?!
            require(campaign.deadline< block.timestamp,"The deadline be a date in the future");
            
            //filling up the struct 
            campaign.owner=_owner;
            campaign.title=_title;
            campaign.description=_description;
            campaign.target=_target;
            campaign.deadline=_deadline;
            campaign.amountCollected=0;
            campaign.image=_image;

            numberOfCampaigns++;

            return numberOfCampaigns-1;

    }

    //this function will take campaign id (basically numberofCampaigns) as an input and collect the amount paid and his address and push that inside the struct array . also add the amount with the amountCollected
    function donateCampaign(uint256 _id) public payable{
        uint256 amount=msg.value;
        Campaign storage campaign=campaigns[_id];

        //we want to push the address of the person who donated
        campaign.donators.push(msg.sender);

        //we also want to push the amount(donation) of that person
        campaign.donations.push(amount);

        //checking whether the transaction is send or not 
        (bool sent,)=payable(campaign.owner).call{value:amount}("");

        //if the donar successfully send then stores the total amount recieved by that campaign 
        if (sent){
            campaign.amountCollected=campaign.amountCollected+amount;

        }

    }

    //fetch all the donators
    //we are passing the campaign id and returning all the donators address as well as there donations
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory){
        return (campaigns[_id].donators,campaigns[_id].donations);
    }

    //this function will return all the  campaigns created till now
    function getCampaign() public view returns (Campaign[] memory){
        //it stores all the campaign which has been created till now
        Campaign[] memory allCampaigns=new Campaign[](numberOfCampaigns);

        for (uint i=0;i<numberOfCampaigns;i++){

            Campaign storage item=campaigns[i];
            allCampaigns[i]=item;

        }
        return allCampaigns;
    }
}