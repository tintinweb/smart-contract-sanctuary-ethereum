/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract CrowdFunding {
    struct Campaign {
        address payable receiver;
        uint numFunder;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCampagins;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => Funder[]) public funders;

    mapping(uint => mapping(address => bool)) public isParticipate;

    event CampaignLog(uint campaignID, address receiver, uint goal);
    event BidLog(address bidAddr, uint campaignId);

    modifier judgeParticipate(uint campaignId) {
        require(isParticipate[campaignId][msg.sender] == false);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external returns(uint campaignID) {
        uint campaignId = numCampagins++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;

        emit CampaignLog(campaignId, receiver, goal);
        return campaignId;
    }

    function bid(uint campaignID) external payable judgeParticipate(campaignID) {
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunder += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[campaignID][msg.sender] = true;

        emit BidLog(msg.sender, campaignID);
    }

    function withdraw(uint campaignID) external returns(bool reached) {
        Campaign storage c = campaigns[campaignID];

        if (c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);
        return true;
    }
}