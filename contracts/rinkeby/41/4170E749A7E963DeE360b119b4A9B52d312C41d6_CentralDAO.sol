// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CentralDAO{

    struct Voting{
        string header;
        string description;
        uint approvalCount;
        bool complete;
        mapping(address => bool) approvals;
    }

    address public manager;
    mapping(address => uint) public userTimestamp;
    uint public currentPeriodActivity;
    uint public lastPeriodActivity;
    uint public activityDate;
    uint public numberOfVotings;
    mapping (uint256 => Voting) votings;

    constructor(uint timestamp, uint initialActivity){ //epoch unix timestamp
        manager = msg.sender;
        activityDate = timestamp;
        lastPeriodActivity = initialActivity;
    }
    
    modifier restricted() {
        require(msg.sender == manager, "Only owner can do it");
        _;
    }

    function vote(uint index) public {
        Voting storage voting = votings[index];

        require(!voting.approvals[msg.sender], "You can't vote twice!");
        require(bytes(voting.header).length != 0);

        voting.approvals[msg.sender] = true;
        voting.approvalCount++;

        if(activityDate >= userTimestamp[msg.sender]){
            currentPeriodActivity = currentPeriodActivity + 1;
            userTimestamp[msg.sender] = block.timestamp;
        }
    }

    function updateActivity(uint newTimestamp) public restricted {
        require(newTimestamp <= block.timestamp, "You can't set date for the future");
        activityDate = newTimestamp;
        lastPeriodActivity = currentPeriodActivity;
        currentPeriodActivity = 0;
    }

    function createVoting(string memory header, string memory description) public restricted {
        Voting storage voting = votings[numberOfVotings++];
        voting.header = header;
        voting.description = description;
        voting.approvalCount = 0;
        voting.complete = false;
    }

    function finalizeVoting(uint index) public restricted {
        Voting storage voting = votings[index];
        require(!voting.complete, "Voting can't be complete to finalize it");
        require(voting.approvalCount > (lastPeriodActivity / 2), "Insufficient votes to finalise a voting");
        voting.complete = true;
    }

    function checkIfComplete(uint index) public view returns(bool){
        Voting storage voting = votings[index];
        return voting.complete;
    }
    function getApprovalCount(uint index) public view returns(uint){
        Voting storage voting = votings[index];
        return voting.approvalCount;
    }
    function getLastPeriodActivity() public view returns(uint){
        return lastPeriodActivity;
    }



}