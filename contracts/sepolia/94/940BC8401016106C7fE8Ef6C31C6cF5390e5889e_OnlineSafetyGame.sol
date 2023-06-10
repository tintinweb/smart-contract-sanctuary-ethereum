// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// imports to help with true randomness and automate contract
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
// imports helps get the requestion eth conversion rate
// import "./PriceConverter.sol";

// Custom error for ownership validation
error OnlyOwnerCanMakeCall();

/* Errors */
error Game__SendMoreToEnterGame(uint256 requiredAmount, uint256 actualAmount);
error Game__TransferFailed();
error Game__NotOpen();
error Game__GameIsOver();
error Game__GameHasBeenPlayed7x();
error Game__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 s_players,
    uint256 gameState
);

// Custom error when transferring the nth place, lucky winners', owner's prize fails
error Game__nthPlaceTransferFailed();
error Game__LuckyPlayersTransferFailed();
error Game__OwnerTransferFailed();

/**
 * @title Online Safety Game Contract
 * @author Adebayo Omolumo
 * @notice Using what I have learn't from Patrick to create Online Safety Quizzy Game
 * @dev This implements AggregatorV3Interface, chainlink VRF V2 and chainlink Automations
 */

contract OnlineSafetyGame is VRFConsumerBaseV2, AutomationCompatible {
    // Using PriceConverter library for conversion
    // using PriceConverter for uint256;

    enum GameState {
        OPEN,
        CALCULATING
    }

    // on the event players send funds to contract address by accident
    event _fund(address indexed funder, uint256 amount);
    event _withdraw(uint256 indexed blockTimeStamp, uint256 amount);

    // important events during the game
    event GameEnter(address indexed player);
    event RequestGameWinner(uint256 indexed requestId);
    event WinnersPayed(
        address indexed winner1,
        address indexed winner2,
        address indexed winner3
    );
    event OwnerPayed(address indexed owner);
    event LuckyWinnersPayed(address payable luckyPlayer);

    struct Players_data {
        address player;
        uint256 score;
        uint256 winnings;
        uint256 hasPlayed;
        bool isPlaying;
    }

    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => Players_data) public playersData;

    // Tracking accidental funders
    address[] public funders;

    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 14; // at least 1 dollar (this was used wth price converter, due to complications it will be used in version 2)
    uint internal funding;
    uint internal totalBalance;

    // entrance fee determined on contract initialization, players allowed and last question
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    uint32 private constant LAST_QUESTION = 10;

    address payable[] private s_winners;

    // Player with the first, second and third highest score
    Players_data public first;
    Players_data public second;
    Players_data public third;

    // Debugging stores the block time for some callback function test, will remove in preoduction
    uint256 public stat_gameEndTime;
    uint256 public stat_checkUpkeepCalled;
    uint256 public stat_performUpkeepCalled;
    uint256 public stat_performUpkeepCalled2;
    uint256 public stat_fulfillRandomWordsTime;
    uint256 public stat_RandomNumber;

    // i_vrfCoordinator.requestRandomWords() function and it's args
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    // Game state
    GameState private s_gameState;
    uint public immutable i_interval;
    uint public s_lastTimeStamp;
    uint round;

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);

        // Chainlink VRF Coordinator args
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_entranceFee = entranceFee;

        // track the current game state
        s_gameState = GameState.OPEN;
        s_lastTimeStamp = block.timestamp;

        i_owner = msg.sender;
    }

    /**
     * @notice Enter the game by paying a specified amount in USD
     * @dev Requires the game to be open for entry. It initializes/reinitializes the player. I am not adding a way to block multiple plays yet because they could just use another account
     */
    function enterGame() external payable {
        /*Doesnt need public visibility */
        if (msg.value < i_entranceFee) {
            revert Game__SendMoreToEnterGame(i_entranceFee, msg.value);
        }

        if (s_gameState != GameState.OPEN) {
            revert Game__NotOpen();
        }
        funding = funding + msg.value;

        uint hasPlayed = playersData[msg.sender].hasPlayed + 1;
        uint winnings = playersData[msg.sender].winnings;
        playersData[msg.sender] = Players_data(
            msg.sender,
            0,
            winnings,
            hasPlayed,
            true
        );

        s_players.push(payable(msg.sender));
        emit GameEnter(msg.sender);
    }

    /**
     * @notice Updates the player's score based on the provided score and speed
     * @dev Requires the player to be currently playing the game
     * @param calculatedScore The score * speed achieved by the player
     */
    function updatePlayerScore(uint256 calculatedScore) external {
        if (!playersData[msg.sender].isPlaying) {
            revert Game__GameIsOver();
        }

        playersData[msg.sender].score =
            playersData[msg.sender].score +
            calculatedScore;
        assignRanking(msg.sender);
    }

    /**
     * @notice Assigns ranking to a player based on the provided score and address
     * @dev Updates the first, second, and third winners based on the current player's score,
     *      and checks if the game is over for the player
     * @param addr The address of the player
     */
    function assignRanking(address addr) internal {
        Players_data memory currPlayer;
        currPlayer = playersData[addr];

        if (currPlayer.score > first.score) {
            third = second;
            second = first;
            first = currPlayer;
        } else if (currPlayer.score > second.score) {
            third = second;
            second = currPlayer;
        } else if (currPlayer.score > third.score) {
            third = currPlayer;
        }
        playersData[addr].isPlaying = false;
    }

    function gameOver() external {
        playersData[msg.sender].isPlaying = false;
    }

    /**
     * @notice Checks whether upkeep is needed for the game
     * @dev Returns true if the game is open, enough time has passed, there are players, and there is balance available
     * @return upkeepNeeded Boolean indicating whether upkeep is needed
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (GameState.OPEN == s_gameState);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);

        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Performs the upkeep of the game by initiating the calculation of winners
     * @dev Reverts if the upkeep is not needed
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        stat_checkUpkeepCalled = block.timestamp;

        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Game__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_gameState)
            );
        }

        stat_performUpkeepCalled = block.timestamp;

        s_gameState = GameState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        stat_performUpkeepCalled2 = block.timestamp;

        emit RequestGameWinner(requestId);
    }

    /**
     * @notice Fulfills the request for random words by updating game state and selecting winners
     * @dev Resets the player list, updates the last timestamp, sets the game state to open,
     *      adds the first, second, and third winners, and distributes the balance among winners
     * @param randomWords An array of random words used for winner selection
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        stat_RandomNumber = randomWords[0];
        stat_fulfillRandomWordsTime = block.timestamp;
        uint256 luckyIndex = randomWords[0] % s_players.length;
        address payable luckyWinner = s_players[luckyIndex];

        s_winners = new address payable[](0);

        s_winners.push(payable(first.player));
        s_winners.push(payable(second.player));
        s_winners.push(payable(third.player));
        s_winners.push(payable(luckyWinner));

        distributeBalance(s_winners);
    }

    /**
     * @notice Distributes the balance among the winners and other players
     * @dev Requires a minimum of 10 accounts, ensures sufficient balance, and distributes amounts to winners and other players
     * @param accounts An array of payable addresses representing the winners and other players
     */
    function distributeBalance(address payable[] memory accounts) internal {
        require(accounts.length >= 4, "Insufficient number of accounts");

        // uint256 totalBalance = address(this).balance;
        totalBalance = funding;

        uint256 firstPlaceAmount = (totalBalance * 35) / 100;
        uint256 secondPlaceAmount = (totalBalance * 20) / 100;
        uint256 thirdPlaceAmount = (totalBalance * 10) / 100;
        uint256 ownerAmount = (totalBalance * 5) / 100;
        uint256 luckyAmount = (totalBalance * 7) / 100;

        funding =
            funding -
            (luckyAmount +
                ownerAmount +
                thirdPlaceAmount +
                secondPlaceAmount +
                firstPlaceAmount);

        /**
         *
         * @notice Create backup functions owner can call if any of this fails
         */
        (bool firstPay, ) = accounts[0].call{value: firstPlaceAmount}("");
        // playersData[accounts[0]].winnings = firstPlaceAmount;
        playersData[accounts[0]] = Players_data(
            msg.sender,
            0,
            firstPlaceAmount,
            0,
            false
        );

        (bool secondPay, ) = accounts[1].call{value: secondPlaceAmount}("");
        // playersData[accounts[1]].winnings = secondPlaceAmount;
        playersData[accounts[1]] = Players_data(
            msg.sender,
            0,
            secondPlaceAmount,
            0,
            false
        );

        (bool thirdPay, ) = accounts[2].call{value: thirdPlaceAmount}("");
        // playersData[accounts[2]].winnings = thirdPlaceAmount;
        playersData[accounts[2]] = Players_data(
            msg.sender,
            0,
            thirdPlaceAmount,
            0,
            false
        );

        if (!(firstPay && secondPay && thirdPay)) {
            revert Game__nthPlaceTransferFailed();
        }

        emit WinnersPayed(accounts[0], accounts[1], accounts[2]);

        (bool luckyPay, ) = accounts[3].call{value: luckyAmount}("");
        playersData[accounts[3]].winnings = luckyAmount;

        if (!luckyPay) {
            revert Game__LuckyPlayersTransferFailed();
        }

        emit LuckyWinnersPayed(accounts[3]);

        (bool ownerPay, ) = i_owner.call{value: ownerAmount}("");
        if (!ownerPay) {
            revert Game__OwnerTransferFailed();
        }
        emit OwnerPayed(i_owner);

        stat_gameEndTime = block.timestamp;

        s_players = new address payable[](0);
        delete first;
        delete second;
        delete third;

        round++;
        s_lastTimeStamp = block.timestamp;
        s_gameState = GameState.OPEN;
    }

    /**
     * @notice Accepts funds and adds the sender to the list of funders
     * @dev Requires the sent value to meet a minimum conversion rate to USD
     */
    function fund() public payable {
        require(msg.value >= MINIMUM_USD, "You need to pay more ETH!");

        funders.push(msg.sender);
        emit _fund(msg.sender, msg.value);

        addressToAmountFunded[msg.sender] = msg.value;
    }

    /**
     * @notice This allows only the contract creator/owner to withdraw funds
     */
    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        uint256 currentBal = address(this).balance;

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call function failed");

        emit _withdraw(block.timestamp, currentBal);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert OnlyOwnerCanMakeCall();
        }
        _;
    }

    /**
     * @dev The function will allow us track the most recent previous winners
     * @param index is the uint value for positions
     * @return The 0: first, 1: second, 2: third, 3: lucky,
     */

    function getAPrevWinner(uint256 index) public view returns (address) {
        return s_winners[index];
    }

    function getGameState() public view returns (GameState) {
        return s_gameState;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    /**
     *  @dev Retrieves the remaining time in seconds until the specified end time.
     *  @return The remaining time in seconds as a signed integer.
     *  This function allows tracking negative values, indicating that the end time has passed.
     */

    function getTimeLeft() public view returns (int) {
        // using int on the chance the value is -ve
        int currentTime = int(block.timestamp);
        int endTime = int(s_lastTimeStamp + i_interval);
        return endTime - currentTime;
    }

    function isGameOver() public view returns (bool) {
        return getTimeLeft() < 1;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getRemainingBalance() public view onlyOwner returns (int) {
        return int(totalBalance) - int(funding);
    }

    function getPlayersData()
        external
        view
        returns (address, uint, uint, uint, bool)
    {
        return (
            playersData[msg.sender].player,
            playersData[msg.sender].score,
            playersData[msg.sender].winnings,
            playersData[msg.sender].hasPlayed,
            playersData[msg.sender].isPlaying
        );
    }

    function getFirst() external view returns (address, uint) {
        return (first.player, first.score);
    }

    function getSecond() external view returns (address, uint) {
        return (second.player, second.score);
    }

    function getThird() external view returns (address, uint) {
        return (third.player, third.score);
    }

    function getRounds() external view returns (uint) {
        return round;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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