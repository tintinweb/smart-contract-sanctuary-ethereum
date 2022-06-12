/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal {
        string name;
        uint voteCount;
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson && !voters[voter].voted && voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);

        require(to != msg.sender);

        while(voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender);
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];

        if(delegate_.voted) { 
            proposals[delegate_.vote].voteCount += sender.weight;
        }
        delegate_.weight += sender.weight;

    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for(uint p = 0; p < proposals.length; p++) {
            if(proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() public view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}