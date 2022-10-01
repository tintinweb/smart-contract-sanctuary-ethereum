/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract charity
{
    uint countcamp=0;
   struct Campaign {
        string title;
        string description;
        bool isLive;
        address initiator;
        uint256 deadline;
        uint256 target;
        uint balance;
    }
    Campaign[] campaigns;
    function setcampaign(string memory _title, string memory _desc, bool _islive, uint numberOfDays,uint256 _target) public
      {
        Campaign memory campignn;
        campignn.title = _title;
        campignn.description = _desc;
        campignn.isLive = _islive;
        campignn.initiator = msg.sender;
        campignn.target = _target;
        campignn.deadline = block.timestamp + (numberOfDays * 1 days);      
          campaigns.push(campignn);
        countcamp++;
      }
      function donate(uint _index) public payable
      {
         Campaign storage camp = campaigns[_index];
        if(block.timestamp > camp.deadline){
            camp.isLive = false;
        }
     //   require(block.timestamp < camp.deadline, "Campaign has ended");
         require(msg.value > 0, "Wrong ETH value");
        camp.balance+=msg.value;
      }
       function togglecampain(uint _index) public
      {
         Campaign storage camp = campaigns[_index];
        camp.isLive=!camp.isLive;
      }
      function getcount() public view returns(uint){
          return countcamp;
      }  
       function get(uint _index) public view returns (string memory title, string memory description, bool islive, address initiator, uint256 deadline , uint256 target , uint256 balance) {
        Campaign storage getcamp = campaigns[_index];
        return (getcamp.title, getcamp.description , getcamp.isLive, getcamp.initiator, getcamp.deadline, getcamp.target, getcamp.balance);
        }
        function withdrawCampaignFunds(uint _index) public {
        Campaign storage camp = campaigns[_index];
       require(msg.sender == camp.initiator, "Not campaign initiator");
        require(camp.isLive==false, "campaign is still active");
        require(block.timestamp > camp.deadline, "Campaign is still active");
        require(camp.balance > 0, "No funds to withdraw");
        uint256 amountToWithdraw = camp.balance;
        camp.balance = 0;
        payable(camp.initiator).transfer(amountToWithdraw);
    }
}