// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        uint8 vote;
        bool isVoted;
        address votedPresidentAddress;
        string votedPresidentName;
    }

    struct PresidentialCandidate {
        string name;
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
    uint256 public voterCount;
    uint256 public presidentialCandidateCount;
    uint256 public totalVotes;
    address public administrator;
    VotingState public votingState;
    PresidentialCandidate public electedPresident;
    address public electedPresidentAddress;

    event VotersCreated(string message);
    event CandidatesCreated(string message);
    event VoterHasVoted(
        address indexed voter,
        address indexed votedPresidentAddress,
        string votedPresidentName,
        string message
    );
    event PresidentElected(
        address indexed votedPresidentAddress,
        string votedPresidentName,
        uint256 voteCount,
        string message
    );
    event ResetVoting(string message);

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

    function addVoter(address voterAddress) public {
        if (voters[voterAddress].vote == 1) {
            return;
        }
        Voter memory newVoter;
        newVoter.vote = 1;
        voters[voterAddress] = newVoter;
        votersAddress.push(voterAddress);
        voterCount += 1;
    }

    /// @dev Add x amount of voters.
    function addVoters(address[] memory addresses)
        public
        isVotingClosed
        onlyAdministrator
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            address voterAddress = addresses[i];
            addVoter(voterAddress);
        }
        emit VotersCreated("Voters are created.");
    }

    /// @dev Add address to be a presidential candidate and a voter.
    function addPresidentialCandidates(
        address[] memory addresses,
        string[] memory name
    ) public isVotingClosed onlyAdministrator {
        require(addresses.length > 0, "Need some inputs!");
        require(
            addresses.length == name.length,
            "Map adresses array to name array!"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            address candidateAddress = addresses[i];
            if (presidentialCandidates[candidateAddress].isCandidate == true) {
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
            presidentialCandidateCount += 1;
        }
        emit CandidatesCreated("Candidates are created.");
    }

    /// @dev Start voting state.
    function startVoting() public isVotingClosed onlyAdministrator {
        votingState = VotingState.ONGOING;
    }

    /// @dev Vote for a president.
    function votePresident(address presidentAddress) public isVotingOngoing {
        Voter storage voter = voters[msg.sender];
        require(voter.isVoted == false, "You already voted!");
        require(
            presidentialCandidates[presidentAddress].isCandidate == true,
            "Candidate does not exist!"
        );
        voter.isVoted = true;
        voter.votedPresidentAddress = presidentAddress;
        voter.votedPresidentName = presidentialCandidates[presidentAddress]
            .name;
        presidentialCandidates[presidentAddress].voteCount += 1;
        voter.vote = 0;
        totalVotes += 1;
        emit VoterHasVoted(
            msg.sender,
            voter.votedPresidentAddress,
            voter.votedPresidentName,
            "Voted successfully!"
        );
    }

    /// @dev Compute for the winner and end the voting.
    function calculateWinnerAndEndVoting()
        public
        isVotingOngoing
        onlyAdministrator
        returns (string memory presidentName)
    {
        votingState = VotingState.CALCULATING_WINNER;
        for (uint256 i = 0; i < presidentialCandidatesAddress.length; i++) {
            address candidateAddress = presidentialCandidatesAddress[i];
            if (
                presidentialCandidates[candidateAddress].voteCount >
                electedPresident.voteCount
            ) {
                electedPresident = presidentialCandidates[candidateAddress];
                electedPresidentAddress = candidateAddress;
            }
        }
        electedPresident.isCandidate = false;
        electedPresident.isPresident = true;
        votingState = VotingState.PRESIDENT_ELECTED; // Lock all functions
        emit PresidentElected(
            electedPresidentAddress,
            electedPresident.name,
            electedPresident.voteCount,
            "A new president has been elected!"
        );
        return electedPresident.name;
    }

    /// @dev Reset: voteCount, voteState
    function resetVoting() public onlyAdministrator isPresidentElected {
        votingState = VotingState.CLOSED;
        PresidentialCandidate memory temp;
        electedPresident = temp;
        for (uint256 i = 0; i < votersAddress.length; i++) {
            Voter memory voter;
            voter.vote = 1;
            voters[votersAddress[i]] = voter;
        }

        for (uint256 j = 0; j < presidentialCandidatesAddress.length; j++) {
            address candidateAddress = presidentialCandidatesAddress[j];
            presidentialCandidates[candidateAddress].isCandidate = true;
            presidentialCandidates[candidateAddress].isPresident = false;
            presidentialCandidates[candidateAddress].voteCount = 0;
        }
        emit ResetVoting("Voting has been reset!");
    }
}