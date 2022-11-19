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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/* Errors */
error Roulette__PleaseSendMoreMoney();
error Roulette__ExceedsMaximumBet();
error Roulette__NotEnoughMoneyToStart();
error Roulette__UpkeepNotNeeded(uint256 currentBalance, uint256 numberOfBets);
error Roulette__TransactionFailed();
error Roulette__IsContract();
error Roulette__NotAnOwner();
error Roulette__CasinoIsEmpty();
error Roulette__EmptyBalance();
error Roulette__PleaseWaitForLiquidity();
error Roulette__NotPossibleNumbersArrayLength();
error Roulette__NotPossibleBet();

/**@title Roulette contract
 * @author Vyacheslav Pyzhov
 * @dev This implements the Chainlink VRF Version 2
 */

contract Roulette is VRFConsumerBaseV2, ReentrancyGuard, AutomationCompatibleInterface {
	constructor(
		address _vrfCoordinatorV2,
		uint64 _subscriptionId,
		bytes32 _gasLane,
		uint256 _interval,
		uint256 _startGameValue,
		uint256 _minimalBet,
		uint256 _maximumBet
	) payable VRFConsumerBaseV2(_vrfCoordinatorV2) {
		owner = msg.sender;
		startGameValue = _startGameValue;
		minimalBet = _minimalBet;
		maximumBet = _maximumBet;

		vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
		subscriptionId = _subscriptionId;
		gasLane = _gasLane;
		interval = _interval;
		lastTimeStamp = block.timestamp;
	}

	/* Type declarations */
	struct Bet {
		address player;
		uint256 amount;
		uint8 betType; // 0: oneNumber, 1: twoNumbers, 2: threeNumbers, 3: fourNumbers, 4: sixNumbers, 5: column, 6: dozen 7: eighteen, 8: modulus, 9: color:
		uint8[] numbers;
	}

	/* State variables */
	//Owner
	address public immutable owner;

	// Chainlink VRF Variables
	VRFCoordinatorV2Interface private immutable vrfCoordinator;
	uint64 private immutable subscriptionId;
	bytes32 public immutable gasLane;

	uint32 public constant CALLBACK_GAS_LIMIT = 500000;
	uint16 public constant REQUEST_CONFIRMATIONS = 3;
	uint32 public constant NUM_WORDS = 1;

	// Roulette State Variables
	uint256 public immutable interval;
	uint256 public lastTimeStamp;
	uint256 public immutable startGameValue;
	uint256 public immutable minimalBet;
	uint256 public immutable maximumBet;
	uint256 public moneyInTheBank;
	uint256 public currentCasinoBalance;
	uint256 public lastWinningNumber;
	mapping(address => uint256) public playersBalances;
	uint256 public allPlayersWinnings;
	// Array of Bets
	Bet[] public betsArr;

	/* Events */
	event BetCreated(Bet indexed bet, uint256 indexed time);
	event RequestedNumber(uint256 indexed requestId);
	event GameStarted(uint256 indexed time);
	event GameFinished(uint256 indexed winningNumber, uint256 indexed time);
	event ReceivedDirectValue(address indexed msgSender, uint256 indexed msgValue);

	/* Modifiers */
	modifier onlyOwner() {
		if (msg.sender != owner) {
			revert Roulette__NotAnOwner();
		}
		_;
	}

	/* Functions */

	// Creates a bet for a player
	function createBet(uint8 _betType, uint8[] calldata _numbers) public payable {
		if (msg.value < minimalBet) {
			revert Roulette__PleaseSendMoreMoney();
		}
		if (msg.value > maximumBet) {
			revert Roulette__ExceedsMaximumBet();
		}
		if (!possibleNumbersLength(_betType, _numbers.length)) {
			revert Roulette__NotPossibleNumbersArrayLength();
		}
		if (!possibleBet(_betType, _numbers)) {
			revert Roulette__NotPossibleBet();
		}
		Bet memory newBet = Bet({
			player: msg.sender,
			amount: msg.value,
			betType: _betType,
			numbers: _numbers
		});

		betsArr.push(newBet);

		moneyInTheBank += msg.value;

		emit BetCreated(newBet, block.timestamp);
	}

	// Checks for minimal amount and bets existing
	function checkUpkeep(
		bytes memory /* checkData */
	) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
		bool hasPlayers = betsArr.length > 0;
		bool hasStartGameValue = moneyInTheBank >= startGameValue;
		bool timePassed = ((block.timestamp - lastTimeStamp) > interval);

		upkeepNeeded = (timePassed && hasPlayers && hasStartGameValue);
		return (upkeepNeeded, "0x0");
	}

	// If everything's good, starts the game - request random number from Oracle
	function performUpkeep(bytes calldata /* performData */) external override {
		(bool upkeepNeeded, ) = checkUpkeep("");

		if (!upkeepNeeded) {
			revert Roulette__UpkeepNotNeeded(moneyInTheBank, betsArr.length);
		}

		uint256 requestId = vrfCoordinator.requestRandomWords(
			gasLane,
			subscriptionId,
			REQUEST_CONFIRMATIONS,
			CALLBACK_GAS_LIMIT,
			NUM_WORDS
		);
		emit RequestedNumber(requestId);
		emit GameStarted(block.timestamp);
	}

	// Oracle invokes this function
	function fulfillRandomWords(
		uint256 /*_requestId*/,
		uint256[] memory _randomWords
	) internal override {
		uint256 _rouletteWinNum = (_randomWords[0] % (37));
		lastWinningNumber = _rouletteWinNum;
		Bet[] memory _betsArr = betsArr;

		uint256 tempAmount;

		for (uint256 i; i < _betsArr.length; i += 1) {
			if (checkWinBet(_betsArr[i].betType, _betsArr[i].numbers, _rouletteWinNum)) {
				uint256 _winAmount = calcWin(_betsArr[i].betType, _betsArr[i].amount);
				playersBalances[_betsArr[i].player] += _winAmount;
				allPlayersWinnings += _winAmount;
			} else {
				tempAmount += _betsArr[i].amount;
			}
		}
		currentCasinoBalance += tempAmount;

		moneyInTheBank = 0;

		clearBetsArray(betsArr.length);
		lastTimeStamp = block.timestamp;
		emit GameFinished(_rouletteWinNum, block.timestamp);
	}

	// Withdrawal for players
	function withdrawPlayer() external nonReentrant {
		if (msg.sender.code.length > 0) {
			revert Roulette__IsContract();
		}
		if (playersBalances[address(msg.sender)] < 1) {
			revert Roulette__EmptyBalance();
		}

		uint256 _availableAmount = playersBalances[address(msg.sender)];

		uint256 _contractBalance = getCurrentContractBalance();

		if (_contractBalance >= _availableAmount) {
			(bool success, ) = msg.sender.call{value: _availableAmount}("");

			if (!success) {
				revert Roulette__TransactionFailed();
			}

			playersBalances[address(msg.sender)] = 0;

			allPlayersWinnings -= _availableAmount;
		} else {
			(bool success, ) = msg.sender.call{value: _contractBalance}("");

			if (!success) {
				revert Roulette__TransactionFailed();
			}

			playersBalances[address(msg.sender)] -= _contractBalance;

			allPlayersWinnings -= _contractBalance;
		}
	}

	// Withdrawal for Casino Owner
	function withdrawOwner() external onlyOwner nonReentrant {
		if (currentCasinoBalance < 1) {
			revert Roulette__CasinoIsEmpty();
		}
		bool _enoughLiquidity = ((getCurrentContractBalance() - currentCasinoBalance) >=
			allPlayersWinnings);

		if (_enoughLiquidity) {
			(bool success, ) = msg.sender.call{value: currentCasinoBalance}("");

			if (!success) {
				revert Roulette__TransactionFailed();
			}

			currentCasinoBalance = 0;
		} else {
			revert Roulette__PleaseWaitForLiquidity();
		}
	}

	receive() external payable {
		emit ReceivedDirectValue(msg.sender, msg.value);
	}

	/* View (getter) Functions */
	function checkBalance(address _player) public view returns (uint256 playerBalance_) {
		return playersBalances[_player];
	}

	function getCurrentContractBalance() public view returns (uint256 balance_) {
		return address(this).balance;
	}

	function getStartGameValue() public view returns (uint256 startGameValue_) {
		return startGameValue;
	}

	function getMaximumBet() public view returns (uint256 maximumBet_) {
		return maximumBet;
	}

	function getMinimalBet() public view returns (uint256 minimalBet_) {
		return minimalBet;
	}

	function getMoneyInTheBank() public view returns (uint256 moneyInTheBank_) {
		return moneyInTheBank;
	}

	function getLastWinningNumber() public view returns (uint256 lastWinningNumber_) {
		return lastWinningNumber;
	}

	function getNumberOfPlayers() public view returns (uint256 length_) {
		return betsArr.length;
	}

	function getInterval() public view returns (uint256 interval_) {
		return interval;
	}

	function getLastTimeStamp() public view returns (uint256 lastTimeStamp_) {
		return lastTimeStamp;
	}

	function clearBetsArray(uint256 _length) internal {
		for (uint256 i; i < _length; i += 1) {
			betsArr.pop();
		}
	}

	/* Pure Functions */
	//Possible numbers array length
	function possibleNumbersLength(
		uint8 _betType,
		uint256 _numbersLength
	) internal pure returns (bool correctLength_) {
		bool _correctLength;

		if (
			(_betType == 9 ||
				_betType == 8 ||
				_betType == 7 ||
				_betType == 6 ||
				_betType == 5 ||
				_betType == 0) && (_numbersLength == 1)
		) {
			return !_correctLength;
		}
		if (_betType == 4 && (_numbersLength == 6)) {
			return !_correctLength;
		}
		if (_betType == 3 && (_numbersLength == 4)) {
			return !_correctLength;
		}
		if (_betType == 2 && (_numbersLength == 3)) {
			return !_correctLength;
		}
		if (_betType == 1 && (_numbersLength == 2)) {
			return !_correctLength;
		}

		return _correctLength;
	}

	//Possible real roulette bet
	function possibleBet(
		uint8 _betType,
		uint8[] calldata _numbers
	) internal pure returns (bool correctBet_) {
		bool _correctBet;
		uint8 _leftBorder = _numbers[0];
		uint8 _rightBorder = _numbers[_numbers.length - 1];

		if (
			(_betType == 9 ||
				_betType == 8 ||
				_betType == 7 ||
				_betType == 6 ||
				_betType == 5 ||
				_betType == 0)
		) {
			return !_correctBet;
		}
		if (
			(_betType == 4) &&
			((_leftBorder % 3 == 1) && (_leftBorder % 2 == 1)) &&
			(arrInc(_betType, _numbers))
		) {
			return !_correctBet;
		}

		if (
			(_betType == 3) &&
			(_leftBorder != 0) &&
			(_leftBorder % 3 == 1 || _leftBorder % 3 == 2) &&
			(_rightBorder < 37) &&
			(arrInc(_betType, _numbers))
		) {
			return !_correctBet;
		} else if (
			(_betType == 3) &&
			(_leftBorder != 0) &&
			(_leftBorder % 3 == 1 || _leftBorder % 3 == 2) &&
			(_rightBorder < 37) &&
			(!arrInc(_betType, _numbers))
		) {
			return _correctBet;
		} else if ((_betType == 3) && (_leftBorder == 0)) {
			if ((_numbers[1] == 1) && (_numbers[2] == 2) && (_rightBorder == 3)) {
				return !_correctBet;
			}
			return _correctBet;
		}

		if (
			(_betType == 2) &&
			(_leftBorder != 0) &&
			(_leftBorder % 3 == 1) &&
			(arrInc(_betType, _numbers))
		) {
			return !_correctBet;
		} else if ((_betType == 2) && (_leftBorder == 0)) {
			if (
				((_numbers[1] == 1) && (_rightBorder == 2)) ||
				((_numbers[1] == 2) && (_rightBorder == 3))
			) {
				return !_correctBet;
			}
			return _correctBet;
		}

		if (
			(((_betType == 1) && (_leftBorder != 0)) &&
				(((_rightBorder < 37 && _rightBorder > 1) && (_rightBorder - _leftBorder == 1)))) ||
			(((_rightBorder < 37 && _rightBorder > 3) && (_rightBorder - _leftBorder == 3)))
		) {
			return !_correctBet;
		} else if ((_betType == 1) && (_leftBorder == 0)) {
			if ((_rightBorder == 1) || (_rightBorder == 2) || (_rightBorder == 3)) {
				return !_correctBet;
			}
			return _correctBet;
		}

		return _correctBet;
	}

	//Array values are incrementing check
	function arrInc(
		uint8 _betType,
		uint8[] calldata _numbers
	) internal pure returns (bool incrementing_) {
		bool _incrementing = true;
		if (_betType == 3) {
			if (
				!((_numbers[0] == _numbers[1] - 1) &&
					(_numbers[1] == _numbers[2] - 2) &&
					(_numbers[2] == _numbers[3] - 1))
			) {
				return !_incrementing;
			}

			return _incrementing;
		} else if (_betType != 3) {
			for (uint256 i; i < _numbers.length - 1; i += 1) {
				if (!(_numbers[i] == _numbers[i + 1] - 1)) {
					return !_incrementing;
				}
			}
			return _incrementing;
		}

		return !_incrementing;
	}

	//Calculates winning amount if bet has won
	function calcWin(uint8 _betType, uint256 _amount) internal pure returns (uint256 amount_) {
		if (_betType == 0) {
			return _amount * 36;
		}
		if (_betType == 1) {
			return _amount * 18;
		}
		if (_betType == 2) {
			return _amount * 12;
		}
		if (_betType == 3) {
			return _amount * 9;
		}
		if (_betType == 4) {
			return _amount * 6;
		}
		if (_betType == 5 || _betType == 6) {
			return _amount * 3;
		} else {
			return _amount * 2;
		}
	}

	// Checks bets for winning (matching with random roulette number)
	function checkWinBet(
		uint8 _betType,
		uint8[] memory numbers,
		uint256 _rouletteWinNum
	) internal pure returns (bool won_) {
		bool won;

		if (_rouletteWinNum == 0) {
			return won = (_betType == 0 && numbers[0] == 0);
			/* bet on 0 */
		} else {
			if (_betType == 0) {
				return won = (numbers[0] == _rouletteWinNum); /* bet on number */
			} else if (_betType == 1 || _betType == 2 || _betType == 3 || _betType == 4) {
				for (uint8 i; i < numbers.length; i += 1) {
					if (numbers[i] == _rouletteWinNum) {
						return !won;
					}
				}

				return won;
			} else if (_betType == 5) {
				if (numbers[0] == 0) {
					return won = (_rouletteWinNum % 3 == 1);
				} /* bet on left column */
				if (numbers[0] == 1) {
					return won = (_rouletteWinNum % 3 == 2);
				}
				/* bet on middle column */
				else {
					return won = (_rouletteWinNum % 3 == 0);
				} /* bet on right column */
			} else if (_betType == 6) {
				if (numbers[0] == 0) {
					return won = (_rouletteWinNum < 13);
				} /* bet on 1st dozen */
				if (numbers[0] == 1) {
					return won = (_rouletteWinNum > 12 && _rouletteWinNum < 25);
				}
				/* bet on 2nd dozen */
				else {
					return won = (_rouletteWinNum > 24);
				} /* bet on 3rd dozen */
			} else if (_betType == 7) {
				if (numbers[0] == 0) {
					return won = (_rouletteWinNum < 19);
				}
				/* bet on low 18s */
				else {
					return won = (_rouletteWinNum > 18);
				} /* bet on high 18s */
			} else if (_betType == 8) {
				if (numbers[0] == 0) {
					return won = (_rouletteWinNum % 2 == 0);
				}
				/* bet on even */
				else {
					return won = (_rouletteWinNum % 2 == 1);
				} /* bet on odd */
			} else if (_betType == 9) {
				if (numbers[0] == 0) {
					/* bet on black */
					if (_rouletteWinNum < 11 || (_rouletteWinNum > 19 && _rouletteWinNum < 29)) {
						return won = (_rouletteWinNum % 2 == 0);
					} else {
						return won = (_rouletteWinNum % 2 == 1);
					}
				} else {
					/* bet on red */
					if (_rouletteWinNum < 11 || (_rouletteWinNum > 19 && _rouletteWinNum < 29)) {
						return won = (_rouletteWinNum % 2 == 1);
					} else {
						return won = (_rouletteWinNum % 2 == 0);
					}
				}
			}
		}
		return won;
	}
}