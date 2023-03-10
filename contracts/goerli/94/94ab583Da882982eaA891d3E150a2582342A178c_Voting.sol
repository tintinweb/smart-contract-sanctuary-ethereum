// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Voting {
    address public owner; // Owner address. Could be replaced by OZ ownable
    uint public startTime;
    uint public endTime;
    uint public immutable candidatesCount; // Number of candidates which is set inside constructor

    mapping(address => bool) public registered; // To check if voter is registered or not
    mapping(address => uint) public voteResult; // Voted result. If 0, not voted yet. Candidate number starts from 1
    mapping(uint => uint) public voteCount; // Number of votes casted for each candidate

    // Errors - for gas efficiency
    error VoteNotAvailable();
    error NotRegistered();
    error AlreadyVoted();
    error NotOwner();
    error InvalidCandidate();
    error InvalidVotingPeriod();

    // Events - backend can tract the events
    event Registered(address indexed voter);
    event Voted(uint indexed candidate, address indexed voter);

    constructor(uint _startTime, uint _endTime, uint _candidatesCount) {
        owner = msg.sender;
        candidatesCount = _candidatesCount;
        setVotingPeriod(_startTime, _endTime);
    }

    function vote(uint candidate) external onlyRegistered {
        if(block.timestamp < startTime || block.timestamp > endTime) {
            revert VoteNotAvailable();
        }

        if(candidate == 0 || candidate > candidatesCount) { // Check if candidate number is in range
            revert InvalidCandidate();
        }

        if(voteResult[msg.sender] > 0) {   // Check if not voted yet
            revert AlreadyVoted();
        }
    
        voteResult[msg.sender] = candidate;
        voteCount[candidate] ++;

        emit Voted(candidate, msg.sender);
    }

    // Admin functions
    function setVotingPeriod(uint _startTime, uint _endTime) public onlyOwner {
        if(_startTime >= _endTime) {
            revert InvalidVotingPeriod();
        }
        startTime = _startTime;
        endTime = _endTime;
    }

    function register(address voter) external onlyOwner {
        registered[voter] = true;

        emit Registered(voter);
    }
    // End of Admin functions

    // Modifiers
    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyRegistered() {
        if(!registered[msg.sender]) {
            revert NotRegistered();
        }
        _;
    }
}