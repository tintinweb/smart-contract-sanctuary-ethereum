/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CrowdFunding{
    struct Funder{
        address addr;
        uint256 amount;
    }

    struct Campaign{
        address payable beneficiary;
        uint256 fundingGoal;
        uint256 numFunders;
        uint256 amount;
        mapping(uint256 => Funder) funders;
    }

    uint256 public numCampaigns;

    mapping(uint => Campaign) public campaigns;
    
    function newCampaign(address payable beneficiary, uint256 goal)
        public
        returns (uint256 campaignID)
    {
        campaignID = numCampaigns++;

        Campaign storage c = campaigns[campaignID];
        c.beneficiary = beneficiary;
        c.fundingGoal = goal;
    }

    function contribute(uint256 campaignID) public payable{
        Campaign storage c = campaigns[campaignID];

        c.funders[c.numFunders++] = Funder({
            addr: msg.sender,
            amount: msg.value
        });
        c.amount += msg.value;
    }

    function checkGoalReached(uint256 campaignID)
        public
        returns (bool reached)
    {
        Campaign storage c = campaigns[campaignID];
        if (c.amount < c.fundingGoal) return false;
        uint256 amount = c.amount;
        c.amount = 0;
        c.beneficiary.transfer(amount);
        return true;
    }

    event cevent(address addr, uint256 amount);

    function AddressAmount(uint256 campaignID)
        public
        returns (address addr, uint256 amount)
    {
        emit cevent(campaigns[campaignID].funders[0].addr, campaigns[campaignID].funders[0].amount);
        return (campaigns[campaignID].funders[0].addr, campaigns[campaignID].funders[0].amount);
    }
}