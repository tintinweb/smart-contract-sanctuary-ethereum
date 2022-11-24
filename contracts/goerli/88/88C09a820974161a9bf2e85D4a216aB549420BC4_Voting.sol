pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT

contract Voting {
    struct Candidate {
        string name;
        uint voteCount;
        uint id;
    }
    struct Voter {
        bool voted;
        uint votedFor;
    }

    Candidate[] public candidates;
    mapping(address => Voter) public voters;

    function addCandidate(string memory name) public {
        candidates.push(Candidate(name, 0, candidates.length));
    }

    function vote(uint candidateId) public {
        //require(!voters[msg.sender].voted, "Already voted");
        require(voters[msg.sender].voted == false, "Already voted");
        require(candidateId < candidates.length, "Invalid candidate");
        voters[msg.sender] = (Voter(true, candidateId));
        candidates[candidateId].voteCount++;
    }

    function viewVotes(uint candidateId) public view returns (uint){
        require(candidateId < candidates.length, "Invalid candidate");
        return candidates[candidateId].voteCount;
    }

    function viewCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function viewVoter(
        address voterAddress
    ) public view returns (Voter memory) {
        return voters[voterAddress];
    }

    function pickWinner() public view returns (string memory) {
        uint winningVoteCount = 0;
        string memory winner;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winner = candidates[i].name;
            }
        }
        return winner;
    }
}