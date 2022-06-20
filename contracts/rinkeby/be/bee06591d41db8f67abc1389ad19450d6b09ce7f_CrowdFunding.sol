/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

contract CrowdFunding {
    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalVoteUp;
        uint totalVoteDown;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
        uint voteType;
    }

    uint public numCampagins;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;
    
    Campaign[] public campaignsArray;
    mapping(uint => mapping(address => bool)) public isVoteUpParticipate;
    mapping(uint => mapping(address => bool)) public isVoteDownParticipate;

    event CampaignLog(uint campaignID, address receiver, uint goal);
    event VoteLog(uint campaignID, address sender);

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignID) {
        campaignID = numCampagins++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;

        campaignsArray.push(c);
        emit CampaignLog(campaignID, receiver, goal);
    }

    modifier judgeParticipate(uint campaignID, uint voteType) {
        if(voteType == 0){
            require(isVoteUpParticipate[campaignID][msg.sender] == false);
        }
        if(voteType == 1){
            require(isVoteDownParticipate[campaignID][msg.sender] == false);
        }
        _;
    }

    function vote(uint campaignID, uint voteType) external payable judgeParticipate(campaignID, voteType) {
        Campaign storage c = campaigns[campaignID];
        c.totalAmount += msg.value;
        c.numFunders += 1;
     
        funders[campaignID].push(Funder({
            addr: msg.sender,
            voteType: voteType,
            amount: msg.value
        }));
        if(voteType == 0){
            isVoteUpParticipate[campaignID][msg.sender] = true;
            c.totalVoteUp += 1;
        }
        if(voteType == 1){
            isVoteDownParticipate[campaignID][msg.sender] = true;
            c.totalVoteDown += 1;
        }

        emit VoteLog(campaignID, msg.sender);
    }

    function withdraw(uint campaignID) external returns(bool reached) {
        Campaign storage c = campaigns[campaignID];

        if(c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);
    }
}