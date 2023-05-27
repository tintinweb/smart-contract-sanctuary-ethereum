/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.1 <0.9.0;

contract Poll {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    //creates a mapping called voters that maps addresses to a bool value to track if they voted or not
    mapping(address => bool) public voters;
    // creates a mapping called candidates that maps a uint called the candidateID to candidates in our system
    mapping(uint => Candidate) public candidates;
    // init candidatesCount to 0
    uint8 public candidatesCount = 0;

    // add candidates to candidates mapping
    constructor () {
        addCandidate("Hamza Saht");
        addCandidate("Omar Hussein");
        addCandidate("Badi Mohammad");
        }
    // a function to add candidates to candidates mapping based on candidate ID
    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint8 _candidateId) public {
        // make sure the voter did not vote before
        require(!voters[msg.sender], "You have already Voted");
        voters[msg.sender] = true;
        // make sure the voter is voting for a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Please enter a valid candidate");
        candidates[_candidateId].voteCount++;
    }
    // a function to return a candidate's vote count
    function getCandidatesVoteCount(uint8 _candidateId) public view returns (uint)
    {
        return candidates[_candidateId].voteCount;
    }
}