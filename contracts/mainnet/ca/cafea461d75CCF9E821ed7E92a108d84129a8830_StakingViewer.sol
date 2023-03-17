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

/**
 * @dev Simple library that defines basic math functions that allow overflow
 */
library UncheckedMath {

  function uncheckedAdd(uint a, uint b) internal pure returns (uint) {
    unchecked { return a + b; }
  }

  function uncheckedSub(uint a, uint b) internal pure returns (uint) {
    unchecked { return a - b; }
  }

  function uncheckedMul(uint a, uint b) internal pure returns (uint) {
    unchecked { return a * b; }
  }

  function uncheckedDiv(uint a, uint b) internal pure returns (uint) {
    unchecked { return a / b; }
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

import "../../abstract/Multicall.sol";
import "../../interfaces/ICover.sol";
import "../../interfaces/INXMMaster.sol";
import "../../interfaces/IStakingNFT.sol";
import "../../interfaces/IStakingPool.sol";
import "../../interfaces/IStakingProducts.sol";
import "../../interfaces/IStakingPoolFactory.sol";
import "../../libraries/StakingPoolLibrary.sol";
import "../../libraries/UncheckedMath.sol";

contract StakingViewer is Multicall {
  using UncheckedMath for uint;

  struct Pool {
    uint poolId;
    bool isPrivatePool;
    address manager;
    uint poolFee;
    uint maxPoolFee;
    uint activeStake;
    uint currentAPY;
  }

  struct StakingProduct {
    uint productId;
    uint lastEffectiveWeight;
    uint targetWeight;
    uint targetPrice;
    uint bumpedPrice;
  }

  struct Deposit {
    uint tokenId;
    uint trancheId;
    uint stake;
    uint stakeShares;
    uint reward;
  }

  struct Token {
    uint tokenId;
    uint poolId;
    uint activeStake;
    uint expiredStake;
    uint rewards;
    Deposit[] deposits;
  }

  struct TokenPoolMap {
    uint poolId;
    uint tokenId;
  }

  struct AggregatedTokens {
    uint totalActiveStake;
    uint totalExpiredStake;
    uint totalRewards;
  }

  struct AggregatedRewards {
    uint totalRewards;
    uint[] trancheIds;
  }

  INXMMaster public immutable master;
  IStakingNFT public immutable stakingNFT;
  IStakingPoolFactory public immutable stakingPoolFactory;
  IStakingProducts public immutable stakingProducts;

  uint public constant TRANCHE_DURATION = 91 days;
  uint public constant MAX_ACTIVE_TRANCHES = 8;
  uint public constant ONE_NXM = 1 ether;
  uint public constant TRANCHE_ID_AT_DEPLOY = 213; // first active tranche at deploy time
  uint public constant MAX_UINT = type(uint).max;

  constructor(
    INXMMaster _master,
    IStakingNFT _stakingNFT,
    IStakingPoolFactory _stakingPoolFactory,
    IStakingProducts _stakingProducts
  ) {
    master = _master;
    stakingNFT = _stakingNFT;
    stakingPoolFactory = _stakingPoolFactory;
    stakingProducts = _stakingProducts;
  }

  function cover() internal view returns (ICover) {
    return ICover(master.contractAddresses('CO'));
  }

  function stakingPool(uint poolId) public view returns (IStakingPool) {
    return IStakingPool(
      StakingPoolLibrary.getAddress(address(stakingPoolFactory), poolId)
    );
  }

  /* ========== STAKING POOL ========== */

  function getPool(uint poolId) public view returns (Pool memory pool) {

    IStakingPool _stakingPool = stakingPool(poolId);

    pool.poolId = poolId;
    pool.isPrivatePool = _stakingPool.isPrivatePool();
    pool.manager = _stakingPool.manager();
    pool.poolFee = _stakingPool.getPoolFee();
    pool.maxPoolFee = _stakingPool.getMaxPoolFee();
    pool.activeStake = _stakingPool.getActiveStake();
    pool.currentAPY =
      _stakingPool.getActiveStake() != 0
        ? _stakingPool.getRewardPerSecond() * 365 days / _stakingPool.getActiveStake()
        : 0;

    return pool;
  }

  function getPools(uint[] memory poolIds) public view returns (Pool[] memory pools) {

    uint poolsLength = poolIds.length;
    pools = new Pool[](poolsLength);

    for (uint i = 0; i < poolsLength; i++) {
      pools[i] = getPool(poolIds[i]);
    }

    return pools;
  }

  function getAllPools() public view returns (Pool[] memory pools) {

    uint poolCount = stakingPoolFactory.stakingPoolCount();
    pools = new Pool[](poolCount);

    for (uint i = 0; i < poolCount; i++) {
      pools[i] = getPool(i+1); // poolId starts from 1
    }

    return pools;
  }

  function getProductPools(uint productId) public view returns (Pool[] memory pools) {
    uint queueSize = 0;
    uint poolCount = stakingPoolFactory.stakingPoolCount();
    Pool[] memory stakedPoolsQueue = new Pool[](poolCount);

    for (uint i = 1; i <= poolCount; i++) {
      (
        uint lastEffectiveWeight,
        uint targetWeight,
        /* uint targetPrice */,
        /* uint bumpedPrice */,
        uint bumpedPriceUpdateTime
      ) = stakingProducts.getProduct(i, productId);

      if (targetWeight == 0 && lastEffectiveWeight == 0 && bumpedPriceUpdateTime == 0) {
        continue;
      }

      Pool memory pool = getPool(i);
      stakedPoolsQueue[queueSize] = pool;
      queueSize++;
    }
    pools = new Pool[](queueSize);

    for (uint i = 0; i < queueSize; i++) {
      pools[i] = stakedPoolsQueue[i];
    }

    return pools;
  }

  /* ========== PRODUCTS ========== */

  function getPoolProducts(uint poolId) public view returns (StakingProduct[] memory products) {

    uint stakedProductsCount = 0;
    uint coverProductCount = cover().productsCount();
    StakingProduct[] memory stakedProductsQueue = new StakingProduct[](coverProductCount);

    for (uint i = 0; i < coverProductCount; i++) {
      (
        uint lastEffectiveWeight,
        uint targetWeight,
        uint targetPrice,
        uint bumpedPrice,
        uint bumpedPriceUpdateTime
      ) = stakingProducts.getProduct(poolId, i);

      if (targetWeight == 0 && lastEffectiveWeight == 0 && bumpedPriceUpdateTime == 0) {
        continue;
      }

      StakingProduct memory product;
      product.productId = i;
      product.lastEffectiveWeight = lastEffectiveWeight;
      product.targetWeight = targetWeight;
      product.bumpedPrice = bumpedPrice;
      product.targetPrice = targetPrice;

      stakedProductsQueue[stakedProductsCount] = product;
      stakedProductsCount++;
    }

    products = new StakingProduct[](stakedProductsCount);

    for (uint i = 0; i < stakedProductsCount; i++) {
      products[i] = stakedProductsQueue[i];
    }

    return products;
  }

  /* ========== TOKENS AND DEPOSITS ========== */

  function getStakingPoolsOf(
    uint[] memory tokenIds
  ) public view returns (TokenPoolMap[] memory tokenPools) {

    tokenPools = new TokenPoolMap[](tokenIds.length);

    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      uint poolId = stakingNFT.stakingPoolOf(tokenId);
      tokenPools[i] = TokenPoolMap(poolId, tokenId);
    }

    return tokenPools;
  }

  function _getToken(uint poolId, uint tokenId) internal view returns (Token memory token) {

    IStakingPool _stakingPool = stakingPool(poolId);

    uint firstActiveTrancheId = block.timestamp / TRANCHE_DURATION;
    uint depositCount;

    Deposit[] memory depositsQueue;
    {
      uint maxTranches = firstActiveTrancheId - TRANCHE_ID_AT_DEPLOY + MAX_ACTIVE_TRANCHES;
      depositsQueue = new Deposit[](maxTranches);
    }

    // Active tranches

    for (uint i = 0; i < MAX_ACTIVE_TRANCHES; i++) {
      (
        uint lastAccNxmPerRewardShare,
        uint pendingRewards,
        uint stakeShares,
        uint rewardsShares
      ) = _stakingPool.getDeposit(tokenId, firstActiveTrancheId + i);

      if (rewardsShares == 0) {
        continue;
      }

      Deposit memory deposit;
      deposit.tokenId = tokenId;
      deposit.trancheId = firstActiveTrancheId + i;

      uint stake =
        _stakingPool.getActiveStake()
        * stakeShares
        / _stakingPool.getStakeSharesSupply();

      uint newRewardPerShare = _stakingPool.getAccNxmPerRewardsShare().uncheckedSub(lastAccNxmPerRewardShare);
      uint reward = pendingRewards + newRewardPerShare * rewardsShares / ONE_NXM;

      deposit.stake = stake;
      deposit.stakeShares = stakeShares;
      deposit.reward = reward;
      depositsQueue[depositCount++] = deposit;

      token.activeStake += stake;
      token.rewards += reward;
    }

    // Expired tranches

    for (uint i = TRANCHE_ID_AT_DEPLOY; i < firstActiveTrancheId; i++) {
      (
        uint lastAccNxmPerRewardShare,
        uint pendingRewards,
        uint stakeShares,
        uint rewardsShares
      ) = _stakingPool.getDeposit(tokenId, i);

      if (rewardsShares == 0) {
        continue;
      }

      (
        uint accNxmPerRewardShareAtExpiry,
        uint stakeAmountAtExpiry,
        uint stakeShareSupplyAtExpiry
      ) = _stakingPool.getExpiredTranche(i);

      // to avoid this the workaround is to call processExpirations as the first call in the
      // multicall batch. this will require the call to be explicitly be static in js:
      // viewer.callStatic.multicall(...)
      require(stakeShareSupplyAtExpiry != 0, "Tranche expired but expirations were not processed");

      Deposit memory deposit;
      deposit.stake = stakeAmountAtExpiry * stakeShares / stakeShareSupplyAtExpiry;
      deposit.stakeShares = stakeShares;

      uint newRewardPerShare = accNxmPerRewardShareAtExpiry.uncheckedSub(lastAccNxmPerRewardShare);
      deposit.reward = pendingRewards + newRewardPerShare * rewardsShares / ONE_NXM;

      deposit.tokenId = tokenId;
      deposit.trancheId = i;

      depositsQueue[depositCount] = deposit;
      depositCount++;

      token.expiredStake += deposit.stake;
      token.rewards += deposit.reward;
    }

    token.tokenId = tokenId;
    token.poolId = poolId;
    token.deposits = new Deposit[](depositCount);

    for (uint i = 0; i < depositCount; i++) {
      token.deposits[i] = depositsQueue[i];
    }

    return token;
  }

  function getToken(uint tokenId) public view returns (Token memory token) {
    uint poolId = stakingNFT.stakingPoolOf(tokenId);
    return _getToken(poolId, tokenId);
  }

  function getTokens(uint[] memory tokenIds) public view returns (Token[] memory tokens) {

    tokens = new Token[](tokenIds.length);

    for (uint i = 0; i < tokenIds.length; i++) {
      uint poolId = stakingNFT.stakingPoolOf(tokenIds[i]);
      tokens[i] = _getToken(poolId, tokenIds[i]);
    }

    return tokens;
  }

  function getAggregatedTokens(
    uint[] calldata tokenIds
  ) public view returns (AggregatedTokens memory aggregated) {

    for (uint i = 0; i < tokenIds.length; i++) {
      Token memory token = getToken(tokenIds[i]);
      aggregated.totalActiveStake += token.activeStake;
      aggregated.totalExpiredStake += token.expiredStake;
      aggregated.totalRewards += token.rewards;
    }

    return aggregated;
  }

  function getManagerRewards (uint[] memory poolIds) public view returns (Token[] memory tokens) {
    tokens = new Token[](poolIds.length);

    for (uint i = 0; i < poolIds.length; i++) {
      tokens[i] = _getToken(poolIds[i], 0);
    }
  }

  function processExpirations(uint[] memory poolIds) public {
    for (uint i = 0; i < poolIds.length; i++) {
      stakingPool(poolIds[i]).processExpirations(true);
    }
  }
}