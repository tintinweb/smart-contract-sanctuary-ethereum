// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dao {
    struct Vote {
        bytes32 id;
        string title;
        string description;
        address creator;
        uint256 createdTime;
        uint256 timeLimit; // in seconds
    }
    mapping(address => bool) public members;
    mapping(bytes32 => bool) public voteIds;
    Vote[] votes;

    constructor() {
        members[msg.sender] = true;
    }

    function addMember(address _newMember) external onlyMembers returns (bool) {
        members[_newMember] = true;
        return true;
    }

    function createVote(
        string memory _title,
        string memory _description,
        uint256 _timeLimit
    ) external onlyMembers returns (bool) {
        Vote memory vote;
        bytes32 _id = keccak256(abi.encodePacked(_title, _description));

        if (voteIds[_id]) {
            return false;
        }

        vote.id = _id;
        vote.title = _title;
        vote.description = _description;
        vote.timeLimit = _timeLimit;
        vote.createdTime = block.timestamp;
        vote.creator = msg.sender;

        votes.push(vote);
        voteIds[_id] = true;

        return true;
    }

    function getVotesTotal() public view returns (uint256) {
        return votes.length;
    }

    function getVotes() public view returns (Vote[] memory) {
        return votes;
    }

    receive() external payable {}

    modifier onlyMembers() {
        require(
            members[msg.sender] == true,
            "Only members can call this function"
        );
        _;
    }
}