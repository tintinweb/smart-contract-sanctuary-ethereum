// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        // uint256 is number in python
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        // address[] means an array of address
        address[] donators;
        uint256[] donations;
    }


    mapping(uint256 => Campaign) public campaigns;

//keep track of numberOfCampaigns to create ids
    uint256 public numberOfCampaigns = 0;

//_owner the underscore is to show that the the parameters is for that specific function 
//sting paramerters always use memory
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        //is everything okay?
        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

//payable is a function that signified that we're sending cryptocurrency throughout this function
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.owner).call{value: amount}("");
    
        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

//view means it's going to return some data to be able to view it
//the array of address of donators and the array of address of donations from the struct campaign
    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory){
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

//no parameters because we want to get all campaigns
//this function is used to fetch all the campaigns from memory
    function getCampaigns() public view returns (Campaign[] memory) {
        // in here, we're creating a new variable called allCampaigns which is of a type array of multiple campaign structure
        // we're creating an empty array with as many empty elements as there are actaul campaigns
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            //fetching a specific campaign from storage
            Campaign storage item = campaigns[i];

            //populate that item into the array in allCampaigns that was previously created
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

}