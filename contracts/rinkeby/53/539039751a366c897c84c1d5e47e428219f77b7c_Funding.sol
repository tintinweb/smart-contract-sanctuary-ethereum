/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity 0.8.11;
contract backup{
    struct Campaign{
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalAmount;
    }

    struct Funder{
        address addr;
        uint amount;
    }

    uint public numCams;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address => bool)) public isParticipate;
}



contract Funding is backup{
    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    modifier judgeParticipate(uint campaignID){
        require(isParticipate[campaignID][msg.sender] == false);
        _;
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external returns(uint campaignID){
        campaignID = numCams++;
        Campaign storage User = campaigns[campaignID];
        User.receiver = receiver;
        User.fundingGoal = goal;
    }

    function bid(uint campaignID) external payable judgeParticipate(campaignID) {
        Campaign storage User = campaigns[campaignID];

        User.totalAmount += msg.value;
        User.numFunders += 1;

        funders[campaignID].push(Funder({addr: msg.sender, amount: msg.value}));
        
        isParticipate[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns(bool reached){
        Campaign storage User = campaigns[campaignID];

        if (User.totalAmount < User.fundingGoal){
            return false;
        }

        uint amount = User.totalAmount;
        User.totalAmount = 0;
        User.receiver.transfer(amount);

        return true;
    }
}