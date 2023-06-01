// SPDX-License-Identifier: MIT

// This contract represents a democratic voting system where users can create proposals, grant voting rights, and vote for proposals.

pragma solidity ^0.8.9;

contract FreeCouncil {
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    address public chairperson;
    mapping(address => bool) public voters;
    Proposal[] public proposals;

    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Only the chairperson can perform this action.");
        _;
    }

    constructor() {
        chairperson = msg.sender;
    }

    function addProposal(string memory description) public onlyChairperson {
        proposals.push(Proposal(description, 0));
    }

    function giveRightToVote(address voter) public onlyChairperson {
        require(!voters[voter], "This voter has already been granted the right to vote.");
        voters[voter] = true;
    }

    function vote(uint256 index) public {
        require(voters[msg.sender], "This address does not have the right to vote.");
        require(index < proposals.length, "Invalid proposal index.");

        proposals[index].voteCount += 1;
        // Remove the voter's right to vote after they cast their vote
        voters[msg.sender] = false;
    }

    function winningProposal() public view returns (uint256 winningIndex) {
        uint256 winningCount = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningCount) {
                winningCount = proposals[i].voteCount;
                winningIndex = i;
            }
        }
    }

    function proposalDescription(uint256 index) public view returns (string memory) {
        require(index < proposals.length, "Invalid proposal index.");
        return proposals[index].description;
    }
}