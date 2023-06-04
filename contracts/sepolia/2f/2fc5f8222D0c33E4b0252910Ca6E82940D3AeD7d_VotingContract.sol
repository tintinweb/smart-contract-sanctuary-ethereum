// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract VotingContract {

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    address public owner;

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;

    uint256 public candidateCount;

    constructor(){
        owner = msg.sender;
        addCandidate("Alex");
        addCandidate("Bay");

    }

    function addCandidate(string memory _name) public {
        require(msg.sender == owner, "Only owner can add candidates");
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!voters[msg.sender], "You have voted!");
        require(_candidateId <= candidateCount && _candidateId >= 1, "Invalid candidate Id");
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }

}