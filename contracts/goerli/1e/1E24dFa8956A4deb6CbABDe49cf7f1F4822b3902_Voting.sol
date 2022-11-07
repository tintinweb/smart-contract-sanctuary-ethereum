// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Error
error Voting__OnlyOrganiserCanCallThisFunction(
    address caller,
    address organiser
);
error Voting__CandidateWithIdNotExists(uint256 candidateId);
error Voting__UpKeepNotNeeded(bool isActive, bool timePassed);
error Voting__CanditateAlreadyExists(address candidateAddr);
error Voting__VoterAlreadyExists(address VoterAddr);
error Voting__VoterWithIdNotExists(uint256 voterId);
error Voting__VotingClosed();
error Voting__VotingTimePassed(uint256 timePassed, uint256 votingDuration);
error Voting__CannotStartNewRoundWithoutBeforePickingWinner();


/**
 * @title A Voting Smart Contract
 * @author Aditya Bhattad
 * @notice This is a fully secure voting smart contract
 * @dev This makes use of chainlink automation to automate the voting process
 */
contract Voting is AutomationCompatibleInterface {
    using Counters for Counters.Counter;

    // Events.
    event CandidateCreated(
        uint256 indexed candidateId,
        address indexed candidateAddress,
        string indexed candidateName,
        string candidateIpfsURL,
        string candidateImage
    );
    event VoterCreated(
        uint256 indexed voterId,
        address indexed voterAddress,
        bool indexed alreadyVoted,
        string voterName,
        string ipfsURL
    );
    event Voted(uint256 indexed candidateId, address indexed voterAddress);
    event NewVotingStarted(uint256 indexed newVotingRoundNumber);
    event WinnerPicked(uint256 indexed winnerId);

    // Voting Record Variables.
    bool private isVotingActive;
    uint256 private votingTimePeriodInSeconds;
    uint256 private votingTimestamp;
    Counters.Counter private votingRoundNumber;
    mapping(uint256 => uint256) private roundNumberToWinnerId;
    bool private isWinnerPicked;

    // Candidate Variables.
    Counters.Counter private _candidateCounter;
    address public votingOrganizer;
    struct Candidate {
        uint256 id;
        string name;
        string image;
        address walletAddress;
        uint256 voteCount;
        string ipfsURL;
    }
    address[] private arrayOfCandidateAddresses;
    mapping(uint256 => mapping(address => Candidate))
        private addressToCandidate;
    // mapping(address => Candidate) private addressToCandidate;

    // Voter Variables.
    Counters.Counter private _voterCounter;
    address[] private arrayofVoterAddresses;
    struct Voter {
        uint256 id;
        string name;
        address walletAddress;
        bool alreadyVoted;
        string ipfsURL;
    }
    mapping(uint256 => mapping(address => Voter)) private addressToVoter;

    // Old and unefficient way of storing candiates and voters.
    // mapping(address => Voter) private addressToVoter;


    constructor(uint256 firstVoteTimePeriodInSec) {
        votingOrganizer = msg.sender;
        votingRoundNumber.increment();
        votingTimestamp = block.timestamp;
        votingTimePeriodInSeconds = firstVoteTimePeriodInSec;
        isWinnerPicked=false;
        isVotingActive = true;
    }

    
    modifier onlyOrganiser() {
        if (msg.sender != votingOrganizer) {
            revert Voting__OnlyOrganiserCanCallThisFunction(
                msg.sender,
                votingOrganizer
            );
        }
        _;
    }

    modifier checkVotingActive() {
        if (!isVotingActive) {
            revert Voting__VotingClosed();
        }
        _;
    }

    /**
     * @notice This function is used to create a new candidate
     * @param _name The name of the candidate
     * @param _image The image of the candidate
     * @param _candidateAddress The wallet address of the candidate
     * @param _ipfsURL The ipfs url of the candidate
     * @dev This function is only callable by the voting organizer
     * @dev This function emits the CandidateCreated event if executed successfully
     */
    function addCandidate(
        address _candidateAddress,
        string memory _name,
        string memory _image,
        string memory _ipfsURL
    ) external onlyOrganiser checkVotingActive {
        if ((block.timestamp - votingTimestamp) > votingTimePeriodInSeconds) {
            revert Voting__VotingTimePassed(
                (block.timestamp - votingTimestamp),
                votingTimePeriodInSeconds
            );
        }
        uint256 _votingRoundNum = votingRoundNumber.current();
        if (
            addressToCandidate[_votingRoundNum][_candidateAddress]
                .walletAddress == _candidateAddress
        ) {
            revert Voting__CanditateAlreadyExists(_candidateAddress);
        }
        _candidateCounter.increment();
        uint256 _id = _candidateCounter.current();
        Candidate storage candidate = addressToCandidate[_votingRoundNum][
            _candidateAddress
        ];
        candidate.id = _id;
        candidate.name = _name;
        candidate.image = _image;
        candidate.walletAddress = _candidateAddress;
        candidate.ipfsURL = _ipfsURL;

        arrayOfCandidateAddresses.push(_candidateAddress);

        emit CandidateCreated(
            candidate.id,
            candidate.walletAddress,
            candidate.name,
            candidate.ipfsURL,
            candidate.image
        );
    }

    /**
     * @notice This function is used to create a new voter
     * @param _name The name of the voter
     * @param _voterAddress The wallet address of the voter
     * @param _ipfsURL The ipfs url of the voter
     * @dev This function can be called by anyone
     * @dev This function can be called only when the voting is active
     * @dev This function can be called only when the voting time period has not passed
     * @dev This function emits a VoterCreated event if executed successfully
     */
    function addVoter(
        address _voterAddress,
        string memory _name,
        string memory _ipfsURL
    ) external checkVotingActive {
        if ((block.timestamp - votingTimestamp) > votingTimePeriodInSeconds) {
            revert Voting__VotingTimePassed(
                (block.timestamp - votingTimestamp),
                votingTimePeriodInSeconds
            );
        }
        uint256 _votingRoundNum = votingRoundNumber.current();
        if (
            addressToVoter[_votingRoundNum][_voterAddress].walletAddress ==
            _voterAddress
        ) {
            revert Voting__VoterAlreadyExists(_voterAddress);
        }
        _voterCounter.increment();
        uint256 _id = _voterCounter.current();
        Voter storage voter = addressToVoter[_votingRoundNum][_voterAddress];
        voter.id = _id;
        voter.name = _name;
        voter.walletAddress = _voterAddress;
        voter.ipfsURL = _ipfsURL;
        voter.alreadyVoted = false;

        arrayofVoterAddresses.push(_voterAddress);

        emit VoterCreated(
            voter.id,
            voter.walletAddress,
            voter.alreadyVoted,
            voter.name,
            voter.ipfsURL
        );
    }

    /**
     * @notice This function is used to vote for a candidate
     * @param candidateId The id of the desired candidate
     * @dev This function can be called by anyone
     * @dev This function can be called only when the voting is active
     * @dev This function can be called only when the voting time period has not passed
     * @dev This function emits a Voted event if executed successfully
     */
    function giveVote(uint256 candidateId) external checkVotingActive {
        if ((block.timestamp - votingTimestamp) > votingTimePeriodInSeconds) {
            revert Voting__VotingTimePassed(
                (block.timestamp - votingTimestamp),
                votingTimePeriodInSeconds
            );
        }
        uint256 _votingRoundNum = votingRoundNumber.current();
        uint256 voterArryLen = arrayofVoterAddresses.length;
        bool voterExists = false;
        for (uint x = 0; x < voterArryLen; ) {
            if (arrayofVoterAddresses[x] == msg.sender) {
                voterExists = true;
            }
            unchecked {
                x++;
            }
        }
        require(voterExists, "You are not registered to vote");
        require(
            !addressToVoter[_votingRoundNum][msg.sender].alreadyVoted,
            "The msg sender has already voted"
        );

        uint candidateArryLength = arrayOfCandidateAddresses.length;
        bool voted = false;
        for (uint y = 0; y < candidateArryLength; ) {
            if (
                addressToCandidate[_votingRoundNum][
                    arrayOfCandidateAddresses[y]
                ].id == candidateId
            ) {
                addressToCandidate[_votingRoundNum][
                    arrayOfCandidateAddresses[y]
                ].voteCount += 1;
                voted = true;
            }
            unchecked {
                y++;
            }
        }
        if (!voted) {
            revert Voting__CandidateWithIdNotExists(candidateId);
        }

        addressToVoter[_votingRoundNum][msg.sender].alreadyVoted = voted;
        emit Voted(candidateId, msg.sender);
    }

    /**
     * @dev This function is to be called internally by performUpKeep.
     * @dev This function emits a WinnerPicked with winner candidate Id event if executed successfully
     */
    function pickWinner() internal checkVotingActive {
        uint256 _votingRoundNum = votingRoundNumber.current();
        uint lenOfCandidateArry = arrayOfCandidateAddresses.length;
        uint max = 0;
        uint indexOfCandidateWithMaxVotes;
        for (uint256 x = 0; x < lenOfCandidateArry; ) {
            if (
                addressToCandidate[_votingRoundNum][
                    arrayOfCandidateAddresses[x]
                ].voteCount > max
            ) {
                max = addressToCandidate[_votingRoundNum][
                    arrayOfCandidateAddresses[x]
                ].voteCount;
                indexOfCandidateWithMaxVotes = x;
            }
            unchecked {
                x++;
            }
        }
        roundNumberToWinnerId[_votingRoundNum] = addressToCandidate[
            _votingRoundNum
        ][arrayOfCandidateAddresses[indexOfCandidateWithMaxVotes]].id;

        isVotingActive = false;
        isWinnerPicked = true;
        emit WinnerPicked(
            addressToCandidate[_votingRoundNum][
                arrayOfCandidateAddresses[indexOfCandidateWithMaxVotes]
            ].id
        );
        votingRoundNumber.increment();
    }

    /**
     * @notice This function can be only called by the organiser of the voting
     * @notice This function can be called only when the winner of the last round has been picked.
     * @param _votingTimePeriod The time period for which the voting will be active
     * @dev This function resets the array of old candidates and voters.
     * @dev This function emits a NewVotingStarted event if executed successfully
     */
    function startNewVoting(uint256 _votingTimePeriod)
        external
        onlyOrganiser
    {
        if(!isWinnerPicked){
            revert Voting__CannotStartNewRoundWithoutBeforePickingWinner();
        }
        isVotingActive = true;
        isWinnerPicked = false;
        votingTimePeriodInSeconds = _votingTimePeriod;
        votingTimestamp = block.timestamp;
        arrayOfCandidateAddresses = new address[](0);
        arrayofVoterAddresses = new address[](0);
        uint newVotingRoundNumber = votingRoundNumber.current();
        emit NewVotingStarted(newVotingRoundNumber);
    }

    // Chainlink Automation Functions.
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = isVotingActive;
        bool timePassed = ((block.timestamp - votingTimestamp) >
            votingTimePeriodInSeconds);
        upkeepNeeded = (isOpen && timePassed);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Voting__UpKeepNotNeeded(
                isVotingActive,
                ((block.timestamp - votingTimestamp) >
                    votingTimePeriodInSeconds)
            );
        }
        pickWinner();
    }

    // getter functions
    function getAllCandidates() public view returns (address[] memory) {
        return arrayOfCandidateAddresses;
    }

    function getCandidateLength() public view returns (uint256) {
        return arrayOfCandidateAddresses.length;
    }

    function getCandidateByAddress(
        uint256 _votingRoundNum,
        address _candidateAddress
    ) public view returns (Candidate memory) {
        return addressToCandidate[_votingRoundNum][_candidateAddress];
    }

    function getCandidateById(uint256 _votingRoundNum, uint256 candidateId)
        public
        view
        returns (Candidate memory)
    {
        uint256 lenOfCandidateArry = arrayOfCandidateAddresses.length;
        for (uint z = 0; z < lenOfCandidateArry; ) {
            if (
                addressToCandidate[_votingRoundNum][
                    arrayOfCandidateAddresses[z]
                ].id == candidateId
            ) {
                return
                    addressToCandidate[_votingRoundNum][
                        arrayOfCandidateAddresses[z]
                    ];
            }
            unchecked {
                z++;
            }
        }
        revert Voting__CandidateWithIdNotExists(candidateId);
    }

    function getVoterById(uint256 _votingRoundNum, uint256 voterId)
        public
        view
        returns (Voter memory)
    {
        uint256 lengthOfVoterArry = arrayofVoterAddresses.length;
        for (uint a = 0; a < lengthOfVoterArry; ) {
            if (
                addressToVoter[_votingRoundNum][arrayofVoterAddresses[a]].id ==
                voterId
            ) {
                return
                    addressToVoter[_votingRoundNum][arrayofVoterAddresses[a]];
            }
            unchecked {
                a++;
            }
        }
        revert Voting__VoterWithIdNotExists(voterId);
    }

    function getVoterByAddress(uint256 _votingRoundNum, address voterAddr)
        public
        view
        returns (Voter memory)
    {
        return addressToVoter[_votingRoundNum][voterAddr];
    }

    function getAllVoters() public view returns (address[] memory) {
        return arrayofVoterAddresses;
    }

    function getVoterLength() public view returns (uint256) {
        return arrayofVoterAddresses.length;
    }

    function getIsVotingActive() public view returns (bool) {
        return isVotingActive;
    }

    function getVotingCurrentVotingDuration() public view returns (uint256) {
        return votingTimePeriodInSeconds;
    }

    function getCurrentVotingRoundNumber() public view returns (uint256) {
        return votingRoundNumber.current();
    }

    function getRoundWinnerById(uint256 roundNumber)
        public
        view
        returns (uint256)
    {
        return roundNumberToWinnerId[roundNumber];
    }

    function getIsWinnerPickedStatus() public view returns(bool){
        return isWinnerPicked;
    }

    function getLastVotingTimeStamp() public view returns(uint256){
        return votingTimestamp;
    }
}