/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity 0.8.11;

contract CrowdFundding{


    struct Campaign{
        address payable receiver;
        uint funddingGoal;
        uint totalAmount;
        uint numFunders;
    }

    struct Funder{
        uint amount;
        address addr;
    }

    uint public numCampagins;

    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;
    mapping(uint => mapping(address => bool)) public isPartication;


    modifier judgePartication(uint campaignId){
        require(isPartication[campaignId][msg.sender] == false);
        _;
    }

    function newCampagin(address payable receiver, uint goal) external returns(uint campaginID) {
        campaginID = numCampagins++;
        Campaign storage c = campaigns[campaginID];
        c.receiver = receiver;
        c.funddingGoal = goal;
        return campaginID;
    }

    function bid(uint campaignId) external payable judgePartication(campaignId){
        Campaign storage c = campaigns[campaignId];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignId].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));
        isPartication[campaignId][msg.sender] = true;
    }

    function withdraw(uint campaignId) external returns(bool reached){
        Campaign storage c = campaigns[campaignId];

        if(c.totalAmount < c.funddingGoal){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);
        return true;

    }
}