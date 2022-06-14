/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


contract Ballot {
    

    address public immutable owner;
    uint public immutable duration = 3 days; 
    uint public numberOfBallot;
    uint constant public payForVoting = 0.01 ether;
    uint constant public payForEachVote = 0.009 ether;
    uint public contractFeeToWithdraw;
    // number of ballot => all info about current voting
    mapping(uint => VotingInfo) public allVotings;
    //address of participants => number of voting => already voted?
    mapping(address => mapping(uint => bool)) public votedVoters;
    



    struct  VotingInfo {
        uint finishAt;
        uint learderScore;
        uint winner;
        uint voteCount;
        bool isFinished;
        //number of candidate => candidate address
        mapping(uint => address) candidatesAddress;
        //number of candidate => vote counter
        mapping(uint => uint) currentVoting;
    }

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }

    //Create new Ballot with needed amount of candidates
    function createBallot(address[] calldata candidatesAddr) external onlyOwner {
        allVotings[numberOfBallot].finishAt = block.timestamp + duration;
        for (uint i = 0; i < candidatesAddr.length; i++) {
            allVotings[numberOfBallot].candidatesAddress[i] = candidatesAddr[i];
            allVotings[numberOfBallot].currentVoting[i];
        }
        numberOfBallot++;
    }

    //main function to receive money and vote
    function vote(uint _votingNumber, uint _candidate) external payable  {
        require(votedVoters[msg.sender][_votingNumber] == false, "already is Voted");
        require (allVotings[_votingNumber].finishAt > block.timestamp, "Voting is over, please check voting number");
        require(msg.value == payForVoting, "Please pay 0.01 ETH for voting");
        uint candidateScores = ++allVotings[_votingNumber].currentVoting[_candidate];
        allVotings[_votingNumber].voteCount++;
        if (candidateScores > allVotings[_votingNumber].learderScore) {
            allVotings[_votingNumber].learderScore = candidateScores;
            allVotings[_votingNumber].winner = _candidate;
        }
        votedVoters[msg.sender][_votingNumber] = true;
        contractFeeToWithdraw += payForVoting/10;
    }
    //Anybody can finish voting after the end
    function finishVoting(uint _votingNumber) external {
        require (allVotings[_votingNumber].finishAt < block.timestamp, "Voting is not finished yet");
        require (!allVotings[_votingNumber].isFinished, "Already finished");
        //Choosed winner and send money
        if (allVotings[_votingNumber].voteCount == 0) return;
        allVotings[_votingNumber].isFinished = true;
        address payable winner = payable(allVotings[_votingNumber].candidatesAddress[allVotings[_votingNumber].winner]);       
        winner.transfer(allVotings[_votingNumber].voteCount * payForEachVote);
    }

    function withdrawFee () external onlyOwner {
        payable(owner).transfer(contractFeeToWithdraw);
        contractFeeToWithdraw = 0;
    }


    //======================================================================================================
    // View functions
    //How many votes for candidate
    function howManyScore(uint _votingNumber, uint _candidate) external view returns(uint) {
        return allVotings[_votingNumber].currentVoting[_candidate];
    }
    //Already voted?
    function isVotedView(uint _votingNumber) external view returns(bool) {
        return votedVoters[msg.sender][_votingNumber];
    }
    //address of candidate
    function candidateAddr(uint _votingNumber, uint _candidate) external view returns(address) {
        return allVotings[_votingNumber].candidatesAddress[_candidate];
    }
    //who is winner
    function whoIsWinner(uint _votingNumber) external view returns(uint) {
        return allVotings[_votingNumber].winner;
    }
    
    //======================================================================================================
    //======================================================================================================
}