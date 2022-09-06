// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import 'hardhat/console.sol';
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Betwei is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  uint64 immutable s_subscriptionId;

  // Rinkeby address and keyhash Chainlink VRF
  address immutable vrfCoordinator; // = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  bytes32 immutable keyHash; // = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  uint32 callbackGasLimit = 150000;

  uint16 requestConfirmations = 3;

  uint32 numWords =  1;

  //uint256[] public s_randomWords;
  //uint256 public s_requestId;

  address s_owner;

  enum GameType {
    RANDOMWINNER
  }

  enum GameStatus {
    OPEN,
    CLOSED,
    CALCULATING,
    FINISHED
  }

  struct Game {
    GameType gameType;
    GameStatus status;
    address owner;
    string description;
    // TODO only registered by owner in private games?
    address payable[] members;
    mapping(address => bool) winners;
    address[] winnersIndexed; // TODO: to evaluate
    mapping(address => uint256) playersBalance;
    uint256 balance;
    uint256 gameId;
    uint256 duration;
    uint256 solution;
    uint256 neededAmount;
    // TODO block number create game?
  }

  mapping(address => uint256[]) games;
  mapping(uint256 => uint256) requests;

  Game[] indexedGames;

  /**
   * Events
   */
  event NewGameCreated(uint256 indexed gameId);
  event EnrolledToGame(uint256 indexed gameId, address indexed player);
  event FinishGame(uint256 indexed gameId, address[] indexed winner); // TODO multiples winners?
  event WithdrawFromGame(uint256 indexed gameId, address indexed winner);


  constructor(
    uint64 _subscriptionId,
    bytes32 _keyHash,
    address _vrfCoordinatorAddress
  )
    VRFConsumerBaseV2(_vrfCoordinatorAddress)
  {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
    s_owner = msg.sender;
    vrfCoordinator = _vrfCoordinatorAddress;
    keyHash = _keyHash;
    s_subscriptionId = _subscriptionId;
  }

  /**
   * Manage game
   */

  /**
   * Create new game
   * duration param -> max players
   * return gameId
   * TODO: amount parameter
   */
  function createNewGame(GameType _type, uint16 _duration, string memory _description) public payable hasAmount returns(uint256) {
    uint256 newIndex = indexedGames.length; 
    emit NewGameCreated(newIndex);
    Game storage newGame = indexedGames.push();
    newGame.owner = msg.sender;
    newGame.duration = _duration;
    newGame.gameType = _type;
    newGame.status = GameStatus.OPEN;
    newGame.neededAmount = msg.value;
    newGame.playersBalance[msg.sender] += msg.value;
    newGame.members.push(payable(address(msg.sender)));
    newGame.gameId = newIndex;
    newGame.balance += msg.value;
    newGame.description = _description;
    games[msg.sender].push(newIndex);
    return newIndex;
  }

  function enrollToGame(uint256 gameId) external payable canEnroll(gameId) hasAmount gameExists(gameId) returns(bool) {
    emit EnrolledToGame(gameId, msg.sender);
    Game storage game = indexedGames[gameId];
    game.members.push(payable(address(msg.sender)));
    games[msg.sender].push(gameId);
    if (game.duration <= game.members.length) {
      game.status = GameStatus.CLOSED;
    }
    game.playersBalance[msg.sender] += msg.value;
    game.balance += msg.value;

    return true;
  }

  function usersEnrolled(uint256 gameId) external view gameExists(gameId) returns(uint256) {
    Game storage game = indexedGames[gameId];
    return game.members.length;
  }

  function closeGame(uint256 gameId) external gameExists(gameId) canManageGame(gameId) returns(bool) {
    Game storage game = indexedGames[gameId];
    if(
      game.status != GameStatus.OPEN &&
      game.status != GameStatus.CLOSED
    ) {
      revert();
    }
    game.status = GameStatus.CLOSED;

    return true;
  }

  function startGame(uint256 gameId) external gameExists(gameId) canManageGame(gameId) {
    Game storage game = indexedGames[gameId];
    require(game.status == GameStatus.CLOSED, 'The game not is closed');
    game.status = GameStatus.CALCULATING;

    // TODO multiple winner
    _calculatingWinner(gameId);

  }

  function _calculatingWinner(uint _gameId) internal  {
    Game storage game = indexedGames[_gameId];
    require(game.status == GameStatus.CALCULATING, "You aren't at that stage yet!");

    // TODO migrato to governance smartcontract
    uint256 requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

    requests[requestId] = game.gameId;

  }


  /**
   * Chainlink VRF functions
   */


  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    _selectWinner(requestId, randomWords);
  }

  function _selectWinner(uint256 requestId, uint256[] memory randomWords) public {
    uint256 gameIndex = requests[requestId];
    Game storage game = indexedGames[gameIndex];
    require(game.status == GameStatus.CALCULATING, "Game not exists");
    game.status = GameStatus.FINISHED;
    game.solution = randomWords[0];
    uint256 winnerIndex = game.solution % game.members.length;
    address winnerAddress = game.members[winnerIndex];
    // only 1 winner
    game.winnersIndexed.push(winnerAddress);
    game.winners[winnerAddress] = true;
    emit FinishGame(game.gameId, game.winnersIndexed);
  }

  /**
   * Withdraw function
   */
  function withdrawGame(uint256 _gameId) external gameExists(_gameId) returns(bool) {
    Game storage game = indexedGames[_gameId];
    require(game.status == GameStatus.FINISHED, "Game no finished");
    require(game.playersBalance[msg.sender] > 0, 'Player balance 0');
    require(game.winners[msg.sender], 'Player not winner');
    require(game.balance > 0, "Game finished, balance 0");
    emit WithdrawFromGame(game.gameId, msg.sender);
    uint256 balanceGame = game.balance;
    game.balance = 0;

    // transfer all game balance
    (bool success,) = payable(msg.sender).call{value: balanceGame}("");
    require(success, "Transfer amount fail");

    return true;
  }

  /**
   * Read functions
   */

  function gameStatus(uint _gameId) public view returns(uint256) {
    return uint256(indexedGames[_gameId].status);
  }

  function winners(uint _gameId) public view returns(address[] memory) {
    return indexedGames[_gameId].winnersIndexed;
  }

  function gameBalance(uint _gameId) public view returns(uint256) {
    Game storage game = indexedGames[_gameId];
    require(game.playersBalance[msg.sender] > 0, 'Address not is member in the game');
    return game.balance;
  }

  function playerGames(address _player) external view returns(uint256[] memory) {
    return games[_player];
  }

  function viewGame(uint256 _gameId)
    external
    view
    returns(
      uint256 balance,
      uint256 duration,
      uint256 neededAmount,
      GameType gameType,
      GameStatus status,
      string memory description,
      address payable[] memory members,
      address owner
  ) {
    Game storage game = indexedGames[_gameId];
    balance = game.balance; 
    duration = game.duration;
    neededAmount = game.neededAmount;
    owner = game.owner;
    status = game.status;
    gameType = game.gameType;
    members = game.members;
    description = game.description;
  }

  function getBalance() public view onlyOwner returns(uint256) {
    return address(this).balance;
  }


  /**
   * Start - Modifiers
   */
  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  modifier gameExists(uint256 _gameId) {
    require(indexedGames[_gameId].gameId >= 0, 'Game not exists');
    _;
  }

  modifier canEnroll(uint256 _gameId) {
    Game storage game = indexedGames[_gameId];
    require(game.playersBalance[msg.sender] <= 0, "User cannot enroll");
    require(game.neededAmount >= msg.value, "The amount required should be greather or equal");
    require(game.duration > game.members.length, "User cannot enroll");
    require(game.status == GameStatus.OPEN, "User cannot enroll");
    _;
  }

  modifier canManageGame(uint _gameId) {
    Game storage game = indexedGames[_gameId];
    require(game.owner == msg.sender, "Can't start game");
    _;
  }

  modifier hasAmount() {
    require(msg.value > 0, "Amount has greather than 0 ");
    _;
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