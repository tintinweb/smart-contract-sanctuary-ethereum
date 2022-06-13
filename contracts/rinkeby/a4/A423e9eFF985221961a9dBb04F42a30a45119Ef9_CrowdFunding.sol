// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract CrowdFundingStorage {
    struct Campaign {
        address payable receiver;
        uint256 numFunders;
        uint256 fundingGoal;
        uint256 totalAmount;
    }

    struct Funder {
        address addr;
        uint256 amount;
    }

    uint256 public numCampaigns;
    mapping(uint256 => Campaign) campaigns;
    mapping(uint256 => Funder[]) funders;
    mapping(uint256 => mapping(address => bool)) public participate;
}

contract CrowdFunding is CrowdFundingStorage {
    address public immutable owner;

    event CampaignCreated(uint256 _id, address indexed _receiver, uint256 _goal);
    event BidPlaced(address indexed _from, uint256 _id);
    event WithdrawDone(address indexed _from, uint256 _id);
    event WithdrawFailed(address indexed _from, uint256 _id);

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier validate(uint256 id) {
        require(participate[id][msg.sender] == false);
        _;
    }

    function getCampaign(uint256 id) external view returns(Campaign memory) {
        return campaigns[id];
    }

    function newCampaign(address payable receiver, uint256 goal) external returns(uint256 id) {
        id = numCampaigns++;
        Campaign storage c = campaigns[id];
        c.receiver = receiver;
        c.fundingGoal = goal;

        emit CampaignCreated(id, receiver, goal);
    }

    function bid(uint256 id) external payable validate(id) {
        Campaign storage c = campaigns[id];
        
        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[id].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        participate[id][msg.sender] = true;

        emit BidPlaced(msg.sender, id);
    }

    function withdraw(uint256 id) external {
        Campaign storage c = campaigns[id];

        if(c.totalAmount < c.fundingGoal) {
            emit WithdrawFailed(msg.sender, id);
            return;
        }

        uint256 amount = c.totalAmount;
        c.totalAmount = 0;
        c.receiver.transfer(amount);

        emit WithdrawDone(msg.sender, id);
    }
}