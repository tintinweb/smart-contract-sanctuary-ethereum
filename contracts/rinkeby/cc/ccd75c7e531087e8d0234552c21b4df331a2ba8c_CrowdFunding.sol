/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//创建不同的募资活动
//记录相应活动下的募资总体信息
//创建不同的募资活动

//SPDX-License-Identifier:UNLICENSED

pragma solidity 0.8.11;

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
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;
    mapping(uint => mapping(address => bool)) public isPartcipate;
}

contract CrowdFunding is CrowdFundingStorage{
    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    modifier judgeParticipate(uint campaignID) {
        require(isPartcipate[campaignID][msg.sender] == false);
        _;
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external returns (uint campaignID){
        campaignID = numCampagins++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function showCampaignAmount(uint campaignID) external view returns (uint fundingGoal){
        Campaign storage c = campaigns[campaignID];
        fundingGoal = c.fundingGoal;
    }

    function bid(uint campaignID) external payable judgeParticipate(campaignID){
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isPartcipate[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns (bool reached){
        Campaign storage c = campaigns[campaignID];

        if(c.totalAmount < c.fundingGoal){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}