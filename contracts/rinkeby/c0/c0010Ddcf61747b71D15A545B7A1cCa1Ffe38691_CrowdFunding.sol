/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity 0.8.11;

contract CrowdFundingStorage {
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
    mapping(uint => mapping(address => bool)) public isParticipate;

}


contract CrowdFunding is CrowdFundingStorage{

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier judgeParticipate(uint campaignId) {
        require(isParticipate[campaignId][msg.sender] == false);
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignId) {

        campaignId = numCampagins++;
        Campaign storage c = campaigns[campaignId];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(uint campaignId) external payable judgeParticipate(campaignId){
        Campaign storage c = campaigns[campaignId];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignId].push(Funder({
        addr: msg.sender,
        amount: msg.value
        }));

        isParticipate[campaignId][msg.sender] == true;
    }


    function withDraw(uint campaignId) external returns(bool reched) {
        Campaign storage c = campaigns[campaignId];
        if(c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;

        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}