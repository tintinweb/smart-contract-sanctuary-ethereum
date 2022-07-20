/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Election {
    // Read/write candidate
    //string public candidate;
    event votedEvent(address indexed _from);

    // Constructor
    constructor() {
        addCandidate("candidate 1");
        addCandidate("candidate 2");
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint256 public candidatesCount;

    function addCandidate(string memory name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name, 0);
    }

    function vote(uint256 _candidateId) public returns (address) {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        emit votedEvent(msg.sender);
        return (msg.sender);
    }
}