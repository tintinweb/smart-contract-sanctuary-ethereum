// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

pragma solidity 0.8.11;

contract CrowdFundingStorage{

    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder{
        address addr;
        uint amount;
    }

    uint public numCampagins;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    Campaign[] public campaignsArray;
    mapping(uint => mapping(address => bool)) public isParticipate;
}

contract CrowdFundings is CrowdFundingStorage{

    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    event CampaignLog(uint campaignId,address receiver,uint goal);

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier judgeParticipate(uint campaignId){
        require(isParticipate[campaignId][msg.sender] == false);
        _;
    }

    function newCampaign(address payable receiver,uint goal)external isOwner() returns(uint campaignId){
        campaignId  = numCampagins++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;

        campaignsArray.push(c);
        emit CampaignLog(campaignId,receiver,goal);
    }

    function bid(uint campaignId) external payable judgeParticipate(campaignId){
        Campaign storage c = campaigns[campaignId];

        c.totalAmount += msg.value;
        c.numFunders += 1;
        funders[campaignId].push(Funder({
        addr:msg.sender,
        amount:msg.value
        }));

        isParticipate[campaignId][msg.sender] = true;
    }

    function withdraw(uint campaignId) external returns(bool reached){
        Campaign storage c = campaigns[campaignId];

        if(c.totalAmount < c.fundingGoal){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }

}