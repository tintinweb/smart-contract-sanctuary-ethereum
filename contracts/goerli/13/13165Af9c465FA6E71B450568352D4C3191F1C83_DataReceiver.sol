//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IDataReceiver, IOracleSidechain} from '../interfaces/IDataReceiver.sol';

contract DataReceiver is IDataReceiver {
  IOracleSidechain public immutable oracleSidechain;

  constructor(IOracleSidechain _oracleSidechain) {
    oracleSidechain = _oracleSidechain;
  }

  function addObservation(uint32 _blockTimestamp, int24 _tick) external {
    if (oracleSidechain.write(_blockTimestamp, _tick)) {
      emit ObservationAdded(msg.sender, _blockTimestamp, _tick);
    } else {
      revert ObservationNotWritable(_blockTimestamp);
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleSidechain} from '../interfaces/IOracleSidechain.sol';

/// @title The DataReceiver interface
/// @author 0xJabberwock (from DeFi Wonderland)
/// @notice Contains state variables, events, custom errors and functions used in DataReceiver
interface IDataReceiver {
  // STATE VARIABLES

  function oracleSidechain() external view returns (IOracleSidechain _oracleSidechain);

  // EVENTS

  event ObservationAdded(address user, uint32 blockTimestamp, int24 tick);

  // CUSTOM ERRORS

  error ObservationNotWritable(uint32 blockTimestamp);

  // FUNCTIONS

  function addObservation(uint32 _blockTimestamp, int24 _tick) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

/// @title The OracleSidechain interface
/// @author 0xJabberwock (from DeFi Wonderland)
/// @notice Contains state variables, events, custom errors and functions used in OracleSidechain
interface IOracleSidechain {
  // STATE VARIABLES

  /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
  /// when accessed externally.
  /// @return _observationIndex The index of the last oracle observation that was written,
  /// @return _observationCardinality The current maximum number of observations stored in the pool,
  /// @return _observationCardinalityNext The next maximum number of observations, to be updated when the observation.
  function slot0()
    external
    view
    returns (
      uint16 _observationIndex,
      uint16 _observationCardinality,
      uint16 _observationCardinalityNext
    );

  function lastTick() external view returns (int24 _lastTick);

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

  /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param blockTimestamp The timestamp of the observation
  /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
  event Initialize(uint32 blockTimestamp, int24 tick);

  /// @notice Emitted by the pool for increases to the number of observations that can be stored
  /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
  /// just before a mint/swap/burn.
  /// @param observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(uint16 observationCardinalityNextOld, uint16 observationCardinalityNextNew);

  event ObservationWritten(address user, uint32 blockTimestamp, int24 tick);

  // CUSTOM ERRORS

  error AI();

  // FUNCTIONS

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

  function write(uint32 _blockTimestamp, int24 _tick) external returns (bool _written);

  /// @notice Sets the initial price for the pool
  /// @param _blockTimestamp The timestamp of the observation
  /// @param _tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
  function initialize(uint32 _blockTimestamp, int24 _tick) external;

  /// @notice Increase the maximum number of price and liquidity observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param _observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(uint16 _observationCardinalityNext) external;
}