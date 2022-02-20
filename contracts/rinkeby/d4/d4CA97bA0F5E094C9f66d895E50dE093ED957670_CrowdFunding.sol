/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract CrowdFunding {
    address immutable owner;
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


    modifier judgeParticipate(uint campaignID) {
        require(isParticipate[campaignID][msg.sender] == false);
        _;
    } 

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    } 

    constructor() {
        owner = msg.sender;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns (uint campaignID) {
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;

        campaignsArray.push(c);
    }

    function bid(uint campaignID) external payable judgeParticipate(campaignID) {
        Campaign storage c = campaigns[campaignID];
        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({addr: msg.sender, amount: msg.value}));

        isParticipate[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns (bool reached) {
        Campaign storage c = campaigns[campaignID];
        if (c.totalAmount < c.fundingGoal)
            return false;
        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);
        return true;
    }
}