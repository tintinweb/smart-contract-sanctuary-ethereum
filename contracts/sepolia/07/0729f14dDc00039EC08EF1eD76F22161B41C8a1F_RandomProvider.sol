// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import "./interfaces/IRandomProvider.sol";
import "./interfaces/IBabylon7Core.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title RandomProvider
/// @notice RandomProvider is dedicated to interactions with the Chainlink VRF service and storage of
/// random requests data corresponding to listings from Babylon7Core
/// @dev RandomProvider inherits VRFConsumerBaseV2 contract and IRandomProvider interface.
contract RandomProvider is IRandomProvider, VRFConsumerBaseV2 {
    /// @dev Babylon7Core for accepting requests and pushing results
    IBabylon7Core public immutable core;
    /// @dev VRF coordinator for making requests
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    /// @dev VRF subscription identifier
    uint64 public immutable subscriptionId;
    /// @dev VRF gas price limiter key hash
    bytes32 public immutable keyHash;

    /// @dev requestId => requestStatus
    mapping(uint256 => RequestStatus) public requests;

    uint32 private constant CALLBACK_GAS_LIMIT = 500000;
    uint16 private constant REQUEST_CONFIRMATIONS = 20;
    uint16 private constant NUM_WORDS = 1;

    /// @dev Storage struct that contains info about random request
    struct RequestStatus {
        /// @dev Whether a requestId exists
        bool exists;
        /// @dev Timestamp of a request
        uint256 requestTimestamp;
        /// @dev To which listing a request corresponds
        uint256 listingId;
    }

    /// @notice Emitted when a random request is fulfilled by the Chainlink VRF
    /// @param requestId identifier of a random request
    /// @param listingId identifier of a listing
    /// @param randomWords array of acquired random words
    event RequestFulfilled(uint256 requestId, uint256 listingId, uint256[] randomWords);

    /// @notice Emitted when a random request is sent to the VRF coordinator
    /// @param requestId identifier of a random request
    /// @param listingId identifier of a listing
    event RequestSent(uint256 requestId, uint256 listingId);

    error OnlyBabylon7Core();
    error RequestIdNotFound();

    constructor(
        IBabylon7Core core_,
        address vrfCoordinator_,
        uint64 subscriptionId_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        core = core_;
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
    }

    /// @notice Accepts random words for a request and pushes the result to the Babylon7Core
    /// @dev inherited from VRFConsumerBaseV2
    /// @param _requestId identifier of a request
    /// @param _randomWords an array of random words
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (!requests[_requestId].exists) revert RequestIdNotFound();
        core.resolveWinner(requests[_requestId].listingId, _randomWords[0]);
        emit RequestFulfilled(_requestId, requests[_requestId].listingId, _randomWords);
    }

    /// @inheritdoc IRandomProvider
    function isRequestOverdue(uint256 requestId) external view override returns (bool) {
        return (block.timestamp > requests[requestId].requestTimestamp + 1 days);
    }

    /// @inheritdoc IRandomProvider
    function requestRandom(uint256 listingId) external override returns (uint256 requestId) {
        if (msg.sender != address(core)) revert OnlyBabylon7Core();

        requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        requests[requestId] = RequestStatus({exists: true, requestTimestamp: block.timestamp, listingId: listingId});
        emit RequestSent(requestId, listingId);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IBabylon7Core {
    /// @dev Indicates type of a token
    enum ItemType {
        ERC721,
        ERC1155
    }

    /// @dev Storage struct that contains all information about raffled token
    struct ListingItem {
        /// @dev Type of a token
        ItemType itemType;
        /// @dev Address of a token
        address token;
        /// @dev Token identifier
        uint256 identifier;
        /// @dev Amount of tokens
        uint256 amount;
    }

    /// @dev Indicates state of a listing
    enum ListingState {
        Active,
        Resolving,
        Successful,
        Finalized,
        Canceled
    }

    /// @dev Storage struct that contains all required information for a specific listing
    struct ListingInfo {
        /// @dev Token that is provided for a raffle
        ListingItem item;
        /// @dev Indicates current state of a listing
        ListingState state;
        /// @dev Address of a listing creator
        address creator;
        /// @dev Address of a listing winner
        address winner;
        /// @dev ETH price per 1 ticket
        uint256 price;
        /// @dev Timestamp when listing starts
        uint256 timeStart;
        /// @dev Total amount of tickets to be sold
        uint256 totalTickets;
        /// @dev Current amount of sold tickets
        uint256 currentTickets;
        /// @dev Basis points of donation
        uint256 donationBps;
        /// @dev Requiest id from Chainlink VRF
        uint256 randomRequestId;
        /// @dev Timestamp of creation
        uint256 creationTimestamp;
    }

    /// @dev Storage struct that contains all restriction for a specific listing
    struct ListingRestrictions {
        /// @dev Root of an allowlist Merkle tree
        bytes32 allowlistRoot;
        /// @dev Amount of tickets reserved for an allowlist
        uint256 reserved;
        /// @dev Amount of tickets bought by allowlisted users
        uint256 mintedFromReserve;
        /// @dev Amount of maximum tickets per 1 address
        uint256 maxPerAddress;
    }

    /// @notice Determines the winner of a raffle based on the provided random number, then transfers
    /// the item to the winner
    /// @dev called by the Chainlink VRF service only through the Random Provider contract
    /// @param id identifier of a listing
    /// @param random a random number provided by the Chainlink VRF
    function resolveWinner(uint256 id, uint256 random) external;

    /// @notice Returns all info about a listing with a specific id
    /// @param id identifier of a listing
    /// @return ListingInfo struct for a listing
    function getListingInfo(uint256 id) external view returns (ListingInfo memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IRandomProvider {
    /// @notice Returns whether the request is overdue or not
    /// @param requestId identifier of a request
    /// @return boolean whether the request is overdue or not
    function isRequestOverdue(uint256 requestId) external view returns (bool);

    /// @notice Makes a random number request to the Chainlink VRF Coordinator
    /// @dev the overdue criteria is whether 24 hours passed
    /// @param listingId identifier of a listing
    /// @return requestId identifier of a request
    function requestRandom(uint256 listingId) external returns (uint256);
}