// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RNGChainlinkV2Interface} from "../interfaces/RNGChainlinkV2Interface.sol";

contract RNGChainlinkV2 is RNGChainlinkV2Interface, VRFConsumerBaseV2, Ownable {
    /* ============ Global Variables ============ */

    address public s_manager;

    /// @dev Reference to the VRFCoordinatorV2 deployed contract
    VRFCoordinatorV2Interface internal vrfCoordinator;

    /// @dev A counter for the number of requests made used for request ids
    uint32 internal requestCounter;

    /// @dev Chainlink VRF subscription id
    uint64 internal subscriptionId;

    /// @dev Hash of the public key used to verify the VRF proof
    bytes32 internal keyHash;

    /// @dev A list of random numbers from past requests mapped by request id
    mapping(uint32 => uint256) internal randomNumbers;

    /// @dev A list of blocks to be locked at based on past requests mapped by request id
    mapping(uint32 => uint32) internal requestLockBlock;

    /// @dev A mapping from Chainlink request ids to internal request ids
    mapping(uint256 => uint32) internal chainlinkRequestIds;

    /* ============ Events ============ */

    /**
     * @notice Emitted when the Chainlink VRF keyHash is set
     * @param keyHash Chainlink VRF keyHash
     */
    event KeyHashSet(bytes32 keyHash);

    /**
     * @notice Emitted when the Chainlink VRF subscription id is set
     * @param subscriptionId Chainlink VRF subscription id
     */
    event SubscriptionIdSet(uint64 subscriptionId);

    /**
     * @notice Emitted when the Chainlink VRF Coordinator address is set
     * @param vrfCoordinator Address of the VRF Coordinator
     */
    event VrfCoordinatorSet(VRFCoordinatorV2Interface indexed vrfCoordinator);

    /* ============ Constructor ============ */

    /**
     * @notice Constructor of the contract
     * @param _vrfCoordinator Address of the VRF Coordinator
     * @param _subscriptionId Chainlink VRF subscription id
     * @param _keyHash Hash of the public key used to verify the VRF proof
     */
    constructor(
        VRFCoordinatorV2Interface _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(address(_vrfCoordinator)) {
        _setVRFCoordinator(_vrfCoordinator);
        _setSubscriptionId(_subscriptionId);
        _setKeyhash(_keyHash);
    }

    modifier onlyManager() {
        require(
            msg.sender == s_manager,
            "Manager: Only manager contract can call this function"
        );
        _;
    }

    /* ============ External Functions ============ */

    function requestRandomNumber()
        external
        override
        returns (uint32 requestId, uint32 lockBlock)
    {
        uint256 _vrfRequestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            1000000,
            1
        );

        requestCounter++;
        uint32 _requestCounter = requestCounter;

        requestId = _requestCounter;
        chainlinkRequestIds[_vrfRequestId] = _requestCounter;

        lockBlock = uint32(block.number);
        requestLockBlock[_requestCounter] = lockBlock;

        emit RandomNumberRequested(_requestCounter, msg.sender);
    }

    function isRequestComplete(uint32 _internalRequestId)
        external
        view
        override
        returns (bool isCompleted)
    {
        return randomNumbers[_internalRequestId] != 0;
    }

    function randomNumber(uint32 _internalRequestId)
        external
        view
        override
        returns (uint256 randomNum)
    {
        return randomNumbers[_internalRequestId];
    }

    function getLastRequestId()
        external
        view
        override
        returns (uint32 requestId)
    {
        return requestCounter;
    }

    function getRequestFee()
        external
        pure
        override
        returns (address feeToken, uint256 requestFee)
    {
        return (address(0), 0);
    }

    function getKeyHash() external view override returns (bytes32) {
        return keyHash;
    }

    function getSubscriptionId() external view override returns (uint64) {
        return subscriptionId;
    }

    function getVrfCoordinator()
        external
        view
        override
        returns (VRFCoordinatorV2Interface)
    {
        return vrfCoordinator;
    }

    function setSubscriptionId(uint64 _subscriptionId)
        external
        override
        onlyOwner
    {
        _setSubscriptionId(_subscriptionId);
    }

    function setKeyhash(bytes32 _keyHash) external override onlyOwner {
        _setKeyhash(_keyHash);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Callback function called by VRF Coordinator
     * @dev The VRF Coordinator will only call it once it has verified the proof associated with the randomness.
     * @param _vrfRequestId Chainlink VRF request id
     * @param _randomWords Chainlink VRF array of random words
     */
    function fulfillRandomWords(
        uint256 _vrfRequestId,
        uint256[] memory _randomWords
    ) internal override {
        uint32 _internalRequestId = chainlinkRequestIds[_vrfRequestId];
        require(_internalRequestId > 0, "RNGChainLink/requestId-incorrect");

        uint256 _randomNumber = _randomWords[0];
        randomNumbers[_internalRequestId] = _randomNumber;

        emit RandomNumberCompleted(_internalRequestId, _randomNumber);
    }

    /**
     * @notice Set Chainlink VRF coordinator contract address.
     * @param _vrfCoordinator Chainlink VRF coordinator contract address
     */
    function _setVRFCoordinator(VRFCoordinatorV2Interface _vrfCoordinator)
        internal
    {
        require(
            address(_vrfCoordinator) != address(0),
            "RNGChainLink/vrf-not-zero-addr"
        );
        vrfCoordinator = _vrfCoordinator;
        emit VrfCoordinatorSet(_vrfCoordinator);
    }

    /**
     * @notice Set Chainlink VRF subscription id associated with this contract.
     * @param _subscriptionId Chainlink VRF subscription id
     */
    function _setSubscriptionId(uint64 _subscriptionId) internal {
        require(_subscriptionId > 0, "RNGChainLink/subId-gt-zero");
        subscriptionId = _subscriptionId;
        emit SubscriptionIdSet(_subscriptionId);
    }

    function setManager(address _manager) public onlyOwner {
        s_manager = _manager;
    }

    /**
     * @notice Set Chainlink VRF keyHash.
     * @param _keyHash Chainlink VRF keyHash
     */
    function _setKeyhash(bytes32 _keyHash) internal {
        require(_keyHash != bytes32(0), "RNGChainLink/keyHash-not-empty");
        keyHash = _keyHash;
        emit KeyHashSet(_keyHash);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {RNGInterface} from "./RNGInterface.sol";

/**
 * @title RNG Chainlink V2 Interface
 * @notice Provides an interface for requesting random numbers from Chainlink VRF V2.
 */
interface RNGChainlinkV2Interface is RNGInterface {
    /**
     * @notice Get Chainlink VRF keyHash associated with this contract.
     * @return bytes32 Chainlink VRF keyHash
     */
    function getKeyHash() external view returns (bytes32);

    /**
     * @notice Get Chainlink VRF subscription id associated with this contract.
     * @return uint64 Chainlink VRF subscription id
     */
    function getSubscriptionId() external view returns (uint64);

    /**
     * @notice Get Chainlink VRF coordinator contract address associated with this contract.
     * @return address Chainlink VRF coordinator address
     */
    function getVrfCoordinator()
        external
        view
        returns (VRFCoordinatorV2Interface);

    /**
     * @notice Set Chainlink VRF keyHash.
     * @dev This function is only callable by the owner.
     * @param keyHash Chainlink VRF keyHash
     */
    function setKeyhash(bytes32 keyHash) external;

    /**
     * @notice Set Chainlink VRF subscription id associated with this contract.
     * @dev This function is only callable by the owner.
     * @param subscriptionId Chainlink VRF subscription id
     */
    function setSubscriptionId(uint64 subscriptionId) external;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

/**
 * @title Random Number Generator Interface
 * @notice Provides an interface for requesting random numbers from 3rd-party RNG services (Chainlink VRF, Starkware VDF, etc..)
 */
interface RNGInterface {
    /**
     * @notice Emitted when a new request for a random number has been submitted
     * @param requestId The indexed ID of the request used to get the results of the RNG service
     * @param sender The indexed address of the sender of the request
     */
    event RandomNumberRequested(
        uint32 indexed requestId,
        address indexed sender
    );

    /**
     * @notice RNG Request
     * @param id          RNG request ID
     * @param lockBlock   Block number that the RNG request is locked
     * @param requestedAt Time when RNG is requested
     */
    struct RngRequest {
        uint32 id;
        uint32 lockBlock;
        uint64 requestedAt;
    }

    /**
     * @notice Emitted when an existing request for a random number has been completed
     * @param requestId The indexed ID of the request used to get the results of the RNG service
     * @param randomNumber The random number produced by the 3rd-party service
     */
    event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

    /**
     * @notice Gets the last request id used by the RNG service
     * @return requestId The last request id used in the last request
     */
    function getLastRequestId() external view returns (uint32 requestId);

    /**
     * @notice Gets the Fee for making a Request against an RNG service
     * @return feeToken The address of the token that is used to pay fees
     * @return requestFee The fee required to be paid to make a request
     */
    function getRequestFee()
        external
        view
        returns (address feeToken, uint256 requestFee);

    /**
     * @notice Sends a request for a random number to the 3rd-party service
     * @dev Some services will complete the request immediately, others may have a time-delay
     * @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
     * @return requestId The ID of the request used to get the results of the RNG service
     * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
     * The calling contract should "lock" all activity until the result is available via the `requestId`
     */
    function requestRandomNumber()
        external
        returns (uint32 requestId, uint32 lockBlock);

    /**
     * @notice Checks if the request for randomness from the 3rd-party service has completed
     * @dev For time-delayed requests, this function is used to check/confirm completion
     * @param requestId The ID of the request used to get the results of the RNG service
     * @return isCompleted True if the request has completed and a random number is available, false otherwise
     */
    function isRequestComplete(uint32 requestId)
        external
        view
        returns (bool isCompleted);

    /**
     * @notice Gets the random number produced by the 3rd-party service
     * @param requestId The ID of the request used to get the results of the RNG service
     * @return randomNum The random number
     */
    function randomNumber(uint32 requestId)
        external
        returns (uint256 randomNum);
}