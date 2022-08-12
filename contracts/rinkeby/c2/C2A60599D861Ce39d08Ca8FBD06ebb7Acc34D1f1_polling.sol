//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Participation__NotOpen();
error Participation__AlreadyOpen();
error Voting__NotOpen();
error Voter__AlreadyEntered();

contract polling {
    enum PollingState {
        OPEN,
        VOTING,
        CLOSED
    }

    struct candidate {
        uint256 id;
        address add;
        string name;
        uint256 votes;
    }

    uint256 private s_numOfCandidates = 0;
    PollingState private s_pollingState;
    address[] private s_voters;
    candidate[] private s_candidates;

    event CandidateEnter(address indexed candidate);
    event VoterEnter(address indexed candidate);
    event VotingStarted();

    function enterAsCandidate(string memory _name) public {
        if (s_pollingState != PollingState.OPEN) {
            revert Participation__NotOpen();
        }
        s_candidates.push(candidate(s_numOfCandidates, msg.sender, _name, 0));
        s_numOfCandidates++;
        emit CandidateEnter(msg.sender);
    }

    function startVoting() public {
        if (s_pollingState == PollingState.VOTING) {
            revert Participation__AlreadyOpen();
        }
        s_pollingState = PollingState.VOTING;
        emit VotingStarted();
    }

    function enterVoter() public {
        if (s_pollingState != PollingState.VOTING) {
            revert Voting__NotOpen();
        }
        for (uint i = 0; i < s_voters.length; i++) {
            if (msg.sender == s_voters[i]) {
                revert Voter__AlreadyEntered();
            }
        }
        s_voters.push(msg.sender);
    }

    function vote(uint256 id) public {
        s_candidates[id].votes++;
    }

    function getNumberOfCandidates() public view returns (uint256) {
        return s_numOfCandidates;
    }

    function getPollingState() public view returns (PollingState) {
        return s_pollingState;
    }

    function getCandidate(uint256 index) public view returns (address) {
        return s_candidates[index].add;
    }

    function getVoter(uint256 index) public view returns (address) {
        return s_voters[index];
    }
}