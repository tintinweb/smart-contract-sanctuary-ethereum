// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Raffle definition - raising money by selling numbered tickets, one or some of which are
// subsequently drawn at random, the holder of such tickets winning a prize

//Pick a random winner (verifiably random so that no one can tamper with it)

// Winner selected automatically at certain interval

// Chainlink oracles are used - Randmness, Automated execution (Chainlink keepers)

//Using chainlik Get a random number to generate a verifyable random number
// Run yarn add --dev @chainlink/contracts to get all the contracts
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol';

/*** @title - A sample Raffle contract
 * @author - Sai Pramod U
 * @notice - this contract is to create a decentrilized raffle
 * @dev - This uses chainlink VRF v2
 */

// In order to inherit VRFConsumerBaseV2.sol use 'is'
contract Raffle is VRFConsumerBaseV2 {
  /***********Enums ****************/
  // Enums are the way to create custom data types
  enum RaffleState {
    OPEN,
    CALCULATING
  } // This Rafflestate is a uint256 data type with 0= Open and 1 = calculating

  /***********Error Functions ************/
  //Error function to create custom errors
  error Raffle_NotenoughETHEntered();
  error Raffle__TransferFailed();
  error Raffle__RaffleIsNotCurrentlyOPEN();
  error Raffle__ErrorInConditions(
    uint256 currentBalance,
    uint256 playerPoolLength,
    RaffleState stateOfRaffle
  );

  /*****************State Variables initialization*********/
  //i is for immmutable (constant), immutable variables need to be assigned in constructor
  uint256 private immutable i_entranceFee;
  //we want to use VRFCoordinatorV2Interface, creating contract variable
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_keyhash; // look into VRFCoordinatorV2Interface to learn about keyhash
  uint64 private immutable i_subId;
  uint16 private constant c_minimumRequestConfirmations = 3;
  uint32 private immutable i_callbackGasLimit;
  uint32 private constant c_numWords = 1; // No. of random nos we want

  /******** Lottery Variables ************/
  // we want all the players in storage variable to access even outside the functions
  address payable[] s_players;
  address payable s_recentwinner;
  RaffleState private s_raffleState;
  uint256 private s_lasttimeStamp;
  uint256 private immutable i_interval;

  /***************Events **************/

  //Events - events are a way to store something in the transaction log which can be accessed later
  // inexed variables are easier to access when needed
  event RaffleEnter(address indexed player);
  event RequestedRaffleWinner(uint256 indexed requestId);
  event RaffleWinner(address indexed recentWinner);

  /***********Constructor**********/

  //Constructor is exceuted first with the arguments
  // If we inherit any contract, we need to put that contract's constructor here, see VRFConsumerBaseV2 contarct constructor
  constructor(
    address _vrfCoordinator, //_vrfCoordinator address is not available for local chain, we need to deploy a mock for this
    uint256 entranceFee,
    bytes32 keyhash,
    uint64 subId,
    uint32 callbackGasLimit,
    uint256 interval
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    //Here we are assigning a minimum value to enter the raffle
    i_entranceFee = entranceFee;
    // contract variable = contract_name(contract_address)
    i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    // Assigning all required variables for calling interface contract
    i_keyhash = keyhash;
    i_subId = subId;
    i_callbackGasLimit = callbackGasLimit;
    s_raffleState = RaffleState.OPEN; // We can also use s_raffleState = RaffleState(0) - This is becaus 0 is OPEN
    s_lasttimeStamp = block.timestamp;
    i_interval = interval;
  }

  /********Condition to Enter Raffle ************/

  //creating the function to enter the raffle, it is payable so that people can send eth to it
  function enterRaffle() public payable {
    //Checking if entered amount is more than entrance fee, revert is gas efficient to do this
    if (msg.value < i_entranceFee) {
      revert Raffle_NotenoughETHEntered();
    }
    // Checking if the raffle is still open or not
    if (s_raffleState == RaffleState.CALCULATING) {
      revert Raffle__RaffleIsNotCurrentlyOPEN();
    }
    //We can push the msg.sender address to s_players array, we have to typecast msg.sender as payable as
    //it is not payable by default
    s_players.push(payable(msg.sender));
    //Emitting the data for the event
    emit RaffleEnter(msg.sender);
  }

  /************Picking the Random Number **********************/
  /* * This is the funcion that chainlink keeper node calls
   * Here we are just automating to generate a random number once certain conditions are met
   * The following should be true to proceed to get a random number
   1. The set time interval should have passed
   2. The lottery should be open - ie. no one should be able to enter the raffle when we are processing the winner
   3. The raffle (this contract) has ETH and atleast one player
   4. For this off chain timer - subsricption is needed and should have enough LINK tokens funded in it
   */

  // We are not passing anything to function, perform data is something that we can get back if certain conditions
  // are fullfilled, once the returned upkeepNeeded passes, automatically performUpkeep is triggered
  // Notice that checkupkeep and performUpkeep are from AutomationCompatibleInterface, we do not need contract addresses to use these
  function checkUpkeep()
    public
    view
    returns (
      // bytes calldata /*checkData */
      bool upkeepNeeded,
      bytes memory /*performData */
    )
  {
    // We will now check all the conditions we need
    bool isOpen = (s_raffleState == RaffleState.OPEN);
    bool timePassed = (block.timestamp - s_lasttimeStamp) > i_interval;
    bool hasPlayers = s_players.length > 0;
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    return (upkeepNeeded, '0x0');
  }

  /**
   * @dev Once `checkUpkeep` is returning `true`, performUpkeep function is called automatically
   * and it kicks off a Chainlink requestRandomWords VRF call to get a random winner.
   */

  //Now we need to pick a random winner from the pool of people who have entered
  // Here we will just get one random number from oracle chainlink
  function performUpkeep() external // bytes calldata /* performData */
  {
    (bool upkeepNeeded, ) = checkUpkeep();
    if (!upkeepNeeded) {
      revert Raffle__ErrorInConditions(
        address(this).balance,
        s_players.length,
        s_raffleState
      );
    }
    // We can assign rafflestate as calculating here, as we are processing the randomwinner
    s_raffleState = RaffleState.CALCULATING;
    // Here we request the random number, i_vrfCoordinator.requestRandomWords() is called from interface
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_keyhash,
      i_subId,
      c_minimumRequestConfirmations,
      i_callbackGasLimit,
      c_minimumRequestConfirmations
    );
    emit RequestedRaffleWinner(requestId);
  }

  /************Picking the Random Winner **********************/
  //fulfillRandomWords is from VRFConsumerBaseV2 abstract contract,
  // override will override the function in VRFConsumerBaseV2 contract with this function
  function fulfillRandomWords(
    uint256,
    /*requestId */
    // Request id is not used
    uint256[] memory randomWords
  ) internal override {
    // The random number generated will be so long, we need to use a modulus operator to size it within pool
    // Only 1 random no. is generated in our case (c_minimumRequestConfirmations) which we can assign to randomWords
    uint256 indexofWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexofWinner];
    s_recentwinner = recentWinner;
    // Now we can send all the money to the winner. We can use call same as Fundme contract.
    (bool callSuccess, ) = recentWinner.call{ value: address(this).balance }(
      ''
    );
    // We can now throw an error if callSuccess is false
    if (!callSuccess) {
      revert Raffle__TransferFailed();
    }
    // We can log the recent winners in the transaction log
    emit RaffleWinner(recentWinner);

    // After we have picked the winner and sent all the eth, we can now reset the pool of players
    // we are making s_players a new array with size zero - (0)
    s_players = new address payable[](0);
    // As we have picked the winner, we can assign the Rafflestate back to open
    s_raffleState = RaffleState.OPEN;
    // We can reset the timestamp
    s_lasttimeStamp = block.timestamp;
  }

  /************* View or Pure Getter Functions ***************/
  //we can create a function to view the entrance fee, best practice is to use get for view functions
  function getEntrancFee() public view returns (uint256) {
    return i_entranceFee;
  }

  //function to get the address of a player from s_players array
  function getPlayer(uint256 index) public view returns (address) {
    return s_players[index];
  }

  //function to get players length
  function getPlayersLength() public view returns (uint256) {
    return s_players.length;
  }

  //function to get raffle state
  function getRaffleState() public view returns (RaffleState) {
    return s_raffleState;
  }

  //function to get how many block confirmations we coded, notice the pure finction
  // since c_minimumRequestConfirmations is constant it is not stored in storage, it can be assigned as pure
  function getBlockConfirmations() public pure returns (uint256) {
    return c_minimumRequestConfirmations;
  }

  // Function to get recentwinner
  function getRecentWinner() public view returns (address) {
    return s_recentwinner;
  }

  //function to get last time stamp
  function getLastTimeStamp() public view returns (uint256) {
    return s_lasttimeStamp;
  }

  //function to get interval coded
  function getInterval() public view returns (uint256) {
    return i_interval;
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