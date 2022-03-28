// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ballot {
    // storage
    address public chairperson;

    // custom type to represent a single voter
    struct Voter {
        address delegate; // person delegated to vote on your behalf
        uint256 vote; // index of the voted proposal
        uint256 weight; // weight of the voter
        bool voted; // whether voter has voted or not
    }

    // custom type for a single proposal
    struct Proposal {
        bytes32 name; // 32-bytes (eg. Migrate to Eth2)
        uint256 voteCount; // number of accumulated votes
    }

    // given address, return Voter
    mapping(address => Voter) public voters;

    // array of `Proposal`
    Proposal[] public proposals;

    constructor(bytes32[] memory proposalName) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // for proposal in proposalName:
        //    proposals + [Proposal(proposal, 0)]
        for (uint256 i = 0; i < proposalName.length; i++) {
            proposals.push(Proposal({name: proposalName[i], voteCount: 0}));
        }
    }

    function giveRightToVote(address _voter) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can assign rights to vote"
        );
        require(!voters[_voter].voted, "The voter has already voted.");
        require(
            voters[_voter].weight == 0,
            "Voter already has the right to vote."
        );

        voters[_voter].weight = 1;
    }

    function delegate(address _to) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted. Cannot delegate.");
        require(msg.sender != _to, "You cannot delegate to yourself.");
        // prevent loop in delegation
        // a -> b -> a
        // a is msg.sender
        // b is voters[_to]
        // b -> delegating back to a
        while (voters[_to].delegate != address(0)) {
            _to = voters[_to].delegate;

            require(_to != msg.sender, "Found loop in delegation");
        }

        Voter storage delegate_ = voters[_to];

        // delegate to anybody as long the delegate has rights to vote
        require(delegate_.weight > 0);
        sender.voted = true;
        sender.delegate = _to;
        // actual delegation. two scenarios:
        // 1. if the delegate have not voted yet
        if (!delegate_.voted) {
            delegate_.weight += sender.weight;
        } else {
            // 2. if the delegate has already voted
            proposals[delegate_.vote].voteCount += sender.weight;
        }
    }

    // person A voted for proposal B
    function vote(uint256 _proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "No rights to vote");
        require(!sender.voted, "You already voted");

        sender.vote = _proposal;
        sender.voted = true;

        proposals[_proposal].voteCount += sender.weight;
    }

    // return the index of the winning Proposal
    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;

        // for proposal in proposals:
        //   if proposal.voteCount > winningVoteCount:
        //      winningVoteCount = proposal.voteCount
        //      winningProposal = proposal

        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}