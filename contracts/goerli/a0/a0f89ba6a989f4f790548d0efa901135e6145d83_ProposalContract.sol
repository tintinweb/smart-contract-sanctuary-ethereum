/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalContract {
    //creating a proposal contract that requires votes before it will be executed
    uint256 maxAmountToAcceptProposal;
    uint256 ID = 1;

    struct Proposal {
        string title;
        address ownerOfProposal;
        uint256 deadline;
        uint256 numberOfVotes;
        bool executed;
    }

    mapping(address => bool) hasVoted;
    mapping(uint256 => Proposal) proposals;

    event VoteCreated(string, uint256);
    event VotedNow(string, uint256);

    constructor(uint256 _maxAmountToAcceptProposal) {
        maxAmountToAcceptProposal = _maxAmountToAcceptProposal;
    }

    //create proposal
    function createProposal(string memory _title, uint256 _deadline) external {
        Proposal storage vote = proposals[ID];
        vote.title = _title;
        vote.ownerOfProposal = msg.sender;
        vote.deadline = block.timestamp + (_deadline * 1 seconds);
        emit VoteCreated("Voted created with id:", ID);
        ID++;
    }

    function voteProposal(uint256 _id) external {
        Proposal storage vote = proposals[_id];
        bool userVoted = hasVoted[msg.sender];
        require(!userVoted, "Error: user already voted");
        hasVoted[msg.sender] = true;
        require(vote.executed == false, "Error: proposal closed");
        require(
            vote.numberOfVotes <= maxAmountToAcceptProposal,
            "Error: max vote reached"
        );
        require(vote.deadline >= block.timestamp, "Error: deadline passed");
        vote.numberOfVotes += 1;
        if (vote.numberOfVotes == maxAmountToAcceptProposal) {
            vote.executed = true;
        }
        emit VotedNow("Voted for proposal:", vote.numberOfVotes);
    }

    function returnProposal(uint256 _id)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            bool
        )
    {
        Proposal memory _vote = proposals[_id];
        return (
            _vote.title,
            _vote.ownerOfProposal,
            _vote.deadline,
            _vote.numberOfVotes,
            _vote.executed
        );
    }
}