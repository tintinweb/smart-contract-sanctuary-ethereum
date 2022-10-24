// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "../Schema.sol";
import "../Interfaces/ICanvas.sol";
import "./VRF.sol";

contract CanvasKeeper is KeeperCompatibleInterface {
  address public canvasAddress;
  address public vrfAddress;

  constructor(address _canvasAddress, address _vrfAddress) {
    canvasAddress = _canvasAddress;
    vrfAddress = _vrfAddress;
  }

  function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
    uint256 canvasId = abi.decode(checkData, (uint256));
    Schema.VRFHelper memory info = ICanvas(canvasAddress).getVRFHelper(canvasId);

    if (
      !info.vrfPending &&
      info.tokenIdCounter - info.randomizedTraitsCounter > 0 &&
      info.vrfLastRunTimestamp + (info.vrfMinuteInterval * 60) < block.timestamp
    ) {
      return (true, checkData);
    } else return (false, '');
  }

  function performUpkeep(bytes calldata performData) external override {
    uint256 canvasId = abi.decode(performData, (uint256));
    Schema.VRFHelper memory info = ICanvas(canvasAddress).getVRFHelper(canvasId);

    if (
      !info.vrfPending &&
      info.tokenIdCounter - info.randomizedTraitsCounter > 0 &&
      info.vrfLastRunTimestamp + (info.vrfMinuteInterval * 60) < block.timestamp
    ) {
      CanvasVRF(vrfAddress).requestVRF(canvasId);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

// ! => Immutable once canvas approved
// * => Immutable once isImmutable true
library Schema {
  struct ContractInfo {
    address daoAddress;
    address newDaoRequest;
    address curatorAddress;
    address newCuratorRequest;
    address canvasAddress;
    address licenseRegistryAddress;
    address tokenRegistryAddress;
    address vrfAddress;
    address keeperAddress;
    address keeperRegistrarAddress;
    address linkTokenAddress;
    address collectionContractAddress;
    address canvasOneAddress;
    address canvasOneCuratedAddress;
    address payable protocolFeeRecipient;
    uint256 protocolFeeBps;
    uint256 protocolDutchRefundFeeBps;
    uint256 canvasCounter;
    uint256 canvasCuratedCounter;
    uint256 canvasOpenCounter;
    uint256 canvasOneCounter;
    uint256 canvasOneCuratedCounter;
    bool openCanvas;
    bool openCanvasOne;
  }

  struct Canvas {
    address admin;
    string name;                  // !
    string symbol;                // !
    string description;
    string thumbnailUri;          // !
    string baseUri;               // !
    string collectionUri;
    string externalUrl;
    address saleToken;
    uint256 salePrice;
    uint256 dutchEndPrice;
    uint256 dutchEndTime;
    uint256 totalQuantity;
    uint256 bulkMax;
    uint256 walletMax;
    uint256 mintPassPerQuantity;
    uint256 vrfMinuteInterval;
    uint256 saleStart;
    uint256 saleEnd;
    address payable feeRecipient;
    bytes32 merkleRoot;
    uint16 feeBps;                 // *
    bool externalUrlSlash;
    bool soulbound;                // !
    bool editioned;                // *
    bool requireOwnership;         // *
    bool requireLicense;           // *
    bool randomizeTraits;          // !
    bool isOne;                    // !
    bool restrictToAllowList;
    bool presaleActive;
    bool saleActive;
    bool queueActive;
    bool refundableDutch;
    bool reserveAuction;
    bool restrictRefAddress;       // *
    bool restrictRefOverride;      // *
    bool requireOwnershipOverride; // *
    bool customizeAudio;           // *
    bool customizeText;            // *
    bool customizeArt;             // *
    bool customizeFile;            // *
    bool customizeOther;           // *
    bool isImmutable;              // ! *
    bool unlockRequest;
  }

  struct CanvasAsset {
    string thumbnailUri;
    string baseUri;
  }

  struct CanvasTraits {
    string urlParam;
    string trait;
    string[] values;
    uint256[] chancesOrQuantity;
    uint256[] selectedQuantity;
    uint256[] traitPremiumPrice;
    uint16 traitsChance;
    bool selectable;
    bool selectableQuantity;
    bool premiumPricing;
  }

  struct CanvasSystem {
    address newAdminRequest;
    uint256 tokenIdCounter;
    uint256 randomizedTraitsCounter;
    uint256 vrfLastRunTimestamp;
    uint256 revenue;
    uint256 refundSum;
    uint256 dutchEndPrice;
    uint256 protocolFeeBps;
    uint256 protocolDutchRefundFeeBps;
    bool isCurated;
    bool vrfPending;
    bool approved;
    bool auctionPayout;
    bool expiredRefunded;
    bool oneMinted;
  }

  struct MintPasses {
    uint256 chainId;
    address tokenAddress;
    uint256 tokenIdLow;
    uint256 tokenIdHigh;
  }

  struct MintPassToken {
    uint256 chainId;
    address tokenAddress;
    uint256 tokenId;
    uint256 quantity;
  }

  struct MintRequest {
    address mintTo;
    uint256 quantity;
    uint256 allowance;
    uint256 queueTime;
    bytes32[] proof;
    uint256[] selectedTraits;
    MintPassToken[] mintPassTokens;
    string[] purchaseIdentifiers;
  }

  struct Partnership {
    uint256 discountBps;
    uint256 allocation;
    uint256 mintCounter;
  }

  struct PurchaseTracker {
    uint256 quantity;
    uint256 spend;
    bool refundClaimed;
  }

  struct Bid {
    address payable bidder;
    uint256 value;
    uint256 timestamp;
  }

  struct RandomTraits {
    uint256 randomizedAtTokenId;
    uint256 randomWord;
  }

  struct TokenRef {
    uint256 chainId;
    address tokenAddress;
    uint256 tokenId;
    string contentType;
    bool useRepo;
  }

  struct Customization {
    uint256 assetVersion; // 0 is latest version, 1 is first version
    TokenRef[] refs;
    string title;
    string subtitle;
    uint256[] selectedTraits; // Immutable upon mint
    string purchaseIdentifier; // Immutable upon mint
  }

  struct VRFHelper {
    address admin;
    bool vrfPending;
    uint256 tokenIdCounter;
    uint256 randomizedTraitsCounter;
    uint256 vrfLastRunTimestamp;
    uint256 vrfMinuteInterval;
  }

  struct Storage {
    uint256 reentrancyStatus;
    string externalBaseUrl;

    ContractInfo contractInfo;

    mapping (address => bool) erc20AllowList;

    mapping (uint256 => address) canvasToCollection;
    mapping (address => uint256) collectionToCanvas;

    // canvasId => config
    mapping (uint256 => Canvas) canvas;
    mapping (uint256 => CanvasAsset[]) canvasAssets;
    mapping (uint256 => CanvasTraits[]) canvasTraits; // !
    mapping (uint256 => CanvasSystem) canvasSystem;
    mapping (uint256 => MintPasses[]) mintPassTokens;
    mapping (uint256 => address[]) creators;
    mapping (uint256 => address[]) allowedRefs;

    // canvasId => partner address => discount bps
    mapping (uint256 => mapping (address => Partnership)) partners;

    // canvasId => system vars
    mapping (uint256 => RandomTraits[]) randomizedTraits;
    mapping (uint256 => Bid[]) bids;

    // canvasId => purchaser address => tracker
    mapping (uint256 => mapping (address => PurchaseTracker)) purchaseTracker;
    // canvasId => chainId => mint pass contract => token id => quantity
    mapping (uint256 => mapping (uint256 => mapping (address => mapping (uint256 => uint256)))) mintPassTracker;

    // contract => tokenId => customization
    mapping (address => mapping (uint256 => Customization)) customization;

    // canvasOneTokenId => canvasId
    mapping (uint256 => uint256) canvasOne;
    mapping (uint256 => uint256) canvasOneCurated;

    mapping(address => uint256) nonces;

    bytes32 _CACHED_DOMAIN_SEPARATOR;
    uint256 _CACHED_CHAIN_ID;
    address _CACHED_THIS;

    bytes32 _HASHED_NAME;
    bytes32 _HASHED_VERSION;
    bytes32 _TYPE_HASH;
  }
}


error AlreadyClaimed();
error AlreadyMinted();
error AlreadyApproved();
error AlreadyPaid();
error AuctionEnded();
error AuctionUnpaid();
error CanvasOneDisabled();
error CanvasOpenDisabled();
error CanvasCuratedDisabled();
error ExistingSubscription();
error InsufficientBalance();
error InvalidAllowlist();
error InvalidFee();
error InvalidInput();
error InvalidLicense();
error InvalidOwner();
error InvalidQuantity();
error InvalidReference();
error InvalidSignature();
error InvalidTime();
error InvalidToken();
error InvalidTraits();
error NoPermission();
error NonTransferable();
error NotLinkToken();
error NotOnAuction();
error NotQueued();
error OverAllowance(uint256 allowance);
error OverMintLimit(uint256 mintLimit);
error PaymentError();
error RegistryError();
error ReserveNotMet();
error SaleInactive();
error SaleOngoing();
error SoldOut();
error TraitUnavailable();
error TraitsImmutable();
error TokenDisabled();
error TenPercentAboveBidNotMet();
error VRFNotNeeded();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../Schema.sol";

interface ICanvas {
  /// @notice Gets DAO's address
  function daoAddress() external view returns (address daoAddress);

  function setVrfResult(
    uint256 canvasId,
    uint256 vrfResult,
    string memory action
  ) external;

  function contractInfo() external view returns (Schema.ContractInfo memory info);

  function getVRFHelper(uint256 canvasId) external view returns (Schema.VRFHelper memory info);

  function tokenURI(address collectionAddress, uint256 tokenId) external view returns (string memory);

  function getCanvasId(
    address collectionAddress,
    uint256 tokenId
  ) external view returns (
    uint256 canvasId
  );

  function getCreators(
    uint256 canvasId
  ) external view returns (
    address[] memory creators
  );

  function royaltyInfo(
    address collectionAddress,
    uint256 tokenId,
    uint256 value
  ) external view returns (
    address recipient,
    uint256 amount
  );

  function checkTransfer(
    address collectionAddress,
    address from,
    address to,
    uint256 tokenId
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "../Schema.sol";
import "../Interfaces/ICanvas.sol";

contract CanvasVRF is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface public vrfCoordinator;
  LinkTokenInterface public linkToken;
  bytes32 public keyHash;

  address public deployerAddress;
  address public canvasAddress;
  address public keeperRegistrarAddress;
  address public keeperAddress;

  mapping (uint256 => uint64) public canvasIdToSubscriptionId;
  mapping(uint256 => uint256) public vrfToCanvasId;

  constructor(
    address _canvasAddress,
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    address _keeperRegistrarAddress
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    canvasAddress = _canvasAddress;
    vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    linkToken = LinkTokenInterface(_linkToken);
    keyHash = _keyHash;
    keeperRegistrarAddress = _keeperRegistrarAddress;
  }

  function setKeeperAddress(address _keeperAddress) external {
    if (msg.sender != ICanvas(canvasAddress).contractInfo().daoAddress) revert NoPermission();
    keeperAddress = _keeperAddress;
  }

  function createNewSubscription(uint256 canvasId) external {
    if (msg.sender != ICanvas(canvasAddress).getVRFHelper(canvasId).admin) revert NoPermission();
    if (canvasIdToSubscriptionId[canvasId] != 0) revert ExistingSubscription();

    canvasIdToSubscriptionId[canvasId] = vrfCoordinator.createSubscription();
    vrfCoordinator.addConsumer(canvasIdToSubscriptionId[canvasId], address(this));
  }

  function cancelSubscription(uint256 canvasId) external {
    address admin = ICanvas(canvasAddress).getVRFHelper(canvasId).admin;
    if (msg.sender != admin) revert NoPermission();

    canvasIdToSubscriptionId[canvasId] = 0;
    vrfCoordinator.cancelSubscription(canvasIdToSubscriptionId[canvasId], admin);
  }

  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes memory data
  ) public {
    (bytes32 callType, uint256 canvasId) = abi.decode(data, (bytes32, uint256));
    if (msg.sender != address(linkToken)) revert NotLinkToken();
    if (sender != ICanvas(canvasAddress).getVRFHelper(canvasId).admin) revert NoPermission();

    if (callType == bytes32('fundVrf'))
      linkToken.transferAndCall(address(vrfCoordinator), amount, abi.encode(canvasIdToSubscriptionId[canvasId]));
    else if (callType == bytes32('automateVrf')) {
      uint8 source = 110;

      bytes memory callData = abi.encodeWithSelector(
        bytes4(keccak256("register(string,bytes,address,uint32,address,bytes,uint96,uint8,address)")),
        "CanvasKeeper",
        hex"",
        keeperAddress,
        uint32(300000),
        sender,
        abi.encode(canvasId),
        uint96(amount),
        source,
        address(this)
      );

      linkToken.transferAndCall(keeperRegistrarAddress, amount, callData);
    }
  }

  function resetVRF(uint256 canvasId) external {
    if (msg.sender != ICanvas(canvasAddress).getVRFHelper(canvasId).admin) revert NoPermission();

    ICanvas(canvasAddress).setVrfResult(canvasId, 0, "reset");
  }

  // Called by public or keeper
  function requestVRF(uint256 canvasId) external {
    Schema.VRFHelper memory info = ICanvas(canvasAddress).getVRFHelper(canvasId);

    if (info.vrfPending ||
        info.tokenIdCounter - info.randomizedTraitsCounter == 0 ||
        info.vrfLastRunTimestamp + (info.vrfMinuteInterval * 60) > block.timestamp)
      revert VRFNotNeeded();

    uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, canvasIdToSubscriptionId[canvasId], 7, 300000, 1);

    vrfToCanvasId[requestId] = canvasId;
    ICanvas(canvasAddress).setVrfResult(canvasId, 0, "requested");
  }

  // Chainlink VRF Callback
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    uint256 canvasId = vrfToCanvasId[requestId];
    ICanvas(canvasAddress).setVrfResult(canvasId, randomWords[0], "fulfilled");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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