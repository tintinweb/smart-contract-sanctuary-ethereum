// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; // to work with COORDINATOR and VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // to use functionalities for Chainlink VRF
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // use Chainlink Keepers

error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Raffle__TransferFailed();

/**@title A Raffle Smart Contract
 * @author JMariadlcs
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    
    /// @notice Enums
    // To let user enter the Raffle or not
    enum RaffleState { 
        Open,
        Calculating
    }

    /// @notice State Variables
    uint256 private s_entranceFee; // Fee to join the Raffle (Immutable: unchangeable and cheaper)
    uint256 private immutable i_interval; // interval when Raffle State should change
    address payable[] private s_players; // to have raffle players

     /// @notice Lottery Variables
    address private s_recentWinner; // most recent Winner
    RaffleState private s_raffleState; // s_ because 'store' and we are going to change the value
    uint256 private s_lastTimeStamp; // to get last time Raffle State changed

    /// @notice VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // coordinator for working with Chainlink VRF 
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // how many blocks are needed to be considered complete
    uint32 private constant NUM_WORDS = 1; // how many random numbers we want to get

    /// @notice Events
    event RaffleEnter(address indexed player); // when a user enters Raffle
    event RequestedRaffleWinner(uint256 indexed requestId); // when VRF gives a random number (winner)
    event WinnerPicked(address indexed winner); // winner is picked

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinatorV2, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2) {
        s_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.Open;

        //VRF Variables
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); // interface(address) -> contract, so i_vrfCoordinator is now a contract (we can interat with it)
        i_gasLane = gasLane; // keyHash -> how much gas is max to get Random Number (price per gas)
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit; // when Chainlink node respond with the random number it uses gas - max gas amount
    }

    /**
    * @notice Function for users to join the Raffle
    * @dev 
    * - Payable function because it is receiving ETH
    * - Check if msg.value is correct
    * - Check state of Raffle -> Open or Calculating
    * - Emit event
    */
    function enterRaffle() public payable {
        // require(msg.value > i_entranceFee, "Not enough money sent."); ->  Better use custom error
        if (msg.value < s_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        // Check Raffle state
        if (s_raffleState != RaffleState.Open) { // Raffle closed
            revert Raffle__RaffleNotOpen();
        }

        // Raffle Open -> users can enter
        s_players.push((payable(msg.sender))); // store player address into array
        emit RaffleEnter(msg.sender);
    }

    /**
    * @notice Functions for select a RANDOMand AUTOMATICALLY WINNER -> Chainlink Keepers || DIRECTLY DONE BY KEEPERS BELOW
    * @dev 
    * 1 - Want it done Automatically
    * 2 - Want it to be really RANDOM
    function requestRandomWinner() external {
        s_raffleState = RaffleState.Calculating;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);
        emit RequestedRaffleWinner(requestId);
    }
    */

    /**
    * @notice Function to check the 4 below requirements, if fulfilled -> pick a Winner
    * @dev 
    * 1 - Be true after some interval
    * 2 - Want the lottery to be open
    * 3 - The contract has ETH
    * 4 - There is al least 1 player
    * 5- Keepers has LINK
    */
    function checkUpkeep( bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.Open == s_raffleState; // 2 - check if its open
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval); // 1 - true if timePassed is > interval
        bool hasPlayers = s_players.length > 0; // 4 - check if there is al least 1 player
        bool hasBalance = address(this).balance > 0; // 3 - check if contract has ETH
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers); // EVERY REQUIREMENT IS FULFILLED -> true
        return (upkeepNeeded, "0x0"); 
    }

    
    /**
    * @notice Functions to actually pick a random NUMBER -> Chainlink keepers to do it Automatically and decentralized
    */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep(""); //checkUpkeep returns 2 parameters but we only need first 1
        if (!upkeepNeeded) { // requirements not met
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        // REQUIREMENTS MET! -> PICK A WINNER (random NUMBER) -> use Chainlink VRF
        s_raffleState = RaffleState.Calculating; // Change Raffle State
        uint256 requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);
        emit RequestedRaffleWinner(requestId);    
    }

    /**
    * @notice Functions to actually pick a winner -> Pass from Chanlink VRF random NUMBER to WINNER
    * @dev 
    * -> should be internal override -> override implemented fulfillRandomWords in VRFConsumerBasev2
    * - randomWords -> array of randomWords
    * - should RESET RAFFLE
    * - should pay winner
    * - use .call() to send ETH (best way to do it)
    */
    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length; // just in case random number is very long we apply modular function
        address payable recentWinner = s_players[indexOfWinner]; // WINNER PICKED
        s_recentWinner = recentWinner; // get view Winner address from outside the contract

        // RESET RAFFLE and PAY WINNER
        s_players = new address payable[](0); // reset players array
        s_raffleState = RaffleState.Open;
        s_lastTimeStamp = block.timestamp; 
        (bool success, ) = recentWinner.call{value: address(this).balance}(""); // We pay winner (SEND ALL THE ETH IN THE CONTRACT)
        if (!success) { // check if transaction succeded
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    // GETTER FUNCTIONS
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return s_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
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
pragma solidity ^0.8.0;

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