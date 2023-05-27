/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

/**
*/

//The community decides on their representatives, whom they can delegate their stakes to.                                                            
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Swap {
    struct Stakeholder {
        bool isStakeholder;
        uint256 weight;
    }

    mapping(address => Stakeholder) public stakeholders;
    address[] public stakeholdersList;

    struct Proposal {
        string description;
        address proposer;
        uint256 minVotes;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes;

    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event VoteCasted(uint256 indexed proposalId, address indexed voter, uint256 aggregatedVotes);
    event ProposalExecuted(uint256 indexed proposalId);


    modifier onlyStakeholder() {
        require(stakeholders[msg.sender].isStakeholder, "Restricted to stakeholders");
        _;
    }

    function addStakeholder(address account, uint256 weight) public {
        stakeholders[account] = Stakeholder(true, weight);
        stakeholdersList.push(account);
    }
   
    function removeStakeholder(address account) public {
        delete stakeholders[account];

        for (uint i = 0; i < stakeholdersList.length - 1; i++) {
            if (stakeholdersList[i] == account) {
                stakeholdersList[i] = stakeholdersList[stakeholdersList.length - 1];
                break;
            }
        }

        stakeholdersList.pop();
    }

    function createProposal(string memory description) public onlyStakeholder {
        uint256 minVotes = (stakeholdersList.length * 2) / 3;

        proposals.push(Proposal(description, msg.sender, minVotes, false));
        emit ProposalCreated(proposals.length - 1, description, msg.sender);
    }

    function vote(uint256 proposalId) public onlyStakeholder {
        require(!proposalVotes[proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[proposalId][msg.sender] = true;
        proposals[proposalId].minVotes -= stakeholders[msg.sender].weight;

        emit VoteCasted(proposalId, msg.sender, stakeholders[msg.sender].weight);

        if (proposals[proposalId].minVotes <= 0) {
            executeProposal(proposalId);
        }
    }

    function executeProposal(uint256 proposalId) private {
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.executed, "Proposal already executed");
        require(proposal.minVotes <= 0, "Not enough votes");

       

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}