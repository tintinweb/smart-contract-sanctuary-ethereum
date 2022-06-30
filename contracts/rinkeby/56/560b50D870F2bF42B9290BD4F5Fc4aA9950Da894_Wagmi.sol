// SPDX-License-Identifier: MIT

//
//  $$\      $$\  $$$$$$\   $$$$$$\  $$\      $$\ $$$$$$\
//  $$ | $\  $$ |$$  __$$\ $$  __$$\ $$$\    $$$ |\_$$  _|
//  $$ |$$$\ $$ |$$ /  $$ |$$ /  \__|$$$$\  $$$$ |  $$ |
//  $$ $$ $$\$$ |$$$$$$$$ |$$ |$$$$\ $$\$$\$$ $$ |  $$ |
//  $$$$  _$$$$ |$$  __$$ |$$ |\_$$ |$$ \$$$  $$ |  $$ |
//  $$$  / \$$$ |$$ |  $$ |$$ |  $$ |$$ |\$  /$$ |  $$ |
//  $$  /   \$$ |$$ |  $$ |\$$$$$$  |$$ | \_/ $$ |$$$$$$\
//  \__/     \__|\__|  \__| \______/ \__|     \__|\______|
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Wagmi is Ownable, Pausable, VRFConsumerBaseV2 {
    // ============ Structs ============

    struct Prize {
        // smart contract collection address on ETH
        address collection;
        // price in native token
        uint256 price;
    }

    struct Bet {
        address player;
        // index to prizes array
        uint32 prizeId;
        // ball position guess
        uint32 x; // < IMAGE_MAX_X
        uint32 y; // < IMAGE_MAX_Y
    }

    // ============ Constants ============
    // max image width
    uint256 private constant IMAGE_MAX_X = 1000;
    // max image height
    uint256 private constant IMAGE_MAX_Y = 1000;
    // how many pixels is allowed to move randomly ball position
    uint256 private constant BALL_POSITION_MAX_SHIFT = 50;
    // time when game ends after enough investments is collected
    uint256 private constant GAME_END_AFTER_FUNDED = 5 minutes;
    // uint256 private constant GAME_END_AFTER_FUNDED = 7 days;
    // time until prize has to be delivered to winner
    uint256 private constant PRIZE_DELIVERY_THRESHOLD = 5 minutes;
    // uint256 private constant PRIZE_DELIVERY_THRESHOLD = 7 days;

    // ***** START Chainlink config
    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    // Rinkeby coordinator.
    address private constant VRF_COORDINATOR =
    0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    // Polygon mainnet coordinator
    // address private constant VRF_COORDINATOR = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    // Rinkeby gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 private constant KEY_HASH =
    0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    // Polygon mainnet gas lane to use, which specifies the maximum gas price to bump to.
    // bytes32 private constant KEY_HASH = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

    // How many random values to receive
    uint32 private constant NUM_WORDS = 1;
    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // ***** END Chainlink config

    // ============ Variables ============

    bool public isActive;
    bool public isPrizeDelivered;
    uint256 public ticketPrice;
    bytes32 public commit;
    bool public hasWinner;
    uint256 public winningBetId;
    Bet public winningBet;
    Prize public wonPrize;
    Prize[] public prizes;
    mapping(address => uint256) public investors;
    Bet[] public bets;
    uint256[] public winningCandidateBetIds;
    // Coordinates from commit
    uint256 public commitBallX;
    uint256 public commitBallY;
    // Final random coordinates
    uint256 public ballX;
    uint256 public ballY;
    // Timestamp when game ends
    uint256 public gameEnd;
    // Leftover from prize purchase
    uint256 public prizePurchaseSurplus;
    // Total amount from investments
    uint256 public investmentFunds;
    // Total amount from ticket sale
    uint256 public ticketSaleFunds;

    uint256 private _maxPrizePrice;
    uint256 private _ballRandomRequestId;
    uint256 private _winnerRandomRequestId;
    bool private _prizeFundsWithdrawn;
    // Chainlink VRF subscription ID
    uint64 private _subscriptionId;
    // Chainlink coordinator
    VRFCoordinatorV2Interface private _coordinator;

    // ============ Modifiers ============

    modifier onlyActive() {
        require(isActive, "Game is not active");
        _;
    }

    // ============ Events ============

    event BetPlaced(address indexed player, Bet bet);
    event Invested(address indexed investor, uint256 amount);
    event TicketPriceChanged(uint256 price);
    event GameFinished(uint256 invested, uint256 ticketSales);
    event BallPositionFound(uint256 x, uint256 y);
    event WinningBetFound(Bet bet);
    event PurchasePrizeFundsWitdhrawn(uint256 amount);
    event PrizeDelivered(uint256 surplus);
    event InvestmentClaimed(address indexed investor, uint256 amount);

    // ============ Methods ============

    /**
     *  @param commit_ Hashed coordinates x, y and salt.
     *  x and y has to be > 0 and x <= IMAGE_MAX_X and y <= IMAGE_MAX_Y.
     *  Can be obtained from getCommit method.
     *  @param subscriptionId chainlink VRF subscription ID
     *  @param ticketPrice_ ticket price in native token
     *  @param prizes_ array of prizes
     */
    constructor(
        bytes32 commit_,
        uint64 subscriptionId,
        uint256 ticketPrice_,
        Prize[] memory prizes_
    ) VRFConsumerBaseV2(VRF_COORDINATOR) {
        commit = commit_;
        ticketPrice = ticketPrice_;
        _subscriptionId = subscriptionId;
        _coordinator = VRFCoordinatorV2Interface(VRF_COORDINATOR);

        isActive = true;
        isPrizeDelivered = false;
        _prizeFundsWithdrawn = false;

    unchecked {
        uint256 maxPrizePrice = 0;
        for (uint256 i = 0; i < prizes_.length; i++) {
            prizes.push(prizes_[i]);

            if (maxPrizePrice < prizes_[i].price) {
                maxPrizePrice = prizes_[i].price;
            }
        }
        _maxPrizePrice = maxPrizePrice;
    }
    }

    /**
     *  @dev Set ticket price in native token
     */
    function setTicketPrice(uint256 ticketPrice_) external onlyOwner {
        ticketPrice = ticketPrice_;

        emit TicketPriceChanged(ticketPrice_);
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     *  @dev Get commit with coordinates for starting game
     *
     *  @param x X ball coordinate
     *  @param y Y ball coordinate
     *  @param salt random salt (eg. keccak256(uuid4))
     */
    function getCommit(
        uint256 x,
        uint256 y,
        string calldata salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(x, y, salt));
    }

    /**
     *  @notice Invest
     */
    function invest() external payable onlyActive whenNotPaused {
        investmentFunds += msg.value;

        if (gameEnd == 0 && investmentFunds >= _maxPrizePrice) {
            gameEnd = block.timestamp + GAME_END_AFTER_FUNDED;
        }

        investors[msg.sender] += msg.value;

        emit Invested(msg.sender, msg.value);
    }

    /**
     *  @notice Place bets
     *  @dev Don't pass huge arrays because of gas limit
     */
    function placeBets(Bet[] calldata bets_)
    external
    payable
    onlyActive
    whenNotPaused
    {
        require(bets_.length > 0, "At least 1 bet required");
        require(msg.value >= bets_.length * ticketPrice, "Too small value");

        ticketSaleFunds += msg.value;

    unchecked {
        for (uint256 i = 0; i < bets_.length; i++) {
            require(
                bets_[i].x > 0 && bets_[i].y > 0,
                "Invalid coordinates"
            );
            require(
                bets_[i].x <= IMAGE_MAX_X && bets_[i].y <= IMAGE_MAX_Y,
                "Invalid coordinates"
            );
            require(bets_[i].prizeId < prizes.length, "Invalid prize ID");

            bets.push(bets_[i]);

            emit BetPlaced(msg.sender, bets_[i]);
        }
    }
    }

    /**
     *  @dev Should be called with leftover value from NFT purchase
     */
    function deliverPrize() external payable onlyOwner {
        require(hasWinner, "Does not have winner");

        prizePurchaseSurplus = msg.value;
        isPrizeDelivered = true;

        emit PrizeDelivered(msg.value);
    }

    /**
     *  @dev Reveals chosen coordinates and ends game
     */
    function finishGame(
        uint256 x,
        uint256 y,
        string calldata salt
    ) external onlyOwner onlyActive {
        require(commit == getCommit(x, y, salt), "Commit does not match");

        commitBallX = x;
        commitBallY = y;

        // Will revert if subscription is not set and funded
        _ballRandomRequestId = _coordinator.requestRandomWords(
            KEY_HASH,
            _subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        isActive = false;

        emit GameFinished(investmentFunds, ticketSaleFunds);
    }

    /**
     *  @dev It's computation-heavy to find winner on-chain so it has to be done
     *  @dev off-chain and only winner candidates are passed here
     *  @dev (there can be more winning bets in the same distance from center ball position).
     *  @dev Anyone can verify that all candidates were selected correctly by owner.
     *
     *  @param winningCandidateBetIds_ index IDs from bets array with closest placed bets from ball position
     */
    function findWinner(uint256[] calldata winningCandidateBetIds_)
    external
    onlyOwner
    {
        require(!isActive, "Game is still active");
        require(ballX > 0 && ballY > 0, "Ball position not found");
        require(!hasWinner, "Winner already found");
        require(
            winningCandidateBetIds_.length > 0,
            "At least 1 candidate required"
        );

        winningCandidateBetIds = winningCandidateBetIds_;

        if (winningCandidateBetIds.length == 1) {
            _setWinner(winningCandidateBetIds[0]);
            return;
        }

        // Will revert if subscription is not set and funded
        _winnerRandomRequestId = _coordinator.requestRandomWords(
            KEY_HASH,
            _subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
    }

    function claimInvestment() external {
        require(!isActive, "Game is not finished");
        require(investors[msg.sender] != 0, "Nothing to claim");
        require(
            isPrizeDelivered ||
            block.timestamp > gameEnd + PRIZE_DELIVERY_THRESHOLD,
            "Not available"
        );

        uint256 totalFunds = ticketSaleFunds +
        investmentFunds -
        wonPrize.price +
        prizePurchaseSurplus;

        uint256 investedPortion = investors[msg.sender] / investmentFunds;

        uint256 profit = totalFunds * investedPortion;

        investors[msg.sender] = 0;

        payable(msg.sender).transfer(profit);

        emit InvestmentClaimed(msg.sender, profit);
    }

    /**
     *  @dev Allow owner to withdraw funds for prize purchase
     */
    function withdrawPrizePurchaseFunds() external onlyOwner {
        require(!hasWinner, "Winner not found");
        require(!_prizeFundsWithdrawn, "Already withdrawn");
        require(!isPrizeDelivered, "Prize already delivered");

        _prizeFundsWithdrawn = true;

        payable(msg.sender).transfer(wonPrize.price);

        emit PurchasePrizeFundsWitdhrawn(wonPrize.price);
    }

    /**
     *  @dev Select random winner
     */
    function _setWinner(uint256 winningBetId_) private {
        winningBetId = winningBetId_;
        winningBet = bets[winningBetId];
        wonPrize = prizes[winningBet.prizeId];
        hasWinner = true;

        emit WinningBetFound(winningBet);
    }

    /**
     *  @dev Select random winner
     */
    function _selectRandomWinner(uint256 random) private {
        _setWinner(random % winningCandidateBetIds.length);
    }

    /**
     *  @dev Select random ball position
     */
    function _selectRandomBallPosition(uint256 random) private {
        uint256 commitBallXAdjusted = commitBallX;
        uint256 commitBallYAdjusted = commitBallY;

        // adjust coordinates if it's too close to borders
        // and subtract by BALL_POSITION_MAX_SHIFT so random value
        // can be number between 0 and 2*BALL_POSITION_MAX_SHIFT
        if (commitBallXAdjusted < BALL_POSITION_MAX_SHIFT) {
            commitBallXAdjusted = 0;
        } else if (
            IMAGE_MAX_X - commitBallXAdjusted < BALL_POSITION_MAX_SHIFT
        ) {
            commitBallXAdjusted = IMAGE_MAX_X - BALL_POSITION_MAX_SHIFT * 2;
        } else {
            commitBallXAdjusted =
            commitBallXAdjusted -
            BALL_POSITION_MAX_SHIFT;
        }

        if (commitBallYAdjusted < BALL_POSITION_MAX_SHIFT) {
            commitBallYAdjusted = 0;
        } else if (
            IMAGE_MAX_Y - commitBallYAdjusted < BALL_POSITION_MAX_SHIFT
        ) {
            commitBallYAdjusted = IMAGE_MAX_Y - BALL_POSITION_MAX_SHIFT * 2;
        } else {
            commitBallYAdjusted =
            commitBallYAdjusted -
            BALL_POSITION_MAX_SHIFT;
        }

        uint256 range = BALL_POSITION_MAX_SHIFT * 2;

        uint256 xShift = random % range;
        uint256 yShift = (random >> 16) % range;

        ballX = commitBallXAdjusted + xShift;
        ballY = commitBallYAdjusted + yShift;

        emit BallPositionFound(ballX, ballY);
    }

    /**
     *  @dev Chainlink callback with random value
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
    {
        requestId == _winnerRandomRequestId
        ? _selectRandomWinner(randomWords[0])
        : _selectRandomBallPosition(randomWords[0]);
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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