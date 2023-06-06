/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Voting{

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        string name;
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    string[] public proposals_list;

    constructor() {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        proposals_list.push("0");
        proposals.push(Proposal({
            name: "0",
            voteCount: 0
        }));
    }

    function voter_proposal(string memory names) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to proposal");
        proposals_list.push(names);
        proposals.push(Proposal({
            name: names,
            voteCount: 0
        }));
    }

    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function vote(uint proposal) public {    
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }

    function return_proposal() public view returns(string[] memory Proposals_){
        Proposals_ = proposals_list;
    }

    function restart() public{
        for (uint p = 0; p < proposals.length; p++) {
            proposals_list.pop();
            proposals.pop();
        }
    }
}