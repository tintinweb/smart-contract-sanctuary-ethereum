// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Candidate {
    int256 id;
    string name;
    uint256 voteCount;
}

struct voter {
    address voterAddress;
    bool isVoted;
    int256 candiateId;
}

contract VoteMethods {
    mapping(int256 => Candidate) public candidates;

    mapping(address => voter) public voters;

    // method to set candidate
    function setCandidate(int256 _id, string memory _name) public {
        Candidate memory candidate = Candidate(_id, _name, 0);
        candidates[_id] = candidate;
    }

    // method to get candidate
    function getCandidate(int256 _id) public view returns (string memory) {
        return candidates[_id].name;
    }

    // winner
    function _getWinner(int256 len)
        internal
        view
        virtual
        returns (string memory)
    {
        uint256 winnerVoteCount = 0;
        string memory winnerName = "";
        for (int256 i = 1; i <= len; i++) {
            if (candidates[i].voteCount > winnerVoteCount) {
                winnerVoteCount = candidates[i].voteCount;
                winnerName = candidates[i].name;
            }
        }
        return winnerName;
    }
}

contract Owner {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed");
        _; // which means rest of code comes here
    }
}

struct votingSystemDetails {
    uint256 totalVotes;
    uint256 totalCandidates;
    uint256 voteCount;
}

contract VotingSystem is VoteMethods, Owner {
    votingSystemDetails public vote_detail;

    function vote(int256 candidateId) public {
        require(voters[msg.sender].isVoted == false, "You have already voted");

        // check if candidate is in the mapping
        require(candidates[candidateId].id != 0, "Candidate does not exist");

        // vote count should be less than total votes
        require(
            vote_detail.voteCount < vote_detail.totalVotes,
            "Voting is over"
        );

        candidates[candidateId].voteCount++;
        vote_detail.voteCount++;
        // set voter as voted
        voter memory _voter = voter(msg.sender, true, candidateId); // creating voter object
        voters[msg.sender] = _voter; // setting voter object
    }

    // one time function to set total votes
    function setTotalVotes(uint256 _totalVotes) public onlyOwner {
        vote_detail.totalVotes = _totalVotes;
    }

    function setTotalCandidates(uint256 _totalCandidates) public onlyOwner {
        vote_detail.totalCandidates = _totalCandidates;
    }

    function getVoteCount() public view onlyOwner returns (uint256) {
        return vote_detail.voteCount;
    }

    function getWinner() public view onlyOwner returns (string memory) {
        return _getWinner(int256(vote_detail.totalCandidates));
    }
}