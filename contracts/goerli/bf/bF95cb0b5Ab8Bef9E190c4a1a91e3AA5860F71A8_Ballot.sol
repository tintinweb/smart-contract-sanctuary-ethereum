// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation.
contract Ballot {
    struct Voter {
        uint256 weight; /// Weight is accumulated by delegation
        bool voted; /// If true, the person has already voted
        address delegate; /// person delegated to
        uint256 vote; /// index of the voted proposal
    }

    struct Proposal {
        bytes32 name; /// Short name (up to 32 bytes)
        uint256 voteCount; /// Number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    uint256 public totalVoteCount;

    event NewVoter(address indexed voter);

    event Delegated(
        address indexed voter,
        address indexed finalDelegate,
        uint256 finalWeight,
        bool voted,
        uint256 proposal,
        uint256 proposalVotes
    );

    event Voted(
        address indexed voter,
        uint256 indexed proposal,
        uint256 weight
    );

    /// Create a new ballot to choose one of 'proposalNames'
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // TODO: Allow giving of rights to multiple users
    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "Only chairman can give right to vote"
        );
        require(!voters[voter].voted, "The voter already voted.");
        require(
            voters[voter].weight == 0,
            "The voter already has the right to vote."
        );

        voters[voter].weight = 1;

        emit NewVoter(voter);
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];

        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

        // Forward the delegation as long as 'to' also delegated
        // Such loops are dangerous because they might need more gas then available if they run too long
        // In this case, the delegation will not be executed
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];

        require(delegate_.weight >= 1, "Delegate does not have right to vote");

        sender.voted = true;

        sender.delegate = to;

        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
            totalVoteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }

        emit Delegated(
            msg.sender,
            to,
            delegate_.weight,
            delegate_.voted,
            delegate_.vote,
            proposals[delegate_.vote].voteCount
        );
    }

    function vote(uint256 proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;

        // If proposal is out of the rage of the array,
        // this will throw automatically and revert all changes
        proposals[proposal].voteCount += sender.weight;
        totalVoteCount += sender.weight;

        emit Voted(msg.sender, proposal, sender.weight);
    }

    // TODO: What to do if there is a tie
    function winningProposal() public view returns (uint256 winningProposal_) {
        require(totalVoteCount > 0, "There are no votes yet.");

        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // TODO: Add timelock
    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}