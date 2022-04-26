// SPDX-License-Identifier: MIT

// Lucky Box (raffle draw)
// @Creator: Sharkz
// @Author: Jason Hoi

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IVoteBox.sol";

contract LuckyBox is VRFConsumerBaseV2, Ownable, ReentrancyGuard {
    event DrawCreated(uint256 index, string topic, string content, uint64 poolSize, uint64 winnerSize, uint64 drawTime, uint256 voteBoxPollId, address voteBoxContract);
    event DrawSeeded(uint256 index, uint256 randomSeed);

    // Chainlink VRF, https://docs.chain.link/docs/vrf-contracts/#configurations
    struct VRFRequestConfig {
        uint64 subId;
        uint32 reqGasLimit;
        uint16 reqConfirmations;
    }
    VRFRequestConfig public vrfConfig;
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address vrfLinkContract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 vrfKeyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint256 public vrfRequestId;

    struct DrawEvent {
        string topic;
        string content;
        uint64 poolSize;
        uint64 winnerSize;
        uint64 drawTime;
        uint64 voteBoxPollId;
        IVoteBox voteBoxContract;
    }
    // all draw events
    mapping(uint256 => DrawEvent) public drawEvents;
    // draw seeds
    mapping(uint256 => uint256) private _drawSeeds;
    // total draw event counter, also the next event index id
    uint256 public eventCount;
    // total seeded event counter, also the next seedding event index id
    uint256 public seededEventCount;

    constructor (uint64 _subId) VRFConsumerBaseV2(vrfCoordinator) {
        // VRF setup
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(vrfLinkContract);
        vrfConfig = VRFRequestConfig({
            subId: _subId,
            reqGasLimit: 2500000,
            reqConfirmations: 3
        });
    }

    // [email protected]
    function customDraw(uint256 _randomSeed) external onlyOwner {
        _seed(_randomSeed);
    }

    function createDraw(
        string calldata _topic, 
        string calldata _content, 
        uint64 _poolSize,
        uint64 _winnerSize,
        uint64 _drawTime,
        uint64 _voteBoxPollId,
        address _voteBoxContract
    ) external {
        require(bytes(_topic).length > 0, "Topic is empty");
        require(_poolSize > 0, "Pool size is zero");
        require(_winnerSize > 0, "Winner size is zero");

        uint256 _index = eventCount;
        drawEvents[_index].topic = _topic;
        drawEvents[_index].content = _content;
        drawEvents[_index].poolSize = _poolSize;
        drawEvents[_index].winnerSize = _winnerSize;
        drawEvents[_index].drawTime = _drawTime;
        drawEvents[_index].voteBoxPollId = _voteBoxPollId;
        drawEvents[_index].voteBoxContract = IVoteBox(_voteBoxContract);
        eventCount++;

        emit DrawCreated(_index, _topic, _content, _poolSize, _winnerSize, _drawTime, _voteBoxPollId, _voteBoxContract);
    }

    // Run next lucky draw (Lucky draw seed will be filled by Chainlink VRF service)
    function draw() public nonReentrant onlyOwner {
        require (eventCount > seededEventCount, "No pending draw event");

        VRFRequestConfig memory vrf = vrfConfig;
        vrfRequestId = COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrf.subId,
            vrf.reqConfirmations,
            vrf.reqGasLimit,
            1
        );
    }

    function setVoteBoxContract(uint256 _drawIndex, address _voteBoxContract) external onlyOwner{
        require(_existsDraw(_drawIndex), "Draw is not exists");
        require(_voteBoxContract != address(0), "Invalid contract address");

        drawEvents[_drawIndex].voteBoxContract = IVoteBox(_voteBoxContract);
    }

    function getAllWinners(uint256 _drawIndex) public view returns (uint256[] memory) {
        require(_existsDraw(_drawIndex), "Draw is not exists");
        require(_isDrawSeeded(_drawIndex), "Draw is not seeded");

        uint256 drawTime = uint256(drawEvents[_drawIndex].drawTime);
        require(drawTime > 0 && block.timestamp > drawTime, "Draw time is not reached");

        uint256 seed = _drawSeeds[_drawIndex];
        require(seed > 0, "Draw is not seeded");

        uint256 poolSize = drawEvents[_drawIndex].poolSize;

        // create sequential id pool
        uint256[] memory ids = new uint256[](poolSize + 1);
        for (uint256 i = 0; i < poolSize; i++) {
            ids[i] = i;
        }
        // shuffle the pool
        for (uint256 i = 0; i < poolSize; i++) {
            uint256 swap = uint256(keccak256(abi.encode(seed,i))) % poolSize;
            (ids[i], ids[swap]) = (ids[swap], ids[i]);
        }

        // generate winner pool
        uint256 winnerSize = drawEvents[_drawIndex].winnerSize;
        // when total pool size is smaller than target winner pool size, everyone win!
        if (poolSize < winnerSize) {
            winnerSize = poolSize;
        }
        uint256[] memory winnerIds = new uint256[](winnerSize);
        for (uint256 i = 0; i < winnerSize; i++) {
            winnerIds[i] = ids[i];
        }

        return winnerIds;
    }

    function getWinnerByIndex(uint256 _drawIndex, uint256 _index) public view returns (uint256) {
        require(_existsDraw(_index), "Draw is not exists");
        require(_isDrawSeeded(_index), "Draw is not seeded");

        uint256[] memory ids = getAllWinners(_drawIndex);
        return ids[_index];
    }

    function getWinnerVoterAddress(uint256 _drawIndex, uint256 _index) public view returns (address) {
        require(_existsDraw(_index), "Draw is not exists");
        require(_isDrawSeeded(_index), "Draw is not seeded");

        uint256[] memory ids = getAllWinners(_drawIndex);
        uint256 voterIndex = ids[_index];

        // call external contract
        IVoteBox voteBox = drawEvents[_drawIndex].voteBoxContract;
        uint256 pid = drawEvents[_drawIndex].voteBoxPollId;
        

        return voteBox.getVoterAddress(pid, voterIndex);
    }

    ///////// Internal functions
    // Check if draw event exists
    function _existsDraw(uint256 _drawIndex) internal view returns (bool) {
        return _drawIndex < eventCount;
    }
    // Check if draw event seeded (finished raffle draw)
    function _isDrawSeeded(uint256 _drawIndex) internal view returns (bool) {
        return _drawSeeds[_drawIndex] > 0;
    }
    // Insert the new seed to the last unseeded draw event
    function _seed(uint256 _randomSeed) internal {
        require (eventCount > seededEventCount, "All draws are seeded");

        // do raffle draw (seed the next unseeded event to reveal winners)
        uint256 _index = seededEventCount;
        _drawSeeds[_index] = _randomSeed;
        seededEventCount++;

        emit DrawSeeded(_index, _randomSeed);
    }

    // Chainlink random seeding
    function fulfillRandomWords(uint256 _reqId, uint256[] memory _randomWords) internal override {
        require(_reqId == vrfRequestId, "Invalid VRF request id");

        if (_randomWords[0] > 0) {
            _seed(_randomWords[0]);
        }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// VoteBox interface
// @Creator: Sharkz
// @Author: Jason Hoi

pragma solidity ^0.8.0;

interface IVoteBox {
    event PollCreated(uint256 pollId, string topic, uint256 startTime, uint256 endTime, uint optionCount);
    event PollChangedStartTime(uint256 pollId, uint256 time);
    event PollChangedEndTime(uint256 pollId, uint256 time);
    event Voted(address indexed sender, uint256 pollId, uint value);

    // Get total poll count
    function totalPoll() external view returns (uint256);
    // Get poll total options available
    function getPollOptionCount(uint256 _pid) external view returns (uint256);
    // Get poll content
    function getPollContent(uint256 _pid) external view returns (string memory);
    // Get poll total vote counts
    function getPollVoteCount(uint256 _pid) external view returns (uint256);
    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view returns (uint256);
    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view returns (address);
    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view returns (bool);
    // Check voter is on poll allowlist
    function isVoterAllowed(bytes calldata _signature, uint256 _pid) external view returns (bool);
    // Check if voter is currently holder target NFT
    function isNftHolder(address _addr) external view returns(bool);
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