// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Mycontract
 {
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
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberofCampaings =0;

    function createCampaign(address _owner,string memory _title,string memory _description,uint256 _target,
    uint256 _deadline,string memory _image) public returns (uint256){

        Campaign storage campaign = campaigns[numberofCampaings];

        require(campaign.deadline < block.timestamp);

        campaign.owner=_owner;
        campaign.title=_title;
        campaign.description=_description;
        campaign.target=_target;
        campaign.deadline=_deadline;
        campaign.amountCollected=0;
        campaign.image=_image;
        numberofCampaings++;
        return numberofCampaings -1;
    }

    function donateToCampaigns(uint256 _id)public payable{

        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[ _id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        (bool sent,)=payable(campaign.owner).call{value:amount}("");
        
        if(sent){
            campaign.amountCollected = campaign.amountCollected+amount;
        }
            }
  
  
  
  function getDonateors(uint256 _id) view public returns (address[] memory,uint256[] memory){
    return (campaigns[_id].donators,campaigns[_id].donations);
  }

  function getCapaigns() public view returns (Campaign[] memory){
    Campaign[] memory allcomapigns = new Campaign[](numberofCampaings);
    for( uint i=0;i<numberofCampaings;i++){
        Campaign storage iteam = campaigns[i];
        allcomapigns[i]=iteam;
    }
    return allcomapigns;
  }
    
}