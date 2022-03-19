// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool isVoted;
        address votedPresidentAddress;
        bytes32 votedPresidentName;
    }

    struct PresidentialCandidate {
        bytes32 name;
        uint256 voteCount;
        bool isCandidate;
        bool isPresident;
    }

    enum VotingState {
        CLOSED,
        ONGOING,
        CALCULATING_WINNER,
        PRESIDENT_ELECTED
    }

    mapping(address => Voter) public voters;
    mapping(address => PresidentialCandidate) public presidentialCandidates;
    address[] public votersAddress;
    address[] public presidentialCandidatesAddress;
    address public administrator;
    VotingState public votingState;
    PresidentialCandidate public electedPresident;

    event VotersCreated(bytes32 message);

    modifier onlyAdministrator() {
        require(msg.sender == administrator, "You are not authorized!");
        _;
    }

    modifier isVotingClosed() {
        require(votingState == VotingState.CLOSED, "The voting is going!");
        _;
    }

    modifier isVotingOngoing() {
        require(
            votingState == VotingState.ONGOING,
            "The voting has not yet started!"
        );
        _;
    }

    modifier isPresidentElected() {
        require(
            votingState == VotingState.PRESIDENT_ELECTED,
            "A President has been elected!"
        );
        _;
    }

    constructor() {
        administrator = msg.sender;
        votingState = VotingState.CLOSED;
    }

    /// @dev Add a single voter
    function addVoter(address voterAddress)
        public
        isVotingClosed
        onlyAdministrator
    {
        Voter memory newVoter;
        voters[voterAddress] = newVoter;
        votersAddress.push(voterAddress);
    }

    /// @dev Add x amount of voters.
    function addVoters(address[] memory addresses)
        public
        isVotingClosed
        onlyAdministrator
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            address voterAddress = addresses[i];
            if (voters[voterAddress].isVoted == false) {
                continue;
            }
            addVoter(voterAddress);
        }
        emit VotersCreated("Voters are created.");
    }

    /// @dev Add address to be a presidential candidate and a voter.
    function addPresidentialCandidates(
        address[] memory addresses,
        bytes32[] memory name
    ) public isVotingClosed onlyAdministrator {
        require(
            addresses.length == name.length,
            "Map adresses array to name array!"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            address candidateAddress = addresses[i];
            if (presidentialCandidates[candidateAddress].isPresident == true) {
                continue;
            }
            presidentialCandidates[candidateAddress] = PresidentialCandidate(
                name[i],
                0,
                true,
                false
            );
            presidentialCandidatesAddress.push(candidateAddress);

            addVoter(candidateAddress);
        }
    }

    /// @dev Start voting state.
    function startVoting() public isVotingClosed onlyAdministrator {
        votingState = VotingState.ONGOING;
    }

    /// @dev Vote for a president.
    function votePresident(address presidentAddress) public isVotingOngoing {
        Voter memory voter = voters[msg.sender];
        require(voter.isVoted == false, "You already voted!");
        voter.isVoted = true;
        voter.votedPresidentAddress = presidentAddress;
        voter.votedPresidentName = presidentialCandidates[presidentAddress]
            .name;
        presidentialCandidates[presidentAddress].voteCount += 1;
    }

    /// @dev Compute for the winner and end the voting.
    function calculateWinnerAndEndVoting()
        public
        isVotingOngoing
        onlyAdministrator
        returns (bytes32 presidentName)
    {
        votingState = VotingState.CALCULATING_WINNER;
        for (uint256 i = 0; i < presidentialCandidatesAddress.length; i++) {
            address candidateAddress = presidentialCandidatesAddress[i];
            if (
                presidentialCandidates[candidateAddress].voteCount >
                electedPresident.voteCount
            ) {
                electedPresident = presidentialCandidates[candidateAddress];
            }
        }
        electedPresident.isCandidate = false;
        electedPresident.isPresident = true;
        votingState = VotingState.PRESIDENT_ELECTED; // Lock all functions

        return electedPresident.name;
    }

    /// @dev Reset: voteCount, voteState
    function resetVoting() public onlyAdministrator isPresidentElected {
        for (uint256 i = 0; i < votersAddress.length; i++) {
            Voter memory voter;
            voters[votersAddress[i]] = voter;
        }

        for (uint256 j = 0; j < presidentialCandidatesAddress.length; j++) {
            address candidateAddress = presidentialCandidatesAddress[j];
            presidentialCandidates[candidateAddress].isCandidate = true;
            presidentialCandidates[candidateAddress].isPresident = false;
            presidentialCandidates[candidateAddress].voteCount = 0;
        }
    }
}