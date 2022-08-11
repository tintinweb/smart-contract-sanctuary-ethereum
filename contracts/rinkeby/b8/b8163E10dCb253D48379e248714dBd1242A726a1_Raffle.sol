// Raffle
// Enter the lottery by paying some amount
// Pick a random winner (verifiably random / verifiable randomness... tamper-proof, bcz randomness can be tampered with)
// Winner to be selected in a completely automated manner after X time (event-trigger-driven)
// Chainlink's Oracle n/w = Randomness (VRF), auto-executable (Keppers)


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;                                                             // July 29

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";                       // Needed to make our contract VRF-able. Interetsed in fulfillRandomWords() function
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";    //10 functions in total out of which we're interested in 1 and that's = requestRandomwords() only. Did not directly inherit it, yet we can call it's requestRandomWords() funtion.
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";    // Contrary to the example, Patrick said we'll go with the interface rather the contract that inherits the interface, because we want to override those 2 functions, that's it. Can be done with the interface.

/* Custom Errors declared */
error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailer();
error Raffle__Notopen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/** @title A sample Raffle contract
*   @author Manu Kapoor
*   @notice This is an untamperable decentralized Lottery Smart Contract
*   @dev This contract implements Chainlink VRF v2 and Chainlink Keeper
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {                   // do a preliminary check by : yarn hardhat compile
                                                                     // Raffle and VRFConsumerBasev2 (interface - ABI array will be generated) will be compiled
    
    /* Type declaration */
    enum RaffleState{                                                // needed - as more than 2 states possible, so no boolean.
        OPEN,                                                        // uint256 0, 1
        CALCULATING
    }

    /*All State Variables*/
    address payable[] private s_players;                            // Storage var - bcz we'll be adding / removing players a lot
    uint256 private immutable i_entranceFee;                        // saving gas #1,2 - once set (inside constructor), it's going to be constant    
    
    /* Lottery variables, part of State variables, of course */
    address payable private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* parameters of requestRandomWords() function */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS =3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /* Events */
    event RaffleEnter(address indexed players);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* functions() */
    constructor (
        address vrfCoordinatorV2,       // It's a contract's address. Outside the scope of this conntract, hence "mock(s)" needed.
        uint256 entranceFee, 
        bytes32 gasLane, 
        uint64 subscriptionId,
        uint32 callbackGasLimit,        // used for fulfillRandomWords() eventually to process + store returned (verified) Random Words that were requested by requestRandomWords()
        uint256 interval
        ) VRFConsumerBaseV2(vrfCoordinatorV2) {                                 // calling possible as it's made internal by inheriting, else would have been external by merely importing.
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);     // type casted address to type contract / interface VRFC..V2Int.
            i_entranceFee = entranceFee;
            i_gasLane = gasLane;
            i_subscriptionId = subscriptionId;
            i_callbackGasLimit = callbackGasLimit;
            s_raffleState = RaffleState.OPEN;                                   // syntax to access / assign permitted values to any enum type variable
            s_lastTimeStamp = block.timestamp;
            i_interval = interval;
    }

    function enterRaffle () public payable {                                    // Should only run when the Lottery is in OPEN state.
        // if not enough ETH sent, revert for this user
        // using custom_error instead of require
        // saving gas#3 

        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__Notopen();
        }

        s_players.push(payable(msg.sender));    // player entered in our Array. We can enter more details fo the player using Array of Struct.
        emit RaffleEnter(msg.sender);           // Event name reversed from that of the function

    }

    /**          NatSpec 
    * @dev -    Chainlink nodes look for this function to return True-upkeepNeeded variable.
    *           If it does, then they'd run performUpkeep = requestRandomWinner() function
    *           The following should be true iff following CHECKs are met:
    *           1. The time interval has been passed
    *           2. The Lottery has at least one player and has at least some non-zero ETH amount left.
    *           3. Subscription still has some funds left to let Chainlink nodes to process the checkUpKeep function.
    *           4. Upkeep has not been cancelled yet and wants to be performed by the Nodes.
    *           5. The Lottery must be in an "open" state and not in a "closed" / "calculating" one.
    */

    // The function is made "public" so that performUpkeep can call it internally.
    // declare checkData "memory" contrary to "calldata" in the counter.sol example
    // "override" - Despite the actual function not marked "virtual" in KeeperCompatibleInterface.sol, we have to mark it "override" else compilation error.
    // only defined, not explicitly invoked in our contract. Implicitly invoked by Chainlink Keepers node / network / arch.
    function checkUpkeep (bytes memory /* checkData */) public override returns (bool upkeepNeeded, bytes memory /*performData*/) {           // should work when lottery in OPEN state.
        bool isOpen = (RaffleState.OPEN == s_raffleState);                              // Check # 5                
        bool isTimePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);         // Check # 1. Also, s_lastTimeStamp resetting in fulfillRandomWords()
        //  Off-chain, at every block, timestamp is read and cpmpared. Same written in Chainlink Keepers docs
        bool hasPlayers = (s_players.length > 0);                                       // Check # 2 (a)
        bool hasBalance = (address(this).balance > 0);                                  // Check # 2 (b)
        upkeepNeeded = (isOpen && isTimePassed && hasPlayers && hasBalance);            // will be automatically returned
    }

    // This function is made "external" so that if any user invokes it, it will revert if upkeepNeeded is false, along with the reason of revert.
    // "override" - Despite the actual function not marked "virtual" in KeeperCompatibleInterface.sol, we have to mark it "override" else compilation error.
    // only defined, not explicitly invoked in our contract. Implicitly invoked by Chainlink Keepers node / network / arch.
    function performUpkeep(bytes calldata /* performData */) external override {        // "external" are gas-cheaper than the internal ones
       
        // 1. Name changed: earleir, it was requestRandomWinner().
        // When we do not want to use Keepers and only VRF func. of Chainlink, we'll keep the name requestRandomWinner()
        // 2.. Request the random no. using this function.
        // 3. Once you get it, now do something with it - anohter function below will do it.
        // Safer and brute force-tamper-proof which is hard to acheive in 1 transaction-process.

        (bool upkeepNeeded, ) = checkUpkeep("");

        if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded (address(this).balance, s_players.length, uint256(s_raffleState));    // Check # 5, 2(a), 2(b) not met yet
        }

        s_raffleState = RaffleState.CALCULATING;
        // Below, used nowhere while testing checkUpkeep() and invoking performUpkeep()
        uint256 requestId = i_vrfCoordinator.requestRandomWords(        // interesting and insightful to read about NatSpec comments of this function in VRFCoordinatorV2interface.sol
                                                                        // directly invoked, not defined by us here.
                                                                        // mandated to be invoked explicitly by us in our S/C to send request to Chainklink node.
        i_gasLane,                                  //  gasLane - Aug. 01
        i_subscriptionId,
        REQUEST_CONFIRMATIONS,                      //  no need to 'parameterize' this
        i_callbackGasLimit,   
        NUM_WORDS                                   //  no need to 'parameterize' this
    );
    emit RequestedRaffleWinner(requestId);          //  actually, this event is redundant bcz rRW() is originally emitting an event...
                                                    //  body defined inside VRFCoodV2Mock (that inherits - VRFCoodV2Interface)...
                                                    // we did Not inerit VRFCoodV2Interface, only imported, hence used its object
    }

    // only defined, not explicitly invoked in our contract. Implicitly invoked by Chainlink VRF node returning the random words, passing thru VRF Cood (same as VRF Cood V2 (Mock))
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override { // why so? - 
        uint256 indexOfWinner = randomWords[0] % s_players.length;          // we need only 1 randomword, randomWords-array length = 1
        address payable recentWinner = s_players[indexOfWinner];           // 0 to (length-1) remainder will be the selected winner
        s_recentWinner = recentWinner;
        
        //  The Lottery is getting reset here wit h3 updates:
        //  Till the winner is picked, state is CALCULATING, not OPEN
        s_raffleState = RaffleState.OPEN;                                  
        //  Also, make s_players array NULL now, before new round of enrolments starts
        s_players = new address payable[](0);
        //  Reset the Timestamp also
        s_lastTimeStamp = block.timestamp;
        
        //  Now, transfer all the money in the contract to the winner
        (bool success, ) = s_recentWinner.call{value: address(this).balance}("");
        //  Not require, go with revert
        if (!success) {
            revert Raffle__TransferFailer();
        }
        emit WinnerPicked(recentWinner);                                   // I believe it is samne as s_recentWinner

    }

    /* View and Pure functions */

    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 index) public view returns(address) {  // declaring address type in return is ok for address payable type array but not other way around
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {       // returns RaffleState as 0, 1 but it's in BigNumber format (unit tetsing)
        return s_raffleState;
    }

    //"pure" fucntion ? NUM_WORDS is not read from the Storage as it goes straight into the bytecode (part of it only).
    // Hence, technically, it's not reading any state variable here.abi
    //bcz, return NUM_WORDS = return 1 (No state variable read)
    function getNumwords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    // Not the present block.timestamp. Our contract's Timestamp variable value
    function getLatestTimestamp() public view returns (uint256) {
        return s_lastTimeStamp;             
    }

    function getRequestConfirmations() public pure returns(uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getRaffleBalance() public view returns(uint256) {
        return address(this).balance;
    }
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
 * @dev The purpose of this contract is to make it easy for unrelated contracts (Raffle.sol)
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator -- this func.() is the one that establishes the connection with the "consumer_contract" - Raffle.sol
 * @dev 2. The consumer contract implements fulfillRandomWords. -- this func.() is the one that is virtual and overridden by Raffle.sol
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
 * @dev The randomness argument to fulfillRandomWords is a set of random words (array randomwords[] in my Raffle.sol)
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
   * @notice fulfillRandomness handles the VRF response. Your contract (Raffle.sol) must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts (Raffle.sol) to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof (called fulfillment received) rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call.
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