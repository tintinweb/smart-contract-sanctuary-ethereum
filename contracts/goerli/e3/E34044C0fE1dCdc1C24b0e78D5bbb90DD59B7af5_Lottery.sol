// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////
//  Imports  //
///////////////
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

//////////////
//  Errors  //
//////////////
error Lottery__AlreadyStarted();
error Lottery__NotOpen();
error Lottery__NotEnoughFeeSent();
error Lottery__TransferFailed();
error Lottery__UpkeepNotNeeded();

////////////////////
// Smart Contract //
////////////////////

/**
 * @title Decentralized Lottery contract
 * @author Dariusz Setlak
 * @notice The Decentralized Lottery smart contract.
 * @dev The Decentralized Lottery smart contract containing the following functions:
 * Main functions: startLottery, joinLottery, checkUpkeep, performUpkeep, fulfillRandomWords
 * Getter functions: getLotteryState, getLotteryEntranceFee, getLotteryStartTimeStamp, getLotteryPlayersNumber,
 * getLatestLotteryWinner, getLotteyDurationTime, getLotteryBalance, getLotteryFeesValues
 * Other functions: receive, fallback
 */
contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    //////////////
    //  Events  //
    //////////////
    event LotteryStarted(LotteryFee indexed entranceFee, address indexed firstPlayer);
    event LotteryJoined(address indexed newPlayer);
    event LotteryWinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed winner, uint256 indexed winnerPrize);
    event NewTransferReceived(uint256 amount);

    //////////////
    //   Enums  //
    //////////////

    /**
     * @dev Enum variable storing 3 possible lottery states: 0 - CLOSE, 1 - OPEN, 2 - CALCULATING
     * CLOSE - lottery in not started state, first player which join the lottery also OPEN it
     * OPEN - lottery is in open state, first player who join the lottery OPEN it and choose the entrance fee
     * CALCULATING - lottery is choosing the winner, not possible to join lottery
     */
    enum LotteryState {
        CLOSE, // uint8 = 0
        OPEN, // uint8 = 1
        CALCULATING // uint8 = 2
    }

    /**
     * @dev Enum variable storing 3 possible lottery entrance fee values:
     * LOW - 0.1
     * MEDIUM - 0.5
     * HIGH - 1
     */
    enum LotteryFee {
        LOW, // uint8 = 0
        MEDIUM, // uint8 = 1
        HIGH // uint8 = 2
    }

    ///////////////
    //  Scructs  //
    ///////////////

    /**
     * @dev Struct of lottery data parameters.
     * LotteryState lotteryState - lottery state ENUM parameter
     * uint256 lotteryFee - lottery fee parameter
     * uint256 startTimeStamp - lottery start time stamp parameter
     * LotteryPlayers[] players - array of lottery players addresses
     * address latestLotteryWinner - latest lottery winner parameter
     */
    struct LotteryData {
        LotteryState lotteryState;
        uint256 lotteryFee;
        uint256 startTimeStamp;
        address payable[] players;
        address latestLotteryWinner;
    }

    ////////////////
    //  Mappings  //
    ////////////////

    /// @dev Mapping LotteryFee to lottery entrance fee constant values.
    mapping(LotteryFee => uint256) private s_lotteryFees;

    ///////////////////////
    // Lottery variables //
    ///////////////////////

    /// @dev Lottery data parameters struct variable
    LotteryData private s_lotteryData;

    /// @dev Lottery duration time 5 minutes value
    uint256 private immutable i_durationTime; // seconds

    /// @dev Lottery entrance fee LOW value
    uint256 private constant FEE_LOW = 100000000000000000; // 0.1 ETH

    /// @dev Lottery entrance fee MEDIUM value
    uint256 private constant FEE_MEDIUM = 500000000000000000; // 0.5 ETH

    /// @dev Lottery entrance fee HIGH value
    uint256 private constant FEE_HIGH = 1000000000000000000; // 1 ETH

    ///////////////////
    // VRF variables //
    ///////////////////

    /// @dev The VRFCoordinatorV2 contract.
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    /// @dev The gas lane key hash value is the maximum gas price you want to pay for a single VRF request in wei.
    bytes32 private immutable i_gasLane;

    /// @dev The subscription ID that this contract uses for funding VRF requests.
    uint32 private immutable i_subscriptionId;

    /// @dev The limit for how much gas to use for the callback request to fulfillRandomWords() contract function.
    /// This variable set the limit of computation of fulfillRandomWords() function.
    uint32 private immutable i_callbackGasLimit;

    /// @dev The number of confirmations that Chainlink node should wait before responding.
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    /// @dev The number of random values requested to VRFCoordinatorV2 contract.
    uint32 private constant NUM_WORDS = 1;

    ///////////////////
    //  Constructor  //
    ///////////////////

    /**
     * @dev Lottery contract constructor.
     * Set given parameters to appropriate variables, when contract deploys.
     * @param durationTime given lottery duration time parameter in seconds
     * @param vrfCoordinatorV2 given vrfCoordinatorV2 contract
     * @param gasLane given gas lane key hash value
     * @param subscriptionId given Chainlink VRF subscriptionId number
     * @param callbackGasLimit given limit of gas for a single Chainlink VRF request
     */
    constructor(
        uint256 durationTime,
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint32 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        // Set given parameters to immutable contract variables
        i_durationTime = durationTime;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        // Set lottery initial state to CLOSE
        s_lotteryData.lotteryState = LotteryState.CLOSE;

        // Assign mapping of lottery fees ENUM option variables to appropriate constant values
        s_lotteryFees[LotteryFee.LOW] = FEE_LOW;
        s_lotteryFees[LotteryFee.MEDIUM] = FEE_MEDIUM;
        s_lotteryFees[LotteryFee.HIGH] = FEE_HIGH;
    }

    ////////////////////
    // Main Functions //
    ////////////////////

    /**
     * @notice Function for start new decentralized lottery.
     * @dev Function allows any user to start new decentralized lottery with entrance fee of his choice.
     * When the first player starts new lottery, he set lottery entrance fee for himself and all new players,
     * who join the lottery, until fixed lottery time passes. The first player can choose entrance fee amount
     * from 3 awaliable ENUM variables opctions: LOW - 0.1, MEDIUM - 0.5 and HIGH - 1.
     *
     * This is an external function, invoked by the user, using front-end application.
     *
     * @param _entranceFee lottery entrance fee of choice (ENUM)
     */
    function startLottery(LotteryFee _entranceFee) external payable {
        // Check if lottery is in CLOSE state
        if (s_lotteryData.lotteryState != LotteryState.CLOSE) {
            revert Lottery__AlreadyStarted();
        }

        // Set lottery entrance fee
        if (_entranceFee == LotteryFee.LOW) s_lotteryData.lotteryFee = s_lotteryFees[LotteryFee.LOW];
        else if (_entranceFee == LotteryFee.MEDIUM) s_lotteryData.lotteryFee = s_lotteryFees[LotteryFee.MEDIUM];
        else if (_entranceFee == LotteryFee.HIGH) s_lotteryData.lotteryFee = s_lotteryFees[LotteryFee.HIGH];

        // Check if first player enough entrance fee with transaction
        if (msg.value < s_lotteryFees[_entranceFee]) {
            revert Lottery__NotEnoughFeeSent();
        }

        // Change lottery state to OPEN
        s_lotteryData.lotteryState = LotteryState.OPEN;

        // Push first player's address to lottery player's array
        s_lotteryData.players.push(payable(msg.sender));

        // Set lottery starting time stamp
        s_lotteryData.startTimeStamp = block.timestamp;

        // Emit an event LotteryStarted
        emit LotteryStarted(_entranceFee, msg.sender);
    }

    /**
     * @notice Function for joining new players to already started lottery.
     * @dev Function allows new players to join already started lottery, until lottery time is up.
     * To join already started lottery, new player has to send entrance fee with transaction.
     * The lottery entrance fee can not be changed until lottery duration time expires and the winner
     * is picked. If that happens, the lottery can be started again by first player with new entrance
     * fee using `startLottery` function.
     *
     * This is an external function, invoked by the user, using front-end application.
     */
    function joinLottery() external payable {
        // Check if lottery is in OPEN state
        if (s_lotteryData.lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }

        // Check if new player enough entrance fee with transaction
        if (msg.value < s_lotteryData.lotteryFee) {
            revert Lottery__NotEnoughFeeSent();
        }

        // Push new lottery player's address to array
        s_lotteryData.players.push(payable(msg.sender));

        // Emit an event LotteryStarted
        emit LotteryJoined(msg.sender);
    }

    /**
     * @notice Chainlink Automation function for checking if upKeep action is needed.
     * @dev Public and overriden Chainlink Automation function for checking the conditions,
     * which have to be passed to perform upKeep action.
     * The following conditions should be true in order to return true value of `upkeepNeeded`:
     * 1. The lottery should be in an OPEN state
     * 2. The Lottery duration time should have passed
     * 3. The lottery should have at lease 1 player
     * 3. The lottery balance should be > 0
     * 3. Chainlink Automation subscription should be funded with LINK
     *
     * This is a public function, invoked by Chainlink Automation node.
     *
     * @return upkeepNeeded the upkeepNeeded bool variable
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isLotteryOpen = s_lotteryData.lotteryState == LotteryState.OPEN;
        // bool lotteryTimePassed = (block.timestamp - s_lotteryData.startTimeStamp) > i_durationTime;
        bool lotteryHasPlayers = s_lotteryData.players.length > 0;
        bool lotteryHasBalance = address(this).balance > 0;

        if (
            isLotteryOpen &&
            /*lotteryTimePassed &&*/
            lotteryHasPlayers &&
            lotteryHasBalance
        ) return (upkeepNeeded = true, "");
        else return (upkeepNeeded = false, "");
    }

    /**
     * @notice Chainlink Automation function for performing upKeep action.
     * @dev External and overriden Chainlink Automation function for performing upKeep action.
     *
     * This is an external function, invoked by Chainlink Automation node.
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // Check if upKeep action is needed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded();
        }

        // Set lottery state to CALCULATING
        s_lotteryData.lotteryState = LotteryState.CALCULATING;

        // Perform upKeep action: Chainlink VRF requestRandomWords function
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // Emit an event LotteryWinnerRequested
        emit LotteryWinnerRequested(requestId);
    }

    /**
     * @notice Chainlink VRF function for random pick the lottery winner.
     * @dev Intenal and overriden Chainlink VRF function for random pick the lottery winner.
     *
     * This is an internal function, invoked by Chainlink Automation node.
     *
     * @param _randomNumbers random numbers array from Chainlink VRF
     */
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory _randomNumbers
    ) internal override {
        // Pick the lottery winner
        uint256 indexOfWinner = _randomNumbers[0] % s_lotteryData.players.length;
        address payable currentWinner = s_lotteryData.players[indexOfWinner];

        // Set current winner address as latest lottery winner
        s_lotteryData.latestLotteryWinner = currentWinner;

        // Set the lottery state to CLOSE
        s_lotteryData.lotteryState = LotteryState.CLOSE;

        // Reset the lottery participants addresses array
        s_lotteryData.players = new address payable[](0);

        // Transfer lottery funds to the lottery winner
        uint256 lotteryBalance = address(this).balance;
        (bool success, ) = currentWinner.call{value: lotteryBalance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }

        // Emit an event WinnerPicked
        emit WinnerPicked(currentWinner, lotteryBalance);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    /**
     * @notice Getter function to get the current lottery state: 0 - NOT_STARTED, 1 - OPEN, 2 - CALCULATING
     * @return The lottery state ENUM variable.
     */
    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryData.lotteryState;
    }

    /**
     * @notice Getter function to get the current lottery entrance fee.
     * @return The lottery entrance fee.
     */
    function getLotteryEntranceFee() public view returns (uint256) {
        return s_lotteryData.lotteryFee;
    }

    /**
     * @notice Getter function to get the current lottery starting time stamp.
     * @return The lottery starting time stamp.
     */
    function getLotteryStartTimeStamp() public view returns (uint256) {
        return s_lotteryData.startTimeStamp;
    }

    /**
     * @notice Getter function to get the number of current lottery players.
     * @return The number of lottery players.
     */
    function getLotteryPlayersNumber() public view returns (uint256) {
        return s_lotteryData.players.length;
    }

    /**
     * @notice Getter function to get the latest lottery winner address.
     * @return The latest lottery winner address.
     */
    function getLatestLotteryWinner() public view returns (address) {
        return s_lotteryData.latestLotteryWinner;
    }

    /**
     * @notice Getter function to get the fixed lottery duration time.
     * @return The lottery duration time in seconds
     */
    function getLotteryDurationTime() public view returns (uint256) {
        return i_durationTime;
    }

    /**
     * @notice Getter function to get the current lottery balance.
     * @return The lottery balance.
     */
    function getLotteryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Getter function to get the lottery entrance fees ENUM options: 0 - LOW, 1 - MEDIUM, 2 - HIGH
     * @param _entranceFee the LotteryFee ENUM input parameter
     * @return The lottery duration time of chosen ENUM value.
     */
    function getLotteryFeesValues(LotteryFee _entranceFee) public view returns (uint256) {
        return s_lotteryFees[_entranceFee];
    }

    /////////////////////
    // Other Functions //
    /////////////////////

    /**
     * @notice Receive funds
     * @dev Function allows to receive funds sent to smart contract.
     */
    receive() external payable {
        // console.log("Function `receive` invoked");
        emit NewTransferReceived(msg.value);
    }

    /**
     * @notice Fallback function
     * @dev Function executes if none of the contract functions (function selector) match the intended
     * function calls.
     */
    fallback() external payable {
        // console.log("Function `fallback` invoked");
        emit NewTransferReceived(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

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