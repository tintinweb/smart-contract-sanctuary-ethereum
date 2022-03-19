// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    enum VotingState {
        CLOSED,
        ONGOING
    }

    struct Voter {
        bool canVote;
        bool isVoted;
        address votedPresident;
    }

    struct PresidentialCandidate {
        bytes32 name;
        uint256 voteCount;
        bool isPresident;
    }

    mapping(address => Voter) public voters;
    mapping(address => PresidentialCandidate) public presidentialCandidates;
    address[] public presidentialCandidatesAddress;
    address[] public votersAddress;

    address public administrator;
    VotingState public votingState;

    event VotersCreated(bytes32 message);

    constructor() {
        administrator = msg.sender;
        votingState = VotingState.CLOSED;
    }

    // ADD VOTERS
    function addVoters(bytes20[] memory addresses) public {
        require(msg.sender == administrator, "You are not authorized!");
        require(
            votingState == VotingState.CLOSED,
            "You can't add voters anymore!"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            address voterAddress = address(addresses[i]);
            if (voters[voterAddress].canVote || voters[voterAddress].isVoted)
                continue;
            Voter memory newVoter;
            newVoter.canVote = true;
            newVoter.isVoted = false;
            voters[voterAddress] = newVoter;
            votersAddress.push(voterAddress);
        }
        emit VotersCreated("Voters are created.");
    }

    // ADD PRES CANDIDATES
    

    // VOTE
    // CHECKWINNER
}