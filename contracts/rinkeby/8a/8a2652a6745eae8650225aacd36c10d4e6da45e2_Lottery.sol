/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


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

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


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

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: contracts/lottery.sol



// modify for tickets and higher chance to win based on amount entered (1 ticket per 0.01 eth/usd value($10)
// add an oracle for the eth price the determines entry value
// modify to make entry timelocked for a certain amount of time after a winner selected
// winner is automatically selected at a certain time every day (can only enter before that)
// if there is only one entrant then return funds back to them at the winner selection time
// display odds of winning
// Use chainlink VRF to get winner (allow manager or any entrant to settle the lottery/contract pays out the link)

/*
https://docs.chain.link/docs/chainlink-vrf/
VRF v2 requests receive funding from subscription accounts. 
The Subscription Manager lets you create an account and pre-pay for VRF v2, 
so you don't provide funding each time your application requests randomness. 
This reduces the total gas cost to use VRF v2. It also provides a simple way 
to fund your use of Chainlink products from a single location, so you don't have 
to manage multiple wallets across several different systems and applications.
*/



// Rinkeby

pragma solidity ^0.8.9;




// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol




contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {

    VRFCoordinatorV2Interface COORDINATOR; // RNG 
    AggregatorV3Interface internal priceFeed; // Data Feed

     struct Player {
        uint weight; // 1 weight = $1 at time of entry based on chainlink data feed (ex. $100 = 100 weight)
        address playerAddress; // address of player
    }
    
    
    address public manager;

    // Keeper vars
    uint public immutable interval;
    uint public lastTimeStamp;

    Player[] public players; // index maps to a player object  
    uint public totalPlayers; // # of current players in the lottery session 
    address payable public currWinner; // latest lottery winner
    bool lotteryOpen; // State of the lottery {true, false}

    // Chainlink VRF Initiliazation
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    uint64 subscriptionId; // Subscription ID
    uint256 public s_requestId; // requestID assigned to coordinator randomWords call
    bytes32 public keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; // 30gwei hash
    uint32 callbackGasLimit = 300000; // max fee for calling fulfillRandomWords() used by coordinator
    uint16 requestConfirmations = 3; // minimum confirmations for random number request to be recieved
    uint32 numWords =  3; // amount of random numbers to query	
    
    uint256[] public randomResult; // return random number

    constructor(uint64 _subscriptionId, uint _interval) 
    VRFConsumerBaseV2(vrfCoordinator) 
    {
        manager = msg.sender;
        totalPlayers = 0;
        lotteryOpen = true;

        //keeper 
        interval = _interval;
        //lastTimeStamp = block.timestamp; initalized when 2 players enter lottery

        // VRFV2
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator); // coordinator
        subscriptionId = _subscriptionId;

        // Data Feed
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); // data feed
    }

    modifier isManager() {
        require (msg.sender == manager, 
        "Only the manager can execute this function");
        _;
    }

    function concludeLottery() internal { // only performUpKeep calls this
        lotteryOpen = false; // close so that no one can enter after random numbers are calculated (can't game system)

        // Will revert if subscription is not set and funded. 
        s_requestId = COORDINATOR.requestRandomWords
        (
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords //called by VRF coodinator returns random result only VRF coordinator can call raw -> which calls this function
    (
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomResult = randomWords;
        pickWinner();
    }

    /**
     * Returns the latest price
    */
    function getLatestPrice() public view returns (uint) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint(price); // returns price in eth 10^8 
    }

    function enter() public payable {
        // minimum required players to start lottery is 2
        require(lotteryOpen);

        if (totalPlayers == 1) { // executed when a second player enters the lottery
            lastTimeStamp = block.timestamp; // lottery will close specified interval after this entry    
        }
        
        uint dollarsPassed = (msg.value * getLatestPrice()) / 10**26; // 10**8 price * 10**18 to wei = 10**26 is (price ** amt) / 10^26
        require(dollarsPassed >= 10); // min entry $10

        Player memory player = Player(dollarsPassed, address(msg.sender)); // initalize new player using players count as index
        players.push(player); 
        totalPlayers++; // increment players
    }

    function viewPlayers() public view returns(address[] memory) {
        // Gets all player objects by using the totalPlayers count
        address[] memory playerAdresses  = new address[](totalPlayers);

        for (uint i=0; i < totalPlayers; i++) {
            playerAdresses[i] = (players[i].playerAddress);
        }

        return playerAdresses;
    }

    function pickWinner() internal {
        // generates 3 random numbers
        // gets 2 random players and uses their weight values
        // 3rd random value is modulo'd against the sum weight of the 2 players rand(0,totalWeight) to produce the settler
        // using algo from https://stackoverflow.com/questions/1761626/weighted-random-numbers
        
        uint playerOneIndex = randomResult[0] % totalPlayers;
        uint playerTwoIndex = randomResult[1] % totalPlayers;

        Player memory playerOne = players[playerOneIndex];
        Player memory playerTwo = players[playerTwoIndex];

        uint weight =  playerOne.weight + playerTwo.weight;
        uint settler = randomResult[2] % weight; 

        if(settler < playerOne.weight) {
            currWinner = payable(playerOne.playerAddress);
        } else {
            currWinner = payable(playerTwo.playerAddress); 
        }

        // settle the lottery for winner
        currWinner.transfer(address(this).balance); // transfer all funds to winner

        // reinitalize lottery
        delete players; // clear existing 
        totalPlayers = 0;
        lastTimeStamp = 0; // reset to 0 so keeper won't execute when there are less than 2 players
        lotteryOpen = true; // reopen lottery

    }

    function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        if  (lastTimeStamp != 0 
            && 
            (block.timestamp - lastTimeStamp) > interval) 
        {
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;  
        }
        
        // We don't use the checkData
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        require(block.timestamp != 0);
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = 0; // set to nil for now, should only be active once there are 2 people in an active lottery
            concludeLottery();
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }    



    // 1) if lottery is active, and time since last lottery ended is > interval (lottery can only be closed 1 hour after open)
    // 2) copy players array into memory   
    // 3) using sum of weight (dollars entered)
    // 4) gen rand(0, weight)
    // 5) loop over all players if weight greater then rand return player else rand-=weight keep looping
    // this is costly would need to find a way to do this off-chain
}