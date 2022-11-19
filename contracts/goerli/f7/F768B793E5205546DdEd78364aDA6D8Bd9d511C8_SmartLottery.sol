// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error SmartLottery__LotteryNotOpen();
error SmartLottery__NotEnoughFunds();
error SmartLottery__PlayerAlreadyInLottery();
error SmartLottery__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);
error SmartLottery__NoPendingRewards();
error SmartLottery__ExternalCallFailed();

/**
 * @title SmartLottery
 * @author jrmunchkin
 * @notice This contract creates a simple lottery which will picked a random winner once the lottery end.
 * The player must pay entrance fee to play the lottery, the winner win all the pot.
 * @dev The constructor takes an interval (time of duration of the lottery) and and usd entrance fee (entrance fee in dollars).
 * This contract implements Chainlink Keeper to know when the lottery must end.
 * This contract implements Chainlink VRF to pick a random winner when the lottery ends.
 * This contract also implements the Chainlink price feed to know the entrance fee value in ETH.
 */
contract SmartLottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum LotteryState {
        OPEN,
        CALCULATE_WINNER
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    AggregatorV3Interface private immutable i_ethUsdPriceFeed;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_usdEntranceFee;
    uint256 private immutable i_interval;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    LotteryState private s_lotteryState;
    uint256 private s_lotteryNumber;
    address payable[] private s_players;
    uint256 private s_startTimestamp;
    mapping(uint256 => uint256) private s_lotteryBalance;
    mapping(uint256 => address) private s_lotteryWinners;
    mapping(address => uint256) private s_rewardsBalance;

    event StartLottery(uint256 indexed lotteryNumber, uint256 startTime);
    event EnterLottery(uint256 indexed lotteryNumber, address indexed player);
    event RequestLotteryWinner(
        uint256 indexed lotteryNumber,
        uint256 indexed requestId
    );
    event WinnerLotteryPicked(
        uint256 indexed lotteryNumber,
        address indexed winner
    );
    event ClaimLotteryRewards(address indexed winner, uint256 amount);

    /**
     * @notice contructor
     * @param _vrfCoordinatorV2 VRF Coordinator contract address
     * @param _subscriptionId Subscription Id of Chainlink VRF
     * @param _gasLane Gas lane of Chainlink VRF
     * @param _callbackGasLimit Callback gas limit of Chainlink VRF
     * @param _ethUsdPriceFeed Price feed address ETH to USD
     * @param _usdEntranceFee Entrance fee value in dollars
     * @param _interval Duration of the lottery
     */
    constructor(
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint32 _callbackGasLimit,
        address _ethUsdPriceFeed,
        uint256 _usdEntranceFee,
        uint256 _interval
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = _subscriptionId;
        i_gasLane = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        i_ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        i_usdEntranceFee = _usdEntranceFee * (10**18);
        i_interval = _interval;
        s_lotteryNumber = 1;
        s_lotteryState = LotteryState.OPEN;
    }

    /**
     * @notice Allow user to enter the lottery by paying entrance fee
     * @dev When the first player enter the lottery the duration start
     * emit an event EnterLottery when player enter the lottery
     * emit an event StartLottery the lottery duration start
     */
    function enterLottery() external payable {
        if (s_lotteryState != LotteryState.OPEN)
            revert SmartLottery__LotteryNotOpen();
        if (msg.value < getEntranceFee()) revert SmartLottery__NotEnoughFunds();
        if (isPlayerAlreadyInLottery(msg.sender))
            revert SmartLottery__PlayerAlreadyInLottery();
        s_lotteryBalance[s_lotteryNumber] += msg.value;
        s_players.push(payable(msg.sender));
        if (s_players.length == 1) {
            s_startTimestamp = block.timestamp;
            emit StartLottery(s_lotteryNumber, s_startTimestamp);
        }
        emit EnterLottery(s_lotteryNumber, msg.sender);
    }

    /**
     * @notice Chainlink checkUpkeep which will check if lottery must end
     * @return upkeepNeeded boolean to know if Chainlink must perform upkeep
     * @dev Lottery end when all this assertions are true :
     * The lottery is open
     * The lottery have at least one player
     * The lottery have some balance
     * The lottery duration is over
     */
    function checkUpkeep(
        bytes memory /* _checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = s_lotteryState == LotteryState.OPEN;
        bool timePassed = ((block.timestamp - s_startTimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = s_lotteryBalance[s_lotteryNumber] > 0;
        upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Chainlink performUpkeep which will end the lottery
     * @dev This function is call if upkeepNeeded of checkUpkeep is true
     * Call Chainlink VRF to request a random winner
     * emit an event RequestLotteryWinner when request winner is called
     */
    function performUpkeep(
        bytes calldata /* _performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert SmartLottery__UpkeepNotNeeded(
                s_lotteryBalance[s_lotteryNumber],
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.CALCULATE_WINNER;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestLotteryWinner(s_lotteryNumber, requestId);
    }

    /**
     * @notice Picked a random winner and restart lottery
     * @dev Call by the Chainlink VRF after requesting a random winner
     * emit an event WinnerLotteryPicked when random winner has been picked
     */
    function fulfillRandomWords(
        uint256, /*_requestId*/
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        uint256 actualLotteryNumber = s_lotteryNumber;
        address winner = s_players[indexOfWinner];
        s_lotteryWinners[actualLotteryNumber] = winner;
        s_players = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lotteryNumber++;
        s_rewardsBalance[winner] = s_lotteryBalance[actualLotteryNumber];
        emit WinnerLotteryPicked(
            actualLotteryNumber,
            s_lotteryWinners[actualLotteryNumber]
        );
    }

    /**
     * @notice Allow user to claim his lottery rewards
     * emit an event ClaimLotteryRewards when user claimed his rewards
     */
    function claimRewards() external {
        if (s_rewardsBalance[msg.sender] <= 0)
            revert SmartLottery__NoPendingRewards();
        uint256 toTransfer = s_rewardsBalance[msg.sender];
        s_rewardsBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: toTransfer}("");
        if (!success) revert SmartLottery__ExternalCallFailed();
        emit ClaimLotteryRewards(msg.sender, toTransfer);
    }

    /**
     * @notice Check if the user already play the lottery
     * @param _user address of the user
     * @return isAllowed true if inside, false ether
     */
    function isPlayerAlreadyInLottery(address _user)
        public
        view
        returns (bool)
    {
        for (
            uint256 playersIndex = 0;
            playersIndex < s_players.length;
            playersIndex++
        ) {
            if (s_players[playersIndex] == _user) return true;
        }
        return false;
    }

    /**
     * @notice Get entrance fee to participate to the lottery
     * @return entranceFee Entrance fee in ETH
     * @dev Implements Chainlink price feed
     */
    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = i_ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        return (i_usdEntranceFee * 10**18) / adjustedPrice;
    }

    /**
     * @notice Get entrance fee in dollars to participate to the lottery
     * @return usdEntranceFee Entrance fee in dollars
     */
    function getUsdEntranceFee() external view returns (uint256) {
        return i_usdEntranceFee;
    }

    /**
     * @notice Get duration of the lottery
     * @return interval Duration of the lottery
     */
    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    /**
     * @notice Get actual lottery number
     * @return lotteryNumber Actual lottery number
     */
    function getActualLotteryNumber() external view returns (uint256) {
        return s_lotteryNumber;
    }

    /**
     * @notice Get the state of the lottery
     * @return lotteryState Lottery state
     */
    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    /**
     * @notice Get player address with index
     * @param _index Index of player
     * @return player Player address
     */
    function getPlayer(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    /**
     * @notice Get the number of players of the lottery
     * @return numPlayers Number of players
     */
    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    /**
     * @notice Get the timestamp when the lottery start
     * @return startTimestamp Start timestamp
     */
    function getStartTimestamp() external view returns (uint256) {
        return s_startTimestamp;
    }

    /**
     * @notice Get the value of rewards of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return lotteryBalance Lottery Balance
     */
    function getLotteryBalance(uint256 _lotteryNumber)
        external
        view
        returns (uint256)
    {
        return s_lotteryBalance[_lotteryNumber];
    }

    /**
     * @notice Get the winner of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return lotteryWinner Lottery winner
     */
    function getWinner(uint256 _lotteryNumber) external view returns (address) {
        return s_lotteryWinners[_lotteryNumber];
    }

    /**
     * @notice Get the user pending rewards of his winning lotteries
     * @param _user address of the user
     * @return rewardsBalance Rewards balance
     */
    function getUserRewardsBalance(address _user)
        external
        view
        returns (uint256)
    {
        return s_rewardsBalance[_user];
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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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