// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █                                                                        
                                                                       
 *******************************************************************************
 * LuckyBox - A raffle drawer for a pool of ids
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-05-01
 *
 */

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/vote/IVoteBox.sol";
import "../lib/Adminable.sol";

/**
 * @dev Lucky draw facility designed to connect with VoteBox contract, random seeded 
 *  provided by requesting Chainlink VRF for RNG seeding.
 *  
 *  Steps to start a new draw event:
 *  1) Admin calls createDraw() to setup new draw event, draw event linking with 
 *     VoteBox contract (optional) to allow this contract to fetch winner wallet 
 *     address from VoteBox voters.
 *  2) Admin calls setDrawProvenance() (each draw can be set once) to proof the 
 *     draw participants address sequence is fixed, each address is map to a 
 *     winner index number (start from index 0 to n-1).
 *  3) Admin calls draw() to request Chainlink random seed and assign to next 
 *     pending draw event (each draw can be set once), after seeding is done, 
 *     getWinnerByIndex(n) will show the first winner index number:
 *     #1 first-place winner: getWinnerByIndex(0)
 *     #2 second-place winner: getWinnerByIndex(1)
 *     #3 third-place winner: getWinnerByIndex(2)
 *
 */
contract LuckyBox is Adminable, VRFConsumerBaseV2, ReentrancyGuard {
    event DrawCreated(uint256 indexed index, string topic, string content, uint64 poolSize, uint64 winnerSize, uint64 drawTime, uint256 indexed voteBoxPollId, address indexed voteBoxContract);
    event DrawSeeded(uint256 indexed index, uint256 randomSeed);

    // Chainlink VRF, https://docs.chain.link/docs/vrf-contracts/#configurations
    struct VRFRequestConfig {
        uint64 subId;
        uint32 reqGasLimit;
        uint16 reqConfirmations;
    }
    address public vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address public vrfLinkContract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 public vrfKeyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    VRFRequestConfig public vrfConfig;
    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface public LINKTOKEN;
    uint256 public vrfRequestId;

    struct DrawEvent {
        // draw topic name
        string topic;
        // draw content ipfs or link to the content
        string content;
        // hash proof of the ids to wallet mapping data
        string provenance;
        // the pool of all ids
        uint64 poolSize;
        // the pool size for winners
        uint64 winnerSize;
        // reveal the result only after block time is after draw time
        uint64 drawTime;
        // if voting contract poll id is non-zero, enable checking votebox voter address directly
        uint64 voteBoxPollId;
        // linking voting contract (if the draw need to link VoteBox contract)
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
    function testDraw(uint256 _randomSeed) external onlyAdmin {
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
    ) external onlyAdmin {
        require(bytes(_topic).length > 0, "Topic is empty");
        require(_poolSize > 0, "Pool size is zero");
        require(_winnerSize > 0, "Winner size is zero");
        require(_drawTime > 0, "Draw time is zero");

        uint256 _i = eventCount;
        drawEvents[_i].topic = _topic;
        drawEvents[_i].content = _content;
        drawEvents[_i].poolSize = _poolSize;
        drawEvents[_i].winnerSize = _winnerSize;
        drawEvents[_i].drawTime = _drawTime;
        drawEvents[_i].voteBoxPollId = _voteBoxPollId;
        drawEvents[_i].voteBoxContract = IVoteBox(_voteBoxContract);
        eventCount++;

        emit DrawCreated(_i, _topic, _content, _poolSize, _winnerSize, _drawTime, _voteBoxPollId, _voteBoxContract);
    }

    // Calculate prevenance hash with the draw participants' addresses sequence, participants index start from 0
    function setDrawProvenance(uint256 _drawIndex, string memory _proof) external onlyAdmin {
        require(bytes(drawEvents[_drawIndex].provenance).length == 0, "Draw provenance already setup");
        drawEvents[_drawIndex].provenance = _proof;
    }

    // Run next lucky draw (Lucky draw seed will be filled by Chainlink VRF service)
    function draw() external nonReentrant onlyAdmin {
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

    // change draw event VoteBox contract link
    function setVoteBoxData(uint256 _drawIndex, address _voteBoxContract, uint256 _pid) external onlyAdmin{
        require(_existsDraw(_drawIndex), "Draw is not exists");
        require(_voteBoxContract != address(0), "Invalid contract address");
        require(_pid > 0, "Invalid VoteBox poll id");

        drawEvents[_drawIndex].voteBoxContract = IVoteBox(_voteBoxContract);
        drawEvents[_drawIndex].voteBoxPollId = uint64(_pid);
    }

    // get an array of all winner ids
    function getAllWinners(uint256 _drawIndex) public view returns (uint256[] memory) {
        require(_existsDraw(_drawIndex), "Draw is not exists");
        require(_isDrawSeeded(_drawIndex), "Draw is not seeded");

        uint256 drawTime = uint256(drawEvents[_drawIndex].drawTime);
        require(drawTime > 0 && block.timestamp > drawTime, "Draw time is not reached");

        uint256 seed = _drawSeeds[_drawIndex];
        require(seed > 0, "Draw is not seeded");

        // create sequential id pool
        uint256 poolSize = drawEvents[_drawIndex].poolSize;
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
        // when total pool size is smaller than target winner pool size, everyone win!
        uint256 winnerSize = drawEvents[_drawIndex].winnerSize;
        if (poolSize < winnerSize) {
            winnerSize = poolSize;
        }

        // select winners one by one from start index in the shuffled pool
        uint256[] memory winnerIds = new uint256[](winnerSize);
        for (uint256 i = 0; i < winnerSize; i++) {
            winnerIds[i] = ids[i];
        }

        return winnerIds;
    }

    // get winners participants id, ex: winner index 0 is first-place winner, index 1 is second-place winner...
    function getWinnerByIndex(uint256 _drawIndex, uint256 _winnerIndex) external view returns (uint256) {
        require(_existsDraw(_drawIndex), "Draw is not exists");
        require(_isDrawSeeded(_drawIndex), "Draw is not seeded");

        uint256[] memory ids = getAllWinners(_drawIndex);
        return ids[_winnerIndex];
    }

    // get winner voter address (available if draw linked to VoteBox contract) for a draw event with winner index
    function getWinnerVoterAddress(uint256 _drawIndex, uint256 _winnerIndex) external view returns (address) {
        require(_existsDraw(_drawIndex), "Draw is not exists");
        require(_isDrawSeeded(_drawIndex), "Draw is not seeded");

        uint256[] memory ids = getAllWinners(_drawIndex);
        uint256 voterIndex = ids[_winnerIndex];

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
        require (seededEventCount < eventCount, "All draws are seeded");

        // setup the random seed for next draw event (reveal winners)
        uint256 _drawIndex = seededEventCount;
        _drawSeeds[_drawIndex] = _randomSeed;
        emit DrawSeeded(_drawIndex, _randomSeed);

        seededEventCount++;
    }

    // Chainlink VRF Coordinator will call this internal function via rawFulfillRandomWords() public function
    function fulfillRandomWords(uint256 _reqId, uint256[] memory _randomWords) internal override {
        require(_reqId == vrfRequestId, "Invalid VRF request id");

        if (_randomWords[0] > 0) {
            _seed(_randomWords[0]);
        }
    }
    
    // Chainlink VRF change subscription Id
    function changeVRFSubId(uint64 _subId) external onlyAdmin {
        vrfConfig.subId = _subId;
    }

    // Chainlink VRF change Coordinator contract address
    function changeVRFCoordinator(address _contractAddr) external onlyAdmin {
        vrfCoordinator = _contractAddr;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    // Chainlink VRF change LINK token contract address
    function changeVRFLinkToken(address _contractAddr) external onlyAdmin {
        vrfLinkContract = _contractAddr;
        LINKTOKEN = LinkTokenInterface(vrfLinkContract);
    }
    
    // Chainlink VRF change key hash
    function changeVRFKeyHash(bytes32 _keyHash) external onlyAdmin {
        vrfKeyHash = _keyHash;
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

/**
 *******************************************************************************
 * IVoteBox interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-02
 *
 */

pragma solidity ^0.8.7;

interface IVoteBox {
    event PollCreated(uint256 indexed pollId, string topic);
    event PollChangedStartTime(uint256 indexed pollId, uint256 indexed time);
    event PollChangedEndTime(uint256 indexed pollId, uint256 indexed time);
    event Voted(address indexed sender, uint256 indexed pollId, uint256 value);

    // Get total poll count
    function totalPoll() external view returns (uint256);
    // Get poll content
    function getPollTopic(uint256 _pid) external view returns (string memory);
    // Get poll content
    function getPollContent(uint256 _pid) external view returns (string memory);
    // Get poll total options available
    function getPollOptionCount(uint256 _pid) external view returns (uint256);
    // Get poll option name
    function getPollOptionName(uint256 _pid, uint256 _option) external view returns (string memory);
    // Get poll total vote counts
    function getPollTotalVoteCount(uint256 _pid) external view returns (uint256);
    // Get poll total vote score
    function getPollTotalVoteScore(uint256 _pid) external view returns (uint256);
    // Get poll total vote count for an option
    function getPollOptionVoteCount(uint256 _pid, uint256 _option) external view returns (uint256);
    // Get poll total vote score for an option
    function getPollOptionVoteScore(uint256 _pid, uint256 _option) external view returns (uint256);
    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view returns (uint256);
    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view returns (address);
    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view returns (bool);
    // Check voter is on poll allowlist
    function isVoterAllowed(uint256 _pid, bytes calldata _signature) external view returns (bool);
    // Check voter is poll targeted nft holder
    function isVoterTokenOwner(uint256 _pid, address _addr) external returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-27
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides basic multiple admins access control 
 * mechanism, admins are granted exclusive access to specific functions with the 
 * provided modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access for  
 * admins only.
 * 
 */
contract Adminable is Context {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);
    event AdminTransfer(address indexed from, address indexed to);

    // Array of admin addresses
    address[] private _admins;

    // add the first admin with contract creator
    constructor() {
        _createAdmin(_msgSender());
    }

    modifier onlyAdmin() {
        require(_msgSender() != address(0), "Adminable: caller is the zero address");

        bool found = false;
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_msgSender() == _admins[i]) {
                found = true;
            }
        }
        require(found, "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual onlyAdmin returns (bool) {
        for (uint256 i = 0; i < _admins.length; i++) {
          if (addr == _admins[i])
          {
            return true;
          }
        }
        return false;
    }

    function countAdmin() external view virtual returns (uint256) {
        return _admins.length;
    }

    function getAdmin(uint256 _index) external view virtual onlyAdmin returns (address) {
        return _admins[_index];
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        bool existingAdmin = isAdmin(to);

        // approve = true, adding
        // approve = false, removing
        if (approved) {
            require(!existingAdmin, "Adminable: add admin for existing admin");
            _createAdmin(to);

        } else {
            // for safety, prevent removing initial admin
            require(to != _admins[0], "Adminable: can not remove initial admin with setAdmin");

            // remove existing admin
            require(existingAdmin, "Adminable: remove non-existent admin");
            uint256 total = _admins.length;

            // replace current array element with last element, and pop() remove last element
            if (to != _admins[total - 1]) {
                _admins[_adminIndex(to)] = _admins[total - 1];
                _admins.pop();
            } else {
                _admins.pop();
            }

            emit AdminRemoved(to);
        }
    }

    function _adminIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i] && addr != address(0)) {
                return i;
            }
        }
        revert("Adminable: admin index not found");
    }

    function _createAdmin(address addr) internal virtual {
        _admins.push(addr);
        emit AdminCreated(addr);
    }

    /**
     * @dev Transfers message sender admin account to a new address
     */
    function transferAdmin(address to) public virtual onlyAdmin {
        require(to != address(0), "Adminable: address is the zero address");
        
        _admins[_adminIndex(_msgSender())] = to;
        emit AdminTransfer(_msgSender(), to);
    }

    /**
     * @dev Leaves the contract without admin.
     *
     * NOTE: Renouncing the last admin will leave the contract without any admins,
     * thereby removing any functionality that is only available to admins.
     */
    function renounceLastAdmin() public virtual onlyAdmin {
        require(_admins.length == 1, "Adminable: can not renounce admin when there are more than one admins");

        delete _admins;
        emit AdminRemoved(_msgSender());
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