/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

pragma solidity 0.8.18;

contract CrowdFundingStorage {

    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fudingGoal;
        uint totalAmount;
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCampaigns;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address => bool)) public isParticipate;
}

contract CrowdFunding is CrowdFundingStorage{
    address immutable owner = msg.sender;

    modifier isOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier judgeParticipate(uint campaignID) {
        require(isParticipate[campaignID][msg.sender] == false);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner returns(uint campaignID) {
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fudingGoal = goal;
    }

    function bid(uint campaignID) external payable judgeParticipate(campaignID) {
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunders ++;

        funders[campaignID].push(Funder({
            addr:msg.sender,
            amount:msg.value
        }));

        isParticipate[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns(bool reached) {
        Campaign storage c = campaigns[campaignID];

        if(c.totalAmount < c.fudingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}