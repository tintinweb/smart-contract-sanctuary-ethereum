/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
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
 //   Campaign[] campagins;
    mapping(uint => Campaign) campagins;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address=>bool)) public isParticipate;

    modifier judgeParticipate(uint campaignID){
        require(isParticipate[campaignID][msg.sender] == false);
        _;
    }

    event BidLog(uint campaignID,address sender);
    
    function newCampaign(address payable receiver, uint goal) external returns(uint campaignID){
        campaignID = numCampagins++;
        Campaign storage c = campagins[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(uint campaignID) payable external{
        Campaign storage c = campagins[campaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));
        emit BidLog(campaignID,msg.sender);

        isParticipate[campaignID][msg.sender] = true;
    }

    function withdraw(uint campaignID) external returns(bool reached){
        Campaign storage c = campagins[campaignID];

        if(c.totalAmount < c.fundingGoal){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}