/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity 0.8.11;

contract CrowdFunding {

    address immutable owner;

    constructor (){
        owner = msg.sender;
    }
    struct Campaign {
        address payable receiver;
        uint numFunders;
        uint fundingGoal;
        uint totalAmount;
        uint32 startAt;
        uint32 endAt;
    }

    struct Funder{
        address addr;
        uint amount;
    }
    uint public numCampaigns;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;
    

    mapping(uint => mapping( address => bool)) public isParticipate;

    modifier judgeParticipate(uint campaignID) {
        require(isParticipate[campaignID][msg.sender] == false);
        _;

    }
    event CampaignLog(uint campaignID, address receiver, uint goal);

    

    function newCampain(address payable receiver, uint goal) external returns(uint campaignID){
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
        emit CampaignLog(campaignID, receiver,goal);

    }

    function bid (uint campainID) external payable {
        Campaign storage c = campaigns[campainID];
        require(block.timestamp >= c.startAt, "started");
         require(block.timestamp < c.endAt, "ended");
        c.totalAmount += msg.value;
        c.numFunders += 1;
        funders[campainID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));
        isParticipate[campainID][msg.sender] = true;
        
    }
        function withdraw(uint campaignID) external returns(bool reached){
            Campaign storage c = campaigns[campaignID];
            if (c.totalAmount < c.fundingGoal){
                return false;
            }

            uint amount = c.totalAmount;
            c.totalAmount = 0;
            c.receiver.transfer(amount);

            return true;
        }

    }