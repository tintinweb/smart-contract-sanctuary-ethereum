// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {

    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountcollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping (uint256 =>Campaign) public campaigns;
    uint256 public number_of_Campaigns=0;


    function create_campaign(address _owner,
                            string memory _title,
                            string memory _description,
                            uint256 _target,
                            uint256 _deadline,
                            string memory _image)public returns (uint256)
    {
        Campaign storage campaign=campaigns[number_of_Campaigns];
// is everything good
// check if deadline in the future
        require(campaign.deadline<block.timestamp, "the deadline should be in the future");
        campaign.owner=_owner;
        campaign.title=_title;
        campaign.description=_description;
        campaign.target=_target;
        campaign.deadline=_deadline;
        campaign.image=_image;
        campaign.amountcollected=0;
        number_of_Campaigns++;

        return number_of_Campaigns-1;



    }
// deside whoom to donate
    function donate_to_campaign(uint256 _id)public payable{
        uint256 amount=msg.value;
        Campaign storage campaign=campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
//now sending the money
        (bool sent,)=payable(campaign.owner).call{value: amount}("");
        if(sent){
            campaign.amountcollected+=amount;
        }

        

    }
// get the donators and their contribution for the particular campaign
    function getdonators(uint256 _id)view public returns(address[]memory,uint256[]memory){
        return (campaigns[_id].donators, campaigns[_id].donations);

    }
    function getCampaigns()public view returns(Campaign[] memory){
        // we have empty array of that many struct that we have the number of campains
        Campaign[] memory allcampaigns=new Campaign[](number_of_Campaigns);

        // traverse through the campain map
        for(uint i=0 ;i<number_of_Campaigns;i++){
            Campaign storage item=campaigns[i];

            allcampaigns[i]=item;
        }
        return allcampaigns;




    }






    constructor() {}
}