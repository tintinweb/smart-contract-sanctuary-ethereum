/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract CrowdFundingStorage {
    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint currentAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCampaigns;
    // 活动编号 => 活动
    mapping(uint => Campaign) campaigns;
    // 活动编号 => 参与者
    mapping(uint => Funder[]) funders;
    // 每个活动仅限参与一次
    mapping(uint => mapping(address => bool)) public isParticipate;
}

contract CrowdFunding is CrowdFundingStorage {
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner,"not owner!");
        _;
    }

    modifier judgeParticipate(uint campaignId){
        require(isParticipate[campaignId][msg.sender] == false,"you have participated!");
        _;
    }

    event CampaignLog(uint campaignId, address receiver, uint goal);

    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignId){
        campaignId = numCampaigns++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;

        // 抛出事件进行索引
        emit CampaignLog(campaignId, receiver, goal);
    }

    function bid(uint campaignId) external payable judgeParticipate(campaignId){
        Campaign storage c = campaigns[campaignId];
        c.currentAmount += msg.value;
        c.numFunders += 1;
        funders[campaignId].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));
        isParticipate[campaignId][msg.sender] = true;
    }

    function withdraw(uint campaignId) external returns(bool reached){
        Campaign storage c = campaigns[campaignId];
        if(c.currentAmount < c.fundingGoal){
            return false;
        }
        uint amount = c.currentAmount;
        c.currentAmount = 0;
        c.receiver.transfer(amount);
        return true;
    }


}