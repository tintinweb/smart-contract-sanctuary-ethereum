// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
//we use chainlink oracle for randomness, automated exectution(chainlink keeper)
//before you can import
//yarn add --dev @chainlink/contracts
error RangeOutOfBounds();
error Roullete__NotEnoughEth();
error Roullete_transferFailed();
error Roullete_closed();
error Roullete_upKeepNotNeeded(
    uint256 currentBalance,
    uint256 Bplayers,
    uint256 Rplayers,
    uint256 Gplayers,
    uint256 roulleteState
);

//we need to make it
//this implements chianlink v2 and chainlink keepers
contract Roullete is VRFConsumerBaseV2, KeeperCompatibleInterface {
    uint256 private color = 0;
    enum RoulleteState {
        OPEN, //0
        CALCULATING //1
    }
    enum Bets {
        RED,
        BLACK,
        GREEN
    }
    uint256 private immutable i_entraceFee; //immutable --> we only set it once in the constructor
    address payable[] private s_RedPlayers; //payable since we want to pay them if they win
    address payable[] private s_GreenPlayers; //payable since we want to pay them if they win
    address payable[] private s_BlackPlayers; //payable since we want to pay them if they win
    VRFCoordinatorV2Interface private immutable i_COORDINATOR;
    //events
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant requestConfirmations = 3;
    uint32 private immutable i_callbackgaslimit;
    uint32 private constant numWords = 1;
    uint256 private s_lastTimeStamp;
    uint256 internal constant MAX_CHANCE_VALUE = 100; // max chance is 100 percent
    uint256 private constant c_interval = 30;
    event requestedRoulleteResult(uint256 indexed requestId);
    event RoulleteEnter(address indexed player);
    event winnerpicked(address payable[] indexed winner);
    string lastColor = "";
    address payable[] private s_recentWinners;
    RoulleteState private s_roulleteState;

    //VRFCoordinatorV2 is where we generate the random number (the address where we are going to generate the number !)
    constructor(
        uint256 entranceFee,
        address VRFCoordinatorV2, //contract address --> probably need a mock for this ....
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(VRFCoordinatorV2) {
        //since we only set it once, we can make it immutable
        i_entraceFee = entranceFee;
        i_COORDINATOR = VRFCoordinatorV2Interface(VRFCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackgaslimit = callbackGasLimit;
        s_roulleteState = RoulleteState.OPEN;
        s_lastTimeStamp = block.timestamp;
        color = 3;
    }

    function enterRed() public payable {
        if (msg.value < i_entraceFee) {
            revert Roullete__NotEnoughEth();
        }

        if (s_roulleteState != RoulleteState.OPEN) {
            revert Roullete_closed();
        }
        s_RedPlayers.push(payable(msg.sender)); //make ssure each address is payabe
        emit RoulleteEnter(msg.sender);
    }

    function enterBlack() public payable {
        if (msg.value < i_entraceFee) {
            revert Roullete__NotEnoughEth();
        }

        if (s_roulleteState != RoulleteState.OPEN) {
            revert Roullete_closed();
        }
        s_BlackPlayers.push(payable(msg.sender)); //make ssure each address is payabe
        emit RoulleteEnter(msg.sender);
    }

    function enterGreen() public payable {
        if (msg.value < i_entraceFee) {
            revert Roullete__NotEnoughEth();
        }

        if (s_roulleteState != RoulleteState.OPEN) {
            revert Roullete_closed();
        }
        s_GreenPlayers.push(payable(msg.sender)); //make ssure each address is payabe
        emit RoulleteEnter(msg.sender);
    }

    /**
    *@dev alex kang 
    this is the function chainlink keeper calls, they look for the upkeepneeded 
    the following should be true in order to return true
        1. TIME INTERVAL SHOULD BE PASSED
        2. lottery should have at least 1 player and some eth 
        3.subscription funded with LINK
        4. LOTTERY should be in an "open" state --> when we are waiting for the number to get back
        we are in a closed state 
    
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */ //we use perform data when we want to do intensive calculations off chain to reduce gas fees and pass into
        )
    //performUpkeep when needed

    {
        bool isOpen = s_roulleteState == RoulleteState.OPEN;
        // block.timeStamp gives the current time, in order to get the time passed
        //we could do something like block.timeStamp - prevTimeStamp(we neeod a variable for this )
        bool timepassed = ((block.timestamp - s_lastTimeStamp)) > c_interval;
        bool hasplayers = (s_BlackPlayers.length > 0 ||
            s_RedPlayers.length > 0 ||
            s_GreenPlayers.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = isOpen && timepassed && hasplayers && hasBalance;
    }

    //we want chainlink keeper to call this so we do not have call it ourselvrsd
    //before we had it as requestRandom, but in keepers we had to have a
    //performUpkeep, u might as well switch the name to perform upkeep
    //chainlink keepers will do intensive work off chain to see if they can call the perform up keep function, if it can, it calls this function on chain

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //request random number
        //once we get it --> do smt with it
        // 2 trasaction process --> fair
        //before we call perform up keep we need to check if checkupkeep is true
        (bool upkeepNeeded, ) = checkUpkeep(""); //since we do not use calldata, and since we only want the bool, we just pull that one out
        if (!upkeepNeeded) {
            //the reason why we check again is the suggestion to always revalidate checkupkeep conditions when being called to prevent malicious attakcs
            revert Roullete_upKeepNotNeeded(
                address(this).balance,
                s_BlackPlayers.length,
                s_RedPlayers.length,
                s_GreenPlayers.length,
                uint256(s_roulleteState)
            );
        }

        s_roulleteState = RoulleteState.CALCULATING;
        uint256 requestid = i_COORDINATOR.requestRandomWords( //calling it on the coordinator
            i_gasLane, //gaslane
            i_subscriptionId,
            requestConfirmations,
            i_callbackgaslimit,
            numWords
        );

        emit requestedRoulleteResult(requestid); //save request id to logs
    }

    //in chainlink contracts src v0.8 --> fullfillRandomWords is virtual meaning we can ovvereide it
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        //since we only requesting one randomness, randomwords will come back as size 1
        //we can use modular operator
        //if s_players is of size 10
        //and we have random number == 202
        // we can 202 % 10   == 2 --> 2th winner
        uint256 chance = randomWords[0] % MAX_CHANCE_VALUE;
        Bets winningBet = getWinningBet(chance);
        if (winningBet == Bets.RED) {
            s_recentWinners = s_RedPlayers;
            color = 2;
        } else if (winningBet == Bets.BLACK) {
            s_recentWinners = s_BlackPlayers;
            color = 1;
        } else {
            s_recentWinners = s_GreenPlayers;
            color = 0;
        }
        s_lastTimeStamp = block.timestamp;

        s_RedPlayers = new address payable[](0);
        s_BlackPlayers = new address payable[](0);
        s_GreenPlayers = new address payable[](0);
        if (color == 0) {
            lastColor = "GREEN";
        } else if (color == 1) {
            lastColor = "BLACK";
        } else {
            lastColor = "RED";
        }
        //a for loop
        if (s_recentWinners.length == 0) {
            //no winner
        } else if (color == 0) {
            for (uint256 i = 0; i < s_recentWinners.length; i++) {
                //make it constatnt winning for now
                (bool success, ) = s_recentWinners[i].call{value: 0.14 ether}(
                    ""
                );
                if (!success) {
                    revert Roullete_transferFailed();
                }
            }
        } else {
            for (uint256 i = 0; i < s_recentWinners.length; i++) {
                //make it constatnt winning for now
                (bool success, ) = s_recentWinners[i].call{value: 0.02 ether}(
                    ""
                );
                if (!success) {
                    revert Roullete_transferFailed();
                }
            }
        }
        emit winnerpicked(s_recentWinners);
        s_roulleteState = RoulleteState.OPEN;
        color = 3;
    }

    function getWinningBet(uint256 chance) public pure returns (Bets) {
        uint256 sumsf = 0;
        uint256[3] memory chanceArray = getChanceArray();

        for (uint256 i = 0; i < chanceArray.length; i++) {
            if (chance >= sumsf && chance < sumsf + chanceArray[i]) {
                return Bets(i);
            } else {
                sumsf += chanceArray[i];
            }
        }

        revert RangeOutOfBounds();
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [49, 49, MAX_CHANCE_VALUE];
    }

    /*
        notes about chainlink VRF v2 

        getting a random number --> you need a subcription 


    */
    function getEntraceFee() public view returns (uint256) {
        return i_entraceFee;
    }

    function getBlackPlayer(uint256 index) public view returns (address) {
        return s_BlackPlayers[index];
    }

    function getRedPlayer(uint256 index) public view returns (address) {
        return s_RedPlayers[index];
    }

    function getGreenPlayer(uint256 index) public view returns (address) {
        return s_GreenPlayers[index];
    }

    function getRecentWinners(uint256 index) public view returns (address) {
        return s_recentWinners[index];
    }

    function amountOfWinners() public view returns (uint256) {
        return s_recentWinners.length;
    }

    function getroulletestate() public view returns (RoulleteState) {
        return s_roulleteState;
    }

    //the reason why it is pure is because numwords is a constant
    function getNumWords() public pure returns (uint256) {
        return numWords;
    }

    function getNumberOfPlayersOfBlack() public view returns (uint256) {
        return s_BlackPlayers.length;
    }

    function getNumberOfPlayersOfRed() public view returns (uint256) {
        return s_RedPlayers.length;
    }

    function getNumberOfPlayersOfGreen() public view returns (uint256) {
        return s_GreenPlayers.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return requestConfirmations;
    }

    function getgasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getInterval() public pure returns (uint256) {
        return c_interval;
    }

    function getLatestColor() public view returns (string memory) {
        return lastColor;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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
}

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