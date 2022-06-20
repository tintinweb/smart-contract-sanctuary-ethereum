pragma solidity 0.7.6;

import "./interfaces/IDeployer01.sol";
import "./Pool.sol";

contract Deployer01 is IDeployer01 {
    function deploy(address poolToken, address uniPool, address setting, string memory tradePair, bool reverse, uint8 oracle) external override returns (address, address) {
        Pool pool = new Pool(poolToken, uniPool, setting, tradePair, reverse, oracle);
        return (address(pool), pool.debtToken());
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.7.6;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BasicMaths.sol";

library Price {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using BasicMaths for bool;

    uint256 private constant E18 = 1e18;

    function lsTokenPrice(uint256 totalSupply, uint256 liquidityPool)
        internal
        pure
        returns (uint256)
    {
        if (totalSupply == 0 || liquidityPool == 0) {
            return E18;
        }

        return liquidityPool.mul(E18) / totalSupply;
    }

    function lsTokenByPoolToken(
        uint256 totalSupply,
        uint256 liquidityPool,
        uint256 poolToken
    ) internal pure returns (uint256) {
        return poolToken.mul(E18) / lsTokenPrice(totalSupply, liquidityPool);
    }

    function poolTokenByLsTokenWithDebt(
        uint256 totalSupply,
        uint256 bondsLeft,
        uint256 liquidityPool,
        uint256 lsToken
    ) internal pure returns (uint256) {
        require(liquidityPool > bondsLeft, "debt scale over pool assets");
        return lsToken.mul(lsTokenPrice(totalSupply, liquidityPool.sub(bondsLeft))) / E18;
    }

    function calLsAvgPrice(
        uint256 lsAvgPrice,
        uint256 lsTotalSupply,
        uint256 amount,
        uint256 lsTokenAmount
    ) internal pure returns (uint256) {
        return lsAvgPrice.mul(lsTotalSupply).add(amount.mul(E18)) / lsTotalSupply.add(lsTokenAmount);
    }

    function divPrice(uint256 value, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return value.mul(E18) / price;
    }

    function mulPrice(uint256 size, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return size.mul(price) / E18;
    }

    function calFundingFee(uint256 rebaseSize, uint256 price)
        internal
        pure
        returns (uint256)
    {
        return mulPrice(rebaseSize.div(E18), price);
    }

    function calDeviationPrice(uint256 deviation, uint256 price, uint8 direction)
        internal
        pure
        returns (uint256)
    {
        if (direction == 1) {
            return price.add(price.mul(deviation) / E18);
        }

        return price.sub(price.mul(deviation) / E18);
    }

    function calRepay(int256 debtChange)
        internal
        pure
        returns (uint256)
    {
        return debtChange < 0 ? uint256(-debtChange): 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library BasicMaths {
    /**
     * @dev Returns the abs of substraction of two unsigned integers
     *
     * _Available since v3.4._
     */
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return b - a;
        }
    }

    /**
     * @dev Returns a - b if a > b, else return 0
     *
     * _Available since v3.4._
     */
    function sub2Zero(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return 0;
        }
    }

    /**
     * @dev if isSub then Returns a - b, else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            return SafeMath.sub(a, b);
        }
    }

    /**
     * @dev if isSub then Returns sub2Zero(a, b), else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub2Zero(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            if (a > b) {
                return a - b;
            } else {
                return 0;
            }
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1 ) / 2;
        uint256 y = x;
        while(z < y){
            y = z;
            z = ( x / z + z ) / 2;
        }
        return y;
    }

    function pow(uint256 x) internal pure returns (uint256) {
        return SafeMath.mul(x, x);
    }

    function diff2(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a >= b) {
            return (true, a - b);
        } else {
            return (false, b - a);
        }
    }
}

pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity 0.7.6;

interface ISystemSettings {
    struct PoolSetting {
        address owner;
        uint256 marginRatio;
        uint256 closingFee;
        uint256 liqFeeBase;
        uint256 liqFeeMax;
        uint256 liqFeeCoefficient;
        uint256 liqLsRequire;
        uint256 rebaseCoefficient;
        uint256 imbalanceThreshold;
        uint256 priceDeviationCoefficient;
        uint256 minHoldingPeriod;
        uint256 debtStart;
        uint256 debtAll;
        uint256 minDebtRepay;
        uint256 maxDebtRepay;
        uint256 interestRate;
        uint256 liquidityCoefficient;
        bool deviation;
    }

    function official() external view returns (address);

    function deployer02() external view returns (address);

    function leverages(uint32) external view returns (bool);

    function protocolFee() external view returns (uint256);

    function liqProtocolFee() external view returns (uint256);

    function marginRatio() external view returns (uint256);

    function closingFee() external view returns (uint256);

    function liqFeeBase() external view returns (uint256);

    function liqFeeMax() external view returns (uint256);

    function liqFeeCoefficient() external view returns (uint256);

    function liqLsRequire() external view returns (uint256);

    function rebaseCoefficient() external view returns (uint256);

    function imbalanceThreshold() external view returns (uint256);

    function priceDeviationCoefficient() external view returns (uint256);

    function minHoldingPeriod() external view returns (uint256);

    function debtStart() external view returns (uint256);

    function debtAll() external view returns (uint256);

    function minDebtRepay() external view returns (uint256);

    function maxDebtRepay() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function liquidityCoefficient() external view returns (uint256);

    function deviation() external view returns (bool);

    function checkOpenPosition(uint16 level) external view;

    function requireSystemActive() external view;

    function requireSystemSuspend() external view;

    function resumeSystem() external;

    function suspendSystem() external;

    function mulClosingFee(uint256 value) external view returns (uint256);

    function mulLiquidationFee(uint256 margin, uint256 deltaBlock) external view returns (uint256);

    function mulMarginRatio(uint256 margin) external view returns (uint256);

    function mulProtocolFee(uint256 amount) external view returns (uint256);

    function mulLiqProtocolFee(uint256 amount) external view returns (uint256);

    function meetImbalanceThreshold(
        uint256 nakedPosition,
        uint256 liquidityPool
    ) external view returns (bool);

    function mulImbalanceThreshold(uint256 liquidityPool)
        external
        view
        returns (uint256);

    function calDeviation(uint256 nakedPosition, uint256 liquidityPool)
        external
        view
        returns (uint256);

    function calRebaseDelta(
        uint256 rebaseSizeXBlockDelta,
        uint256 imbalanceSize
    ) external view returns (uint256);

    function calDebtRepay(
        uint256 lsPnl,
        uint256 totalDebt,
        uint256 totalLiquidity
    ) external view returns (uint256);

    function calDebtIssue(
        uint256 tdPnl,
        uint256 lsAvgPrice,
        uint256 lsPrice
    ) external view returns (uint256);

    function mulInterestFromDebt(
        uint256 amount
    ) external view returns (uint256);

    function divInterestFromDebt(
        uint256 amount
    ) external view returns (uint256);

    function mulLiquidityCoefficient(
        uint256 nakedPositions
    ) external view returns (uint256);

    enum systemParam {
        MarginRatio,
        ProtocolFee,
        LiqProtocolFee,
        ClosingFee,
        LiqFeeBase,
        LiqFeeMax,
        LiqFeeCoefficient,
        LiqLsRequire,
        RebaseCoefficient,
        ImbalanceThreshold,
        PriceDeviationCoefficient,
        MinHoldingPeriod,
        DebtStart,
        DebtAll,
        MinDebtRepay,
        MaxDebtRepay,
        InterestRate,
        LiquidityCoefficient,
        Other
    }

    event AddLeverage(uint32 leverage);
    event DeleteLeverage(uint32 leverage);

    event SetSystemParam(systemParam param, uint256 value);
    event SetDeviation(bool deviation);

    event SetPoolOwner(address pool, address owner);
    event SetPoolParam(address pool, systemParam param, uint256 value);
    event SetPoolDeviation(address pool, bool deviation);

    event Suspend(address indexed sender);
    event Resume(address indexed sender);
}

pragma solidity 0.7.6;

interface IRates {
    function oraclePool() external view returns (address);

    function reverse() external view returns (bool);

    function getPrice() external view returns (uint);

    function updatePrice() external;
}

pragma solidity 0.7.6;

interface IPoolCallback {
    function poolV2Callback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external payable;

    function poolV2RemoveCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external;

    function poolV2BondsCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external;

    function poolV2BondsCallbackFromDebt(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external;
}

pragma solidity 0.7.6;

interface IPool {
    struct Position {
        uint256 openPrice;
        uint256 openBlock;
        uint256 margin;
        uint256 size;
        uint256 openRebase;
        address account;
        uint8 direction;
    }

    function _positions(uint32 positionId)
        external
        view
        returns (
            uint256 openPrice,
            uint256 openBlock,
            uint256 margin,
            uint256 size,
            uint256 openRebase,
            address account,
            uint8 direction
        );

    function debtToken() external view returns (address);

    function lsTokenPrice() external view returns (uint256);

    function addLiquidity(address user, uint256 amount) external;

    function removeLiquidity(address user, uint256 lsAmount, uint256 bondsAmount, address receipt) external;

    function openPosition(
        address user,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external returns (uint32);

    function addMargin(
        address user,
        uint32 positionId,
        uint256 margin
    ) external;

    function closePosition(
        address receipt,
        uint32 positionId
    ) external;

    function liquidate(
        address user,
        uint32 positionId,
        address receipt
    ) external;

    function exit(
        address receipt,
        uint32 positionId
    ) external;

    event MintLiquidity(uint256 amount);

    event AddLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bonds
    );

    event RemoveLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bondsRequired
    );

    event OpenPosition(
        address indexed sender,
        uint256 openPrice,
        uint256 openRebase,
        uint8 direction,
        uint16 level,
        uint256 margin,
        uint256 size,
        uint32 positionId
    );

    event AddMargin(
        address indexed sender,
        uint256 margin,
        uint32 positionId
    );

    event ClosePosition(
        address indexed receipt,
        uint256 closePrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 pnl,
        uint32  positionId,
        bool isProfit,
        int256 debtChange
    );

    event Liquidate(
        address indexed sender,
        uint32 positionID,
        uint256 liqPrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 liqReward,
        uint256 pnl,
        bool isProfit,
        uint256 debtRepay
    );

    event Rebase(uint256 rebaseAccumulatedLong, uint256 rebaseAccumulatedShort);
}

pragma solidity 0.7.6;

interface IDeployer02 {
    function deploy(
        address owner,
        address poolToken,
        address setting,
        string memory tradePair) external returns (address);
}

pragma solidity 0.7.6;

interface IDeployer01 {
    function deploy(
        address poolToken,
        address uniPool,
        address setting,
        string memory tradePair,
        bool reverse,
        uint8 oracle) external returns (address, address);
}

pragma solidity 0.7.6;

interface IDebt {

    function owner() external view returns (address);

    function issueBonds(address recipient, uint256 amount) external;

    function burnBonds(uint256 amount) external;

    function repayLoan(address payer, address recipient, uint256 amount) external;

    function totalDebt() external view returns (uint256);

    function bondsLeft() external view returns (uint256);

    event RepayLoan(
        address indexed receipt,
        uint256 bondsTokenAmount,
        uint256 poolTokenAmount
    );
}

pragma solidity 0.7.6;

import "./interfaces/IRates.sol";
import "./libraries/BasicMaths.sol";
import './libraries/UQ112x112.sol';
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Rates is IRates {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using SafeCast for uint256;
    using UQ112x112 for uint224;

    address internal _oraclePool;
    bool internal _reverse;
    uint8 internal _oracle;

    uint32[] private _secondsAgo;
    uint32 private constant OBSERVE_TIME_INTERVAL = 60;
    uint256 private constant E18 = 1e18;
    uint256 private constant E28 = 1e28;
    uint256 private constant E38 = 1e38;
    uint256 private constant E58 = 1e58;
    int256 private precisionDiff = 0;
    uint256 private _priceCumulativeOld;
    uint256 private _priceOld;
    uint32 private _timestampOld;

    constructor(address oraclePool, bool reverse, uint8 oracle) {
        _oraclePool = oraclePool;
        _reverse = reverse;
        _oracle = oracle;
        initPrecisionDiff();

        if (oracle == 0) {
            _secondsAgo = [OBSERVE_TIME_INTERVAL, 0];
        } else {
            _initialPriceV2();
        }
    }

    function initPrecisionDiff() internal {
        address token0;
        address token1;

        if (_oracle == 0) {
            token0 = IUniswapV3Pool(_oraclePool).token0();
            token1 = IUniswapV3Pool(_oraclePool).token1();
        } else {
            token0 = IUniswapV2Pair(_oraclePool).token0();
            token1 = IUniswapV2Pair(_oraclePool).token1();
        }

        precisionDiff =
            int256(ERC20(token0).decimals()) -
            int256(ERC20(token1).decimals());

        if (_oracle != 0 && _reverse) {
            precisionDiff = -precisionDiff;
        }
    }

    function oraclePool() external view override returns (address) {
        return _oraclePool;
    }

    function reverse() external view override returns (bool) {
        return _reverse;
    }

    function getPrice() external view override returns (uint256) {
        return _getPrice();
    }

    function updatePrice() external override {
        require(_oracle != 0, "O Err");

        (uint256 priceCumulativeLast, uint32 blockTimestamp, uint256 price) = _getPriceV2();
        if (blockTimestamp != _timestampOld) {
            _updatePriceV2(priceCumulativeLast, blockTimestamp, price);
        }
    }

    function _getPrice() internal view returns (uint256) {
        if (_oracle == 0) {
            return _getPriceV3();
        } else {
            (, , uint256 price) = _getPriceV2();
            return price;
        }
    }

    function _getPriceAndUpdate() internal returns (uint256) {
        if (_oracle == 0) {
            return _getPriceV3();
        } else {
            (uint256 priceCumulativeLast, uint32 timestampLast, uint256 price) = _getPriceV2();
            if (timestampLast != _timestampOld) {
                _updatePriceV2(priceCumulativeLast, timestampLast, price);
            }

            return price;
        }
    }

    function _getPriceV3() internal view returns (uint256) {
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(_oraclePool).observe(
            _secondsAgo
        );
        uint256 sqrtPriceX96 = uint256(
            TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) /
                    int56(OBSERVE_TIME_INTERVAL))
            )
        );
        uint256 price;
        if (sqrtPriceX96 > E38) {
            price = (sqrtPriceX96 >> 96).mul((sqrtPriceX96.mul(E18)) >> 96);
        } else if (
            precisionDiff > 0 &&
            sqrtPriceX96 < E28.div(10**(uint256(precisionDiff).div(2)))
        ) {
            price =
                (
                    sqrtPriceX96.mul(sqrtPriceX96).mul(E18).mul(
                        10**uint256(precisionDiff)
                    )
                ) >>
                192;
        } else if (sqrtPriceX96 < E28) {
            price = (sqrtPriceX96.mul(sqrtPriceX96).mul(E18)) >> 192;
        } else {
            price = (((sqrtPriceX96.mul(sqrtPriceX96)) >> 96).mul(E18)) >> 96;
        }

        if (precisionDiff > 0) {
            if (sqrtPriceX96 > E28.div(10**(uint256(precisionDiff).div(2)))) {
                price = price.mul(10**uint256(precisionDiff));
            }
        } else if (precisionDiff < 0) {
            price = price.div(10**uint256(-precisionDiff));
        }
        if (price == 0) {
            price = 1;
        }
        if (_reverse) {
            price = _priceReciprocal(price);
        }
        if (price == 0) {
            price = 1;
        }
        return price;
    }

    function _getPriceV2() internal view returns (uint256 priceCumulativeLast, uint32 , uint256 price) {
        IUniswapV2Pair pair = IUniswapV2Pair(_oraclePool);
        (uint112 _reserve0, uint112 _reserve1, uint32 timestampLast) = pair.getReserves();

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        if (blockTimestamp == _timestampOld) {
            return (priceCumulativeLast, blockTimestamp, _priceOld);
        }

        if (_reverse) {
            priceCumulativeLast = pair.price1CumulativeLast();
            if (timestampLast < blockTimestamp) {
                priceCumulativeLast = priceCumulativeLast.add(uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * (blockTimestamp - timestampLast));
            }
        } else {
            priceCumulativeLast = pair.price0CumulativeLast();
            if (timestampLast < blockTimestamp) {
                priceCumulativeLast = priceCumulativeLast.add(uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * (blockTimestamp - timestampLast));
            }
        }

        uint256 priceX112 = priceCumulativeLast.sub(_priceCumulativeOld) / (blockTimestamp - _timestampOld);

        if (priceX112 > E58) {
            price = (priceX112 >> 112).mul(E18);
        } else {
            price = (priceX112.mul(E18)) >> 112;
        }

        if (precisionDiff > 0) {
            price = price.mul(10**uint256(precisionDiff));
        } else {
            price = price / 10**uint256(-precisionDiff);
        }

        if (price == 0) {
            price = 1;
        }

        return (priceCumulativeLast, blockTimestamp, price);
    }

    function _initialPriceV2() internal {
        IUniswapV2Pair pair = IUniswapV2Pair(_oraclePool);
        uint112 reverse0;
        uint112 reverse1;
        (reverse0, reverse1, _timestampOld) = pair.getReserves();
        require(reverse0 > 0 && reverse1 > 0, "not init");

        if (_reverse) {
            _priceCumulativeOld = pair.price1CumulativeLast();
            _priceOld = uint256(reverse0).mul(E18) / reverse1;
        } else {
            _priceCumulativeOld = pair.price0CumulativeLast();
            _priceOld = uint256(reverse1).mul(E18) / reverse0;
        }

        if (precisionDiff > 0) {
            _priceOld = _priceOld.mul(10**uint256(precisionDiff));
        } else {
            _priceOld = _priceOld / 10**uint256(-precisionDiff);
        }
    }

    function _updatePriceV2(uint256 priceCumulativeLast, uint32 timestampLast, uint256 price) internal {
        _priceCumulativeOld = priceCumulativeLast;
        _timestampOld = timestampLast;
        _priceOld = price;
    }

    function _priceReciprocal(uint256 originalPrice)
        internal
        pure
        returns (uint256)
    {
        uint256 one = E18**2;
        uint256 half = originalPrice.div(2);
        return half.add(one).div(originalPrice);
    }
}

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./libraries/Price.sol";
import "./libraries/BasicMaths.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ISystemSettings.sol";
import "./interfaces/IPoolCallback.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IDeployer02.sol";
import "./interfaces/IDebt.sol";
import "./Rates.sol";

contract Pool is ERC20, Rates, IPool {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using BasicMaths for bool;
    using SafeERC20 for IERC20;

    address public _poolToken;
    address public _settings;
    address public override debtToken;

    uint256 public _lastRebaseBlock = 0;
    uint32 public _positionIndex = 0;
    uint8 public _poolDecimalDiff;
    mapping(uint32 => Position) public override _positions;

    uint256 public _lsAvgPrice = 1e18;
    uint256 public _liquidityPool = 0;
    uint256 public _totalSizeLong = 0;
    uint256 public _totalSizeShort = 0;
    uint256 public _rebaseAccumulatedLong = 0;
    uint256 public _rebaseAccumulatedShort = 0;

    uint8 private constant StandardDecimal = 18;
    bool private locked;

    constructor(
        address poolToken,
        address uniPool,
        address setting,
        string memory symbol,
        bool reverse,
        uint8 oracle
    ) ERC20(symbol, symbol) Rates(uniPool, reverse, oracle) {
        uint8 decimals = ERC20(poolToken).decimals();

        _setupDecimals(decimals);
        _poolToken = poolToken;
        _settings = setting;
        _poolDecimalDiff = StandardDecimal > ERC20(poolToken).decimals()
            ? StandardDecimal - ERC20(poolToken).decimals()
            : 0;

        debtToken = IDeployer02(ISystemSettings(setting).deployer02()).deploy(address(this), poolToken, setting, symbol);
    }

    function lsTokenPrice() external view override returns (uint256) {
        return
            Price.lsTokenPrice(
                IERC20(address(this)).totalSupply(),
                _liquidityPool
            );
    }

    function poolCallback(address user, uint256 amount) internal lock {
        uint256 balanceBefore = IERC20(_poolToken).balanceOf(address(this));
        IPoolCallback(msg.sender).poolV2Callback(
            amount,
            _poolToken,
            address(_oraclePool),
            user,
            _reverse
        );
        require(
            IERC20(_poolToken).balanceOf(address(this)) >=
                balanceBefore.add(amount),
            "PT Err"
        );
    }

    function _mintLsByPoolToken(uint256 amount) internal {
        uint256 lsTokenAmount = Price.lsTokenByPoolToken(
            IERC20(address(this)).totalSupply(),
            _liquidityPool,
            amount
        );

        _mint(ISystemSettings(_settings).official(), lsTokenAmount);
        emit MintLiquidity(lsTokenAmount);
    }

    function addLiquidity(address user, uint256 amount) external override {
        ISystemSettings(_settings).requireSystemActive();
        require(amount > 0, "Amt Err");
        rebase();

        uint256 lsTotalSupply = IERC20(address(this)).totalSupply();
        uint256 lsTokenAmount = Price.lsTokenByPoolToken(
            lsTotalSupply,
            _liquidityPool,
            amount
        );
        poolCallback(user, amount);

        _mint(user, lsTokenAmount);
        _liquidityPool = _liquidityPool.add(amount);
        _lsAvgPrice = Price.calLsAvgPrice(_lsAvgPrice, lsTotalSupply, amount, lsTokenAmount);

        IDebt debt = IDebt(debtToken);
        uint bonds;
        if (lsTotalSupply > 0) {
            bonds = debt.bondsLeft().mul(lsTokenAmount) / lsTotalSupply;
            if (bonds > 0) {
                debt.issueBonds(user, bonds);
            }
        }

        emit AddLiquidity(user, amount, lsTokenAmount, bonds);
    }

    function removeLiquidity(address user, uint256 amount, uint256 bondsAmount, address receipt) external override lock {
        ISystemSettings settings = ISystemSettings(_settings);
        rebase();

        IERC20 ls = IERC20(address(this));
        uint256 bondsLeft = IDebt(debtToken).bondsLeft();
        uint256 poolTokenAmount;

        if (bondsAmount == 0) {
            // remove ls without bonds
            poolTokenAmount = Price.poolTokenByLsTokenWithDebt(
                ls.totalSupply(),
                bondsLeft,
                _liquidityPool,
                amount
            );
        } else {
            // remove ls with bonds
            uint256 bondsRequired = bondsLeft.mul(amount).div(ls.totalSupply());
            if (bondsAmount >= bondsRequired) {
                bondsAmount = bondsRequired;
            } else {
                amount = bondsAmount.mul(ls.totalSupply()).div(bondsLeft);
            }

            IPoolCallback(msg.sender).poolV2BondsCallback(
                bondsAmount,
                _poolToken,
                address(_oraclePool),
                user,
                _reverse
            );

            IDebt(debtToken).burnBonds(bondsAmount);
            poolTokenAmount = Price.poolTokenByLsTokenWithDebt(
                ls.totalSupply(),
                0,
                _liquidityPool,
                amount
            );
        }

        uint256 nakedPosition = Price
            .mulPrice(_totalSizeLong.diff(_totalSizeShort), _getPrice())
            .div(10**_poolDecimalDiff);
        require(settings.mulLiquidityCoefficient(nakedPosition) <= _liquidityPool.sub2Zero(poolTokenAmount),
            "Ls Err");

        uint256 balanceBefore = ls.balanceOf(address(this));
        IPoolCallback(msg.sender).poolV2RemoveCallback(
            amount,
            _poolToken,
            address(_oraclePool),
            user,
            _reverse
        );
        require(
            ls.balanceOf(address(this)) >=
                balanceBefore.add(amount),
            "LS Err"
        );

        _burn(address(this), amount);
        _liquidityPool = _liquidityPool.sub(poolTokenAmount);
        IERC20(_poolToken).safeTransfer(receipt, poolTokenAmount);

        emit RemoveLiquidity(user, poolTokenAmount, amount, bondsAmount);
    }

    function openPosition(
        address user,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external override returns (uint32) {
        ISystemSettings setting = ISystemSettings(_settings);
        setting.checkOpenPosition(leverage);
        require(
            direction == 1 || direction == 2,
            "D Err"
        );

        require(position > 0, "Amt Err");
        require(_liquidityPool > 0, "L Err");

        rebase();

        uint256 price = _getPrice();
        uint256 value = position.mul(leverage);

        if (setting.deviation()) {
            uint256 nakedPosition;
            bool positive;

            if (direction == 1) {
                (positive, nakedPosition) = Price
                    .mulPrice(_totalSizeLong, price)
                    .div(10**_poolDecimalDiff)
                    .add(value)
                    .diff2(
                        Price.mulPrice(_totalSizeShort, price).div(
                            10**_poolDecimalDiff
                        )
                    );
            } else {
                (positive, nakedPosition) = Price
                    .mulPrice(_totalSizeLong, price)
                    .div(10**_poolDecimalDiff)
                    .diff2(
                        Price
                            .mulPrice(_totalSizeShort, price)
                            .div(10**_poolDecimalDiff)
                            .add(value)
                    );
            }

            if ((direction == 1) == positive) {
                uint256 deviation = setting.calDeviation(
                    nakedPosition,
                    _liquidityPool
                );
                price = Price.calDeviationPrice(deviation, price, direction);
            }
        }

        poolCallback(user, position);
        if (_poolDecimalDiff > 0) {
            value = value.mul(10**_poolDecimalDiff);
        }
        uint256 size = Price.divPrice(value, price);

        uint256 openRebase;
        if (direction == 1) {
            _totalSizeLong = _totalSizeLong.add(size);
            openRebase = _rebaseAccumulatedLong;
        } else {
            _totalSizeShort = _totalSizeShort.add(size);
            openRebase = _rebaseAccumulatedShort;
        }

        _positionIndex++;
        _positions[_positionIndex] = Position(
            price,
            block.number,
            position,
            size,
            openRebase,
            msg.sender,
            direction
        );

        emit OpenPosition(
            user,
            price,
            openRebase,
            direction,
            leverage,
            position,
            size,
            _positionIndex
        );
        return _positionIndex;
    }

    function addMargin(
        address user,
        uint32 positionId,
        uint256 margin
    ) external override {
        ISystemSettings(_settings).requireSystemActive();
        Position memory p = _positions[positionId];
        require(msg.sender == p.account, "P Err");
        rebase();

        poolCallback(user, margin);
        _positions[positionId].margin = p.margin.add(margin);

        emit AddMargin(user, margin, positionId);
    }

    function closePosition(
        address receipt,
        uint32 positionId
    ) external override {
        ISystemSettings setting = ISystemSettings(_settings);
        setting.requireSystemActive();

        Position memory p = _positions[positionId];
        require(p.account == msg.sender, "P Err");
        rebase();

        uint256 closePrice = _getPrice();
        uint256 pnl;
        bool isProfit;
        if (block.number - p.openBlock > setting.minHoldingPeriod()) {
            pnl = Price.mulPrice(p.size, closePrice.diff(p.openPrice));
            isProfit = (closePrice >= p.openPrice) == (p.direction == 1);
        }

        uint256 fee = setting.mulClosingFee(Price.mulPrice(p.size, closePrice));
        uint256 fundingFee;
        if (p.direction == 1) {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedLong.sub(p.openRebase)),
                closePrice
            );

            _totalSizeLong = _totalSizeLong.sub(p.size);
        } else {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedShort.sub(p.openRebase)),
                closePrice
            );

            _totalSizeShort = _totalSizeShort.sub(p.size);
        }

        if (_poolDecimalDiff != 0) {
            pnl = pnl.div(10**_poolDecimalDiff);
            fee = fee.div(10**_poolDecimalDiff);
            fundingFee = fundingFee.div(10**_poolDecimalDiff);
        }

        require(
            isProfit.addOrSub2Zero(p.margin, pnl) > fee.add(fundingFee),
            "Close Err"
        );

        int256 debtChange;
        uint256 transferOut = isProfit.addOrSub(p.margin, pnl).sub(fee).sub(
            fundingFee
        );

        if (transferOut < p.margin) {
            // repay debt
            uint256 debtRepay = setting.calDebtRepay(p.margin - transferOut,
                IDebt(debtToken).totalDebt(),
                _liquidityPool
            );

            if (debtRepay > 0) {
                IERC20(_poolToken).safeTransfer(debtToken, debtRepay);
            }

            debtChange = int256(-debtRepay);

        } else {

            uint256 debtIssue;
            if (_liquidityPool.add(p.margin) < transferOut) {
                debtIssue = transferOut - p.margin;
            }
            else {
                uint256 lsPrice = Price.lsTokenPrice(
                    IERC20(address(this)).totalSupply(),
                    _liquidityPool.add(p.margin) - transferOut);

                debtIssue = setting.calDebtIssue(transferOut - p.margin,
                    _lsAvgPrice,
                    lsPrice
                );
            }

            transferOut = transferOut.sub(debtIssue);
            if (debtIssue > 0) {
                IDebt(debtToken).issueBonds(receipt, debtIssue);
            }

            debtChange = int256(debtIssue);
        }

        if (transferOut > 0) {
            IERC20(_poolToken).safeTransfer(receipt, transferOut);
        }

        if (p.margin >= transferOut.add(Price.calRepay(debtChange))) {
            _liquidityPool = _liquidityPool.add(p.margin.sub(transferOut.add(Price.calRepay(debtChange))));
        } else {
            _liquidityPool = _liquidityPool.sub(transferOut.add(Price.calRepay(debtChange)).sub(p.margin));
        }

        _mintLsByPoolToken(setting.mulProtocolFee(fundingFee.add(fee)));

        delete _positions[positionId];
        emit ClosePosition(
            receipt,
            closePrice,
            fee,
            fundingFee,
            pnl,
            positionId,
            isProfit,
            debtChange
        );
    }

    function liquidate(
        address user,
        uint32 positionId,
        address receipt
    ) external override {
        Position memory p = _positions[positionId];
        require(p.account != address(0), "P Err");

        ISystemSettings setting = ISystemSettings(_settings);
        setting.requireSystemActive();
        require(IERC20(address(this)).balanceOf(user) >= setting.liqLsRequire(), "too less ls");

        rebase();

        uint256 liqPrice = _getPrice();
        uint256 pnl = Price.mulPrice(p.size, liqPrice.diff(p.openPrice));
        uint256 fee = setting.mulClosingFee(Price.mulPrice(p.size, liqPrice));
        uint256 fundingFee;

        if (p.direction == 1) {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedLong.sub(p.openRebase)),
                liqPrice
            );

            _totalSizeLong = _totalSizeLong.sub(p.size);
        } else {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedShort.sub(p.openRebase)),
                liqPrice
            );

            _totalSizeShort = _totalSizeShort.sub(p.size);
        }

        if (_poolDecimalDiff != 0) {
            pnl = pnl.div(10**_poolDecimalDiff);
            fee = fee.div(10**_poolDecimalDiff);
            fundingFee = fundingFee.div(10**_poolDecimalDiff);
        }

        bool isProfit = (liqPrice >= p.openPrice) == (p.direction == 1);

        require(
            isProfit.addOrSub2Zero(p.margin, pnl) < fee.add(fundingFee).add(setting.mulMarginRatio(p.margin)),
            "Liq Err"
        );

        uint256 liquidateFee = setting.mulLiquidationFee(p.margin, block.number - p.openBlock);
        uint256 liqProtocolFee = setting.mulLiqProtocolFee(liquidateFee);
        liquidateFee = liquidateFee.sub(liqProtocolFee);

        uint256 debtRepay = setting.calDebtRepay(p.margin.sub(liquidateFee),
            IDebt(debtToken).totalDebt(),
            _liquidityPool
        );
        if (debtRepay > 0) {
            IERC20(_poolToken).safeTransfer(debtToken, debtRepay);
        }

        _liquidityPool = _liquidityPool.add(p.margin.sub(liquidateFee).sub(debtRepay));
        IERC20(_poolToken).safeTransfer(receipt, liquidateFee);
        delete _positions[positionId];

        uint256 protocolFee = setting.mulProtocolFee(fundingFee.add(fee));
        _mintLsByPoolToken(protocolFee.add(liqProtocolFee));

        emit Liquidate(
            user,
            positionId,
            liqPrice,
            fee,
            fundingFee,
            liquidateFee,
            pnl,
            isProfit,
            debtRepay
        );
    }

    function rebase() internal {
        ISystemSettings setting = ISystemSettings(_settings);
        uint256 currBlock = block.number;

        if (_lastRebaseBlock == currBlock) {
            return;
        }

        if (_liquidityPool == 0) {
            _lastRebaseBlock = currBlock;
            return;
        }

        uint256 rebasePrice = _getPriceAndUpdate();
        uint256 nakedPosition = Price
            .mulPrice(_totalSizeLong.diff(_totalSizeShort), rebasePrice)
            .div(10**_poolDecimalDiff);

        if (!setting.meetImbalanceThreshold(nakedPosition, _liquidityPool)) {
            _lastRebaseBlock = currBlock;
            return;
        }

        uint256 rebaseSize = _totalSizeLong.diff(_totalSizeShort).sub(
            Price
                .divPrice(
                    setting.mulImbalanceThreshold(_liquidityPool),
                    rebasePrice
                )
                .mul(10**_poolDecimalDiff)
        );

        if (_totalSizeLong > _totalSizeShort) {
            uint256 rebaseDelta = setting.calRebaseDelta(
                rebaseSize.mul(block.number.sub(_lastRebaseBlock)),
                _totalSizeLong
            );

            _rebaseAccumulatedLong = _rebaseAccumulatedLong.add(rebaseDelta);
        } else {
            uint256 rebaseDelta = setting.calRebaseDelta(
                rebaseSize.mul(block.number.sub(_lastRebaseBlock)),
                _totalSizeShort
            );

            _rebaseAccumulatedShort = _rebaseAccumulatedShort.add(rebaseDelta);
        }
        _lastRebaseBlock = currBlock;

        emit Rebase(
            _rebaseAccumulatedLong,
            _rebaseAccumulatedShort
        );
    }

    function exit(
        address receipt,
        uint32 positionId
    ) external override {
        ISystemSettings(_settings).requireSystemSuspend();

        Position memory p = _positions[positionId];
        require(p.account == msg.sender, "P Err");

        if (p.direction == 1) {
            _totalSizeLong = _totalSizeLong.sub(p.size);
        } else {
            _totalSizeShort = _totalSizeShort.sub(p.size);
        }

        IERC20(_poolToken).safeTransfer(receipt, p.margin);

        delete _positions[positionId];
    }

    modifier lock() {
        require(!locked, 'LOCK');
        locked = true;
        _;
        locked = false;
    }
}