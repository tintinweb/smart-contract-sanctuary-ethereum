// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IBasePositionManager {
  struct Position {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    // the ID of the pool with which this token is connected
    uint80 poolId;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the current rToken that the position owed
    uint256 rTokenOwed;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct PoolInfo {
    address token0;
    uint16 fee;
    address token1;
  }

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct BurnRTokenParams {
    uint256 tokenId;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function positions(
    uint256 tokenId
  ) external view returns (Position memory pos, PoolInfo memory info);

  function addressToPoolId(address pool) external view returns (uint80);

  function addLiquidity(
    IncreaseLiquidityParams calldata params
  )
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function removeLiquidity(
    RemoveLiquidityParams calldata params
  ) external returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function burnRTokens(
    BurnRTokenParams calldata params
  ) external returns (uint256 rTokenQty, uint256 amount0, uint256 amount1);

  function transferAllTokens(address token, uint256 minAmount, address recipient) external payable;

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function approve(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint16 indexed swapFeeBps,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint16 indexed swapFeeBps, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint16 governmentFeeBps);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeBps Swap fee, in basis points.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint16 swapFeeBps) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in basis points
  function feeConfiguration() external view returns (address _feeTo, uint16 _governmentFeeBps);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address token0,
      address token1,
      uint16 swapFeeBps,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeBps Desired swap fee for the pool, in basis points
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeBps The fee amount to enable, in basis points
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint16 swapFeeBps, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IKyberSwapFarmingToken} from './periphery/IKyberSwapFarmingToken.sol';

interface IKyberSwapElasticLMV3 {
  error Forbidden();
  error EmergencyEnabled();
  error EmergencyDisabled();

  error InvalidRange();
  error InvalidTime();
  error InvalidReward();
  error InvalidLength();

  error PositionNotEligible();
  error FarmNotFound();
  error InvalidFarm();
  error NotOwner();
  error StakeNotFound();
  error NotEnoughRewardLeft();
  error RangeNotFound();
  error PhaseNotSettled();
  error PhaseSettled();
  error InvalidInput();
  error FailToAdd();
  error FailToRemove();

  event TransferAdmin(address oldAdmin, address newAdmin);
  event EnabledEmergency();
  event DisabledEmergency();
  event UpdateOperator(address operator, bool grantOrRevoke);
  event UpdateTokenCode();
  event WithdrawUnusedRewards(address token, uint256 amount, address receiver);

  event AddFarm(
    uint256 indexed fId,
    address poolAddress,
    RangeInput[] ranges,
    PhaseInput phase,
    address farmingToken
  );
  event AddPhase(uint256 indexed fId, PhaseInput phase);
  event ForceClosePhase(uint256 indexed fId);
  event AddRange(uint256 indexed fId, RangeInput range);
  event RemoveRange(uint256 indexed fId, uint256 rangeId);
  event ExpandEndTimeAndRewards(uint256 indexed fId, uint256 duration, uint256[] rewardAmounts);

  event Deposit(
    uint256 indexed fId,
    uint256 rangeId,
    uint256[] nftIds,
    address indexed depositer,
    address receiver
  );
  event UpdateLiquidity(
    uint256 indexed fId,
    uint256 nftId,
    uint128 oldLiquidity,
    uint128 newLiquidity
  );
  event Withdraw(uint256[] nftIds, address receiver);
  event WithdrawEmergency(uint256 nftId, address receiver);
  event ClaimReward(uint256 fId, uint256 nftId, address token, uint256 amount, address receiver);

  struct RangeInput {
    int24 tickLower;
    int24 tickUpper;
    uint32 weight;
  }

  struct RewardInput {
    address rewardToken;
    uint256 rewardAmount;
  }

  struct PhaseInput {
    uint32 startTime;
    uint32 endTime;
    RewardInput[] rewards;
  }

  struct RangeInfo {
    int24 tickLower;
    int24 tickUpper;
    uint32 weight;
    bool isRemoved;
  }

  struct PhaseInfo {
    uint32 startTime;
    uint32 endTime;
    bool isSettled;
    RewardInput[] rewards;
  }

  struct FarmInfo {
    address poolAddress;
    RangeInfo[] ranges;
    PhaseInfo phase;
    uint128 liquidity;
    IKyberSwapFarmingToken farmingToken;
  }

  struct StakeInfo {
    address owner;
    uint256 fId;
    uint256 rangeId;
    uint128 liquidity;
  }

  struct RewardInfo {
    uint256 lastSumRewardPerLiquidity;
    uint256 rewardUnclaimed;
  }

  // ======== admin ============
  /// @dev transfer admin to another address
  /// @param _admin new admin address
  function transferAdmin(address _admin) external;

  /// @dev setup emergency mode
  /// @dev  when it enabled allow user to withdrawEmergency their nft without any condition, also forbidden deposit & updateLiquidity
  /// @dev  when it disable, user withdrawEmgergency must do all calculations, allow to deposit & updateLiquidity
  function emergencySetup(bool isEnable) external;

  /// @dev grant/revoke operator rights for an address
  /// @param user operator address
  /// @param grantOrRevoke true to grant, false to revoke
  function updateOperator(address user, bool grantOrRevoke) external;

  /// @dev update creation code of FarmingToken, use to deploy when adding new farm
  /// @param _farmingTokenCreationCode creation code to update
  function updateTokenCode(bytes memory _farmingTokenCreationCode) external;

  /// @dev withdraw leftover rewards from the contract for admin
  /// @param tokens address of tokens
  /// @param amounts amount of tokens
  function withdrawUnusedRewards(address[] calldata tokens, uint256[] calldata amounts) external;

  // ======== operator ============
  /// @dev create a new farm matched with an Elastic Pool
  /// @param poolAddress elastic pool address
  /// @param ranges eligible farm ranges
  /// @param phase farm first phase
  /// @param isUsingToken set true to deploy FarmingToken
  /// @return fId newly created farm's id
  function addFarm(
    address poolAddress,
    RangeInput[] calldata ranges,
    PhaseInput calldata phase,
    bool isUsingToken
  ) external returns (uint256 fId);

  /// @dev add a phase to farm, settle old phase if it's not settled yet
  /// @param fId farm's id
  /// @param phaseData phase data to add
  function addPhase(uint256 fId, PhaseInput calldata phaseData) external;

  /// @dev force close a phase before it's endTime
  /// @param fId farm's id
  function forceClosePhase(uint256 fId) external;

  /// @dev add an eligible range to farm
  /// @param fId farm's id
  /// @param range range data to add
  function addRange(uint256 fId, RangeInput calldata range) external;

  /// @dev remove an eliggible range from farm
  /// @dev it's status will be set to removed
  /// @dev but it's data still there incase we need to calculate liquidity
  /// @param fId farm's id
  /// @param rangeId range's id to remove
  function removeRange(uint256 fId, uint256 rangeId) external;

  /// @dev expand endTime for a duration, adding more rewards
  /// @param fId farm's id
  /// @param duration duration to add
  /// @param rewardAmounts reward amounts to add
  function expandEndTimeAndRewards(
    uint256 fId,
    uint32 duration,
    uint256[] calldata rewardAmounts
  ) external;

  // ======== user ============
  /// @dev deposit nfts to farm
  /// @dev store curRewardPerLiq now to stake info, mint an amount of farmingToken (if needed) to msg.sender
  /// @param fId farm's id
  /// @param rangeId rangeId to add, should use quoter to get best APR rangeId
  /// @param nftIds nfts to deposit
  function deposit(
    uint256 fId,
    uint256 rangeId,
    uint256[] memory nftIds,
    address receiver
  ) external;

  /// @dev claim reward earned for nfts
  /// @param fId farm's id
  /// @param nftIds nfts to claim
  function claimReward(uint256 fId, uint256[] memory nftIds) external;

  /// @dev withdraw nfts from farm
  /// @dev only can call by nfts's owner, also claim reward earned
  /// @dev burn an amount of farmingToken (if needed) from msg.sender
  /// @param fId farm's id
  /// @param nftIds nfts to withdraw
  function withdraw(uint256 fId, uint256[] memory nftIds) external;

  /// @dev update liquidity of nfts when addLiquidity from Elastic Pool
  /// @dev only can call by nfts's owner
  /// @dev calculate reward earned, reset stakeInfo, mint an amount of farmingToken to msg.sender
  /// @param fId farm's id
  /// @param nftIds nfts to update liquidity
  function updateLiquidity(uint256 fId, uint256 rangeId, uint256[] calldata nftIds) external;

  /// @dev withdraw nfts in case emergency
  /// @dev only can call by nfts's owner
  /// @dev in normal case, abandon all rewards, must return farmingToken
  /// @dev incase emergencyEnabled, bypass all calculation when emergencyEnabled
  /// @param fId farm's id
  /// @param nftIds nfts to withdraw
  function withdrawEmergency(uint256 fId, uint256[] calldata nftIds) external;

  // ======== view ============

  function getAdmin() external view returns (address);

  function getNft() external view returns (IERC721);

  function getFarm(
    uint256 fId
  )
    external
    view
    returns (
      address poolAddress,
      RangeInfo[] memory ranges,
      PhaseInfo memory phase,
      uint128 liquidity,
      IKyberSwapFarmingToken
    );

  function getStake(
    uint256 nftId
  ) external view returns (address owner, uint256 fId, uint256 rangeId, uint128 liquidity);

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs);

  function getSumRewardPerLiquidity(uint256 fId, address token) external view returns (uint256);

  function getLastSumRewardPerLiquidity(
    uint256 fId,
    uint256 nftId,
    address token
  ) external view returns (uint256);

  function getLastUpdatedTime(uint256 fId) external view returns (uint32);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IFactory} from './IFactory.sol';

interface IPoolStorage {
  struct PoolData {
    uint160 sqrtP;
    int24 nearestCurrentTick;
    int24 currentTick;
    bool locked;
    uint128 baseL;
    uint128 reinvestL;
    uint128 reinvestLLast;
    uint256 feeGrowthGlobal;
    uint128 secondsPerLiquidityGlobal;
    uint32 secondsPerLiquidityUpdateTime;
  }

  // data stored for each initialized individual tick
  struct TickData {
    // gross liquidity of all positions in tick
    uint128 liquidityGross;
    // liquidity quantity to be added | removed when tick is crossed up | down
    int128 liquidityNet;
    // fee growth per unit of liquidity on the other side of this tick (relative to current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 feeGrowthOutside;
    // seconds spent on the other side of this tick (relative to current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint128 secondsPerLiquidityOutside;
  }

  /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
  /// @return The contract address
  function factory() external view returns (IFactory);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (IERC20);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (IERC20);

  /// @notice The fee to be charged for a swap in basis points
  /// @return The swap fee in basis points
  function swapFeeBps() external view returns (uint16);

  /// @notice The pool tick distance
  /// @dev Ticks can only be initialized and used at multiples of this value
  /// It remains an int24 to avoid casting even though it is >= 1.
  /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
  /// @return The tick distance
  function tickDistance() external view returns (int24);

  /// @notice Maximum gross liquidity that an initialized tick can have
  /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxTickLiquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Returns the information about a position by the position's key
  /// @return liquidity the liquidity quantity of the position
  /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );

  /// @notice Fetches the pool's liquidity values
  /// @return baseL pool's base liquidity without reinvest liqudity
  /// @return reinvestL the liquidity is reinvested into the pool
  /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
  function getLiquidityState()
    external
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint128 reinvestLLast
    );

  /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
  function getFeeGrowthGlobal() external view returns (uint256);

  /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
  /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
  function getSecondsPerLiquidityData()
    external
    view
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

  /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
  /// @param tickLower The lower tick (of a position)
  /// @param tickUpper The upper tick (of a position)
  /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
  /// between the 2 ticks, per unit of liquidity.
  function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/IAccessControl.sol';

interface IKyberSwapFarmingToken is IAccessControl {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function mint(address account, uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */

  function burn(address account, uint256 amount) external;

  function addWhitelist(address account) external;

  function removeWhitelist(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
/// @dev Code has been modified to be compatible with sol 0.8
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDivFloor(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      require(denominator > 0, '0 denom');
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1, 'denom <= prod1');

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    uint256 twos = denominator & (~denominator + 1);
    // Divide denominator by power of two
    assembly {
      denominator := div(denominator, twos)
    }

    // Divide [prod1 prod0] by the factors of two
    assembly {
      prod0 := div(prod0, twos)
    }
    // Shift in bits from prod1 into prod0. For this we need
    // to flip `twos` such that it is 2**256 / twos.
    // If twos is zero, then it becomes one
    assembly {
      twos := add(div(sub(0, twos), twos), 1)
    }
    unchecked {
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;

      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
    }
    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivCeiling(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDivFloor(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      result++;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';

library LMMath {
  function calcSumRewardPerLiquidity(
    uint256 rewardAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 curTime,
    uint32 lastTouchedTime,
    uint128 totalLiquidity
  ) internal pure returns (uint256) {
    uint32 joinedDuration;
    uint32 duration;

    unchecked {
      joinedDuration = (curTime < endTime ? curTime : endTime) - lastTouchedTime;
      duration = endTime - startTime;
    }

    return (rewardAmount * joinedDuration * C.TWO_POW_48) / (duration * totalLiquidity);
  }

  function calcRewardAmount(
    uint256 curSumRewardPerLiquidity,
    uint256 lastSumRewardPerLiquidity,
    uint128 liquidity
  ) internal pure returns (uint256) {
    uint256 deltaSumRewardPerLiquidity;

    unchecked {
      deltaSumRewardPerLiquidity = curSumRewardPerLiquidity - lastSumRewardPerLiquidity;
    }

    return (deltaSumRewardPerLiquidity * liquidity) / C.TWO_POW_48;
  }

  function calcRewardUntilNow(
    uint256 rewardAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 curTime
  ) internal pure returns (uint256) {
    uint32 joinedDuration;
    uint32 duration;

    unchecked {
      joinedDuration = curTime - startTime;
      duration = endTime - startTime;
    }

    return (rewardAmount * joinedDuration) / duration;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title Contains constants needed for math libraries
library MathConstants {
  uint256 internal constant TWO_POW_48 = 2 ** 48;
  uint256 internal constant TWO_POW_96 = 2 ** 96;
  uint128 internal constant MIN_LIQUIDITY = 100_000;
  uint24 internal constant FEE_UNITS = 100_000;
  uint8 internal constant RES_96 = 96;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {LMMath} from '../libraries/LMMath.sol';

import {IKyberSwapElasticLMV3} from '../interfaces/liquidityMining/IKyberSwapElasticLMV3.sol';
import {IKyberSwapFarmingToken} from '../interfaces/liquidityMining/periphery/IKyberSwapFarmingToken.sol';
import {IBasePositionManager} from '../interfaces/liquidityMining/IBasePositionManager.sol';
import {IPoolStorage} from '../interfaces/liquidityMining/IPoolStorage.sol';

import {LMHelperV2} from './LMHelperV2.sol';

contract KyberSwapElasticLMV3 is IKyberSwapElasticLMV3, LMHelperV2, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.UintSet;

  IERC721 private immutable nft;
  address private admin;
  bytes private farmingTokenCreationCode;
  mapping(address => bool) private operators; // address => bool
  mapping(uint256 => FarmInfo) private farms; // fId => FarmInfo
  mapping(uint256 => StakeInfo) private stakes; // sId => stakeInfo
  mapping(uint256 => uint32) private lastUpdatedTime; // fId => timestamp
  mapping(uint256 => mapping(uint256 => mapping(address => RewardInfo))) private rewardInfos; // fId => sId => tokenAddress => tokenAmount
  mapping(uint256 => mapping(address => uint256)) private sumRewardPerLiquidity; // fId => tokenAddress => tokenAmount
  mapping(address => EnumerableSet.UintSet) private depositNFTs;

  uint256 public farmCount;
  bool public emergencyEnabled;

  constructor(IERC721 _nft) {
    admin = msg.sender;
    nft = _nft;
  }

  receive() external payable {}

  // ======== admin ============
  /// @inheritdoc IKyberSwapElasticLMV3
  function transferAdmin(address _admin) external override {
    if (msg.sender != admin) revert Forbidden();
    admin = _admin;

    emit TransferAdmin(msg.sender, _admin);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function emergencySetup(bool isEnable) external override {
    if (msg.sender != admin) revert Forbidden();
    emergencyEnabled = isEnable;
    emit DisabledEmergency();
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function updateOperator(address user, bool grantOrRevoke) external override {
    if (msg.sender != admin) revert Forbidden();
    operators[user] = grantOrRevoke;

    emit UpdateOperator(user, grantOrRevoke);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function updateTokenCode(bytes memory _farmingTokenCreationCode) external override {
    if (msg.sender != admin) revert Forbidden();
    farmingTokenCreationCode = _farmingTokenCreationCode;

    emit UpdateTokenCode();
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function withdrawUnusedRewards(
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external override {
    if (msg.sender != admin) revert Forbidden();

    uint256 rewardTokenLength = tokens.length;
    for (uint256 i; i < rewardTokenLength; ) {
      safeTransfer(tokens[i], msg.sender, amounts[i]);

      emit WithdrawUnusedRewards(tokens[i], amounts[i], msg.sender);

      unchecked {
        ++i;
      }
    }
  }

  // ======== operator ============
  /// @inheritdoc IKyberSwapElasticLMV3
  function addFarm(
    address poolAddress,
    RangeInput[] calldata ranges,
    PhaseInput calldata phase,
    bool isUsingToken
  ) external override returns (uint256 fId) {
    if (!_isOperator(msg.sender)) revert Forbidden();

    fId = farmCount;
    FarmInfo storage farm = farms[fId];

    for (uint256 i; i < ranges.length; ) {
      if (ranges[i].tickLower > ranges[i].tickUpper || ranges[i].weight == 0)
        revert InvalidRange();

      farm.ranges.push(
        IKyberSwapElasticLMV3.RangeInfo({
          tickLower: ranges[i].tickLower,
          tickUpper: ranges[i].tickUpper,
          weight: ranges[i].weight,
          isRemoved: false
        })
      );

      unchecked {
        ++i;
      }
    }

    if (phase.startTime < block.timestamp || phase.endTime <= phase.startTime)
      revert InvalidTime();

    farm.poolAddress = poolAddress;
    farm.phase.startTime = phase.startTime;
    farm.phase.endTime = phase.endTime;

    if (phase.rewards.length == 0) revert InvalidReward();

    for (uint256 i; i < phase.rewards.length; ) {
      farm.phase.rewards.push(phase.rewards[i]);

      unchecked {
        ++i;
      }
    }

    address destination;
    if (isUsingToken) {
      bytes memory creationCode = abi.encodePacked(
        farmingTokenCreationCode,
        abi.encode(msg.sender)
      );
      bytes32 salt = keccak256(abi.encode(msg.sender, fId));
      assembly {
        destination := create2(0, add(creationCode, 32), mload(creationCode), salt)
        if iszero(extcodesize(destination)) {
          revert(0, 0)
        }
      }
      farm.farmingToken = IKyberSwapFarmingToken(destination);
    }

    lastUpdatedTime[fId] = phase.startTime;

    unchecked {
      ++farmCount;
    }

    emit AddFarm(fId, poolAddress, ranges, phase, destination);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function addPhase(uint256 fId, PhaseInput calldata phaseInput) external override {
    _checkRoleAndFarm(fId);
    if (phaseInput.startTime < block.timestamp || phaseInput.endTime <= phaseInput.startTime)
      revert InvalidTime();

    FarmInfo memory farm = farms[fId];
    uint256 length = farm.phase.rewards.length;

    if (phaseInput.rewards.length != length) revert InvalidReward();

    uint32 lastTouchedTime = lastUpdatedTime[fId];
    if (block.timestamp > lastTouchedTime && farm.liquidity > 0 && !farm.phase.isSettled) {
      for (uint256 i; i < length; ) {
        RewardInput memory reward = farm.phase.rewards[i];
        _updateSumRewardPerLiquidity(
          fId,
          reward,
          farm.phase.startTime,
          farm.phase.endTime,
          lastTouchedTime,
          farm.liquidity,
          farm.phase.isSettled
        );

        unchecked {
          ++i;
        }
      }
    }

    PhaseInfo storage phase = farms[fId].phase;

    phase.startTime = phaseInput.startTime;
    phase.endTime = phaseInput.endTime;

    for (uint256 i; i < length; ) {
      if (farm.phase.rewards[i].rewardToken != phaseInput.rewards[i].rewardToken)
        revert InvalidReward();
      phase.rewards[i].rewardAmount = phaseInput.rewards[i].rewardAmount;

      unchecked {
        ++i;
      }
    }

    if (farm.phase.isSettled) phase.isSettled = false;
    lastUpdatedTime[fId] = phaseInput.startTime;

    emit AddPhase(fId, phaseInput);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function forceClosePhase(uint256 fId) external override {
    _checkRoleAndFarm(fId);
    FarmInfo memory farm = farms[fId];

    if (farm.phase.endTime < block.timestamp || farm.phase.isSettled) revert PhaseSettled();
    _updateFarmSumRewardPerLiquidity(fId, farm);
    farms[fId].phase.isSettled = true;

    emit ForceClosePhase(fId);
  }

  function addRange(uint256 fId, RangeInput calldata range) external override {
    _checkRoleAndFarm(fId);
    if (range.tickLower > range.tickUpper || range.weight == 0) revert InvalidRange();

    farms[fId].ranges.push(
      IKyberSwapElasticLMV3.RangeInfo({
        tickLower: range.tickLower,
        tickUpper: range.tickUpper,
        weight: range.weight,
        isRemoved: false
      })
    );

    emit AddRange(fId, range);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function removeRange(uint256 fId, uint256 rangeId) external override {
    _checkRoleAndFarm(fId);
    if (rangeId >= farms[fId].ranges.length || farms[fId].ranges[rangeId].isRemoved)
      revert RangeNotFound();

    farms[fId].ranges[rangeId].isRemoved = true;

    emit RemoveRange(fId, rangeId);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function expandEndTimeAndRewards(
    uint256 fId,
    uint32 duration,
    uint256[] calldata rewardAmounts
  ) external override {
    _checkRoleAndFarm(fId);
    FarmInfo memory farm = farms[fId];

    if (farm.phase.endTime < block.timestamp) revert InvalidTime();

    uint256 length = rewardAmounts.length;
    if (length != farm.phase.rewards.length) revert InvalidReward();

    PhaseInfo storage phase = farms[fId].phase;
    if (phase.isSettled) revert PhaseSettled();

    if (block.timestamp > farm.phase.startTime) {
      _updateFarmSumRewardPerLiquidity(fId, farm);

      for (uint256 i; i < length; ) {
        uint256 rewardAmountNow = LMMath.calcRewardUntilNow(
          farm.phase.rewards[i].rewardAmount,
          farm.phase.startTime,
          farm.phase.endTime,
          uint32(block.timestamp)
        );

        phase.rewards[i].rewardAmount =
          farm.phase.rewards[i].rewardAmount -
          rewardAmountNow +
          rewardAmounts[i];

        unchecked {
          ++i;
        }
      }

      phase.startTime = uint32(block.timestamp);
      lastUpdatedTime[fId] = uint32(block.timestamp);
    } else {
      for (uint256 i; i < length; ) {
        phase.rewards[i].rewardAmount = farm.phase.rewards[i].rewardAmount + rewardAmounts[i];

        unchecked {
          ++i;
        }
      }
    }

    if (duration != 0) phase.endTime = farm.phase.endTime + duration;

    emit ExpandEndTimeAndRewards(fId, duration, rewardAmounts);
  }

  // ======== user ============
  /// @inheritdoc IKyberSwapElasticLMV3
  function deposit(
    uint256 fId,
    uint256 rangeId,
    uint256[] calldata nftIds,
    address receiver
  ) external override {
    if (fId >= farmCount) revert FarmNotFound();
    FarmInfo memory farm = farms[fId];
    if (rangeId >= farm.ranges.length || farm.ranges[rangeId].isRemoved) revert RangeNotFound();
    if (farm.phase.endTime < block.timestamp || farm.phase.isSettled) revert PhaseSettled();
    if (emergencyEnabled) revert EmergencyEnabled();

    (bool isInvalid, uint128[] memory nftLiquidities) = checkPosition(
      farm.poolAddress,
      address(nft),
      farm.ranges[rangeId].tickLower,
      farm.ranges[rangeId].tickUpper,
      nftIds
    );

    if (isInvalid) revert PositionNotEligible();

    uint32 weight = farm.ranges[rangeId].weight;
    uint128 totalLiquidity;
    uint256 length = nftIds.length;
    for (uint256 i; i < length; ) {
      uint256 nftId = nftIds[i];
      uint128 liquidityWithWeight = nftLiquidities[i] * weight;

      nft.transferFrom(msg.sender, address(this), nftId);
      if (!depositNFTs[receiver].add(nftId)) revert FailToAdd();
      StakeInfo storage stake = stakes[nftId];
      stake.owner = receiver;
      stake.fId = fId;
      stake.rangeId = rangeId;
      stake.liquidity = liquidityWithWeight;
      totalLiquidity += liquidityWithWeight;

      unchecked {
        ++i;
      }
    }

    _join(fId, farm, nftIds, totalLiquidity);

    if (address(farm.farmingToken) != address(0)) farm.farmingToken.mint(receiver, totalLiquidity);

    emit Deposit(fId, rangeId, nftIds, msg.sender, receiver);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function claimReward(uint256 fId, uint256[] calldata nftIds) external override nonReentrant {
    FarmInfo memory farm = farms[fId];
    _claimReward(fId, farm, nftIds, msg.sender);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function withdraw(uint256 fId, uint256[] calldata nftIds) external override nonReentrant {
    FarmInfo memory farm = farms[fId];
    uint128[] memory liquidities = _claimReward(fId, farm, nftIds, msg.sender);

    uint256 length = nftIds.length;
    uint128 totalLiq;
    for (uint256 i; i < length; ) {
      totalLiq += liquidities[i];

      delete stakes[nftIds[i]];

      if (!depositNFTs[msg.sender].remove(nftIds[i])) revert FailToRemove();
      nft.transferFrom(address(this), msg.sender, nftIds[i]);

      unchecked {
        ++i;
      }
    }

    farms[fId].liquidity = farm.liquidity - totalLiq;
    if (address(farm.farmingToken) != address(0)) farm.farmingToken.burn(msg.sender, totalLiq);

    emit Withdraw(nftIds, msg.sender);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  function updateLiquidity(
    uint256 fId,
    uint256 rangeId,
    uint256[] memory nftIds
  ) external override {
    if (fId >= farmCount) revert FarmNotFound();
    FarmInfo memory farm = farms[fId];
    if (rangeId >= farm.ranges.length || farm.ranges[rangeId].isRemoved) revert RangeNotFound();
    if (farm.phase.endTime < block.timestamp || farm.phase.isSettled) revert PhaseSettled();
    if (emergencyEnabled) revert EmergencyEnabled();

    uint256 length = nftIds.length;
    uint128[] memory curLiquidities = new uint128[](length);
    uint128[] memory newLiquidities = new uint128[](length);

    for (uint256 i; i < length; ) {
      StakeInfo memory stake = stakes[nftIds[i]];
      if (stake.owner != msg.sender) revert NotOwner();
      if (stake.fId != fId || stake.liquidity == 0) revert StakeNotFound();

      curLiquidities[i] = stake.liquidity;

      (, , , uint128 newLiquidity) = getPositionInfo(address(nft), nftIds[i]);
      newLiquidities[i] = newLiquidity * farm.ranges[stake.rangeId].weight;

      unchecked {
        ++i;
      }
    }

    _updateLiquidity(fId, farm, nftIds, curLiquidities, newLiquidities, msg.sender);
  }

  /// @inheritdoc IKyberSwapElasticLMV3
  // function removeLiquidityAndClaimFee(
  //   uint256 fId,
  //   uint256 rangeId,
  //   uint256[] calldata nftIds,
  //   uint128[] calldata liquidities,
  //   uint256 amount0Min,
  //   uint256 amount1Min,
  //   uint256 deadline,
  //   bool claimFee
  // ) external override {
  //   FarmInfo memory farm = farms[fId];

  //   if (liquidities.length != nftIds.length) revert InvalidInput();

  //   uint128[] memory curLiquidities = new uint128[](nftIds.length);
  //   uint128[] memory newLiquidities = new uint128[](nftIds.length);

  //   for (uint256 i; i < nftIds.length; ) {
  //     uint256 nftId = nftIds[i];
  //     StakeInfo memory stake = stakes[nftId];

  //     if (stake.owner != msg.sender) revert NotOwner();
  //     if (stake.fId != fId || stake.liquidity == 0) revert StakeNotFound();
  //     if (stake.rangeId != rangeId) revert RangeNotFound();

  //     curLiquidities[i] = stake.liquidity;

  //     _removeLiquidity(nftId, liquidities[i], deadline, claimFee);

  //     (, , , uint128 newLiquidity) = getPositionInfo(address(nft), nftId);
  //     newLiquidities[i] = newLiquidity * farm.ranges[stake.rangeId].weight;

  //     unchecked {
  //       ++i;
  //     }
  //   }

  //   _updateLiquidity(fId, farm, nftIds, curLiquidities, newLiquidities, msg.sender);
  //   _transferTokens(farm.poolAddress, amount0Min, amount1Min, msg.sender);
  // }

  /// @inheritdoc IKyberSwapElasticLMV3
  function withdrawEmergency(uint256 fId, uint256[] calldata nftIds) external override {
    FarmInfo memory farm = farms[fId];
    uint256 length = nftIds.length;

    uint128 deltaLiq;
    for (uint256 i; i < length; ) {
      uint256 nftId = nftIds[i];
      StakeInfo memory stake = stakes[nftId];
      if (stake.owner != msg.sender) revert NotOwner();
      if (stake.fId != fId || stake.liquidity == 0) revert StakeNotFound();

      if (!emergencyEnabled) {
        deltaLiq += stake.liquidity;
        if (!depositNFTs[stake.owner].remove(nftId)) revert FailToRemove();
      }

      delete stakes[nftId];
      nft.transferFrom(address(this), stake.owner, nftId);

      emit WithdrawEmergency(nftId, stake.owner);

      unchecked {
        ++i;
      }
    }

    if (deltaLiq > 0) {
      farms[fId].liquidity -= deltaLiq;
      if (address(farm.farmingToken) != address(0)) farm.farmingToken.burn(msg.sender, deltaLiq);
    }
  }

  // ======== getter ============
  function getAdmin() external view override returns (address) {
    return admin;
  }

  function getNft() external view override returns (IERC721) {
    return nft;
  }

  function getFarm(
    uint256 fId
  )
    external
    view
    override
    returns (
      address poolAddress,
      RangeInfo[] memory ranges,
      PhaseInfo memory phase,
      uint128 liquidity,
      IKyberSwapFarmingToken
    )
  {
    return (
      farms[fId].poolAddress,
      farms[fId].ranges,
      farms[fId].phase,
      farms[fId].liquidity,
      farms[fId].farmingToken
    );
  }

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs) {
    listNFTs = depositNFTs[user].values();
  }

  function getStake(
    uint256 nftId
  )
    external
    view
    override
    returns (address owner, uint256 fId, uint256 rangeId, uint128 liquidity)
  {
    return (
      stakes[nftId].owner,
      stakes[nftId].fId,
      stakes[nftId].rangeId,
      stakes[nftId].liquidity
    );
  }

  function getSumRewardPerLiquidity(
    uint256 fId,
    address token
  ) external view override returns (uint256) {
    return sumRewardPerLiquidity[fId][token];
  }

  function getLastSumRewardPerLiquidity(
    uint256 fId,
    uint256 nftId,
    address token
  ) external view override returns (uint256) {
    return rewardInfos[fId][nftId][token].lastSumRewardPerLiquidity;
  }

  function getLastUpdatedTime(uint256 fId) external view override returns (uint32) {
    return lastUpdatedTime[fId];
  }

  // ======== internal ============
  /// @dev join farm for nfts
  /// @dev update sumRewardPerLiquidity
  /// @dev store nft lastSumRewardPerLiquidiy by current sumRewardPerLiquidity
  /// @dev update farm's liquidity
  /// @param fId farm's id
  /// @param farm farmInfo memory for reading
  /// @param nftIds nfts to join
  /// @param totalLiquidity total liquidity of nfts pre-calculated
  function _join(
    uint256 fId,
    FarmInfo memory farm,
    uint256[] calldata nftIds,
    uint128 totalLiquidity
  ) internal {
    uint256[] memory curSumRewardPerLiquidity = _updateFarmSumRewardPerLiquidity(fId, farm);
    uint256 length = farm.phase.rewards.length;
    for (uint256 i; i < length; ) {
      uint256 nftLength = nftIds.length;
      for (uint256 j; j < nftLength; ) {
        RewardInfo storage rewardInfo = rewardInfos[fId][nftIds[j]][
          farm.phase.rewards[i].rewardToken
        ];

        rewardInfo.lastSumRewardPerLiquidity = curSumRewardPerLiquidity[i];

        unchecked {
          ++j;
        }
      }

      unchecked {
        ++i;
      }
    }

    farms[fId].liquidity = farm.liquidity + totalLiquidity;
  }

  /// @dev claim reward for nfts
  /// @param fId farm's id
  /// @param farm farm memory for reading
  /// @param nftIds nfts for claim reward
  /// @param receiver reward receiver
  /// @return liquidities nft's liquidities for further calulation
  function _claimReward(
    uint256 fId,
    FarmInfo memory farm,
    uint256[] memory nftIds,
    address receiver
  ) internal returns (uint128[] memory liquidities) {
    uint256 length = nftIds.length;
    liquidities = new uint128[](length);

    for (uint256 i; i < length; ) {
      uint256 nftId = nftIds[i];
      StakeInfo memory stake = stakes[nftId];

      if (stake.fId != fId || stake.liquidity == 0) revert StakeNotFound();
      if (stake.owner != receiver) revert NotOwner();

      liquidities[i] = stake.liquidity;

      unchecked {
        ++i;
      }
    }

    _updateAndTransferReward(fId, farm, nftIds, liquidities, msg.sender);
  }

  /// @dev update liquidity of a nft deposited to farm
  /// @dev there is 2 cases:
  /// @dev user add liquidity on elastic pool, totalNewLiquidity > totalCurLiquidity
  /// @dev user use removeLiquidityAndClaimFee, totalCurLiquidity > totalNewLiquidity
  /// @dev update sumRewardPerLiquidity of farm, update rewardInfo of nfts
  /// @dev update farm's total liquidity
  /// @param fId farm's id
  /// @param farm farm memory for reading
  /// @param nftIds nfts to update
  /// @param curLiquidities total current liquidity of nfts already pre-calculated
  /// @param newLiquidities total new liquidity of nfts already pre-calculated
  function _updateLiquidity(
    uint256 fId,
    FarmInfo memory farm,
    uint256[] memory nftIds,
    uint128[] memory curLiquidities,
    uint128[] memory newLiquidities,
    address receiver
  ) internal {
    uint256[] memory curSumRewardPerLiquidities = _updateFarmSumRewardPerLiquidity(fId, farm);
    uint256 nftLength = nftIds.length;
    uint128 totalCurLiquidity;
    uint128 totalNewLiquidity;

    for (uint256 i; i < nftLength; ) {
      _updateRewardInfo(
        fId,
        nftIds[i],
        curLiquidities[i],
        farm.phase.rewards,
        curSumRewardPerLiquidities,
        false,
        receiver
      );

      stakes[nftIds[i]].liquidity = newLiquidities[i];

      totalCurLiquidity += curLiquidities[i];
      totalNewLiquidity += newLiquidities[i];

      emit UpdateLiquidity(fId, nftIds[i], curLiquidities[i], newLiquidities[i]);

      unchecked {
        ++i;
      }
    }

    unchecked {
      if (address(farm.farmingToken) != address(0) && totalNewLiquidity != totalCurLiquidity) {
        if (totalNewLiquidity > totalCurLiquidity) {
          farm.farmingToken.mint(receiver, totalNewLiquidity - totalNewLiquidity);
        } else {
          farm.farmingToken.burn(receiver, totalCurLiquidity - totalNewLiquidity);
        }
      }
    }

    farms[fId].liquidity = farm.liquidity + totalNewLiquidity - totalCurLiquidity;
  }

  /// @dev remove liquidiy of nft from posManager
  /// @param nftId nft's id
  /// @param liquidity liquidity amount to remove
  /// @param deadline removeLiquidity deadline
  /// @param claimFee true to burnRToken, false to not
  function _removeLiquidity(
    uint256 nftId,
    uint128 liquidity,
    uint256 deadline,
    bool claimFee
  ) internal {
    IBasePositionManager posManager = IBasePositionManager(address(nft));

    IBasePositionManager.RemoveLiquidityParams memory removeLiq = IBasePositionManager
      .RemoveLiquidityParams({
        tokenId: nftId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: deadline
      });
    posManager.removeLiquidity(removeLiq);

    if (claimFee) {
      IBasePositionManager.BurnRTokenParams memory burnRToken = IBasePositionManager
        .BurnRTokenParams({tokenId: nftId, amount0Min: 0, amount1Min: 0, deadline: deadline});
      posManager.burnRTokens(burnRToken);
    }
  }

  /// @dev transfer tokens from removeLiquidity (and burnRToken if any) to receiver
  /// @param poolAddress address of Elastic Pool
  /// @param amount0Min minimum amount of token0 should receive
  /// @param amount1Min minimum amount of token1 should receive
  /// @param receiver receiver of tokens
  function _transferTokens(
    address poolAddress,
    uint256 amount0Min,
    uint256 amount1Min,
    address receiver
  ) internal {
    IBasePositionManager posManager = IBasePositionManager(address(nft));

    posManager.transferAllTokens(
      address(IPoolStorage(poolAddress).token0()),
      amount0Min,
      receiver
    );
    posManager.transferAllTokens(
      address(IPoolStorage(poolAddress).token1()),
      amount1Min,
      receiver
    );
  }

  /// @dev update rewardInfos then transfer for multiple positions
  /// @param fId farm's id
  /// @param farm farm memory for reading
  /// @param nftIds nfts to update
  /// @param liquidities liquidity of nfts
  /// @param receiver reward receiver
  function _updateAndTransferReward(
    uint256 fId,
    FarmInfo memory farm,
    uint256[] memory nftIds,
    uint128[] memory liquidities,
    address receiver
  ) internal {
    uint256[] memory curSumRewardPerLiquidities = _updateFarmSumRewardPerLiquidity(fId, farm);
    uint256 nftLength = nftIds.length;

    for (uint256 i; i < nftLength; ) {
      _updateRewardInfo(
        fId,
        nftIds[i],
        liquidities[i],
        farm.phase.rewards,
        curSumRewardPerLiquidities,
        true,
        receiver
      );
    }
  }

  /// @dev calculate and update rewardUnclaimed, lastSumRewardPerLiquidity for a single position
  /// @dev rewardAmount = (sumRewardPerLiq - lastSumRewardPerLiq) * stake.liquidiy
  /// @dev if transferRewardUnclaimed =  true then transfer all rewardUnclaimed, update rewardUnclaimed = 0
  /// @dev if transferRewardUnclaimed =  false then update rewardUnclaimed = rewardUnclaimed + rewardAmount
  /// @dev update lastSumRewardPerLiquidity
  /// @param fId farm's id
  /// @param nftId nft's id to update
  /// @param liquidity nft's liquidity
  /// @param rewards current phase rewards
  /// @param curSumRewardPerLiquidities current sumRewardPerLiquidities of farm, indexing by reward
  /// @param isClaim is transfer reward or not
  /// @param receiver reward receiver
  function _updateRewardInfo(
    uint256 fId,
    uint256 nftId,
    uint128 liquidity,
    RewardInput[] memory rewards,
    uint256[] memory curSumRewardPerLiquidities,
    bool isClaim,
    address receiver
  ) internal {
    uint256 rewardLength = rewards.length;
    for (uint256 i; i < rewardLength; ) {
      address rewardToken = rewards[i].rewardToken;
      uint256 rewardUnclaimed = rewardInfos[fId][nftId][rewardToken].rewardUnclaimed;

      uint256 rewardAmount = LMMath.calcRewardAmount(
        curSumRewardPerLiquidities[i],
        rewardInfos[fId][nftId][rewardToken].lastSumRewardPerLiquidity,
        liquidity
      );

      if (rewardAmount != 0) {
        rewardUnclaimed += rewardAmount;

        if (isClaim) {
          rewardInfos[fId][nftId][rewardToken].rewardUnclaimed = 0;
          safeTransfer(rewardToken, receiver, rewardUnclaimed);

          emit ClaimReward(fId, nftId, rewardToken, rewardAmount, receiver);
        } else {
          rewardInfos[fId][nftId][rewardToken].rewardUnclaimed = rewardUnclaimed;
        }
      }

      rewardInfos[fId][nftId][rewardToken].lastSumRewardPerLiquidity = curSumRewardPerLiquidities[
        i
      ];

      unchecked {
        ++i;
      }
    }
  }

  /// @dev update farm's sumRewardPerLiquidity
  /// @dev update farm's lastUpdatedTime
  /// @dev if block.timestamp > farm's endTime then update phase to settled
  /// @param fId farm's id
  /// @param farm farm memory for reading
  /// @return curSumRewardPerLiquidity array of sumRewardPerLiquidity until now
  function _updateFarmSumRewardPerLiquidity(
    uint256 fId,
    FarmInfo memory farm
  ) internal returns (uint256[] memory curSumRewardPerLiquidity) {
    uint32 lastTouchedTime = lastUpdatedTime[fId];
    uint256 length = farm.phase.rewards.length;
    curSumRewardPerLiquidity = new uint256[](length);

    for (uint256 i; i < length; ) {
      curSumRewardPerLiquidity[i] = _updateSumRewardPerLiquidity(
        fId,
        farm.phase.rewards[i],
        farm.phase.startTime,
        farm.phase.endTime,
        lastTouchedTime,
        farm.liquidity,
        farm.phase.isSettled
      );

      unchecked {
        ++i;
      }
    }

    if (block.timestamp > lastTouchedTime) lastUpdatedTime[fId] = uint32(block.timestamp);
    if (block.timestamp > farm.phase.endTime) farms[fId].phase.isSettled = true;
  }

  /// @dev update sumRewardPerLiquidity for each reward token
  /// @dev if block.timestamp > lastTouched means sumRewardPerLiquidity had increase
  /// @dev if not then just return it
  /// @param fId farm's id
  /// @param reward reward to calculate
  /// @param startTime farm's startTime
  /// @param endTime farm's endTime
  /// @param lastTouchedTime farm's lastTouchedTime
  /// @param totalLiquidity farm's total liquidity
  /// @param isSettled farm phase is settled or not
  /// @return sumRewardPerLiquidity until now
  function _updateSumRewardPerLiquidity(
    uint256 fId,
    RewardInput memory reward,
    uint32 startTime,
    uint32 endTime,
    uint32 lastTouchedTime,
    uint128 totalLiquidity,
    bool isSettled
  ) internal returns (uint256) {
    uint256 tempSumRewardPerLiquidity = sumRewardPerLiquidity[fId][reward.rewardToken];

    if (block.timestamp > lastTouchedTime && totalLiquidity > 0 && !isSettled) {
      uint256 deltaSumRewardPerLiquidity = LMMath.calcSumRewardPerLiquidity(
        reward.rewardAmount,
        startTime,
        endTime,
        uint32(block.timestamp),
        lastTouchedTime,
        totalLiquidity
      );

      tempSumRewardPerLiquidity += deltaSumRewardPerLiquidity;
      sumRewardPerLiquidity[fId][reward.rewardToken] = tempSumRewardPerLiquidity;
    }

    return tempSumRewardPerLiquidity;
  }

  /// @dev check if someone is operator or not
  /// @param user address of user
  /// @return bool true if address is operator, false if not
  function _isOperator(address user) internal view returns (bool) {
    return operators[user];
  }

  function _checkRoleAndFarm(uint256 fId) private view {
    if (!_isOperator(msg.sender)) revert Forbidden();
    if (fId >= farmCount) revert InvalidFarm();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {MathConstants as C} from '../libraries/MathConstants.sol';
import {FullMath} from '../libraries/FullMath.sol';

import {IBasePositionManager} from '../interfaces/liquidityMining/IBasePositionManager.sol';

abstract contract LMHelperV2 {
  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  function getBalance(address token) internal view returns (uint256) {
    return
      token == ETH_ADDRESS
        ? payable(address(this)).balance
        : IERC20(token).balanceOf(address(this));
  }

  function safeTransfer(address token, address to, uint256 amount) internal {
    (bool success, ) = token == ETH_ADDRESS
      ? payable(to).call{value: amount}('')
      : token.call(abi.encodeWithSignature('transfer(address,uint256)', to, amount));

    assert(success);
  }

  function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
    (bool success, ) = token.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', from, to, amount)
    );

    assert(success);
  }

  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) public view returns (bool) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IBasePositionManager(nftContract).addressToPoolId(pAddress) == pData.poolId;
  }

  function checkPosition(
    address pAddress,
    address nftContract,
    int24 tickLower,
    int24 tickUpper,
    uint256[] memory nftIds
  ) internal view returns (bool isInvalid, uint128[] memory liquidities) {
    uint256 length = nftIds.length;
    liquidities = new uint128[](length);
    uint256 poolId = IBasePositionManager(nftContract).addressToPoolId(pAddress);
    for (uint256 i; i < length; ) {
      (
        uint256 nftPoolId,
        int24 nftTickLower,
        int24 nftTickUpper,
        uint128 liquidity
      ) = getPositionInfo(nftContract, nftIds[i]);

      if (
        poolId != nftPoolId ||
        tickLower < nftTickLower ||
        nftTickUpper < tickUpper ||
        liquidity == 0
      ) {
        isInvalid = true;
        break;
      }

      liquidities[i] = liquidity;

      unchecked {
        ++i;
      }
    }
  }

  function getPositionInfo(
    address nftContract,
    uint256 nftId
  ) internal view returns (uint256, int24, int24, uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return (pData.poolId, pData.tickLower, pData.tickUpper, pData.liquidity);
  }

  function _getPositionFromNFT(
    address nftContract,
    uint256 nftId
  ) internal view returns (IBasePositionManager.Position memory) {
    (IBasePositionManager.Position memory pData, ) = IBasePositionManager(nftContract).positions(
      nftId
    );
    return pData;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}