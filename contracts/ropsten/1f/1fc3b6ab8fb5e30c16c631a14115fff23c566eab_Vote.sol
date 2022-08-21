// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



contract Vote {

    struct Voter {
        uint count;
        bool isVoted;  
        address delegate; 
        uint voteFor;   
    }

    address public owner;
    uint[] public proposalVoteCounter;

    mapping(address => Voter) public voters;

    constructor(uint proposalsCounts) {

        owner = msg.sender;
        voters[owner].count = 1;

        for (uint i = 0; i < proposalsCounts; i++) {
            proposalVoteCounter.push(0);
        }
    }

    function vote(uint proposal) public {
        require(proposal < proposalVoteCounter.length);
        Voter storage sender = voters[msg.sender];
        require(sender.count != 0);
        require(!sender.isVoted);
        sender.isVoted = true;
        sender.voteFor = proposal;
        proposalVoteCounter[proposal] += sender.count;
    }




    function delegateVote(address voter) public {
        require(msg.sender == owner);
        require(!voters[voter].isVoted);
        require(voters[voter].count == 0);

        voters[voter].count = 1;
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.isVoted);
        require(to != msg.sender);

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender);
        }

        sender.isVoted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.isVoted) {
            proposalVoteCounter[delegate_.voteFor] += sender.count;
        } else {
            delegate_.count += sender.count;
        }
    
    }

    function getWinner() public view returns (uint winnerProposal) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposalVoteCounter.length; p++) {
            if (proposalVoteCounter[p] > winningVoteCount) {
                winningVoteCount = proposalVoteCounter[p];
                winnerProposal = p;
            }
        }
    }

    function hasRightToVote(address voter) public view returns (bool){
        return voters[voter].count != 0;
    }
}