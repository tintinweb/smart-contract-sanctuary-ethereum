// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint target;
        uint deadline;
        uint amountCollected;
        string image;
        address[] donators;
        uint[] donations;
    }
    mapping (uint => Campaign) public campaigns;
    uint public numberOf_compaigns=0;


    function createCampaign(address _owner, string memory _title, string memory _desc, uint _target, uint _deadline, string memory _image)
    public returns(uint)        
    {
        Campaign storage campaing= campaigns[numberOf_compaigns];
        require(_deadline < block.timestamp,"A deadline should be in the futur");
        campaing.owner=_owner;
        campaing.title=_title;
        campaing.description=_desc;
        campaing.target=_target;
        campaing.deadline=_deadline;
        campaing.amountCollected=0;
        campaing.image=_image;
        numberOf_compaigns++;

        return numberOf_compaigns-1;



        
    }
    function donateToCompaign(uint _id) public payable{
        uint amount=msg.value;
        Campaign storage campaign=campaigns[_id];

        campaign.donations.push(amount);
        campaign.donators.push(msg.sender);
        

        (bool send,) =payable(campaign.owner).call{value:amount}("");
        if(send){
            campaign.amountCollected+=amount;
        }


    }
    function getDonators(uint _id) public view returns(address[] memory, uint[] memory){
        return (campaigns[_id].donators,campaigns[_id].donations);
    }
    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns=new Campaign[](numberOf_compaigns);
        for (uint256 i = 0; i < numberOf_compaigns; i++) {
            Campaign storage item=campaigns[i];
            allCampaigns[i]=item;
        }
        return allCampaigns;
    }
}