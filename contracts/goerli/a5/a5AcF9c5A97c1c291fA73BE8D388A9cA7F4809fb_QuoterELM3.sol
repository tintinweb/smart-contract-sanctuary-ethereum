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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IKyberSwapFarmingToken} from './periphery/IKyberSwapFarmingToken.sol';

interface IKyberSwapElasticLMV3 {
  error Forbidden();

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

  event AddFarm(
    uint256 indexed fId,
    address poolAddress,
    RangeInput[] ranges,
    PhaseInput phase,
    address farmingToken
  );
  event AddRange(uint256 indexed fId, RangeInput range);
  event RemoveRange(uint256 indexed fId, uint256 rangeId);
  event AddPhase(uint256 indexed fId, PhaseInput phase);
  event UpdateEndTime(uint256 indexed fId, uint256 newEndTime);
  event UpdateRewards(uint256 indexed fId, uint256[] rewards);
  event Deposit(uint256 indexed fId, uint32 weight, uint256[] nftIds, address receiver);
  event Withdraw(uint256[] nftIds, address receiver);
  event WithdrawEmergency(uint256 nftId, address receiver);
  event ClaimReward(uint256[] nftIds, address[] receivers);

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

  function addFarm(
    address poolAddress,
    RangeInput[] calldata ranges,
    PhaseInput calldata phase,
    bool isUsingToken
  ) external returns (uint256 fId);

  function addPhase(uint256 fId, PhaseInput calldata phaseData) external;

  function addRange(uint256 fId, RangeInput calldata range) external;

  function claimReward(uint256 fId, uint256[] memory nftIds) external;

  function deposit(
    uint256 fId,
    uint256 rangeId,
    uint256[] memory nftId,
    address receiver
  ) external;

  function forceClosePhase(uint256 fId) external;

  function removeRange(uint256 fId, uint256 rangeId) external;

  function updateEndTimeAndRewards(uint256 fId, uint32 endTime, uint256[] calldata rewardAmounts) external;

  function updateLiquidity(uint256 nftId) external;

  function transferAdmin(address _admin) external;

  function withdraw(uint256 fId, uint256[] memory nftIds) external;

  function withdrawEmergency(uint256 nftId) external;

  function withdrawUnsedRewards(address[] calldata tokens, uint256[] calldata amounts) external;

  function claimFee(
    uint256[] calldata nftIds,
    uint128[] calldata liquidities,
    uint256[] calldata amount0Mins,
    uint256[] calldata amount1Mins,
    uint256 deadline
  ) external;

  function updateOperator(address user, bool grantOrRevoke) external;

  function updateTokenCode(bytes memory _farmingTokenCreationCode) external;

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
pragma solidity ^0.8.0;

import {IKyberSwapElasticLMV3} from '../IKyberSwapElasticLMV3.sol';
import {IKyberSwapFarmingToken} from './IKyberSwapFarmingToken.sol';

interface IQuoterELM3 {
  
  struct UserInfo {
    uint256 nftId;
    uint256 fId;
    uint256 rangeId;
    uint128 liquidity;
    uint256[] currentUnclaimedRewards;
  }

  function getUnclaimedReward(uint256 nftId)
    external
    view
    returns (uint256[] memory currentUnclaimedRewards);

  function getUserInfo(address user) external view returns (UserInfo[] memory);

  function getEligibleRanges(uint256 fId, uint256 nftId)
    external
    view
    returns (uint256[] memory indexesValid);
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

import {FullMath} from './FullMath.sol';
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
    uint256 joinedDuration = (curTime < endTime ? curTime : endTime) - lastTouchedTime;
    uint256 duration = endTime - startTime;

    uint256 numerator = FullMath.mulDivFloor(rewardAmount, joinedDuration, duration);
    return FullMath.mulDivFloor(numerator, C.TWO_POW_96, totalLiquidity);
  }

  function calcRewardAmount(
    uint256 curSumRewardPerLiquidity,
    uint256 lastSumRewardPerLiquidity,
    uint128 liquidity
  ) internal pure returns (uint256) {
    return
      FullMath.mulDivFloor(
        curSumRewardPerLiquidity - lastSumRewardPerLiquidity,
        liquidity,
        C.TWO_POW_96
      );
  }

  function calcRewardUntilNow(
    uint256 rewardAmount,
    uint32 startTime,
    uint32 endTime,
    uint256 curTime
  ) internal pure returns (uint256) {
    return FullMath.mulDivFloor(rewardAmount, curTime - startTime, endTime - startTime);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title Contains constants needed for math libraries
library MathConstants {
  uint256 internal constant TWO_POW_96 = 2**96;
  uint128 internal constant MIN_LIQUIDITY = 100_000;
  uint24 internal constant FEE_UNITS = 100_000;
  uint8 internal constant RES_96 = 96;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IQuoterELM3} from '../../interfaces/liquidityMining/periphery/IQuoterELM3.sol';
import {IKyberSwapElasticLMV3 as IELM3} from '../../interfaces/liquidityMining/IKyberSwapElasticLMV3.sol';
import {IKyberSwapFarmingToken} from '../../interfaces/liquidityMining/periphery/IKyberSwapFarmingToken.sol';
import {FullMath} from '../../libraries/FullMath.sol';
import {LMMath} from '../../libraries/LMMath.sol';
import {MathConstants as C} from '../../libraries/MathConstants.sol';
import {IBasePositionManager} from '../../interfaces/liquidityMining/IBasePositionManager.sol';

interface ILMHelperV2 {
  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (bool);

  function getPositionInfo(
    address nftContract,
    uint256 nftId
  ) external view returns (int24, int24, uint128);

  function _calcSumRewardPerLiquidity(
    uint256 rewardAmount,
    uint32 joinedDuration,
    uint32 duration,
    uint128 totalLiquidity
  ) external pure returns (uint256);
}

contract QuoterELM3 is IQuoterELM3 {
  error PositionNotEligible();

  IELM3 public immutable farmSC;

  constructor(IELM3 _farmSC) {
    farmSC = _farmSC;
  }

  //reward will around this result
  function getUnclaimedReward(
    uint256 nftId
  ) public view returns (uint256[] memory currentUnclaimedRewards) {
    (, uint256 fId, , uint256 sLiq) = farmSC.getStake(nftId);
    (, , IELM3.PhaseInfo memory phase, uint128 fLiq, ) = farmSC.getFarm(fId);
    currentUnclaimedRewards = new uint256[](phase.rewards.length);

    for (uint256 i; i < phase.rewards.length; i++) {
      uint256 tempSumRewardPerLiquidity = _updateRwPLiq(
        fId,
        phase.rewards[i].rewardToken,
        phase.rewards[i].rewardAmount,
        phase.startTime,
        phase.endTime,
        farmSC.getLastUpdatedTime(fId),
        fLiq,
        phase.isSettled
      );
      currentUnclaimedRewards[i] += FullMath.mulDivFloor(
        tempSumRewardPerLiquidity -
          farmSC.getLastSumRewardPerLiquidity(fId, nftId, phase.rewards[i].rewardToken),
        sLiq,
        C.TWO_POW_96
      );
    }
  }

  function _updateRwPLiq(
    uint256 fId,
    address rwToken,
    uint256 rwAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 lastTouchedTime,
    uint128 totalLiquidity,
    bool isSettled
  ) private view returns (uint256 tempSumRewardPerLiquidity) {
    // ILMHelperV2 helper = ILMHelperV2(address(farmSC));
    tempSumRewardPerLiquidity = farmSC.getSumRewardPerLiquidity(fId, rwToken);

    if (block.timestamp > lastTouchedTime && totalLiquidity > 0 && !isSettled) {
      uint256 deltaSumRewardPerLiquidity = LMMath.calcSumRewardPerLiquidity(
        rwAmount,
        startTime,
        endTime,
        uint32(block.timestamp),
        lastTouchedTime,
        totalLiquidity
      );

      tempSumRewardPerLiquidity += deltaSumRewardPerLiquidity;
    }
  }

  function getEligibleRanges(
    uint256 fId,
    uint256 nftId
  ) external view returns (uint256[] memory indexesValid) {
    ILMHelperV2 helper = ILMHelperV2(address(farmSC));
    address nftAddr = address(farmSC.getNft());
    (address poolAddr, IELM3.RangeInfo[] memory rangesInfo, , , ) = farmSC.getFarm(fId);
    if (!helper.checkPool(poolAddr, nftAddr, nftId)) revert PositionNotEligible();

    (int24 tickLower, int24 tickUpper, ) = _getPositionInfo(nftAddr, nftId);

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

  function getUserInfo(address user) external view returns (UserInfo[] memory result) {
    uint256[] memory listNFTs = farmSC.getDepositedNFTs(user);
    result = new UserInfo[](listNFTs.length);
    for (uint256 i = 0; i < listNFTs.length; ++i) {
      (, uint256 fId, uint256 rId, uint128 sLiq) = farmSC.getStake(listNFTs[i]);
      result[i].nftId = listNFTs[i];
      result[i].fId = fId;
      result[i].rangeId = rId;
      result[i].liquidity = sLiq;
      result[i].currentUnclaimedRewards = getUnclaimedReward(listNFTs[i]);
    }
  }

  function _getPositionInfo(
    address nftContract,
    uint256 nftId
  ) private view returns (int24, int24, uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return (pData.tickLower, pData.tickUpper, pData.liquidity);
  }

  function _getPositionFromNFT(
    address nftContract,
    uint256 nftId
  ) private view returns (IBasePositionManager.Position memory) {
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