// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

error Ballot__OnlyChairpersonCanGiveRightToVote();
error Ballot__VoterAlreadyVoted();
error Ballot__DelegatorNoRightToVote();
error Ballot__AlreadyVoted();
error Ballot__NoSelfDelegation();
error Ballot__LoopInDelegation();
error Ballot__NoRightToVote();

/// @title Voting with delegation.
contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint192 weight; // weight is accumulated by delegation
        uint64 vote; // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name; // short name (up to 32 bytes)
        uint256 voteCount; // number of accumulated votes
    }

    address public chairperson;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint256 i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) external {
        // If the first argument of `require` evaluates
        // to `false`, execution terminates and all
        // changes to the state and to Ether balances
        // are reverted.
        // This used to consume all gas in old EVM versions, but
        // not anymore.
        // It is often a good idea to use `require` to check if
        // functions are called correctly.
        // As a second argument, you can also provide an
        // explanation about what went wrong.
        if (msg.sender != chairperson)
            revert Ballot__OnlyChairpersonCanGiveRightToVote();

        if (voters[voter].voted) revert Ballot__VoterAlreadyVoted();
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) external {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        if (voters[msg.sender].weight == 0)
            revert Ballot__DelegatorNoRightToVote();

        if (sender.voted) revert Ballot__AlreadyVoted();

        if (to == msg.sender) revert Ballot__NoSelfDelegation();

        // Forward the delegation as long as
        // `to` also delegated.
        // In general, such loops are very dangerous,
        // because if they run too long, they might
        // need more gas than is available in a block.
        // In this case, the delegation will not be executed,
        // but in other situations, such loops might
        // cause a contract to get "stuck" completely.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            if (to == msg.sender) revert Ballot__LoopInDelegation();
        }

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        Voter storage delegate_ = voters[to];

        // Voters cannot delegate to wallets that cannot vote.
        if (delegate_.weight == 0) revert Ballot__DelegatorNoRightToVote();
        sender.voted = true;
        sender.delegate = to;
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
    function vote(uint64 proposal) external {
        Voter storage sender = voters[msg.sender];
        if (sender.weight == 0) revert Ballot__NoRightToVote();
        if (sender.voted) revert Ballot__AlreadyVoted();
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view returns (uint256 winningProposal_) {
        Proposal[] memory proposals_ = proposals;

        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals_.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
        // Doesn't work for some reason
        // require(
        //     proposals[winningProposal_].voteCount != 0,
        //     "No votes have been casted yet"
        // );
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() external view returns (bytes32 winnerName_) {
        // TODO
        // require(
        //     proposals[winningProposal()].voteCount != 0,
        //     "No votes have been casted yet"
        // );
        winnerName_ = proposals[winningProposal()].name;
    }

    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }
}