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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RandomizationErrors.sol";

/// @title Randomization library
/// @dev Lightweight library used for basic randomization capabilities for ERC-721 tokens when an Oracle is not available
library Randomization {

	/// Returns a value based on the spread of a random uint8 seed and provided percentages
	/// @dev The last percentage is assumed if the sum of all elements do not add up to 100, in which case the length of the array is returned
	/// @param random A uint8 random value
	/// @param percentages An array of percentages
	/// @return The index in which the random seed falls, which can be the length of the input array if the values do not add up to 100
	function randomIndex(uint8 random, uint8[] memory percentages) internal pure returns (uint256) {
		uint256 spread = (3921 * uint256(random) / 10000) % 100; // 0-255 needs to be balanced to evenly spread with % 100
		uint256 remainingPercent = 100;
		for (uint256 i = 0; i < percentages.length; i++) {
			uint256 nextPercentage = percentages[i];
			if (remainingPercent < nextPercentage) revert PercentagesGreaterThan100();
			remainingPercent -= nextPercentage;
			if (spread >= remainingPercent) {
				return i;
			}
		}
		return percentages.length;
	}

	/// Returns a random seed suitable for ERC-721 attribute generation when an Oracle such as Chainlink VRF is not available to a contract
	/// @dev Not suitable for mission-critical code. Always be sure to perform an analysis of your randomization before deploying to production
	/// @param initialSeed A uint256 that seeds the randomization function
	/// @return A seed that can be used for attribute generation, which may also be used as the `initialSeed` for a future call
	function randomSeed(uint256 initialSeed) internal view returns (uint256) {
		// Unit tests should confirm that this provides a more-or-less even spread of randomness
		return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, initialSeed >> 1)));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the percentages array sum up to more than 100
error PercentagesGreaterThan100();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../utils/GameUtils.sol";

/// @title Provides support for the TicTacDao game
interface IGameLogicProvider is IERC165 {

	/// @dev When the game tokenId does not exist
	error NonexistentGame();

	/// @dev When total game quantity has been reached (see you on secondary markets)
	error SoldOut();

	/// Creates the specified number of newly initialized games
	/// @dev May throw SoldOut if the quantity results in too many games
	/// @param quantity The number of games to create
	/// @return startingGameId The starting gameId of the set
	function createGames(uint256 quantity) external returns (uint256 startingGameId);

	/// Processes the player's move and updates the state
	/// @dev May throw NonexistentGame, or InvalidMove if the position is invalid given the state
	/// @param gameId The token id of the game
	/// @param position The position of the player's next move
	/// @return resultingState The resulting state of the game
	function processMove(uint256 gameId, uint256 position) external returns (ITicTacToe.GameState resultingState);

	/// Restarts a game
	/// @param gameId The token id of the game to restart
	function restartGame(uint256 gameId) external;

	/// Returns the `ITicTacToe.Game` info for the specified `tokenId`
	/// @param gameId The token id of the game
	function ticTacToeGame(uint256 gameId) external view returns (ITicTacToe.Game memory);

	/// Returns the total number of games currently stored by the contract
	function totalGames() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITicTacToe interface
interface ITicTacToe {

	/// Represents the state of a Game
	enum GameState {
		InPlay, OwnerWon, ContractWon, Tie
	}

	/// Contains aggregated information about game results
	struct GameHistory {
		uint32 wins;
		uint32 losses;
		uint32 ties;
		uint32 restarts;
	}

	/// Contains information about a TicTacToe game
	struct Game {
		uint8[] moves;
		GameState state;
		GameHistory history;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GameConnector
abstract contract GameConnector is Ownable, IERC165 {

	/// @dev Wen the caller is not allowed
	error CallerNotAllowed();

	/// @dev The address to the game;
	mapping(address => bool) private _allowedCallers;

	/// Assigns the address to the mapping of allowed callers
	/// @dev If assigning allowed to address(0), anyone may call the `onlyAllowedCallers` functions
	/// @param caller The address of the caller with which to assign allowed
	/// @param allowed Whether the `caller` will be allowed to call `onlyAllowedCallers` functions
	function assignAllowedCaller(address caller, bool allowed) external onlyOwner {
		if (allowed) {
			_allowedCallers[caller] = allowed;
		} else {
			delete _allowedCallers[caller];
		}
	}

	/// Prevents a function from executing if not called by an allowed caller
	modifier onlyAllowedCallers() {
		if (!_allowedCallers[_msgSender()] && !_allowedCallers[address(0)]) revert CallerNotAllowed();
		_;
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}

	/// @inheritdoc Ownable
	function transferOwnership(address newOwner) public virtual override {
		if (newOwner != owner()) {
			delete _allowedCallers[owner()];
		}
		super.transferOwnership(newOwner);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@theappstudio/solidity/contracts/utils/Randomization.sol";
import "../interfaces/IGameLogicProvider.sol";
import "./GameConnector.sol";

/// @title GameLogicV1
contract GameLogicV1 is GameConnector, VRFConsumerBaseV2, IGameLogicProvider {

	/// @dev Event emitted when a random number request happens to fail (probably misconfiguration)
	event RandomRequestFailed(uint64 indexed subscriptionId);

	/// @dev Event emitted when the VRF subscription is updated
	event VRFSubscriptionUpdated(uint64 indexed subscriptionId, bytes32 keyHash, uint32 callbackGasLimit);

	/// @dev Maximum games that will exist on the blockchain
	uint256 public constant MAX_GAMES = 999;

	/// @dev Seed for randomness
	uint256 private _seed;

	/// @dev Array of GameIds to GameInfo structs
	GameUtils.GameInfo[] private _gameIdsToGameInfo;

	/// @dev The interface to the VRFCoordinator so that requests can be made
	VRFCoordinatorV2Interface private immutable _coordinator;

	/// @dev Stores outstanding VRF requests
	mapping(uint256 => bool) private _outstandingRequests;

	/// @dev The gaslimit needed to fulfill the Chainlink VRF callback
	uint32 private _callbackGasLimit;

	/// @dev The number of confirmations before VRF requests are fulfilled (default minimum is 3)
	uint16 private _requestConfirmations;

	/// @dev The keyHash of the "gas lane" used by Chainlink
	bytes32 private _keyHash;

	/// @dev The configured VRF subscription id
	uint64 private _subscriptionId;

	/// @dev Can devs do something?
	constructor(uint256 seed, address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
		_seed = seed;
		_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
	}

	/// Configures a chainlink VRF2 subscription for random number generation
	/// @dev Only the contract owner may call this
	/// @param keyHash The keyHash of the "gas lane" used by Chainlink
	/// @param subscriptionId The subscription id
	/// @param requestConfirmations The number of confirmations before requests are fulfilled (default minimum is 3)
	/// @param callbackGasLimit The gaslimit needed to fulfill the callback
	function configureVrfSubscription(bytes32 keyHash, uint64 subscriptionId, uint16 requestConfirmations, uint32 callbackGasLimit) external onlyOwner {
		_keyHash = keyHash;
		_subscriptionId = subscriptionId;
		_requestConfirmations = requestConfirmations;
		_callbackGasLimit = callbackGasLimit;
		emit VRFSubscriptionUpdated(subscriptionId, keyHash, callbackGasLimit);
	}

	/// @inheritdoc IGameLogicProvider
	function createGames(uint256 quantity) external onlyAllowedCallers returns (uint256 startingGameId) {
		startingGameId = _gameIdsToGameInfo.length;
		if (startingGameId + quantity > MAX_GAMES) revert SoldOut();
		ITicTacToe.GameHistory memory history = ITicTacToe.GameHistory(0, 0, 0, 0);
		uint256 seed = Randomization.randomSeed(_seed);
		for (uint i = 0; i < quantity; i++) {
			_gameIdsToGameInfo.push(GameUtils.initializeGame(history, seed >> i, 0));
		}
		_seed = seed;
	}

	/// @inheritdoc VRFConsumerBaseV2
	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		if (!_outstandingRequests[requestId]) return;
		delete _outstandingRequests[requestId];
		if (randomWords.length == 0 || randomWords[0] == 0) return;
		_seed = randomWords[0];
	}

	/// Provides the internal GameUtils.GameInfo memory struct to an allowed caller
	function gameInfoStruct(uint256 gameId) external view onlyAllowedCallers onlyWhenExists(gameId) returns (GameUtils.GameInfo memory) {
		return _gameIdsToGameInfo[gameId];
	}

	/// Ensures the function only continues if the token exists
	modifier onlyWhenExists(uint256 gameId) {
		if (gameId >= _gameIdsToGameInfo.length) revert NonexistentGame();
		_;
	}

	/// @inheritdoc IGameLogicProvider
	function processMove(uint256 gameId, uint256 position) external onlyAllowedCallers onlyWhenExists(gameId) returns (ITicTacToe.GameState resultingState) {
		uint256 seed = Randomization.randomSeed(_seed);
		GameUtils.GameInfo memory gameInfo = GameUtils.processMove(_gameIdsToGameInfo[gameId], position, seed);
		_gameIdsToGameInfo[gameId] = gameInfo;
		_seed = seed;
		resultingState = gameInfo.state;
		if (resultingState == ITicTacToe.GameState.OwnerWon && _subscriptionId != 0 && gameInfo.history.wins % 5 == 0) {
			// If configured, we should occasionally re-seed randomness when somebody wins
			try _coordinator.requestRandomWords(_keyHash, _subscriptionId, _requestConfirmations, _callbackGasLimit, 1) returns (uint256 requestId) {
				_outstandingRequests[requestId] = true;
			} catch {
				emit RandomRequestFailed(_subscriptionId);
			}
		}
	}

	/// @inheritdoc IGameLogicProvider
	function restartGame(uint256 gameId) external onlyAllowedCallers onlyWhenExists(gameId) {
		GameUtils.GameInfo memory gameInfo = _gameIdsToGameInfo[gameId];
		if (gameInfo.state == ITicTacToe.GameState.InPlay) {
			gameInfo.history.restarts += 1;
		}
		uint256 seed = Randomization.randomSeed(_seed);
		_gameIdsToGameInfo[gameId] = GameUtils.initializeGame(gameInfo.history, seed, block.number);
		_seed = seed;
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public pure override(GameConnector, IERC165) returns (bool) {
		return interfaceId == type(IGameLogicProvider).interfaceId || super.supportsInterface(interfaceId);
	}

	/// @inheritdoc IGameLogicProvider
	function ticTacToeGame(uint256 gameId) external view onlyAllowedCallers onlyWhenExists(gameId) returns (ITicTacToe.Game memory) {
		return GameUtils.gameFromGameInfo(_gameIdsToGameInfo[gameId]);
	}

	/// @inheritdoc IGameLogicProvider
	function totalGames() external view returns (uint256) {
		return _gameIdsToGameInfo.length;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ITicTacToe.sol";
// import "hardhat/console.sol";

/// @title GameUtils
library GameUtils {

	/// @dev When the player attempts a change that is not valid for the current GameState
	error InvalidGameState();

	/// @dev When the player attempts to make an invalid move
	error InvalidMove();

	/// @dev When a player attempts to make multiple moves within the same block for the same game
	error NoMagic();

	/// Represents one of the game players
	enum GamePlayer {
		Contract, Owner
	}

	/// Represents the storage of a game, suitable for the contract to make choices
	struct GameInfo {
		ITicTacToe.GameState state;
		uint8 moves;
		uint8[9] board;
		uint40 blockNumber; // The block number of the last move. To save gas, not updated on a win/lose/tie
		ITicTacToe.GameHistory history;
	}

	/// @dev Constant for reporting an invalid index
	uint256 internal constant INVALID_MOVE_INDEX = 0xFF;

	/// Returns whether the bits under test match the bits being tested for
	/// @param bits The bits to test
	/// @param matchBits The bits being tested for
	/// @return Whether the bits under test match the bits being tested for
	function bitsMatch(uint256 bits, uint256 matchBits) internal pure returns (bool) {
		return (bits & matchBits) == matchBits;
	}

	/// Returns an ITicTacToe.Game from the supplied GameInfo
	/// @param gameInfo The GameInfo structure to convert
	/// @return game The converted Game structure
	function gameFromGameInfo(GameInfo memory gameInfo) internal pure returns (ITicTacToe.Game memory game) {
		game.state = gameInfo.state;
		game.history = gameInfo.history;
		game.moves = new uint8[](gameInfo.moves);
		for (uint256 move = 0; move < gameInfo.moves; move++) {
			game.moves[move] = gameInfo.board[move];
		}
	}

	/// Returns an GameInfo from the supplied ITicTacToe.Game
	/// @param game The ITicTacToe.Game structure to convert
	/// @return gameInfo The converted GameInfo structure
	function gameInfoFromGame(ITicTacToe.Game memory game) internal pure returns (GameInfo memory gameInfo) {
		gameInfo.state = game.state;
		gameInfo.history = game.history;
		gameInfo.moves = uint8(game.moves.length);
		for (uint256 move = 0; move < game.moves.length; move++) {
			gameInfo.board[move] = game.moves[move];
		}
	}

	/// Returns the index of the desired position in the GameInfo's board array
	/// @param gameInfo The GameInfo to examine
	/// @param position The position to search
	/// @return The index within the board array of the result, or `INVALID_MOVE_INDEX` if not found
	function indexOfPosition(GameInfo memory gameInfo, uint256 position) internal pure returns (uint256) {
		for (uint256 index = gameInfo.moves; index < gameInfo.board.length; index++) {
			if (position == gameInfo.board[index]) {
				return index;
			}
		}
		return INVALID_MOVE_INDEX;
	}

	/// Returns a new initialized GameUtils.GameInfo struct using the existing GameHistory
	/// @param history The history of games to attach to the new instance
	/// @param seed An initial seed for the contract's first move
	/// @param blockNumber A optional value to use as the initial block number, which will be collapsed to uint40
	/// @return A new intitialzed GameUtils.GameInfo struct
	function initializeGame(ITicTacToe.GameHistory memory history, uint256 seed, uint256 blockNumber) internal pure returns (GameUtils.GameInfo memory) {
		uint8 firstMove = uint8(seed % 9);
		uint8[9] memory board;
		board[0] = firstMove;
		for (uint256 i = 1; i < 9; i++) {
			board[i] = i <= firstMove ? uint8(i-1) : uint8(i);
		}
		return GameUtils.GameInfo(ITicTacToe.GameState.InPlay, 1, board, uint40(blockNumber), history);
	}

	/// Returns the bits representing the player's moves
	/// @param gameInfo The GameInfo structure
	/// @param gamePlayer The GamePlayer for which to generate the map
	/// @return map A single integer value representing a bitmap of the player's moves
	function mapForPlayer(GameInfo memory gameInfo, GamePlayer gamePlayer) internal pure returns (uint256 map) {
		// These are the bits for each board position
		uint16[9] memory positionsToBits = [256, 128, 64, 32, 16, 8, 4, 2, 1];
		for (uint256 index = uint256(gamePlayer); index < gameInfo.moves; index += 2) {
			uint256 position = gameInfo.board[index];
			map += positionsToBits[position];
		}
	}

	/// Updates the GameInfo structure based on the positionIndex being moved
	/// @param gameInfo The GameInfo structure
	/// @param positionIndex The index within the board array representing the desired move
	function performMove(GameInfo memory gameInfo, uint256 positionIndex) internal pure {
		uint8 movePosition = gameInfo.moves & 0x0F;
		uint8 nextPosition = gameInfo.board[positionIndex];
		gameInfo.board[positionIndex] = gameInfo.board[movePosition];
		gameInfo.board[movePosition] = nextPosition;
		gameInfo.moves += 1;
	}

	/// Returns whether the player has won based on its playerMap
	/// @param playerMap The bitmap of the player's moves
	/// @return Whether the bitmap represents a winning game
	function playerHasWon(uint256 playerMap) internal pure returns (bool) {
		// These are winning boards when bits are combined
		uint16[8] memory winningBits = [448, 292, 273, 146, 84, 73, 56, 7];
		for (uint256 index = 0; index < winningBits.length; index++) {
			if (bitsMatch(playerMap, winningBits[index])) {
				return true;
			}
		}
		return false;
	}

	/// Processes a move on an incoming GameInfo structure and returns a resulting GameInfo structure
	/// @param gameInfo The incoming GameInfo structure
	/// @param position The player's attempted move
	/// @param seed A seed used for randomness
	/// @return A resulting GameInfo structure that may also include the contract's move if the game continues
	function processMove(GameUtils.GameInfo memory gameInfo, uint256 position, uint256 seed) internal view returns (GameUtils.GameInfo memory) {
		if (gameInfo.state != ITicTacToe.GameState.InPlay) revert InvalidGameState();
		// console.log("block number %d vs %d", gameInfo.blockNumber, block.number);
		if (gameInfo.blockNumber >= block.number) revert NoMagic();
		uint256 positionIndex = indexOfPosition(gameInfo, position);
		if (positionIndex == INVALID_MOVE_INDEX) revert InvalidMove();
		// console.log("Playing position:", position); //, positionIndex, gameInfo.moves);
		performMove(gameInfo, positionIndex);

		if (gameInfo.moves < 4) { // No chance of winning just yet
			uint256 openSlot = uint8(seed % (9 - gameInfo.moves));
			// console.log(" - random move:", gameInfo.board[openSlot + gameInfo.moves]);
			performMove(gameInfo, openSlot + gameInfo.moves);
			gameInfo.blockNumber = uint40(block.number);
		} else /* if (gameInfo.moves < 9) */ { // Owner or Contract may win
			uint256 ownerMap = mapForPlayer(gameInfo, GamePlayer.Owner);
			if (playerHasWon(ownerMap)) {
				gameInfo.state = ITicTacToe.GameState.OwnerWon;
				gameInfo.history.wins += 1;
			} else {
				bool needsMove = true;
				uint256 contractMap = mapForPlayer(gameInfo, GamePlayer.Contract);
				// If the Contract has an imminent win, take it.
				for (uint256 openSlot = gameInfo.moves; openSlot < 9; openSlot++) {
					if (winableMove(contractMap, gameInfo.board[openSlot])) {
						// console.log(" - seizing move:", gameInfo.board[openSlot]); //, gameInfo.moves);
						performMove(gameInfo, openSlot);
						needsMove = false;
						break;
					}
				}
				if (needsMove) {
					// If the Owner has an imminent win, block it.
					for (uint256 openSlot = gameInfo.moves; openSlot < 9; openSlot++) {
						if (winableMove(ownerMap, gameInfo.board[openSlot])) {
							// console.log(" - blocking move:", gameInfo.board[openSlot]); //, gameInfo.moves);
							performMove(gameInfo, openSlot);
							needsMove = false;
							break;
						}
					}
				}
				if (needsMove) {
					uint256 openSlot = uint8(seed % (9 - gameInfo.moves));
					// console.log(" - random move:", gameInfo.board[openSlot + gameInfo.moves]);
					performMove(gameInfo, openSlot + gameInfo.moves);
				}
				if (playerHasWon(mapForPlayer(gameInfo, GamePlayer.Contract))) {
					gameInfo.state = ITicTacToe.GameState.ContractWon;
					gameInfo.history.losses += 1;
				} else if (gameInfo.moves > 8) {
					gameInfo.state = ITicTacToe.GameState.Tie;
					gameInfo.history.ties += 1;
				} else {
					gameInfo.blockNumber = uint40(block.number);
				}
			}
		}
		return gameInfo;
	}

	/// Returns whether the next position would result in a winning board if applied
	/// @param playerMap The bitmap representing the player's current moves
	/// @param nextPosition The next move being considered
	/// @return Whether the next position would result in a winning board
	function winableMove(uint256 playerMap, uint256 nextPosition) internal pure returns (bool) {
		if (nextPosition == 0) {
			return bitsMatch(playerMap, 192) || bitsMatch(playerMap, 36) || bitsMatch(playerMap, 17);
		} else if (nextPosition == 1) {
			return bitsMatch(playerMap, 320) || bitsMatch(playerMap, 18);
		} else if (nextPosition == 2) {
			return bitsMatch(playerMap, 384) || bitsMatch(playerMap, 20) || bitsMatch(playerMap, 9);
		} else if (nextPosition == 3) {
			return bitsMatch(playerMap, 260) || bitsMatch(playerMap, 24);
		} else if (nextPosition == 4) {
			return bitsMatch(playerMap, 257) || bitsMatch(playerMap, 130) || bitsMatch(playerMap, 68) || bitsMatch(playerMap, 40);
		} else if (nextPosition == 5) {
			return bitsMatch(playerMap, 65) || bitsMatch(playerMap, 48);
		} else if (nextPosition == 6) {
			return bitsMatch(playerMap, 288) || bitsMatch(playerMap, 80) || bitsMatch(playerMap, 3);
		} else if (nextPosition == 7) {
			return bitsMatch(playerMap, 144) || bitsMatch(playerMap, 5);
		} else /* if (nextPosition == 8) */ {
			return bitsMatch(playerMap, 272) || bitsMatch(playerMap, 72) || bitsMatch(playerMap, 6);
		}
	}
}