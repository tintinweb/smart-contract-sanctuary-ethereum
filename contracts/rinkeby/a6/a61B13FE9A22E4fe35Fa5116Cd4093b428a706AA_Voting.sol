//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

/* Errors */
/// Not an owner!
error Voting__NotAnOwner();

/// Owner doesn't have access to this action!
error Voting__AnOwner();

/// You are not in a voter list!
error Voting__NotAVoter();

/// You have already voted!
error Voting__AlreadyVoted();

/// Voting not open yet!
error Voting__NotOpen();

/// Not the time of registration!
error Voting__NotRegistering();

/// Voting not closed yet!
error Voting__NotClosed();

/// Wrong password!
error Voting__WrongPassword();

/// The citizen is already registered!
error Voting__AlreadyRegisteredCitizen();

/// Wrong address!
error Voting__WrongAddress();

/**
 * @title Election Contract
 * @author Raj Kiran Chaudhary
 * @notice This contract will electronize the traditional voting system which hadnt had
 * @notice much of transparency. There was a trust issue which a blockchain is going to solve
 * @dev Chill out, I am a newbie too!!!
 */

contract Voting {
    struct Voter {
        uint256 id;
        uint256 citizenId;
        address voterAddress;
    }

    struct Party {
        uint256 id;
        string name;
        string president;
        string symbol;
    }

    enum VotingStatus {
        Registering,
        Open,
        Close
    }

    // Events
    event NewVoterRegistered(
        uint256 indexed citizenId,
        uint256 indexed voterId
    );
    event NewPartyRegistered(uint256 indexed partyId);
    event Voted(uint256 indexed voterId);
    event NewWinnerSet(uint256 indexed partyId);

    // State Variables
    address private s_owner;
    VotingStatus private s_votingStatus = VotingStatus.Close;
    uint256 private s_voterId = 1;
    uint256 private s_partyId = 1;
    Party[] private s_parties;
    Party private s_recentWinner;
    uint256[] private s_registeredCitizenIds;

    // Mappings
    mapping(uint256 => Voter) private s_citizenIdToVoter;
    mapping(uint256 => Voter) private s_voterIdToVoter;
    mapping(uint256 => mapping(uint256 => uint256))
        private s_yearToPartyIdToItsVotes;
    mapping(uint256 => bool) private s_voterIdToVotedOrNot;
    mapping(uint256 => bytes32) private s_citizenIdToTheirPasses;

    constructor() {
        s_owner = msg.sender;
    }

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != getContractOwner()) revert Voting__NotAnOwner();
        _;
    }

    modifier notOnlyOwner() {
        if (msg.sender == getContractOwner()) revert Voting__AnOwner();
        _;
    }

    modifier onlyVotingRegistering() {
        if (getVotingStatus() != VotingStatus.Registering) {
            revert Voting__NotRegistering();
        }
        _;
    }

    modifier onlyVotingOpen() {
        if (getVotingStatus() != VotingStatus.Open) {
            revert Voting__NotOpen();
        }
        _;
    }

    modifier onlyVotingClosed() {
        if (getVotingStatus() != VotingStatus.Close) {
            revert Voting__NotClosed();
        }
        _;
    }

    // Functions
    function changeTheOwner(address newOwner)
        public
        onlyOwner
        onlyVotingClosed
    {
        s_owner = newOwner;
    }

    function registerNewCitizenId(uint256 citizenId, bytes32 pass)
        public
        onlyOwner
    {
        if (
            s_citizenIdToTheirPasses[citizenId] !=
            0x0000000000000000000000000000000000000000000000000000000000000000
        ) {
            revert Voting__AlreadyRegisteredCitizen();
        }
        s_registeredCitizenIds.push(citizenId);
        s_citizenIdToTheirPasses[citizenId] = pass;
    }

    function registerNewParty(
        string memory name,
        string memory president,
        string memory symbol
    ) public onlyOwner onlyVotingRegistering {
        Party memory party = Party(s_partyId++, name, president, symbol);
        s_parties.push(party);

        emit NewPartyRegistered(party.id);
    }

    function registerNewVoter(uint256 citizenId, bytes32 pass)
        public
        notOnlyOwner
        onlyVotingRegistering
    {
        // Checking if the citizenId is there? and passcode is right
        if (
            s_citizenIdToTheirPasses[citizenId] ==
            0x0000000000000000000000000000000000000000000000000000000000000000
        ) {
            revert Voting__NotAVoter();
        }

        if (s_citizenIdToTheirPasses[citizenId] != pass) {
            revert Voting__WrongPassword();
        }

        Voter memory voter = Voter({
            id: s_voterId++,
            citizenId: citizenId,
            voterAddress: msg.sender
        });

        s_voterIdToVoter[voter.id] = voter;
        s_citizenIdToVoter[citizenId] = voter;
        emit NewVoterRegistered(citizenId, voter.id);
    }

    function vote(
        uint256 year,
        uint256 voterId,
        bytes32 pass,
        uint256 partyId
    ) public notOnlyOwner onlyVotingOpen {
        // Check if the voterId is in the list
        Voter memory voter = s_voterIdToVoter[voterId];

        if (voter.id == 0) {
            revert Voting__NotAVoter();
        }

        if (voter.voterAddress != msg.sender) {
            revert Voting__WrongAddress();
        }

        if (s_citizenIdToTheirPasses[voter.citizenId] != pass) {
            revert Voting__WrongPassword();
        }

        // Check if the voter has already voted
        if (s_voterIdToVotedOrNot[voterId]) {
            revert Voting__AlreadyVoted();
        }

        // Increase the party's vote
        s_yearToPartyIdToItsVotes[year][partyId]++;

        // Make voted = true
        s_voterIdToVotedOrNot[voterId] = true;

        emit Voted(voterId);
    }

    // returns the partyId
    function setTheWinner(uint256 year) public onlyOwner onlyVotingClosed {
        uint256 winningPartyId;
        uint256 winningVotes = s_yearToPartyIdToItsVotes[year][1];
        for (uint256 index = 2; index < s_partyId; index++) {
            if (s_yearToPartyIdToItsVotes[year][index] > winningVotes) {
                winningVotes = s_yearToPartyIdToItsVotes[year][index];
                winningPartyId = index;
            }
        }

        Party memory party = s_parties[winningPartyId - 1];
        s_recentWinner = party;

        emit NewWinnerSet(winningPartyId);
    }

    function changeVotingStatus(uint256 votingStatus) public onlyOwner {
        if (votingStatus > 2) revert();
        s_votingStatus = VotingStatus(votingStatus);
    }

    // Pure and view functions
    function getVoterByCitizenId(uint256 citizenId)
        public
        view
        returns (Voter memory)
    {
        return s_citizenIdToVoter[citizenId];
    }

    function getAllParties() public view returns (Party[] memory) {
        // Party[] memory parties = new Party[](s_parties.length);

        // for (uint256 i = 0; i < s_parties.length; i++) {
        //     parties[i] = s_parties[i];
        // }

        // return parties;

        return s_parties;
    }

    function getTheWinner() public view returns (Party memory) {
        return s_recentWinner;
    }

    function getNumberOfVoters() public view returns (uint256) {
        return (s_voterId - 1);
    }

    function getTotalRegisteredCitizens() public view returns (uint256) {
        return s_registeredCitizenIds.length;
    }

    function getContractOwner() public view returns (address) {
        return s_owner;
    }

    function getVotingStatus() public view returns (VotingStatus) {
        return s_votingStatus;
    }
}