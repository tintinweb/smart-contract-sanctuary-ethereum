//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {Oracle} from '@uniswap/v3-core/contracts/libraries/Oracle.sol';
import {IOracleSidechain} from '../interfaces/IOracleSidechain.sol';
import {IOracleFactory} from '../interfaces/IOracleFactory.sol';

/// @title A sidechain oracle contract
/// @author 0xJabberwock (from DeFi Wonderland)
/// @notice Computes on-chain price data from Mainnet
/// @dev Bridges Uniswap V3 pool observations
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
    uint16 _cardinality;
    // TODO: remove factory from parameters (use msg.sender)
    (factory, poolSalt, poolNonce, _cardinality) = IOracleFactory(msg.sender).oracleParameters();

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

  /*
   * NOTE: public function that allows signer to register token0, token1 and fee
   *       before someone registers, oracle can be found with poolSalt, but token0 and token1 views will return address(0)
   */
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
    for (uint256 _i; _i < _observationsDataLength; ++_i) {
      _write(_observationsData[_i]);
    }
    return true;
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
    emit ObservationWritten(msg.sender, _observationData);
  }

  modifier onlyDataReceiver() {
    if (msg.sender != address(factory.dataReceiver())) revert OnlyDataReceiver();
    _;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleSidechain} from './IOracleSidechain.sol';
import {IDataReceiver} from './IDataReceiver.sol';
import {IGovernable} from './peripherals/IGovernable.sol';

interface IOracleFactory is IGovernable {
  // STRUCTS

  struct OracleParameters {
    IOracleFactory factory;
    bytes32 poolSalt;
    uint24 poolNonce;
    uint16 cardinality;
  }

  // STATE VARIABLES

  function dataReceiver() external view returns (IDataReceiver _dataReceiver);

  /// @return _factory The address of the deployer factory
  /// @return _poolSalt The id of both the oracle and the pool
  /// @return _poolNonce The initial nonce of the pool data
  /// @return _cardinality The size of the observations memory storage
  function oracleParameters()
    external
    view
    returns (
      IOracleFactory _factory,
      bytes32 _poolSalt,
      uint24 _poolNonce,
      uint16 _cardinality
    );

  /// @return _initialCardinality The initial size of the observations memory storage for newly deployed pools
  function initialCardinality() external view returns (uint16 _initialCardinality);

  // EVENTS

  event OracleDeployed(address _oracle, bytes32 _poolSalt, uint16 _cardinality);
  event DataReceiverSet(IDataReceiver _dataReceiver);

  event InitialCardinalitySet(uint16 _initialCardinality);

  // ERRORS

  error OnlyDataReceiver();

  // VIEWS

  /// @notice Overrides UniV3Factory getPool mapping
  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  /// @return _oracle The oracle address
  function getPool(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external view returns (address _oracle);

  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  /// @return _poolSalt Pool salt for inquired parameters
  function getPoolSalt(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external view returns (bytes32 _poolSalt);

  // FUNCTIONS

  /// @notice Deploys a new oracle given an inputted salt
  /// @dev Requires that the salt has not been deployed before
  /// @param _poolSalt Pool salt that deterministically binds an oracle with a pool
  /// @return _deployedOracle The address of the newly deployed oracle
  function deployOracle(bytes32 _poolSalt, uint24 _poolNonce) external returns (address _deployedOracle);

  /// @notice Allows governor to set a new allowed dataReceiver
  /// @dev Will disallow the previous dataReceiver
  /// @param _dataReceiver The address of the new allowed dataReceiver
  function setDataReceiver(IDataReceiver _dataReceiver) external;

  /// @notice Allows governor to set a new initial cardinality for new oracles
  /// @param _initialCardinality The initial size of the observations memory storage for newly deployed pools
  function setInitialCardinality(uint16 _initialCardinality) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleFactory} from './IOracleFactory.sol';

/// @title The OracleSidechain interface
/// @author 0xJabberwock (from DeFi Wonderland)
/// @notice Contains state variables, events, custom errors and functions used in OracleSidechain
interface IOracleSidechain {
  // STRUCTS

  struct ObservationData {
    uint32 blockTimestamp;
    int24 tick;
  }

  // STATE VARIABLES

  // TODO: complete natspec

  function factory() external view returns (IOracleFactory _oracleFactory);

  function token0() external view returns (address _token0);

  function token1() external view returns (address _token1);

  function fee() external view returns (uint24 _fee);

  function poolSalt() external view returns (bytes32 _poolSalt);

  function poolNonce() external view returns (uint24 _poolNonce);

  /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
  /// when accessed externally.
  /// @return _sqrtPriceX96 Used to maintain compatibility with Uniswap V3
  /// @return _tick Used to maintain compatibility with Uniswap V3
  /// @return _observationIndex The index of the last oracle observation that was written,
  /// @return _observationCardinality The current maximum number of observations stored in the pool,
  /// @return _observationCardinalityNext The next maximum number of observations, to be updated when the observation.
  /// @return _feeProtocol Used to maintain compatibility with Uniswap V3
  /// @return _unlocked Used to maintain compatibility with Uniswap V3
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
  /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
  /// ago, rather than at a specific index in the array.
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

  event PoolInfoInitialized(bytes32 _poolSalt, address _token0, address _token1, uint24 _fee);
  event ObservationWritten(address _user, ObservationData _observationData);

  // ERRORS

  error AI();
  error InvalidPool();
  error OnlyDataReceiver();

  // FUNCTIONS

  function initializePoolInfo(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external;

  /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
  /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
  /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
  /// you must call it with secondsAgos = [3600, 0].
  /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
  /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
  /// @param _secondsAgos From how long ago each cumulative tick and liquidity value should be returned
  /// @return _tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
  /// @return _secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
  /// timestamp
  function observe(uint32[] calldata _secondsAgos)
    external
    view
    returns (int56[] memory _tickCumulatives, uint160[] memory _secondsPerLiquidityCumulativeX128s);

  function write(ObservationData[] memory _observationsData, uint24 _poolNonce) external returns (bool _written);
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleFactory} from './IOracleFactory.sol';
import {IOracleSidechain} from './IOracleSidechain.sol';
import {IBridgeReceiverAdapter} from './bridges/IBridgeReceiverAdapter.sol';
import {IGovernable} from './peripherals/IGovernable.sol';

/// @title The DataReceiver interface
/// @author 0xJabberwock (from DeFi Wonderland)
/// @notice Contains state variables, events, custom errors and functions used in DataReceiver
interface IDataReceiver is IGovernable {
  // STATE VARIABLES

  function oracleFactory() external view returns (IOracleFactory _oracleFactory);

  //solhint-disable-next-line func-name-mixedcase
  function ORACLE_INIT_CODE_HASH() external view returns (bytes32 _oracleInitCodeHash);

  function whitelistedAdapters(IBridgeReceiverAdapter _adapter) external view returns (bool _isAllowed);

  // EVENTS

  event ObservationsAdded(address _user, IOracleSidechain.ObservationData[] _observationsData);

  event AdapterWhitelisted(IBridgeReceiverAdapter _adapter, bool _isAllowed);

  // ERRORS

  error ObservationsNotWritable();

  error UnallowedAdapter();

  error LengthMismatch();

  // FUNCTIONS

  function addObservations(
    IOracleSidechain.ObservationData[] memory _observationsData,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) external;

  function whitelistAdapter(IBridgeReceiverAdapter _receiverAdapter, bool _isWhitelisted) external;

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

import {IOracleSidechain} from '../IOracleSidechain.sol';
import {IDataReceiver} from '../IDataReceiver.sol';

interface IBridgeReceiverAdapter {
  // FUNCTIONS

  function dataReceiver() external view returns (IDataReceiver _dataReceiver);

  /* NOTE: callback methods should be here declared */

  // EVENTS

  event DataSent(IOracleSidechain.ObservationData[] _observationsData, bytes32 _poolSalt);

  // ERRORS

  error UnauthorizedCaller();
}