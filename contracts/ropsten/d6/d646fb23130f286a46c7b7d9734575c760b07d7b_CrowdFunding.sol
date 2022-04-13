/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

    struct Funder{
        address addr;
        uint amount;
    }

    contract CrowdFunding {

        struct Campaign {
            address payable beneficiary;
            uint fundingGoal;
            uint numFunders;
            uint amount;
            mapping(uint => Funder) funders;
        }

        uint numCampaigns;
        mapping(uint => Campaign) campaigns;

        function newCampaign(address payable beneficiary,uint goal) public returns(uint campaignID) {
            campaignID = numCampaigns++;

            Campaign storage c = campaigns[campaignID];
            c.beneficiary = beneficiary;
            c.fundingGoal = goal;
        }

        function contribute(uint campaignID) public payable {
            Campaign storage c = campaigns[campaignID];
            c.funders[c.numFunders++] = Funder({addr: msg.sender, amount: msg.value});
            c.amount += msg.value;
        }

        
         function checkGoalReached(uint campaignID) public returns (bool reached) {
        Campaign storage c = campaigns[campaignID];
        if (c.amount < c.fundingGoal)
            return false;
        uint amount = c.amount;
        c.amount = 0;
        c.beneficiary.transfer(amount);
        return true;
    }
    
    }