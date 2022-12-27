// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line strict-import
pragma solidity ^0.7.6;

//import "hardhat/console.sol"; // TODO: remove in prod

import "./Constants.sol";
import { requireErrCode, CronErrors } from "./Errors.sol";
import { OrderPools } from "./VirtualOrderStructs.sol";

/// @notice Library for packing and upacking containers into full slots for
///         sload/sstore optimization.
///
/// @dev It's certainly possible to write a generic shifting method that accepts an offset and
///      a bit-mask or number of bits to mask. That is not used here b/c desipite it reducing
///      contract size, it increases gas used sufficiently to warrant the approach below.
///
library BitPackingLib {
  //
  // Generic Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice TODO
  /// @param _slot TODO
  /// @param _bit  TODO
  /// @param _offset The offset from the first bit in the slot (the least-significant bit) to
  ///                modify with the data in _bit. For example, to manipulate bit 7 in the slot,
  ///                pass in an offset of 6. Note that bits are numbered starting at 1 herein.
  ///                Ensure that _offset is between 0 and 255, there is no safety check built-in
  ///                to improve gas efficiency.
  function packBit(
    uint256 _slot,
    uint256 _bit,
    uint256 _offset
  ) internal pure returns (uint256 slot) {
    requireErrCode(_bit <= MAX_U1, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 mask = MAX_U1 << _offset;
    slot = (_bit != 0) ? (_slot | mask) : (_slot & (~mask));
  }

  /// @notice TODO
  function unpackBit(uint256 _slot, uint256 _offset) internal pure returns (uint256 bit) {
    bit = ((_slot >> _offset) & MAX_U1);
  }

  /// @notice TODO
  function packU10(
    uint256 _slot,
    uint256 _valueU10,
    uint256 _offset
  ) internal pure returns (uint256 slot) {
    requireErrCode(_valueU10 <= MAX_U10, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 clearMask = ~(MAX_U10 << _offset);
    uint256 setMask = (_valueU10 & MAX_U10) << _offset;
    slot = (_slot & clearMask) | setMask;
  }

  /// @notice TODO
  function unpackU10(uint256 _slot, uint256 _offset) internal pure returns (uint256 valueU10) {
    valueU10 = (_slot >> _offset) & MAX_U10;
  }

  /// @notice TODO
  /// TODO: more efficient check for overflow?
  function incrementPairWithClampU96(
    uint256 _slot,
    uint256 _increment0,
    uint256 _increment1
  ) internal pure returns (uint256 slot) {
    uint256 value0U96 = ((_slot >> 96) & MAX_U96);
    uint256 value1U96 = (_slot & MAX_U96);

    if (_increment0 > 0) {
      requireErrCode(_increment0 <= MAX_U96, CronErrors.INCREMENT_TOO_LARGE);
      value0U96 += _increment0;
      if (value0U96 > MAX_U96) {
        value0U96 = MAX_U96;
      }
    }

    if (_increment1 > 0) {
      requireErrCode(_increment1 <= MAX_U96, CronErrors.INCREMENT_TOO_LARGE);
      value1U96 += _increment1;
      if (value1U96 > MAX_U96) {
        value1U96 = MAX_U96;
      }
    }

    // NOTE: No need create set masks as _value*U96 above checked against MAX_U96/clamped.
    uint256 clearMask = ~((MAX_U96 << 96) | MAX_U96);
    slot = (_slot & clearMask) | (value0U96 << 96) | value1U96;
  }

  function unpackAndClearPairU96(uint256 _slot)
    internal
    pure
    returns (
      uint256 slot,
      uint256 value0U96,
      uint256 value1U96
    )
  {
    value0U96 = (_slot >> 96) & MAX_U96;
    value1U96 = _slot & MAX_U96;

    uint256 clearMask = ~((MAX_U96 << 96) | MAX_U96);
    slot = _slot & clearMask;
  }

  /// @notice TODO
  function unpackPairU96(uint256 _slot) internal pure returns (uint256 value0U96, uint256 value1U96) {
    value0U96 = (_slot >> 96) & MAX_U96;
    value1U96 = _slot & MAX_U96;
  }

  /// @notice TODO
  function packPairU112(
    uint256 _slot,
    uint256 _value0U112,
    uint256 _value1U112
  ) internal pure returns (uint256 slot) {
    requireErrCode(_value0U112 <= MAX_U112, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);
    requireErrCode(_value1U112 <= MAX_U112, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 clearMask = ~((MAX_U112 << 112) | MAX_U112);
    uint256 setMask0 = (_value0U112 & MAX_U112) << 112;
    uint256 setMask1 = _value1U112 & MAX_U112;
    slot = (_slot & clearMask) | setMask0 | setMask1;
  }

  /// @notice TODO
  function unpackPairU112(uint256 _slot) internal pure returns (uint256 value0U112, uint256 value1U112) {
    value0U112 = (_slot >> 112) & MAX_U112;
    value1U112 = _slot & MAX_U112;
  }

  /// @notice TODO
  /// TODO: more efficient check for overflow?
  function incrementPairU112(
    uint256 _slot,
    uint256 _increment0,
    uint256 _increment1
  ) internal pure returns (uint256 slot) {
    uint256 value0U112 = ((_slot >> 112) & MAX_U112);
    uint256 value1U112 = (_slot & MAX_U112);

    if (_increment0 > 0) {
      requireErrCode(_increment0 <= MAX_U112, CronErrors.INCREMENT_TOO_LARGE);
      value0U112 += _increment0;
      requireErrCode(value0U112 <= MAX_U112, CronErrors.OVERFLOW);
    }
    if (_increment1 > 0) {
      requireErrCode(_increment1 <= MAX_U112, CronErrors.INCREMENT_TOO_LARGE);
      value1U112 += _increment1;
      requireErrCode(value1U112 <= MAX_U112, CronErrors.OVERFLOW);
    }

    // NOTE: No need create set masks as _value*U112 above checked against MAX_U112.
    uint256 clearMask = ~((MAX_U112 << 112) | MAX_U112);
    slot = (_slot & clearMask) | (value0U112 << 112) | value1U112;
  }

  function decrementPairU112(
    uint256 _slot,
    uint256 _decrement0,
    uint256 _decrement1
  ) internal pure returns (uint256 slot) {
    uint256 value0U112 = ((_slot >> 112) & MAX_U112);
    uint256 value1U112 = (_slot & MAX_U112);

    if (_decrement0 > 0) {
      requireErrCode(value0U112 >= _decrement0, CronErrors.UNDERFLOW);
      value0U112 -= _decrement0;
    }
    if (_decrement1 > 0) {
      requireErrCode(value1U112 >= _decrement1, CronErrors.UNDERFLOW);
      value1U112 -= _decrement1;
    }

    // NOTE: No need create set masks as _value*U112 above both less than MAX_U112 (correct by
    //       construction--checked at creation/pack) and operation is subtraction with underflow
    //       checked;
    uint256 clearMask = ~((MAX_U112 << 112) | MAX_U112);
    slot = (_slot & clearMask) | (value0U112 << 112) | value1U112;
  }

  /// @notice TODO
  /// @dev boolean _token0 true instructs this to unpack the upper 128-bits, otherwise the lower 128-bits.
  function unpackU128(uint256 _slot, bool _token0) internal pure returns (uint256 valueU128) {
    valueU128 = ((_token0) ? (_slot >> 128) : _slot) & MAX_U128;
  }

  /// @notice TODO
  function packPairU128(uint256 _value0U128, uint256 _value1U128) internal pure returns (uint256 slot) {
    requireErrCode(_value0U128 <= MAX_U128, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);
    requireErrCode(_value1U128 <= MAX_U128, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    slot = ((_value0U128 & MAX_U128) << 128) | (_value1U128 & MAX_U128);
  }

  /// @notice TODO
  function unpackPairU128(uint256 _slot) internal pure returns (uint256 value0U128, uint256 value1U128) {
    value0U128 = (_slot >> 128) & MAX_U128;
    value1U128 = _slot & MAX_U128;
  }

  //
  // Slot 2 Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice TODO
  function packOracleTimeStampS2(uint256 _slot, uint256 _oracleTimeStamp) internal pure returns (uint256 slot) {
    requireErrCode(_oracleTimeStamp <= MAX_U32, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 clearMask = ~(MAX_U32 << S2_OFFSET_ORACLE_TIMESTAMP);
    uint256 setMask = (_oracleTimeStamp & MAX_U32) << S2_OFFSET_ORACLE_TIMESTAMP;
    slot = (_slot & clearMask) | setMask;
  }

  /// @notice TODO
  function unpackOracleTimeStampS2(uint256 _slot) internal pure returns (uint256 oracleTimeStamp) {
    oracleTimeStamp = (_slot >> S2_OFFSET_ORACLE_TIMESTAMP) & MAX_U32;
  }

  //
  // Slot 3 Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice TODO
  /// @dev feeShiftU3 is bits 247-245 (first bit is counted as bit 1).
  function packFeeShiftS3(uint256 _slot, uint256 _feeShiftU3) internal pure returns (uint256 slot) {
    requireErrCode(_feeShiftU3 <= MAX_U3, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 clearMask = ~(MAX_U3 << S3_OFFSET_FEE_SHIFT_U3);
    uint256 setMask = (_feeShiftU3 & MAX_U3) << S3_OFFSET_FEE_SHIFT_U3;
    slot = (_slot & clearMask) | setMask;
  }

  /// @notice TODO
  /// @dev feeShiftU3 is bits 247-245 (first bit is counted as bit 1).
  function unpackFeeShiftS3(uint256 _slot) internal pure returns (uint256 feeShiftU3) {
    feeShiftU3 = (_slot >> S3_OFFSET_FEE_SHIFT_U3) & MAX_U3;
  }

  /// @notice TODO
  /// @dev holdingPeriodSec bits 244-225 (first bit is counted as bit 1).
  function packHoldingPeriodSecS3(uint256 _slot, uint256 _holdingPeriodSec) internal pure returns (uint256 slot) {
    requireErrCode(_holdingPeriodSec <= MAX_U20, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 clearMask = ~(MAX_U20 << S3_OFFSET_HOLDING_PERIOD_SEC);
    uint256 setMask = (_holdingPeriodSec & MAX_U20) << S3_OFFSET_HOLDING_PERIOD_SEC;
    slot = (_slot & clearMask) | setMask;
  }

  /// @notice TODO
  /// @dev holdingPeriodSec bits 244-225 (first bit is counted as bit 1).
  function unpackHoldingPeriodSecS3(uint256 _slot) internal pure returns (uint256 holdingPeriodSec) {
    holdingPeriodSec = (_slot >> S3_OFFSET_HOLDING_PERIOD_SEC) & MAX_U20;
  }

  //
  // Slot 4 Packing Functions
  ////////////////////////////////////////////////////////////////////////////////

  /// @notice TODO
  function packBalancerFeeS4(uint256 _slot, uint256 _balancerFeeDU1F18) internal pure returns (uint256 slot) {
    requireErrCode(_balancerFeeDU1F18 <= MAX_U60, CronErrors.VALUE_EXCEEDS_CONTAINER_SZ);

    uint256 clearMask = ~(MAX_U60 << S4_OFFSET_BALANCER_FEE);
    uint256 setMask = (_balancerFeeDU1F18 & MAX_U60) << S4_OFFSET_BALANCER_FEE;
    slot = (_slot & clearMask) | setMask;
  }

  /// @notice TODO
  function unpackBalancerFeeS4(uint256 _slot) internal pure returns (uint256 balancerFeeDU1F18) {
    balancerFeeDU1F18 = (_slot >> S4_OFFSET_BALANCER_FEE) & MAX_U60;
  }
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

//
// General Constants
////////////////////////////////////////////////////////////////////////////////
address constant NULL_ADDR = address(0);

uint256 constant FALSE = 0;

uint256 constant MAX_U128 = type(uint128).max;
uint256 constant MAX_U112 = type(uint112).max;
uint256 constant MAX_U96 = type(uint96).max;
uint256 constant MAX_U64 = type(uint64).max;
uint256 constant MAX_U60 = 2**60 - 1;
uint256 constant MAX_U32 = type(uint32).max;
uint256 constant MAX_U24 = type(uint24).max;
uint256 constant MAX_U20 = 0xFFFFF;
uint256 constant MAX_U16 = type(uint16).max;
uint256 constant MAX_U10 = 0x3FF;
uint256 constant MAX_U8 = type(uint8).max;
uint256 constant MAX_U3 = 0x7;
uint256 constant MAX_U1 = 0x1;
uint256 constant MAX_BOOL = 0x1;

uint256 constant ONE_DU1_18 = 10**18;
uint256 constant DENOMINATOR_DU1_18 = 10**18;

//
// Bit-Packing Constants
//
// Dev: Bit-offsets below are the offset from the first bit. For example to get
//      to bit 250, the offset 249 is used. (The first bit is counted as bit 1).
////////////////////////////////////////////////////////////////////////////////

// Pool Offsets:
uint256 constant P_OFFSET_TOKEN0_SALES_RATE = 112;
uint256 constant P_OFFSET_TOKEN1_SALES_RATE = 0;

// Slot 1 Offsets:
uint256 constant S1_OFFSET_SHORT_TERM_FEE_BP = 244; // Bits 254-245;
uint256 constant S1_OFFSET_PARTNER_FEE_BP = 234; // Bits 244-235;
uint256 constant S1_OFFSET_LONG_TERM_FEE_BP = 224; // Bits 234-225;
uint256 constant S1_OFFSET_TOKEN0_ORDERS = 112; // Bits 224-113;
uint256 constant S1_OFFSET_TOKEN1_ORDERS = 0; // Bits 112-1;

// Slot 2 Offsets:
uint256 constant S2_OFFSET_ORACLE_TIMESTAMP = 224; // Bits 256-225;
uint256 constant S2_OFFSET_TOKEN0_PROCEEDS = 112; // Bits 224-113;
uint256 constant S2_OFFSET_TOKEN1_PROCEEDS = 0; // Bits 112-1;

// Slot 3 Offsets:
uint256 constant S3_OFFSET_FEE_SHIFT_U3 = 222; // Bits 225-223
uint256 constant S3_OFFSET_HOLDING_PENALTY_BP = 212; // Bits 222-213;
uint256 constant S3_OFFSET_HOLDING_PERIOD_SEC = 192; // Bits 212-193;
uint256 constant S3_OFFSET_TOKEN0_CRONFI_FEES = 96; // Bits 192-97;
uint256 constant S3_OFFSET_TOKEN1_CRONFI_FEES = 0; // Bits 96-1;

// Slot 4 Offsets:
uint256 constant S4_OFFSET_PAUSE = 255; // Bit 256
uint256 constant S4_OFFSET_FEE_ENABLED = 254; // Bit 255
uint256 constant S4_OFFSET_COLLECT_BALANCER_FEES = 253; // Bit 254
uint256 constant S4_OFFSET_ZERO_CRONFI_FEES = 252; // Bit 253
uint256 constant S4_OFFSET_BALANCER_FEE = 192; // Bits 252-193;
uint256 constant S4_OFFSET_TOKEN0_BALANCER_FEES = 96; // Bits 192-97;
uint256 constant S4_OFFSET_TOKEN1_BALANCER_FEES = 0; // Bits 96-1;

//
// Scaling Constants
////////////////////////////////////////////////////////////////////////////////
// Tuning notes: 128 too high, results in data loss for safety suite.
//               112 fails if orderpool values compressed into 112-bits instead of 128
//               96 passes.
//               80 passes.
//               64 passes.
//               56 fails tolerance.
//               Desmos analysis has more details.
// TODO: Need to understand and set this appropriately to prevent scaledProceeds pool breakdown.
//       Analysis should start at maximum expected scaled proceeds and work backward to figure
//       out scaling and if U128 should be used for additional headroom.
// TODO: Link to analytical analysis showcasing operational limits.
//
uint256 constant B112 = 112; // Bits in fixed point denominator.
uint256 constant B96 = 96; // Bits in fixed point denominator.
uint256 constant B64 = 64; // Bits in fixed point denominator.
uint256 constant B56 = 56;
uint256 constant BXXX = B64; // Bits for scaling shifts of shared scaled proceeds.

//
// Pool Specific Constants
////////////////////////////////////////////////////////////////////////////////
uint256 constant MINIMUM_LIQUIDITY = 10**3;

uint16 constant STABLE_OBI = 64; // ~ [email protected] 14s/block
uint16 constant LIQUID_OBI = 257; // ~ [email protected] 14s/block
uint16 constant VOLATILE_OBI = 1028; // ~ [email protected] 14s/block

//
// Holding Period Constants
////////////////////////////////////////////////////////////////////////////////
uint16 constant DEFAULT_HOLDING_PENALTY_BP = 100; // 0.1%
uint16 constant MAX_HOLDING_PENALTY_BP = 1000; // 1 %

uint24 constant DEFAULT_HOLDING_PERIOD = 7 * 24 * 60 * 60; // 1 week in seconds
uint24 constant MAX_HOLDING_PERIOD = 7 * 24 * 60 * 60; // 1 week in seconds

//
// Fees Constants
////////////////////////////////////////////////////////////////////////////////
// Note: Mult-by these constants requires Max. 14-bits (~13.3 bits) headroom to prevent overflow.
//       BP = Total Basis Points  (Non-standard definition here, 100k vs. 1k).
//       ST = Short-Term Swap
//       LT = Long-Term Swap
//       LP = Liquidity Provider
//       CF = Cron Fi
//
uint256 constant BP = 100000;
uint256 constant MAX_FEE_BP = 1000; // 1.000%

// Short Term Swap Payouts:
// ----------------------------------------
uint16 constant STABLE_ST_FEE_BP = 10; // 0.010%
uint16 constant LIQUID_ST_FEE_BP = 50; // 0.050%
uint16 constant VOLATILE_ST_FEE_BP = 100; // 0.100%

// Partner Swap Payouts:
// ----------------------------------------
uint16 constant STABLE_ST_PARTNER_FEE_BP = 5; // 0.005%
uint16 constant LIQUID_ST_PARTNER_FEE_BP = 25; // 0.025%
uint16 constant VOLATILE_ST_PARTNER_FEE_BP = 50; // 0.050%

// Long Term Swap Payouts
// ----------------------------------------
uint16 constant STABLE_LT_FEE_BP = 30; // 0.030%
uint16 constant LIQUID_LT_FEE_BP = 150; // 0.150%
uint16 constant VOLATILE_LT_FEE_BP = 300; // 0.300%

uint8 constant DEFAULT_FEE_SHIFT = 1; // 66% LP to 33% CronFi

// SPDX-License-Identifier: BUSL-1.1

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//

// solhint-disable-next-line strict-import
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol"; // TODO: remove in prod
// import "forge-std/console.sol"; // TODO: remove in prod

import { Math } from "./balancer-core-v2/lib/math/Math.sol";

import { IERC20 } from "./balancer-core-v2/lib/openzeppelin/IERC20.sol";
import { ReentrancyGuard } from "./balancer-core-v2/lib/openzeppelin/ReentrancyGuard.sol";

import { IMinimalSwapInfoPool } from "./balancer-core-v2/vault/interfaces/IMinimalSwapInfoPool.sol";
import { IBasePool } from "./balancer-core-v2/vault/interfaces/IBasePool.sol";
import { IVault } from "./balancer-core-v2/vault/interfaces/IVault.sol";
import { BalancerPoolToken } from "./balancer-core-v2/pools/BalancerPoolToken.sol";

import { Rook } from "./partners/Rook.sol";
import { IArbitrageurList } from "./interfaces/IArbitrageurList.sol";
import { ICronV1PoolFactory } from "./interfaces/ICronV1PoolFactory.sol";

import "./Constants.sol";
import { requireErrCode, revertErrCode, CronErrors } from "./Errors.sol";
import { ExecVirtualOrdersMem, MiscLib, PriceOracle } from "./Misc.sol";
import { BitPackingLib } from "./BitPacking.sol";
import { VirtualOrders, OrderPools, Order, MintEvent } from "./VirtualOrderStructs.sol";
import { VirtualOrderLib } from "./VirtualOrders.sol";

uint256 constant MAX_RESULTS = 100;
uint256 constant MAX_ITERATIONS = 100;

/// @title  An implementation of a Time-Weighted Average Market Maker on Balancer V2 Vault Pools.
/// @author Zero Slippage (0slippage), Based upon the Paradigm paper TWAMM and the reference design
///         created by frankieislost with optimizations from FRAX incorporated for gas efficiency.
/// @notice For usage details, see the documentation at <TODO URL>
contract CronV1Pool is IMinimalSwapInfoPool, BalancerPoolToken, ReentrancyGuard {
  using Math for uint256;
  using VirtualOrderLib for VirtualOrders;

  enum PoolType {
    Stable, // 0
    Liquid, // 1
    Volatile // 2
  }

  enum JoinType {
    Join, // 0
    Reward // 1
  }

  enum SwapType {
    RegularSwap, // 0
    LongTermSwap, // 1
    PartnerSwap, // 2
    KDAOSwap // 3
  }

  enum ExitType {
    Exit, // 0
    Withdraw, // 1
    Cancel, // 2
    FeeWithdraw // 3
  }

  enum ParamType {
    // Slot 1:
    SwapFeeBP, // 0
    PartnerFeeBP, // 1
    LongSwapFeeBP, // 2
    // Slot 3:
    HoldingPenaltyBP, // 3
    HoldingPeriodSec // 4
  }

  IVault private immutable VAULT;
  bytes32 public immutable POOL_ID;
  IERC20 private immutable TOKEN0;
  IERC20 private immutable TOKEN1;
  PoolType private immutable POOL_TYPE;
  uint16 private immutable ORDER_BLOCK_INTERVAL;
  uint8 private immutable TOKEN0_IDX;
  uint8 private immutable TOKEN1_IDX;
  address private immutable FACTORY;

  VirtualOrders private virtualOrders;

  /* Slot 1:
   *
   * The following variables are bit-mapped into uint256 slot1 (in non-standard
   * container sizes related to their actual ranges where needed):
   *
   * uint16 public shortTermFeeBP;
   * uint16 public partnerFeeBP;
   * uint16 public longTermFeeBP;
   * uint112 public token0Orders;
   * uint112 public token1Orders;
   *
   * slot 1 layout:
   *
   *   256-255  free (2-bits)
   *   -------
   *   254-245  shortTermFeeBP (10-bits)
   *   -------
   *   244-235  partnerFeeBP (10-bits)
   *   -------
   *   234-225  longTermFeeBP (10-bits)
   *   -------
   *   224-113  token0Orders (112-bits)
   *   -------
   *   112-  1  token1Orders (112-bits)
   *
   */
  uint256 private slot1;

  /* Slot 2:
   *
   * The following variables are bit-mapped into uint256 slot2 (in non-standard
   * container sizes related to their actual ranges where needed):
   *
   * uint32 public oracleTimeStamp; // Last time stamp
   * uint112 public token0Proceeds;
   * uint112 public token1Proceeds;
   *
   * slot 2 layout:
   *
   *   256-225  oracleTimeStamp (32-bits)
   *   -------
   *   224-113  token0Proceeds (112-bits)
   *   -------
   *   112-  1  token1Proceeds (112-bits)
   *
   */
  uint256 private slot2;

  /* Slot 3:
   *
   * The following variables are bit-mapped into uint256 slot3 (in non-standard
   * container sizes related to their actual ranges where needed):
   *
   * uint8 public feeShiftU3;
   * uint16 public holdingPenaltyBP;
   * uint24 public holdingPeriodSec;
   * uint96 public token0CronFiFees;
   * uint96 public token1CronFiFees;
   *
   * slot 3 layout:
   *
   *   256-226  free (31-bits)
   *   -------
   *   225-223  feeShiftU3 (3-bits)
   *   -------
   *   222-213  holdingPenaltyBP (10-bits)
   *   -------
   *   212-193  holdingPeriodSec (20-bits)
   *   -------
   *   192- 97  token0CronFiFees (96-bits)
   *   -------
   *    96-  1  token1CronFiFees (96-bits)
   *
   */
  uint256 private slot3;

  /* Slot 4 Begin
   *
   * The following variables are bit-mapped into uint256 slot4 (in non-standard
   * container sizes related to their actual ranges where needed):
   *
   * bool public paused;
   * bool public feeEnabled;
   * bool public collectBalancerFees;
   * bool public zeroCronFiFees;
   * uint64 public balancerFeeDU1F18; // Max 1e18.
   * uint112 public token0BalancerFees;
   * uint112 public token1BalancerFees;
   *
   * slot 4 layout:
   *
   *       256  paused (1-bit)
   *   -------
   *       255  feeEnabled (1-bit)
   *   -------
   *       254  collectBalancerFees (1-bit)
   *   -------
   *       253  zeroCronFiFees (1-bit)
   *   -------
   *   252-193  balancerFeeDU1F18 (60-bits)
   *   -------
   *   192- 97  token0BalancerFees (96-bits)
   *   -------
   *    96-  1  token1BalancerFees (96-bits)
   *
   */
  uint256 private slot4;

  PriceOracle public priceOracle; // Uniswap V2 Style Oracle

  mapping(address => bool) internal adminAddrMap;
  mapping(address => address) internal partnerContractAddrMap;

  address internal rookPartnerContractAddr;
  address internal feeAddr;

  mapping(address => MintEvent[]) private mintEventMap;
  mapping(address => uint256[]) private orderIdMap;

  // onSwap Events
  event ShortTermSwap(
    address indexed sender,
    address indexed tokenIn,
    uint256 amountIn,
    uint256 amountOut,
    uint256 swapType
  );
  event LongTermSwap(
    address indexed sender,
    address indexed tokenIn,
    uint256 amountIn,
    uint256 intervals,
    uint256 orderId
  );

  // onJoin Events
  //
  // Overloads:
  //  - A PoolJoin event where poolTokenAmt is zero is a Reward event (reduce contract size by sharing
  //    events).
  //
  event PoolJoin(address indexed sender, uint256 token0In, uint256 token1In, uint256 poolTokenAmt);

  // onExit Events
  event WithdrawLongTermSwap(
    address indexed sender,
    address indexed refundToken,
    uint256 refundOut,
    address indexed proceedsToken,
    uint256 proceedsOut,
    uint256 orderId
  );
  event FeeWithdraw(address indexed sender, uint256 token0Out, uint256 token1Out);
  event PoolExit(
    address indexed sender,
    uint256 poolTokenAmt,
    uint256 token0Out,
    uint256 penalty0,
    uint256 token1Out,
    uint256 penalty1
  );

  event AdministratorStatusChange(address indexed sender, address indexed admin, bool status);
  event ArbPartnerStatusChange(address indexed sender, address indexed arbPartner, bool status);

  event ProtocolFeeTooLarge(uint256 suggestedProtocolFee);
  event ParameterChange(address indexed sender, ParamType paramType, uint256 value);

  event FeeAddressChange(address indexed sender, address indexed feeAddress);

  event UpdatedArbitragePartner(address indexed sender, address partner, address list, bool isRook);
  event UpdatedArbitrageList(address indexed partner, address indexed oldList, address indexed newList);
  event TransferMintEvent(address indexed source, address indexed destination, uint256 amount, uint256 timestamp);

  /// @notice TODO
  /// @dev    Cannot be used on Balancer Vault callbacks (onJoin, onExit,
  ///         onSwap) because msg.sender is the Vault address.
  modifier senderIsFactoryOwner() {
    _senderIsFactoryOwner(); // #contractsize
    _;
  }

  /// @notice Requires attached function is called by an address that is an
  ///         administrator.
  /// @dev    Cannot be used on Balancer Vault callbacks (onJoin, onExit,
  ///         onSwap) because msg.sender is the Vault address.
  modifier senderIsAdmin() {
    _senderIsAdmin(); // #contractsize
    _;
  }

  /// @notice Requires attached function is called by an address that is
  ///         an administrator or arbitrage partner.
  /// @dev    Cannot be used on Balancer Vault callbacks (onJoin, onExit,
  ///         onSwap) because msg.sender is the Vault address.
  modifier senderIsArbitragePartner() {
    _senderIsArbitragePartner(); // #contractsize
    _;
  }

  /// @notice Allows attached function execution if pool is not paused.
  ///         Blocks execution of virtual orders in the event of a severe problem
  ///         (i.e. detected overflow etc). When paused the pool allows exits,
  ///         withdraws, and cancel withdraws and refunds. Virtual orders will
  ///         not be updated from the last virtual order block (LVOB) for the
  ///         aforementioned allowed transactions.
  modifier poolNotPaused() {
    _poolNotPaused(); // #contractsize
    _;
  }

  /// @notice Creates an instance of a Balancer Vault TWAMM pool, complete with virtual order management
  ///         and virtualized reserves. LP tokens in the form of an instance of BalancerPoolToken with
  ///         name and symbol according to _poolName and _poolSymbol, respectively.
  /// @param _token0Inst The contract instance for token 0.
  /// @param _token1Inst The contract instance for token 1.
  /// @param _vaultInst  The vault instance this pool will sit atop.
  /// @param _poolName   The name for this pool.
  /// @param _poolSymbol The symbol for this pool.
  /// @param _poolTypeU  An enumeration value for the pool type. Possible values are stable, liquid and volatile.
  ///                   Each value affects both the fees charged by the pool and the order block interval.
  /// @param _adminAddr  A default address that can administer the pool (pause, add/remove admins, add/remove
  ///                   partners).
  /// TODO:
  ///   - #savegas Consider initializing values in the constructor to reduce gas fees for initial users (i.e.
  ///              saving on the 0->X 20k storage slot init gas.)
  constructor(
    IERC20 _token0Inst,
    IERC20 _token1Inst,
    IVault _vaultInst,
    string memory _poolName,
    string memory _poolSymbol,
    uint256 _poolTypeU,
    address _factory,
    address _adminAddr
  ) BalancerPoolToken(_poolName, _poolSymbol) {
    // check to ensure only factory can create pools
    requireErrCode(msg.sender == _factory, CronErrors.SENDER_NOT_FACTORY);

    FACTORY = _factory;

    bytes32 poolIdValue = _vaultInst.registerPool(IVault.PoolSpecialization.TWO_TOKEN);

    bool token0First = _token0Inst < _token1Inst;
    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = (token0First) ? _token0Inst : _token1Inst;
    tokens[1] = (token0First) ? _token1Inst : _token0Inst;
    _vaultInst.registerTokens(
      poolIdValue,
      tokens,
      new address[](2) /* assetManagers */
    );

    VAULT = _vaultInst;
    POOL_ID = poolIdValue;
    TOKEN0 = _token0Inst;
    TOKEN1 = _token1Inst;
    TOKEN0_IDX = token0First ? 0 : 1;
    TOKEN1_IDX = token0First ? 1 : 0;

    PoolType lPoolType = PoolType(_poolTypeU);
    POOL_TYPE = lPoolType;

    requireErrCode(PoolType.Stable <= lPoolType && lPoolType <= PoolType.Volatile, CronErrors.INVALID_POOL_TYPE);

    // Note: Conditional assignment style for immutables.
    ORDER_BLOCK_INTERVAL = (lPoolType == PoolType.Stable) ? STABLE_OBI : (lPoolType == PoolType.Liquid)
      ? LIQUID_OBI
      : VOLATILE_OBI;

    if (lPoolType == PoolType.Stable) {
      uint256 localSlot1 = BitPackingLib.packU10(0, STABLE_ST_FEE_BP, S1_OFFSET_SHORT_TERM_FEE_BP);
      localSlot1 = BitPackingLib.packU10(localSlot1, STABLE_ST_PARTNER_FEE_BP, S1_OFFSET_PARTNER_FEE_BP);
      slot1 = BitPackingLib.packU10(localSlot1, STABLE_LT_FEE_BP, S1_OFFSET_LONG_TERM_FEE_BP);
    } else if (lPoolType == PoolType.Liquid) {
      uint256 localSlot1 = BitPackingLib.packU10(0, LIQUID_ST_FEE_BP, S1_OFFSET_SHORT_TERM_FEE_BP);
      localSlot1 = BitPackingLib.packU10(localSlot1, LIQUID_ST_PARTNER_FEE_BP, S1_OFFSET_PARTNER_FEE_BP);
      slot1 = BitPackingLib.packU10(localSlot1, LIQUID_LT_FEE_BP, S1_OFFSET_LONG_TERM_FEE_BP);
    } else {
      // PoolType.Volatile
      uint256 localSlot1 = BitPackingLib.packU10(0, VOLATILE_ST_FEE_BP, S1_OFFSET_SHORT_TERM_FEE_BP);
      localSlot1 = BitPackingLib.packU10(localSlot1, VOLATILE_ST_PARTNER_FEE_BP, S1_OFFSET_PARTNER_FEE_BP);
      slot1 = BitPackingLib.packU10(localSlot1, VOLATILE_LT_FEE_BP, S1_OFFSET_LONG_TERM_FEE_BP);
    }

    uint256 localSlot3 = slot3;
    localSlot3 = BitPackingLib.packFeeShiftS3(localSlot3, DEFAULT_FEE_SHIFT);
    localSlot3 = BitPackingLib.packU10(localSlot3, DEFAULT_HOLDING_PENALTY_BP, S3_OFFSET_HOLDING_PENALTY_BP);
    slot3 = BitPackingLib.packHoldingPeriodSecS3(localSlot3, DEFAULT_HOLDING_PERIOD);

    uint256 localSlot4 = BitPackingLib.packBit(0, 0, S4_OFFSET_PAUSE);
    localSlot4 = BitPackingLib.packBit(localSlot4, 0, S4_OFFSET_FEE_ENABLED);
    slot4 = BitPackingLib.packBit(localSlot4, 1, S4_OFFSET_COLLECT_BALANCER_FEES);

    adminAddrMap[_adminAddr] = true;
    emit AdministratorStatusChange(msg.sender, _adminAddr, true);

    feeAddr = NULL_ADDR;
    emit FeeAddressChange(msg.sender, NULL_ADDR);

    virtualOrders.lastVirtualOrderBlock = block.number;
  }

  /// @notice Callback for IVault.sol swap method that facilitates handling of Balancer TWAMM swap operations. Swap
  ///         operations include the traditional Constant Product Automated Market Maker (CPAMM) swap, modified to
  ///         operate with lazy loading virtual orders. Supported virtual orders include Long-Term-swaps (LT) and
  ///         operations for managing issued virtual orders including cancelling virtual orders and withdrawing
  ///         proceeds from them.
  /// @param _swapRequest      All fields except userData documented in IPoolSwapStructs.sol. userData for this
  ///                         contract are comprised of two uint256 containers, swapType and argument:
  ///                         * swapType is decoded into the Enum SwapType.
  ///                         * argument is used as follows:
  ///                              - swapType == RegularSwap || KDAOSwap, argument ignored.
  ///                              - swapType == PartnerSwap, argument is the partner address stored in
  ///                                                         a uint256, and used to look up the partner's
  ///                                                         current arbitrage list address.
  ///                              - swapType == LongTermSwap, argument is order intervals.
  /// @param _currentBalanceTokenInU112 TODO
  /// @param _currentBalanceTokenOutU112 TODO
  /// @return amountOutU112  A uint256 container representing a uint112 value pertaining to the swap operation
  ///                        specified in _swapRequest.userData, as described above.
  /// TODO:
  ///   - #safety Need to check for overflow for all input amounts (total in pool must be < MAX_U112)
  function onSwap(
    SwapRequest memory _swapRequest,
    uint256 _currentBalanceTokenInU112,
    uint256 _currentBalanceTokenOutU112
  ) external override(IMinimalSwapInfoPool) nonReentrant poolNotPaused returns (uint256 amountOutU112) {
    requireErrCode(msg.sender == address(VAULT), CronErrors.NON_VAULT_CALLER);

    // #savegas #savesize
    IERC20 tokenIn = _swapRequest.tokenIn;
    address from = _swapRequest.from;
    uint256 amount = _swapRequest.amount;

    requireErrCode(tokenIn == TOKEN0 || tokenIn == TOKEN1, CronErrors.INVALID_TOKEN_SPECIFIED);
    requireErrCode(_swapRequest.kind == IVault.SwapKind.GIVEN_IN, CronErrors.UNSUPPORTED_SWAP_KIND);

    (uint256 swapTypeU, uint256 argument) = abi.decode(_swapRequest.userData, (uint256, uint256));
    SwapType swapType = SwapType(swapTypeU);

    bool token0To1 = (tokenIn == TOKEN0);
    (uint256 token0Reserve, uint256 token1Reserve) = _executeVirtualOrders(
      token0To1 ? _currentBalanceTokenInU112 : _currentBalanceTokenOutU112,
      token0To1 ? _currentBalanceTokenOutU112 : _currentBalanceTokenInU112,
      block.number
    );

    if (swapType == SwapType.LongTermSwap) {
      uint256 orderId = _longTermSwap(from, token0To1, amount, argument);
      emit LongTermSwap(from, address(tokenIn), amount, argument, orderId);
    } else {
      uint256 feeOffset = S1_OFFSET_PARTNER_FEE_BP;
      if (swapType == SwapType.RegularSwap) {
        feeOffset = S1_OFFSET_SHORT_TERM_FEE_BP;
      } else if (swapType == SwapType.PartnerSwap) {
        address contractAddress = partnerContractAddrMap[address(argument)];
        requireErrCode(IArbitrageurList(contractAddress).isArbitrageur(from), CronErrors.SENDER_NOT_PARTNER);
      } else if (swapType == SwapType.KDAOSwap) {
        requireErrCode(
          Rook(rookPartnerContractAddr).getKeeperWhitelistPosition_pab(from) != 0,
          CronErrors.SENDER_NOT_KEEPER
        );
      } else {
        revertErrCode(CronErrors.INVALID_SWAP_TYPE);
      }

      amountOutU112 = _shortTermSwap(
        token0To1,
        BitPackingLib.unpackU10(slot1, feeOffset),
        amount,
        token0Reserve,
        token1Reserve
      );
      emit ShortTermSwap(from, address(tokenIn), amount, amountOutU112, swapTypeU);
    }
  }

  /// @notice Called by the Vault when a user calls IVault.joinPool to add liquidity to this Pool.
  /// @param _poolId              The ID for this pool in the Balancer Vault
  /// @param _sender                 The account performing the join (typically the pool shareholder).
  /// @param _recipient              Is the account designated to receive pool shares in the form of LP tokens.
  /// @param _currentBalancesU112   TODO
  ///                               Contains total token balances for each token the Pool registered in the Vault,
  ///                               in the same order that IVault.getPoolTokens would return. Differs from TWAMMs
  ///                               accounting of token reserves for this pool b/c of virtual orders.
  /// @param _protocolFeeDU1F18 The updated Balancer protocol fee.
  /// @param _userData               Comprised of a uint256 container and a 2 element array of uint256 containers:
  ///                               joinType and amounts, as described below:
  ///                               * joinType is decoded into the Enum JoinType
  ///                               * amounts is a 2 element array of uint256 containers, representing U112
  ///                               integer values of the maximum pool token amounts to provide in exchange for pool
  ///                               shares / LP tokens when joinType == Join. The values represent the amount to
  ///                               reward to the pool reserves (in exchange for nothing) when joinType == Reward.
  ///                               Array order is by the token order returned by IVault.getPoolTokens.
  /// @return amountsInU112        An array of uint256 containers, representing U112 integer values of the pool token
  ///                               amounts exchanged for pool shares / LP tokens received or received as part of a
  ///                               "reward" operation. The integer values in each array element are the amount of each
  ///                               token scaled by their number of decimal places. Array order is by the token order
  ///                               returned by IVault.getPoolTokens.
  /// @return dueProtocolFeeAmounts Balancer protocol fees
  function onJoinPool(
    bytes32 _poolId,
    address _sender,
    address _recipient,
    uint256[] memory _currentBalancesU112,
    uint256, /* lastChangeBlock - not used */
    uint256 _protocolFeeDU1F18,
    bytes calldata _userData
  )
    external
    override(IBasePool)
    nonReentrant
    poolNotPaused
    returns (uint256[] memory amountsInU112, uint256[] memory dueProtocolFeeAmounts)
  {
    _poolSafetyChecks(msg.sender, _poolId);

    JoinType joinType;
    // Stack Too Deep Opt.:
    {
      uint256 joinTypeU;
      (joinTypeU, amountsInU112) = abi.decode(_userData, (uint256, uint256[]));
      joinType = JoinType(joinTypeU);
    }
    requireErrCode(amountsInU112.length == 2, CronErrors.INVALID_ARGUMENTS);

    //
    // BEGIN WARNING: Don't move the following lines of code. Depending on where you
    //                move them, contract size increases 53b+.
    ////////////////////////////////////////////////////////////////////////////////
    // #savesize #savegas
    uint256 token0In = amountsInU112[TOKEN0_IDX];
    uint256 token1In = amountsInU112[TOKEN1_IDX];

    uint256 amountLP;
    ////////////////////////////////////////////////////////////////////////////////
    // END WARNING
    //

    //    uint256 totalSupply = totalSupply();
    uint256 token0Reserve;
    uint256 token1Reserve;
    if ((joinType == JoinType.Join && totalSupply() != 0) || (joinType == JoinType.Reward)) {
      // NOTE: Execute Virtual Orders is run for JoinType.Reward to ensure that the change in liquidity is
      // affecting virtual trades henceforth--not at the Last Virtual Order Block.
      (token0Reserve, token1Reserve) = _executeVirtualOrders(
        _currentBalancesU112[TOKEN0_IDX],
        _currentBalancesU112[TOKEN1_IDX],
        block.number
      );
    }

    if (joinType == JoinType.Join) {
      // Stack Too Deep Opt.:
      amountLP = _mintWrapper(_sender, _recipient, token0In, token1In, token0Reserve, token1Reserve);
    } else if (joinType != JoinType.Reward) {
      revertErrCode(CronErrors.INVALID_JOIN_TYPE);
    }

    // Reward Event when amountLP = 0
    emit PoolJoin(_sender, token0In, token1In, amountLP);

    dueProtocolFeeAmounts = _handleBalancerFees(_protocolFeeDU1F18);
  }

  /// @notice Called by the Vault when a user calls IVault.exitPool to remove liquidity from this Pool.
  /// @param _poolId              The ID for this pool in the Balancer Vault
  /// @param _sender                 The account performing the exit (typically the pool shareholder).
  /// @param _protocolFeeDU1F18 The updated Balancer protocol fee.
  /// @param _currentBalancesU112   TODO
  /// @param _userData               Comprised of 2 uint256 containers: exitType & argument as described below:
  ///                               * exitType is decoded into the Enum ExitType
  ///                               * argument is used as follows:
  ///                                    - if exitType == Exit
  ///                                           - argument is the number of LP tokens to redeem on exit
  ///                                           (burn). The value in the argument represents a number
  ///                                           with 18 decimal places.
  ///                                    - exitType == Withdraw || Cancel
  ///                                           - argument is the order id for the LT Swap
  ///                                    - exitType == FeeWithdraw
  ///                                           - argument is ignored
  ///
  /// @return amountsOutU112       An array of uint256 containers representing U112 integer values of the pool
  ///                               token amounts redeemed for _userData.amountLP LP token shares. The integer
  ///                               values in each array element are the amount of each token scaled by their
  ///                               number of decimal places. Array order is by the token order returned by
  ///                               IVault.getPoolTokens.
  /// @return dueProtocolFeeAmounts Balancer protocol fees
  function onExitPool(
    bytes32 _poolId,
    address _sender,
    address, /* _recipient - not used */
    uint256[] memory _currentBalancesU112,
    uint256, /* lastChangeBlock - not used */
    uint256 _protocolFeeDU1F18,
    bytes calldata _userData
  )
    external
    override(IBasePool)
    nonReentrant
    returns (uint256[] memory amountsOutU112, uint256[] memory dueProtocolFeeAmounts)
  {
    _poolSafetyChecks(msg.sender, _poolId);

    ExitType exitType;
    uint256 argument;
    // Stack too deep opt.:
    {
      uint256 exitTypeU;
      (exitTypeU, argument) = abi.decode(_userData, (uint256, uint256));
      exitType = ExitType(exitTypeU);
    }

    uint256 token0Out;
    uint256 token1Out;

    if (exitType == ExitType.FeeWithdraw) {
      (token0Out, token1Out) = _withdrawCronFees(_sender);
    } else {
      // Stack too deep opt.:
      {
        // Must be run for other exit types below too. In this block b/c token*Reserve
        // variables only used in _exit method (stack too deep opt)
        (uint256 token0Reserve, uint256 token1Reserve) = _executeVirtualOrders(
          _currentBalancesU112[TOKEN0_IDX],
          _currentBalancesU112[TOKEN1_IDX],
          block.number
        );

        if (exitType == ExitType.Exit) {
          (token0Out, token1Out) = _exit(_sender, argument, token0Reserve, token1Reserve);
        }
      }

      if (exitType == ExitType.Withdraw || exitType == ExitType.Cancel) {
        // For all calls in this else block:
        //   - argument is the Order ID
        //   - _sender must be the original virtual order _sender
        //
        // TODO: #safety add a maximum proceeds amount that can be used if rounding error on proceeds
        //       that permits withdraw despite failure. Can be expressed as whole numbers or percents.
        //       - Alternate soltuion would be a tolerance (i.e. within x of proceeds, just give proceeds).
        //       - Document and analyze the nature of this problem more clearly (different method of computing
        //         gross proceeds and individual proceeds).
        //       - Or perf. numerical analysis to disprove this concern
        //
        (token0Out, token1Out) = _withdrawLongTermSwapWrapper(argument, _sender, exitType == ExitType.Cancel);
      } else if (exitType != ExitType.Exit) {
        revertErrCode(CronErrors.INVALID_EXIT_TYPE);
      }
    }

    amountsOutU112 = new uint256[](2);
    amountsOutU112[TOKEN0_IDX] = token0Out;
    amountsOutU112[TOKEN1_IDX] = token1Out;

    dueProtocolFeeAmounts = _handleBalancerFees(_protocolFeeDU1F18);
  }

  /// @notice Set the administrator status of the provided address. Status "true" gives
  ///         administrative privileges.
  /// @param _admin  The address to add / remove administrative privileges.
  /// @param _status Whether to grant (true) or deny (false) administrative privileges.
  /// @dev          Careful. You can remove all administrative privileges, rendering the
  ///               contract unmanageable.
  /// Note: Must be called by the factory owner.
  ///
  function setAdminStatus(address _admin, bool _status) external senderIsFactoryOwner nonReentrant {
    adminAddrMap[_admin] = _status;
    emit AdministratorStatusChange(msg.sender, _admin, _status);
  }

  /// @notice Sets the destination address for Cron-Fi Swap fees. This value must
  ///         match the destination address in the forthcoming collection call (likely
  ///         a branch of onSwap). If this value is not set, Cron-Fi fees will not
  ///         be collected and all fees not going to Balancer will be reinvested in
  ///         reserves to go to the LPs. Cron-Fi Swap Fees only apply to Long-Term Swap orders.
  /// @param _feeDestination A destination address for Cron-Fi Swap fees. If unset (NULL_ADDRESS), no
  ///                       Cron-Fi Swap Fees are collected.
  /// Note: Must be called by the factory owner.
  ///
  function setFeeAddress(address _feeDestination) external senderIsFactoryOwner nonReentrant {
    feeAddr = _feeDestination;
    uint256 feeEnabled = (_feeDestination != NULL_ADDR) ? 1 : 0;
    slot4 = BitPackingLib.packBit(slot4, feeEnabled, S4_OFFSET_FEE_ENABLED);
    emit FeeAddressChange(msg.sender, _feeDestination);
  }

  /// @notice Sets whether the pool is paused or not. When the pool is paused,
  ///         New swaps of any kind cannot be issued. Liquidity cannot be provided.
  ///         Virtual orders are not executed for the remainder of allowable
  ///         operations, which include: removing liquidity, cancelling an order,
  ///         withdrawing cancelled or long-term swap proceeds.
  ///         This is a safety measure that is not a part of regular expected pool
  ///         operations.
  /// @param _pauseValue Pause the pool (true) or not.
  /// Note: Must be called by an administrator.
  ///
  function setPause(bool _pauseValue) external senderIsAdmin nonReentrant {
    slot4 = BitPackingLib.packBit(slot4, _pauseValue ? 1 : 0, S4_OFFSET_PAUSE);
  }

  /// @notice TODO
  /// @dev This aggregated parameter setter saves ~200 bytes of contract size. The missing 'else'
  ///      in the first if statement is intentional.
  ///
  function setParameter(uint256 _paramTypeU, uint256 _value) external senderIsAdmin nonReentrant {
    ParamType paramType = ParamType(_paramTypeU);

    // 1. Determine the bit-offset for any values that require an offset to be set:
    //
    uint256 offset;
    if (paramType == ParamType.SwapFeeBP) {
      offset = S1_OFFSET_SHORT_TERM_FEE_BP;
    } else if (paramType == ParamType.PartnerFeeBP) {
      offset = S1_OFFSET_PARTNER_FEE_BP;
    } else if (paramType == ParamType.LongSwapFeeBP) {
      offset = S1_OFFSET_LONG_TERM_FEE_BP;
    } else if (paramType == ParamType.HoldingPenaltyBP) {
      offset = S3_OFFSET_HOLDING_PENALTY_BP;
    }

    // 2. Map _paramType numerically to the corresponding slot and then do numerical limits test
    //    and set the value if conformant.
    //
    //    The 'value' variable is used to emit an event if a value is set. If a parameter cannot be
    //    set for some reason, the function returns and fails to emit the event.
    //
    //    No mapping from _paramType is made to the slot since there is no shared BitPackingLib
    //    setter function for slot3 values, hence checks against the enum directly.
    //
    uint256 value = _value;
    if (_paramTypeU <= 2 && offset != 0 && _value <= MAX_FEE_BP) {
      // Slot 1:
      slot1 = BitPackingLib.packU10(slot1, value, offset);
    } else if (paramType == ParamType.HoldingPenaltyBP && _value <= MAX_HOLDING_PENALTY_BP) {
      // Slot 3:
      slot3 = BitPackingLib.packU10(slot3, _value, S3_OFFSET_HOLDING_PENALTY_BP);
    } else if (paramType == ParamType.HoldingPeriodSec && _value <= MAX_HOLDING_PERIOD) {
      // Slot 3:
      slot3 = BitPackingLib.packHoldingPeriodSecS3(slot3, _value);
    } else {
      revertErrCode(CronErrors.PARAM_ERROR);
    }

    emit ParameterChange(msg.sender, paramType, value);
  }

  /// @notice TODO
  /// @param _collectCronFiFee TODO
  ///
  function setCollectCronFiFees(bool _collectCronFiFee) external senderIsFactoryOwner nonReentrant {
    slot4 = BitPackingLib.packBit(slot4, _collectCronFiFee ? 1 : 0, S4_OFFSET_FEE_ENABLED);
  }

  /// @notice TODO
  /// @param _collectBalancerFee TODO
  ///
  function setCollectBalancerFees(bool _collectBalancerFee) external senderIsFactoryOwner nonReentrant {
    slot4 = BitPackingLib.packBit(slot4, _collectBalancerFee ? 1 : 0, S4_OFFSET_COLLECT_BALANCER_FEES);
  }

  /// TODO: update documentation below
  /// @notice TODO
  /// @param _feeShift  TODO
  ///
  /// Convert Number of LP Shares to a Shift-Value (# bits to shift left).
  /// LP Fee Shares =  2 (66%), CronFi Fee Shares = 1 (33%), Denominator =  3, _feeShift=1
  /// LP Fee Shares =  4 (80%), CronFi Fee Shares = 1 (20%), Denominator =  5, _feeShift=2
  /// LP Fee Shares =  8 (88%), CronFi Fee Shares = 1 (11%), Denominator =  9, _feeShift=3
  /// LP Fee Shares = 16 (94%), CronFi Fee Shares = 1 ( 5%), Denominator = 17, _feeShift=4
  ///
  /// Previous documentation:
  /// notice Sets the number of fee shares to split between the LP and CronFi if
  ///         CronFi fee collection is enabled (when feeTo address is no the
  ///         NULL address). For instance, if fees are split 1 to 2 for CronFi
  ///         and LPs respectively, set _feeShares=2. This results in feeShiftU4
  ///         being set to 1 (the number of bits to shift the base share for the
  ///         LPs portion--CronFi always gets a single share).
  /// param _feeShares is a 256-bit container representing how many fee shares
  ///                  an LP gets (CronFi always gets a single share if this
  ///                  mechanism is enabled). Valid values are 2 (66%), 4 (80%),
  ///                  8 (99%), and 16 (95%). Specifiying invalid values results
  ///                  in no-operation (percentages are approximate).
  /// Note: Must be called by the factory owner.
  function setFeeShift(uint256 _feeShift) external senderIsFactoryOwner nonReentrant {
    if (_feeShift < 1 || _feeShift > 4) {
      // TODO: more meaningful error code
      revertErrCode(CronErrors.PARAM_ERROR);
    }
    slot3 = BitPackingLib.packFeeShiftS3(slot3, _feeShift);
  }

  /// @notice Sets the rook partner address to point to their contract address
  ///         listing approved arbitrage addresses. Using this method specific to
  ///         Rook enables the use of the specific KDAOSwap swap where a partner address
  ///         need not be specified for Rook's arbitrageurs along with Rook's proprietary
  ///         arbitrageur lookup. It also facilitates updating the arbitrage list for Rook
  ///         with their proprietary list update methods.
  /// @notice Sets the address of an arbitrage partner to point to a contract address
  ///         listing the partner's approved arbitrage addresses.
  /// @param _arbPartner is the address of the arbitrage partner.
  /// @param _arbitrageList is the address of an arbitrage contract instance conforming
  ///        to IArbitrageurList (or if _isRook to Rook contract interface).
  /// @param _isRook  TODO
  /// @dev NOTE: THERE CAN ONLY BE ONE ROOK PARTNER ADDRESS PER TWAMM POOL, OTHERWISE THE
  ///      LAST SET ONE TAKES PRECIDENCE.
  function setArbitragePartner(
    address _arbPartner,
    address _arbitrageList,
    bool _isRook
  ) external senderIsAdmin nonReentrant {
    if (_isRook) {
      // The following check ensures only one partner is defined as Rook. To change the
      // partner address, the arbitrage list address must be set to the null address first.
      requireErrCode(
        rookPartnerContractAddr == NULL_ADDR || partnerContractAddrMap[_arbPartner] == rookPartnerContractAddr,
        CronErrors.SINGLE_ROOK_PARTNER
      );

      rookPartnerContractAddr = _arbitrageList;
    }

    partnerContractAddrMap[_arbPartner] = _arbitrageList;
    emit UpdatedArbitragePartner(msg.sender, _arbPartner, _arbitrageList, _isRook);
  }

  /// @notice Advances the specified arbitrage partner (msg.sender) arbitrageur list
  ///         contract to the newest contract, if available.
  /// @return the new arbitrageur list contract address.
  /// @dev must be called by
  function updateArbitrageList() external senderIsArbitragePartner nonReentrant returns (address) {
    address currentList;
    address oldList = partnerContractAddrMap[msg.sender];
    address nextList = oldList;

    bool isRook = (nextList == rookPartnerContractAddr);

    do {
      currentList = nextList;
      nextList = (isRook) ? Rook(currentList).nextLinkedWhitelist() : IArbitrageurList(currentList).nextList();
    } while (nextList != NULL_ADDR);

    partnerContractAddrMap[msg.sender] = currentList;
    if (isRook) {
      rookPartnerContractAddr = currentList;
    }

    emit UpdatedArbitrageList(msg.sender, oldList, currentList);
    return currentList;
  }

  /// @notice TODO
  function transferMintEvent(
    address _dest,
    uint256 _srcEventIndex,
    uint256 _amount
  ) external nonReentrant {
    requireErrCode(_dest != msg.sender || _dest != NULL_ADDR, CronErrors.CANNOT_TRANSFER_TO_SELF_OR_NULL);

    MintEvent[] storage srcMintEvts = mintEventMap[msg.sender];
    uint256 srcLength = srcMintEvts.length;
    requireErrCode(_srcEventIndex < srcLength, CronErrors.NO_MINT_EVENT_AT_INDEX);

    uint256 timestamp = srcMintEvts[_srcEventIndex].timestamp;
    uint256 amountLP = srcMintEvts[_srcEventIndex].amountLP;
    requireErrCode(_amount <= amountLP, CronErrors.INSUFFICIENT_MINT_EVENT_LP);

    if (_amount == amountLP) {
      // When the number of tokens to burn equals the number in the
      // mint event, delete the event (use the shift-pop technique
      // to adjust length--can't use substitution pop method b/c
      // order is important):
      _deleteMintEvents(srcMintEvts, srcLength, _srcEventIndex, 1);
    } else {
      // When the number of tokens is less than the number in the mint event,
      // update the mint event with the amount remaining after the transfer.
      srcMintEvts[_srcEventIndex].amountLP -= _amount;
    }

    // Find destination index for insertion (we're already there if
    // destination length is zero or the length, in which case we just
    // append):
    //
    MintEvent[] storage dstMintEvts = mintEventMap[_dest];
    uint256 dstIndex = 0;
    uint256 dstLength = dstMintEvts.length;
    while (dstIndex < dstLength && timestamp > dstMintEvts[dstIndex].timestamp) {
      dstIndex++;
    }

    if (dstLength == 0 || dstIndex == dstLength) {
      // If we're in a zero length array or at the end, just push the
      // event to transfer onto the destination list:
      dstMintEvts.push(MintEvent(timestamp, _amount));
    } else if (timestamp == dstMintEvts[dstIndex].timestamp) {
      // Special case - timestamps equal, push tokens into existing storage. (saves gas)
      dstMintEvts[dstIndex].amountLP += _amount;
    } else {
      // Insert after shifting elements towards end from insertion position:
      //

      // Solidity insert by shifting. Add element to the array end and increase length
      // variable.
      dstMintEvts.push();
      dstLength++;

      // Copy the elements from smaller index to one larger index, effecting a
      // single position shift towards the end, starting from the end of the array
      // and working down to the insertion position.
      uint256 index = dstLength - 1;
      while (index > dstIndex) {
        dstMintEvts[index] = dstMintEvts[index - 1];
        index--;
      }
      // Finally, insert the new mint event in the insertion position:
      dstMintEvts[dstIndex].timestamp = timestamp;
      dstMintEvts[dstIndex].amountLP = _amount;
    }

    TransferMintEvent(msg.sender, _dest, _amount, timestamp);
  }

  /// @notice Executes existing Virtual Orders (Long-Term-swaps) since lastVirtualOrderBlock,
  ///         updating TWAMM reserve values and other TWAMM state variables up to the specified
  ///         maximum block.
  /// @param _maxBlock A specified block to update the virtual orders to (useful to specify in rare
  ///                 situation where inactive pool requires too much gas for a single successful call to
  ///                 executeVirtualOrders.) If not specified or not lastVirtualOrderBlock < _maxBlock < block.number,
  ///                 value is automatically set to block.number.
  function executeVirtualOrdersToBlock(uint256 _maxBlock) external nonReentrant {
    (, uint256[] memory balances, ) = VAULT.getPoolTokens(POOL_ID);
    _executeVirtualOrders(balances[TOKEN0_IDX], balances[TOKEN1_IDX], _maxBlock);
  }

  /// TODO: update this doc (now first 100 results)
  /// @notice Return the last 100 (MAX_RESULTS) order IDs for address _owner. If _offset > 0 is specified
  ///         then the last 100 (MAX_RESULTS) order IDs for address _owner shifted _offset from the total
  ///         number of order IDs is returned.  For example, if address _owner has 12 order IDs, then
  ///         order ID indices 2 to 11 are returned if _offset is zero. If _offset is two, then order ID
  ///         indices 0 to 9 are returned. This facilitates collecting all order IDs using multiple calls
  ///         but gets the most recent 10 by default for efficiency.
  /// @param  _owner is the address of the owner to fetch order ids for.
  /// @param  _offset is the number of elements from the end of the list to start fetching results from (
  ///         consult the operating description above).
  /// @return orderIds A uint256 array of order IDs associated with user's address
  /// @return numResults The number of order IDs returned (if a user has less than 10, MAX_RESULTS, some of
  ///                the result elements will be zero).
  function getOrderIds(address _owner, uint256 _offset)
    external
    view
    returns (
      uint256[] memory orderIds,
      uint256 numResults,
      uint256 totalResults
    )
  {
    orderIds = new uint256[](MAX_RESULTS);

    uint256[] storage orderIdArr = orderIdMap[_owner];
    totalResults = orderIdArr.length;

    for (uint256 index = _offset; numResults < MAX_RESULTS && index < totalResults; index++) {
      orderIds[numResults++] = orderIdArr[index];
    }
  }

  /// @notice TODO
  function getOrderIdCount() external view returns (uint256 nextOrderId) {
    nextOrderId = virtualOrders.nextOrderId;
  }

  /// @notice TODO
  function getSalesRateAmounts() external view returns (uint256 salesRate0, uint256 salesRate1) {
    uint256 salesRates = virtualOrders.orderPools.currentSalesRates;
    salesRate0 = (salesRates >> 112) & MAX_U112;
    salesRate1 = salesRates & MAX_U112;
  }

  /// @notice TODO
  /// TODO: needs paging strategy for length
  function getMintEvents(address _owner, uint256 _offset)
    external
    view
    returns (
      MintEvent[] memory mintEvents,
      uint256 numResults,
      uint256 totalResults
    )
  {
    mintEvents = new MintEvent[](MAX_RESULTS);

    MintEvent[] storage mintEventArr = mintEventMap[_owner];
    totalResults = mintEventArr.length;

    for (uint256 index = _offset; numResults < MAX_RESULTS && index < totalResults; index++) {
      mintEvents[numResults++] = mintEventArr[index];
    }
  }

  /// @notice Returns the TWAMM pool's reserves after the execution of all virtual orders up to the
  ///         current block. Differs from _calculateReserves in considering the execution of virtual
  ///         orders since the last virtual order block (LVOB).
  /// @return reserve0 A U112 value representing the amount of token 0, scaled up to token 0 decimal
  ///         places, held in this TWAMM pool as of the current block.
  /// @return reserve1 A U112 value representing the amount of token 1, scaled up to token 1 decimal
  ///         places, held in this TWAMM pool as of the current block.
  function getReserveAmounts() external view returns (uint112 reserve0, uint112 reserve1) {
    (, uint256[] memory balances, ) = VAULT.getPoolTokens(POOL_ID);

    ExecVirtualOrdersMem memory evoMem = _getExecVirtualOrdersMem(balances[TOKEN0_IDX], balances[TOKEN1_IDX]);

    // Is pause check needed to prevent this running if paused?  <-- TODO: Major Issue
    uint256 longTermFeeBP = BitPackingLib.unpackU10(slot1, S1_OFFSET_LONG_TERM_FEE_BP);
    virtualOrders.executeVirtualOrdersView(evoMem, ORDER_BLOCK_INTERVAL, longTermFeeBP);

    reserve0 = uint112(evoMem.token0Reserve);
    reserve1 = uint112(evoMem.token1Reserve);
  }

  // Slot 1:
  //
  function getShortTermFeePoints() external view returns (uint256) {
    return BitPackingLib.unpackU10(slot1, S1_OFFSET_SHORT_TERM_FEE_BP);
  }

  function getPartnerFeePoints() external view returns (uint256) {
    return BitPackingLib.unpackU10(slot1, S1_OFFSET_PARTNER_FEE_BP);
  }

  function getLongTermFeePoints() external view returns (uint256) {
    return BitPackingLib.unpackU10(slot1, S1_OFFSET_LONG_TERM_FEE_BP);
  }

  function getOrderAmounts() external view returns (uint256 token0, uint256 token1) {
    (token0, token1) = BitPackingLib.unpackPairU112(slot1);
  }

  // Slot 2:
  //
  function getOracleTimeStamp() external view returns (uint256) {
    return BitPackingLib.unpackOracleTimeStampS2(slot2);
  }

  function getProceedAmounts() external view returns (uint256 token0, uint256 token1) {
    (token0, token1) = BitPackingLib.unpackPairU112(slot2);
  }

  // Slot 3:
  //
  function getFeeShift() external view returns (uint256) {
    return BitPackingLib.unpackFeeShiftS3(slot3);
  }

  function getHoldingPenaltyPoints() external view returns (uint256) {
    return BitPackingLib.unpackU10(slot3, S3_OFFSET_HOLDING_PENALTY_BP);
  }

  function getHoldingPeriod() external view returns (uint256) {
    return BitPackingLib.unpackHoldingPeriodSecS3(slot3);
  }

  function getCronFeeAmounts() external view returns (uint256 token0, uint256 token1) {
    (token0, token1) = BitPackingLib.unpackPairU96(slot3);
  }

  // Slot 4:
  //
  function isPaused() external view returns (bool) {
    return BitPackingLib.unpackBit(slot4, S4_OFFSET_PAUSE) != FALSE;
  }

  function isCollectingCronFees() external view returns (bool) {
    return BitPackingLib.unpackBit(slot4, S4_OFFSET_FEE_ENABLED) != FALSE;
  }

  function isCollectingBalancerFees() external view returns (bool) {
    return BitPackingLib.unpackBit(slot4, S4_OFFSET_COLLECT_BALANCER_FEES) != FALSE;
  }

  function getBalancerFee() external view returns (uint256) {
    return BitPackingLib.unpackBalancerFeeS4(slot4);
  }

  function getBalancerFeeAmounts() external view returns (uint256 token0, uint256 token1) {
    (token0, token1) = BitPackingLib.unpackPairU96(slot4);
  }

  /// @notice TODO:
  function _senderIsFactoryOwner() internal view {
    requireErrCode(msg.sender == ICronV1PoolFactory(FACTORY).owner(), CronErrors.SENDER_NOT_FACTORY_OWNER);
  }

  /// @notice TODO:
  function _senderIsAdmin() internal view {
    requireErrCode(adminAddrMap[msg.sender], CronErrors.SENDER_NOT_ADMIN);
  }

  /// @notice TODO:
  function _senderIsArbitragePartner() internal view {
    requireErrCode(partnerContractAddrMap[msg.sender] != NULL_ADDR, CronErrors.SENDER_NOT_ARBITRAGE_PARTNER);
  }

  /// @notice TODO:
  function _poolNotPaused() internal view {
    uint256 paused = BitPackingLib.unpackBit(slot4, S4_OFFSET_PAUSE);
    requireErrCode(paused == FALSE, CronErrors.POOL_PAUSED);
  }

  /// @notice executes existing Virtual Orders (Long-Term-swaps) since lastVirtualOrderBlock,
  ///         updating TWAMM reserve values and other TWAMM state variables up to the specified
  ///         maximum block.
  /// @param _balance0        The Balancer Vault balance of Token 0 for this pool. A U112 value in a
  ///                        U256 container.
  /// @param _balance1        The Balancer Vault balance of Token 1 for this pool. A U112 value in a
  ///                        U256 container.
  /// @param _maxBlock        A specified block to update the virtual orders to (useful to specify in rare
  ///                        situation where inactive pool requires too much gas for a single successful call to
  ///                        executeVirtualOrders.) If not specified or not lastVirtualOrderBlock < _maxBlock < block.number,
  ///                        value is automatically set to block.number.
  /// @return token0TwammRes A U112 value representing the amount of token 0, scaled up to token 0 decimal
  ///                        places, held in this TWAMM pool as of the specified maximum Block (_maxBlock).
  /// @return token1TwammRes A U112 value representing the amount of token 1, scaled up to token 1 decimal
  ///                        places, held in this TWAMM pool as of the specified maximum Block (_maxBlock).
  /// @dev            Private version of this function that does no checks on param _maxBlock
  /// TODO:
  ///   - #safety Need to check for overflow. On overflow, clamp to maximum (stop fee collection
  ///             until collected). Issue fee oflow event log.
  function _executeVirtualOrders(
    uint256 _balance0,
    uint256 _balance1,
    uint256 _maxBlock
  ) private returns (uint256 token0TwammRes, uint256 token1TwammRes) {
    if (!(virtualOrders.lastVirtualOrderBlock < _maxBlock && _maxBlock < block.number)) {
      _maxBlock = block.number;
    }

    uint256 localSlot4 = slot4; // #savegas
    uint256 paused = BitPackingLib.unpackBit(localSlot4, S4_OFFSET_PAUSE);

    ExecVirtualOrdersMem memory evoMem = _getExecVirtualOrdersMem(_balance0, _balance1);

    if (paused == FALSE) {
      uint256 longTermFeeBP = BitPackingLib.unpackU10(slot1, S1_OFFSET_LONG_TERM_FEE_BP);
      virtualOrders.executeVirtualOrdersToBlock(evoMem, ORDER_BLOCK_INTERVAL, _maxBlock, longTermFeeBP);

      uint256 feeEnabled = BitPackingLib.unpackBit(localSlot4, S4_OFFSET_FEE_ENABLED);
      if (feeEnabled != FALSE) {
        // CAREFUL!  Note the change to localSlot4 here!!! It gets set below when balancer fees
        //           are updated.
        localSlot4 = BitPackingLib.packBit(localSlot4, 1, S4_OFFSET_ZERO_CRONFI_FEES);

        slot3 = BitPackingLib.incrementPairWithClampU96(slot3, evoMem.token0CronFiFees, evoMem.token1CronFiFees);
      }

      // TODO: Check fee additions do not exceed maximum--if they do, then clamp to maximum and
      //       consider issuing warning event.  (Prevents blockage, can clamp to lower maximum to
      //       compress data further).
      //       - in checking here, need to make sure that value won't overflow on add
      //       - need to make sure value doesn't exceed MAX_U112
      slot4 = BitPackingLib.incrementPairWithClampU96(localSlot4, evoMem.token0BalancerFees, evoMem.token1BalancerFees);

      // Update order accounting:
      //
      slot1 = BitPackingLib.decrementPairU112(slot1, evoMem.token0Orders, evoMem.token1Orders);

      // Update proceeds accounting:
      //
      slot2 = BitPackingLib.incrementPairU112(slot2, evoMem.token0Proceeds, evoMem.token1Proceeds);

      // As in UNI V2, the oracle price is based on the reserves before the current operation (i.e. swap).
      // For TWAMM, we augment that to incorporate the reserves after executing virtual operations.
      // Note: We only update the oracle when not paused.  If Paused, pricing info becomes distorted and
      //       shouldn't be incorporated into the oracle.  <-- TODO: Discuss / consider.
      //
      // TODO: check evoMem.tokenNReserve <= MAX_U112?
      _updateOracle(evoMem.token0Reserve, evoMem.token1Reserve);
    }

    token0TwammRes = evoMem.token0Reserve;
    token1TwammRes = evoMem.token1Reserve;
  }

  /// @notice TODO
  function _updateOracle(uint256 _token0ReserveU112, uint256 _token1ReserveU112) private {
    uint256 localSlot2 = slot2;
    uint32 oracleTimeStamp = uint32(BitPackingLib.unpackOracleTimeStampS2(localSlot2));

    // UNI V2 Style Oracle
    uint32 blockTimeStamp = uint32(block.timestamp % 2**32);
    uint32 timeElapsed = blockTimeStamp - oracleTimeStamp; // nv. underflows

    if (timeElapsed > 0 && _token0ReserveU112 > 0 && _token1ReserveU112 > 0) {
      // UQ112x112 RESULT: INCREMENTED VALUE RELIES UPON/EXPECTS OVERFLOW, HENCE UNCHECKED!
      //                   Overflow is not possible in the shift (U256 > (U112 << 112)).
      priceOracle.token0 += ((_token1ReserveU112 << 112) / _token0ReserveU112) * timeElapsed;
      priceOracle.token1 += ((_token0ReserveU112 << 112) / _token1ReserveU112) * timeElapsed;
    }

    slot2 = BitPackingLib.packOracleTimeStampS2(localSlot2, blockTimeStamp);
  }

  /// @notice Execute a Short-Term-swap (ST)-swap, selling _amountInU112 _tokenIn to this pool in exchange for the
  ///         pool's other token. The swap is atomic and executes in a single transaction, unlike Long-Term-swaps
  ///         (Virtual Orders.)
  /// @param _token0To1     TODO
  // param _tokenIn          TODO: remove this and refs to it in this documentation.
  /// @param _amountInU112    Is a uint256 container reperesenting a U112 amount of the token being sold to the pool.
  ///                         This value should be scaled up to the number of decimal places of _tokenIn.
  /// @param _token0Reserve TODO
  /// @param _token1Reserve TODO
  /// @return amountOutU112  A uint256 container representing a U112 amount of the token being returned
  ///                         for swapping _tokenIn with this pool.
  /// TODO:
  ///   - #safety Need to check for overflow for all input amounts (total in pool must be < MAX_U112)
  function _shortTermSwap(
    bool _token0To1,
    uint256 _swapFee,
    uint256 _amountInU112,
    uint256 _token0Reserve,
    uint256 _token1Reserve
  ) private returns (uint256 amountOutU112) {
    uint256 grossFee = (_amountInU112.mul(_swapFee)).divUp(BP);

    uint256 localSlot4 = slot4; // #savegas
    uint256 collectBalancerFees = BitPackingLib.unpackBit(localSlot4, S4_OFFSET_COLLECT_BALANCER_FEES);
    if (collectBalancerFees != FALSE) {
      uint256 balancerFeeDU1F18 = BitPackingLib.unpackBalancerFeeS4(localSlot4);
      uint256 balancerFeeU112 = (grossFee.mul(balancerFeeDU1F18)).divUp(DENOMINATOR_DU1_18);

      // #contractsize add balancer fees from swap
      slot4 = BitPackingLib.incrementPairWithClampU96(
        localSlot4,
        (_token0To1 ? balancerFeeU112 : 0),
        (_token0To1 ? 0 : balancerFeeU112)
      );
    }

    // Note: LP Fees are automatically collected in the vault balances and need not be calculated here.
    //       (Previously they were computed and added to twamm reserves explicitly as lpFee = grossFee - balancerFee)
    uint256 amountInLessFeesU112 = _amountInU112 - grossFee;
    if (_token0To1) {
      // TODO:
      //   - #savegas unchecked optimizations if possible
      //   - #safety do we need to check limits on balancer fees below?
      uint256 nextReserve0U112 = _token0Reserve.add(amountInLessFeesU112);
      amountOutU112 = (_token1Reserve.mul(amountInLessFeesU112)).divDown(nextReserve0U112);
    } else {
      // TODO:
      //   - #savegas unchecked optimizations if possible
      //   - #safety do we need to check limits on balancer fees below?
      uint256 nextReserve1U112 = _token1Reserve.add(amountInLessFeesU112);
      amountOutU112 = (_token0Reserve.mul(amountInLessFeesU112)).divDown(nextReserve1U112);
    }
  }

  /// @notice Execute a Long-Term-swap (LT)-swap (Virtual Order), which sells _amountInU112 _tokenIn to this pool
  ///         in exchange for the pool's other token. The swaps are broken up into smaller orders according to the
  ///         value _orderIntervals. The swap size is _amountInU112 / _orderIntervals and each swap occurs
  ///         ORDER_BLOCK_INTERVAL blocks apart until the order is exahausted. Proceeds can be withdrawn at any time
  ///         during the order and/or at the end of the order, until they are exhausted. Orders can be cancelled by
  ///         executing _withdrawLongTermSwap.
  /// @param _sender           Is the account issuing the LT-swap. Only this account can withdraw the order.
  // param _token0To1         TODO
  // param _tokenIn          TODO: remove references in do to this and this
  /// @param _amountInU112    Is a uint256 container reperesenting a U112 amount of the token being sold to the pool.
  ///                         This value should be scaled up to the number of decimal places of _tokenIn.
  /// @param _orderIntervals   The number of intervals to execute the trade of _amountInU112 _tokenIn over. _amountInU112
  ///                         is divided into this many trades and executed sequentially each interval. The number of
  ///                         blocks per interval is given by this contracts ORDER_BLOCK_INTERVAL.
  /// @dev The order id for an issued order is in the event log emitted by this function. No safety is provided for
  ///      checking existing order ids being reissued b/c the order id space is very large (type(uint256).max).
  /// TODO:
  ///   - #safety  Need to check for overflow for all input amounts (total in pool must be < MAX_U112)
  ///   - #safety  Need to determine if overflow checking operations required here.
  ///   - #safety  Ensure cost of an orderId wrap attack is prohibitively expensive (i.e. issuing U256_MAX + n
  ///              orders to clobber an existing valuable order). (Would need to mine so many that it seems unlikely
  ///              even for a skim style attack.)
  ///   - #savegas Should the increment of nextOrderId be unchecked (desire overflow to zero).
  ///     #issue
  function _longTermSwap(
    address _sender,
    bool _token0To1,
    uint256 _amountInU112,
    uint256 _orderIntervals
  ) private returns (uint256 orderId) {
    requireErrCode(_amountInU112 < MAX_U112, CronErrors.LT_TRADE_AMOUNT_TOO_LARGE);

    // Determine selling rate based on number of blocks to expiry and total amount
    uint256 lastExpiryBlock = block.number - (block.number % ORDER_BLOCK_INTERVAL);
    uint256 orderExpiry = ORDER_BLOCK_INTERVAL * (_orderIntervals + 1) + lastExpiryBlock; // +1 protects from div 0
    uint256 tradeBlocks = orderExpiry - block.number;
    uint256 sellingRate = _amountInU112 / tradeBlocks;
    requireErrCode(sellingRate > 0, CronErrors.ZERO_SALES_RATE);

    // Update the current and ending sales rates state:
    //
    OrderPools storage ops = virtualOrders.orderPools;
    ops.currentSalesRates = BitPackingLib.incrementPairU112(
      ops.currentSalesRates,
      _token0To1 ? sellingRate : 0,
      _token0To1 ? 0 : sellingRate
    );
    ops.salesRatesEndingPerBlock[orderExpiry] = BitPackingLib.incrementPairU112(
      ops.salesRatesEndingPerBlock[orderExpiry],
      _token0To1 ? sellingRate : 0,
      _token0To1 ? 0 : sellingRate
    );

    // NOTE: Cast to uint112 below for sellingRate is safe because _amountInU112 is confirmed to be
    //       less than 112-bits in check above and division operation will not underflow the value.
    // NOTE: Cast to uint128 below for unpackPairU128 is safe because result of that function
    //       cannot execeed 128-bits (correct by construction, i.e. function pulls a 128-bit value from
    //       packed storage in 256-bit slot).
    // NOTE: scaledProceeds0 is measured in amount of Token 1 received for selling Token 0 from Order Pool 0
    //       to the AMM (and vice-versa scaledProceeds1).
    orderId = virtualOrders.nextOrderId++;
    virtualOrders.orderMap[orderId] = Order(
      _token0To1,
      uint112(sellingRate),
      uint128(BitPackingLib.unpackU128(ops.scaledProceeds, _token0To1)),
      _sender,
      orderExpiry
    );
    orderIdMap[_sender].push(orderId);

    // Update order accounting (add the user's order amount to the global orders accounting):
    // Note: The amount in (_amountInU112) is not the amount that will be swapped due to
    //       truncation. The amount that will be swapped is the number of blocks in the order
    //       multiplied by the order sales rate. The remainder is added to the pool reserves,
    //       augmenting LP rewards (Caveat Emptor Design Philosophy for Swap User). The addition
    //       happens when vault and pool reserves are sync'd.
    // TODO: Consider adding the difference between amountIn and the actual amount below to token
    //       reserves here since EVO has run and the pool is up-to-date.
    // TODO: Checks for pool overflow (this will become a sync method call likely).
    //       - Does Bal do this already apriori or after? (check their code or test)
    // Increment the order amounts:
    uint256 orderAmount = sellingRate * tradeBlocks;
    slot1 = BitPackingLib.incrementPairU112(slot1, (_token0To1 ? orderAmount : 0), (_token0To1 ? 0 : orderAmount));
  }

  /// @notice TODO
  function _withdrawCronFees(address _sender) private returns (uint256 token0Out, uint256 token1Out) {
    // IMPORTANT: safety check to ensure user is fee address
    requireErrCode(feeAddr == _sender, CronErrors.SENDER_NOT_FEE_ADDRESS);

    // Note: Optimization - the U96 values being read below are the Cron-Fi Fees. The are assigned to the
    //       output tokens and their count is cleared. The zero Cron-Fi fees flag is set to save gas
    //       on future computations (preventing an un-necesary read from slot3).
    uint256 localSlot4 = slot4; // #savegas
    uint256 zeroCronFiFees = BitPackingLib.unpackBit(localSlot4, S4_OFFSET_ZERO_CRONFI_FEES);

    if (zeroCronFiFees != FALSE) {
      // Send the Cron-Fi fees out of the pool and zero our accounting of them:
      (slot3, token0Out, token1Out) = BitPackingLib.unpackAndClearPairU96(slot3);

      // Set the Zero Cron-Fi fees flag since we've cleared the Cron-Fi fees counters:
      slot4 = BitPackingLib.packBit(localSlot4, 1, S4_OFFSET_ZERO_CRONFI_FEES);
    }

    emit FeeWithdraw(_sender, token0Out, token1Out);
  }

  /// @notice TODO
  /// Stack too deep workaround:
  function _withdrawLongTermSwapWrapper(
    uint256 _orderId,
    address _sender,
    bool _cancel
  ) private returns (uint256 token0Out, uint256 token1Out) {
    (bool token0To1, uint256 refundU112, uint256 proceedsU112) = _withdrawLongTermSwap(_orderId, _sender, _cancel);

    // Update order and proceeds accounting:
    // NOTE: The execute virtual orders run prior to this function updates the orders and proceeds amounts.
    token0Out = (token0To1) ? refundU112 : proceedsU112;
    token1Out = (token0To1) ? proceedsU112 : refundU112;
  }

  /// @notice Cancel a Long-Term (LT)-swap (Virtual Order). Call this method, to refunds the unsold tokens
  ///         and partial proceeds from sold tokens of the LT-Swap. Calls to this method are made through
  ///         the Vault's exit method which calls the callback to these methods, onExit, requiring particular
  ///         configuration of swapData.
  /// @param _orderId          TODO
  /// @param _sender TODO
  /// @param _cancel TODO
  /// @return token0To1
  /// @return refundU112 TODO
  /// @return proceedsU112 TODO
  ///
  /// TODO:
  ///   - #safety             Need to determine if overflow checking operations required here.
  ///   - #savegas            Can both these happen in a batch swap?
  ///     #usability          Batch swap and/or periphery contract?
  function _withdrawLongTermSwap(
    uint256 _orderId,
    address _sender,
    bool _cancel
  )
    private
    returns (
      bool token0To1,
      uint256 refundU112,
      uint256 proceedsU112
    )
  {
    Order storage order = virtualOrders.orderMap[_orderId];

    requireErrCode(order.owner == _sender, CronErrors.SENDER_NOT_ORDER_OWNER);

    token0To1 = order.token0To1;
    uint256 expiry = order.orderExpiry;
    uint256 stakedAmount = order.salesRate;

    if (_cancel) {
      // IMPORTANT: Ensures order NOT ALREADY expired.
      requireErrCode(expiry > block.number, CronErrors.COMPLETED_ORDER);

      // Calculate unsold amount to refund:
      // Note: Must use lvbo, not block.number to yield correct result when paused.
      refundU112 = (expiry - virtualOrders.lastVirtualOrderBlock) * stakedAmount;
    } else {
      // IMPORTANT: Handles already completely withdrawn orders.
      requireErrCode(stakedAmount > 0, CronErrors.COMPLETED_ORDER_WITHDRAWN);
    }

    uint256 scaledProceeds = BitPackingLib.unpackU128(
      (!_cancel && (block.number > expiry))
        ? virtualOrders.scaledProceedsAtBlock[expiry] // Expired or cancelled order - calculate scaled proceeds at expiry.
        : virtualOrders.orderPools.scaledProceeds, // Unexpired order. Remit current proceeds.
      token0To1
    );
    proceedsU112 = _calculateProceeds(scaledProceeds, order.scaledProceedsAtSubmission, stakedAmount);

    // WARNING: This must come after the calculation of proceedsU112
    if (!_cancel && (block.number <= expiry)) {
      // Reset stake if not cancellation and not expired order

      // NOTE: Cast to uint128 below for scaledProceeds is safe because result of function unpackPairU128
      //       cannot execeed 128-bits (correct by construction, i.e. function pulls a 128-bit value from
      //       packed storage in 256-bit slot).
      order.scaledProceedsAtSubmission = uint128(scaledProceeds);
    }

    requireErrCode(refundU112 > 0 || proceedsU112 > 0, CronErrors.NO_REFUND_AVAILABLE);

    if (_cancel) {
      OrderPools storage ops = virtualOrders.orderPools;

      // Decrement the current and ending sales rates:
      ops.currentSalesRates = BitPackingLib.decrementPairU112(
        ops.currentSalesRates,
        token0To1 ? stakedAmount : 0,
        token0To1 ? 0 : stakedAmount
      );
      ops.salesRatesEndingPerBlock[expiry] = BitPackingLib.decrementPairU112(
        ops.salesRatesEndingPerBlock[expiry],
        token0To1 ? stakedAmount : 0,
        token0To1 ? 0 : stakedAmount
      );

      // Update the order accounting:
      slot1 = BitPackingLib.decrementPairU112(slot1, (token0To1 ? refundU112 : 0), (token0To1 ? 0 : refundU112));
    }

    // Update the proceed accounting:
    slot2 = BitPackingLib.decrementPairU112(slot2, (token0To1 ? 0 : proceedsU112), (token0To1 ? proceedsU112 : 0));

    if (_cancel || block.number > expiry) {
      // Remove stake and clear order state for rebate and to indicate order complete:
      order.orderExpiry = 0;
      order.salesRate = 0;
      order.scaledProceedsAtSubmission = 0;
    }

    emit WithdrawLongTermSwap(
      order.owner,
      (token0To1) ? address(TOKEN0) : address(TOKEN1), // sell token
      refundU112,
      (token0To1) ? address(TOKEN1) : address(TOKEN0), // buy token
      proceedsU112,
      _orderId
    );
  }

  /// TODO - documentation (this is a stack too deep opt)
  // @notice Perform the initial mint / join operation for a pool with no liquidity.
  // @param _token0In TODO
  // @param _token1In TODO
  // @return amountLP      The number of Liquidity Provider (LP) tokens minted by providing liquidity; 18 decimal
  ///                       places.
  /// TODO:
  ///   - #safety Need to check for overflow:
  ///               * For all input amounts (total in pool must be < MAX_U112). Right now
  ///                 it is neglecting the balance of this contract and just looking at the
  ///                 reserves. Needs to consider order pool outstanding orders and proceeds.
  ///   - #savegas Are any checks here redundant (i.e. done by Balancer on exit).
  ///   - #safety Is R3 needed if the sub underflows? (This check makes sure the mean exceeds min)
  ///     #savegas
  // @notice Perform a mint / join operation for a pool that already has liquidity.
  // @param _token0In TODO
  // @param _token1In TODO
  // @param _token0Balance TODO
  // @param _token1Balance TODO
  // @param _lTotalSupply   The total issued supply of LP tokens.
  // TODO: delete next docstring when working
  // @param _currentBalancesU112   TODO
  // @return _amountLP      The number of Liquidity Provider (LP) tokens minted by providing liquidity;
  ///                       18 decimal places.
  /// TODO:
  ///   - #safety Need to check for overflow:
  ///               * For all input amounts (total in pool must be < MAX_U112). Right now
  ///                 it is neglecting the balance of this contract and just looking at the
  ///                 reserves. Needs to consider order pool outstanding orders and proceeds.
  ///   - #savegas Are any checks here redundant (i.e. done by Balancer on exit).
  function _mintWrapper(
    address _sender,
    address _recipient,
    uint256 _token0In,
    uint256 _token1In,
    uint256 _token0Reserve,
    uint256 _token1Reserve
  ) private returns (uint256 amountLP) {
    uint256 _totalSupply = totalSupply();

    // #contractsize (re-use checks and zero value reserve addition for initial mint)
    // TODO: Analyze this path and see if the MAX_U112 check for the sum is made elsewhere.
    //       Shouldn't be possible to overflow the U256, explain why for audit.
    // TODO: Can usurp this entire problem by checking inflows and outflows against current balances instead
    //       of against reserves etc.
    //
    requireErrCode(
      _token0In <= MAX_U112 && (_token0In + _token0Reserve) <= MAX_U112,
      CronErrors.TOO_MUCH_TOKEN0_LIQUIDITY
    ); // R1
    requireErrCode(
      _token1In <= MAX_U112 && (_token1In + _token1Reserve) <= MAX_U112,
      CronErrors.TOO_MUCH_TOKEN1_LIQUIDITY
    ); // R2

    if (_totalSupply == 0) {
      requireErrCode(
        (_token0In >= MINIMUM_LIQUIDITY) && (_token1In >= MINIMUM_LIQUIDITY),
        CronErrors.INSUFFICIENT_LIQUIDITY
      ); // R3

      amountLP = MiscLib.sqrt(_token0In.mul(_token1In)).sub(MINIMUM_LIQUIDITY);

      // Initial Mint does not execute virtual orders, is only run once b/c of MINIMUM_LIQUIDITY, thus
      // an explicit call to update the oracle using the amounts in.
      _updateOracle(_token0In, _token1In);

      _mintPoolTokens(address(0), MINIMUM_LIQUIDITY); // Permanently locked for div / 0 safety.
    } else {
      amountLP = Math.min(
        _token0In.mul(_totalSupply).divDown(_token0Reserve),
        _token1In.mul(_totalSupply).divDown(_token1Reserve)
      );
    }

    requireErrCode(amountLP > 0, CronErrors.INSUFFICIENT_LIQUIDITY);
    _mintPoolTokens(_recipient, amountLP);

    // Setup holding period to disincentivize MEV capture attacks:
    MintEvent[] storage mintEvents = mintEventMap[_sender];
    mintEvents.push(MintEvent(block.timestamp, amountLP));
  }

  /// @notice TODO
  function _exit(
    address _sender,
    uint256 _tokensLP,
    uint256 _token0Reserve,
    uint256 _token1Reserve
  ) private returns (uint256 token0Out, uint256 token1Out) {
    uint256 lTotalSupply = totalSupply(); // Super-important that this is before burning pool tokens.
    // TODO: does _burnPoolTokens check for reasonable things (i.e. exceeding balance etc.)
    _burnPoolTokens(_sender, _tokensLP);
    token0Out = (_token0Reserve.mul(_tokensLP)).divDown(lTotalSupply);
    token1Out = (_token1Reserve.mul(_tokensLP)).divDown(lTotalSupply);

    // Prevent MEV Attack Process (Holding Period Deration)
    ////////////////////////////////////////////////////////////////////////////////

    // Iterate over mint events to determine how many of the specified tokens to exit (burn)
    // need be penalized due to holding period violations. Also update mintEvents to remove
    // tokens being exited (burned), in order of longest held:
    //
    uint256 penalizedLP = _tokensLP;
    uint256 localSlot3 = slot3;
    //
    // Stack too deep opt.
    {
      uint256 holdingPeriodSec = BitPackingLib.unpackHoldingPeriodSecS3(localSlot3);

      uint256 index = 0;
      uint256 countLP = _tokensLP;

      MintEvent[] storage mintEvents = mintEventMap[_sender];
      uint256 length = mintEvents.length;
      uint256 deleteElements = 0;

      while (index < length) {
        // Note: Mint events are stored in ascending time order.

        if (countLP >= mintEvents[index].amountLP) {
          // When the number of tokens to burn exceeds or equals the number in the
          // mint event, mark it for deletion later.
          deleteElements++;
          countLP -= mintEvents[index].amountLP;

          // Reduce the penalized LP token count if the holding period is satisfied.
          if ((block.timestamp - mintEvents[index].timestamp) >= holdingPeriodSec) {
            penalizedLP -= mintEvents[index].amountLP;
          }
        } else {
          // When the number of tokens is less than the number in the mint event,
          // update the mint event with the amount remaining for redemption and stop
          // iterations:
          mintEvents[index].amountLP -= countLP;
          countLP = 0;

          // Reduce the penalized LP token count if the holding period is satisfied.
          if ((block.timestamp - mintEvents[index].timestamp) >= holdingPeriodSec) {
            penalizedLP = 0;
          }
          break;
        }

        index++;
      }

      // Delete invalidated mint events (use the shift-pop technique
      // to adjust length--can't use substitution pop method b/c
      // order is important):
      //
      if (deleteElements > 0) {
        _deleteMintEvents(mintEvents, length, 0, deleteElements);
      }
    }

    // Figure out the penalized amounts out (if there's any penalty):
    //
    uint256 penalty0;
    uint256 penalty1;
    if (_tokensLP > 0) {
      // TODO: Justify unchecked math below
      uint256 holdingPenaltyBP = BitPackingLib.unpackU10(localSlot3, S3_OFFSET_HOLDING_PENALTY_BP);
      penalty0 = (holdingPenaltyBP * (penalizedLP * token0Out).divUp(_tokensLP)) / BP;
      penalty1 = (holdingPenaltyBP * (penalizedLP * token1Out).divUp(_tokensLP)) / BP;
      token0Out -= penalty0;
      token1Out -= penalty1;
    }

    emit PoolExit(_sender, _tokensLP, token0Out, penalty0, token1Out, penalty1);
  }

  /// TODO
  function _handleBalancerFees(uint256 _protocolFeeDU1F18) private returns (uint256[] memory dueProtocolFeeAmounts) {
    uint256 localSlot4 = slot4;
    if (_protocolFeeDU1F18 <= ONE_DU1_18) {
      uint256 currentBalancerFee = BitPackingLib.unpackBalancerFeeS4(localSlot4);
      // #savegas:
      if (currentBalancerFee != _protocolFeeDU1F18) {
        localSlot4 = BitPackingLib.packBalancerFeeS4(localSlot4, _protocolFeeDU1F18);
      }
    } else {
      // Ignore change and keep operating with old fee if new fee is too large.
      emit ProtocolFeeTooLarge(_protocolFeeDU1F18);
    }

    dueProtocolFeeAmounts = new uint256[](2);
    // Send the Balancer fees out of the pool and zero our accounting of them:
    (slot4, dueProtocolFeeAmounts[TOKEN0_IDX], dueProtocolFeeAmounts[TOKEN1_IDX]) = BitPackingLib.unpackAndClearPairU96(
      localSlot4
    );
  }

  /// TODO
  function _deleteMintEvents(
    MintEvent[] storage _mintEvents,
    uint256 _length,
    uint256 _startIndex,
    uint256 _numberToDelete
  ) private {
    uint256 updatedLength = _length - _numberToDelete;
    for (uint256 index = _startIndex; index < updatedLength; index++) {
      _mintEvents[index] = _mintEvents[index + 1];
    }
    while (_numberToDelete-- > 0) {
      _mintEvents.pop();
    }
  }

  /// @notice TODO
  /// @param _sender TODO
  /// @param _poolId TODO
  /// #contractsize
  function _poolSafetyChecks(address _sender, bytes32 _poolId) private view {
    requireErrCode(_sender == address(VAULT), CronErrors.NON_VAULT_CALLER);
    requireErrCode(_poolId == POOL_ID, CronErrors.INCORRECT_POOL_ID);
  }

  /// @notice TODO
  function _getExecVirtualOrdersMem(uint256 _token0Balance, uint256 _token1Balance)
    private
    view
    returns (ExecVirtualOrdersMem memory evoMem)
  {
    (uint256 token0TwammRes, uint256 token1TwammRes) = _calculateReserves(_token0Balance, _token1Balance);

    // Fees:
    //   * The LP Fee and Balancer Fee sum to 100%, which in this case is 1e18:
    //
    //       lpFeeU60 + balancerFeeDU1F18 = ONE_DU1_18
    //
    //   * If no Balancer Fee is collected, the LP Fee is 100%, which is 1e18.
    //   * If a Cron-Fi Fee is collected (when feeEnabled is true), then the LP Fee is sub-divided into
    //     1 + 2^feeShiftU3 parts, where Cron-Fi takes 1 part and the LPs get 2^feeShiftU3 parts.
    //     The implementation uses shifting because it is the inner loop of execute virtual orders and
    //     saves a reasonable amount of gas over multiplying.
    //
    uint256 localSlot = slot4; // #savegas
    uint256 feeEnabled = BitPackingLib.unpackBit(localSlot, S4_OFFSET_FEE_ENABLED);
    uint256 collectBalancerFees = BitPackingLib.unpackBit(localSlot, S4_OFFSET_COLLECT_BALANCER_FEES);
    uint256 balancerFeeDU1F18 = BitPackingLib.unpackBalancerFeeS4(localSlot);

    uint256 lpFeeU60 = (collectBalancerFees != FALSE) ? ONE_DU1_18 - balancerFeeDU1F18 : ONE_DU1_18;

    // When CronFi fees are not enabled, feeShareU60 is set to zero and feeShiftU3 is ignored in
    // execute virtual orders. Otherwise the values are set as below. This saves gas by confining
    // reads from / writes to slot3 to periods where Cron Fi fees are being collected OR when Cron Fi
    // fees are non-zero.
    uint256 feeShiftU3;
    uint256 feeShareU60;
    if (feeEnabled != FALSE) {
      feeShiftU3 = BitPackingLib.unpackFeeShiftS3(slot3);
      feeShareU60 = lpFeeU60 / (1 + 2**feeShiftU3);
    }

    evoMem = ExecVirtualOrdersMem(
      token0TwammRes,
      token1TwammRes,
      lpFeeU60,
      feeShareU60,
      feeShiftU3,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    );
  }

  /// @notice Calculates the TWAMM pool's reserves at the current state (i.e. not considering
  ///         unexecuted virtual orders). The calculation is the difference between the Balancer
  ///         vault token balances and the pools fees, orders and proceeds.
  /// @param _balance0        The Balancer Vault balance of Token 0 for this pool. A U112 value in a
  ///                        U256 container.
  /// @param _balance1        The Balancer Vault balance of Token 1 for this pool. A U112 value in a
  ///                        U256 container.
  /// @return token0TwammRes A U112 value representing the amount of token 0, scaled up to token 0 decimal
  ///                        places, held in this TWAMM pool as of the last virtual order block (LVOB).
  /// @return token1TwammRes A U112 value representing the amount of token 1, scaled up to token 1 decimal
  ///                        places, held in this TWAMM pool as of the last virtual order block (LVOB).
  ///
  ///
  function _calculateReserves(uint256 _balance0, uint256 _balance1)
    private
    view
    returns (uint256 token0TwammRes, uint256 token1TwammRes)
  {
    (uint256 token0Orders, uint256 token1Orders) = BitPackingLib.unpackPairU112(slot1);
    (uint256 token0Proceeds, uint256 token1Proceeds) = BitPackingLib.unpackPairU112(slot2);
    uint256 localSlot4 = slot4;
    (uint256 token0BalancerFees, uint256 token1BalancerFees) = BitPackingLib.unpackPairU96(localSlot4);

    // NOTE: _balance0 and _balance1 should not exceed 2^112 - 1 according to balancer documentation
    //       [https://dev.balancer.fi/deep-dive/guided-tour-of-balancer-vault/episode-2-joins#vault-poolbalances.sol-5]
    //       and / all the values being summed in parenthesis are maximum 2^112 - 1, so we only
    //       need check for underflow on the / subtraction, not overflow on the addition of four uint112
    //       numbers that won't exceed the uint256 they're implicitly placed in by the solidity compiler
    //       in the addition [https://docs.soliditylang.org/en/v0.7.6/types.html#implicit-conversions].
    //       (Because tokenXBalancerFees and tokenXCronFiFees are both uint256, the other addends are
    //       implicitly converted to uint256 for the additions.)
    //
    // NOTE: Optimization - prevent un-necessary read of slot3 by storing whether the Cron-Fi Fees stored
    //       in slot3 are zero (in flag zeroCronFiFees stored in slot4):
    //

    token0TwammRes = _balance0.sub(token0Orders + token0Proceeds + token0BalancerFees);
    token1TwammRes = _balance1.sub(token1Orders + token1Proceeds + token1BalancerFees);

    uint256 zeroCronFiFees = BitPackingLib.unpackBit(localSlot4, S4_OFFSET_ZERO_CRONFI_FEES);
    if (zeroCronFiFees != FALSE) {
      (uint256 token0CronFiFees, uint256 token1CronFiFees) = BitPackingLib.unpackPairU96(slot3);
      token0TwammRes = token0TwammRes.sub(token0CronFiFees);
      token1TwammRes = token1TwammRes.sub(token1CronFiFees);
    }
  }

  /// @notice TODO
  //// TODO
  ///   - #numericalanalysis Understand appropriate BXXX value for real world conditions as well as extrema.
  ///     #safety
  function _calculateProceeds(
    uint256 _scaledProceeds,
    uint256 _startScaledProceeds,
    uint256 _stakedAmount
  ) private pure returns (uint256 proceedsU112) {
    // NOTE: Underflow is REQUIRED here for uint128, hence casts to uint128 and intentionally unchecked subtraction!
    uint128 orderProceeds = uint128(_scaledProceeds) - uint128(_startScaledProceeds);

    // NOTE: Safe math operator is not needed below because product of to uint128 values cannot overflow (stored
    //       _stakedAmount (salesRate) is uint128, but assigned to uint256 upstream for gas efficiency (prefer
    //       uint256 native type).
    proceedsU112 = (orderProceeds * _stakedAmount) >> BXXX;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.6;

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
// solhint-disable-next-line func-visibility
function requireErrCode(bool _condition, uint256 _errorCode) pure {
  if (!_condition) revertErrCode(_errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
// solhint-disable-next-line func-visibility
function revertErrCode(uint256 _errorCode) pure {
  // We're going to dynamically create a revert string based on the error code, with the following format:
  // 'BAL#{errorCode}'
  // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
  //
  // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
  // number (8 to 16 bits) than the individual string characters.
  //
  // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
  // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
  // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
  // solhint-disable-next-line no-inline-assembly
  assembly {
    // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
    // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
    // the '0' character.

    let units := add(mod(_errorCode, 10), 0x30)

    _errorCode := div(_errorCode, 10)
    let tenths := add(mod(_errorCode, 10), 0x30)

    _errorCode := div(_errorCode, 10)
    let hundreds := add(mod(_errorCode, 10), 0x30)

    // With the individual characters, we can now construct the full string. The "CFI#" part is a known constant
    // (0x43464923): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
    // characters to it, each shifted by a multiple of 8.
    // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
    // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
    // array).

    let revertReason := shl(200, add(0x43464923000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

    // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
    // message will have the following layout:
    // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

    // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
    // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
    mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
    // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
    mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
    // The string length is fixed: 7 characters.
    mstore(0x24, 7)
    // Finally, the string itself is stored.
    mstore(0x44, revertReason)

    // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
    // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
    revert(0, 100)
  }
}

library CronErrors {
  // Permissions:
  uint256 internal constant SENDER_NOT_FACTORY = 0;
  uint256 internal constant SENDER_NOT_FACTORY_OWNER = 1;
  uint256 internal constant SENDER_NOT_ADMIN = 2;
  uint256 internal constant SENDER_NOT_ARBITRAGE_PARTNER = 3;
  uint256 internal constant NON_VAULT_CALLER = 4;
  uint256 internal constant SENDER_NOT_PARTNER = 5;
  uint256 internal constant SENDER_NOT_KEEPER = 6;
  uint256 internal constant SENDER_NOT_FEE_ADDRESS = 7;
  uint256 internal constant SENDER_NOT_ORDER_OWNER = 8;
  uint256 internal constant CANNOT_TRANSFER_TO_SELF_OR_NULL = 9;

  // Modifiers:
  uint256 internal constant POOL_PAUSED = 100;

  // Configuration & Parameterization:
  uint256 internal constant INVALID_POOL_TYPE = 200;
  uint256 internal constant UNSUPPORTED_SWAP_KIND = 201;
  uint256 internal constant INVALID_SWAP_TYPE = 202;
  uint256 internal constant INVALID_ARGUMENTS = 203;
  uint256 internal constant INSUFFICIENT_LIQUIDITY = 204;
  uint256 internal constant INVALID_JOIN_TYPE = 205;
  uint256 internal constant INCORRECT_POOL_ID = 206;
  uint256 internal constant INVALID_EXIT_TYPE = 207;
  uint256 internal constant ZERO_SALES_RATE = 208;
  uint256 internal constant COMPLETED_ORDER_WITHDRAWN = 209;
  uint256 internal constant NO_PROCEEDS_TO_WITHDRAW = 210;
  uint256 internal constant COMPLETED_ORDER = 211;
  uint256 internal constant NO_REFUND_AVAILABLE = 212;
  uint256 internal constant TOO_MUCH_TOKEN0_LIQUIDITY = 213;
  uint256 internal constant TOO_MUCH_TOKEN1_LIQUIDITY = 214;
  uint256 internal constant NO_MINT_EVENT_AT_INDEX = 215;
  uint256 internal constant INSUFFICIENT_MINT_EVENT_LP = 216;
  uint256 internal constant LT_TRADE_AMOUNT_TOO_LARGE = 217;
  uint256 internal constant INVALID_TOKEN_SPECIFIED = 218;
  uint256 internal constant SINGLE_ROOK_PARTNER = 219;

  // Orders & Operation:
  uint256 internal constant SALES_RATE_T0_TOO_LARGE = 215;
  uint256 internal constant SALES_RATE_END_T0_TOO_LARGE = 216;
  uint256 internal constant SALES_RATE_T1_TOO_LARGE = 217;
  uint256 internal constant SALES_RATE_END_T1_TOO_LARGE = 218;
  uint256 internal constant DECREMENT_T0_TOO_LARGE = 219;
  uint256 internal constant DECREMENT_T0_END_TOO_LARGE = 220;
  uint256 internal constant DECREMENT_T1_TOO_LARGE = 221;
  uint256 internal constant DECREMENT_T1_END_TOO_LARGE = 222;
  //  uint256 internal constant SALES_RATE_TOO_LARGE = 223; // <-- deprecated
  uint256 internal constant INCREMENT_TOO_LARGE = 224;
  //  uint256 internal constant SCALED_PROCEEDS_TOO_LARGE = 225; // <-- deprecated
  uint256 internal constant PROCEEDS_TOO_LARGE = 226;
  uint256 internal constant ORDERS_UNDERFLOW = 227;
  uint256 internal constant PROCEEDS_OVERFLOW = 228; // Similar to PROCEEDS_TOO_LARGE but for entire staking algo.

  // General:
  uint256 internal constant VALUE_EXCEEDS_CONTAINER_SZ = 300;
  uint256 internal constant OVERFLOW = 301;
  uint256 internal constant UNDERFLOW = 302;
  uint256 internal constant PARAM_ERROR = 303;

  // Factory:
  uint256 internal constant ZERO_TOKEN_ADDRESSES = 400;
  uint256 internal constant IDENTICAL_TOKEN_ADDRESSES = 401;
  uint256 internal constant EXISTING_POOL = 402;
  uint256 internal constant INVALID_FACTORY_OWNER = 403;
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

//
// Structs for reducing gas used in loops and/or addressing Solidity's limited
// stack for variables.
////////////////////////////////////////////////////////////////////////////////

/// @notice Container for executing virtual orders
/// TODO:
///   - #documentation Add member natspec documentation
struct ExecVirtualOrdersMem {
  uint256 token0Reserve;
  uint256 token1Reserve;
  uint256 lpFeeU60;
  uint256 feeShareU60;
  uint256 feeShiftU3;
  uint256 token0BalancerFees;
  uint256 token1BalancerFees;
  uint256 token0CronFiFees;
  uint256 token1CronFiFees;
  uint256 token0Orders;
  uint256 token1Orders;
  uint256 token0Proceeds;
  uint256 token1Proceeds;
}

/// @notice Gas optimization pushing storage variables into memory for loop.
///         (Reduces gas when pool is inactive for > 1 OBI.)
/// TODO:
///   - #documentation Add member natspec documentation
struct LoopMem {
  // Block Numbers:
  uint256 lastVirtualOrderBlock;
  // Order Pool Items:
  uint256 scaledProceeds0;
  uint256 scaledProceeds1;
  uint256 currentSalesRate0;
  uint256 currentSalesRate1;
}

/// @notice TODO
struct PriceOracle {
  uint256 token0; // Cumulative last price token 0
  uint256 token1; // Cumulative last price token 1
}

//
//
// Square-root function for providing initial liquidity
////////////////////////////////////////////////////////////////////////////////
/// TODO:
///   - #documentation Add member natspec documentation
///   - #savegas       Is the PRB implementation better?
library MiscLib {
  // From: https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
  //
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 _y) internal pure returns (uint256 z) {
    if (_y > 3) {
      z = _y;
      uint256 x = _y / 2 + 1;
      while (x < z) {
        z = x;
        x = (_y / x + x) / 2;
      }
    } else if (_y != 0) {
      z = 1;
    }
  }
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

/// @notice Information related to providing liquidity and holding period for a specific
///         address.
/// TODO: can these be packed into one slot together reasonably? (I believe amountLP
///       is not limited to U112 but rather U256 as per ERC20) #savegas
struct MintEvent {
  uint256 timestamp;
  uint256 amountLP;
}

/// @notice Information associated with a virtual order.
/// @member token0To1 The direction of the LT Trade described in this order.
///                   True is Token0 --> Token1
/// @member salesRate is the sales rate of this order in tokens per block.
/// @member scaledProceedsAtSubmission is the scaled proceeds at the time of this
///                                    order submission.
/// @member owner     The address issuing this order. Exclusively able to
///                   cancel and withdraw it.
/// @member orderExpiry is the block in which this order expires.
struct Order {
  bool token0To1;
  uint112 salesRate;
  uint128 scaledProceedsAtSubmission;
  address owner;
  uint256 orderExpiry;
}

/// TODO: update this:
/// @notice  An Order Pool is an abstraction for a pool of long term orders that
///          sells a token at a constant rate to the embedded AMM.  The order
///          pool handles the logic for distributing the proceeds from these
///          sales to the owners of the long term orders through a modified
///          version of the staking algorithm from:
///          https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
///          You can think of this as a staking pool where all long term
///          orders are staked. The pool is paid when virtual long term orders
///          are executed, and each order is paid proportionally by the
///          order's sale rate per block.
/// @member currentSalesRates       Current rate that tokens are being sold (per block) for
///                                 each order pool. Stored in a single 256-bit slot for
///                                 efficiency.
/// @member scaledProceeds          Sum of (salesProceeds_k / salesRate_k) over every period k
///                                 for each order pool. Stored in a single 256-bit slot for
///                                 efficiency.
///                                 TODO: rename to scaledProceeds
///                                 (Each scaled proceed is U128, scaled proceeds 0 is upper
///                                  128-bits.)
/// @member salesRateEndingPerBlock This maps block numbers to the cumulative
///                                 sales rate of orders that expire on that block for each
///                                 order pool. Stored in a single 256-bit slot each for
///                                 efficiency.
/// @dev All struct members are shared values for orderPool0 and orderPool1 in this format if
///      they're U112:
///                         MSB                 224..113              112..1    LSB
///                            < empty | pool 0 value U112 | pool 1 value U112 >
///
///      If they're U128:
///                         MSB         256..129              128..1    LSB
///                            < pool 0 value U128 | pool 1 value U128 >
/// @dev scaledProceeds are always increasing and are expected to overflow. It's the difference
///      between the scaledProceeds at two blocks that determines the proceeds in a particular
///      time-interval. A user's sales rate dividing that amount determines their share of the
///      proceeds (scaledProceeds are normalized to the total sales rate and scaled up for
///      maintaining precision). The subtraction of the two points is also expected to underflow.
///      This implemenation is in Solidity 7* wherein the unchecked block is not present, hence
///      this note.
/// TODO:
///   - #savegas    Revisit the usage patterns for the functions below and optimize
///                 further (can be combined to achieve further savings).
///   - #practices  The methods operating on this struct likely ought to be part of a library
///                 attached to the struct solidity style, a.k.a. "Using" clause.
struct OrderPools {
  uint256 currentSalesRates;
  uint256 scaledProceeds;
  mapping(uint256 => uint256) salesRatesEndingPerBlock;
}

/// @notice Struct containing Virtual Order Management state.
/// @member orderPools TODO
/// @member scaledProceedsAtBlock A mapping from Ethereum block number to
///                               a uint256 container that holds the
///                               scaledProceeds for each order pool. Saves
///                               significant gas on sstore/sload ops
///                               merging these values here and storing them
///                               instead of one slot for each in each order
///                               pool.  (Each scaled proceed is U128, scaled
///                               proceeds 0 is upper 128-bits.)
/// @member orderMap A mapping from order id to orders.
/// @member lastVirtualOrderBlock The Ethereum block number before which
///                               the last virtual orders were executed.
/// @member nextOrderId A uint256 container counting order ids. The value is
///                     the next order id to be issued when a user places a
///                     virtual order.
struct VirtualOrders {
  OrderPools orderPools;
  mapping(uint256 => uint256) scaledProceedsAtBlock;
  mapping(uint256 => Order) orderMap;
  uint256 lastVirtualOrderBlock;
  uint256 nextOrderId;
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

import { Math } from "./balancer-core-v2/lib/math/Math.sol";

import { BitPackingLib } from "./BitPacking.sol";
import { BP, DENOMINATOR_DU1_18, BXXX, MAX_U112 } from "./Constants.sol";
import { requireErrCode, CronErrors } from "./Errors.sol";
import { ExecVirtualOrdersMem, LoopMem } from "./Misc.sol";
import { VirtualOrders } from "./VirtualOrderStructs.sol";

/// @notice This library handles executes virtual orders and updates virtual order state.
library VirtualOrderLib {
  using Math for uint256;

  /// @notice Execute virtual orders to the specified block from last virtual order block.
  /// TODO
  ///   - #practices Natspec documentation
  function executeVirtualOrdersToBlock(
    VirtualOrders storage _self,
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _orderBlockInterval,
    uint256 _blockNumber,
    uint256 _poolFeeLTBP
  ) internal {
    // Less gas to do the loop with memory than storage; update storage at end.
    (LoopMem memory loopMem, uint256 expiryBlock) = _getLoopMem(_self, _orderBlockInterval);

    // Iterate through blocks eligible for order expiries, moving state forward
    while (expiryBlock < _blockNumber) {
      executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, _poolFeeLTBP);

      // Handle orders expiring at end of interval
      _decrementSalesRates(_self, expiryBlock, loopMem);
      _updateScaledProceeds(_self, loopMem, expiryBlock);

      expiryBlock += _orderBlockInterval;
    }

    // Finally, move state to current block if necessary
    if (loopMem.lastVirtualOrderBlock != _blockNumber) {
      expiryBlock = _blockNumber;
      executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, _poolFeeLTBP);

      // Handle orders expiring at end of interval
      _decrementSalesRates(_self, expiryBlock, loopMem);
      _updateScaledProceeds(_self, loopMem, expiryBlock);
    }

    _self.lastVirtualOrderBlock = loopMem.lastVirtualOrderBlock;
    _self.orderPools.currentSalesRates = BitPackingLib.packPairU112(
      0,
      loopMem.currentSalesRate0,
      loopMem.currentSalesRate1
    );
    _self.orderPools.scaledProceeds = BitPackingLib.packPairU128(loopMem.scaledProceeds0, loopMem.scaledProceeds1);
  }

  ///@notice Read only (view function) version of executes all virtual orders until current block is reached.
  /// TODO:
  ///   - #practices Natspec documentation
  function executeVirtualOrdersView(
    VirtualOrders storage _self,
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _orderBlockInterval,
    uint256 _poolFeeLTBP
  ) internal view {
    (LoopMem memory loopMem, uint256 expiryBlock) = _getLoopMem(_self, _orderBlockInterval);

    while (expiryBlock < block.number) {
      executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, _poolFeeLTBP);

      // Handle orders expiring at end of interval
      _decrementSalesRates(_self, expiryBlock, loopMem);

      expiryBlock += _orderBlockInterval;
    }

    if (_self.lastVirtualOrderBlock != block.number) {
      expiryBlock = block.number;
      executeVirtualTradesAndOrderExpiries(_evoMem, expiryBlock, loopMem, _poolFeeLTBP);
    }
  }

  /// @notice Executes all virtual orders between current lastVirtualOrderBlock and blockNumber
  ///         also handles orders that expire at end of final block. This assumes that no orders
  ///         expire inside the given interval.
  /// TODO:
  ///   - #practices Natspec documentation
  ///   - #safety  Need to determine if overflow / underflow checking operations required here.
  ///   - #numericalanalysis Understand appropriate BXXX value for real world conditions as well as extrema.
  ///     #safety
  ///   - #savegas (tradeoff lp fee growth likely) Sum gross fees but don't compute lpFee / balancerFee
  ///              and add them back in until the loop is done.  Will effect trade / liquidity, but
  ///              reduce gas cost.
  ///   - #savegas Most of these eVO loops are for the same number of blocks; if so code path for
  ///              typical code path with values reused (since tokenIn stays the same), other codepath
  ///              when increment changes. (i.e. store last increment, if same as this one, dont
  ///              update fee calculations.)
  ///   - #savegas To add cfFee:  make lpFee calc share based (i.e. 2/6). Then can calc cfFee >> 1 and
  ///              subtract sum of both to get balancer fee.  <-- optimizing for limited stack here & gas
  function executeVirtualTradesAndOrderExpiries(
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _expiryBlock,
    LoopMem memory _loopMem,
    uint256 _poolFeeLTBP
  ) internal pure {
    // Handle amount sold from virtual trades and related fees
    uint256 blockNumberIncrement = _expiryBlock - _loopMem.lastVirtualOrderBlock;

    uint256 currentSalesRate0 = _loopMem.currentSalesRate0; // #savegas & space
    uint256 currentSalesRate1 = _loopMem.currentSalesRate1; // #savegas & space

    uint256 token0In = currentSalesRate0 * blockNumberIncrement;
    uint256 grossFeeT0 = (token0In.mul(_poolFeeLTBP)).divUp(BP);

    uint256 token1In = currentSalesRate1 * blockNumberIncrement;
    uint256 grossFeeT1 = (token1In.mul(_poolFeeLTBP)).divUp(BP);

    (uint256 lpFeeT0, uint256 lpFeeT1) = updateFees(_evoMem, grossFeeT0, grossFeeT1);

    // Update balances from sales
    (uint256 token0Out, uint256 token1Out) = computeVirtualBalances(
      _evoMem,
      token0In - grossFeeT0,
      token1In - grossFeeT1
    );

    // Update order and proceeds accounting:
    // NOTE: The orders are summed b/c at the end of all iterations, the sum gets subtracted from the
    //       pools current order amount.
    //
    _evoMem.token0Orders += token0In;
    _evoMem.token1Orders += token1In;
    _evoMem.token0Proceeds += token0Out;
    _evoMem.token1Proceeds += token1Out;

    // Update balances reserves including lp fees
    _evoMem.token0Reserve += lpFeeT0;
    _evoMem.token1Reserve += lpFeeT1;

    // Distribute proceeds to pools:
    if (currentSalesRate0 != 0) {
      // Inlining distribute payment for move to memory
      // TODO: May need to check that token1Out does not exceed MAX U128 (would result in
      //       two overflows, breaking RF). Alternately link to analytical proof.
      // Note: Overflow required here. Intentionally unchecked.
      _loopMem.scaledProceeds0 += uint128((token1Out << BXXX) / currentSalesRate0);
    }
    if (currentSalesRate1 != 0) {
      // Inlining distribute payment for move to memory
      // TODO: May need to check that token1Out does not exceed MAX U128 (would result in
      //       two overflows, breaking RF). Alternately link to analytical proof.
      // Note: Overflow required here. Intentionally unchecked.
      _loopMem.scaledProceeds1 += uint128((token0Out << BXXX) / currentSalesRate1);
    }

    _loopMem.lastVirtualOrderBlock = _expiryBlock;
  }

  /// @notice Computes the result of virtual trades by the token pools
  /// TODO:
  ///   - #practices Natspec documentation
  ///   - #safety    Overflow / underflow checking or safe operations required here.
  ///   - #savegas   Try passing in reserves and returning new reserves instead of
  ///                using mem struct?
  ///   - #safety    Understand if subtraction results can be negative here (under what
  ///                conditions if any).
  ///   - divDown is default behavior (for /) and we already check for div by zero,
  ///     consider getting rid of the call and using the / op.
  ///
  function computeVirtualBalances(
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _token0In,
    uint256 _token1In
  ) internal pure returns (uint256 token0Out, uint256 token1Out) {
    // TODO: are zero assignments needed? #savegas
    if (_token0In == 0 && _token1In == 0) {
      // If no orders selling to pool, NO-OP:
    } else {
      uint256 token0Reserve = _evoMem.token0Reserve; // #savegas #savesize
      uint256 token1Reserve = _evoMem.token1Reserve; // Passed in though ExecVirtualOrdersMem b/c stack too deep.

      if (_token0In == 0) {
        // For single pool selling, use CPAMM formula:
        token1Reserve = token1Reserve.add(_token1In);
        token0Out = (token0Reserve.mul(_token1In)).divDown(token1Reserve);
        token0Reserve = token0Reserve.sub(token0Out);
      } else if (_token1In == 0) {
        // For single pool selling, use CPAMM formula:
        token0Reserve = token0Reserve.add(_token0In);
        token1Out = (token1Reserve.mul(_token0In)).divDown(token0Reserve);
        token1Reserve = token1Reserve.sub(token1Out);
      } else {
        // When both pools sell, apply the TWAMM formula in the form of the FRAX Approximation
        uint256 sum0 = token0Reserve.add(_token0In);
        uint256 sum1 = token1Reserve.add(_token1In);

        // Note: purposely using standard rounding (divDown = /) here to reduce operating error.
        uint256 ammEndToken1 = (token0Reserve.mul(sum1)).divDown(sum0);
        token0Reserve = (token0Reserve.mul(token1Reserve)).divDown(ammEndToken1);
        token1Reserve = ammEndToken1; // Updating here, otherwise would corrupt "k" value in line above.

        token0Out = sum0.sub(token0Reserve);
        token1Out = sum1.sub(ammEndToken1);
      }

      _evoMem.token0Reserve = token0Reserve;
      _evoMem.token1Reserve = token1Reserve;
    }
  }

  /// @notice TODO
  function updateFees(
    ExecVirtualOrdersMem memory _evoMem,
    uint256 _grossFeeT0,
    uint256 _grossFeeT1
  ) internal pure returns (uint256 lpFeeT0, uint256 lpFeeT1) {
    uint256 feeShareU60 = _evoMem.feeShareU60; // #savegas #savesize

    if (feeShareU60 == 0) {
      uint256 lpFeeU60 = _evoMem.lpFeeU60; // #savegas #savesize
      lpFeeT0 = (_grossFeeT0.mul(lpFeeU60)).divUp(DENOMINATOR_DU1_18);
      lpFeeT1 = (_grossFeeT1.mul(lpFeeU60)).divUp(DENOMINATOR_DU1_18);

      // Accumulate fees for balancer
      _evoMem.token0BalancerFees += _grossFeeT0 - lpFeeT0;
      _evoMem.token1BalancerFees += _grossFeeT1 - lpFeeT1;
    } else {
      // Note: When the fee address is set, Cron Fi splits the fees with the LPs
      //       and balancer.  The feeShareU60 value is 1/3 the fee remaining from
      //       considering the Balancer Protocol fee. This value is then divided
      //       with 1 part going to CronFi and 2 parts to the LPs.
      //       For example if the Balancer Protocol fee is half of all fees collected,
      //       then 1/6 of the collected fee goes to Cron Fi and 1/3 of the fees
      //       collected go to the LPs.
      uint256 feeShareT0 = (_grossFeeT0.mul(feeShareU60)).divUp(DENOMINATOR_DU1_18);
      uint256 feeShareT1 = (_grossFeeT1.mul(feeShareU60)).divUp(DENOMINATOR_DU1_18);

      // LPs get 2^_evoMemFeeShift_U4 of the fee shares, Cron Fi gets 1.
      uint256 feeShiftU3 = _evoMem.feeShiftU3; // #savegas #savesize
      lpFeeT0 = feeShareT0 << feeShiftU3;
      lpFeeT1 = feeShareT1 << feeShiftU3;

      // Accumulate fees for balancer
      _evoMem.token0BalancerFees += _grossFeeT0 - lpFeeT0 - feeShareT0;
      _evoMem.token1BalancerFees += _grossFeeT1 - lpFeeT1 - feeShareT1;

      // Accumulate fees for CronFi
      _evoMem.token0CronFiFees += feeShareT0;
      _evoMem.token1CronFiFees += feeShareT1;
    }
  }

  /// @notice TODO
  function _updateScaledProceeds(
    VirtualOrders storage _self,
    LoopMem memory _loopMem,
    uint256 _expiryBlock
  ) private {
    _self.scaledProceedsAtBlock[_expiryBlock] = BitPackingLib.packPairU128(
      _loopMem.scaledProceeds0,
      _loopMem.scaledProceeds1
    );
  }

  /// @notice TODO
  function _getLoopMem(VirtualOrders storage _self, uint256 _orderBlockInterval)
    private
    view
    returns (LoopMem memory loopMem, uint256 expiryBlock)
  {
    uint256 lvob = _self.lastVirtualOrderBlock; // #savegas
    expiryBlock = lvob - (lvob % _orderBlockInterval) + _orderBlockInterval;
    loopMem.lastVirtualOrderBlock = lvob;

    (loopMem.currentSalesRate0, loopMem.currentSalesRate1) = BitPackingLib.unpackPairU112(
      _self.orderPools.currentSalesRates
    );

    (loopMem.scaledProceeds0, loopMem.scaledProceeds1) = BitPackingLib.unpackPairU128(_self.orderPools.scaledProceeds);
  }

  function _decrementSalesRates(
    VirtualOrders storage _self,
    uint256 _expiryBlock,
    LoopMem memory _loopMem
  ) private view {
    (uint256 salesRateEndingPerBlock0, uint256 salesRateEndingPerBlock1) = BitPackingLib.unpackPairU112(
      _self.orderPools.salesRatesEndingPerBlock[_expiryBlock]
    );

    if (salesRateEndingPerBlock0 > 0) {
      requireErrCode(_loopMem.currentSalesRate0 >= salesRateEndingPerBlock0, CronErrors.UNDERFLOW);
      _loopMem.currentSalesRate0 -= salesRateEndingPerBlock0;
    }
    if (salesRateEndingPerBlock1 > 0) {
      requireErrCode(_loopMem.currentSalesRate1 >= salesRateEndingPerBlock1, CronErrors.UNDERFLOW);
      _loopMem.currentSalesRate1 -= salesRateEndingPerBlock1;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./IAuthentication.sol";

/**
 * @dev Building block for performing access control on external functions.
 *
 * This contract is used via the `authenticate` modifier (or the `_authenticateCaller` function), which can be applied
 * to external functions to only make them callable by authorized accounts.
 *
 * Derived contracts must implement the `_canPerform` function, which holds the actual access control logic.
 */
abstract contract Authentication is IAuthentication {
    bytes32 private immutable _actionIdDisambiguator;

    /**
     * @dev The main purpose of the `actionIdDisambiguator` is to prevent accidental function selector collisions in
     * multi contract systems.
     *
     * There are two main uses for it:
     *  - if the contract is a singleton, any unique identifier can be used to make the associated action identifiers
     *    unique. The contract's own address is a good option.
     *  - if the contract belongs to a family that shares action identifiers for the same functions, an identifier
     *    shared by the entire family (and no other contract) should be used instead.
     */
    constructor(bytes32 actionIdDisambiguator) {
        _actionIdDisambiguator = actionIdDisambiguator;
    }

    /**
     * @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
     */
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    /**
     * @dev Reverts unless the caller is allowed to call the entry point function.
     */
    function _authenticateCaller() internal view {
        bytes32 actionId = getActionId(msg.sig);
        _require(_canPerform(actionId, msg.sender), Errors.SENDER_NOT_ALLOWED);
    }

    function getActionId(bytes4 selector) public view override returns (bytes32) {
        // Each external function is dynamically assigned an action identifier as the hash of the disambiguator and the
        // function selector. Disambiguation is necessary to avoid potential collisions in the function selectors of
        // multiple contracts.
        return keccak256(abi.encodePacked(_actionIdDisambiguator, selector));
    }

    function _canPerform(bytes32 actionId, address user) internal view virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../openzeppelin/IERC20.sol";

import "./BalancerErrors.sol";

import "../../vault/interfaces/IAsset.sol";

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IAsset[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library
 */
library Math {
    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        // Silence state mutability warning without generating bytecode.
        // See https://github.com/ethereum/solidity/issues/10090#issuecomment-741789128 and
        // https://github.com/ethereum/solidity/issues/2691
        this;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce bytecode size.
// Modifier code is inlined by the compiler, which causes its code to appear multiple times in the codebase. By using
// private functions, we achieve the same end result with slightly higher runtime gas costs, but reduced bytecode size.

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

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
        _enterNonReentrant();
        _;
        _exitNonReentrant();
    }

    function _enterNonReentrant() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        _require(_status != _ENTERED, Errors.REENTRANCY);

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _exitNonReentrant() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

import "./IERC20.sol";

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
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     *
     * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
     */
    function _callOptionalReturn(address token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        (bool success, bytes memory returndata) = token.call(data);

        // If the low-level call didn't succeed we return whatever was returned from it.
        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
        _require(returndata.length == 0 || abi.decode(returndata, (bool)), Errors.SAFE_ERC20_CALL_FAILED);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../lib/math/Math.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/IERC20Permit.sol";
import "../lib/openzeppelin/EIP712.sol";

/**
 * @title Highly opinionated token implementation
 * @author Balancer Labs
 * @dev
 * - Includes functions to increase and decrease allowance as a workaround
 *   for the well-known issue with `approve`:
 *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * - Allows for 'infinite allowance', where an allowance of 0xff..ff is not
 *   decreased by calls to transferFrom
 * - Lets a token holder use `transferFrom` to send their own tokens,
 *   without first setting allowance
 * - Emits 'Approval' events whenever allowance is changed by `transferFrom`
 */
contract BalancerPoolToken is IERC20, IERC20Permit, EIP712 {
    using Math for uint256;

    // State variables

    uint8 private constant _DECIMALS = 18;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPE_HASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    // Function declarations

    constructor(string memory tokenName, string memory tokenSymbol) EIP712(tokenName, "1") {
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    // External functions

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balance[account];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _setAllowance(msg.sender, spender, amount);

        return true;
    }

    function increaseApproval(address spender, uint256 amount) external returns (bool) {
        _setAllowance(msg.sender, spender, _allowance[msg.sender][spender].add(amount));

        return true;
    }

    function decreaseApproval(address spender, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowance[msg.sender][spender];

        if (amount >= currentAllowance) {
            _setAllowance(msg.sender, spender, 0);
        } else {
            _setAllowance(msg.sender, spender, currentAllowance.sub(amount));
        }

        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _move(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowance[sender][msg.sender];
        _require(msg.sender == sender || currentAllowance >= amount, Errors.INSUFFICIENT_ALLOWANCE);

        _move(sender, recipient, amount);

        if (msg.sender != sender && currentAllowance != uint256(-1)) {
            // Because of the previous require, we know that if msg.sender != sender then currentAllowance >= amount
            _setAllowance(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        _require(block.timestamp <= deadline, Errors.EXPIRED_PERMIT);

        uint256 nonce = _nonces[owner];

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPE_HASH, owner, spender, value, nonce, deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ecrecover(hash, v, r, s);
        _require((signer != address(0)) && (signer == owner), Errors.INVALID_SIGNATURE);

        _nonces[owner] = nonce + 1;
        _setAllowance(owner, spender, value);
    }

    // Public functions

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner];
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    // Internal functions

    function _mintPoolTokens(address recipient, uint256 amount) internal {
        _balance[recipient] = _balance[recipient].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), recipient, amount);
    }

    function _burnPoolTokens(address sender, uint256 amount) internal {
        uint256 currentBalance = _balance[sender];
        _require(currentBalance >= amount, Errors.INSUFFICIENT_BALANCE);

        _balance[sender] = currentBalance - amount;
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(sender, address(0), amount);
    }

    function _move(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 currentBalance = _balance[sender];
        _require(currentBalance >= amount, Errors.INSUFFICIENT_BALANCE);
        // Prohibit transfers to the zero address to avoid confusion with the
        // Transfer event emitted by `_burnPoolTokens`
        _require(recipient != address(0), Errors.ERC20_TRANSFER_TO_ZERO_ADDRESS);

        _balance[sender] = currentBalance - amount;
        _balance[recipient] = _balance[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    // Private functions

    function _setAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin/IERC20.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/helpers/Authentication.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IAuthorizer.sol";

/**
 * @dev This an auxiliary contract to the Vault, deployed by it during construction. It offloads some of the tasks the
 * Vault performs to reduce its overall bytecode size.
 *
 * The current values for all protocol fee percentages are stored here, and any tokens charged as protocol fees are
 * sent to this contract, where they may be withdrawn by authorized entities. All authorization tasks are delegated
 * to the Vault's own authorizer.
 */
contract ProtocolFeesCollector is Authentication, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Absolute maximum fee percentages (1e18 = 100%, 1e16 = 1%).
    uint256 private constant _MAX_PROTOCOL_SWAP_FEE_PERCENTAGE = 50e16; // 50%
    uint256 private constant _MAX_PROTOCOL_FLASH_LOAN_FEE_PERCENTAGE = 1e16; // 1%

    IVault public immutable vault;

    // All fee percentages are 18-decimal fixed point numbers.

    // The swap fee is charged whenever a swap occurs, as a percentage of the fee charged by the Pool. These are not
    // actually charged on each individual swap: the `Vault` relies on the Pools being honest and reporting fees due
    // when users join and exit them.
    uint256 private _swapFeePercentage;

    // The flash loan fee is charged whenever a flash loan occurs, as a percentage of the tokens lent.
    uint256 private _flashLoanFeePercentage;

    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    constructor(IVault _vault)
        // The ProtocolFeesCollector is a singleton, so it simply uses its own address to disambiguate action
        // identifiers.
        Authentication(bytes32(uint256(address(this))))
    {
        vault = _vault;
    }

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external nonReentrant authenticate {
        InputHelpers.ensureInputLengthMatch(tokens.length, amounts.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];
            token.safeTransfer(recipient, amount);
        }
    }

    // authenticate disabled for testing close to production
    // function setSwapFeePercentage(uint256 newSwapFeePercentage) external authenticate {
    function setSwapFeePercentage(uint256 newSwapFeePercentage) external {
        _require(newSwapFeePercentage <= _MAX_PROTOCOL_SWAP_FEE_PERCENTAGE, Errors.SWAP_FEE_PERCENTAGE_TOO_HIGH);
        _swapFeePercentage = newSwapFeePercentage;
        emit SwapFeePercentageChanged(newSwapFeePercentage);
    }

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external authenticate {
        _require(
            newFlashLoanFeePercentage <= _MAX_PROTOCOL_FLASH_LOAN_FEE_PERCENTAGE,
            Errors.FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH
        );
        _flashLoanFeePercentage = newFlashLoanFeePercentage;
        emit FlashLoanFeePercentageChanged(newFlashLoanFeePercentage);
    }

    function getSwapFeePercentage() external view returns (uint256) {
        return _swapFeePercentage;
    }

    function getFlashLoanFeePercentage() external view returns (uint256) {
        return _flashLoanFeePercentage;
    }

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts) {
        feeAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ++i) {
            feeAmounts[i] = tokens[i].balanceOf(address(this));
        }
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        return _getAuthorizer().canPerform(actionId, account, address(this));
    }

    function _getAuthorizer() internal view returns (IAuthorizer) {
        return vault.getAuthorizer();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IVault.sol";
import "./IPoolSwapStructs.sol";

/**
 * @dev Interface for adding and removing liquidity that all Pool contracts should implement. Note that this is not
 * the complete Pool contract interface, as it is missing the swap hooks. Pool contracts should also inherit from
 * either IGeneralPool or IMinimalSwapInfoPool
 */
interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `currentBalances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `currentBalances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "../../lib/openzeppelin/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

/**
 * @dev Pool contracts with the MinimalSwapInfo or TwoToken specialization settings should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will grant
 * to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IMinimalSwapInfoPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/openzeppelin/IERC20.sol";

import "./IVault.sol";

interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "../../lib/openzeppelin/IERC20.sol";

import "./IWETH.sol";
import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";
import "../ProtocolFeesCollector.sol";

import "../../lib/helpers/ISignaturesValidator.sol";
import "../../lib/helpers/ITemporarilyPausable.sol";

pragma solidity ^0.7.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (ProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/IERC20.sol";

/**
 * @dev Interface for the WETH token contract used internally for wrapping and unwrapping, to support
 * sending and receiving ETH in joins, swaps, and internal balance deposits and withdrawals.
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

/// @notice Interface for managing list of addresses permitted to perform preferred rate
///         arbitrage swaps on Cron-Fi TWAMM V1.0.
///
interface IArbitrageurList {
  /// @param sender is the address that called the function changing list owner permissions.
  /// @param listOwner is the address to change list owner permissions on.
  /// @param permission is true if the address specified in listOwner is granted list owner
  ///        permissions. Is false otherwise.
  ///
  event ListOwnerPermissions(address indexed sender, address indexed listOwner, bool indexed permission);

  /// @param sender is the address that called the function changing arbitrageur permissions.
  /// @param arbitrageurs is a list of addresses to change arbitrage permissions on.
  /// @param permission is true if the addresses specified in arbitrageurs is granted
  ///        arbitrage permissions. Is false otherwise.
  ///
  event ArbitrageurPermissions(address indexed sender, address[] arbitrageurs, bool indexed permission);

  /// @param sender is the address that called the function changing the next list address.
  /// @param nextListAddress is the address the return value of the nextList function is set to.
  ///
  event NextList(address indexed sender, address indexed nextListAddress);

  /// @notice Returns true if the provide address is permitted the preferred
  ///         arbitrage rate in the partner swap method of a Cron-Fi TWAMM pool.
  ///         Returns false otherwise.
  /// @param _address the address to check for arbitrage rate permissions.
  ///
  function isArbitrageur(address _address) external returns (bool);

  /// @notice Returns the address of the next contract implementing the next list of arbitrageurs.
  ///         If the return value is the NULL address, address(0), then the TWAMM contract's update
  ///         list method will keep the existing address it is storing to check for arbitrage permissions.
  ///
  function nextList() external returns (address);
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

interface ICronV1PoolFactory {
  // Events
  event TWAMMPoolCreated(address indexed pool, address indexed token0, address indexed token1, uint256 poolType);

  // Functions
  function create(
    address _token0,
    address _token1,
    string memory _name,
    string memory _symbol,
    uint256 _poolType,
    address _pauser
  ) external returns (address);

  function setOwner(address _owner) external;

  function owner() external view returns (address);

  function getPool(
    address _token0,
    address _token1,
    uint8 _poolType
  ) external view returns (address pool);
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

abstract contract Rook {
  function nextLinkedWhitelist() public virtual returns (address);

  //  function isWhitelistedKeeper(address keeper) public view virtual returns (bool);

  // solhint-disable-next-line
  function getKeeperWhitelistPosition_pab(address keeper) public view virtual returns (uint256);
}