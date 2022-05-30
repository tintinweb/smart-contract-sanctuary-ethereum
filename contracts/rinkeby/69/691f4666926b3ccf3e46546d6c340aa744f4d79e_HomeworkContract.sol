/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity 0.8.14;

contract HomeworkContract{
    address immutable owner;
    
    constructor() {
        owner = msg.sender;
    }

    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundingGoals;
        uint totalAmount;
    }

    struct Funder{
        address addr;
        uint amount;
    }

    uint public numCampaigns;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;
    
    mapping(uint => mapping(address => bool)) public isParticipated;

    modifier judgeParticipated(uint campaignID){
        require(isParticipated[campaignID][msg.sender] == false);
        _;
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignID){
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoals = goal;
    }

    function bid(uint campaignID) external payable judgeParticipated(campaignID){
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipated[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns(bool reached){
        Campaign storage c = campaigns[campaignID];

        if(c.totalAmount < c.fundingGoals){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}