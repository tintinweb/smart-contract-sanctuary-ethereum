// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract fund {
    struct Campaign {
        address Owner;
        string title;
        string description;
        uint256 target;
        uint256 amountCollected;
        string imageUrl;
        uint256 deadline;
        address[] donators; // array of the donators
        uint256[] donations; // array of the donation
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberofcampaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline,string memory _imageUrl) public returns (uint256){
        Campaign storage campaign = campaigns[numberofcampaigns];

        // is everything ok ?
        require(campaign.deadline < block.timestamp, "Deadline must be set to the future date");

        campaign.Owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.imageUrl = _imageUrl;

        numberofcampaigns++;

        return numberofcampaigns-1;


    }

    function donateToCampaign(uint256 _id)public payable{
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,) = payable(campaign.Owner).call{value: amount}("");

        if (sent){
            campaign.amountCollected = campaign.amountCollected + amount;


        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory){
        return(campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns()public view returns (Campaign[] memory){


        Campaign[] memory allCampaigns = new Campaign[](numberofcampaigns); // allCampaigns is a new variable which is type of array of multiple campaign structures. WITh this  we re not getting the campaigns instead we re creating an empty array with as many element as that of the structure(the number of campaigns).

        for (uint i =0; i<numberofcampaigns; i++){
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;



    }

}