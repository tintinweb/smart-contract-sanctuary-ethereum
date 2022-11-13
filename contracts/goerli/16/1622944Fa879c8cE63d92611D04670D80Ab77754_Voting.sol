// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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
    mapping(uint256 => Ballot) ballots;
    uint256 nextBallotId;
    address public admin;
    mapping(address => mapping(uint256 => bool)) public votes;

    constructor() {
        admin = msg.sender;
    }

    function addVoters(address[] calldata _voters) external onlyAdmin {
        for (uint256 i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
    }

    function createBallot(
        string memory name,
        string[] memory choices,
        uint256 offset
    ) public onlyAdmin {
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = name;
        ballots[nextBallotId].end = block.timestamp + offset;
        for (uint256 i = 0; i < choices.length; i++) {
            ballots[nextBallotId].choices.push(Choice(i, choices[i], 0));
        }
        nextBallotId++;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function vote(uint256 ballotId, uint256 choiceId) external {
        require(voters[msg.sender] == true, "only voters can vote");
        require(
            votes[msg.sender][ballotId] == false,
            "voter can only vote once"
        );
        require(
            block.timestamp < ballots[ballotId].end,
            "can only vote until ballot end date"
        );
        votes[msg.sender][ballotId] = true;
        ballots[ballotId].choices[choiceId].votes++;
    }

    function result(uint256 ballotId) external view returns (Choice[] memory) {
        require(
            block.timestamp >= ballots[ballotId].end,
            "cannot see the ballot result before ballot end"
        );
        return ballots[ballotId].choices;
    }
}