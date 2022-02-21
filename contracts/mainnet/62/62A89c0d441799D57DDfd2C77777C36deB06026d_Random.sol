// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
*
        :'#######:::'#######:::'#######:::'#######:::'#######:::'#######::
        '##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:
        ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##:
        : #######::: #######::: #######::: #######::: #######::: #######::
        '##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:
        ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##:
        . #######::. #######::. #######::. #######::. #######::. #######::
        :.......::::.......::::.......::::.......::::.......::::.......:::  

                              A game of chance
*/
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {IERC20} from'@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Random is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface public COORDINATOR;
  LinkTokenInterface public LINKTOKEN;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // USDT address
  IERC20 public usdt;

  // Duration that game lasts
  uint public gameDuration;

  // Time when game starts - after bootstrap
  uint public startTime;

  // Cost per dice roll
  uint public ticketSize = 1 * 10 ** 6;

  // Percentage precision
  uint public percentagePrecision = 10 ** 2;

  // Fees earmarked for VRF requests
  uint public linkFeePercent = 20 * percentagePrecision;

  // Fees for the house
  uint public houseFeePercent = 5 * percentagePrecision; // 5%

  // Fee % (10**2 precision)
  uint public feePercentage = linkFeePercent + houseFeePercent; // 25%

  // Revenue split % (10**2 precision) - all depositors with a roll above 600k get a revenue split 
  uint public revenueSplitPercentage = 20 * percentagePrecision; // 20%

  // Threshold roll above which rollers get revenue split
  uint public revenueSplitRollThreshold = 60 * 10 ** 4; // 600k

  // Total revenue collected from all dice rolls
  uint public revenue;

  // Total revenue split shares for rolls above revenue split threshold
  uint public totalRevenueSplitShares;

  // Maps users to amount earned via revenue splits shares
  mapping(address => uint) public revenueSplitSharesPerUser;

  // Tracks revenue split collected per user
  mapping (address => uint) public revenueSplitCollectedPerUser;

  // Total fees collected from all dice rolls
  uint public feesCollected;

  // Winnings distributed at bootstrap
  uint public bootstrapWinnings;

  // Toggled to true to begin the game
  bool public isBootstrapped;

  // Roll with number closest to winning number
  DiceRoll public currentWinner;

  // Winning roll
  DiceRoll public winner;

  // Number to win
  uint public winningNumber = 888888;

  // Maps request IDs to addresses that rolled dice
  mapping (uint => address) public rollRequests;

  // Tracks number of rolls - used as auto-incrementing roll ID
  uint public rollCount;

  // Store dice rolls by roll ID here
  mapping (uint => DiceRoll) public diceRolls;

  address public vrfCoordinator;

  address public link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  // 200 gwei
  bytes32 public keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
  
  uint32 public callbackGasLimit = 600000;

  // The default is 3, but you can set this higher.
  uint16 public requestConfirmations = 3;

  // Contract owner
  address owner;

  struct DiceRoll {
    // Random number on roll
    uint roll;
    // Address of roller
    address roller;
  }

  event LogNewRollRequest(uint requestId, address indexed roller);
  event LogOnRollResult(uint requestId, uint rollId, uint roll, address indexed roller);
  event LogNewCurrentWinner(uint requestId, uint rollId, uint roll, address indexed roller);
  event LogGameOver(address indexed winner, uint winnings); 
  event LogOnCollectRevenueSplit(address indexed user, uint split);

  constructor(
    uint64 subscriptionId,
    address _usdt,
    address _vrfCoordinator,
    uint _gameDuration
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    owner = msg.sender;
    s_subscriptionId = subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    usdt = IERC20(_usdt);
    gameDuration = _gameDuration;
  }

  // Set a new coordinator address
  function setCoordinator(address _coordinator) 
  public
  onlyOwner 
  returns (bool) {
    require(!isBootstrapped, "Contract is already bootstrapped");
    vrfCoordinator = _coordinator;
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    return true;
  }

  // Called initially to bootstrap the game
  function bootstrap(
    uint _bootstrapWinnings
  )
  public
  onlyOwner
  returns (bool) {
    require(!isBootstrapped, "Game already bootstrapped");
    bootstrapWinnings = _bootstrapWinnings;
    revenue += _bootstrapWinnings;
    isBootstrapped = true;
    startTime = block.timestamp;
    usdt.transferFrom(msg.sender, address(this), _bootstrapWinnings);
    return true;
  }

  // Allows owner to collect fees
  function collectFees() 
  public
  returns (bool) {
    uint fees = getFees();
    feesCollected += fees;
    usdt.transfer(owner, fees);
    return true;
  }

  // Process random words from chainlink VRF2
  function fulfillRandomWords(
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    for (uint i = 0; i < randomWords.length; i++) {
      diceRolls[++rollCount].roll = getFormattedNumber(randomWords[i]);
      diceRolls[rollCount].roller = rollRequests[requestId];

      // If the game was over between rolls - don't perform any of the below logic
      if (!isGameOver()) {
        if (diceRolls[rollCount].roll == winningNumber) {
          // User wins
          winner = diceRolls[rollCount];
          // Transfer revenue to winner
          collectFees();
          uint revenueSplit = getRevenueSplit();
          uint winnings = revenue - feesCollected - revenueSplit;
          usdt.transfer(winner.roller, winnings);
          emit LogGameOver(winner.roller, winnings);
        } else if (diceRolls[rollCount].roll >= revenueSplitRollThreshold) {
          totalRevenueSplitShares += 1;
          revenueSplitSharesPerUser[diceRolls[rollCount].roller] += 1;
        }

        if (diceRolls[rollCount].roll != winningNumber) {
          int diff = getDiff(diceRolls[rollCount].roll, winningNumber);
          int currentWinnerDiff = getDiff(currentWinner.roll, winningNumber);

          if (diff <= currentWinnerDiff) 
            currentWinner = diceRolls[rollCount];

          emit LogNewCurrentWinner(requestId, rollCount, diceRolls[rollCount].roll, diceRolls[rollCount].roller);
        }
      }

      emit LogOnRollResult(requestId, rollCount, diceRolls[rollCount].roll, diceRolls[rollCount].roller);
    }
  }

  // Returns difference between 2 dice rolls
  function getDiff(uint a, uint b) private pure returns (int) {
    unchecked {
      int x = int(a-b);
      return x >= 0 ? x : -x;
    }
  }

  // Ends a game that is past it's duration without a winner
  function endGame()
  public
  returns (bool) {
    require(
      hasGameDurationElapsed() && winner.roller == address(0), 
      "Game duration hasn't elapsed without a winner"
    );
    winner = currentWinner;
    // Transfer revenue to winner
    collectFees();
    uint revenueSplit = getRevenueSplit();
    uint winnings = revenue - feesCollected - revenueSplit;
    usdt.transfer(winner.roller, winnings);
    emit LogGameOver(winner.roller, winnings);
    return true;
  }

  // Allows users to collect their share of revenue split after a game is over  
  function collectRevenueSplit() external {
    require(isGameOver(), "Game isn't over");
    require(revenueSplitSharesPerUser[msg.sender] > 0, "User does not have any revenue split shares");
    require(revenueSplitCollectedPerUser[msg.sender] == 0, "User has already collected revenue split");
    uint revenueSplit = getRevenueSplit();
    uint userRevenueSplit = revenueSplit * revenueSplitSharesPerUser[msg.sender] / totalRevenueSplitShares; 
    revenueSplitCollectedPerUser[msg.sender] = userRevenueSplit;
    usdt.transfer(msg.sender, userRevenueSplit);
    emit LogOnCollectRevenueSplit(msg.sender, userRevenueSplit);
  }

  // Assumes the subscription is funded sufficiently.
  function rollDice() external {
    require(isBootstrapped, "Game is not bootstrapped");
    require(!isGameOver(), "Game is over");
    revenue += ticketSize;
    usdt.transferFrom(msg.sender, address(this), ticketSize);
    
    // Will revert if subscription is not set and funded.
    uint requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      1
    );
    rollRequests[requestId] = msg.sender;

    emit LogNewRollRequest(requestId, msg.sender);
  }

  // Approve USD once and roll multiple times
  function rollMultipleDice(uint32 times) external {
    require(isBootstrapped, "Game is not bootstrapped");
    require(!isGameOver(), "Game is over");
    require(times > 1 && times <= 5, "Should be >=1 and <=5 rolls in 1 txn");
    uint total = ticketSize * times;
    revenue += total;
    usdt.transferFrom(msg.sender, address(this), total);
    
    // Will revert if subscription is not set and funded.
    uint requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      times
    );
    rollRequests[requestId] = msg.sender;
    emit LogNewRollRequest(requestId, msg.sender);
  }

  // Returns current available fees
  function getFees()
  public
  view
  returns (uint) {
    return ((revenue * feePercentage) / (100 * percentagePrecision)) - feesCollected;
  }

  // Returns revenue split for rollers above 600k
  function getRevenueSplit()
  public
  view
  returns (uint) {
    return ((revenue * revenueSplitPercentage) / (100 * percentagePrecision));
  }

  // Format number to 0 - 10 ** 6 range
  function getFormattedNumber(
    uint number
  )
  public
  pure
  returns (uint) {
    return number % 1000000 + 1;
  }

  // Returns whether the game is still running
  function isGameOver()
  public
  view
  returns (bool) {
    return winner.roller != address(0) || hasGameDurationElapsed();
  }

  // Returns whether the game duration has ended
  function hasGameDurationElapsed()
  public
  view
  returns (bool) {
    return block.timestamp > startTime + gameDuration;
  }

  function updateCallbackGasLimit(uint32 limit)
  public
  onlyOwner returns (bool) {
    require(limit >= 500000, "Limit must be >=500000");
    callbackGasLimit = limit;
    return true;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}