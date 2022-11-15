//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleSidechain, IOracleFactory} from '../interfaces/IOracleSidechain.sol';
import {Oracle} from '@uniswap/v3-core/contracts/libraries/Oracle.sol';
import {TickMath} from '@uniswap/v3-core/contracts/libraries/TickMath.sol';

/// @title The SidechainOracle contract
/// @notice Computes and stores on-chain price data from Mainnet
contract OracleSidechain is IOracleSidechain {
  using Oracle for Oracle.Observation[65535];

  /// @inheritdoc IOracleSidechain
  IOracleFactory public immutable factory;

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
  /// @inheritdoc IOracleSidechain
  Slot0 public slot0;

  /// @inheritdoc IOracleSidechain
  Oracle.Observation[65535] public observations;

  /// @inheritdoc IOracleSidechain
  bytes32 public immutable poolSalt;

  uint24 public poolNonce;
  /// @inheritdoc IOracleSidechain
  address public token0;
  /// @inheritdoc IOracleSidechain
  address public token1;
  /// @inheritdoc IOracleSidechain
  uint24 public fee;

  /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
  function _getBlockTimestamp() internal view virtual returns (uint32) {
    return uint32(block.timestamp); // truncation is desired
  }

  constructor() {
    factory = IOracleFactory(msg.sender);
    uint16 _cardinality;
    (poolSalt, poolNonce, _cardinality) = factory.oracleParameters();

    slot0 = Slot0({
      sqrtPriceX96: 0,
      tick: 0,
      observationIndex: _cardinality - 1,
      observationCardinality: _cardinality,
      observationCardinalityNext: _cardinality,
      feeProtocol: 0,
      unlocked: true
    });
  }

  /// @inheritdoc IOracleSidechain
  function initializePoolInfo(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external {
    if (!slot0.unlocked) revert AI();

    (address _token0, address _token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
    if (poolSalt != keccak256(abi.encode(_token0, _token1, _fee))) revert InvalidPool();

    token0 = _token0;
    token1 = _token1;
    fee = _fee;
    slot0.unlocked = false;

    emit PoolInfoInitialized(poolSalt, _token0, _token1, _fee);
  }

  /// @inheritdoc IOracleSidechain
  function observe(uint32[] calldata _secondsAgos)
    external
    view
    returns (int56[] memory _tickCumulatives, uint160[] memory _secondsPerLiquidityCumulativeX128s)
  {
    return observations.observe(_getBlockTimestamp(), _secondsAgos, slot0.tick, slot0.observationIndex, 0, slot0.observationCardinality);
  }

  /// @inheritdoc IOracleSidechain
  function write(ObservationData[] memory _observationsData, uint24 _poolNonce) external onlyDataReceiver returns (bool _written) {
    if (_poolNonce != poolNonce++) return false;

    uint256 _observationsDataLength = _observationsData.length;
    for (uint256 _i; _i < _observationsDataLength; ) {
      _write(_observationsData[_i]);
      unchecked {
        ++_i;
      }
    }
    slot0.sqrtPriceX96 = TickMath.getSqrtRatioAtTick(slot0.tick);

    // emits UniV3 Swap event topic with minimal data
    emit Swap(address(0), address(0), 0, 0, slot0.sqrtPriceX96, 0, slot0.tick);
    return true;
  }

  function increaseObservationCardinalityNext(uint16 _observationCardinalityNext) external onlyFactory {
    uint16 _observationCardinalityNextOld = slot0.observationCardinalityNext;
    if (_observationCardinalityNext <= _observationCardinalityNextOld) return;
    slot0.observationCardinalityNext = _observationCardinalityNext;
    emit IncreaseObservationCardinalityNext(_observationCardinalityNextOld, _observationCardinalityNext);
  }

  function _write(ObservationData memory _observationData) private {
    (uint16 _indexUpdated, uint16 _cardinalityUpdated) = observations.write(
      slot0.observationIndex,
      _observationData.blockTimestamp,
      slot0.tick,
      0,
      slot0.observationCardinality,
      slot0.observationCardinalityNext
    );
    (slot0.observationIndex, slot0.observationCardinality) = (_indexUpdated, _cardinalityUpdated);
    slot0.tick = _observationData.tick;
  }

  modifier onlyDataReceiver() {
    if (msg.sender != address(factory.dataReceiver())) revert OnlyDataReceiver();
    _;
  }

  modifier onlyFactory() {
    if (msg.sender != address(factory)) revert OnlyFactory();
    _;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleFactory} from './IOracleFactory.sol';

interface IOracleSidechain {
  // STRUCTS

  struct ObservationData {
    uint32 blockTimestamp;
    int24 tick;
  }

  // STATE VARIABLES

  // TODO: complete natspec

  /// @return _oracleFactory The address of the OracleFactory
  function factory() external view returns (IOracleFactory _oracleFactory);

  /// @return _token0 The mainnet address of the Token0 of the oracle
  function token0() external view returns (address _token0);

  /// @return _token1 The mainnet address of the Token1 of the oracle
  function token1() external view returns (address _token1);

  /// @return _fee The fee identifier of the pool
  function fee() external view returns (uint24 _fee);

  /// @return _poolSalt The identifier of both the pool and the oracle
  function poolSalt() external view returns (bytes32 _poolSalt);

  /// @return _poolNonce Last recorded nonce of the pool history
  function poolNonce() external view returns (uint24 _poolNonce);

  /// @notice Replicates the UniV3Pool slot0 behaviour (semi-compatible)
  /// @return _sqrtPriceX96 Used to maintain compatibility with Uniswap V3
  /// @return _tick Used to maintain compatibility with Uniswap V3
  /// @return _observationIndex The index of the last oracle observation that was written,
  /// @return _observationCardinality The current maximum number of observations stored in the pool,
  /// @return _observationCardinalityNext The next maximum number of observations, to be updated when the observation.
  /// @return _feeProtocol Used to maintain compatibility with Uniswap V3
  /// @return _unlocked Used to track if a pool information was already verified
  function slot0()
    external
    view
    returns (
      uint160 _sqrtPriceX96,
      int24 _tick,
      uint16 _observationIndex,
      uint16 _observationCardinality,
      uint16 _observationCardinalityNext,
      uint8 _feeProtocol,
      bool _unlocked
    );

  /// @notice Returns data about a specific observation index
  /// @param _index The element of the observations array to fetch
  /// @return _blockTimestamp The timestamp of the observation,
  /// @return _tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
  /// @return _secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
  /// @return _initialized whether the observation has been initialized and the values are safe to use
  function observations(uint256 _index)
    external
    view
    returns (
      uint32 _blockTimestamp,
      int56 _tickCumulative,
      uint160 _secondsPerLiquidityCumulativeX128,
      bool _initialized
    );

  // EVENTS

  /// @notice Emitted when the pool information is verified
  /// @param _poolSalt Identifier of the pool and the oracle
  /// @param _token0 The contract address of either token0 or token1
  /// @param _token1 The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  event PoolInfoInitialized(bytes32 indexed _poolSalt, address _token0, address _token1, uint24 _fee);

  /// @notice Emitted by the oracle to hint indexers that the pool state has changed
  /// @dev Imported from IUniswapV3PoolEvents (semi-compatible)
  /// @param _sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
  /// @param _tick The log base 1.0001 of price of the pool after the swap
  event Swap(address indexed, address indexed, int256, int256, uint160 _sqrtPriceX96, uint128, int24 _tick);

  /// @notice Emitted by the oracle for increases to the number of observations that can be stored
  /// @dev Imported from IUniswapV3PoolEvents (fully-compatible)
  /// @param _observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param _observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(uint16 _observationCardinalityNextOld, uint16 _observationCardinalityNextNew);

  // ERRORS

  error AI();
  error InvalidPool();
  error OnlyDataReceiver();
  error OnlyFactory();

  // FUNCTIONS

  /// @notice Permisionless method to verify token0, token1 and fee
  /// @dev Before verified, token0 and token1 views will return address(0)
  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  function initializePoolInfo(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external;

  /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
  /// @dev Imported from UniV3Pool (semi compatible, optimistically extrapolates)
  /// @param _secondsAgos From how long ago each cumulative tick and liquidity value should be returned
  /// @return _tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
  /// @return _secondsCumulativeX128s Cumulative seconds as of each `secondsAgos` from the current block timestamp
  function observe(uint32[] calldata _secondsAgos)
    external
    view
    returns (int56[] memory _tickCumulatives, uint160[] memory _secondsCumulativeX128s);

  /// @notice Permisioned method to push a dataset to update
  /// @param _observationsData Array of tuples containing the dataset
  /// @param _poolNonce Nonce of the observation broadcast
  function write(ObservationData[] memory _observationsData, uint24 _poolNonce) external returns (bool _written);

  /// @notice Permisioned method to increase the cardinalityNext value
  /// @param _observationCardinalityNext The new next length of the observations array
  function increaseObservationCardinalityNext(uint16 _observationCardinalityNext) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Oracle
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library Oracle {
    error I();
    error OLD();

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

    /// @notice Transforms a previous observation into a new observation, given the passage of time and the current tick and liquidity values
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param last The specified observation to be transformed
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @return Observation The newly populated observation
    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity
    ) private pure returns (Observation memory) {
        unchecked {
            uint32 delta = blockTimestamp - last.blockTimestamp;
            return
                Observation({
                    blockTimestamp: blockTimestamp,
                    tickCumulative: last.tickCumulative + int56(tick) * int56(uint56(delta)),
                    secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
                        ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
                    initialized: true
                });
        }
    }

    /// @notice Initialize the oracle array by writing the first slot. Called once for the lifecycle of the observations array
    /// @param self The stored oracle array
    /// @param time The time of the oracle initialization, via block.timestamp truncated to uint32
    /// @return cardinality The number of populated elements in the oracle array
    /// @return cardinalityNext The new length of the oracle array, independent of population
    function initialize(Observation[65535] storage self, uint32 time)
        internal
        returns (uint16 cardinality, uint16 cardinalityNext)
    {
        self[0] = Observation({
            blockTimestamp: time,
            tickCumulative: 0,
            secondsPerLiquidityCumulativeX128: 0,
            initialized: true
        });
        return (1, 1);
    }

    /// @notice Writes an oracle observation to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. cardinality and index must be tracked externally.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored oracle array
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @param cardinality The number of populated elements in the oracle array
    /// @param cardinalityNext The new length of the oracle array, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        unchecked {
            Observation memory last = self[index];

            // early return if we've already written an observation this block
            if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

            // if the conditions are right, we can bump the cardinality
            if (cardinalityNext > cardinality && index == (cardinality - 1)) {
                cardinalityUpdated = cardinalityNext;
            } else {
                cardinalityUpdated = cardinality;
            }

            indexUpdated = (index + 1) % cardinalityUpdated;
            self[indexUpdated] = transform(last, blockTimestamp, tick, liquidity);
        }
    }

    /// @notice Prepares the oracle array to store up to `next` observations
    /// @param self The stored oracle array
    /// @param current The current next cardinality of the oracle array
    /// @param next The proposed next cardinality which will be populated in the oracle array
    /// @return next The next cardinality which will be populated in the oracle array
    function grow(
        Observation[65535] storage self,
        uint16 current,
        uint16 next
    ) internal returns (uint16) {
        unchecked {
            if (current <= 0) revert I();
            // no-op if the passed next value isn't greater than the current next value
            if (next <= current) return current;
            // store in each slot to prevent fresh SSTOREs in swaps
            // this data will not be used because the initialized boolean is still false
            for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
            return next;
        }
    }

    /// @notice comparator for 32-bit timestamps
    /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to time
    /// @param time A timestamp truncated to 32 bits
    /// @param a A comparison timestamp from which to determine the relative position of `time`
    /// @param b From which to determine the relative position of `time`
    /// @return Whether `a` is chronologically <= `b`
    function lte(
        uint32 time,
        uint32 a,
        uint32 b
    ) private pure returns (bool) {
        unchecked {
            // if there hasn't been overflow, no need to adjust
            if (a <= time && b <= time) return a <= b;

            uint256 aAdjusted = a > time ? a : a + 2**32;
            uint256 bAdjusted = b > time ? b : b + 2**32;

            return aAdjusted <= bAdjusted;
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same observation, or adjacent observations.
    /// @dev The answer must be contained in the array, used when the target is located within the stored observation
    /// boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation recorded before, or at, the target
    /// @return atOrAfter The observation recorded at, or after, the target
    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        unchecked {
            uint256 l = (index + 1) % cardinality; // oldest observation
            uint256 r = l + cardinality - 1; // newest observation
            uint256 i;
            while (true) {
                i = (l + r) / 2;

                beforeOrAt = self[i % cardinality];

                // we've landed on an uninitialized tick, keep searching higher (more recently)
                if (!beforeOrAt.initialized) {
                    l = i + 1;
                    continue;
                }

                atOrAfter = self[(i + 1) % cardinality];

                bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

                // check if we've found the answer!
                if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

                if (!targetAtOrAfter) r = i - 1;
                else l = i + 1;
            }
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized observation.
    /// Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param tick The active tick at the time of the returned or simulated observation
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The total pool liquidity at the time of the call
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation which occurred at, or before, the given timestamp
    /// @return atOrAfter The observation which occurred at, or after, the given timestamp
    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        unchecked {
            // optimistically set before to the newest observation
            beforeOrAt = self[index];

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
            beforeOrAt = self[(index + 1) % cardinality];
            if (!beforeOrAt.initialized) beforeOrAt = self[0];

            // ensure that the target is chronologically at or after the oldest observation
            if (!lte(time, beforeOrAt.blockTimestamp, target)) revert OLD();

            // if we've reached this point, we have to binary search
            return binarySearch(self, time, target, index, cardinality);
        }
    }

    /// @dev Reverts if an observation at or before the desired observation timestamp does not exist.
    /// 0 may be passed as `secondsAgo' to return the current cumulative values.
    /// If called with a timestamp falling between two observations, returns the counterfactual accumulator values
    /// at exactly the timestamp between the two observations.
    /// @param self The stored oracle array
    /// @param time The current block timestamp
    /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulative The tick * time elapsed since the pool was first initialized, as of `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128 The time elapsed / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint16 cardinality
    ) internal view returns (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) {
        unchecked {
            if (secondsAgo == 0) {
                Observation memory last = self[index];
                if (last.blockTimestamp != time) last = transform(last, time, tick, liquidity);
                return (last.tickCumulative, last.secondsPerLiquidityCumulativeX128);
            }

            uint32 target = time - secondsAgo;

            (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(
                self,
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
                        ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / int56(uint56(observationTimeDelta))) *
                        int56(uint56(targetDelta)),
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
    }

    /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
    /// @dev Reverts if `secondsAgos` > oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128s The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint16 cardinality
    ) internal view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) {
        unchecked {
            if (cardinality <= 0) revert I();

            tickCumulatives = new int56[](secondsAgos.length);
            secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);
            for (uint256 i = 0; i < secondsAgos.length; i++) {
                (tickCumulatives[i], secondsPerLiquidityCumulativeX128s[i]) = observeSingle(
                    self,
                    time,
                    secondsAgos[i],
                    tick,
                    index,
                    liquidity,
                    cardinality
                );
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

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
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
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
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from './peripherals/IGovernable.sol';
import {IOracleSidechain} from './IOracleSidechain.sol';
import {IDataReceiver} from './IDataReceiver.sol';

interface IOracleFactory is IGovernable {
  // STRUCTS

  struct OracleParameters {
    bytes32 poolSalt; // Identifier of the pool and oracle
    uint24 poolNonce; // Initial nonce of the deployed pool
    uint16 cardinality; // Initial cardinality of the deployed pool
  }

  // STATE VARIABLES

  /// @return _oracleInitCodeHash The oracle creation code hash used to calculate their address
  //solhint-disable-next-line func-name-mixedcase
  function ORACLE_INIT_CODE_HASH() external view returns (bytes32 _oracleInitCodeHash);

  /// @return _dataReceiver The address of the DataReceiver for the oracles to consult
  function dataReceiver() external view returns (IDataReceiver _dataReceiver);

  /// @return _poolSalt The id of both the oracle and the pool
  /// @return _poolNonce The initial nonce of the pool data
  /// @return _cardinality The size of the observations memory storage
  function oracleParameters()
    external
    view
    returns (
      bytes32 _poolSalt,
      uint24 _poolNonce,
      uint16 _cardinality
    );

  /// @return _initialCardinality The initial size of the observations memory storage for newly deployed pools
  function initialCardinality() external view returns (uint16 _initialCardinality);

  // EVENTS

  /// @notice Emitted when a new oracle is deployed
  /// @param _poolSalt The id of both the oracle and the pool
  /// @param _oracle The address of the deployed oracle
  /// @param _initialNonce The initial nonce of the pool data
  event OracleDeployed(bytes32 indexed _poolSalt, address indexed _oracle, uint24 _initialNonce);

  /// @notice Emitted when a new DataReceiver is set
  /// @param _dataReceiver The address of the new DataReceiver
  event DataReceiverSet(IDataReceiver _dataReceiver);

  /// @notice Emitted when a new initial oracle cardinality is set
  /// @param _initialCardinality The initial length of the observationCardinality array
  event InitialCardinalitySet(uint16 _initialCardinality);

  // ERRORS

  /// @notice Thrown when a contract other than the DataReceiver tries to deploy an oracle
  error OnlyDataReceiver();

  // FUNCTIONS

  /// @notice Deploys a new oracle given an inputted salt
  /// @dev Requires that the salt has not been deployed before
  /// @param _poolSalt Pool salt that deterministically binds an oracle with a pool
  /// @return _oracle The address of the newly deployed oracle
  function deployOracle(bytes32 _poolSalt, uint24 _poolNonce) external returns (IOracleSidechain _oracle);

  /// @notice Allows governor to set a new allowed dataReceiver
  /// @dev Will disallow the previous dataReceiver
  /// @param _dataReceiver The address of the new allowed dataReceiver
  function setDataReceiver(IDataReceiver _dataReceiver) external;

  /// @notice Allows governor to set a new initial cardinality for new oracles
  /// @param _initialCardinality The initial size of the observations memory storage for newly deployed pools
  function setInitialCardinality(uint16 _initialCardinality) external;

  /// @notice Overrides UniV3Factory getPool mapping
  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  /// @return _oracle The oracle address
  function getPool(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external view returns (IOracleSidechain _oracle);

  /// @notice Tracks the addresses of the oracle by poolSalt
  /// @param _poolSalt Identifier of both the pool and the oracle
  /// @return _oracle The address (if deployed) of the correspondant oracle
  function getPool(bytes32 _poolSalt) external view returns (IOracleSidechain _oracle);

  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  /// @return _poolSalt Pool salt for inquired parameters
  function getPoolSalt(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external view returns (bytes32 _poolSalt);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from './peripherals/IGovernable.sol';
import {IOracleFactory} from './IOracleFactory.sol';
import {IOracleSidechain} from './IOracleSidechain.sol';
import {IBridgeReceiverAdapter} from './bridges/IBridgeReceiverAdapter.sol';

interface IDataReceiver is IGovernable {
  // STATE VARIABLES

  /// @return _oracleFactory The address of the OracleFactory
  function oracleFactory() external view returns (IOracleFactory _oracleFactory);

  /// @notice Tracks already deployed oracles
  /// @param _poolSalt The identifier of the oracle
  /// @return _deployedOracle The address of the correspondant Oracle
  function deployedOracles(bytes32 _poolSalt) external view returns (IOracleSidechain _deployedOracle);

  /// @notice Tracks the whitelisting of bridge adapters
  /// @param _adapter Address of the bridge adapter to consult
  /// @return _isAllowed Whether a bridge adapter is whitelisted
  function whitelistedAdapters(IBridgeReceiverAdapter _adapter) external view returns (bool _isAllowed);

  /// @return _oracleInitCodeHash The oracle creation code hash used to calculate their address
  //solhint-disable-next-line func-name-mixedcase
  function ORACLE_INIT_CODE_HASH() external view returns (bytes32 _oracleInitCodeHash);

  // EVENTS

  /// @notice Emitted when a broadcast observation is succesfully processed
  /// @param _poolSalt Identifier of the pool to fetch
  /// @return _poolNonce Nonce of the observation broadcast
  /// @return _observationsData Array of tuples containing the dataset
  /// @return _receiverAdapter Handler of the broadcast
  event ObservationsAdded(
    bytes32 indexed _poolSalt,
    uint24 _poolNonce,
    IOracleSidechain.ObservationData[] _observationsData,
    address _receiverAdapter
  );

  /// @notice Emitted when a new adapter whitelisting rule is set
  /// @param _adapter Address of the adapter
  /// @param _isAllowed New whitelisting status
  event AdapterWhitelisted(IBridgeReceiverAdapter _adapter, bool _isAllowed);

  // ERRORS

  /// @notice Thrown when the broadcast nonce is incorrect
  error ObservationsNotWritable();

  /// @notice Thrown when a not-whitelisted adapter triggers an update
  error UnallowedAdapter();

  /// @notice Thrown when mismatching lists length
  error LengthMismatch();

  // FUNCTIONS

  /// @notice Allows whitelisted bridge adapters to push a broadcast
  /// @param _observationsData Array of tuples containing the dataset
  /// @param _poolSalt Identifier of the pool to fetch
  /// @param _poolNonce Nonce of the observation broadcast
  function addObservations(
    IOracleSidechain.ObservationData[] memory _observationsData,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) external;

  /// @notice Allows governance to set an adapter whitelisted state
  /// @param _receiverAdapter Address of the adapter
  /// @param _isWhitelisted New whitelisting status
  function whitelistAdapter(IBridgeReceiverAdapter _receiverAdapter, bool _isWhitelisted) external;

  /// @notice Allows governance to batch set adapters whitelisted state
  /// @param _receiverAdapters Array of addresses of the adapter
  /// @param _isWhitelisted Array of whitelisting status for each address
  function whitelistAdapters(IBridgeReceiverAdapter[] calldata _receiverAdapters, bool[] calldata _isWhitelisted) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

interface IGovernable {
  // STATE VARIABLES

  /// @return _governor Address of the current governor
  function governor() external view returns (address _governor);

  /// @return _pendingGovernor Address of the current pending governor
  function pendingGovernor() external view returns (address _pendingGovernor);

  // EVENTS

  /// @notice Emitted when a new pending governor is set
  /// @param _governor Address of the current governor
  /// @param _pendingGovernor Address of the proposed next governor
  event PendingGovernorSet(address _governor, address _pendingGovernor);

  /// @notice Emitted when a new governor is set
  /// @param _newGovernor Address of the new governor
  event PendingGovernorAccepted(address _newGovernor);

  // ERRORS

  /// @notice Throws if a variable is assigned to the zero address
  error ZeroAddress();

  /// @notice Throws if a non-governor user tries to call a OnlyGovernor function
  error OnlyGovernor();

  /// @notice Throws if a non-pending-governor user tries to call a OnlyPendingGovernor function
  error OnlyPendingGovernor();

  // FUNCTIONS

  /// @notice Allows a governor to propose a new governor
  /// @param _pendingGovernor Address of the proposed new governor
  function setPendingGovernor(address _pendingGovernor) external;

  /// @notice Allows a proposed governor to accept the governance
  function acceptPendingGovernor() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IDataReceiver} from '../IDataReceiver.sol';
import {IOracleSidechain} from '../IOracleSidechain.sol';

interface IBridgeReceiverAdapter {
  // FUNCTIONS

  function dataReceiver() external view returns (IDataReceiver _dataReceiver);

  /* NOTE: callback methods should be here declared */

  // ERRORS

  error UnauthorizedCaller();
}