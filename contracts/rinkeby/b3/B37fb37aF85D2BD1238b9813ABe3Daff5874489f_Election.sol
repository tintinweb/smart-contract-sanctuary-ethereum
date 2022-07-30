// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

contract Election {
    // Variable and Data Structures
    address internal owner;
    uint256 public candidateCount;

    struct Candidate {
        uint256 id;
        string name;
        uint256 votes;
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public votedOrNot;

    // Events
    event Voted(uint256 id, string name, uint256 voteCount);

    event electionUpdate(uint256 indexed candidateId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "not the owner");
        _;
    }

    // Constructor
    constructor() {
        msg.sender == owner;
    }

    // Functions
    function addCandiate(string memory name) public onlyOwner {
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!votedOrNot[msg.sender], "You already voted for the candiate");
        // require a valid candidate.
        require(_candidateId > 0 && _candidateId < candidateCount);

        candidates[_candidateId].votes++;
        votedOrNot[msg.sender] = false;

        emit Voted(
            _candidateId,
            candidates[_candidateId].name,
            candidates[_candidateId].votes
        );
    }
}