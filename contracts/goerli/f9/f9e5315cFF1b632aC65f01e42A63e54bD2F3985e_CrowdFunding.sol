// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner; //Address of the owner of the campaign
        string title; //Title of the campaign
        string description; //description of the campaign
        uint256 target; //Target amount the the campaign needs to achieve
        uint256 deadline; //Deadline of the campaign
        uint256 amountCollected; //Amount collected for the campaign
        string image; //Banner of the campaign (we are using string for image because we will be giving a url for the image)
        address[] donators; //Array consisting of the donators
        uint256[] donations; //Array consisting of each individual donation
    }

    mapping(uint256 => Campaign) public campaigns; //Creating a List of campaigns to keep track and indexing

    uint256 public numberOfCampaigns = 0; //keeping track of the number of campaigns to give them IDs

    //Function to create or add a campaign which returns the ID of the campaign once created
    function createCampaign(address _owner,string memory _title,string memory _description,uint256 _target,uint256 _deadline,string memory _image) public returns (uint256) {

        Campaign storage campaign = campaigns[numberOfCampaigns]; //creating a new object of type Campaign with name campaign and stored in campaigns at index numberOfCampaigns

        require(
            campaign.deadline < block.timestamp,
            "THe deadline should be a date in the future."
        ); //if deadline of campaign is in the past (less than the timestamp of the block) then the function won't go any further and return the error message

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.image = _image;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    //Function to Donate to the Campaign
    function donateToCampaign(uint256 _id) public payable {
        //This function takes the ID of the campaign that the donator wants to donate to and is payable, meaning that amount can be tranferred

        uint256 amount = msg.value; //We will get this from the Frontend

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender); //msg.sender will give the address of the sender and will be stored in the donators array of the campaign
        campaign.donations.push(amount); //Pushing the amount to keep track of donations

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    //Function to get the list of donators
    function getDonators(uint256 _id) view public returns(address[] memory,uint256[] memory) { //address[] will be donators 
        return(campaigns[_id].donators,campaigns[_id].donations);
    }

        //Function to get the list of all Campaigns
    function getCampaigns()public view returns(Campaign[] memory) {
        Campaign[] memory allCampaigns=new Campaign[](numberOfCampaigns);

        for(uint i=0;i<numberOfCampaigns;i++)
        {
            allCampaigns[i]=campaigns[i];
        }
        return allCampaigns;
    }

    function deleteCampaign(uint256 _id) public {
    require(campaigns[_id].owner == msg.sender, "Only the campaign owner can delete the campaign");
    
    delete campaigns[_id];
}

}