// SPDX-License-Identifier: None
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @author Johnny Li
/// @custom:email [email protected]
contract Lottery is VRFConsumerBaseV2 {
    /// @param players players list
    /// @param playersMap key: user address, value: bet count
    struct BetInfo {
        address[] players;
        mapping(address => uint256) playersMap;
    }

    /// @notice Contains all information of one game
    /// @param banker banker that starts this game
    /// @param betInfoMap number index to betters info map
    /// @param winnerAward how much do each winner earns
    /// @param withdrawMap if players already withdrew their awards
    struct GameInfo {
        uint8[] luckyNumbers;
        uint128 betAmount;
        uint128 betFee;
        Status status;
        uint32 minPlayerCount;
        uint32 maxPlayerCount;
        uint32 endTimestamp;
        uint32 totalBetCount;
        uint8 winningNumberIndex;
        address banker;
        uint256 winnerAward;
        mapping(uint8 => BetInfo) betInfoMap;
        mapping(address => bool) withdrawMap;
    }

    /// @dev ChainLink VRF service related params
    struct VRFParams {
        bytes32 keyHash;
        VRFCoordinatorV2Interface vrfCoordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    /// @notice Reprensents the game status
    /// @param Init Initial state
    /// @param Open Game is ongoing, players can bet
    /// @param Drawing Time up, no more bet, choosing the winning number
    /// @param Settling Winning number is selected, settling all the remaing work
    /// @param Closed Game ended
    enum Status {
        Init,
        Open,
        Drawing,
        Settling,
        Closed
    }

    error IncorrectAmount();
    error IncorrectStatus(Status expected);
    error IncorrectTiming();
    error InvalidIndex();
    error AlreadyWithdrew();
    error NotAuthorized();
    error ReachPlayerLimit();

    /// @notice Emit when a number is bet by a player
    /// @return gameId game id
    /// @return numberIndex the index of the bet number
    /// @return totalBetCount total bet count of this number
    event NumberBet(
        uint64 indexed gameId,
        uint8 numberIndex,
        uint256 totalBetCount
    );
    /// @notice Emit when status is changed by any reason
    /// @return gameId game id
    /// @return from status before the change
    /// @return to status after the change
    event StatusChanged(uint64 indexed gameId, Status from, Status to);
    /// @notice Emit when the game finished, and the winning number selected
    /// @return gameId game id
    /// @return numberIndex the winning number's index, if it's not in range, means no winning number
    /// @return winnerAward the award amount every winner can get
    event NumberWon(
        uint64 indexed gameId,
        uint8 numberIndex,
        uint256 winnerAward
    );

    /// @notice Every player should pay this fee to start a new game as game banker
    uint256 public bankerFee = type(uint256).max;
    mapping(address => uint256) public playerBalance;
    /// @notice game id to game info map
    mapping(uint64 => GameInfo) gameInfoMap;
    /// @notice sent VRF request id to game id map;
    mapping(uint256 => uint64) vrfRequestGameIdMap;
    /// @notice banker address to game id array that started by this banker
    mapping(address => uint64[]) bankerGameIdMap;
    VRFParams vrfParams;
    address contractOwner;
    uint64 public gameIdCounter;

    constructor(address coordinatorAddr) VRFConsumerBaseV2(coordinatorAddr) {
        contractOwner = msg.sender;
        vrfParams.vrfCoordinator = VRFCoordinatorV2Interface(coordinatorAddr);
    }

    /// @notice Players can send ether to deposit as their balance
    receive() external payable {
        playerBalance[msg.sender] += msg.value;
    }

    // @notice Transfer contract's ownership, and the balance as well
    function setContractOwner(address newOwner) external {
        onlyAllowOwner();
        require(newOwner != address(0));
        uint256 balance = playerBalance[contractOwner];
        playerBalance[contractOwner] = 0;
        contractOwner = newOwner;
        playerBalance[contractOwner] = balance;
    }

    function setBankerFee(uint256 fee) external {
        onlyAllowOwner();
        bankerFee = fee;
    }

    function setVRFSubscriptionId(uint64 subscriptionId) external {
        onlyAllowOwner();
        vrfParams.subscriptionId = subscriptionId;
    }

    function setVRFKeyHash(bytes32 keyHash) external {
        onlyAllowOwner();
        vrfParams.keyHash = keyHash;
    }

    function setVRFCallbackGasLimit(uint32 callbackGasLimit) external {
        onlyAllowOwner();
        vrfParams.callbackGasLimit = callbackGasLimit;
    }

    function setVRFRequestConfirmations(uint16 requestConfirmations) external {
        onlyAllowOwner();
        vrfParams.requestConfirmations = requestConfirmations;
    }

    /// @notice Start a new game
    /// @param luckyNumbers The numbers players can bet on
    /// @param betAmount The amount every bet need to put on the table
    /// @param betFee The extra amount to pay for the game for every single bet
    /// @param minPlayerCount (Inclusive) The minimun player count to draw the game at the end
    /// @param maxPlayerCount (Inclusive) The maximum player count that can bet
    /// @param lastSeconds How long the game lasts
    function start(
        uint8[] memory luckyNumbers,
        uint128 betAmount,
        uint128 betFee,
        uint32 minPlayerCount,
        uint32 maxPlayerCount,
        uint32 lastSeconds
    ) external payable {
        if (msg.value < bankerFee) {
            revert IncorrectAmount();
        }
        unchecked {
            require(lastSeconds < 3600 * 24 * 7);
            require(luckyNumbers.length > 0 && luckyNumbers.length < 1000);
            gameIdCounter += 1;
            uint64 gameId = gameIdCounter;
            GameInfo storage gameInfo = gameInfoMap[gameId];
            gameInfo.banker = msg.sender;
            gameInfo.luckyNumbers = luckyNumbers;
            gameInfo.status = Status.Open;
            gameInfo.betAmount = betAmount;
            gameInfo.betFee = betFee;
            gameInfo.minPlayerCount = minPlayerCount;
            gameInfo.maxPlayerCount = maxPlayerCount;
            gameInfo.endTimestamp = uint32(block.timestamp + lastSeconds);
            emit StatusChanged(gameId, Status.Init, Status.Open);
            bankerGameIdMap[msg.sender].push(gameId);
            playerBalance[contractOwner] += msg.value;
        }
    }

    /// @notice Bet a specific number by the number index
    ///         with either ether or balance (or use both, compensate with balance if ether is insufficient).
    ///         A player can bet one number multiple times.
    /// @param gameId game id
    /// @param luckyNumberIndex the index of the number
    function bet(uint64 gameId, uint8 luckyNumberIndex) external payable {
        GameInfo storage gameInfo = gameInfoMap[gameId];
        if (gameInfo.status != Status.Open) {
            revert IncorrectStatus(Status.Open);
        }
        if (block.timestamp > gameInfo.endTimestamp) {
            revert IncorrectTiming();
        }

        if (gameInfo.totalBetCount >= gameInfo.maxPlayerCount) {
            revert ReachPlayerLimit();
        }
        if (luckyNumberIndex >= gameInfo.luckyNumbers.length) {
            revert InvalidIndex();
        }

        uint256 required = gameInfo.betAmount + gameInfo.betFee;
        if (msg.value > required) {
            revert IncorrectAmount();
        }

        uint256 balance = playerBalance[msg.sender];
        if (msg.value + balance < required) {
            revert IncorrectAmount();
        }

        if (required > msg.value) {
            uint256 requiredBalance = required - msg.value;
            playerBalance[msg.sender] -= requiredBalance;
        }
        unchecked {
            gameInfo.totalBetCount += 1;
            BetInfo storage betInfo = gameInfo.betInfoMap[luckyNumberIndex];
            betInfo.players.push(msg.sender);
            betInfo.playersMap[msg.sender] += 1;
            emit NumberBet(gameId, luckyNumberIndex, betInfo.players.length);
        }
    }

    /// @notice Draw the game
    ///         The game can draw properly only if there are enough participants and
    ///         every number has at least one bet.
    function draw(uint64 gameId) external {
        GameInfo storage gameInfo = gameInfoMap[gameId];
        if (gameInfo.status != Status.Open) {
            revert IncorrectStatus(Status.Open);
        }
        if (block.timestamp < gameInfo.endTimestamp) {
            revert IncorrectTiming();
        }
        if (gameInfo.banker != msg.sender) {
            revert NotAuthorized();
        }

        gameInfo.status = Status.Drawing;
        emit StatusChanged(gameId, Status.Open, Status.Drawing);

        uint256 numbersLength = gameInfo.luckyNumbers.length;
        uint32 totalBetCount = gameInfo.totalBetCount;
        bool canDraw = totalBetCount >= gameInfo.minPlayerCount;
        mapping(uint8 => BetInfo) storage betInfoMap = gameInfo.betInfoMap;
        if (canDraw) {
            unchecked {
                for (uint8 i = 0; i < numbersLength; i++) {
                    if (betInfoMap[i].players.length == 0) {
                        canDraw = false;
                        break;
                    }
                }
            }
        }
        if (canDraw) {
            requestVRF(gameId);
        } else {
            gameInfo.winningNumberIndex = uint8(numbersLength);
            gameInfo.status = Status.Settling;
            emit StatusChanged(gameId, Status.Drawing, Status.Settling);
            doSettle(gameId, gameInfo);
        }
    }

    /// @notice After winning number is selected, banker call this function to finish all remaining work
    function settle(uint64 gameId) external {
        GameInfo storage gameInfo = gameInfoMap[gameId];
        if (gameInfo.banker != msg.sender) {
            revert NotAuthorized();
        }
        doSettle(gameId, gameInfo);
    }

    /// @notice In case of can't receive randomWords from VRF service,
    ///         contractOwner should call it manually after fix all VRF related issues
    ///         so that can request random words again.
    function reDraw(uint64 gameId) external {
        if (msg.sender != contractOwner) {
            revert NotAuthorized();
        }
        if (gameInfoMap[gameId].status != Status.Drawing) {
            revert IncorrectStatus(Status.Drawing);
        }
        requestVRF(gameId);
    }

    /// @notice withdraw player's balance (usually for game bankers or contract owner)
    function withdrawBalance() external {
        uint256 balance = playerBalance[msg.sender];
        require(balance > 0);
        playerBalance[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success);
    }

    /// @notice Winners withdraw their winning award from game play
    function withdrawGameAward(uint64 gameId) external {
        GameInfo storage gameInfo = gameInfoMap[gameId];
        if (gameInfo.status != Status.Closed) {
            revert IncorrectStatus(Status.Closed);
        }
        if (gameInfo.withdrawMap[msg.sender]) {
            revert AlreadyWithdrew();
        }
        gameInfo.withdrawMap[msg.sender] = true;

        uint256 luckyNumberLength = gameInfo.luckyNumbers.length;
        uint8 winningNumberIndex = gameInfo.winningNumberIndex;
        uint256 playerBetCount = 0;
        uint256 amount = 0;
        if (winningNumberIndex < luckyNumberLength) {
            playerBetCount = gameInfo.betInfoMap[winningNumberIndex].playersMap[
                    msg.sender
                ];
            unchecked {
                amount = playerBetCount * gameInfo.winnerAward;
            }
        } else {
            // No winning players
            unchecked {
                for (uint8 i = 0; i < luckyNumberLength; i++) {
                    playerBetCount += gameInfo.betInfoMap[i].playersMap[
                        msg.sender
                    ];
                }
                amount = gameInfo.betAmount * playerBetCount;
            }
        }
        if (amount > 0) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success);
        }
    }

    /// @notice Return game ids with certain status in DESC order
    /// @param onlyActive If true, return currently active games only
    /// @param onlyPlayed If true, return games this player bet only
    /// @param maxCount Result will be sorted by game id DESC, capped with maxCount
    function getGames(
        bool onlyActive,
        bool onlyPlayed,
        uint256 maxCount
    ) external view returns (uint64[] memory result) {
        require(maxCount > 0 && maxCount <= 100);
        uint64 maxGameId = gameIdCounter;
        uint64[] memory gameIds = new uint64[](maxCount);
        uint64 currentIndex = 0;

        unchecked {
            for (uint64 i = maxGameId; currentIndex < maxCount && i > 0; i--) {
                GameInfo storage gameInfo = gameInfoMap[i];
                if (onlyActive && (gameInfo.status == Status.Closed)) {
                    continue;
                }
                if (onlyPlayed && !hasPlayed(gameInfo)) {
                    continue;
                }
                gameIds[currentIndex] = i;
                currentIndex += 1;
            }
            if (currentIndex == 0) return result;

            if (currentIndex < maxCount - 1) {
                result = new uint64[](currentIndex);
                for (uint256 i = 0; i < currentIndex; i++) {
                    result[i] = gameIds[i];
                }
                return result;
            } else {
                return gameIds;
            }
        }
    }

    // @notice Check if msg.sender has any bet on this game
    function hasPlayed(GameInfo storage gameInfo)
        private
        view
        returns (bool played)
    {
        unchecked {
            uint256 length = gameInfo.luckyNumbers.length;
            for (uint8 i = 0; i < length; i++) {
                if (gameInfo.betInfoMap[i].playersMap[msg.sender] > 0) {
                    return true;
                }
            }
            return false;
        }
    }

    /// @notice Get all basic game info
    function getBasicGameInfo(uint64 gameId)
        external
        view
        returns (
            Status status,
            uint8[] memory luckyNumbers,
            uint32 endTimestamp,
            uint32 minPlayerCount,
            uint32 maxPlayerCount,
            uint128 betAmount,
            uint128 betFee,
            uint8 winningNumberIndex,
            uint256 winnerAward
        )
    {
        GameInfo storage gameInfo = gameInfoMap[gameId];
        status = gameInfo.status;
        luckyNumbers = gameInfo.luckyNumbers;
        endTimestamp = gameInfo.endTimestamp;
        minPlayerCount = gameInfo.minPlayerCount;
        maxPlayerCount = gameInfo.maxPlayerCount;
        betAmount = gameInfo.betAmount;
        betFee = gameInfo.betFee;
        winningNumberIndex = gameInfo.winningNumberIndex;
        winnerAward = gameInfo.winnerAward;
    }

    /// @notice Return all game ids a banker has started
    function getBankerGames() external view returns (uint64[] memory) {
        return bankerGameIdMap[msg.sender];
    }

    /// @notice Check if a player already bet the specific number for current game round
    function getNumberBetCount(uint64 gameId, uint8 luckyNumberIndex)
        external
        view
        returns (uint256)
    {
        return
            gameInfoMap[gameId].betInfoMap[luckyNumberIndex].playersMap[
                msg.sender
            ];
    }

    /// @notice Get total bet player count for a specific number
    function getNumberBettersCount(uint64 gameId, uint8 luckyNumberIndex)
        external
        view
        returns (uint256)
    {
        return gameInfoMap[gameId].betInfoMap[luckyNumberIndex].players.length;
    }

    /// @notice Start to request a random number (Chanlink VRF service) to decide the winning number
    function requestVRF(uint64 gameId) internal {
        uint256 requestId = vrfParams.vrfCoordinator.requestRandomWords(
            vrfParams.keyHash,
            vrfParams.subscriptionId,
            vrfParams.requestConfirmations,
            vrfParams.callbackGasLimit,
            1
        );
        vrfRequestGameIdMap[requestId] = gameId;
    }

    /// @dev Callback function of Chainlink VRF service.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint64 gameId = vrfRequestGameIdMap[requestId];
        if (gameId == 0) {
            // Invalid request id, ignore
            return;
        }
        GameInfo storage gameInfo = gameInfoMap[gameId];
        if (gameInfo.status != Status.Drawing) {
            // Already handled, ignore
            return;
        }

        gameInfo.status = Status.Settling;
        emit StatusChanged(gameId, Status.Drawing, Status.Settling);
        gameInfo.winningNumberIndex = uint8(
            randomWords[0] % gameInfo.luckyNumbers.length
        );
        delete vrfRequestGameIdMap[requestId];
    }

    // @dev Final setup after winning number is selected
    function doSettle(uint64 gameId, GameInfo storage gameInfo) private {
        if (gameInfo.status != Status.Settling) {
            revert IncorrectStatus(Status.Settling);
        }
        gameInfo.status = Status.Closed;
        emit StatusChanged(gameId, Status.Settling, Status.Closed);
        uint8 winningNumberIndex = gameInfo.winningNumberIndex;
        uint256 winnerAward;
        if (winningNumberIndex < gameInfo.luckyNumbers.length) {
            unchecked {
                winnerAward =
                    (gameInfo.betAmount * gameInfo.totalBetCount) /
                    gameInfo.betInfoMap[winningNumberIndex].players.length;
            }
        }
        gameInfo.winnerAward = winnerAward;
        emit NumberWon(gameId, winningNumberIndex, winnerAward);
        unchecked {
            playerBalance[gameInfo.banker] +=
                gameInfo.totalBetCount *
                gameInfo.betFee;
        }
    }

    /// @dev Use function instead of modifier in order to reduce contract code size
    function onlyAllowOwner() internal view {
        if (msg.sender != contractOwner) {
            revert NotAuthorized();
        }
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