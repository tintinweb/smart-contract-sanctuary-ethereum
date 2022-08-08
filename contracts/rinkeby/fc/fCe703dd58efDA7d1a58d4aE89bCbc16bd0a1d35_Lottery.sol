//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./LotteryData.sol";

contract Lottery is VRFConsumerBaseV2{
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    LotteryData LOTTERY_DATA;

    using Counters for Counters.Counter;

    using SafeMath for uint256;

    Counters.Counter private lotteryId;

    uint public totalAllowedPlayers = 5;

    address public lotteryManager;

    mapping(uint256 => uint256) private lotteryRandomnessRequest;
    bytes32 private keyHash;
    uint64 immutable s_subscriptionId;
    uint16 immutable requestConfirmations = 3;
    uint32 immutable callbackGasLimit = 100000;
    uint256 public s_requestId;

    event RandomnessRequested(uint256,uint256);
    
    //To emit data which will contain the requestId-from chainlink vrf, lotteryId, winnder address
    event WinnerDeclared(uint256 ,uint256,address);

    //To emit data which will contain the lotteryId, address of new-player & new Price Pool
    event NewLotteryPlayer(uint256, address, uint256);

    //To emit data which will contain the id of newly created lottery
    event LotteryCreated(uint256);


    //custom Errors
    error invalidValue();
    error invalidFee();
    error lotteryNotActive();
    error lotteryFull();
    error alreadyEntered();
    error lotteryEnded();
    error playersNotFound();
    error onlyLotteryManagerAllowed();

     constructor(
        bytes32 _keyHash,
        uint64 subscriptionId, 
        address _vrfCoordinator, 
        address _link,
        address _lotteryData
        ) VRFConsumerBaseV2(_vrfCoordinator){
        lotteryId.increment();   
        lotteryManager = msg.sender;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        LOTTERY_DATA = LotteryData(_lotteryData);
    }

    modifier onlyLotteryManager {
        if(msg.sender != lotteryManager) revert onlyLotteryManagerAllowed();
        _;
    }

    function getAllLotteryIds() public view returns(uint256[] memory){
        return LOTTERY_DATA.getAllLotteryIds();
    }

    function startLottery() public payable onlyLotteryManager {
        LOTTERY_DATA.addLotteryData(lotteryId.current());
        lotteryId.increment();
        emit LotteryCreated(lotteryId.current());
    }

    function isPresent(address[] memory _p, address _a) public pure returns (bool){
        for (uint i=0; i < _p.length; i++) {
            if(_p[i] == _a) {
                return true;
            }
        }
        return false;
    }

    function enterLottery(uint256 _lotteryId) public payable {
        (uint256 lId, 
        uint256 ticketPrice, 
        uint256 prizePool, 
        address[] memory players, 
        address winner, 
        bool isFinished) = LOTTERY_DATA.getLottery(_lotteryId);
        if(isPresent(players, msg.sender)) revert alreadyEntered();
        if(isFinished) revert lotteryNotActive();
        if(players.length >= totalAllowedPlayers) revert lotteryFull();
        if(msg.value < ticketPrice) revert invalidFee();
        uint256  updatedPricePool = prizePool + msg.value;
        LOTTERY_DATA.addPlayerToLottery(_lotteryId, updatedPricePool, msg.sender);
        emit NewLotteryPlayer(_lotteryId, msg.sender, updatedPricePool);
    }

    function pickWinner(uint256 _lotteryId) public onlyLotteryManager {

        if(LOTTERY_DATA.isLotteryFinished(_lotteryId)) revert lotteryEnded();

        address[] memory p = LOTTERY_DATA.getLotteryPlayers(_lotteryId);
        if(p.length == 1) {
            if(p[0] == address(0)) revert playersNotFound();
            //require(p[0] != address(0), "no_players_found");
            LOTTERY_DATA.setWinnerForLottery(_lotteryId, 0);
            payable(p[0]).transfer(address(this).balance);
            emit WinnerDeclared(0,_lotteryId,p[0]);
        } else {
            //LINK is from VRFConsumerBase
            s_requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                1 // number of random numbers
            );
            lotteryRandomnessRequest[s_requestId] = _lotteryId;
            emit RandomnessRequested(s_requestId,_lotteryId);
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        uint256 _lotteryId = lotteryRandomnessRequest[requestId];
        address[] memory allPlayers = LOTTERY_DATA.getLotteryPlayers(_lotteryId);
        uint256 winnerIndex = randomness[0].mod(allPlayers.length);
        LOTTERY_DATA.setWinnerForLottery(_lotteryId, winnerIndex);
        delete lotteryRandomnessRequest[requestId];
        payable(allPlayers[winnerIndex]).transfer(address(this).balance);
        emit WinnerDeclared(requestId,_lotteryId,allPlayers[winnerIndex]);
    }

    function getLotteryDetails(uint256 _lotteryId) public view returns(
        uint256,
        uint256,
        uint256 ,
        address[] memory,
        address ,
        bool
        ){
            return LOTTERY_DATA.getLottery(_lotteryId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


contract LotteryData {

    struct LotteryInfo{
        uint256 lotteryId;
        uint256 ticketPrice;
        uint256 prizePool;
        address[] players;
        address winner;
        bool isFinished;
    }
    mapping(uint256 => LotteryInfo) public lotteries;

    uint256[] public allLotteries;

    uint public lotteryTicketPrice = 0.5 ether;

    address private manager;
    bool private isLotteryContractSet;
    address private lotteryContract;
    constructor(){
        manager = msg.sender;
    }

    error lotteryNotFound();
    error onlyLotteryManagerAllowed();
    error actionNotAllowed();

    modifier onlyManager(){
        if(msg.sender != manager) revert onlyLotteryManagerAllowed();
        _;
    }

    modifier onlyLoterryContract(){
        if(!isLotteryContractSet) revert actionNotAllowed();
        if(msg.sender != lotteryContract) revert onlyLotteryManagerAllowed();
        _;
    }

    function updateLotteryContract(address _lotteryContract) external onlyManager{
        isLotteryContractSet = true;
        lotteryContract = _lotteryContract;
    }

    function getAllLotteryIds() external view returns(uint256[] memory){
        return allLotteries;
    }


    function addLotteryData(uint256 _lotteryId) external onlyLoterryContract{
        LotteryInfo memory lottery = LotteryInfo({
            lotteryId: _lotteryId,
            ticketPrice: lotteryTicketPrice,
            prizePool: 0,
            players: new address[](0),
            winner: address(0),
            isFinished: false
        });
        lotteries[_lotteryId] = lottery;
        allLotteries.push(_lotteryId);
    }

    function addPlayerToLottery(uint256 _lotteryId, uint256 _updatedPricePool, address _player) external onlyLoterryContract{
        LotteryInfo storage lottery = lotteries[_lotteryId];
        if(lottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        lottery.players.push(_player);
        lottery.prizePool = _updatedPricePool;
    }


    function getLotteryPlayers(uint256 _lotteryId) public view returns(address[] memory) {
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
        if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.players;
    }

    function isLotteryFinished(uint256 _lotteryId) public view returns(bool){
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
         if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.isFinished;
    }

    function getLotteryPlayerLength(uint256 _lotteryId) public view returns(uint256){
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
         if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.players.length;
    }

    function getLottery(uint256 _lotteryId) external view returns(
        uint256,
        uint256,
        uint256 ,
        address[] memory,
        address ,
        bool
        ){
            LotteryInfo memory tmpLottery = lotteries[_lotteryId];
            if(tmpLottery.lotteryId == 0){
                revert lotteryNotFound();
            }
            return (
                tmpLottery.lotteryId,
                tmpLottery.ticketPrice,
                tmpLottery.prizePool,
                tmpLottery.players,
                tmpLottery.winner,
                tmpLottery.isFinished
            );
    }

    function setWinnerForLottery(uint256 _lotteryId, uint256 _winnerIndex) external onlyLoterryContract {
        LotteryInfo storage lottery = lotteries[_lotteryId];
        if(lottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        lottery.isFinished = true;
        lottery.winner = lottery.players[_winnerIndex];
    }
}