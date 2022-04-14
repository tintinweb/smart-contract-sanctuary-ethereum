/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        uint votedFor;
        address delegate;
    }

    struct Proposal {
        string name;
        uint count;
    }

    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    address public immutable chairPerson;

    constructor(string[] memory _proposalNames) {
        chairPerson = msg.sender;

        for (uint i=0; i < _proposalNames.length; i++) {
            proposals.push(
                Proposal({
                    name: _proposalNames[i],
                    count: 0
                })
            );
        }
    }

    function giveRightToVote(address _voter) external {
        require(chairPerson == msg.sender, "Only chairperson can give right to vote");

        Voter storage voter = voters[_voter];

        require(!voter.voted, "Already voted");
        require(voter.weight == 0);
        voter.weight = 1;
    }

    function vote(uint _voteFor) external {
        Voter storage voter = voters[msg.sender];
        require(voter.weight != 0, "Not allowed to vote");
        require(!voter.voted, "Already voted");

        voter.voted = true;
        voter.votedFor = _voteFor;

        proposals[_voteFor].count += voter.weight;
    }

    function delegate(address _to) external {
        Voter storage voter = voters[msg.sender];
        require(!voter.voted, "Already voted");
        require(_to != msg.sender, "Cannot delegate self");
        require(voter.weight != 0, "Not allowed to vote");
        
        while (voters[_to].delegate != address(0)) {
            _to = voters[_to].delegate;

            require(_to != msg.sender, "inf loop found");
        }

        voter.voted = true;
        voter.delegate = _to;

        Voter storage _delegate = voters[_to];

        if (_delegate.voted) {
            proposals[_delegate.votedFor].count += voter.weight;
        } else {
            _delegate.weight += voter.weight;
        }
    }

    function getWinningProposal() public view returns (string memory winningProposalName_, uint winningProposalIndex_) {
        uint mostVotes = 0;
        for (uint x=0; x < proposals.length; x++) {
            if (proposals[x].count > mostVotes) {
                winningProposalName_ = proposals[x].name;
                winningProposalIndex_ = x;
                mostVotes = proposals[x].count;
            }
        }
    }
}