/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Vote{

    //storage
    uint256 public candidateLimit = 2;
    uint256 maxVoted = 0;
    uint256 maxVoted2 = 0;
    bool draw = false;

    address payable public desk;

    uint deployDate;
    bool voteDone = false;
    
    modifier onlyVoter() {
        for(uint256 i = 0; i < voters.length; i++){
                if (msg.sender == voters[i].wallet){
                    voter = voters[i];
                }
            }
        require(msg.sender == voter.wallet, "Only voter can call this method!");
        _;
    }

    modifier onlyDesk() {
        require(msg.sender == desk, "Only desk can call this method!");
        _;
    }

    struct Candidate{
        string name;
        string surname;
        int age;
        int voteCount;
        address payable wallet;
        uint256 betAmount;
    }

    struct Voter{
        string name;
        string surname;
        int age;
        bool isVoted;
        address payable wallet;
        uint256 votedTo;
        uint256 betAmount;
    }

    Voter public voter;
    Voter[] public voters;

    Candidate[] public candidates;

    constructor(address payable _desk) payable{
        deployDate = block.timestamp;
        desk = _desk;
    }

    function bet(uint256 candidate) onlyVoter external payable {
        for(uint256 i = 0; i < voters.length; i++){
            if (msg.sender == voters[i].wallet)
                if (voters[i].betAmount == 0 && voters[i].isVoted && voters[i].votedTo == candidate)
                    voters[i].betAmount = address(this).balance;
                else
                    return;
            else
                return;
        }
        candidates[candidate].betAmount += address(this).balance;
        desk.transfer(address(this).balance);
    }

    function addVoter(string memory name, string memory surname, int age, address payable wallet) public returns (string memory){
        if (age < 18)
            return "You are too young to vote!";

        if (age >= 65)
            return "You are too old to vote!";
        
        for(uint256 i = 0; i < voters.length; i++){
            if (wallet == voters[i].wallet){
                voter = voters[i];
                return "This voter is already added! Set the current voter to it.";
            }
        }
        voter = Voter(name, surname, age, false, wallet, 0, 0);
        voters.push(voter);
        return "You can vote successfully now!";
    }

    function vote(uint256 candidate) onlyVoter public returns (string memory) {
        if (getIsElectionDone()){
            voteDone = true;
            return "You can't vote now the election is completed";
        }
        if (candidates.length != candidateLimit)
            return "Election will start once the candidates are filled!";
        if (keccak256(abi.encodePacked(voter.name)) == keccak256(abi.encodePacked("")))
            return "Please set your information correctly";
        
        if(voter.isVoted)
            return "You have already voted";
        if (!voteDone){
            setVoteCount(candidate);
            voter.votedTo = candidate;
            voter.isVoted = true;
            return string(abi.encodePacked("You have voted for ", candidates[candidate].name));
        }

        return "Election is done you can't vote anymore get the results from getElectionLeader!";
    }

    function addCandidate (string memory name, string memory surname, int age, address payable wallet) public returns (string memory){
        if (age <= 18)
            return "You are too young to be a candidate!";

        if (age >= 65)
            return "You are too old to be a candidate!";

        for(uint256 i = 0; i < candidates.length; i++){
            if (wallet == candidates[i].wallet)
                return "This candidate is already added!";
        }

        if(candidates.length == candidateLimit){
            return "Maximum candidate amount is reached!";
        }

        Candidate memory can = Candidate(name, surname, age, 0, wallet, 0);
        candidates.push(can);
        return "Candidate successfully added.";
    }

    function setVoteCount(uint256 candidate) private {
        candidates[candidate].voteCount += 1;
    }

    function claimBet() onlyDesk public payable {
        if(voteDone){
            getElectionLeader();
            if(draw){
                candidates[maxVoted].wallet.transfer(candidates[maxVoted].betAmount / 4);
                candidates[maxVoted2].wallet.transfer(candidates[maxVoted2].betAmount / 4);
            }
            candidates[maxVoted].wallet.transfer(candidates[maxVoted].betAmount / 4);
            for(uint256 i = 0; i < voters.length; i++){
                if (voters[i].votedTo == maxVoted || draw && voters[i].votedTo == maxVoted2)
                    voters[i].wallet.transfer(voters[i].betAmount * 2);
            }
        }
    }

    function getElectionLeader() public returns (string memory){
        int maxVoteCount = 0;
        for (uint256 i = 0; i < candidates.length; i++){
            if (candidates[i].voteCount > maxVoteCount){
                maxVoteCount = candidates[i].voteCount;
                maxVoted = i;
                draw = false;
            } else if (candidates[i].voteCount >= maxVoteCount){
                maxVoted2 = i;
                draw = true;
            }
        }
        if (draw && voteDone)
            return string(abi.encodePacked("Election is a draw, ", abi.encodePacked(candidates[maxVoted].name, abi.encodePacked(" and ", abi.encodePacked(candidates[maxVoted2].name, " won!")))));
        
        if (draw)
            return string(abi.encodePacked("Election is a draw currently, ", abi.encodePacked(candidates[maxVoted].name, abi.encodePacked(" and ", abi.encodePacked(candidates[maxVoted2].name, " won!")))));
        
        if (voteDone)
            return string(abi.encodePacked("Election leader is ", candidates[maxVoted].name));

        return string(abi.encodePacked("Election leader is currently ", candidates[maxVoted].name));
    }

    function getIsElectionDone() public view returns (bool){
        return block.timestamp >= (deployDate + 2 hours);
    }
}