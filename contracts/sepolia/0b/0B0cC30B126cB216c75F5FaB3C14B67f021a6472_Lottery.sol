// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Objective:
// 1. Enter the lottery (paying some amount)
// 2. Pick a random winner (verifiably random) (Winner to be selected once a parameter is satisfied. Eg: time, asset price, money in liquidity pool etc)
// 3. Completely automated winner selection:
//  * The following should be true in order to return true:
//  * i. Our time internal should have passed
//  * ii. The lottery should have atleast 1 player, and have some ETH
//  * iii. Our subscription is funded with LINK
//  * iv. The lottery should be in an "open" state.

// As we are picking random winner (2) and we have some event driven execution (3), we will use Chainlink Oracles
// Aka Chainlink Oracles for Randomness and Automated Execution (ie Chainlink Keepers)

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // for checkUpkeep and performUpkeep

error Lottery__NotEnoughETHEntered();
error Lottery__WinnerTransferFailed();
error Lottery__NotOpen();
error Lottery__checkUpkeepFalse(
  uint256 currentBalance,
  uint256 numPlayers,
  uint256 lotteryState,
  uint256 interval
);

/**
 * @title A sample lottery contract
 * @author Jatin Kalra
 * @notice A contract for creating an untamperable decentralised smart contract
 * @dev This implements Chainlink VRF V2 & Chainlink Keepers
 */

contract Lottery is
  VRFConsumerBaseV2 /* Inheritance to override the fullfillRandomWords internal function from "./node_modules" */,
  KeeperCompatibleInterface /* for checkUpkeep and performUpkeep functions */
{
  // Type Declaration
  enum LotteryState {
    OPEN,
    CALCULATING
  } // in background (indexed): uint256 0 = OPEN, 1 = CALCULATING

  // State Variables
  uint256 private immutable i_entranceFee; // minimum price // A storage var
  address payable[] private s_players; // array of addresses entered (1/2) // payable addresses as if one of them wins, we would be paying them
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // this is a contract
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private immutable i_callbackGasLimit;
  uint32 private constant NUM_WORDS = 1;

  // Lottery Variables (new section for state variables)
  address private s_recentWinner;
  LotteryState private s_lotteryState; // To keep track of contract status (OPEN, CALCULATING) // Other method: uint256 private s_state;
  uint256 private s_lastTimeStamp; // To keep track of block.timestamps
  uint256 private immutable i_interval; // interval between each winner

  // Events
  event LotteryEnter(address indexed player);
  event RequestedLotteryWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed winner);

  // Functions
  /**
   * @notice Constructs a new Lottery contract with the parameters set here.
   * @param vrfCoordinatorV2 The address of the VRFCoordinatorV2 contract.
   * @param entranceFee The minimum price required to enter the lottery.
   * @param gasLane The unique identifier (keyHash) for the VRF system to generate random numbers. Max gas price.
   * @param subscriptionId The unique subscription ID used for funding VRF requests.
   * @param callbackGasLimit The gas limit for the callback request to fulfill the random number.
   * @param interval The interval between each winner selection.
   */
  constructor(
    address vrfCoordinatorV2, // contract address
    uint256 entranceFee,
    bytes32 gasLane /* or keyHash */,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    uint256 interval
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_entranceFee = entranceFee;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); // Linking VRF Contract address with Interface(aka functions and events) and assigning it to a variable
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
    s_lotteryState = LotteryState.OPEN;
    s_lastTimeStamp = block.timestamp;
    i_interval = interval;
  }

  // Objective (1/3: Enter the lottery)

  /**
   * @notice Allows a participant to enter the lottery by paying the entrance fee.
   * @dev Participants must send an amount of Ether greater than or equal to the entrance fee.
   * @dev The lottery must be in an "open" state to allow entries.
   * @dev Emits the `LotteryEnter` event when a participant successfully enters the lottery.
   * @dev Throws a `Lottery__NotEnoughETHEntered` error if the participant does not send enough Ether.
   * @dev Throws a `Lottery__NotOpen` error if the lottery is not in an "open" state.
   */
  function enterLottery() public payable {
    // Other method: require (msg.value > i_entranceFee, "Not Enough ETH!") // gas costly as string is stored as error
    // gas efficient mehod below as error code is stored
    if (msg.value < i_entranceFee) {
      revert Lottery__NotEnoughETHEntered();
    }
    if (s_lotteryState != LotteryState.OPEN) {
      revert Lottery__NotOpen();
    }
    s_players.push(payable(msg.sender)); // array of addresses entered (2/2)

    // Emit an Event whenever we update a dynamic array or mapping; More gas-efficient than storing the variable as thet are stored outside the smart contract
    emit LotteryEnter(msg.sender);
  }

  // Objective (3/3: Completely automated)

  /**
   * @notice Checks if it's time to select a new random winner and restart the lottery.
   * @dev This function is called by Chainlink Keepers nodes to determine if the upkeep is true.
   * @dev The following conditions must be true to return `true`:
   *   i. time interval should have passed.
   *   ii. The lottery should have at least 1 player and have some ETH.
   *   iii. Our subscription is funded with LINK.
   *   iv. The lottery should be in an "open" state.
   * @dev checkUpkeep and performUpkeep reference: https://docs.chain.link/chainlink-automation/compatible-contracts
   * @return upkeepNeeded True if the conditions for selecting a new random winner are met, false otherwise.
   */
  function checkUpkeep(
    bytes memory /* checkData */
  ) public override returns (bool upkeepNeeded, bytes memory /*performData*/) {
    // changed from external to public so that performUpkeep can call it to verify
    //  iv. The lottery should be in an "open" state.
    bool isOpen = (LotteryState.OPEN == s_lotteryState);

    // i. Our time internal should have passed (ie: (current block.timestamp - last block.timestamp) > winner interval)
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);

    //  ii. The lottery should have atleast 1 player, and have some ETH
    bool hasPlayers = (s_players.length > 0);
    bool hasBalance = (address(this).balance > 0);

    //  iii. Our subscription is funded with LINK

    // Checking if all booleans are true or not, in order to restart lottery
    upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
  } // Formating source: https://docs.chain.link/chainlink-automation/compatible-contracts

  // Objective (2/3: Pick a random winner)
  // To pick a random number, a 2 transaction process: Request a random number (1/2); Once requested, do something with it (2/2)
  // Request a random number (1/2)

  /**
   * @notice Performs the upkeep and selects a new random winner for the lottery.
   * @dev This function is called by Chainlink Keepers when the conditions for selecting a new winner are met.
   * @dev Throws a `Lottery__checkUpkeepFalse` error if the conditions for selecting a new winner are not met.
   * @dev Emits the `RequestedLotteryWinner` event when a new winner is requested.
   */
  function performUpkeep(bytes calldata /*performData*/) external {
    //external function as it saves gas when called outside of this contract
    (bool upkeepNeeded, ) = checkUpkeep(""); // checking if checkUpKeep is true
    if (!upkeepNeeded) {
      revert Lottery__checkUpkeepFalse(
        address(this).balance,
        s_players.length,
        uint256(s_lotteryState),
        i_interval
      ); // relevant paramaters status to know why it failed
    }

    s_lotteryState = LotteryState.CALCULATING; // Updating status using enum before requesting the requestId
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane, // aka keyHash; aka max gas price you are willing to pay for a request in wei; aka setting a gas ceiling
      i_subscriptionId, // aka a uint64 subscription ID that this contract uses for funding requests
      REQUEST_CONFIRMATIONS, // A uint16 which says how many confirmations the chainlink node should wait before responding
      i_callbackGasLimit, // A uint32 which sets gas limit for callback request aka `fulfillRandomWords()`
      NUM_WORDS // a uint32 about how many random number we want to get
    ); // requestRandomWords: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol
    emit RequestedLotteryWinner(requestId); // This emit is redundant as its already coded in vrfcoordinatorv2mock
  }

  // Once requested, do something with it (2/2); Here: Pick a random winner from the player's array and send him the money
  /**
   * @notice Handles the fulfillment of a random number request and selects the winner.
   * @dev This function is called internally when the VRF response is received.
   * @param randomWords An array of random words generated by Chainlink VRF.
   * @dev The function selects a winner by taking the modulus of the first random word with the number of players.
   * @dev Transfers the lottery funds to the winner and emits the `WinnerPicked` event.
   * @dev Resets the player array and the timestamp for the next round of the lottery.
   * @dev Once winner is picked, changes the lottery state to Open.
   */
  function fulfillRandomWords(
    uint256 /* requestId */,
    uint256[] memory randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length; // Index 0 as we are only getting 1 random word from the array of words; % use example: 202 (random number) % 10 (entries) = 2 remainder (winner)
    address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;
    s_lotteryState = LotteryState.OPEN; // Changing status to open after winner selection

    // Sending money to winner
    (bool success, ) = recentWinner.call{ value: address(this).balance }(""); // call function syntax: (bool success, bytes memory data) = targetAddress.call{value: amount}(functionSignature);
    // Other method: require(success); Using the below one to be gas-efficient and record errors
    if (!success) {
      revert Lottery__WinnerTransferFailed();
    }
    // Keeping a list of all winners (outside of the contract, in the logs. As there is no array of winners written yet)
    emit WinnerPicked(recentWinner);

    // Resetting array & timestamp
    s_players = new address payable[](0); // Array of size 0
    s_lastTimeStamp = block.timestamp;
  } // Reference: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol

  // View & Pure Functions
  function getEntranceFee() public view returns (uint256) {
    return i_entranceFee;
  }

  function getPlayers(uint256 index) public view returns (address) {
    return s_players[index];
  }

  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }

  function getLotteryState() public view returns (LotteryState) {
    return s_lotteryState;
  }

  function getNumWords() public pure returns (uint256) {
    return NUM_WORDS;
  }

  function getNumberOfPlayers() public view returns (uint256) {
    return s_players.length;
  }

  function getLatestTimeStamp() public view returns (uint256) {
    return s_lastTimeStamp;
  }

  function getRequestConfirmations() public pure returns (uint256) {
    return REQUEST_CONFIRMATIONS;
  }

  function getInterval() public view returns (uint256) {
    return i_interval;
  }
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

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

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