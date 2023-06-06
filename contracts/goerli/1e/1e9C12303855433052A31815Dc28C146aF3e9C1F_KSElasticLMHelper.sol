// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {MathConstants as C} from '../libraries/MathConstants.sol';
import {FullMath} from '../libraries/FullMath.sol';
import {LMMath} from 'contracts/libraries/LMMath.sol';
import {ReinvestmentMath} from '../libraries/ReinvestmentMath.sol';

import {IKSElasticLMHelper} from '../interfaces/liquidityMining/IKSElasticLMHelper.sol';
import {IBasePositionManager} from '../interfaces/liquidityMining/IBasePositionManager.sol';
import {IPoolStorage} from '../interfaces/liquidityMining/IPoolStorage.sol';
import {IKSElasticLMV2 as IELMV2} from '../interfaces/liquidityMining/IKSElasticLMV2.sol';

import {KSAdmin} from './base/KSAdmin.sol';

contract KSElasticLMHelper is IKSElasticLMHelper, KSAdmin {
  error PositionNotEligible();

  using SafeERC20 for IERC20;

  event RescueFund(address token, uint256 amount);

  function rescueFund(IERC20 token, uint256 amount) external isAdmin {
    if (address(token) == address(0)) {
      (bool success, ) = payable(msg.sender).call{value: amount}('');
      require(success, 'rescueFund: failed to collect native');
    } else {
      token.safeTransfer(msg.sender, amount);
    }
    emit RescueFund(address(token), amount);
  }

  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) external view override returns (bool) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IBasePositionManager(nftContract).addressToPoolId(pAddress) == pData.poolId;
  }

  /// @dev use virtual to be overrided to mock data for fuzz tests
  function getActiveTime(
    address pAddr,
    address nftContract,
    uint256 nftId
  ) external view override returns (uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IPoolStorage(pAddr).getSecondsPerLiquidityInside(pData.tickLower, pData.tickUpper);
  }

  function getSignedFee(
    address nftContract,
    uint256 nftId
  ) external view override returns (int256) {
    uint256 feeGrowthInsideLast = _getFee(nftContract, nftId);
    return int256(feeGrowthInsideLast);
  }

  function getSignedFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) external view override returns (int256) {
    uint256 feeGrowthInside = _getFeePool(poolAddress, nftContract, nftId);
    return int256(feeGrowthInside);
  }

  function getLiq(address nftContract, uint256 nftId) external view override returns (uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return pData.liquidity;
  }

  function getPair(
    address nftContract,
    uint256 nftId
  ) external view override returns (address, address) {
    (, IBasePositionManager.PoolInfo memory poolInfo) = IBasePositionManager(nftContract)
      .positions(nftId);

    return (poolInfo.token0, poolInfo.token1);
  }

  // ======== read from farm ============
  function getCurrentUnclaimedReward(
    IELMV2 farm,
    uint256 nftId
  ) public view override returns (uint256[] memory currentUnclaimedRewards) {
    (
      ,
      uint256 fId,
      ,
      uint256 sLiq,
      uint256[] memory sLastSumRewardPerLiquidity,
      uint256[] memory sRewardUnclaimeds
    ) = farm.getStake(nftId);

    (
      ,
      ,
      IELMV2.PhaseInfo memory phase,
      uint256 fLiq,
      ,
      uint256[] memory sumRewardPerLiquidity,
      uint32 lastTouchedTime
    ) = farm.getFarm(fId);

    currentUnclaimedRewards = new uint256[](phase.rewards.length);

    for (uint256 i; i < phase.rewards.length; i++) {
      uint256 tempSumRewardPerLiquidity = _updateRwPLiq(
        phase.rewards[i].rewardAmount,
        phase.startTime,
        phase.endTime,
        lastTouchedTime,
        fLiq,
        phase.isSettled,
        sumRewardPerLiquidity[i]
      );

      currentUnclaimedRewards[i] =
        sRewardUnclaimeds[i] +
        FullMath.mulDivFloor(
          tempSumRewardPerLiquidity - sLastSumRewardPerLiquidity[i],
          sLiq,
          C.TWO_POW_96
        );
    }
  }

  function getEligibleRanges(
    IELMV2 farm,
    uint256 fId,
    uint256 nftId
  ) external view returns (uint256[] memory indexesValid) {
    address nftAddr = address(farm.getNft());
    (address poolAddr, IELMV2.RangeInfo[] memory rangesInfo, , , , , ) = farm.getFarm(fId);
    if (!_checkPool(poolAddr, nftAddr, nftId)) revert PositionNotEligible();

    (, int24 tickLower, int24 tickUpper, ) = getPositionInfo(nftAddr, nftId);

    uint256 length = rangesInfo.length;
    uint256 count;
    for (uint256 i; i < length; ++i) {
      if (
        tickLower <= rangesInfo[i].tickLower &&
        tickUpper >= rangesInfo[i].tickUpper &&
        !rangesInfo[i].isRemoved
      ) ++count;
    }

    indexesValid = new uint256[](count);
    for (uint256 j = length - 1; j > 0; --j) {
      if (
        tickLower <= rangesInfo[j].tickLower &&
        tickUpper >= rangesInfo[j].tickUpper &&
        !rangesInfo[j].isRemoved
      ) {
        indexesValid[count - 1] = j;
        --count;
      }
    }
  }

  function getUserInfo(
    IELMV2 farm,
    address user
  ) external view returns (UserInfo[] memory result) {
    uint256[] memory listNFTs = farm.getDepositedNFTs(user);
    result = new UserInfo[](listNFTs.length);
    for (uint256 i = 0; i < listNFTs.length; ++i) {
      (, uint256 fId, uint256 rId, uint256 sLiq, , ) = farm.getStake(listNFTs[i]);
      result[i].nftId = listNFTs[i];
      result[i].fId = fId;
      result[i].rangeId = rId;
      result[i].liquidity = sLiq;
      result[i].currentUnclaimedRewards = getCurrentUnclaimedReward(farm, listNFTs[i]);
    }
  }

  // ======== read from posManager ============
  function getPositionInfo(
    address nftContract,
    uint256 nftId
  ) public view override returns (uint256, int24, int24, uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return (pData.poolId, pData.tickLower, pData.tickUpper, pData.liquidity);
  }

  function checkPosition(
    address pAddress,
    address nftContract,
    int24 tickLower,
    int24 tickUpper,
    uint256[] memory nftIds
  ) external view override returns (bool isInvalid, uint128[] memory liquidities) {
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

  function _updateRwPLiq(
    uint256 rwAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 lastTouchedTime,
    uint256 totalLiquidity,
    bool isSettled,
    uint256 curSumRewardPerLiquidity
  ) internal view returns (uint256) {
    if (block.timestamp > lastTouchedTime && !isSettled) {
      uint256 deltaSumRewardPerLiquidity = LMMath.calcSumRewardPerLiquidity(
        rwAmount,
        startTime,
        endTime,
        uint32(block.timestamp),
        lastTouchedTime,
        totalLiquidity
      );

      curSumRewardPerLiquidity += deltaSumRewardPerLiquidity;
    }

    return curSumRewardPerLiquidity;
  }

  function _checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) internal view returns (bool) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IBasePositionManager(nftContract).addressToPoolId(pAddress) == pData.poolId;
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

  function _getFee(address nftContract, uint256 nftId) internal view virtual returns (uint256) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return pData.feeGrowthInsideLast;
  }

  function _getFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) internal view virtual returns (uint256 feeGrowthInside) {
    IBasePositionManager.Position memory position = _getPositionFromNFT(nftContract, nftId);
    (, , uint256 lowerValue, ) = IPoolStorage(poolAddress).ticks(position.tickLower);
    (, , uint256 upperValue, ) = IPoolStorage(poolAddress).ticks(position.tickUpper);
    (, int24 currentTick, , ) = IPoolStorage(poolAddress).getPoolState();
    uint256 feeGrowthGlobal = IPoolStorage(poolAddress).getFeeGrowthGlobal();

    {
      (uint128 baseL, uint128 reinvestL, uint128 reinvestLLast) = IPoolStorage(poolAddress)
        .getLiquidityState();
      uint256 rTotalSupply = IERC20(poolAddress).totalSupply();
      // logic ported from Pool._syncFeeGrowth()
      uint256 rMintQty = ReinvestmentMath.calcrMintQty(
        uint256(reinvestL),
        uint256(reinvestLLast),
        baseL,
        rTotalSupply
      );

      if (rMintQty != 0) {
        // fetch governmentFeeUnits
        (, uint24 governmentFeeUnits) = IPoolStorage(poolAddress).factory().feeConfiguration();
        unchecked {
          if (governmentFeeUnits != 0) {
            uint256 rGovtQty = (rMintQty * governmentFeeUnits) / C.FEE_UNITS;
            rMintQty -= rGovtQty;
          }
          feeGrowthGlobal += FullMath.mulDivFloor(rMintQty, C.TWO_POW_96, baseL);
        }
      }
    }
    unchecked {
      if (currentTick < position.tickLower) {
        feeGrowthInside = lowerValue - upperValue;
      } else if (currentTick >= position.tickUpper) {
        feeGrowthInside = upperValue - lowerValue;
      } else {
        feeGrowthInside = feeGrowthGlobal - (lowerValue + upperValue);
      }
    }
  }
}

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

  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
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

  function WETH() external view returns (address);

  function mint(
    MintParams calldata params
  )
    external
    payable
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

  function addLiquidity(
    IncreaseLiquidityParams calldata params
  )
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function removeLiquidity(
    RemoveLiquidityParams calldata params
  ) external returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function syncFeeGrowth(uint256 tokenId) external returns (uint256 additionalRTokenOwed);

  function burnRTokens(
    BurnRTokenParams calldata params
  ) external returns (uint256 rTokenQty, uint256 amount0, uint256 amount1);

  function transferAllTokens(address token, uint256 minAmount, address recipient) external payable;

  function unwrapWeth(uint256 minAmount, address recipient) external payable;
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
pragma solidity ^0.8.0;

import {IBasePositionManager} from './IBasePositionManager.sol';
import {IKSElasticLMV2 as IELMV2} from './IKSElasticLMV2.sol';
import {IKyberSwapFarmingToken} from './periphery/IKyberSwapFarmingToken.sol';

interface IKSElasticLMHelper {
  struct UserInfo {
    uint256 nftId;
    uint256 fId;
    uint256 rangeId;
    uint256 liquidity;
    uint256[] currentUnclaimedRewards;
  }

  //use by both LMv1 and LMv2
  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (bool);

  function getLiq(address nftContract, uint256 nftId) external view returns (uint128);

  function getPair(address nftContract, uint256 nftId) external view returns (address, address);

  //use by LMv1
  function getActiveTime(
    address pAddr,
    address nftContract,
    uint256 nftId
  ) external view returns (uint128);

  function getSignedFee(address nftContract, uint256 nftId) external view returns (int256);

  function getSignedFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (int256);

  //use by LMv2
  function getCurrentUnclaimedReward(
    IELMV2 farm,
    uint256 nftId
  ) external view returns (uint256[] memory currentUnclaimedRewards);

  function getUserInfo(IELMV2 farm, address user) external view returns (UserInfo[] memory);

  function getEligibleRanges(
    IELMV2 farm,
    uint256 fId,
    uint256 nftId
  ) external view returns (uint256[] memory indexesValid);

  function checkPosition(
    address pAddress,
    address nftContract,
    int24 tickLower,
    int24 tickUpper,
    uint256[] memory nftIds
  ) external view returns (bool isInvalid, uint128[] memory liquidities);

  function getPositionInfo(
    address nftContract,
    uint256 nftId
  ) external view returns (uint256, int24, int24, uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IKyberSwapFarmingToken} from './periphery/IKyberSwapFarmingToken.sol';
import {IKSElasticLMHelper} from './IKSElasticLMHelper.sol';

interface IKSElasticLMV2 {
  error Forbidden();
  error EmergencyEnabled();

  error InvalidRange();
  error InvalidTime();
  error InvalidReward();

  error PositionNotEligible();
  error FarmNotFound();
  error InvalidFarm();
  error NotOwner();
  error StakeNotFound();
  error RangeNotMatch();
  error RangeNotFound();
  error PhaseSettled();
  error InvalidInput();
  error LiquidityNotMatch();
  error FailToAdd();
  error FailToRemove();
  error Expired();

  event UpdateEmergency(bool enableOrDisable);
  event UpdateTokenCode(bytes farmingTokenCode);
  event UpdateHelper(IKSElasticLMHelper helper);
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
  event UpdateLiquidity(uint256 indexed fId, uint256 nftId, uint256 liquidity);
  event Withdraw(uint256[] nftIds, address receiver);
  event WithdrawEmergency(uint256 nftId, address receiver);
  event ClaimReward(
    uint256 fId,
    uint256[] nftIds,
    address token,
    uint256 amount,
    address receiver
  );

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

  struct RemoveLiquidityInput {
    uint256 nftId;
    uint128 liquidity;
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
    uint256 liquidity;
    address farmingToken;
    uint256[] sumRewardPerLiquidity;
    uint32 lastTouchedTime;
  }

  struct StakeInfo {
    address owner;
    uint256 fId;
    uint256 rangeId;
    uint256 liquidity;
    uint256[] lastSumRewardPerLiquidity;
    uint256[] rewardUnclaimed;
  }

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

  /// @dev add liquidity of nfts when liquidity already added on Elastic Pool
  /// @dev only can call by nfts's owner
  /// @dev calculate reward earned, update stakeInfo, mint an amount of farmingToken to msg.sender
  /// @param fId farm's id
  /// @param rangeId rangeId of deposited nfts
  /// @param nftIds nfts to add liquidity
  function addLiquidity(uint256 fId, uint256 rangeId, uint256[] calldata nftIds) external;

  /// @dev remove liquidity of nfts from Elastic Pool
  /// @dev only can call by nfts's owner
  /// @dev calculate reward earned, update stakeInfo, mint/burn an amount of farmingToken
  /// @param nftId id of nft to remove liquidity
  /// @param liquidity amount to remove from nft
  /// @param amount0Min min amount of token0 should receive
  /// @param amount1Min min amount of token1 should receive
  /// @param deadline deadline of remove liquidity tx
  /// @param isClaimFee is also burnRTokens or not
  function removeLiquidity(
    uint256 nftId,
    uint128 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isClaimFee,
    bool isReceiveNative
  ) external;

  /// @dev claim fee from Elastic Pool
  /// @dev only can call by nfts's owner
  /// @param fId farm's id
  /// @param nftIds nfts to claim
  /// @param amount0Min min amount of token0 should receive
  /// @param amount1Min min amount of token1 should receive
  /// @param deadline deadline of remove liquidity tx
  function claimFee(
    uint256 fId,
    uint256[] calldata nftIds,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isReceiveNative
  ) external;

  /// @dev withdraw nfts in case emergency
  /// @dev only can call by nfts's owner
  /// @dev in normal case, abandon all rewards, must return farmingToken
  /// @dev incase emergencyEnabled, bypass all calculation
  /// @param nftIds nfts to withdraw
  function withdrawEmergency(uint256[] calldata nftIds) external;

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
      uint256 liquidity,
      address farmingToken,
      uint256[] memory sumRewardPerLiquidity,
      uint32 lastTouchedTime
    );

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs);

  function getStake(
    uint256 nftId
  )
    external
    view
    returns (
      address owner,
      uint256 fId,
      uint256 rangeId,
      uint256 liquidity,
      uint256[] memory lastSumRewardPerLiquidity,
      uint256[] memory rewardUnclaimeds
    );
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
    uint256 totalLiquidity
  ) internal pure returns (uint256 deltaSumRewardPerLiquidity) {
    uint256 joinedDuration;
    uint256 duration;

    unchecked {
      joinedDuration = (curTime < endTime ? curTime : endTime) - lastTouchedTime;
      duration = endTime - startTime;
      deltaSumRewardPerLiquidity =
        (rewardAmount * joinedDuration * C.TWO_POW_96) /
        (duration * totalLiquidity);
    }
  }

  function calcRewardAmount(
    uint256 curSumRewardPerLiquidity,
    uint256 lastSumRewardPerLiquidity,
    uint256 liquidity
  ) internal pure returns (uint256 rewardAmount) {
    uint256 deltaSumRewardPerLiquidity;

    unchecked {
      deltaSumRewardPerLiquidity = curSumRewardPerLiquidity - lastSumRewardPerLiquidity;
      rewardAmount = (deltaSumRewardPerLiquidity * liquidity) / C.TWO_POW_96;
    }
  }

  function calcRewardUntilNow(
    uint256 rewardAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 curTime
  ) internal pure returns (uint256 rewardAmountNow) {
    uint256 joinedDuration;
    uint256 duration;

    unchecked {
      joinedDuration = curTime - startTime;
      duration = endTime - startTime;
      rewardAmountNow = (rewardAmount * joinedDuration) / duration;
    }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {FullMath} from './FullMath.sol';

/// @title Contains helper function to calculate the number of reinvestment tokens to be minted
library ReinvestmentMath {
  /// @dev calculate the mint amount with given reinvestL, reinvestLLast, baseL and rTotalSupply
  /// contribution of lp to the increment is calculated by the proportion of baseL with reinvestL + baseL
  /// then rMintQty is calculated by mutiplying this with the liquidity per reinvestment token
  /// rMintQty = rTotalSupply * (reinvestL - reinvestLLast) / reinvestLLast * baseL / (baseL + reinvestL)
  function calcrMintQty(
    uint256 reinvestL,
    uint256 reinvestLLast,
    uint128 baseL,
    uint256 rTotalSupply
  ) internal pure returns (uint256 rMintQty) {
    uint256 lpContribution = FullMath.mulDivFloor(
      baseL,
      reinvestL - reinvestLLast,
      baseL + reinvestL
    );
    rMintQty = FullMath.mulDivFloor(rTotalSupply, lpContribution, reinvestLLast);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract KSAdmin {
  address public admin;
  mapping(address => bool) public operators; // address => bool

  event TransferAdmin(address indexed admin);
  event UpdateOperator(address indexed user, bool grantOrRevoke);

  modifier isAdmin() {
    require(msg.sender == admin, 'forbidden');
    _;
  }

  modifier isOperator() {
    require(operators[msg.sender], 'forbidden');
    _;
  }

  constructor() {
    admin = msg.sender;
    operators[msg.sender] = true;
  }

  function transferAdmin(address _admin) external virtual isAdmin {
    require(_admin != address(0), 'forbidden');

    admin = _admin;

    emit TransferAdmin(_admin);
  }

  function updateOperator(address user, bool grantOrRevoke) external isAdmin {
    operators[user] = grantOrRevoke;

    emit UpdateOperator(user, grantOrRevoke);
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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