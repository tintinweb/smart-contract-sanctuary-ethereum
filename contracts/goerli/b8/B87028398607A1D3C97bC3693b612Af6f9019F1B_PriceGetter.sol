// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IPool.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "./libraries/TickMath.sol";
import "./libraries/SwapMath.sol";
import "./libraries/FixedPoint128.sol";
import "./libraries/LiquidityMath.sol";
import "./libraries/BitMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/LowGasSafeMath.sol";

contract PriceGetter {
  using LowGasSafeMath for uint256;
  using LowGasSafeMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  IUniswapV3Factory public factory;

  constructor(address _factory) {
    factory = IUniswapV3Factory(_factory);
  }

  function getPrice(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint160 sqrtPriceLimitX96,
    uint24 fee
  ) public view returns (uint256 amountOut) {
    bool zeroForOne = tokenIn < tokenOut;

    IPool pool = IPool(factory.getPool(tokenIn, tokenOut, fee));

    (int256 amount0, int256 amount1) = getSwapAmounts(
      pool,
      zeroForOne,
      amountIn.toInt256(),
      sqrtPriceLimitX96 == 0
        ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
        : sqrtPriceLimitX96
    );

    return uint256(-(zeroForOne ? amount1 : amount0));
  }

  function getSwapAmounts(
    IPool pool,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96
  ) internal view returns (int256 amount0, int256 amount1) {
    Slot0 memory slot0Start = pool.slot0();
    SwapCache memory cache = SwapCache({
      liquidityStart: pool.liquidity(),
      blockTimestamp: uint32(block.timestamp),
      feeProtocol: zeroForOne ? (slot0Start.feeProtocol % 16) : (slot0Start.feeProtocol >> 4),
      secondsPerLiquidityCumulativeX128: 0,
      tickCumulative: 0,
      computedLatestObservation: false
    });

    bool exactInput = amountSpecified > 0;

    SwapState memory state = SwapState({
      amountSpecifiedRemaining: amountSpecified,
      amountCalculated: 0,
      sqrtPriceX96: slot0Start.sqrtPriceX96,
      tick: slot0Start.tick,
      feeGrowthGlobalX128: zeroForOne ? pool.feeGrowthGlobal0X128() : pool.feeGrowthGlobal1X128(),
      protocolFee: 0,
      liquidity: cache.liquidityStart
    });

    // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
    while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
      StepComputations memory step;

      step.sqrtPriceStartX96 = state.sqrtPriceX96;

      (step.tickNext, step.initialized) = nextInitializedTickWithinOneWord(
        pool,
        state.tick,
        pool.tickSpacing(),
        zeroForOne
      );

      // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
      if (step.tickNext < TickMath.MIN_TICK) {
        step.tickNext = TickMath.MIN_TICK;
      } else if (step.tickNext > TickMath.MAX_TICK) {
        step.tickNext = TickMath.MAX_TICK;
      }

      // get the price for the next tick
      step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

      // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
      (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath
        .computeSwapStep(
          state.sqrtPriceX96,
          (
            zeroForOne
              ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
              : step.sqrtPriceNextX96 > sqrtPriceLimitX96
          )
            ? sqrtPriceLimitX96
            : step.sqrtPriceNextX96,
          state.liquidity,
          state.amountSpecifiedRemaining,
          pool.fee()
        );

      if (exactInput) {
        state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
        state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
      } else {
        state.amountSpecifiedRemaining += step.amountOut.toInt256();
        state.amountCalculated = state.amountCalculated.add(
          (step.amountIn + step.feeAmount).toInt256()
        );
      }

      // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
      if (cache.feeProtocol > 0) {
        uint256 delta = step.feeAmount / cache.feeProtocol;
        step.feeAmount -= delta;
        state.protocolFee += uint128(delta);
      }

      // update global fee tracker
      if (state.liquidity > 0)
        state.feeGrowthGlobalX128 += FullMath.mulDiv(
          step.feeAmount,
          FixedPoint128.Q128,
          state.liquidity
        );

      // shift tick if we reached the next price
      if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
        // if the tick is initialized, run the tick transition
        if (step.initialized) {
          // check for the placeholder value, which we replace with the actual value the first time the swap
          // crosses an initialized tick
          if (!cache.computedLatestObservation) {
            (cache.tickCumulative, cache.secondsPerLiquidityCumulativeX128) = observeSingle(
              pool,
              cache.blockTimestamp,
              0,
              slot0Start.tick,
              slot0Start.observationIndex,
              cache.liquidityStart,
              slot0Start.observationCardinality
            );
            cache.computedLatestObservation = true;
          }
          int128 liquidityNet = pool.ticks(step.tickNext).liquidityNet;          // if we're moving leftward, we interpret liquidityNet as the opposite sign
          // safe because liquidityNet cannot be type(int128).min
          if (zeroForOne) liquidityNet = -liquidityNet;

          state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
        }

        state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
      } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
        // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
        state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
      }
    }

    (amount0, amount1) = zeroForOne == exactInput
      ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
      : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
  }

  function nextInitializedTickWithinOneWord(
    IPool pool,
    int24 tick,
    int24 tickSpacing,
    bool lte
  ) internal view returns (int24 next, bool initialized) {
    int24 compressed = tick / tickSpacing;
    if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

    if (lte) {
      (int16 wordPos, uint8 bitPos) = position(compressed);
      // all the 1s at or to the right of the current bitPos
      uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
      uint256 masked = pool.tickBitmap(wordPos) & mask;

      // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
      initialized = masked != 0;
      // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
      next = initialized
        ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
        : (compressed - int24(bitPos)) * tickSpacing;
    } else {
      // start from the word of the next tick, since the current tick state doesn't matter
      (int16 wordPos, uint8 bitPos) = position(compressed + 1);
      // all the 1s at or to the left of the bitPos
      uint256 mask = ~((1 << bitPos) - 1);
      uint256 masked = pool.tickBitmap(wordPos) & mask;

      // if there are no initialized ticks to the left of the current tick, return leftmost in the word
      initialized = masked != 0;
      // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
      next = initialized
        ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
        : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
    }
  }

  function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
    wordPos = int16(tick >> 8);
    bitPos = uint8(tick % 256);
  }

  function observeSingle(
    IPool pool,
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint128 liquidity,
    uint16 cardinality
  ) internal view returns (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) {
    if (secondsAgo == 0) {
      Observation memory last = pool.observations(index);
      if (last.blockTimestamp != time) last = transform(last, time, tick, liquidity);
      return (last.tickCumulative, last.secondsPerLiquidityCumulativeX128);
    }

    uint32 target = time - secondsAgo;

    (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(
      pool,
      time,
      target,
      tick,
      index,
      liquidity,
      cardinality
    );

    if (target == beforeOrAt.blockTimestamp) {
      // we're at the left boundary
      return (beforeOrAt.tickCumulative, beforeOrAt.secondsPerLiquidityCumulativeX128);
    } else if (target == atOrAfter.blockTimestamp) {
      // we're at the right boundary
      return (atOrAfter.tickCumulative, atOrAfter.secondsPerLiquidityCumulativeX128);
    } else {
      // we're in the middle
      uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
      uint32 targetDelta = target - beforeOrAt.blockTimestamp;
      return (
        beforeOrAt.tickCumulative +
          ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / observationTimeDelta) *
          targetDelta,
        beforeOrAt.secondsPerLiquidityCumulativeX128 +
          uint160(
            (uint256(
              atOrAfter.secondsPerLiquidityCumulativeX128 -
                beforeOrAt.secondsPerLiquidityCumulativeX128
            ) * targetDelta) / observationTimeDelta
          )
      );
    }
  }

  function getSurroundingObservations(
    IPool pool,
    uint32 time,
    uint32 target,
    int24 tick,
    uint16 index,
    uint128 liquidity,
    uint16 cardinality
  ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    // optimistically set before to the newest observation
    beforeOrAt = pool.observations(index);

    // if the target is chronologically at or after the newest observation, we can early return
    if (lte(time, beforeOrAt.blockTimestamp, target)) {
      if (beforeOrAt.blockTimestamp == target) {
        // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
        return (beforeOrAt, atOrAfter);
      } else {
        // otherwise, we need to transform
        return (beforeOrAt, transform(beforeOrAt, target, tick, liquidity));
      }
    }

    // now, set before to the oldest observation
    beforeOrAt = pool.observations((index + 1) % cardinality);
    if (!beforeOrAt.initialized) beforeOrAt = pool.observations(0);

    // ensure that the target is chronologically at or after the oldest observation
    require(lte(time, beforeOrAt.blockTimestamp, target), "OLD");

    // if we've reached this point, we have to binary search
    return binarySearch(pool, time, target, index, cardinality);
  }

  function binarySearch(
    IPool pool,
    uint32 time,
    uint32 target,
    uint16 index,
    uint16 cardinality
  ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    uint256 l = (index + 1) % cardinality; // oldest observation
    uint256 r = l + cardinality - 1; // newest observation
    uint256 i;
    while (true) {
      i = (l + r) / 2;

      beforeOrAt = pool.observations(uint16(i % cardinality));

      // we've landed on an uninitialized tick, keep searching higher (more recently)
      if (!beforeOrAt.initialized) {
        l = i + 1;
        continue;
      }

      atOrAfter = pool.observations(uint16((i + 1) % cardinality));

      bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

      // check if we've found the answer!
      if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

      if (!targetAtOrAfter) r = i - 1;
      else l = i + 1;
    }
  }

  function lte(
    uint32 time,
    uint32 a,
    uint32 b
  ) private pure returns (bool) {
    // if there hasn't been overflow, no need to adjust
    if (a <= time && b <= time) return a <= b;

    uint256 aAdjusted = a > time ? a : a + 2**32;
    uint256 bAdjusted = b > time ? b : b + 2**32;

    return aAdjusted <= bAdjusted;
  }

  function transform(
    Observation memory last,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity
  ) private pure returns (Observation memory) {
    uint32 delta = blockTimestamp - last.blockTimestamp;
    return
      Observation({
        blockTimestamp: blockTimestamp,
        tickCumulative: last.tickCumulative + int56(tick) * delta,
        secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
          ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
        initialized: true
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

struct Info {
  // the total position liquidity that references this tick
  uint128 liquidityGross;
  // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
  int128 liquidityNet;
  // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
  // only has relative meaning, not absolute — the value depends on when the tick is initialized
  uint256 feeGrowthOutside0X128;
  uint256 feeGrowthOutside1X128;
  // the cumulative tick value on the other side of the tick
  int56 tickCumulativeOutside;
  // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
  // only has relative meaning, not absolute — the value depends on when the tick is initialized
  uint160 secondsPerLiquidityOutsideX128;
  // the seconds spent on the other side of the tick (relative to the current tick)
  // only has relative meaning, not absolute — the value depends on when the tick is initialized
  uint32 secondsOutside;
  // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
  // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
  bool initialized;
}

struct Observation {
  // the block timestamp of the observation
  uint32 blockTimestamp;
  // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
  int56 tickCumulative;
  // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
  uint160 secondsPerLiquidityCumulativeX128;
  // whether or not the observation is initialized
  bool initialized;
}

struct ProtocolFees {
  uint128 token0;
  uint128 token1;
}

struct Slot0 {
  // the current price
  uint160 sqrtPriceX96;
  // the current tick
  int24 tick;
  // the most-recently updated index of the observations array
  uint16 observationIndex;
  // the current maximum number of observations that are being stored
  uint16 observationCardinality;
  // the next maximum number of observations to store, triggered in observations.write
  uint16 observationCardinalityNext;
  // the current protocol fee as a percentage of the swap fee taken on withdrawal
  // represented as an integer denominator (1/x)%
  uint8 feeProtocol;
  // whether the pool is locked
  bool unlocked;
}

struct SwapCache {
  // the protocol fee for the input token
  uint8 feeProtocol;
  // liquidity at the beginning of the swap
  uint128 liquidityStart;
  // the timestamp of the current block
  uint32 blockTimestamp;
  // the current value of the tick accumulator, computed only if we cross an initialized tick
  int56 tickCumulative;
  // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
  uint160 secondsPerLiquidityCumulativeX128;
  // whether we've computed and cached the above two accumulators
  bool computedLatestObservation;
}

// the top level state of the swap, the results of which are recorded in storage at the end
struct SwapState {
  // the amount remaining to be swapped in/out of the input/output asset
  int256 amountSpecifiedRemaining;
  // the amount already swapped out/in of the output/input asset
  int256 amountCalculated;
  // current sqrt(price)
  uint160 sqrtPriceX96;
  // the tick associated with the current price
  int24 tick;
  // the global fee growth of the input token
  uint256 feeGrowthGlobalX128;
  // amount of input token paid as protocol fee
  uint128 protocolFee;
  // the current liquidity in range
  uint128 liquidity;
}

struct StepComputations {
  // the price at the beginning of the step
  uint160 sqrtPriceStartX96;
  // the next tick to swap to from the current tick in the swap direction
  int24 tickNext;
  // whether tickNext is initialized or not
  bool initialized;
  // sqrt(price) for the next tick (1/0)
  uint160 sqrtPriceNextX96;
  // how much is being swapped in in this step
  uint256 amountIn;
  // how much is being swapped out
  uint256 amountOut;
  // how much fee is being paid in
  uint256 feeAmount;
}

interface IPool {
  function slot0() external view returns (Slot0 memory);

  function liquidity() external view returns (uint128);

  function feeGrowthGlobal0X128() external view returns (uint256);

  function feeGrowthGlobal1X128() external view returns (uint256);

  function tickSpacing() external view returns (int24);

  function fee() external view returns (uint24);

  function protocolFees() external view returns (ProtocolFees memory);

  function tickBitmap(int16) external view returns (uint256);

  function observations(uint256) external view returns (Observation memory);

  function ticks(int24) external view returns (Info memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import "./FullMath.sol";
import "./SqrtPriceMath.sol";

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
  /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
  /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
  /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
  /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
  /// @param liquidity The usable liquidity
  /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
  /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
  /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
  /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
  /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
  /// @return feeAmount The amount of input that will be taken as a fee
  function computeSwapStep(
    uint160 sqrtRatioCurrentX96,
    uint160 sqrtRatioTargetX96,
    uint128 liquidity,
    int256 amountRemaining,
    uint24 feePips
  )
    internal
    pure
    returns (
      uint160 sqrtRatioNextX96,
      uint256 amountIn,
      uint256 amountOut,
      uint256 feeAmount
    )
  {
    bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
    bool exactIn = amountRemaining >= 0;

    if (exactIn) {
      uint256 amountRemainingLessFee = FullMath.mulDiv(
        uint256(amountRemaining),
        1e6 - feePips,
        1e6
      );
      amountIn = zeroForOne
        ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
        : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
      if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
      else
        sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
          sqrtRatioCurrentX96,
          liquidity,
          amountRemainingLessFee,
          zeroForOne
        );
    } else {
      amountOut = zeroForOne
        ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
        : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
      if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
      else
        sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
          sqrtRatioCurrentX96,
          liquidity,
          uint256(-amountRemaining),
          zeroForOne
        );
    }

    bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

    // get the input/output amounts
    if (zeroForOne) {
      amountIn = max && exactIn
        ? amountIn
        : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
      amountOut = max && !exactIn
        ? amountOut
        : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
    } else {
      amountIn = max && exactIn
        ? amountIn
        : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
      amountOut = max && !exactIn
        ? amountOut
        : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
    }

    // cap the output amount to not exceed the remaining output amount
    if (!exactIn && amountOut > uint256(-amountRemaining)) {
      amountOut = uint256(-amountRemaining);
    }

    if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
      // we didn't reach the target, so take the remainder of the maximum input as fee
      feeAmount = uint256(amountRemaining) - amountIn;
    } else {
      feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
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
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

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
        uint256 twos = -denominator & denominator;
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
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import "./LowGasSafeMath.sol";
import "./SafeCast.sol";

import "./FullMath.sol";
import "./UnsafeMath.sol";
import "./FixedPoint96.sol";

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
  using LowGasSafeMath for uint256;
  using SafeCast for uint256;

  /// @notice Gets the next sqrt price given a delta of token0
  /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
  /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
  /// price less in order to not send too much output.
  /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
  /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
  /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
  /// @param liquidity The amount of usable liquidity
  /// @param amount How much of token0 to add or remove from virtual reserves
  /// @param add Whether to add or remove the amount of token0
  /// @return The price after adding or removing amount, depending on add
  function getNextSqrtPriceFromAmount0RoundingUp(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amount,
    bool add
  ) internal pure returns (uint160) {
    // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
    if (amount == 0) return sqrtPX96;
    uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

    if (add) {
      uint256 product;
      if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
        uint256 denominator = numerator1 + product;
        if (denominator >= numerator1)
          // always fits in 160 bits
          return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
      }

      return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
    } else {
      uint256 product;
      // if the product overflows, we know the denominator underflows
      // in addition, we must check that the denominator does not underflow
      require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
      uint256 denominator = numerator1 - product;
      return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
    }
  }

  /// @notice Gets the next sqrt price given a delta of token1
  /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
  /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
  /// price less in order to not send too much output.
  /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
  /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
  /// @param liquidity The amount of usable liquidity
  /// @param amount How much of token1 to add, or remove, from virtual reserves
  /// @param add Whether to add, or remove, the amount of token1
  /// @return The price after adding or removing `amount`
  function getNextSqrtPriceFromAmount1RoundingDown(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amount,
    bool add
  ) internal pure returns (uint160) {
    // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
    // in both cases, avoid a mulDiv for most inputs
    if (add) {
      uint256 quotient = (
        amount <= type(uint160).max
          ? (amount << FixedPoint96.RESOLUTION) / liquidity
          : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
      );

      return uint256(sqrtPX96).add(quotient).toUint160();
    } else {
      uint256 quotient = (
        amount <= type(uint160).max
          ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
          : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
      );

      require(sqrtPX96 > quotient);
      // always fits 160 bits
      return uint160(sqrtPX96 - quotient);
    }
  }

  /// @notice Gets the next sqrt price given an input amount of token0 or token1
  /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
  /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
  /// @param liquidity The amount of usable liquidity
  /// @param amountIn How much of token0, or token1, is being swapped in
  /// @param zeroForOne Whether the amount in is token0 or token1
  /// @return sqrtQX96 The price after adding the input amount to token0 or token1
  function getNextSqrtPriceFromInput(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amountIn,
    bool zeroForOne
  ) internal pure returns (uint160 sqrtQX96) {
    require(sqrtPX96 > 0);
    require(liquidity > 0);

    // round to make sure that we don't pass the target price
    return
      zeroForOne
        ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
        : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
  }

  /// @notice Gets the next sqrt price given an output amount of token0 or token1
  /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
  /// @param sqrtPX96 The starting price before accounting for the output amount
  /// @param liquidity The amount of usable liquidity
  /// @param amountOut How much of token0, or token1, is being swapped out
  /// @param zeroForOne Whether the amount out is token0 or token1
  /// @return sqrtQX96 The price after removing the output amount of token0 or token1
  function getNextSqrtPriceFromOutput(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amountOut,
    bool zeroForOne
  ) internal pure returns (uint160 sqrtQX96) {
    require(sqrtPX96 > 0);
    require(liquidity > 0);

    // round to make sure that we pass the target price
    return
      zeroForOne
        ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
        : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
  }

  /// @notice Gets the amount0 delta between two prices
  /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
  /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up or down
  /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
  function getAmount0Delta(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity,
    bool roundUp
  ) internal pure returns (uint256 amount0) {
    if (sqrtRatioAX96 > sqrtRatioBX96)
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
    uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

    require(sqrtRatioAX96 > 0);

    return
      roundUp
        ? UnsafeMath.divRoundingUp(
          FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
          sqrtRatioAX96
        )
        : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
  }

  /// @notice Gets the amount1 delta between two prices
  /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up, or down
  /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
  function getAmount1Delta(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity,
    bool roundUp
  ) internal pure returns (uint256 amount1) {
    if (sqrtRatioAX96 > sqrtRatioBX96)
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    return
      roundUp
        ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
        : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
  }

  /// @notice Helper that gets signed token0 delta
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The change in liquidity for which to compute the amount0 delta
  /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
  function getAmount0Delta(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    int128 liquidity
  ) internal pure returns (int256 amount0) {
    return
      liquidity < 0
        ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
        : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
  }

  /// @notice Helper that gets signed token1 delta
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The change in liquidity for which to compute the amount1 delta
  /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
  function getAmount1Delta(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    int128 liquidity
  ) internal pure returns (int256 amount1) {
    return
      liquidity < 0
        ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
        : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}