/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract KMUTTElection {
    
    struct Voter {
        uint weight;
        bool voted;
        uint vote;
    }
    
    struct Candidate { 
        string name;
        uint voteCount;
    }
    
    address public chairperson;
    
    mapping(address => Voter) public voters;

    Candidate[] public candidates;

    string[] public candidateNames = ["\xe0\xb9\x84\xe0\xb8\xa1\xe0\xb9\x88\xe0\xb8\x9b\xe0\xb8\xa3\xe0\xb8\xb0\xe0\xb8\xaa\xe0\xb8\x87\xe0\xb8\x84\xe0\xb9\x8c\xe0\xb8\xa5\xe0\xb8\x87\xe0\xb8\x84\xe0\xb8\xb0\xe0\xb9\x81\xe0\xb8\x99\xe0\xb8\x99",
                                        "\xe0\xb8\x9e\xe0\xb8\xa3\xe0\xb8\xa3\xe0\xb8\x84\xe0\xb8\x9e\xe0\xb8\xb0\xe0\xb8\xa5\xe0\xb8\xb1\xe0\xb8\x87\xe0\xb8\x9b\xe0\xb8\xa3\xe0\xb8\xb0\xe0\xb8\x8a\xe0\xb8\xb2\xe0\xb8\xac\xe0\xb8\xb1\xe0\xb8\x94",
                                         "\xe0\xb8\x9e\xe0\xb8\xa3\xe0\xb8\xa3\xe0\xb8\x84\xe0\xb9\x80\xe0\xb8\x9e\xe0\xb8\xb7\xe0\xb9\x88\xe0\xb8\xad\xe0\xb8\xa1\xe0\xb8\xad",
                                          "\xe0\xb8\x9e\xe0\xb8\xa3\xe0\xb8\xa3\xe0\xb8\x84\xe0\xb8\xa1\xe0\xb8\x94\xe0\xb8\xaa\xe0\xb9\x89\xe0\xb8\xa1"];
    uint public numCandidates;
    
    uint public closeDate;
    
    event Voted(address sender, uint candidate, uint voteCount);
    event GaveRightToVote(address voter);
    
    constructor() {
        chairperson = msg.sender;
        numCandidates = candidateNames.length;
        
        closeDate = block.timestamp + 142 hours; //5days 22hours
        
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(
                Candidate({name: candidateNames[i], voteCount: 0})
            );
        }
    }
    
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "only chairperson can give right to vote");
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0, "The voter already have been weight");
        voters[voter].weight = 1;
        
        emit GaveRightToVote(voter);
    }
    
    function vote(uint candidate) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        require(block.timestamp < closeDate, "The voting is closed");
        
        sender.voted = true;
        sender.vote = candidate;
        
        candidates[candidate].voteCount++;
        
        emit Voted(msg.sender, candidate, candidates[candidate].voteCount);
    }
    
    function winnigCandidate() public view returns (uint winningCandidate_) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidate_ = i;
            }
        }
    }
    
    function winnerName() public view returns (string memory) {
        return candidates[winnigCandidate()].name;
    }
}