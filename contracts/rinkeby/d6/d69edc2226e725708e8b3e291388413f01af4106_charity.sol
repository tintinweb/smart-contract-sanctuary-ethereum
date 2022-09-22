/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
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
        uint256 balance;
    }
    Campaign[] campaigns;
    function setcampaign(string memory _title, string memory _desc, bool _islive, uint numberOfDays,uint256 _target) public
      {
          // initialize an empty struct and then update it
        Campaign memory campignn;
        campignn.title = _title;
        campignn.description = _desc;
        campignn.isLive = _islive;
        campignn.initiator = msg.sender;
        campignn.target = _target;
        campignn.deadline = block.timestamp + (numberOfDays * 1 days);
        // todo.completed initialized to false      
          campaigns.push(campignn);
        countcamp++;
      }
      function donate(uint _index , uint256 value) public payable
      {
        Campaign storage camp = campaigns[_index];
      //  require(camp.deadline<block.timestamp,'Campaign Expired');
        camp.balance+=value;
      }
      function getcount() public view returns(uint){
          return countcamp;
      }
       function get(uint _index) public view returns (string memory title, string memory description, bool islive, address initiator, uint256 deadline , uint256 target , uint256 balance) {
        Campaign storage getcamp = campaigns[_index];
        return (getcamp.title, getcamp.description , getcamp.isLive, getcamp.initiator, getcamp.deadline, getcamp.target, getcamp.balance);
        }
}