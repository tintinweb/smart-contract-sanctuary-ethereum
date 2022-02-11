/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract ICrowdFund {

    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundAmountGoal;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCampaigns;
    mapping(uint => Campaign)  campaigns;
    mapping(uint => Funder[])  funders;
    mapping(uint => mapping(address => bool)) public isParticipate;

}

contract CrowdFund is ICrowdFund {
    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier isExistFund(uint _campaignId) {
        require(isParticipate[_campaignId][msg.sender] == false);
        _;
    }


    function newCampaign(address payable _receiver, uint _goal) external isOwner() returns(uint campaignId) {
        campaignId = numCampaigns++;
        Campaign storage campaign = campaigns[campaignId];
        campaign.fundAmountGoal = _goal;
        campaign.receiver = _receiver;
    }

    function bid(uint _campaignId)  external payable isExistFund(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        campaign.totalAmount += msg.value;
        campaign.numFunders += 1;

        funders[_campaignId].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[_campaignId][msg.sender] = true;
    }

    function withdraw(uint _campaignId) external returns(bool reached){
        Campaign storage campaign = campaigns[_campaignId];
        if(campaign.totalAmount < campaign.fundAmountGoal){
            return false;
        }

        uint amount = campaign.totalAmount;
        campaign.totalAmount = 0;
        campaign.receiver.transfer(amount);

        return true;
    }

}