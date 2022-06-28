//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

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

/// The voter is already registered!
error Voting__AlreadyRegisteredCitizen();

/// Wrong address!
error Voting__WrongAddress();

/// You are the delegate to this voter!
error Voting__WrongDelegate();

/// Interval isn't passed yet!
error Voting__BeforeInterval();

/**
 * @title Election Contract
 * @author Raj Kiran Chaudhary
 * @notice This contract will electronize the traditional voting system which hadnt had
 * @notice much of transparency. There was a trust issue which a blockchain is going to solve
 * @dev Chill out, I am a newbie too!!!
 */

contract Voting is KeeperCompatibleInterface {
    struct Voter {
        address voterAddress;
        bool voted;
        address delegate;
    }

    struct Party {
        uint256 id;
        string name;
        string president;
        string presidentImage;
        string symbol;
    }

    enum VotingStatus {
        Registering,
        Open,
        Close
    }

    // Events
    event NewVoterRegistered(address indexed voterAddress);
    event NewPartyRegistered(uint256 indexed partyId);
    event Voted(address indexed voterAddress);
    event NewWinnerSet(uint256 indexed partyId);
    event Delegated(address mainVoter, address delegate);

    // State Variables
    address private s_owner;
    VotingStatus private s_votingStatus;
    uint256 private s_partyId = 1;
    Party[] private s_parties;
    Party private s_recentWinner;
    uint256 private s_year;
    uint256 private s_interval = 120; // 120 seconds
    uint256 private s_lastVotingOpenTimestamp;

    // Mappings
    mapping(uint256 => mapping(uint256 => uint256))
        private s_yearToPartyIdToItsVotes;
    mapping(uint256 => mapping(address => Voter))
        private s_yearToAddressToVoter;
    uint256 private s_totalVoters;

    constructor() {
        s_owner = msg.sender;
        s_votingStatus = VotingStatus.Close;
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

    /* Chainlink Keepers */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isNowOpen = getVotingStatus() == VotingStatus.Open;
        bool isTimePassed = (block.timestamp - s_lastVotingOpenTimestamp) >
            s_interval;
        upkeepNeeded = isNowOpen && isTimePassed;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - s_lastVotingOpenTimestamp) > s_interval) {
            s_votingStatus = VotingStatus.Close;

            uint256 winningPartyId = 1;
            uint256 winningVotes = s_yearToPartyIdToItsVotes[s_year][1];
            for (uint256 index = 2; index < s_partyId; index++) {
                if (s_yearToPartyIdToItsVotes[s_year][index] > winningVotes) {
                    winningVotes = s_yearToPartyIdToItsVotes[s_year][index];
                    winningPartyId = index;
                }
            }

            Party memory party = s_parties[winningPartyId - 1];
            s_recentWinner = party;

            emit NewWinnerSet(winningPartyId);
        }
    }

    // Functions
    function changeTheOwner(address newOwner)
        public
        onlyOwner
        onlyVotingClosed
    {
        s_owner = newOwner;
    }

    function registerNewVoter(address voterAddress)
        public
        onlyOwner
        onlyVotingRegistering
    {
        Voter memory voter = s_yearToAddressToVoter[s_year][voterAddress];

        if (voterAddress == msg.sender) {
            revert Voting__AnOwner();
        }

        if (voter.voterAddress != 0x0000000000000000000000000000000000000000) {
            revert Voting__AlreadyRegisteredCitizen();
        }

        Voter memory newVoter = Voter({
            voterAddress: voterAddress,
            voted: false,
            delegate: 0x0000000000000000000000000000000000000000
        });
        s_totalVoters++;
        s_yearToAddressToVoter[s_year][voterAddress] = newVoter;

        emit NewVoterRegistered(voterAddress);
    }

    function registerNewParty(
        string memory name,
        string memory president,
        string memory presidentImage,
        string memory symbol
    ) public onlyOwner onlyVotingRegistering {
        Party memory party = Party(
            s_partyId++,
            name,
            president,
            presidentImage,
            symbol
        );
        s_parties.push(party);

        emit NewPartyRegistered(party.id);
    }

    function delegateVoter(address delegate)
        public
        notOnlyOwner
        onlyVotingRegistering
    {
        Voter storage voter = s_yearToAddressToVoter[s_year][msg.sender];

        if (voter.voterAddress != msg.sender) {
            revert Voting__NotAVoter();
        }

        voter.delegate = delegate;

        emit Delegated(msg.sender, delegate);
    }

    function delegateVote(uint256 partyId, address mainVoter)
        public
        notOnlyOwner
        onlyVotingOpen
    {
        Voter storage voter = s_yearToAddressToVoter[s_year][mainVoter];

        if (voter.delegate != msg.sender) {
            revert Voting__WrongDelegate();
        }

        // Check if the voter has already voted
        if (voter.voted) {
            revert Voting__AlreadyVoted();
        }

        // Increase the party's vote
        s_yearToPartyIdToItsVotes[s_year][partyId]++;

        // Make voted = true
        voter.voted = true;

        emit Voted(msg.sender);
    }

    function vote(uint256 partyId) public notOnlyOwner onlyVotingOpen {
        // Check if the voterId is in the list
        Voter storage voter = s_yearToAddressToVoter[s_year][msg.sender];

        if (voter.voterAddress != msg.sender) {
            revert Voting__NotAVoter();
        }

        // Check if the voter has already voted
        if (voter.voted) {
            revert Voting__AlreadyVoted();
        }

        // Increase the party's vote
        s_yearToPartyIdToItsVotes[s_year][partyId]++;

        // Make voted = true
        voter.voted = true;

        emit Voted(msg.sender);
    }

    // returns the partyId
    // function setTheWinner() public onlyOwner onlyVotingClosed {
    //     uint256 winningPartyId = 1;
    //     uint256 winningVotes = s_yearToPartyIdToItsVotes[s_year][1];
    //     for (uint256 index = 2; index < s_partyId; index++) {
    //         if (s_yearToPartyIdToItsVotes[s_year][index] > winningVotes) {
    //             winningVotes = s_yearToPartyIdToItsVotes[s_year][index];
    //             winningPartyId = index;
    //         }
    //     }

    //     Party memory party = s_parties[winningPartyId - 1];
    //     s_recentWinner = party;

    //     emit NewWinnerSet(winningPartyId);
    // }

    function changeVotingStatus(uint256 votingStatus) public onlyOwner {
        if (
            getVotingStatus() == VotingStatus.Open &&
            block.timestamp - s_lastVotingOpenTimestamp < s_interval
        ) {
            revert Voting__BeforeInterval();
        }

        if (votingStatus > 2) revert();

        if (votingStatus == uint256(VotingStatus.Open)) {
            s_lastVotingOpenTimestamp = block.timestamp;
        }
        s_votingStatus = VotingStatus(votingStatus);
    }

    function setTheYear(uint256 year) public onlyOwner {
        s_year = year;
    }

    // Pure and view functions
    function getAllParties() public view returns (Party[] memory) {
        return s_parties;
    }

    function getTheWinner() public view returns (Party memory) {
        return s_recentWinner;
    }

    function getNumberOfVoters() public view returns (uint256) {
        return s_totalVoters;
    }

    function getContractOwner() public view returns (address) {
        return s_owner;
    }

    function getVotingStatus() public view returns (VotingStatus) {
        return s_votingStatus;
    }

    function getTheYear() public view returns (uint256) {
        return s_year;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}