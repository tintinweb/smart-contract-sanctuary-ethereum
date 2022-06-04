/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

pragma solidity 0.8.11;

contract CrowdFundingStorage{
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

    uint public numCampaigns;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    mapping(uint => mapping(address => bool))public isParticipate;
    
}

contract CrowdFunding is CrowdFundingStorage{
    address immutable owner;

    constructor(){
        owner = msg.sender;
    }

    modifier judgeParticipate(uint CampaignID){//检查是否已经参与过了
        require(isParticipate[CampaignID][msg.sender] == false);
        _;
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function newCampaign(address payable receiver,uint goal)external returns(uint CampaignID) {
        CampaignID = numCampaigns++;
        Campaign storage c = campaigns[CampaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }

    function bid(uint CampaignID)external payable {
        Campaign storage c = campaigns[CampaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[CampaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[CampaignID][msg.sender] == true;
    }

    function withdraw(uint CampaignID)external returns(bool reached){
        Campaign storage c = campaigns[CampaignID];

        if(c.totalAmount < c.fundingGoal){
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}