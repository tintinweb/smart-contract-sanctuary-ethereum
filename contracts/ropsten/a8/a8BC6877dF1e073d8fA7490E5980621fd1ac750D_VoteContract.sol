// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoteContract {
    // voted event
    event votedEvent(uint256 indexed _candidateId);

    struct Candidate {
        uint256 id;
        string name; // 候选人的名字
        uint256 voteCount;
    }
    mapping(address => bool) public voters;

    mapping(uint256 => Candidate) public candidates;
    uint256 public candidatesCount;

    constructor() {
        addCandidate(unicode"Tiny 熊");
        addCandidate(unicode"Big 熊");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }
}