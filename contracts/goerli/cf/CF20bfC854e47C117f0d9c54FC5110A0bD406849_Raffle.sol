// Raffle:
// Enter the lottery (paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X minutes -> completly automated
// Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keepers)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//for Chainlink VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; //yarn add --dev @chainlink/contracts
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

//for Chainlink Keepers (which is now named Chainlink Automation)
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/** This is called netspec (To give people who are reading our contract even more information)
 * @title A sample Raffle Contract
 * @author Mr Abuz
 * @notice This contract is for creating an untamperable decentralized smart contract
 * @dev This implements Chainlink VRF v2 and Chainlink Keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    // types should be first thing in our smart contract, acording to the best practises. Enum is a type
    // when we are creating an enum we are secretely creating a uint256 where 0 = OPEN, 1 = CALCULATING (good to know for tests). But like this is much more explicit.
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; //always immutable when we're only setting this one time and never change
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId; //uint64 is enough, doesnt actually need to be a uint256
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval; //always think, will I change this variable in the future or not?

    /* Events */
    //A good syntax to name events is to use the function name but reversed
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId); //for now we're not following the naming convention bcuz we'll be changing the name of the functions later. Prob when I see this its already following the naming convention
    event WinnerPicked(address indexed winner); //we don't have a way to keep track of the list of previous winners, so we're just gonna emit an event so that there's always gonna be that easily queriably history of event winners (and this is the use of thegraph as I think of)

    /* Functions */
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        //above is how we call the constructor of a contract we inherited.
        //we took the address that will generate the random number as a parameter and inputed it in the 2nd constructor of the contract we inherited.
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    //we could add some netspec before each of this functions
    function enterRaffle() public payable {
        // to remember the advantage of this vs require: instead of storing a string, it stores an error code in our smart contract which is a lot more gas efficient
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        s_players.push(payable(msg.sender));

        // Events:
        // Emit an event when we update a dynamic array or mapping
        // Events are one type of Logs.
        // This 'events' and 'logs' live in this special data structure that isn't accessible to smart contracts (thats why its cheaper vs storage, that's the trade off).
        // Events allows you to "print" stuff to this 'logging structure' in a way that's more gas efficient than actually saving it into something like a storage variable.
        // This events get emited to a data storage outside of the smart contract.
        // We can still print some information that is important to us, without having to save it in a storage variable which would take a lot more gas.
        // When we want to know if some transfer function was used, or something else, we can just wait and listen for its event. Events can be used for lots of things.

        // In events, we can have up to 3 indexed parameters/topics. Indexed parameters/topics are parameters that are much easier to search for, and much easier to query
        // than non-indexed parameters. The non-indexed parameters are ABI encoded, harder to reach. If we have the abi they're easy to decode, if not its really hard.
        // This non-indexed parameters cost less gas to pump into the Logs. They are in the 'data' section inside the 'Logs' section of etherscan.
        // In cases where we have our contract verified in etherscan, etherscan knows what the abi is, and we can see them clicking in the 'dec(oded mode)'.
        // The indexed parameters/topics are unencrypted and open to see, but cost more gas and you can only have 3 of them.
        // For example in a lottery when there's a winner every 1 min, we can emit the address of the winner every time someone wins the lottery, but it's probably not worth
        // to have an array on storage recording every address that wins and constantly updating it every 1 min because that would cost a lot of gas, so makes sense to make
        // an emit with the address as an indexed variable (easily queriable) so that with protocols like the graph we can query that info if we need it, since its info
        // that we don't need for the smart contract to work on its own, but good to record/have.
        // Remember all of this, all super important

        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that then Chainlink keeper nodes call.
     * they look for the `upkeepNeeded` to be true.
     * The following should be true in order to return true:
     * 1. Our time interval should have passed
     * 2. The lottery should have at least 1 player, and have some ETH
     * 3. Our subscription is funded with LINK.
     * 4. The lottery should be in an "open" state (While we are waiting for our random numbers to come, we are in this wierd limbo state where we are waiting for it, but
     * we shouldnt allow any new player to join. What we want to do is create some state variable (enum) telling us whether the lottery is open or not)
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData*/
        )
    {
        //this bytes calldata allows us to specify really anything that we want when we call this checkUpkeep function. Having this checkdata be of type bytes means that we
        // can even specify this to call other functions. There's a lot of advanced things we can do by just having an imput parameter of type bytes.
        //For us we're gonna keep this simple and not gonna use this checkdata piece (so we /**/ commented it out). This is more advanced stuff.
        //We made this public since we're calling this function from our performUpkeep() to make sure upkeepNeeded = true, and its not just somebody calling performUpkeep().
        // otherwise it would be external.

        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //external to save some gas, makes sense bcuz this is only called by the chainlink keepers
        //function that will be called by the chainlink keeper and will make the vrf request

        //since anyone can call this function, we wanna make sure this is only called when upkeepNeeded from checkUpkeep() is true. If it is, and someone is calling this,
        //they are making us a favor:
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            ); //we're passing some variables so that who ever is getting this error knows why they are getting this error (some of the conditions of upkeepNeeded not true)
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords( //this requestRandomWords() returns an uint256 requestId, an unique id that defines who's requesting this and all this info
            i_gasLane, //keyHash. Maximum gas price we're willing to pay for a request in wei, like a ceiling to prevent paying a lot on a possible spike up in gas. In the bottom of the file I have the link to pick the hash we want.
            i_subscriptionId, //The subscription ID that this contract uses for funding requests. From an acc we create for it, or from one we use.
            REQUEST_CONFIRMATIONS, //How many confirmations the Chainlink node should wait before responding. We're not gonna worry too much about this and we'll make it a constant variable.
            i_callbackGasLimit, //max gas used for them to call our fulfillRandomWords(), which means how much gas does our fulfillRandomWords cost to call, depending on how complex we make it. We'll just know when we code our fulfillRandomWords function and know its gas so we'll set it in the constructor.
            NUM_WORDS //how many random numbers that we want to get. we'll hard code it as a constant
        );
        emit RequestedRaffleWinner(requestId); //this emited event is actually redundant because if we look at i_vrfCoordinator.requestRandomWords() we'd see that it
        //also emits an event that also returns the requestId, so its actually redundant for us to emit this one. We can just use the emited requestId from vrf coordinator.
        //for the purpose of this course and showing what an event looks like we're gonna leave this here, but if we wanted to refactor this we'd definitely want to remove
        //this emit.
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords //function that will receive the random numbers
    )
        internal
        override
    //chainlink node will always call a 'fulfillRandomWords()' function, with this name.
    //It is inherited then overriden because the vrfcoordinator needs to make sure he can call this exact function.
    // /*requestId*/ we doing it like this because we needed to have requestId there because its an overriden function and it must be called exactly like that and have those
    // 2 arguments, but we're not using the variable, so we just maintain the argument spot with uint256 but we dont identify it(otherwise its an unused variable)

    //is this internal (and the contract inherited) so that no1 can call this function i.e. cheat the system? if it was external/public they could, so only way for no1
    //to be able to call is either to be internal with inherit or external with a require for a certain address. Just speculating, lets see.
    //Answer: This function is internal to either be protecting against someone externally calling this function with a pre-determined random number. But also because when we
    //call the function of i_vrfCoordinator contract in our requestRandomWinner(), it calls back another function in our inherited contract (rawFullFillRandomWords()),
    //not this one directly, that has a require to make sure its sent from address vrfCoordinatorV2, and if it is, it internally calls this function. So someone had to call
    //rawFullFillRandomWords()) to get around the system bcuz its the external one, but it had a require for coordinator address that we inputed in our constructor, so they
    //wouldnt be able to. Since only the coordinator address could call it, that rawfullfill automatically internally calls this function (that doesnt have a require but
    //has to be called from some internal function) which could only be that one which had been verified through the require. And since this is internal no1 more can call)
    //so basically its a safe way to make sure this has to be called from the coordinator address by automatically "adding a require coordinator to this function" without we
    //having to type it, nice way.

    //we're gonna pick a random winner using something calling the modulo function: (the same thing i've learned before using the remainder, the modulo operation yields the
    //remainder r after the division of the operand a by the operand n): 5 % 2 = 1 (1 is the remainder); 202 % 10 = 2 (and we always get a number in this case between
    // 0 and 9 because if it was 10 it would be included, so its perfect for this case because 10 would be the length and 9 is then the max index. Super nice)
    {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View / Pure Functions */
    // this gets were also good to make tests
    function getEntranceFee() public view returns (uint256) {
        //this nice logic to make i_entranceFee private and then create a get function if users need to get the value
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        //since NUM_WORDS is stored in the bytecode (its a constant variable), technically this isn't reading from storage, and therefore this can be a pure function.
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
//Chainlink VRF:
//We are following this example -> https://docs.chain.link/docs/vrf/v2/subscription/examples/get-a-random-number/
//Watch this video: https://www.youtube.com/watch?v=rdJ5d8j1RCg

//      -keyHash: https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
//
//For the Chainlink VRF we need to inherit the VRFConsumerBaseV2 and have a fulfillRandomWords() function overridden from it to be called. Also we need to call
// i_vrfCoordinator.requestRandomWords to request those numbers (which will be inside performUpkeep in this case).

//Chainlink Keepers:
//We are following this example -> https://docs.chain.link/docs/chainlink-automation/compatible-contracts/
//Watch this video: https://www.youtube.com/watch?v=-Wkw5JVQGUo
// There's 2 parts to building a Chainlink keeper upkept:
//         1) Write a smart contract that is compatible by implementing two methods (checkUpkeep and performUpkeep)
//         2) Register that smart contract for upkeep with the Chainlink keeper network
//We're probably not gonna use the "checkData" that is in this video but I think I've understood the purpose, it's when you have more than one keeper for the same contract,
//and you wanna send some different data with each different call so you can know which keeper is calling. I'm pretty sure it's that but I might be wrong :P

//For Chainlink Keepers we need to inherit AutomationCompatibleInterface() and have either an checkUpkeep() and a performUpkeep() overriden from it.

//Would be nice to create our own accounts for managing the chainlink balance for the VRF and Keeper

// One nice thing Patrick said: right at the begining when we just had a bit of the enterRaffle function, 1 event, 2 variables, 2 get functions, he said that at this point
// he'd start already writing some tests and already writing some deploy scripts. The reason that we do this is because its good to test our functionality as we progress,
// and often times when he's writing smart contracts he's often flipping between the deploy scripts, the contracts and the tests to make sure everything is doing exactly
// what he wants them to do. For the purpose of this course, and to make it easier for us to follow, we're gonna keep writing our smart contract almost until its complete,
// and then move to the deploy scripts and the tests. But in the future when we're making them its good to deploy and test as we're writing the contracts.

//14:50:37

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
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

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