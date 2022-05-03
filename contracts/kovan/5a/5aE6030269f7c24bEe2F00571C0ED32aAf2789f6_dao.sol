// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract dao {

    struct Election {
        string name;
        uint256 countFor;
        uint256 countAgainst;
        uint256 timeOfCreation;
    }

    constructor() {
        electionCounter = 0;
    }

    uint256 electionCounter;
    mapping(uint256 => Election) public elections;

    mapping (address => mapping (uint256 => bool)) voteRegistry;

    function createElection(string memory name) public {
        Election memory election = Election(name, 0, 0, block.timestamp);
        elections[electionCounter] = election;
        electionCounter++;
    }

    function voteFor(uint256 _electionId) public {
        address _voter = msg.sender;
        require (voteRegistry[_voter][_electionId] == false, "Sender already voted in this post");
        elections[_electionId].countFor++;
        voteRegistry[_voter][_electionId] = true;
    }

    function voteAgainst(uint256 _electionId) public {
        address _voter = msg.sender;
        require (voteRegistry[_voter][_electionId] == false, "Sender already voted in this post");
        elections[_electionId].countAgainst++;
        voteRegistry[_voter][_electionId] = true;
    }


}