// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {
    mapping(address => bool) public voters;
    struct Choice {
        uint256 id;
        string name;
        uint256 votes;
    }
    struct Ballot {
        uint256 id;
        string name;
        Choice[] choices;
        uint256 end;
    }
    address public admin;
    mapping(uint256 => Ballot) public ballots;
    uint256 public nextBallotId;
    mapping(address => mapping(uint256 => bool)) public votes;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function addVoters(address[] memory _voters) public onlyAdmin {
        for (uint256 i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
    }

    function createBallot(
        string memory _name,
        Choice[] memory _choices,
        uint256 offSet
    ) public onlyAdmin {
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = _name;
        ballots[nextBallotId].end = block.timestamp + offSet;
        for (uint256 i = 0; i < _choices.length; i++) {
            ballots[nextBallotId].choices.push(Choice(i, _choices[i].name, 0));
        }
        nextBallotId++;
    }

    function vote(uint256 _ballotId, uint256 _choiceId) public {
        require(voters[msg.sender] == true, "only voters can vote");
        require(votes[msg.sender][_ballotId] == false, "can not vote twice");
        require(ballots[_ballotId].end > block.timestamp, "vote time ended");
        votes[msg.sender][_ballotId] = true;
        ballots[_ballotId].choices[_choiceId].votes++;
    }

    function result(uint256 _ballotId) public view returns (Choice[] memory) {
        require(block.timestamp >= ballots[_ballotId].end);
        return ballots[_ballotId].choices;
    }
}