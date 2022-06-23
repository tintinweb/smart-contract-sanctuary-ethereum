/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract CrowdFunding {

    address public immutable owner;

    constructor(address _owner){
        owner = _owner;
    }

    modifier isOwner(){
        require(msg.sender == owner,"you are not owner!");
        _;
    }

    //募集信息
    struct Campaign {
        address payable recevier;
        uint numFunders;
        uint goalNum;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCampaign;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address => bool)) userParticipate;

    modifier judgeParticipate(uint campaignId){
        require(userParticipate[campaignId][msg.sender] == false);
        _;
    }

    function newCampaign(address payable recevier, uint goalNum) external isOwner() returns(uint campaignId){
        campaignId = numCampaign++;
        Campaign storage c = campaigns[campaignId];
        c.recevier = recevier;
        c.goalNum = goalNum;
    }

    function bid(uint campaignId) external payable judgeParticipate(campaignId) {
        Campaign storage c = campaigns[campaignId];
        c.numFunders++;
        c.totalAmount += msg.value;

        // Funder[] storage f = funders[campaignId];
        // f.push(Funder(msg.sender,msg.value));

    

        // 优雅实现
        funders[campaignId].push(Funder({
            addr : msg.sender,
            amount : msg.value
        }));

        userParticipate[campaignId][msg.sender] == true;

    }

    function withdraw(uint campaignId) external returns(bool reached){
        Campaign storage c = campaigns[campaignId];
        if( c.totalAmount < c.goalNum ){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.recevier.transfer(amount);
        
        return true;
    }
}