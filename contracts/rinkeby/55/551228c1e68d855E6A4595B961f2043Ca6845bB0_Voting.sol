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
    address[] public votersAddress;
    address[] public presidentialCandidatesAddress;

    address public administrator;
    VotingState public votingState;

    event VotersCreated(bytes32 message);

    constructor() {
        administrator = msg.sender;
        votingState = VotingState.CLOSED;
    }

    // ADD VOTERS
    function addVoters(bytes20[] memory addresses) public {
        require(
            votingState == VotingState.CLOSED,
            "You can't add voters anymore!"
        );
        require(msg.sender == administrator, "You are not authorized!");
        for (uint256 i = 0; i < addresses.length; i++) {
            address voterAddress = address(addresses[i]);
            if (voters[voterAddress].canVote || voters[voterAddress].isVoted)
                continue;
            Voter memory newVoter;
            newVoter.canVote = true;
            // newVoter.isVoted = false;
            voters[voterAddress] = newVoter;
            votersAddress.push(voterAddress);
        }
        emit VotersCreated("Voters are created.");
    }

    // ADD PRES CANDIDATES
    function addPresidentialCandidates(
        bytes20[] memory addresses,
        bytes32[] memory name
    ) public {
        require(
            votingState == VotingState.CLOSED,
            "The voting has started, you can't add candidates anymore."
        );
        require(msg.sender == administrator, "You are not authorized!");
        require(
            addresses.length == name.length,
            "Map adresses array to name array!"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            address candidateAddress = address(addresses[i]);
            if (presidentialCandidates[candidateAddress].isPresident == false)
                continue;
            presidentialCandidates[candidateAddress] = PresidentialCandidate(
                name[i],
                0,
                false
            );
            presidentialCandidatesAddress.push(candidateAddress);

            //ADD CANDIDATE AS VOTER TOO
            Voter memory newVoter;
            newVoter.canVote = true;
            // newVoter.isVoted = false;
            voters[candidateAddress] = newVoter;
            votersAddress.push(candidateAddress);
        }
    }

    // VOTE
    // CHECKWINNER
}