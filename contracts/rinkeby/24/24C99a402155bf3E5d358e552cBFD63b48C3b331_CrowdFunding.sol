/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract CrowdFundingStorage{
 struct Campaign {
    address payable receiver;
    uint numFunders;
    uint fundingGoal;
    uint totalAmount;
  }

  struct Funder {
    address addr;
    uint amount;
  }

  uint public numCampagins;
  mapping(uint => Campaign) Campaigns;
  mapping(uint => Funder[]) funders;

  mapping(uint => mapping(address => bool)) public isParticipate;

}

contract CrowdFunding is CrowdFundingStorage {
  address immutable owner;

  constructor() {
    owner =msg.sender;
  }
  
  
  modifier judgeparticipate(uint campaignID) {
    require(isParticipate[campaignID][msg.sender] == false);
    _;
  }

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignID){
    campaignID = numCampagins++;
    Campaign storage c = Campaigns[campaignID];
    c.receiver = receiver;
    c.fundingGoal = goal;
  }

  function bid(uint campaignID) external payable judgeparticipate(campaignID) {
   Campaign storage c = Campaigns[campaignID];

    c.totalAmount += msg.value;
    c.numFunders += 1;
    
    funders[campaignID].push(Funder({
      addr: msg.sender,
      amount: msg.value
    }));

    isParticipate[campaignID][msg.sender] = true;
  }

  function withdraw(uint campaignID) external returns(bool reached){
    Campaign storage c = Campaigns[campaignID];

    if(c.totalAmount < c.fundingGoal) {
      return false;
    }

    uint amount = c.totalAmount;
    c.totalAmount = 0;
    c.receiver.transfer(amount);

    return true;
  }

}