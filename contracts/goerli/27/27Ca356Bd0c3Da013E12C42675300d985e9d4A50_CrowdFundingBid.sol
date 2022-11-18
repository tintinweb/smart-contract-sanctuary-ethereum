/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract CrowdFundingBid{
    address immutable owner;
    struct Campaign{
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder{
        address addr;
        uint amount;
    }
    
    uint public numCampaigns;
    mapping (uint => Campaign) public campaigns;
    mapping (uint => Funder[]) public funders;
    Campaign[] public campaignsArray;

    event CampaignLog(uint campaignID,address receiver,uint goal);
    event NewBid(uint campaignID,address bider,uint amount);

    constructor(){
        owner = msg.sender;
    }

    function newCampaign(address payable receiver,uint goal) external returns (uint campaignID) {
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
        campaignsArray.push(c);
        emit CampaignLog(campaignID, receiver, goal);
    }
    
    function bid(uint campaignID,uint value) external payable{
        Campaign storage c = campaigns[campaignID];
        c.totalAmount += value;
        c.numFunders += 1;
        funders[campaignID].push(Funder({addr:msg.sender,amount:value}));
        emit NewBid(campaignID,msg.sender,value);
    }

    function withdraw(uint campaignID) external returns (bool reached){
        Campaign storage c = campaigns[campaignID];
        if (c.totalAmount < c.fundingGoal) return false;
        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);
        return true;
    }
}