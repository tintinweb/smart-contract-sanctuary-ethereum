// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/// @title Voting with delegation.

contract Ballot {
    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint256 vote; // index of the voted proposal
    }

    struct Proposal {
        bytes32 name; // short name (up to 32 bytes)
        uint256 voteCount; // number of accumulated votes
    }

    uint256 public LARGE_WEIGHT = 5;
    uint256 public MEDIUM_WEIGHT = 2;
    uint256 public NORMAL_WEIGHT = 1;

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Only chairperson can access");
        _;
    }
    modifier voteOnlyOnce(address voter) {
        require(!voters[voter].voted, "The voter already voted.");
        _;
    }

    /// Create a new ballot to choose one of `proposalNames`.
    constructor() {
        chairperson = msg.sender;
        voters[chairperson].weight = LARGE_WEIGHT;
    }

    // For each of the provided proposal names,
    // create a new proposal object and add it
    // to the end of the array.
    function addProposals(bytes32[] memory proposalNames)
        public
        onlyChairperson
    {
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter)
        public
        onlyChairperson
        voteOnlyOnce(voter)
    {
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) public {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;

        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint256 proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function getAllProposals() external view returns (Proposal[] memory) {
        Proposal[] memory items = new Proposal[](proposals.length);
        for (uint256 i = 0; i < proposals.length; i++) {
            items[i] = proposals[i];
        }
        return items;
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() public view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}