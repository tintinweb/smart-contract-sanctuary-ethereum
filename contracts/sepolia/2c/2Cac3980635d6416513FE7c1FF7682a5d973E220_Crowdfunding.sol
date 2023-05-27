// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding{
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
    

    
    mapping (uint256 => Campaign) public campaigns;

    uint256 public no_of_compaigns=0;

    function createCompaign(address _owner,string memory _title,string memory _description,uint256 _target,uint256 _deadline,
    uint256 _amountCollected,string memory _image) public returns(uint256){

        Campaign storage campaign = campaigns[no_of_compaigns];

        require(campaign.deadline < block.timestamp , "The deadline be should be the date in future");
        
        campaign.owner=_owner;
        campaign.title=_title;
        campaign.description=_description;
        campaign.target=_target;
        campaign.deadline=_deadline;
        campaign.amountCollected=_amountCollected;
        campaign.image=_image;

        no_of_compaigns++;

        return no_of_compaigns-1;
    }

    function donateToCompaign(uint256 _id) public payable {
        uint256 amount_want_to_sent = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        
        campaign.donations.push(amount_want_to_sent);

        (bool sent,) = payable(campaign.owner).call{value:amount_want_to_sent}("");
        
        require(sent, "Failed to send funds to the campaign owner");

        if(sent){
            campaign.amountCollected = campaign.amountCollected + amount_want_to_sent;
        }
    }

    function getDonars(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return(campaigns[_id].donators , campaigns[_id].donations);
    }

    function getCompaigns() public view returns (Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](no_of_compaigns);

        for(uint i=0;i<no_of_compaigns;i++){
            Campaign storage item=campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}