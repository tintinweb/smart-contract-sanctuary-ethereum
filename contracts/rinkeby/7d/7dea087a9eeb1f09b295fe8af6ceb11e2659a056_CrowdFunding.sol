/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity 0.8.14;

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

    uint public numCampaigns;
    mapping(uint => Campaign) campaigns;
    mapping(uint => Funder[]) funders;

    Campaign[] public campaignsArray;

    mapping(uint => mapping(address => bool)) public isParticipate;

    event CampaignLog(uint campaignID, address receiver, uint goal);
    event CampaignBid(uint campaignID, address addr);
}

contract CrowdFunding is CrowdFundingStorage {
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    // modifier judgeParticipate(uint campaignID) {
    //     require(isParticipate[campaignID][msg.sender] == false);
    //     _;
    // }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function newCampaign(address payable receiver, uint goal) external isOwner() returns (uint campaignID){
        campaignID = numCampaigns++;
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;

        campaignsArray.push(c);
        emit CampaignLog(campaignID, receiver, goal);
    }

    function bid(uint campaignID) external payable {
        Campaign storage c = campaigns[campaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        isParticipate[campaignID][msg.sender] = true;
        emit CampaignBid(campaignID, msg.sender);
    }

    function withdraw(uint campaignID) external returns(bool reached) {
        Campaign storage c = campaigns[campaignID];

        if (c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        return true;
    }
}