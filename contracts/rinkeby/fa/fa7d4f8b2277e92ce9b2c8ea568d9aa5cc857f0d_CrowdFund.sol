/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

pragma solidity 0.8.11;

contract CrowdFund {
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

    uint public numCampaigns;
    mapping (uint => Campaign) public campaignByID;
    mapping (uint => Funder[]) public funderByID;
    Campaign[] public campaignsArray;
    mapping (uint => mapping(address => bool)) public isParticipate;
    event CampaignLog(uint campaignID,address receiver,uint goal);

    function newCampaign(address payable receiver,uint goal) external returns (uint campaignID){
        campaignID = numCampaigns++;
        Campaign storage c = campaignByID[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
        campaignsArray.push(c);
        emit CampaignLog(campaignID,receiver,goal);
    }

    function bid(uint campaignID) external payable {
        require(isParticipate[campaignID][msg.sender]==false,"has been participated");

        Campaign storage c = campaignByID[campaignID];
        c.totalAmount = msg.value;
        c.numFunders += 1;

        funderByID[campaignID].push(Funder({addr:msg.sender,amount:msg.value}));
        isParticipate[campaignID][msg.sender] = true;
    }
}