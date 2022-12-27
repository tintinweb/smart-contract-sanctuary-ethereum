/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

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

// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

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

pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

pragma solidity ^0.8.0;

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

pragma solidity ^0.8.16;

contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {

  bool public started = false;
  uint256 public entryFee = 1000000;
  address public teamWallet = 0xbea8B34B57cF13B3AF59E775296a782e50d6C0A4;
  address public NFT;
  mapping (address => Entry[]) public entryMap;
  mapping (uint256 => address[]) public playerMap;
  mapping (uint256 => uint8[5]) public drawMap;
  mapping (uint256 => uint256) public rarityMap;
  uint256 public totalEntries = 0;
  uint16 public currentDrawNumber = 1;
  uint256 public maxBall = 35;
  uint256 public lastDrawBlock = 0;
  uint256 public lastDrawBalance = 100 ether;
  uint256 public dayLength = 7150;
  uint8[] public ballBag;
  uint8[5] public lastDrawBalls;

  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords);

  struct RequestStatus {
      bool fulfilled; // whether the request has been successfully fulfilled
      bool exists; // whether a requestId exists
      uint256[] randomWords;
  }
  mapping(uint256 => RequestStatus)
      public s_requests; /* requestId --> requestStatus */
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId = 7696;

  // past requests Id.
  uint256[] public requestIds;
  uint256 public lastRequestId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
  bytes32 keyHash =
      0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 500000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  /**
   * HARDCODED FOR GOERLI
   * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
   */
  constructor()
      VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
      ConfirmedOwner(msg.sender)
  {
      COORDINATOR = VRFCoordinatorV2Interface(
          0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
      );
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords(uint32 numWords)
      external
      onlyOwner
      returns (uint256 requestId)
  { 
      // Pause draw
      started = false;
      // Will revert if subscription is not set and funded.
      requestId = COORDINATOR.requestRandomWords(
          keyHash,
          s_subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          numWords
      );
      s_requests[requestId] = RequestStatus({
          randomWords: new uint256[](0),
          exists: true,
          fulfilled: false
      });
      requestIds.push(requestId);
      lastRequestId = requestId;
      emit RequestSent(requestId, numWords);
      return requestId;
  }

  function fulfillRandomWords(
      uint256 _requestId,
      uint256[] memory _randomWords
  ) internal override {
      require(s_requests[_requestId].exists, "request not found");
      s_requests[_requestId].fulfilled = true;
      s_requests[_requestId].randomWords = _randomWords;
      emit RequestFulfilled(_requestId, _randomWords);
  }

  function getRequestStatus(
      uint256 _requestId
  ) external view returns (bool fulfilled, uint256[] memory randomWords) {
      require(s_requests[_requestId].exists, "request not found");
      RequestStatus memory request = s_requests[_requestId];
      return (request.fulfilled, request.randomWords);
  }

  struct Entry {
    uint16 drawNumber;
    uint8 ball1;
    uint8 ball2;
    uint8 ball3;
    uint8 ball4;
    uint8 ball5;
  }

  function flipSwitch() external onlyOwner {
    started = !started;
  }

  function sort(uint8[5] memory data) internal pure returns (uint8[5] memory) {
    uint length = data.length;
    for (uint i = 1; i < length; i++) {
      uint8 key = data[i];
      int j = int(i) - 1;
      while ((int(j) >= 0) && (data[uint(j)] > key)) {
        data[uint(j + 1)] = data[uint(j)];
        j--;
      }
      data[uint(j + 1)] = key;
    }
    return data;
  }

  function randomBalls() internal {
    uint8[5] memory balls;

    for (uint8 i = 1; i <= maxBall; i++) {
      ballBag.push(i);
    }

    for (uint8 j = 0; j < 5; j++) {
      uint256 index = s_requests[lastRequestId].randomWords[j] % ballBag.length;
      uint8 ball = ballBag[index];
      ballBag[index] = ballBag[ballBag.length - 1];
      ballBag.pop();
      balls[j] = ball;
    }

    lastDrawBalls = sort(balls);
    delete ballBag;
  }

  function randomPlayer(uint rand) internal view returns (address player) {
    player = playerMap[currentDrawNumber][rand];
    return player;
  }

  function validateBalls(uint8 ball1, uint8 ball2, uint8 ball3, uint8 ball4, uint8 ball5) internal view {
    require(ball1!=ball2, 'Balls must all be unique');
    require(ball1!=ball3, 'Balls must all be unique');
    require(ball1!=ball4, 'Balls must all be unique');
    require(ball1!=ball5, 'Balls must all be unique');
    require(ball2!=ball3, 'Balls must all be unique');
    require(ball2!=ball4, 'Balls must all be unique');
    require(ball2!=ball5, 'Balls must all be unique');
    require(ball3!=ball4, 'Balls must all be unique');
    require(ball3!=ball5, 'Balls must all be unique');
    require(ball4!=ball5, 'Balls must all be unique');
    require(ball5>ball4, 'Balls must be in ascending order');
    require(ball4>ball3, 'Balls must be in ascending order');
    require(ball3>ball2, 'Balls must be in ascending order');
    require(ball2>ball1, 'Balls must be in ascending order');
    require(ball1>0, 'Balls must not be 0');
    require(ball5<=maxBall, 'Balls must be less or equal to than maxBall');
  }

  function enter(uint8 ball1, uint8 ball2, uint8 ball3, uint8 ball4, uint8 ball5) external payable {
    require(started, 'Game not started');
    require(msg.value >= entryFee, 'Entry fee is too low');
    validateBalls(ball1, ball2, ball3, ball4, ball5);
    entryMap[msg.sender].push(Entry(currentDrawNumber, ball1, ball2, ball3, ball4, ball5));
    playerMap[currentDrawNumber].push(msg.sender);
    totalEntries++;
  }

  function enterWithNFT(uint8[] memory balls, uint256 tokenId) external payable {
    require(started, 'Game not started');
    require(IERC721(NFT).ownerOf(tokenId) == msg.sender, 'Not the owner of specified tokenId');
    require(msg.value >= entryFee, 'Entry fee is too low');
    require(balls.length % 5 == 0, 'Number of balls is not a multiple of 5');
    require(balls.length / 5 <= rarityMap[tokenId], 'More entries than allowed for tokenId');

    for (uint256 i = 0; i < balls.length; i+=5) {
      uint8 ball1 = balls[i];
      uint8 ball2 = balls[i+1];
      uint8 ball3 = balls[i+2];
      uint8 ball4 = balls[i+3];
      uint8 ball5 = balls[i+4];
      validateBalls(ball1, ball2, ball3, ball4, ball5);
      entryMap[msg.sender].push(Entry(currentDrawNumber, ball1, ball2, ball3, ball4, ball5));
      totalEntries++;
    }
    
    playerMap[currentDrawNumber].push(msg.sender);
  }

  function getEntry(address player, uint256 id) external view returns(uint256[6] memory entry) {
    uint256 drawNumber = entryMap[player][id].drawNumber;
    entry[0] = drawNumber;
    uint256 ball1 = entryMap[player][id].ball1;
    entry[1] = ball1;
    uint256 ball2 = entryMap[player][id].ball2;
    entry[2] = ball2;
    uint256 ball3 = entryMap[player][id].ball3;
    entry[3] = ball3;
    uint256 ball4 = entryMap[player][id].ball4;
    entry[4] = ball4;
    uint256 ball5 = entryMap[player][id].ball5;
    entry[5] = ball5;
    return entry;
  }

  function drawT1A() internal {
    uint256 balance = address(this).balance;
    address T1Awinner = randomPlayer(1);
    payable(T1Awinner).transfer(balance / 100);
  }

  function drawR1A() internal {
    uint256 balance = address(this).balance - lastDrawBalance;
    address R1Awinner = randomPlayer(2);
    payable(R1Awinner).transfer(balance / 100);
  }

  function payTeam() internal {
    uint256 balance = address(this).balance;
    payable(teamWallet).transfer(balance / 50);
  }

  function draw() external returns (uint8[5] memory balls) {
    require(block.number >= lastDrawBlock + dayLength, 'Less than 1 day has passed');
    
    drawT1A();
    drawR1A();
    payTeam();
    randomBalls();

    drawMap[currentDrawNumber] = lastDrawBalls;
    lastDrawBlock = block.number;
    lastDrawBalance = address(this).balance;
    currentDrawNumber++;
    return balls;
  }

  function claim(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
    lastDrawBalance = address(this).balance;
  }

  function setMaxBall(uint256 _maxBall) external onlyOwner {
    maxBall = _maxBall;
  }

  function setDayLength(uint256 _dayLength) external onlyOwner {
    dayLength = _dayLength;
  }

  function setNFT(address _address) external onlyOwner {
    NFT = _address;
  }

  function setRarities(uint256[] memory tokenIds, uint256[] memory rarities) external onlyOwner {
    require(tokenIds.length == rarities.length, 'Arrays of different lengths');

    for (uint256 i; i < tokenIds.length; i++) {
      rarityMap[tokenIds[i]] = rarities[i];
    }
  }

}