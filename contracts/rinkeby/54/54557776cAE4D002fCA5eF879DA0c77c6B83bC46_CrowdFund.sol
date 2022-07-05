/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract CrowdFund {
    address immutable Owner;
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

    uint public numCampaigns;
    mapping (uint => Campaign) public campaigns;
    mapping (uint => Funder[]) public funders;
    Campaign[] public campaignsArray;
    mapping (uint => mapping(address => bool)) public isParticipate;
    event CampaignLog(uint campaignID,address receiver,uint goal);
    event bidLog(uint campaignID,uint256 value);
    modifier isOwner() {
        require(msg.sender == Owner);
        _;
    }

    constructor() {
        Owner = msg.sender;
    }

    function newCampaign(address payable receiver,uint goal) external isOwner() returns (uint campaignID){
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
        campaignsArray.push(c);
        emit CampaignLog(campaignID,receiver,goal);
    }

    function bid(uint campaignID) external payable {
        Campaign storage c = campaigns[campaignID];
        c.totalAmount = msg.value;
        c.numFunders += 1;
        emit bidLog(campaignID,msg.value);
        funders[campaignID].push(Funder({addr:msg.sender,amount:msg.value}));
        isParticipate[campaignID][msg.sender] = true;
    }
}