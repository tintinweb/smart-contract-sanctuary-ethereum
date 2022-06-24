//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IDataReceiver, IOracleSidechain, IBridgeReceiverAdapter} from '../interfaces/IDataReceiver.sol';
import {Governable} from './peripherals/Governable.sol';

contract DataReceiver is Governable, IDataReceiver {
  IOracleSidechain public immutable oracleSidechain;
  mapping(IBridgeReceiverAdapter => bool) public whitelistedAdapters;

  constructor(IOracleSidechain _oracleSidechain, address _governance) Governable(_governance) {
    oracleSidechain = _oracleSidechain;
    governance = _governance;
  }

  function addObservation(uint32 _blockTimestamp, int24 _tick) external onlyWhitelistedAdapters {
    if (oracleSidechain.write(_blockTimestamp, _tick)) {
      emit ObservationAdded(msg.sender, _blockTimestamp, _tick);
    } else {
      revert ObservationNotWritable(_blockTimestamp);
    }
  }

  function whitelistAdapter(IBridgeReceiverAdapter _receiverAdapter, bool _isWhitelisted) external onlyGovernance {
    _whitelistAdapter(_receiverAdapter, _isWhitelisted);
  }

  function whitelistAdapters(IBridgeReceiverAdapter[] calldata _receiverAdapters, bool[] calldata _isWhitelisted) external onlyGovernance {
    uint256 _receiverAdapterLength = _receiverAdapters.length;
    if (_receiverAdapterLength != _isWhitelisted.length) revert LengthMismatch();
    uint256 _i;
    unchecked {
      for (_i; _i < _receiverAdapterLength; ++_i) {
        _whitelistAdapter(_receiverAdapters[_i], _isWhitelisted[_i]);
      }
    }
  }

  function _whitelistAdapter(IBridgeReceiverAdapter _receiverAdapter, bool _isWhitelisted) internal {
    whitelistedAdapters[_receiverAdapter] = _isWhitelisted;
    emit AdapterWhitelisted(_receiverAdapter, _isWhitelisted);
  }

  // TODO: do we want to give governance the power to add observations manually?
  modifier onlyWhitelistedAdapters() {
    if (!whitelistedAdapters[IBridgeReceiverAdapter(msg.sender)]) revert UnallowedAdapter();
    _;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleSidechain} from '../interfaces/IOracleSidechain.sol';
import {IBridgeReceiverAdapter} from '../interfaces/bridges/IBridgeReceiverAdapter.sol';
import {IGovernable} from './peripherals/IGovernable.sol';

/// @title The DataReceiver interface
/// @author 0xJabberwock (from DeFi Wonderland)
/// @notice Contains state variables, events, custom errors and functions used in DataReceiver
interface IDataReceiver is IGovernable {
  // STATE VARIABLES

  function oracleSidechain() external view returns (IOracleSidechain _oracleSidechain);

  function whitelistedAdapters(IBridgeReceiverAdapter _adapter) external view returns (bool _isAllowed);

  // EVENTS

  event ObservationAdded(address user, uint32 blockTimestamp, int24 tick);
  event AdapterWhitelisted(IBridgeReceiverAdapter _adapter, bool _isAllowed);

  // CUSTOM ERRORS

  error ObservationNotWritable(uint32 blockTimestamp);
  error UnallowedAdapter();
  error LengthMismatch();

  // FUNCTIONS

  function addObservation(uint32 _blockTimestamp, int24 _tick) external;

  function whitelistAdapter(IBridgeReceiverAdapter _receiverAdapter, bool _isWhitelisted) external;

  function whitelistAdapters(IBridgeReceiverAdapter[] calldata _receiverAdapters, bool[] calldata _isWhitelisted) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IGovernable} from '../../interfaces/peripherals/IGovernable.sol';

abstract contract Governable is IGovernable {
  /// @inheritdoc IGovernable
  address public override governance;

  /// @inheritdoc IGovernable
  address public override pendingGovernance;

  constructor(address _governance) {
    if (_governance == address(0)) revert NoGovernanceZeroAddress();
    governance = _governance;
  }

  /// @inheritdoc IGovernable
  function setGovernance(address _governance) external override onlyGovernance {
    pendingGovernance = _governance;
    emit GovernanceProposal(_governance);
  }

  /// @inheritdoc IGovernable
  function acceptGovernance() external override onlyPendingGovernance {
    governance = pendingGovernance;
    delete pendingGovernance;
    emit GovernanceSet(governance);
  }

  /// @notice Functions with this modifier can only be called by governance
  modifier onlyGovernance() {
    if (msg.sender != governance) revert OnlyGovernance();
    _;
  }

  /// @notice Functions with this modifier can only be called by pendingGovernance
  modifier onlyPendingGovernance() {
    if (msg.sender != pendingGovernance) revert OnlyPendingGovernance();
    _;
  }
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

interface IBridgeReceiverAdapter {
  // FUNCTIONS

  function addObservation(uint32 _blockTimestamp, int24 _tick) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Governable contract
/// @notice Manages the governance role
interface IGovernable {
  // Events

  /// @notice Emitted when pendingGovernance accepts to be governance
  /// @param governance Address of the new governance
  event GovernanceSet(address governance);

  /// @notice Emitted when a new governance is proposed
  /// @param pendingGovernance Address that is proposed to be the new governance
  event GovernanceProposal(address pendingGovernance);

  // Errors

  /// @notice Throws if the caller of the function is not governance
  error OnlyGovernance();

  /// @notice Throws if the caller of the function is not pendingGovernance
  error OnlyPendingGovernance();

  /// @notice Throws if trying to set governance to zero address
  error NoGovernanceZeroAddress();

  // Variables

  /// @notice Stores the governance address
  /// @return _governance The governance addresss
  function governance() external view returns (address _governance);

  /// @notice Stores the pendingGovernance address
  /// @return _pendingGovernance The pendingGovernance addresss
  function pendingGovernance() external view returns (address _pendingGovernance);

  // Methods

  /// @notice Proposes a new address to be governance
  /// @param _governance The address being proposed as the new governance
  function setGovernance(address _governance) external;

  /// @notice Changes the governance from the current governance to the previously proposed address
  function acceptGovernance() external;
}