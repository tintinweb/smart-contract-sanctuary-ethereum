// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner; //owner's address
        string title; //title of the campaign for which funds are being raised
        string description; //description of the campaign for which the funds are being raised
        uint256 target; //target amount we want to raise
        uint256 deadline; //deadline of the campaign
        uint256 amountCollected; //amountCollected so far for the campaign
        string image; //for the url of the image
        address[] donators; //array of addresses of the donators or backers
        uint256[] donations; //array of actual donation amounts
    }

    mapping(uint256 => Campaign) public campaigns; //mapping of structures to access individual structure

    uint256 public numberOfCampaigns = 0; //global variable marking the number of campaigns

    // ================== FUNCTION ==================
    //this function is basically taking all parameters and returns the id of that campaign
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        //creating a campaign
        Campaign storage campaign = campaigns[numberOfCampaigns];

        //deadline shouldn't be from past
        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future."
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0; //at the beginning the amount collected is 0
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1; //returns the index of the most newly created campaign
    }

    // ================== FUNCTION ==================
    //this function donates the amount to the campaign
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value; //amount that we will be sending from the front-end

        Campaign storage campaign = campaigns[_id]; //id of the struct that is representing the campaign that we are donation to

        campaign.donators.push(msg.sender); //push the address of the sender in the donators array in the campaign struct
        campaign.donations.push(amount); //push the amount that the backer has donated in the donations array in the campaign struct

        //making transaction ↓↓↓
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");
        //sent is variable that will make sure if transaction is happening or not in true or false.
        //payable returns two different values so to account for that, we have that "," saying that we expect something else.
        //we are paying to the owner of the campaign
        //we are sending the amount in the call()

        //checking if the amount sent ↓↓↓
        if (sent) {
            campaign.amountCollected += amount; //once transaction is successful, we increment the amountCollected
        }
    }

    // ================== FUNCTION ==================
    //this function gets all the donators of a specific campaign
    //the fuction takes the id of the contract and returns array of addresses of donators and array of amounts of donations
    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    // ================== FUNCTION ==================
    //this function is used to get all the campaigns and it returns an array of structs Campaign
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        //↑↑↑ This is creating a new array of structures named "allCampaigns" but the size of that array equal to the "numberOfCampaigns" that are exisiting currently. However note that this array of structures is empty currently.
        //So suppose if there are 4 campaigns so far then "allCampaigns" will be: [{},{},{},{}]

        //now we loop through all the campaigns and populate "allCampaigns"
        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}