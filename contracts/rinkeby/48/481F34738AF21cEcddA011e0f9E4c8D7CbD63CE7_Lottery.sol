// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Lottery__NotOwner();
error Lottery__NotSentToWinner();
error Lottery__LotteryUnplayable();
error Lottery__PerformUpkeepNotYetNeeded();
error Lottery__NotEnoughFundToParticipate();
error Lottery__CannotPlayMoreThanOnce();

/// @title A lottery contract
/// @author chain xvi
/// @notice A lottery where participants enter and after an interval a winner is picked
/// @dev This contract uses chainlink oracles for Keepers to automate the execution
/// and for VRF to get random number to pick winner
contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
  address immutable i_owner;

  // lottery data
  address payable[] private s_participants;
  // mapping (address => uint256) public s_participantToAmount;
  mapping (address => bool) s_participantToExists;
  uint256 private s_lotteryAmount;
  address private s_winner;
  bool private s_lotteryPlayable;
  uint256 private immutable i_minEntranceFee;

  // vrf data
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 private immutable i_subscriptionId;
  bytes32 private i_keyHash;
  uint16 constant requestConfirmations = 3;
  uint32 private i_gasLimit;

  // keeper data
  uint256 private s_lastTimeStamp;
  uint256 private immutable i_interval;

  // events
  event LotteryEntered(address indexed participant);
  event RequestedLotteryWinner(uint256 indexed requestId);
  event PickedWinner(address indexed winner);
  event called();

  constructor(uint64 subscriptionId, address vrfCoordinator, bytes32 keyHash, uint32 gasLimit, uint256 intervalSeconds, uint256 minEntranceFee) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    i_owner = msg.sender;
    i_interval = intervalSeconds;
    s_lotteryPlayable = true;
    s_lastTimeStamp = block.timestamp;
    i_keyHash = keyHash;
    i_minEntranceFee = minEntranceFee;
    i_subscriptionId = subscriptionId;
    i_gasLimit = gasLimit;
  }

  /// @notice Allows non duplicate participants to enter the lottery
  /// @dev This function checks if the lottery is playable to make sure the player enters
  /// where no previous winner is being picked by the VRF.
  /// It also checks if the minimum amount is equal or above the minimum.
  function enterLottery() payable public {
    if(!s_lotteryPlayable){
      revert Lottery__LotteryUnplayable();
    }

    if(msg.value < i_minEntranceFee){
      revert Lottery__NotEnoughFundToParticipate();
    }

    if(s_participantToExists[msg.sender]) {
      revert Lottery__CannotPlayMoreThanOnce();
    } else {
      s_lotteryAmount += msg.value;
      s_participants.push(payable(msg.sender));
      s_participantToExists[msg.sender] = true;
    }

    emit LotteryEntered(msg.sender);
  }

  function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
    emit called();
    s_lotteryPlayable = true;
    uint256 randomNumber = randomWords[0] % s_participants.length;
    address payable winner = s_participants[randomNumber];
    s_winner = winner;
    for (uint i = 0; i < s_participants.length; i++) {
      delete s_participantToExists[s_participants[i]];
    }
    s_participants = new address payable[](0);
    s_lastTimeStamp = block.timestamp;

    (bool success, ) = s_winner.call{value: address(this).balance}("");
    if(!success) {
      revert Lottery__NotSentToWinner();
    }

    emit PickedWinner(s_winner);
  }

  function checkUpkeep(bytes memory /*checkData*/) public override view returns (bool upkeepNeeded, bytes memory) {
    // returns true for the keeper to run `performUpkeep`
    // TODO: this should not return true until the time has passed
    upkeepNeeded = ((block.timestamp - s_lastTimeStamp) > i_interval) &&
      (s_participants.length > 0) &&
      (address(this).balance > 0) &&
      s_lotteryPlayable;
  }

  function performUpkeep(bytes calldata /*performData*/) external override {
    (bool upkeepNeeded,) = checkUpkeep("");
    if(!upkeepNeeded) {
      revert Lottery__PerformUpkeepNotYetNeeded();
    }

    s_lotteryPlayable = false;
    uint256 requestId = COORDINATOR.requestRandomWords(
      i_keyHash,
      i_subscriptionId,
      requestConfirmations,
      i_gasLimit,
      1
    );
    emit RequestedLotteryWinner(requestId);
  }

  /// @notice Returns the participants
  /// @return s_participants as address[]
  function getParticipants() public view returns (address payable[] memory) {
    return s_participants;
  }

  /// @notice Returns the lottery amount
  /// @return s_lotteryAmount as uint256
  function getLotteryAmount() public view returns (uint256) {
    return s_lotteryAmount;
  }

  /// @notice Returns the winner
  /// @return s_winner as address
  function getWinner() public view returns (address) {
    return s_winner;
  }

  /// @notice Returns the number of participants
  /// @return s_participants.length as uint256
  function getNumberOfParticipants() public view returns (uint256) {
    return s_participants.length;
  }

  /// @notice Returns the min entrance fee
  /// @return i_minEntranceFee as uint256
  function getMinEntranceFee() public view returns (uint256) {
    return i_minEntranceFee;
  }

  /// @notice Returns the last time stamp
  /// @return s_lastTimeStamp as uint256
  function getLastTimeStamp() public view returns (uint256) {
    return s_lastTimeStamp;
  }

  /// @notice Returns the interval
  /// @return i_interval as uint256
  function getInterval() public view returns (uint256) {
    return i_interval;
  }

  /// @notice Returns the subscriptionId
  /// @return i_subscriptionId as uint256
  function getSubscriptionId() public view returns (uint64) {
    return i_subscriptionId;
  }

  /// @notice Returns the lottery playable state
  /// @return s_lotteryPlayable as bool
  function getLotteryPlayable() public view returns (bool) {
    return s_lotteryPlayable;
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

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
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