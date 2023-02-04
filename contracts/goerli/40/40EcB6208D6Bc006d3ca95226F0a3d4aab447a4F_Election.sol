// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Election {
    // Election Variables
    bool status;
    uint8 numCandidates;
    uint8 numVoters;
    address chairman;

    struct Candidate {
        string candidate_name;
        string candidate_description;
        string imgHash;
        uint8 voteCount;
        uint8 candidateID;
    }

    struct Voter {
        uint8 candidate_id_voted;
        bool voted;
    }

    //Candidate List

    Candidate[] candidates;

    //voter mapping

    mapping(address => Voter) voters;

    // Constructor

    constructor() {
        chairman = msg.sender;
    }

    // function add a candidate

    function addCandidate(
        string memory name,
        string memory description,
        string memory imgHash
    ) public {
        require(chairman == msg.sender, "Only Chairman can add a candidate");
        candidates.push(
            Candidate(name, description, imgHash, 0, numCandidates)
        );
        numCandidates++;
    }

    //function to vote and check for double voting

    function vote(uint8 candidateID) public {
        //if false the vote will be registered
        require(!voters[msg.sender].voted, "Error:You cannot double vote");
        voters[msg.sender] = Voter(candidateID, true);
        numVoters++;
        candidates[candidateID].voteCount++;
    }

    //function to get all the candidates

    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    //function to get count of candidates

    function getNumOfCandidates() public view returns (uint8) {
        return numCandidates;
    }

    function getNumOfVoters() public view returns (uint8) {
        return numVoters;
    }

    function getChairman() public view returns (address) {
        return chairman;
    }

    function getCandidate(
        uint8 candidateID
    ) public view returns (Candidate memory) {
        return candidates[candidateID];
    }

    function winnerCandidate() public view returns (Candidate memory) {
        uint8 largestVotes = candidates[0].voteCount;
        uint8 candidateID;
        for (uint8 i = 1; i < numCandidates; i++) {
            if (largestVotes < candidates[i].voteCount) {
                largestVotes = candidates[i].voteCount;
                candidateID = i;
            }
        }
        return candidates[candidateID];
    }
}