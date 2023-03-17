// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

import "../interfaces/INXMMaster.sol";
import "../interfaces/IMasterAwareV2.sol";
import "../interfaces/IMemberRoles.sol";

abstract contract MasterAwareV2 is IMasterAwareV2 {

  INXMMaster public master;

  mapping(uint => address payable) public internalContracts;

  modifier onlyMember {
    require(
      IMemberRoles(internalContracts[uint(ID.MR)]).checkRole(
        msg.sender,
        uint(IMemberRoles.Role.Member)
      ),
      "Caller is not a member"
    );
    _;
  }

  modifier onlyAdvisoryBoard {
    require(
      IMemberRoles(internalContracts[uint(ID.MR)]).checkRole(
        msg.sender,
        uint(IMemberRoles.Role.AdvisoryBoard)
      ),
      "Caller is not an advisory board member"
    );
    _;
  }

  modifier onlyInternal {
    require(master.isInternal(msg.sender), "Caller is not an internal contract");
    _;
  }

  modifier onlyMaster {
    if (address(master) != address(0)) {
      require(address(master) == msg.sender, "Not master");
    }
    _;
  }

  modifier onlyGovernance {
    require(
      master.checkIsAuthToGoverned(msg.sender),
      "Caller is not authorized to govern"
    );
    _;
  }

  modifier onlyEmergencyAdmin {
    require(
      msg.sender == master.emergencyAdmin(),
      "Caller is not emergency admin"
    );
    _;
  }

  modifier whenPaused {
    require(master.isPause(), "System is not paused");
    _;
  }

  modifier whenNotPaused {
    require(!master.isPause(), "System is paused");
    _;
  }

  function getInternalContractAddress(ID id) internal view returns (address payable) {
    return internalContracts[uint(id)];
  }

  function changeMasterAddress(address masterAddress) public onlyMaster {
    master = INXMMaster(masterAddress);
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

abstract contract Multicall {

  error RevertedWithoutReason(uint index);

  // WARNING: Do not set this function as payable
  function multicall(bytes[] calldata data) external returns (bytes[] memory results) {

    uint callCount = data.length;
    results = new bytes[](callCount);

    for (uint i = 0; i < callCount; i++) {
      (bool ok, bytes memory result) = address(this).delegatecall(data[i]);

      if (!ok) {

        uint length = result.length;

        // 0 length returned from empty revert() / require(false)
        if (length == 0) {
          revert RevertedWithoutReason(i);
        }

        assembly {
          revert(add(result, 0x20), length)
        }
      }

      results[i] = result;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./ICoverNFT.sol";
import "./IStakingNFT.sol";
import "./IStakingPool.sol";
import "./IStakingPoolFactory.sol";

/* ========== DATA STRUCTURES ========== */

enum ClaimMethod {
  IndividualClaims,
  YieldTokenIncidents
}

// Basically CoverStatus from QuotationData.sol but with the extra Migrated status to avoid
// polluting Cover.sol state layout with new status variables.
enum LegacyCoverStatus {
  Active,
  ClaimAccepted,
  ClaimDenied,
  CoverExpired,
  ClaimSubmitted,
  Requested,
  Migrated
}

/* io structs */

struct PoolAllocationRequest {
  uint40 poolId;
  bool skip;
  uint coverAmountInAsset;
}

struct RequestAllocationVariables {
  uint previousPoolAllocationsLength;
  uint previousPremiumInNXM;
  uint refund;
  uint coverAmountInNXM;
}

struct BuyCoverParams {
  uint coverId;
  address owner;
  uint24 productId;
  uint8 coverAsset;
  uint96 amount;
  uint32 period;
  uint maxPremiumInAsset;
  uint8 paymentAsset;
  uint16 commissionRatio;
  address commissionDestination;
  string ipfsData;
}

struct ProductParam {
  string productName;
  uint productId;
  string ipfsMetadata;
  Product product;
  uint[] allowedPools;
}

struct ProductTypeParam {
  string productTypeName;
  uint productTypeId;
  string ipfsMetadata;
  ProductType productType;
}

struct ProductInitializationParams {
  uint productId;
  uint8 weight;
  uint96 initialPrice;
  uint96 targetPrice;
}

/* storage structs */

struct PoolAllocation {
  uint40 poolId;
  uint96 coverAmountInNXM;
  uint96 premiumInNXM;
  uint24 allocationId;
}

struct CoverData {
  uint24 productId;
  uint8 coverAsset;
  uint96 amountPaidOut;
}

struct CoverSegment {
  uint96 amount;
  uint32 start;
  uint32 period; // seconds
  uint32 gracePeriod; // seconds
  uint24 globalRewardsRatio;
  uint24 globalCapacityRatio;
}

struct Product {
  uint16 productType;
  address yieldTokenAddress;
  // cover assets bitmap. each bit represents whether the asset with
  // the index of that bit is enabled as a cover asset for this product
  uint32 coverAssets;
  uint16 initialPriceRatio;
  uint16 capacityReductionRatio;
  bool isDeprecated;
  bool useFixedPrice;
}

struct ProductType {
  uint8 claimMethod;
  uint32 gracePeriod;
}

struct ActiveCover {
  // Global active cover amount per asset.
  uint192 totalActiveCoverInAsset;
  // The last time activeCoverExpirationBuckets was updated
  uint64 lastBucketUpdateId;
}

interface ICover {

  /* ========== VIEWS ========== */

  function coverData(uint coverId) external view returns (CoverData memory);

  function coverDataCount() external view returns (uint);

  function coverSegmentsCount(uint coverId) external view returns (uint);

  function coverSegments(uint coverId) external view returns (CoverSegment[] memory);

  function coverSegmentWithRemainingAmount(
    uint coverId,
    uint segmentId
  ) external view returns (CoverSegment memory);

  function products(uint id) external view returns (Product memory);

  function productTypes(uint id) external view returns (ProductType memory);

  function stakingPool(uint index) external view returns (IStakingPool);

  function productNames(uint productId) external view returns (string memory);

  function productsCount() external view returns (uint);

  function productTypesCount() external view returns (uint);

  function totalActiveCoverInAsset(uint coverAsset) external view returns (uint);

  function globalCapacityRatio() external view returns (uint);

  function globalRewardsRatio() external view returns (uint);

  function getPriceAndCapacityRatios(uint[] calldata productIds) external view returns (
    uint _globalCapacityRatio,
    uint _globalMinPriceRatio,
    uint[] memory _initialPriceRatios,
    uint[] memory _capacityReductionRatios
  );

  /* === MUTATIVE FUNCTIONS ==== */

  function addLegacyCover(
    uint productId,
    uint coverAsset,
    uint amount,
    uint start,
    uint period,
    address newOwner
  ) external returns (uint coverId);

  function buyCover(
    BuyCoverParams calldata params,
    PoolAllocationRequest[] calldata coverChunkRequests
  ) external payable returns (uint coverId);

  function setProductTypes(ProductTypeParam[] calldata productTypes) external;

  function setProducts(ProductParam[] calldata params) external;

  function burnStake(
    uint coverId,
    uint segmentId,
    uint amount
  ) external returns (address coverOwner);

  function coverNFT() external returns (ICoverNFT);

  function stakingNFT() external returns (IStakingNFT);

  function stakingPoolFactory() external returns (IStakingPoolFactory);

  function createStakingPool(
    bool isPrivatePool,
    uint initialPoolFee,
    uint maxPoolFee,
    ProductInitializationParams[] calldata productInitParams,
    string calldata ipfsDescriptionHash
  ) external returns (uint poolId, address stakingPoolAddress);

  function isPoolAllowed(uint productId, uint poolId) external returns (bool);

  /* ========== EVENTS ========== */

  event ProductSet(uint id, string ipfsMetadata);
  event ProductTypeSet(uint id, string ipfsMetadata);
  event CoverEdited(uint indexed coverId, uint indexed productId, uint indexed segmentId, address buyer, string ipfsMetadata);

  // Auth
  error OnlyMemberRolesCanOperateTransfer();
  error OnlyOwnerOrApproved();

  // Cover details
  error CoverPeriodTooShort();
  error CoverPeriodTooLong();
  error CoverOutsideOfTheGracePeriod();
  error CoverAmountIsZero();

  // Products
  error ProductDoesntExist();
  error ProductTypeNotFound();
  error ProductDeprecated();
  error ProductDeprecatedOrNotInitialized();
  error InvalidProductType();
  error UnexpectedProductId();

  // Cover and payment assets
  error CoverAssetNotSupported();
  error InvalidPaymentAsset();
  error UnexpectedCoverAsset();
  error UnsupportedCoverAssets();
  error UnexpectedEthSent();

  // Price & Commission
  error PriceExceedsMaxPremiumInAsset();
  error TargetPriceBelowGlobalMinPriceRatio();
  error InitialPriceRatioBelowGlobalMinPriceRatio();
  error InitialPriceRatioAbove100Percent();
  error CommissionRateTooHigh();

  // ETH transfers
  error InsufficientEthSent();
  error SendingEthToPoolFailed();
  error SendingEthToCommissionDestinationFailed();
  error ReturningEthRemainderToSenderFailed();

  // Misc
  error AlreadyInitialized();
  error ExpiredCoversCannotBeEdited();
  error InsufficientCoverAmountAllocated();
  error UnexpectedPoolId();
  error CapacityReductionRatioAbove100Percent();
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "@openzeppelin/contracts-v4/token/ERC721/IERC721.sol";

interface ICoverNFT is IERC721 {

  function isApprovedOrOwner(address spender, uint tokenId) external returns (bool);

  function mint(address to) external returns (uint tokenId);

  function changeOperator(address newOperator) external;

  function totalSupply() external view returns (uint);

  function name() external view returns (string memory);

  error NotOperator();
  error NotMinted();
  error WrongFrom();
  error InvalidRecipient();
  error InvalidNewOperatorAddress();
  error InvalidNewNFTDescriptorAddress();
  error NotAuthorized();
  error UnsafeRecipient();
  error AlreadyMinted();

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMasterAwareV2 {

  enum ID {
    TC, // TokenController.sol
    P1, // Pool.sol
    MR, // MemberRoles.sol
    MC, // MCR.sol
    CO, // Cover.sol
    SP, // StakingProducts.sol
    PS, // LegacyPooledStaking.sol
    GV, // Governance.sol
    GW, // LegacyGateway.sol
    CL, // CoverMigrator.sol
    AS, // Assessment.sol
    CI, // IndividualClaims.sol - Claims for Individuals
    CG, // YieldTokenIncidents.sol - Claims for Groups
    // TODO: 1) if you update this enum, update lib/constants.js as well
    // TODO: 2) TK is not an internal contract!
    //          If you want to add a new contract below TK, remove TK and make it immutable in all
    //          contracts that are using it (currently LegacyGateway and LegacyPooledStaking).
    TK  // NXMToken.sol
  }

  function changeMasterAddress(address masterAddress) external;

  function changeDependentContractAddress() external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMemberRoles {

  enum Role {Unassigned, AdvisoryBoard, Member, Owner}

  function join(address _userAddress, uint nonce, bytes calldata signature) external payable;

  function switchMembership(address _newAddress) external;

  function switchMembershipAndAssets(
    address newAddress,
    uint[] calldata coverIds,
    uint[] calldata stakingTokenIds
  ) external;

  function switchMembershipOf(address member, address _newAddress) external;

  function totalRoles() external view returns (uint256);

  function changeAuthorized(uint _roleId, address _newAuthorized) external;

  function setKycAuthAddress(address _add) external;

  function members(uint _memberRoleId) external view returns (uint, address[] memory memberArray);

  function numberOfMembers(uint _memberRoleId) external view returns (uint);

  function authorized(uint _memberRoleId) external view returns (address);

  function roles(address _memberAddress) external view returns (uint[] memory);

  function checkRole(address _memberAddress, uint _roleId) external view returns (bool);

  function getMemberLengthForAllRoles() external view returns (uint[] memory totalMembers);

  function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool);

  function membersLength(uint _memberRoleId) external view returns (uint);

  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);

  event MemberJoined(address indexed newMember, uint indexed nonce);

  event switchedMembership(address indexed previousMember, address indexed newMember, uint timeStamp);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function emergencyAdmin() external view returns (address);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);

  function contractAddresses(bytes2 code) external view returns (address payable);

  function upgradeMultipleContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses
  ) external;

  function removeContracts(bytes2[] calldata contractCodesToRemove) external;

  function addNewInternalContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses,
    uint[] calldata _types
  ) external;

  function updateOwnerParameters(bytes8 code, address payable val) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "@openzeppelin/contracts-v4/token/ERC721/IERC721.sol";

interface IStakingNFT is IERC721 {

  function isApprovedOrOwner(address spender, uint tokenId) external returns (bool);

  function mint(uint poolId, address to) external returns (uint tokenId);

  function changeOperator(address newOperator) external;

  function totalSupply() external returns (uint);

  function tokenInfo(uint tokenId) external view returns (uint poolId, address owner);

  function stakingPoolOf(uint tokenId) external view returns (uint poolId);

  function stakingPoolFactory() external view returns (address);

  function name() external view returns (string memory);

  error NotOperator();
  error NotMinted();
  error WrongFrom();
  error InvalidRecipient();
  error InvalidNewOperatorAddress();
  error InvalidNewNFTDescriptorAddress();
  error NotAuthorized();
  error UnsafeRecipient();
  error AlreadyMinted();
  error NotStakingPool();

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

/* structs for io */

struct AllocationRequest {
  uint productId;
  uint coverId;
  uint allocationId;
  uint period;
  uint gracePeriod;
  bool useFixedPrice;
  uint previousStart;
  uint previousExpiration;
  uint previousRewardsRatio;
  uint globalCapacityRatio;
  uint capacityReductionRatio;
  uint rewardRatio;
  uint globalMinPrice;
}

struct StakedProductParam {
  uint productId;
  bool recalculateEffectiveWeight;
  bool setTargetWeight;
  uint8 targetWeight;
  bool setTargetPrice;
  uint96 targetPrice;
}

  struct BurnStakeParams {
    uint allocationId;
    uint productId;
    uint start;
    uint period;
    uint deallocationAmount;
  }

interface IStakingPool {

  /* structs for storage */

  // stakers are grouped in tranches based on the timelock expiration
  // tranche index is calculated based on the expiration date
  // the initial proposal is to have 4 tranches per year (1 tranche per quarter)
  struct Tranche {
    uint128 stakeShares;
    uint128 rewardsShares;
  }

  struct ExpiredTranche {
    uint96 accNxmPerRewardShareAtExpiry;
    uint96 stakeAmountAtExpiry; // nxm total supply is 6.7e24 and uint96.max is 7.9e28
    uint128 stakeSharesSupplyAtExpiry;
  }

  struct Deposit {
    uint96 lastAccNxmPerRewardShare;
    uint96 pendingRewards;
    uint128 stakeShares;
    uint128 rewardsShares;
  }

  function initialize(
    bool isPrivatePool,
    uint initialPoolFee,
    uint maxPoolFee,
    uint _poolId,
    string memory ipfsDescriptionHash
  ) external;

  function processExpirations(bool updateUntilCurrentTimestamp) external;

  function requestAllocation(
    uint amount,
    uint previousPremium,
    AllocationRequest calldata request
  ) external returns (uint premium, uint allocationId);

  function burnStake(uint amount, BurnStakeParams calldata params) external;

  function depositTo(
    uint amount,
    uint trancheId,
    uint requestTokenId,
    address destination
  ) external returns (uint tokenId);

  function withdraw(
    uint tokenId,
    bool withdrawStake,
    bool withdrawRewards,
    uint[] memory trancheIds
  ) external returns (uint withdrawnStake, uint withdrawnRewards);

  function isPrivatePool() external view returns (bool);

  function isHalted() external view returns (bool);

  function manager() external view returns (address);

  function getPoolId() external view returns (uint);

  function getPoolFee() external view returns (uint);

  function getMaxPoolFee() external view returns (uint);

  function getActiveStake() external view returns (uint);

  function getStakeSharesSupply() external view returns (uint);

  function getRewardsSharesSupply() external view returns (uint);

  function getRewardPerSecond() external view returns (uint);

  function getAccNxmPerRewardsShare() external view returns (uint);

  function getLastAccNxmUpdate() external view returns (uint);

  function getFirstActiveTrancheId() external view returns (uint);

  function getFirstActiveBucketId() external view returns (uint);

  function getNextAllocationId() external view returns (uint);

  function getDeposit(uint tokenId, uint trancheId) external view returns (
    uint lastAccNxmPerRewardShare,
    uint pendingRewards,
    uint stakeShares,
    uint rewardsShares
  );

  function getTranche(uint trancheId) external view returns (
    uint stakeShares,
    uint rewardsShares
  );

  function getExpiredTranche(uint trancheId) external view returns (
    uint accNxmPerRewardShareAtExpiry,
    uint stakeAmountAtExpiry,
    uint stakeShareSupplyAtExpiry
  );

  function setPoolFee(uint newFee) external;

  function setPoolPrivacy(bool isPrivatePool) external;

  function getActiveAllocations(
    uint productId
  ) external view returns (uint[] memory trancheAllocations);

  function getTrancheCapacities(
    uint productId,
    uint firstTrancheId,
    uint trancheCount,
    uint capacityRatio,
    uint reductionRatio
  ) external view returns (uint[] memory trancheCapacities);

  /* ========== EVENTS ========== */

  event StakeDeposited(address indexed user, uint256 amount, uint256 trancheId, uint256 tokenId);

  event DepositExtended(address indexed user, uint256 tokenId, uint256 initialTrancheId, uint256 newTrancheId, uint256 topUpAmount);

  event PoolPrivacyChanged(address indexed manager, bool isPrivate);

  event PoolFeeChanged(address indexed manager, uint newFee);

  event PoolDescriptionSet(string ipfsDescriptionHash);

  event Withdraw(address indexed user, uint indexed tokenId, uint tranche, uint amountStakeWithdrawn, uint amountRewardsWithdrawn);

  event StakeBurned(uint amount);

  // Auth
  error OnlyCoverContract();
  error OnlyManager();
  error PrivatePool();
  error SystemPaused();
  error PoolHalted();

  // Fees
  error PoolFeeExceedsMax();
  error MaxPoolFeeAbove100();

  // Voting
  error NxmIsLockedForGovernanceVote();
  error ManagerNxmIsLockedForGovernanceVote();

  // Deposit
  error InsufficientDepositAmount();
  error RewardRatioTooHigh();

  // Staking NFTs
  error InvalidTokenId();
  error NotTokenOwnerOrApproved();
  error InvalidStakingPoolForToken();

  // Tranche & capacity
  error NewTrancheEndsBeforeInitialTranche();
  error RequestedTrancheIsNotYetActive();
  error RequestedTrancheIsExpired();
  error InsufficientCapacity();

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IStakingPoolFactory {

  function stakingPoolCount() external view returns (uint);

  function beacon() external view returns (address);

  function create(address beacon) external returns (uint poolId, address stakingPoolAddress);

  event StakingPoolCreated(uint indexed poolId, address indexed stakingPoolAddress);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./ICover.sol";
import "./IStakingPool.sol";

interface IStakingProducts {

  // TODO: resize values?
  struct Weights {
    uint32 totalEffectiveWeight;
    uint32 totalTargetWeight;
  }

  struct StakedProduct {
    uint16 lastEffectiveWeight;
    uint8 targetWeight;
    uint96 targetPrice;
    uint96 bumpedPrice;
    uint32 bumpedPriceUpdateTime;
  }

  /* ============= PRODUCT FUNCTIONS ============= */

  function setProducts(uint poolId, StakedProductParam[] memory params) external;

  function setInitialProducts(uint poolId, ProductInitializationParams[] memory params) external;

  function getProductTargetWeight(uint poolId, uint productId) external view returns (uint);

  function getTotalTargetWeight(uint poolId) external view returns (uint);

  function getTotalEffectiveWeight(uint poolId) external view returns (uint);

  function getProduct(uint poolId, uint productId) external view returns (
    uint lastEffectiveWeight,
    uint targetWeight,
    uint targetPrice,
    uint bumpedPrice,
    uint bumpedPriceUpdateTime
  );

  /* ============= PRICING FUNCTIONS ============= */

  function getPremium(
    uint poolId,
    uint productId,
    uint period,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint globalMinPrice,
    bool useFixedPrice,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm
  ) external returns (uint premium);

  function calculateFixedPricePremium(
    uint coverAmount,
    uint period,
    uint fixedPrice,
    uint nxmPerAllocationUnit,
    uint targetPriceDenominator
  ) external pure returns (uint);


  function calculatePremium(
    StakedProduct memory product,
    uint period,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint targetPrice,
    uint currentBlockTimestamp,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm,
    uint targetPriceDenominator
  ) external pure returns (uint premium, StakedProduct memory);

  function calculatePremiumPerYear(
    uint basePrice,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm,
    uint targetPriceDenominator
  ) external pure returns (uint);

  // Calculates the premium for a given cover amount starting with the surge point
  function calculateSurgePremium(
    uint amountOnSurge,
    uint totalCapacity,
    uint allocationUnitsPerNxm
  ) external pure returns (uint);

  /* ============= EVENTS ============= */

  event ProductUpdated(uint productId, uint8 targetWeight, uint96 targetPrice);

  /* ============= ERRORS ============= */

  // Auth
  error OnlyStakingPool();
  error OnlyCoverContract();
  error OnlyManager();

  // Products & weights
  error PoolNotAllowedForThisProduct();
  error MustSetPriceForNewProducts();
  error MustSetWeightForNewProducts();
  error TargetPriceTooHigh();
  error TargetPriceBelowMin();
  error TargetWeightTooHigh();
  error MustRecalculateEffectiveWeight();
  error TotalTargetWeightExceeded();
  error TotalEffectiveWeightExceeded();

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

/**
 * @dev Simple library that defines min, max and babylonian sqrt functions
 */
library Math {

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function max(uint a, uint b) internal pure returns (uint) {
    return a > b ? a : b;
  }

  function sum(uint[] memory items) internal pure returns (uint) {
    uint count = items.length;
    uint total;

    for (uint i = 0; i < count; i++) {
      total += items[i];
    }

    return total;
  }

  function divRound(uint a, uint b) internal pure returns (uint) {
    return (a + b / 2) / b;
  }

  function divCeil(uint a, uint b) internal pure returns (uint) {
    return (a + b - 1) / b;
  }

  function roundUp(uint a, uint b) internal pure returns (uint) {
    return divCeil(a, b) * b;
  }

  // babylonian method
  function sqrt(uint y) internal pure returns (uint) {

    if (y > 3) {
      uint z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
      return z;
    }

    if (y != 0) {
      return 1;
    }

    return 0;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeUintCast {
  /**
   * @dev Returns the downcasted uint248 from uint256, reverting on
   * overflow (when the input is greater than largest uint248).
   *
   * Counterpart to Solidity's `uint248` operator.
   *
   * Requirements:
   *
   * - input must fit into 248 bits
   */
  function toUint248(uint256 value) internal pure returns (uint248) {
    require(value < 2**248, "SafeCast: value doesn\'t fit in 248 bits");
    return uint248(value);
  }

  /**
   * @dev Returns the downcasted uint240 from uint256, reverting on
   * overflow (when the input is greater than largest uint240).
   *
   * Counterpart to Solidity's `uint240` operator.
   *
   * Requirements:
   *
   * - input must fit into 240 bits
   */
  function toUint240(uint256 value) internal pure returns (uint240) {
    require(value < 2**240, "SafeCast: value doesn\'t fit in 240 bits");
    return uint240(value);
  }

  /**
   * @dev Returns the downcasted uint232 from uint256, reverting on
   * overflow (when the input is greater than largest uint232).
   *
   * Counterpart to Solidity's `uint232` operator.
   *
   * Requirements:
   *
   * - input must fit into 232 bits
   */
  function toUint232(uint256 value) internal pure returns (uint232) {
    require(value < 2**232, "SafeCast: value doesn\'t fit in 232 bits");
    return uint232(value);
  }

  /**
   * @dev Returns the downcasted uint224 from uint256, reverting on
   * overflow (when the input is greater than largest uint224).
   *
   * Counterpart to Solidity's `uint224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(value < 2**224, "SafeCast: value doesn\'t fit in 224 bits");
    return uint224(value);
  }

  /**
   * @dev Returns the downcasted uint216 from uint256, reverting on
   * overflow (when the input is greater than largest uint216).
   *
   * Counterpart to Solidity's `uint216` operator.
   *
   * Requirements:
   *
   * - input must fit into 216 bits
   */
  function toUint216(uint256 value) internal pure returns (uint216) {
    require(value < 2**216, "SafeCast: value doesn\'t fit in 216 bits");
    return uint216(value);
  }

  /**
   * @dev Returns the downcasted uint208 from uint256, reverting on
   * overflow (when the input is greater than largest uint208).
   *
   * Counterpart to Solidity's `uint208` operator.
   *
   * Requirements:
   *
   * - input must fit into 208 bits
   */
  function toUint208(uint256 value) internal pure returns (uint208) {
    require(value < 2**208, "SafeCast: value doesn\'t fit in 208 bits");
    return uint208(value);
  }

  /**
   * @dev Returns the downcasted uint200 from uint256, reverting on
   * overflow (when the input is greater than largest uint200).
   *
   * Counterpart to Solidity's `uint200` operator.
   *
   * Requirements:
   *
   * - input must fit into 200 bits
   */
  function toUint200(uint256 value) internal pure returns (uint200) {
    require(value < 2**200, "SafeCast: value doesn\'t fit in 200 bits");
    return uint200(value);
  }

  /**
   * @dev Returns the downcasted uint192 from uint256, reverting on
   * overflow (when the input is greater than largest uint192).
   *
   * Counterpart to Solidity's `uint192` operator.
   *
   * Requirements:
   *
   * - input must fit into 192 bits
   */
  function toUint192(uint256 value) internal pure returns (uint192) {
    require(value < 2**192, "SafeCast: value doesn\'t fit in 192 bits");
    return uint192(value);
  }

  /**
   * @dev Returns the downcasted uint184 from uint256, reverting on
   * overflow (when the input is greater than largest uint184).
   *
   * Counterpart to Solidity's `uint184` operator.
   *
   * Requirements:
   *
   * - input must fit into 184 bits
   */
  function toUint184(uint256 value) internal pure returns (uint184) {
    require(value < 2**184, "SafeCast: value doesn\'t fit in 184 bits");
    return uint184(value);
  }

  /**
   * @dev Returns the downcasted uint176 from uint256, reverting on
   * overflow (when the input is greater than largest uint176).
   *
   * Counterpart to Solidity's `uint176` operator.
   *
   * Requirements:
   *
   * - input must fit into 176 bits
   */
  function toUint176(uint256 value) internal pure returns (uint176) {
    require(value < 2**176, "SafeCast: value doesn\'t fit in 176 bits");
    return uint176(value);
  }

  /**
   * @dev Returns the downcasted uint168 from uint256, reverting on
   * overflow (when the input is greater than largest uint168).
   *
   * Counterpart to Solidity's `uint168` operator.
   *
   * Requirements:
   *
   * - input must fit into 168 bits
   */
  function toUint168(uint256 value) internal pure returns (uint168) {
    require(value < 2**168, "SafeCast: value doesn\'t fit in 168 bits");
    return uint168(value);
  }

  /**
   * @dev Returns the downcasted uint160 from uint256, reverting on
   * overflow (when the input is greater than largest uint160).
   *
   * Counterpart to Solidity's `uint160` operator.
   *
   * Requirements:
   *
   * - input must fit into 160 bits
   */
  function toUint160(uint256 value) internal pure returns (uint160) {
    require(value < 2**160, "SafeCast: value doesn\'t fit in 160 bits");
    return uint160(value);
  }

  /**
   * @dev Returns the downcasted uint152 from uint256, reverting on
   * overflow (when the input is greater than largest uint152).
   *
   * Counterpart to Solidity's `uint152` operator.
   *
   * Requirements:
   *
   * - input must fit into 152 bits
   */
  function toUint152(uint256 value) internal pure returns (uint152) {
    require(value < 2**152, "SafeCast: value doesn\'t fit in 152 bits");
    return uint152(value);
  }

  /**
   * @dev Returns the downcasted uint144 from uint256, reverting on
   * overflow (when the input is greater than largest uint144).
   *
   * Counterpart to Solidity's `uint144` operator.
   *
   * Requirements:
   *
   * - input must fit into 144 bits
   */
  function toUint144(uint256 value) internal pure returns (uint144) {
    require(value < 2**144, "SafeCast: value doesn\'t fit in 144 bits");
    return uint144(value);
  }

  /**
   * @dev Returns the downcasted uint136 from uint256, reverting on
   * overflow (when the input is greater than largest uint136).
   *
   * Counterpart to Solidity's `uint136` operator.
   *
   * Requirements:
   *
   * - input must fit into 136 bits
   */
  function toUint136(uint256 value) internal pure returns (uint136) {
    require(value < 2**136, "SafeCast: value doesn\'t fit in 136 bits");
    return uint136(value);
  }

  /**
   * @dev Returns the downcasted uint128 from uint256, reverting on
   * overflow (when the input is greater than largest uint128).
   *
   * Counterpart to Solidity's `uint128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint120 from uint256, reverting on
   * overflow (when the input is greater than largest uint120).
   *
   * Counterpart to Solidity's `uint120` operator.
   *
   * Requirements:
   *
   * - input must fit into 120 bits
   */
  function toUint120(uint256 value) internal pure returns (uint120) {
    require(value < 2**120, "SafeCast: value doesn\'t fit in 120 bits");
    return uint120(value);
  }

  /**
   * @dev Returns the downcasted uint112 from uint256, reverting on
   * overflow (when the input is greater than largest uint112).
   *
   * Counterpart to Solidity's `uint112` operator.
   *
   * Requirements:
   *
   * - input must fit into 112 bits
   */
  function toUint112(uint256 value) internal pure returns (uint112) {
    require(value < 2**112, "SafeCast: value doesn\'t fit in 112 bits");
    return uint112(value);
  }

  /**
   * @dev Returns the downcasted uint104 from uint256, reverting on
   * overflow (when the input is greater than largest uint104).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 104 bits
   */
  function toUint104(uint256 value) internal pure returns (uint104) {
    require(value < 2**104, "SafeCast: value doesn\'t fit in 104 bits");
    return uint104(value);
  }

  /**
   * @dev Returns the downcasted uint96 from uint256, reverting on
   * overflow (when the input is greater than largest uint96).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
    return uint96(value);
  }

  /**
   * @dev Returns the downcasted uint80 from uint256, reverting on
   * overflow (when the input is greater than largest uint80).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 80 bits
   */
  function toUint80(uint256 value) internal pure returns (uint80) {
    require(value < 2**80, "SafeCast: value doesn\'t fit in 80 bits");
    return uint80(value);
  }

  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint56 from uint256, reverting on
   * overflow (when the input is greater than largest uint56).
   *
   * Counterpart to Solidity's `uint56` operator.
   *
   * Requirements:
   *
   * - input must fit into 56 bits
   */
  function toUint56(uint256 value) internal pure returns (uint56) {
    require(value < 2**56, "SafeCast: value doesn\'t fit in 56 bits");
    return uint56(value);
  }

  /**
   * @dev Returns the downcasted uint48 from uint256, reverting on
   * overflow (when the input is greater than largest uint48).
   *
   * Counterpart to Solidity's `uint48` operator.
   *
   * Requirements:
   *
   * - input must fit into 48 bits
   */
  function toUint48(uint256 value) internal pure returns (uint48) {
    require(value < 2**48, "SafeCast: value doesn\'t fit in 48 bits");
    return uint48(value);
  }

  /**
   * @dev Returns the downcasted uint40 from uint256, reverting on
   * overflow (when the input is greater than largest uint40).
   *
   * Counterpart to Solidity's `uint40` operator.
   *
   * Requirements:
   *
   * - input must fit into 40 bits
   */
  function toUint40(uint256 value) internal pure returns (uint40) {
    require(value < 2**40, "SafeCast: value doesn\'t fit in 40 bits");
    return uint40(value);
  }

  /**
   * @dev Returns the downcasted uint32 from uint256, reverting on
   * overflow (when the input is greater than largest uint32).
   *
   * Counterpart to Solidity's `uint32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint24 from uint256, reverting on
   * overflow (when the input is greater than largest uint24).
   *
   * Counterpart to Solidity's `uint24` operator.
   *
   * Requirements:
   *
   * - input must fit into 24 bits
   */
  function toUint24(uint256 value) internal pure returns (uint24) {
    require(value < 2**24, "SafeCast: value doesn\'t fit in 24 bits");
    return uint24(value);
  }

  /**
   * @dev Returns the downcasted uint16 from uint256, reverting on
   * overflow (when the input is greater than largest uint16).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
    return uint16(value);
  }

  /**
   * @dev Returns the downcasted uint8 from uint256, reverting on
   * overflow (when the input is greater than largest uint8).
   *
   * Counterpart to Solidity's `uint8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
    return uint8(value);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

/**
 * @dev Simple library to derive the staking pool address from the pool id without external calls
 */
library StakingPoolLibrary {

  function getAddress(address factory, uint poolId) internal pure returns (address) {

    bytes32 hash = keccak256(
      abi.encodePacked(
        hex'ff',
        factory,
        poolId, // salt
        // init code hash of the MinimalBeaconProxy
        // updated using patch-staking-pool-library.js script
        hex'1eb804b66941a2e8465fa0951be9c8b855b7794ee05b0789ab22a02ee1298ebe' // init code hash
      )
    );

    // cast last 20 bytes of hash to address
    return address(uint160(uint(hash)));
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

import "../../abstract/MasterAwareV2.sol";
import "../../abstract/Multicall.sol";
import "../../interfaces/IStakingProducts.sol";
import "../../libraries/Math.sol";
import "../../libraries/SafeUintCast.sol";
import "../../libraries/StakingPoolLibrary.sol";

contract StakingProducts is IStakingProducts, MasterAwareV2, Multicall {
  using SafeUintCast for uint;

  uint public constant SURGE_PRICE_RATIO = 2 ether;
  uint public constant SURGE_THRESHOLD_RATIO = 90_00; // 90.00%
  uint public constant SURGE_THRESHOLD_DENOMINATOR = 100_00; // 100.00%
  // base price bump
  // +0.2% for each 1% of capacity used, ie +20% for 100%
  uint public constant PRICE_BUMP_RATIO = 20_00; // 20%
  // bumped price smoothing
  // 0.5% per day
  uint public constant PRICE_CHANGE_PER_DAY = 50; // 0.5%
  uint public constant INITIAL_PRICE_DENOMINATOR = 100_00;
  uint public constant TARGET_PRICE_DENOMINATOR = 100_00;
  uint public constant MAX_TOTAL_WEIGHT = 20_00; // 20x

  // The 3 constants below are also used in the StakingPool contract
  uint public constant TRANCHE_DURATION = 91 days;
  uint public constant MAX_ACTIVE_TRANCHES = 8; // 7 whole quarters + 1 partial quarter
  uint public constant WEIGHT_DENOMINATOR = 100;

  // pool id => product id => Product
  mapping(uint => mapping(uint => StakedProduct)) private _products;
  // pool id => { totalEffectiveWeight, totalTargetWeight }
  mapping(uint => Weights) public weights;

  address public immutable coverContract;
  address public immutable stakingPoolFactory;

  constructor(address _coverContract, address _stakingPoolFactory) {
    coverContract = _coverContract;
    stakingPoolFactory = _stakingPoolFactory;
  }

  function getStakingPool(uint poolId) internal view returns (IStakingPool stakingPoolAddress) {
    stakingPoolAddress = IStakingPool(StakingPoolLibrary.getAddress(stakingPoolFactory, poolId));
  }

  function getProductTargetWeight(uint poolId, uint productId) external view override returns (uint) {
    return uint(_products[poolId][productId].targetWeight);
  }

  function getTotalTargetWeight(uint poolId) external override view returns (uint) {
    return weights[poolId].totalTargetWeight;
  }

  function getTotalEffectiveWeight(uint poolId) external override view returns (uint) {
    return weights[poolId].totalEffectiveWeight;
  }

  function getProduct(uint poolId, uint productId) external override view returns (
    uint lastEffectiveWeight,
    uint targetWeight,
    uint targetPrice,
    uint bumpedPrice,
    uint bumpedPriceUpdateTime
  ) {
    StakedProduct memory product = _products[poolId][productId];
    return (
      product.lastEffectiveWeight,
      product.targetWeight,
      product.targetPrice,
      product.bumpedPrice,
      product.bumpedPriceUpdateTime
    );
  }

  function recalculateEffectiveWeights(uint poolId, uint[] calldata productIds) external {

    IStakingPool stakingPool = getStakingPool(poolId);

    (
      uint globalCapacityRatio,
      /* globalMinPriceRatio */,
      /* initialPriceRatios */,
      /* capacityReductionRatios */
      uint[] memory capacityReductionRatios
    ) = ICover(coverContract).getPriceAndCapacityRatios(productIds);

    uint _totalEffectiveWeight = weights[poolId].totalEffectiveWeight;

    for (uint i = 0; i < productIds.length; i++) {
      uint productId = productIds[i];
      StakedProduct memory _product = _products[poolId][productId];

      uint16 previousEffectiveWeight = _product.lastEffectiveWeight;
      _product.lastEffectiveWeight = _getEffectiveWeight(
        stakingPool,
        productId,
        _product.targetWeight,
        globalCapacityRatio,
        capacityReductionRatios[i]
      );
      _totalEffectiveWeight = _totalEffectiveWeight - previousEffectiveWeight + _product.lastEffectiveWeight;
      _products[poolId][productId] = _product;
    }

    weights[poolId].totalEffectiveWeight = _totalEffectiveWeight.toUint32();
  }

  function recalculateEffectiveWeightsForAllProducts(uint poolId) external {
    uint productsCount = ICover(coverContract).productsCount();
    IStakingPool stakingPool = getStakingPool(poolId);

    // initialize array for all possible products
    uint[] memory productIdsRaw = new uint[](productsCount);
    uint stakingPoolProductCount;

    // filter out products that are not in this pool
    for (uint i = 0; i < productsCount; i++) {
      if (_products[poolId][i].bumpedPriceUpdateTime == 0) {
        continue;
      }
      productIdsRaw[stakingPoolProductCount++] = i;
    }

    // use resized array
    uint[] memory productIds = new uint[](stakingPoolProductCount);

    for (uint i = 0; i < stakingPoolProductCount; i++) {
      productIds[i] = productIdsRaw[i];
    }

    (
      uint globalCapacityRatio,
      /* globalMinPriceRatio */,
      /* initialPriceRatios */,
      /* capacityReductionRatios */
      uint[] memory capacityReductionRatios
    ) = ICover(coverContract).getPriceAndCapacityRatios(productIds);

    uint _totalEffectiveWeight;

    for (uint i = 0; i < stakingPoolProductCount; i++) {
      uint productId = productIds[i];
      StakedProduct memory _product = _products[poolId][productId];

      // Get current effectiveWeight
      _product.lastEffectiveWeight = _getEffectiveWeight(
        stakingPool,
        productId,
        _product.targetWeight,
        globalCapacityRatio,
        capacityReductionRatios[i]
      );
      _totalEffectiveWeight += _product.lastEffectiveWeight;
      _products[poolId][productId] = _product;
    }

    weights[poolId].totalEffectiveWeight = _totalEffectiveWeight.toUint32();
  }

  function setProducts(uint poolId, StakedProductParam[] memory params) external {

    IStakingPool stakingPool = getStakingPool(poolId);

    if (msg.sender != stakingPool.manager()) {
      revert OnlyManager();
    }

    uint globalCapacityRatio;
    uint globalMinPriceRatio;
    uint[] memory initialPriceRatios;
    uint[] memory capacityReductionRatios;

    {
      uint numProducts = params.length;
      uint[] memory productIds = new uint[](numProducts);

      for (uint i = 0; i < numProducts; i++) {
        productIds[i] = params[i].productId;
        if (!ICover(coverContract).isPoolAllowed(params[i].productId, poolId)) {
          revert PoolNotAllowedForThisProduct();
        }
      }
      (
        globalCapacityRatio,
        globalMinPriceRatio,
        initialPriceRatios,
        capacityReductionRatios
      ) = ICover(coverContract).getPriceAndCapacityRatios(productIds);
    }

    Weights memory _weights = weights[poolId];
    bool targetWeightIncreased;

    for (uint i = 0; i < params.length; i++) {
      StakedProductParam memory _param = params[i];
      StakedProduct memory _product = _products[poolId][_param.productId];

      bool isNewProduct = _product.bumpedPriceUpdateTime == 0;

      // if this is a new product
      if (isNewProduct) {
        // initialize the bumpedPrice
        _product.bumpedPrice = initialPriceRatios[i].toUint96();
        _product.bumpedPriceUpdateTime = uint32(block.timestamp);
        // and make sure we set the price and the target weight
        if (!_param.setTargetPrice) {
          revert MustSetPriceForNewProducts();
        }
        if (!_param.setTargetWeight) {
          revert MustSetWeightForNewProducts();
        }
      }

      if (_param.setTargetPrice) {

        if (_param.targetPrice > TARGET_PRICE_DENOMINATOR) {
          revert TargetPriceTooHigh();
        }

        if (_param.targetPrice < globalMinPriceRatio) {
          revert TargetPriceBelowMin();
        }

        // if this is an existing product, when the target price is updated we need to calculate the
        // current base price using the old target price and update the bumped price to that value
        // uses the same logic as calculatePremium()
        if (!isNewProduct) {

          // apply price change per day towards previous target price
          uint newBumpedPrice = getBasePrice(
            _product.bumpedPrice,
            _product.bumpedPriceUpdateTime,
            _product.targetPrice,
            block.timestamp
          );

          // update product with new bumped price and bumped price update time
          _product.bumpedPrice = newBumpedPrice.toUint96();
          _product.bumpedPriceUpdateTime = block.timestamp.toUint32();
        }

        _product.targetPrice = _param.targetPrice;
      }

      // if setTargetWeight is set - effective weight must be recalculated
      if (_param.setTargetWeight && !_param.recalculateEffectiveWeight) {
        revert MustRecalculateEffectiveWeight();
      }

      // Must recalculate effectiveWeight to adjust targetWeight
      if (_param.recalculateEffectiveWeight) {

        if (_param.setTargetWeight) {
          if (_param.targetWeight > WEIGHT_DENOMINATOR) {
            revert TargetWeightTooHigh();
          }

          // totalEffectiveWeight cannot be above the max unless target  weight is not increased
          if (!targetWeightIncreased) {
            targetWeightIncreased = _param.targetWeight > _product.targetWeight;
          }
          _weights.totalTargetWeight = _weights.totalTargetWeight - _product.targetWeight + _param.targetWeight;
          _product.targetWeight = _param.targetWeight;
        }

        // subtract the previous effective weight
        _weights.totalEffectiveWeight -= _product.lastEffectiveWeight;

        _product.lastEffectiveWeight = _getEffectiveWeight(
          stakingPool,
          _param.productId,
          _product.targetWeight,
          globalCapacityRatio,
          capacityReductionRatios[i]
        );

        // add the new effective weight
        _weights.totalEffectiveWeight += _product.lastEffectiveWeight;
      }

      // sstore
      _products[poolId][_param.productId] = _product;

      emit ProductUpdated(_param.productId, _param.targetWeight, _param.targetPrice);
    }

    if (_weights.totalTargetWeight > MAX_TOTAL_WEIGHT) {
      revert TotalTargetWeightExceeded();
    }

    if (targetWeightIncreased) {
      if (_weights.totalEffectiveWeight > MAX_TOTAL_WEIGHT) {
        revert TotalEffectiveWeightExceeded();
      }
    }

    weights[poolId] = _weights;
  }

  function getEffectiveWeight(
    uint poolId,
    uint productId,
    uint targetWeight,
    uint globalCapacityRatio,
    uint capacityReductionRatio
  ) public view returns (uint effectiveWeight) {

    IStakingPool stakingPool = getStakingPool(poolId);

    return _getEffectiveWeight(
      stakingPool,
      productId,
      targetWeight,
      globalCapacityRatio,
      capacityReductionRatio
    );
  }

  function _getEffectiveWeight(
    IStakingPool stakingPool,
    uint productId,
    uint targetWeight,
    uint globalCapacityRatio,
    uint capacityReductionRatio
  ) internal view returns (uint16 effectiveWeight) {

    uint[] memory trancheCapacities = stakingPool.getTrancheCapacities(
      productId,
      block.timestamp / TRANCHE_DURATION, // first active tranche id
      MAX_ACTIVE_TRANCHES,
      globalCapacityRatio,
      capacityReductionRatio
    );

    uint totalCapacity = Math.sum(trancheCapacities);

    if (totalCapacity == 0) {
      return targetWeight.toUint16();
    }

    uint[] memory activeAllocations = stakingPool.getActiveAllocations(productId);
    uint totalAllocation = Math.sum(activeAllocations);
    uint actualWeight = Math.min(totalAllocation * WEIGHT_DENOMINATOR / totalCapacity, type(uint16).max);

    return Math.max(targetWeight, actualWeight).toUint16();
  }

  function setInitialProducts(uint poolId, ProductInitializationParams[] memory params) public onlyInternal {

    uint totalTargetWeight;

    for (uint i = 0; i < params.length; i++) {

      ProductInitializationParams memory param = params[i];

      if (param.targetPrice > TARGET_PRICE_DENOMINATOR) {
        revert TargetPriceTooHigh();
      }

      if (param.weight > WEIGHT_DENOMINATOR) {
        revert TargetWeightTooHigh();
      }

      StakedProduct memory product;
      product.bumpedPrice = param.initialPrice;
      product.bumpedPriceUpdateTime = block.timestamp.toUint32();
      product.targetPrice = param.targetPrice;
      product.targetWeight = param.weight;
      product.lastEffectiveWeight = param.weight;

      // sstore
      _products[poolId][param.productId] = product;

      totalTargetWeight += param.weight;
    }

    if (totalTargetWeight > MAX_TOTAL_WEIGHT) {
      revert TotalTargetWeightExceeded();
    }

    weights[poolId] = Weights({
      totalTargetWeight: totalTargetWeight.toUint32(),
      totalEffectiveWeight: totalTargetWeight.toUint32()
    });
  }

  /* pricing code */
  function getPremium(
    uint poolId,
    uint productId,
    uint period,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint globalMinPrice,
    bool useFixedPrice,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNXM
  ) public returns (uint premium) {

    if (msg.sender != StakingPoolLibrary.getAddress(stakingPoolFactory, poolId)) {
      revert OnlyStakingPool();
    }

    StakedProduct memory product = _products[poolId][productId];
    uint targetPrice = Math.max(product.targetPrice, globalMinPrice);

    if (useFixedPrice) {
      return calculateFixedPricePremium(period, coverAmount, targetPrice, nxmPerAllocationUnit, TARGET_PRICE_DENOMINATOR);
    }

    (premium, product) = calculatePremium(
      product,
      period,
      coverAmount,
      initialCapacityUsed,
      totalCapacity,
      targetPrice,
      block.timestamp,
      nxmPerAllocationUnit,
      allocationUnitsPerNXM,
      TARGET_PRICE_DENOMINATOR
    );

    // sstore
    _products[poolId][productId] = product;

    return premium;
  }

  function calculateFixedPricePremium(
    uint coverAmount,
    uint period,
    uint fixedPrice,
    uint nxmPerAllocationUnit,
    uint targetPriceDenominator
  ) public pure returns (uint) {

    uint premiumPerYear =
    coverAmount
    * nxmPerAllocationUnit
    * fixedPrice
    / targetPriceDenominator;

    return premiumPerYear * period / 365 days;
  }

  function getBasePrice(
    uint productBumpedPrice,
    uint productBumpedPriceUpdateTime,
    uint targetPrice,
    uint timestamp
  ) public pure returns (uint basePrice) {

    // use previously recorded bumped price and apply time based smoothing towards target price
    uint timeSinceLastUpdate = timestamp - productBumpedPriceUpdateTime;
    uint priceDrop = PRICE_CHANGE_PER_DAY * timeSinceLastUpdate / 1 days;

    // basePrice = max(targetPrice, bumpedPrice - priceDrop)
    // rewritten to avoid underflow
    return productBumpedPrice < targetPrice + priceDrop
      ? targetPrice
      : productBumpedPrice - priceDrop;
  }

  function calculatePremium(
    StakedProduct memory product,
    uint period,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint targetPrice,
    uint currentBlockTimestamp,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm,
    uint targetPriceDenominator
  ) public pure returns (uint premium, StakedProduct memory) {

    // calculate the bumped price by applying the price bump
    uint priceBump = PRICE_BUMP_RATIO * coverAmount / totalCapacity;

    // apply change in price-per-day towards the target price
    uint basePrice = getBasePrice(
       product.bumpedPrice,
       product.bumpedPriceUpdateTime,
       targetPrice,
       currentBlockTimestamp
     );

    // update product with new bumped price and timestamp
    product.bumpedPrice = (basePrice + priceBump).toUint96();
    product.bumpedPriceUpdateTime = uint32(currentBlockTimestamp);

    // use calculated base price and apply surge pricing if applicable
    uint premiumPerYear = calculatePremiumPerYear(
      basePrice,
      coverAmount,
      initialCapacityUsed,
      totalCapacity,
      nxmPerAllocationUnit,
      allocationUnitsPerNxm,
      targetPriceDenominator
    );

    // calculate the premium for the requested period
    return (premiumPerYear * period / 365 days, product);
  }

  function calculatePremiumPerYear(
    uint basePrice,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm,
    uint targetPriceDenominator
  ) public pure returns (uint) {
    // cover amount has 2 decimals (100 = 1 unit)
    // scale coverAmount to 18 decimals and apply price percentage
    uint basePremium = coverAmount * nxmPerAllocationUnit * basePrice / targetPriceDenominator;
    uint finalCapacityUsed = initialCapacityUsed + coverAmount;

    // surge price is applied for the capacity used above SURGE_THRESHOLD_RATIO.
    // the surge price starts at zero and increases linearly.
    // to simplify things, we're working with fractions/ratios instead of percentages,
    // ie 0 to 1 instead of 0% to 100%, 100% = 1 (a unit).
    //
    // surgeThreshold = SURGE_THRESHOLD_RATIO / SURGE_THRESHOLD_DENOMINATOR
    //                = 90_00 / 100_00 = 0.9
    uint surgeStartPoint = totalCapacity * SURGE_THRESHOLD_RATIO / SURGE_THRESHOLD_DENOMINATOR;

    // Capacity and surge pricing
    //
    //        i        f                         s
    //   ▓▓▓▓▓░░░░░░░░░                          ▒▒▒▒▒▒▒▒▒▒
    //
    //  i - initial capacity used
    //  f - final capacity used
    //  s - surge start point

    // if surge does not apply just return base premium
    // i < f <= s case
    if (finalCapacityUsed <= surgeStartPoint) {
      return basePremium;
    }

    // calculate the premium amount incurred due to surge pricing
    uint amountOnSurge = finalCapacityUsed - surgeStartPoint;
    uint surgePremium = calculateSurgePremium(amountOnSurge, totalCapacity, allocationUnitsPerNxm);

    // if the capacity start point is before the surge start point
    // the surge premium starts at zero, so we just return it
    // i <= s < f case
    if (initialCapacityUsed <= surgeStartPoint) {
      return basePremium + surgePremium;
    }

    // otherwise we need to subtract the part that was already used by other covers
    // s < i < f case
    uint amountOnSurgeSkipped = initialCapacityUsed - surgeStartPoint;
    uint surgePremiumSkipped = calculateSurgePremium(amountOnSurgeSkipped, totalCapacity, allocationUnitsPerNxm);

    return basePremium + surgePremium - surgePremiumSkipped;
  }

  // Calculates the premium for a given cover amount starting with the surge point
  function calculateSurgePremium(
    uint amountOnSurge,
    uint totalCapacity,
    uint allocationUnitsPerNxm
  ) public pure returns (uint) {

    // for every percent of capacity used, the surge price has a +2% increase per annum
    // meaning a +200% increase for 100%, ie x2 for a whole unit (100%) of capacity in ratio terms
    //
    // coverToCapacityRatio = amountOnSurge / totalCapacity
    // surgePriceStart = 0
    // surgePriceEnd = SURGE_PRICE_RATIO * coverToCapacityRatio
    //
    // surgePremium = amountOnSurge * surgePriceEnd / 2
    //              = amountOnSurge * SURGE_PRICE_RATIO * coverToCapacityRatio / 2
    //              = amountOnSurge * SURGE_PRICE_RATIO * amountOnSurge / totalCapacity / 2

    uint surgePremium = amountOnSurge * SURGE_PRICE_RATIO * amountOnSurge / totalCapacity / 2;

    // amountOnSurge has two decimals
    // dividing by ALLOCATION_UNITS_PER_NXM (=100) to normalize the result
    return surgePremium / allocationUnitsPerNxm;
  }

  /* dependencies */

  function changeDependentContractAddress() external {
    // none :)
  }

}