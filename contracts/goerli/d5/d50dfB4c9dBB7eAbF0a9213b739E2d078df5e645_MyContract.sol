// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    //CrowdFunding


    struct Campaign{
       address owner;
       string title;
       string description;
       uint256 target;
       uint256 deadline;
       string image;
       uint256 currentDonation;
       address[] donater;
       uint256[] donation;
    }

    //mapping
    mapping(uint256=>Campaign) public campaigns;

    uint256 public indexing = 0;


    //CreateCampaign
        function createCampaign(string memory _title,string memory _description,uint256 _target,uint256 _deadline,string memory _image) public returns(uint256)
        {   

            Campaign storage newCampaign = campaigns[indexing];
            newCampaign.owner = msg.sender;
            newCampaign.title = _title;
            newCampaign.description = _description;
            newCampaign.target = _target;
            newCampaign.deadline = _deadline;
            newCampaign.image = _image;
            indexing++;
            return indexing - 1;
        }
    // GetDonation
        function getPaid(uint256 _id,uint256 _amount) public payable {
            Campaign storage getdonate = campaigns[_id];
            uint256 amount = _amount;

            require(campaigns[_id].deadline>block.timestamp,"Invalid date");
            getdonate.donater.push(msg.sender);
            getdonate.donation.push(amount);

            (bool sent,) = payable(getdonate.owner).call{value: amount}("");
            if(sent)
            {
                getdonate.currentDonation = getdonate.currentDonation + amount;
            }
        }
    // GetDonators
        function getDonater(uint256 _id) public view returns(address[] memory _donater,uint256[] memory _donation)
        {
            return(campaigns[_id].donater,campaigns[_id].donation);
        }   
    // GetCampaigns
        function getCampaign() public view returns(Campaign[] memory)
        {
            Campaign[] memory allCampaign = new Campaign[](indexing);
// 
            for(uint i=0;i<indexing;i++)
            {
                Campaign storage item = campaigns[i];
                allCampaign[i] = item;
            }

            return allCampaign;
        }
}