/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/// @title Voting with delegation.
contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint lastRoundVoted;  // check if that person already voted
        uint vote;   // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    uint private voteRound;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(){
        voteRound = 0;
    }

    function getProposalsCount() public view returns(uint){
        return proposals.length;
    }

    function addProposal(string memory name) external {
        proposals.push(Proposal({
            name: name,
            voteCount: 0
        }));
    }

    function reset() public {
        for (uint i = 0; i < proposals.length; i++) {
            proposals[i].voteCount = 0;
        }
        voteRound++;
    }

    /// Give your vote to proposal `proposals[proposal].name`.
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.lastRoundVoted < voteRound, "Already voted.");
        sender.lastRoundVoted = voteRound;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount++;
    }
}