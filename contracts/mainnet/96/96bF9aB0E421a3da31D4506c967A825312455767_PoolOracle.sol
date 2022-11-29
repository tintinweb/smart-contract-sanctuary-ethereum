// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;

import "../interfaces/IPoolOracle.sol";
import {Exp64x64} from "../Exp64x64.sol";
import {Math64x64} from "../Math64x64.sol";

/**
 * @title PoolOracle
 * @author Bruno Bonanno
 * @dev This contract collects data from different YieldSpace pools to compute a TWAR using a SMA (https://www.investopedia.com/terms/s/sma.asp)
 * Adapted from https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
 */
//solhint-disable not-rely-on-time
contract PoolOracle is IPoolOracle {
    using Math64x64 for *;
    using Exp64x64 for *;

    event ObservationRecorded(IPool indexed pool, uint256 index, Observation observation);

    error NoObservationsForPool(IPool pool);
    error MissingHistoricalObservation(IPool pool);
    error InsufficientElapsedTime(IPool pool, uint256 elapsedTime);

    struct Observation {
        uint256 timestamp;
        uint256 ratioCumulative;
    }

    uint128 public constant WAD = 1e18;
    uint128 public constant RAY = 1e27;

    // the desired amount of time over which the moving average should be computed, e.g. 24 hours
    uint256 public immutable windowSize;
    // the number of observations stored for each pool, i.e. how many ratio observations are stored for the window.
    // as granularity increases from 1, more frequent updates are needed, but moving averages become more precise.
    // averages are computed over intervals with sizes in the range:
    //   [windowSize - (windowSize / granularity) * 2, windowSize]
    // e.g. if the window size is 24 hours, and the granularity is 24, the oracle will return the TWAR for
    //   the period:
    //   [now - [22 hours, 24 hours], now]
    uint256 public immutable granularity;
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint256 public immutable periodSize;
    // this is to avoid using values that are too close in time to the current observation
    uint256 public immutable minTimeElapsed;

    // mapping from pool address to a list of ratio observations of that pool
    mapping(IPool => Observation[]) public poolObservations;

    constructor(
        uint256 windowSize_,
        uint256 granularity_,
        uint256 minTimeElapsed_
    ) {
        require(granularity_ > 1, "GRANULARITY");
        require((periodSize = windowSize_ / granularity_) * granularity_ == windowSize_, "WINDOW_NOT_EVENLY_DIVISIBLE");
        windowSize = windowSize_;
        granularity = granularity_;
        minTimeElapsed = minTimeElapsed_;
    }

    /// @notice calculates the index of the observation corresponding to the given timestamp
    /// @param timestamp The timestamp to calculate the index for
    /// @return index The index corresponding to the `timestamp`
    function observationIndexOf(uint256 timestamp) public view returns (uint256 index) {
        uint256 epochPeriod = timestamp / periodSize;
        index = epochPeriod % granularity;
    }

    /// @notice returns the oldest observation available, starting at the oldest epoch (at the beginning of the window) relative to the current time
    /// @param pool Address of pool for which the observation is required
    /// @return o The oldest observation available for `pool`
    function getOldestObservationInWindow(IPool pool) public view returns (Observation memory o) {
        uint256 length = poolObservations[pool].length;
        if (length == 0) {
            revert NoObservationsForPool(pool);
        }

        unchecked {
            uint256 observationIndex = observationIndexOf(block.timestamp);
            for (uint256 i; i < length; ) {
                // can't possible overflow
                // compute the oldestObservation given `observationIndex`, basically `widowSize` in the past
                uint256 oldestObservationIndex = (++observationIndex) % granularity;

                // Read the oldest observation
                o = poolObservations[pool][oldestObservationIndex];

                // For an observation to be valid, it has to be newer than the `windowSize`
                if (block.timestamp - o.timestamp < windowSize) {
                    return o;
                }

                // If the observation was not newer than the `windowSize` then we loop and try with the next one
                // We do this for 2 reasons
                //  a) The current slot may have never been updated due to low volume at the time, but the next one may have been.
                //     Finding a not-that-old observation (not strictly `windowTime` old) is better than aborting the whole tx
                //  b) We could be within the first `windowTime` (i.e. 24hs) of this pool being in use by the oracle,
                //     hence we don't have enough history for every slot to be valid,
                //     so we loop hoping for the newer slots to have valid data

                ++i; // can't possible overflow
            }

            revert MissingHistoricalObservation(pool);
        }
    }

    // @inheritdoc IPoolOracle
    function updatePool(IPool pool) public override returns(bool updated) {
        // populate the array with empty observations (only on the first call ever for each pool)
        unchecked {
            for (uint256 i = poolObservations[pool].length; i < granularity; ) {
                poolObservations[pool].push();
                ++i;
            }
        }

        // get the observation for the current period
        uint256 index = observationIndexOf(block.timestamp);
        Observation storage observation = poolObservations[pool][index];

        // we only want to commit updates once per period (i.e. windowSize / granularity)
        uint256 timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            (observation.ratioCumulative, observation.timestamp) = IPool(pool).currentCumulativeRatio();
            emit ObservationRecorded(pool, index, observation);
            updated = true;
        }
    }

    // @inheritdoc IPoolOracle
    function updatePools(IPool[] calldata pools) public override {
        uint length = pools.length;
        for(uint i = 0; i < length;i ++) {
            updatePool(pools[i]);
        }
    }

    /// @inheritdoc IPoolOracle
    function peek(IPool pool) public view override returns (uint256 twar) {
        Observation memory oldestObservation = getOldestObservationInWindow(pool);

        uint256 timeElapsed = block.timestamp - oldestObservation.timestamp;

        // This check is to safeguard the edge case where the pool was initialised just now (or very, very recently)
        // and hence the TWAR can't be trusted as it would be easy to manipulate it.
        // This can happen cause even if we always try to use a value that's `windowSize` old, if said value is stale or invalid
        // we'll loop and try newer ones until we find a valid one (or we blow).
        if (timeElapsed < minTimeElapsed) {
            revert InsufficientElapsedTime(pool, timeElapsed);
        }

        (uint256 currentCumulativeRatio_, ) = IPool(pool).currentCumulativeRatio();
        // cumulative ratio is in (ratio * seconds) units so for the average we simply get it after division by time elapsed
        // cumulative ratio has 27 decimals precision (RAY), the below equation returns a number on 18 decimals precision
        twar = ((currentCumulativeRatio_ - oldestObservation.ratioCumulative) * WAD) / (timeElapsed * RAY);
    }

    /// @inheritdoc IPoolOracle
    function get(IPool pool) public override returns (uint256 twar) {
        updatePool(pool);
        return peek(pool);
    }

    /// @inheritdoc IPoolOracle
    function getSellFYTokenPreview(IPool pool, uint256 fyTokenIn)
        external
        override
        returns (uint256 baseOut, uint256 updateTime)
    {
        (baseOut, updateTime) = _getAmountOverPrice(pool, fyTokenIn, pool.g2());
    }

    /// @inheritdoc IPoolOracle
    function getSellBasePreview(IPool pool, uint256 baseIn)
        external
        override
        returns (uint256 fyTokenOut, uint256 updateTime)
    {
        (fyTokenOut, updateTime) = _getAmountTimesPrice(pool, baseIn, pool.g1());
    }

    /// @inheritdoc IPoolOracle
    function getBuyFYTokenPreview(IPool pool, uint256 fyTokenOut)
        external
        override
        returns (uint256 baseIn, uint256 updateTime)
    {
        (baseIn, updateTime) = _getAmountOverPrice(pool, fyTokenOut, pool.g1());
    }

    /// @inheritdoc IPoolOracle
    function getBuyBasePreview(IPool pool, uint256 baseOut)
        external
        override
        returns (uint256 fyTokenIn, uint256 updateTime)
    {
        (fyTokenIn, updateTime) = _getAmountTimesPrice(pool, baseOut, pool.g2());
    }

    /// @inheritdoc IPoolOracle
    function peekSellFYTokenPreview(IPool pool, uint256 fyTokenIn)
        external
        view
        override
        returns (uint256 baseOut, uint256 updateTime)
    {
        (baseOut, updateTime) = _peekAmountOverPrice(pool, fyTokenIn, pool.g2());
    }

    /// @inheritdoc IPoolOracle
    function peekSellBasePreview(IPool pool, uint256 baseIn)
        external
        view
        override
        returns (uint256 fyTokenOut, uint256 updateTime)
    {
        (fyTokenOut, updateTime) = _peekAmountTimesPrice(pool, baseIn, pool.g1());
    }

    /// @inheritdoc IPoolOracle
    function peekBuyFYTokenPreview(IPool pool, uint256 fyTokenOut)
        external
        view
        override
        returns (uint256 baseIn, uint256 updateTime)
    {
        (baseIn, updateTime) = _peekAmountOverPrice(pool, fyTokenOut, pool.g1());
    }

    /// @inheritdoc IPoolOracle
    function peekBuyBasePreview(IPool pool, uint256 baseOut)
        external
        view
        override
        returns (uint256 fyTokenIn, uint256 updateTime)
    {
        (fyTokenIn, updateTime) = _peekAmountTimesPrice(pool, baseOut, pool.g2());
    }

    function _peekAmountOverPrice(
        IPool pool,
        uint256 amount,
        int128 g
    ) internal view returns (uint256 result, uint256 updateTime) {
        updateTime = block.timestamp;
        uint256 maturity = pool.maturity();
        if (updateTime >= maturity) {
            result = amount;
        } else {
            int128 price = _price(pool, peek(pool), g, maturity, updateTime);
            result = amount.divu(WAD).div(price).mulu(WAD); // result = amount / price
        }
    }

    function _peekAmountTimesPrice(
        IPool pool,
        uint256 amount,
        int128 g
    ) internal view returns (uint256 result, uint256 updateTime) {
        updateTime = block.timestamp;
        uint256 maturity = pool.maturity();
        if (updateTime >= maturity) {
            result = amount;
        } else {
            int128 price = _price(pool, peek(pool), g, maturity, updateTime);
            result = price.mulu(amount); // result = amount * price
        }
    }

    function _getAmountOverPrice(
        IPool pool,
        uint256 amount,
        int128 g
    ) internal returns (uint256 result, uint256 updateTime) {
        updateTime = block.timestamp;
        uint256 maturity = pool.maturity();
        if (updateTime >= maturity) {
            result = amount;
        } else {
            int128 price = _price(pool, get(pool), g, maturity, updateTime);
            result = amount.divu(WAD).div(price).mulu(WAD); // result = amount / price
        }
    }

    function _getAmountTimesPrice(
        IPool pool,
        uint256 amount,
        int128 g
    ) internal returns (uint256 result, uint256 updateTime) {
        updateTime = block.timestamp;
        uint256 maturity = pool.maturity();
        if (updateTime >= maturity) {
            result = amount;
        } else {
            int128 price = _price(pool, get(pool), g, maturity, updateTime);
            result = price.mulu(amount); // result = amount * price
        }
    }

    function _price(
        IPool pool,
        uint256 twar,
        int128 g,
        uint256 maturity,
        uint256 updateTime
    ) internal view returns (int128 price) {
        /*
            https://hackmd.io/VlQkYJ6cTzWIaIyxuR1g2w
            https://www.desmos.com/calculator/39jpmawgpu
            
            price = (c/μ * twar)^t
            price = (c/μ * twar)^(ts*g*ttm)
        */

        // ttm
        int128 timeTillMaturity = (maturity - updateTime).fromUInt();

        // t = ts * g * ttm
        int128 t = pool.ts().mul(g).mul(timeTillMaturity);

        // make twar a binary 64.64 fraction
        int128 twar64 = twar.divu(WAD);

        // price = (c/μ * twar)^t
        price = pool.getC().div(pool.mu()).mul(twar64).pow(t);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./IPool.sol";

interface IPoolOracle {
    /// @notice returns the TWAR for a given `pool` using the moving average over the max available time range within the window
    /// @param pool Address of pool for which the observation is required
    /// @return twar The most up to date TWAR for `pool`
    function peek(IPool pool) external view returns (uint256 twar);

    /// @notice returns the TWAR for a given `pool` using the moving average over the max available time range within the window
    /// @dev will try to record a new observation if necessary, so equivalent to `update(pool); peek(pool);`
    /// @param pool Address of pool for which the observation is required
    /// @return twar The most up to date TWAR for `pool`
    function get(IPool pool) external returns (uint256 twar);

    /// @notice updates the cumulative ratio for the observation at the current timestamp. Each observation is updated at most
    /// once per epoch period.
    /// @param pool Address of pool for which the observation should be recorded
    /// @return updated Flag to indicate if the observation at the current timestamp was actually updated
    function updatePool(IPool pool) external returns(bool updated);

    /// @notice updates the cumulative ratio for the observation at the current timestamp. Each observation is updated at most
    /// once per epoch period.
    /// @param pools Addresses of pool for which the observation should be recorded
    function updatePools(IPool[] calldata pools) external;

    /// Returns how much fyToken would be required to buy `baseOut` base.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseOut Amount of base hypothetically desired.
    /// @return fyTokenIn Amount of fyToken hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function getBuyBasePreview(IPool pool, uint256 baseOut) external returns (uint256 fyTokenIn, uint256 updateTime);

    /// Returns how much base would be required to buy `fyTokenOut`.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenOut Amount of fyToken hypothetically desired.
    /// @return baseIn Amount of base hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function getBuyFYTokenPreview(IPool pool, uint256 fyTokenOut) external returns (uint256 baseIn, uint256 updateTime);

    /// Returns how much fyToken would be obtained by selling `baseIn`.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseIn Amount of base hypothetically sold.
    /// @return fyTokenOut Amount of fyToken hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function getSellBasePreview(IPool pool, uint256 baseIn) external returns (uint256 fyTokenOut, uint256 updateTime);

    /// Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenIn Amount of fyToken hypothetically sold.
    /// @return baseOut Amount of base hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function getSellFYTokenPreview(IPool pool, uint256 fyTokenIn)
        external
        returns (uint256 baseOut, uint256 updateTime);

    /// Returns how much fyToken would be required to buy `baseOut` base.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseOut Amount of base hypothetically desired.
    /// @return fyTokenIn Amount of fyToken hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekBuyBasePreview(IPool pool, uint256 baseOut) external view returns (uint256 fyTokenIn, uint256 updateTime);

    /// Returns how much base would be required to buy `fyTokenOut`.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenOut Amount of fyToken hypothetically desired.
    /// @return baseIn Amount of base hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekBuyFYTokenPreview(IPool pool, uint256 fyTokenOut)
        external view
        returns (uint256 baseIn, uint256 updateTime);

    /// Returns how much fyToken would be obtained by selling `baseIn`.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseIn Amount of base hypothetically sold.
    /// @return fyTokenOut Amount of fyToken hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekSellBasePreview(IPool pool, uint256 baseIn) external view returns (uint256 fyTokenOut, uint256 updateTime);

    /// Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenIn Amount of fyToken hypothetically sold.
    /// @return baseOut Amount of base hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekSellFYTokenPreview(IPool pool, uint256 fyTokenIn)
        external view
        returns (uint256 baseOut, uint256 updateTime);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15; /*
   __     ___      _     _
   \ \   / (_)    | |   | | ███████╗██╗  ██╗██████╗  ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
    \ \_/ / _  ___| | __| | ██╔════╝╚██╗██╔╝██╔══██╗██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
     \   / | |/ _ \ |/ _` | █████╗   ╚███╔╝ ██████╔╝███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
      | |  | |  __/ | (_| | ██╔══╝   ██╔██╗ ██╔═══╝ ██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
      |_|  |_|\___|_|\__,_| ███████╗██╔╝ ██╗██║     ╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
                            Gas optimized math library custom-built by ABDK -- Copyright © 2019 */

import "./Math64x64.sol";

library Exp64x64 {
    using Math64x64 for int128;

    /// @dev Raises a 64.64 number to the power of another 64.64 number
    /// x^y = 2^(y*log_2(x))
    /// https://ethereum.stackexchange.com/questions/79903/exponential-function-with-fractional-numbers
    function pow(int128 x, int128 y) internal pure returns (int128) {
        return y.mul(x.log_2()).exp_2();
    }


    /* Mikhail Vladimirov, [Jul 6, 2022 at 12:26:12 PM (Jul 6, 2022 at 12:28:29 PM)]:
        In simple words, when have an n-bits wide number x and raise it to a power α, then the result would be α*n bits wide.  This, if α<1, the result will loose precision, and if α>1, the result could exceed range.

        So, the pow function multiplies the result by 2^(n * (1 - α)).  We have:

        x ∈ [0; 2^n)
        x^α ∈ [0; 2^(α*n))
        x^α * 2^(n * (1 - α)) ∈ [0; 2^(α*n) * 2^(n * (1 - α))) = [0; 2^(α*n + n * (1 - α))) = [0; 2^(n * (α +  (1 - α)))) =  [0; 2^n)

        So the normalization returns the result back into the proper range.

        Now note, that:

        pow (pow (x, α), 1/α) =
        pow (x^α * 2^(n * (1 -α)) , 1/α) =
        (x^α * 2^(n * (1 -α)))^(1/α) * 2^(n * (1 -1/α)) =
        x^(α * (1/α)) * 2^(n * (1 -α) * (1/α)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1) + n * (1 -1/α)) =
        x

        So, for formulas that look like:

        (a x^α + b y^α + ...)^(1/α)

        The pow function could be used instead of normal power. */
    /// @dev Raise given number x into power specified as a simple fraction y/z and then
    /// multiply the result by the normalization factor 2^(128 /// (1 - y/z)).
    /// Revert if z is zero, or if both x and y are zeros.
    /// @param x number to raise into given power y/z -- integer
    /// @param y numerator of the power to raise x into  -- 64.64
    /// @param z denominator of the power to raise x into  -- 64.64
    /// @return x raised into power y/z and then multiplied by 2^(128 * (1 - y/z)) -- integer
    function pow(
        uint128 x,
        uint128 y,
        uint128 z
    ) internal pure returns (uint128) {
        unchecked {
            require(z != 0);

            if (x == 0) {
                require(y != 0);
                return 0;
            } else {
                uint256 l = (uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - log_2(x)) * y) / z;
                if (l > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0;
                else return pow_2(uint128(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - l));
            }
        }
    }

    /// @dev Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert
    /// in case x is zero.
    /// @param x number to calculate base 2 logarithm of
    /// @return base 2 logarithm of x, multiplied by 2^121
    function log_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            require(x != 0);

            uint256 b = x;

            uint256 l = 0xFE000000000000000000000000000000;

            if (b < 0x10000000000000000) {
                l -= 0x80000000000000000000000000000000;
                b <<= 64;
            }
            if (b < 0x1000000000000000000000000) {
                l -= 0x40000000000000000000000000000000;
                b <<= 32;
            }
            if (b < 0x10000000000000000000000000000) {
                l -= 0x20000000000000000000000000000000;
                b <<= 16;
            }
            if (b < 0x1000000000000000000000000000000) {
                l -= 0x10000000000000000000000000000000;
                b <<= 8;
            }
            if (b < 0x10000000000000000000000000000000) {
                l -= 0x8000000000000000000000000000000;
                b <<= 4;
            }
            if (b < 0x40000000000000000000000000000000) {
                l -= 0x4000000000000000000000000000000;
                b <<= 2;
            }
            if (b < 0x80000000000000000000000000000000) {
                l -= 0x2000000000000000000000000000000;
                b <<= 1;
            }

            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000;
            } /*
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) l |= 0x1; */

            return uint128(l);
        }
    }

    /// @dev Calculate 2 raised into given power.
    /// @param x power to raise 2 into, multiplied by 2^121
    /// @return 2 raised into given power
    function pow_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            uint256 r = 0x80000000000000000000000000000000;
            if (x & 0x1000000000000000000000000000000 > 0) r = (r * 0xb504f333f9de6484597d89b3754abe9f) >> 127;
            if (x & 0x800000000000000000000000000000 > 0) r = (r * 0x9837f0518db8a96f46ad23182e42f6f6) >> 127;
            if (x & 0x400000000000000000000000000000 > 0) r = (r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90) >> 127;
            if (x & 0x200000000000000000000000000000 > 0) r = (r * 0x85aac367cc487b14c5c95b8c2154c1b2) >> 127;
            if (x & 0x100000000000000000000000000000 > 0) r = (r * 0x82cd8698ac2ba1d73e2a475b46520bff) >> 127;
            if (x & 0x80000000000000000000000000000 > 0) r = (r * 0x8164d1f3bc0307737be56527bd14def4) >> 127;
            if (x & 0x40000000000000000000000000000 > 0) r = (r * 0x80b1ed4fd999ab6c25335719b6e6fd20) >> 127;
            if (x & 0x20000000000000000000000000000 > 0) r = (r * 0x8058d7d2d5e5f6b094d589f608ee4aa2) >> 127;
            if (x & 0x10000000000000000000000000000 > 0) r = (r * 0x802c6436d0e04f50ff8ce94a6797b3ce) >> 127;
            if (x & 0x8000000000000000000000000000 > 0) r = (r * 0x8016302f174676283690dfe44d11d008) >> 127;
            if (x & 0x4000000000000000000000000000 > 0) r = (r * 0x800b179c82028fd0945e54e2ae18f2f0) >> 127;
            if (x & 0x2000000000000000000000000000 > 0) r = (r * 0x80058baf7fee3b5d1c718b38e549cb93) >> 127;
            if (x & 0x1000000000000000000000000000 > 0) r = (r * 0x8002c5d00fdcfcb6b6566a58c048be1f) >> 127;
            if (x & 0x800000000000000000000000000 > 0) r = (r * 0x800162e61bed4a48e84c2e1a463473d9) >> 127;
            if (x & 0x400000000000000000000000000 > 0) r = (r * 0x8000b17292f702a3aa22beacca949013) >> 127;
            if (x & 0x200000000000000000000000000 > 0) r = (r * 0x800058b92abbae02030c5fa5256f41fe) >> 127;
            if (x & 0x100000000000000000000000000 > 0) r = (r * 0x80002c5c8dade4d71776c0f4dbea67d6) >> 127;
            if (x & 0x80000000000000000000000000 > 0) r = (r * 0x8000162e44eaf636526be456600bdbe4) >> 127;
            if (x & 0x40000000000000000000000000 > 0) r = (r * 0x80000b1721fa7c188307016c1cd4e8b6) >> 127;
            if (x & 0x20000000000000000000000000 > 0) r = (r * 0x8000058b90de7e4cecfc487503488bb1) >> 127;
            if (x & 0x10000000000000000000000000 > 0) r = (r * 0x800002c5c8678f36cbfce50a6de60b14) >> 127;
            if (x & 0x8000000000000000000000000 > 0) r = (r * 0x80000162e431db9f80b2347b5d62e516) >> 127;
            if (x & 0x4000000000000000000000000 > 0) r = (r * 0x800000b1721872d0c7b08cf1e0114152) >> 127;
            if (x & 0x2000000000000000000000000 > 0) r = (r * 0x80000058b90c1aa8a5c3736cb77e8dff) >> 127;
            if (x & 0x1000000000000000000000000 > 0) r = (r * 0x8000002c5c8605a4635f2efc2362d978) >> 127;
            if (x & 0x800000000000000000000000 > 0) r = (r * 0x800000162e4300e635cf4a109e3939bd) >> 127;
            if (x & 0x400000000000000000000000 > 0) r = (r * 0x8000000b17217ff81bef9c551590cf83) >> 127;
            if (x & 0x200000000000000000000000 > 0) r = (r * 0x800000058b90bfdd4e39cd52c0cfa27c) >> 127;
            if (x & 0x100000000000000000000000 > 0) r = (r * 0x80000002c5c85fe6f72d669e0e76e411) >> 127;
            if (x & 0x80000000000000000000000 > 0) r = (r * 0x8000000162e42ff18f9ad35186d0df28) >> 127;
            if (x & 0x40000000000000000000000 > 0) r = (r * 0x80000000b17217f84cce71aa0dcfffe7) >> 127;
            if (x & 0x20000000000000000000000 > 0) r = (r * 0x8000000058b90bfc07a77ad56ed22aaa) >> 127;
            if (x & 0x10000000000000000000000 > 0) r = (r * 0x800000002c5c85fdfc23cdead40da8d6) >> 127;
            if (x & 0x8000000000000000000000 > 0) r = (r * 0x80000000162e42fefc25eb1571853a66) >> 127;
            if (x & 0x4000000000000000000000 > 0) r = (r * 0x800000000b17217f7d97f692baacded5) >> 127;
            if (x & 0x2000000000000000000000 > 0) r = (r * 0x80000000058b90bfbead3b8b5dd254d7) >> 127;
            if (x & 0x1000000000000000000000 > 0) r = (r * 0x8000000002c5c85fdf4eedd62f084e67) >> 127;
            if (x & 0x800000000000000000000 > 0) r = (r * 0x800000000162e42fefa58aef378bf586) >> 127;
            if (x & 0x400000000000000000000 > 0) r = (r * 0x8000000000b17217f7d24a78a3c7ef02) >> 127;
            if (x & 0x200000000000000000000 > 0) r = (r * 0x800000000058b90bfbe9067c93e474a6) >> 127;
            if (x & 0x100000000000000000000 > 0) r = (r * 0x80000000002c5c85fdf47b8e5a72599f) >> 127;
            if (x & 0x80000000000000000000 > 0) r = (r * 0x8000000000162e42fefa3bdb315934a2) >> 127;
            if (x & 0x40000000000000000000 > 0) r = (r * 0x80000000000b17217f7d1d7299b49c46) >> 127;
            if (x & 0x20000000000000000000 > 0) r = (r * 0x8000000000058b90bfbe8e9a8d1c4ea0) >> 127;
            if (x & 0x10000000000000000000 > 0) r = (r * 0x800000000002c5c85fdf4745969ea76f) >> 127;
            if (x & 0x8000000000000000000 > 0) r = (r * 0x80000000000162e42fefa3a0df5373bf) >> 127;
            if (x & 0x4000000000000000000 > 0) r = (r * 0x800000000000b17217f7d1cff4aac1e1) >> 127;
            if (x & 0x2000000000000000000 > 0) r = (r * 0x80000000000058b90bfbe8e7db95a2f1) >> 127;
            if (x & 0x1000000000000000000 > 0) r = (r * 0x8000000000002c5c85fdf473e61ae1f8) >> 127;
            if (x & 0x800000000000000000 > 0) r = (r * 0x800000000000162e42fefa39f121751c) >> 127;
            if (x & 0x400000000000000000 > 0) r = (r * 0x8000000000000b17217f7d1cf815bb96) >> 127;
            if (x & 0x200000000000000000 > 0) r = (r * 0x800000000000058b90bfbe8e7bec1e0d) >> 127;
            if (x & 0x100000000000000000 > 0) r = (r * 0x80000000000002c5c85fdf473dee5f17) >> 127;
            if (x & 0x80000000000000000 > 0) r = (r * 0x8000000000000162e42fefa39ef5438f) >> 127;
            if (x & 0x40000000000000000 > 0) r = (r * 0x80000000000000b17217f7d1cf7a26c8) >> 127;
            if (x & 0x20000000000000000 > 0) r = (r * 0x8000000000000058b90bfbe8e7bcf4a4) >> 127;
            if (x & 0x10000000000000000 > 0) r = (r * 0x800000000000002c5c85fdf473de72a2) >> 127; /*
      if(x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
      if(x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
      if(x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
      if(x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
      if(x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
      if(x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
      if(x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
      if(x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
      if(x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
      if(x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
      if(x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
      if(x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
      if(x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
      if(x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
      if(x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
      if(x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
      if(x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
      if(x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
      if(x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
      if(x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
      if(x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
      if(x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
      if(x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
      if(x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
      if(x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
      if(x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
      if(x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
      if(x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
      if(x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
      if(x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
      if(x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
      if(x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
      if(x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
      if(x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
      if(x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
      if(x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
      if(x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
      if(x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
      if(x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
      if(x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
      if(x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
      if(x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
      if(x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
      if(x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
      if(x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
      if(x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
      if(x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
      if(x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
      if(x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
      if(x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
      if(x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
      if(x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
      if(x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
      if(x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
      if(x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
      if(x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
      if(x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
      if(x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
      if(x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
      if(x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
      if(x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
      if(x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
      if(x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
      if(x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127; */

            r >>= 127 - (x >> 121);

            return uint128(r);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15; /*
  __     ___      _     _
  \ \   / (_)    | |   | |  ███╗   ███╗ █████╗ ████████╗██╗  ██╗ ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
   \ \_/ / _  ___| | __| |  ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
    \   / | |/ _ \ |/ _` |  ██╔████╔██║███████║   ██║   ███████║███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
     | |  | |  __/ | (_| |  ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
     |_|  |_|\___|_|\__,_|  ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
*/

/// Smart contract library of mathematical functions operating with signed
/// 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
/// basically a simple fraction whose numerator is signed 128-bit integer and
/// denominator is 2^64.  As long as denominator is always the same, there is no
/// need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
/// represented by int128 type holding only the numerator.
/// @title  Math64x64.sol
/// @author Mikhail Vladimirov - ABDK Consulting
/// https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
library Math64x64 {
    /* CONVERTERS
     ******************************************************************************************************************/
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev Convert signed 256-bit integer number into signed 64.64-bit fixed point
    /// number.  Revert on overflow.
    /// @param x signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 64-bit integer number rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64-bit integer number
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /// @dev Convert unsigned 256-bit integer number into signed 64.64-bit fixed point number.  Revert on overflow.
    /// @param x unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /// @dev Convert signed 64.64 fixed point number into unsigned 64-bit integer number rounding down.
    /// Reverts on underflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return unsigned 64-bit integer number
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /// @dev Convert signed 128.128 fixed point number into signed 64.64-bit fixed point number rounding down.
    /// Reverts on overflow.
    /// @param x signed 128.128-bin fixed point number
    /// @return signed 64.64-bit fixed point number
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 128.128 fixed point number.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 128.128 fixed point number
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /* OPERATIONS
     ******************************************************************************************************************/

    /// @dev Calculate x + y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x - y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x///y rounding down.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
    /// number and y is signed 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y signed 256-bit integer number
    /// @return signed 256-bit integer number
    function muli(int128 x, int256 y) internal pure returns (int256) {
        //NOTE: This reverts if y == type(int128).min
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(absoluteResult <= 0x8000000000000000000000000000000000000000000000000000000000000000);
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                    return int256(absoluteResult);
                }
            }
        }
    }

    /// @dev Calculate x * y rounding down, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 256-bit integer number
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /// @dev Calculate x / y rounding towards zero.  Revert on overflow or when y is zero.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are signed 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x signed 256-bit integer number
    /// @param y signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /// @dev Calculate -x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /// @dev Calculate |x|.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /// @dev Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
    ///zero.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /// @dev Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
    /// Revert on overflow or in case x * y is negative.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
            return int128(sqrtu(uint256(m)));
        }
    }

    /// @dev Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// also see:https://hackmd.io/gbnqA3gCTR6z-F0HHTxF-A#33-Normalized-Fractional-Exponentiation
    /// @param x signed 64.64-bit fixed point number
    /// @param y uint256 value
    /// @return signed 64.64-bit fixed point number
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down.  Revert if x < 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /// @dev Calculate binary logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /// @dev Calculate natural logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return int128(int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128));
        }
    }

    /// @dev Calculate binary exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /// @dev Calculate natural exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 64.64-bit fixed point number
    function divuu(uint256 x, uint256 y) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer number.
    /// @param x unsigned 256-bit integer number
    /// @return unsigned 128-bit integer number
    function sqrtu(uint256 x) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing

        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import {IMaturingToken} from "./IMaturingToken.sol";
import {IERC20Metadata} from  "@yield-protocol/utils-v2/contracts/token/ERC20.sol";

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns(IERC20Metadata);
    function base() external view returns(IERC20);
    function burn(address baseTo, address fyTokenTo, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function currentCumulativeRatio() external view returns (uint256 currentCumulativeRatio_, uint256 blockTimestampCurrent);
    function cumulativeRatioLast() external view returns (uint256);
    function fyToken() external view returns(IMaturingToken);
    function g1() external view returns(int128);
    function g2() external view returns(int128);
    function getC() external view returns (int128);
    function getCurrentSharePrice() external view returns (uint256);
    function getCache() external view returns (uint104 baseCached, uint104 fyTokenCached, uint32 blockTimestampLast, uint16 g1Fee_);
    function getBaseBalance() external view returns(uint128);
    function getFYTokenBalance() external view returns(uint128);
    function getSharesBalance() external view returns(uint128);
    function init(address to) external returns (uint256, uint256, uint256);
    function maturity() external view returns(uint32);
    function mint(address to, address remainder, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function mu() external view returns (int128);
    function mintWithBase(address to, address remainder, uint256 fyTokenToBuy, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function retrieveShares(address to) external returns(uint128 retrieved);
    function scaleFactor() external view returns(uint96);
    function sellBase(address to, uint128 min) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function setFees(uint16 g1Fee_) external;
    function sharesToken() external view returns(IERC20Metadata);
    function ts() external view returns(int128);
    function wrap(address receiver) external returns (uint256 shares);
    function wrapPreview(uint256 assets) external view returns (uint256 shares);
    function unwrap(address receiver) external returns (uint256 assets);
    function unwrapPreview(uint256 shares) external view returns (uint256 assets);
    /// Returns the max amount of FYTokens that can be sold to the pool
    function maxFYTokenIn() external view returns (uint128) ;
    /// Returns the max amount of FYTokens that can be bought from the pool
    function maxFYTokenOut() external view returns (uint128) ;
    /// Returns the max amount of Base that can be sold to the pool
    function maxBaseIn() external view returns (uint128) ;
    /// Returns the max amount of Base that can be bought from the pool
    function maxBaseOut() external view returns (uint128);
    /// Returns the result of the total supply invariant function
    function invariant() external view returns (uint128);
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
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}