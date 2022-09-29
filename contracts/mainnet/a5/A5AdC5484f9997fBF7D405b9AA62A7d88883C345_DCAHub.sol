// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import './DCAHubParameters.sol';
import './DCAHubPositionHandler.sol';
import './DCAHubSwapHandler.sol';
import './DCAHubConfigHandler.sol';
import './DCAHubPlatformHandler.sol';

contract DCAHub is DCAHubParameters, DCAHubConfigHandler, DCAHubSwapHandler, DCAHubPositionHandler, DCAHubPlatformHandler, IDCAHub {
  constructor(
    address _immediateGovernor,
    address _timeLockedGovernor,
    ITokenPriceOracle _oracle,
    IDCAPermissionManager _permissionManager
  ) DCAHubPositionHandler(_permissionManager) DCAHubConfigHandler(_immediateGovernor, _timeLockedGovernor, _oracle) {}

  /// @inheritdoc IDCAHubConfigHandler
  function paused() public view override(IDCAHubConfigHandler, DCAHubConfigHandler) returns (bool) {
    return super.paused();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IDCAHub.sol';
import '../libraries/TokenSorting.sol';

abstract contract DCAHubParameters is IDCAHubParameters {
  /// @notice Swap information about a specific pair
  struct SwapData {
    // How many swaps have been executed
    uint32 performedSwaps;
    // How much of token A will be swapped on the next swap
    uint224 nextAmountToSwapAToB;
    // Timestamp of the last swap
    uint32 lastSwappedAt;
    // How much of token B will be swapped on the next swap
    uint224 nextAmountToSwapBToA;
  }

  /// @notice The difference of tokens to swap between a swap, and the previous one
  struct SwapDelta {
    // How much less of token A will the following swap require
    uint128 swapDeltaAToB;
    // How much less of token B will the following swap require
    uint128 swapDeltaBToA;
  }

  /// @notice The sum of the ratios the oracle reported in all executed swaps
  struct AccumRatio {
    // The sum of all ratios from A to B
    uint256 accumRatioAToB;
    // The sum of all ratios from B to A
    uint256 accumRatioBToA;
  }

  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => bytes1)) public activeSwapIntervals; // token A => token B => active swap intervals
  /// @inheritdoc IDCAHubParameters
  mapping(address => uint256) public platformBalance; // token => balance
  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => mapping(bytes1 => mapping(uint32 => SwapDelta)))) public swapAmountDelta; // token A => token B => swap interval => swap number => delta
  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => mapping(bytes1 => mapping(uint32 => AccumRatio)))) public accumRatio; // token A => token B => swap interval => swap number => accum
  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => mapping(bytes1 => SwapData))) public swapData; // token A => token B => swap interval => swap data

  function _assertNonZeroAddress(address _address) internal pure {
    if (_address == address(0)) revert IDCAHub.ZeroAddress();
  }

  function _transfer(
    address _token,
    address _to,
    uint256 _amount
  ) internal {
    if (_amount > 0) {
      IERC20Metadata(_token).safeTransfer(_to, _amount);
    }
  }

  function _balanceOf(address _token) internal view returns (uint256) {
    return IERC20Metadata(_token).balanceOf(address(this));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../libraries/Intervals.sol';
import './DCAHubConfigHandler.sol';
import '../libraries/FeeMath.sol';

abstract contract DCAHubPositionHandler is ReentrancyGuard, DCAHubConfigHandler, IDCAHubPositionHandler {
  struct DCA {
    uint32 swapWhereLastUpdated; // Includes both modify and withdraw
    uint32 finalSwap;
    bytes1 swapIntervalMask;
    address from;
    uint24 rateLower; // We are splitting the rate into two different uints, so that we can use only 2 storage slots
    uint96 rateHigher;
    address to;
  }

  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IDCAHubPositionHandler
  IDCAPermissionManager public permissionManager;
  mapping(uint256 => DCA) internal _userPositions;
  mapping(uint256 => uint256) internal _swappedBeforeModified;
  /// @inheritdoc IDCAHubPositionHandler
  uint256 public totalCreatedPositions;

  constructor(IDCAPermissionManager _permissionManager) {
    _assertNonZeroAddress(address(_permissionManager));
    permissionManager = _permissionManager;
  }

  /// @inheritdoc IDCAHubPositionHandler
  function userPosition(uint256 _positionId) external view returns (UserPosition memory _userPosition) {
    DCA memory _position = _userPositions[_positionId];
    uint32 _performedSwaps = _getPerformedSwaps(_position.from, _position.to, _position.swapIntervalMask);
    uint32 _newestSwapToConsider = _min(_performedSwaps, _position.finalSwap);
    _userPosition.from = IERC20Metadata(_position.from);
    _userPosition.to = IERC20Metadata(_position.to);
    _userPosition.swapsExecuted = _subtractIfPossible(_newestSwapToConsider, _position.swapWhereLastUpdated);
    _userPosition.swapsLeft = _subtractIfPossible(_position.finalSwap, _performedSwaps);
    _userPosition.remaining = _calculateUnswapped(_position, _performedSwaps);
    _userPosition.rate = _mergeRate(_position);
    if (_position.swapIntervalMask > 0) {
      _userPosition.swapInterval = Intervals.maskToInterval(_position.swapIntervalMask);
      _userPosition.swapped = _calculateSwapped(_positionId, _position, _performedSwaps);
    }
  }

  /// @inheritdoc IDCAHubPositionHandler
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions
  ) public nonReentrant whenNotPaused returns (uint256) {
    if (_from == address(0) || _to == address(0) || _owner == address(0)) revert IDCAHub.ZeroAddress();
    if (_from == _to) revert InvalidToken();
    if (_amount == 0) revert ZeroAmount();
    if (_amountOfSwaps == 0) revert ZeroSwaps();
    _assertTokensAreAllowed(_from, _to);
    uint120 _rate = _calculateRate(_amount, _amountOfSwaps);
    uint256 _positionId = ++totalCreatedPositions;
    DCA memory _userPosition = _buildPosition(_from, _to, _amountOfSwaps, Intervals.intervalToMask(_swapInterval), _rate);
    if (allowedSwapIntervals & _userPosition.swapIntervalMask == 0) revert IntervalNotAllowed();
    permissionManager.mint(_positionId, _owner, _permissions);
    _updateActiveIntervalsAndOracle(_from, _to, _userPosition.swapIntervalMask);
    _addToDelta(_from, _to, _userPosition.swapIntervalMask, _userPosition.finalSwap, _rate);
    _userPositions[_positionId] = _userPosition;
    IERC20Metadata(_from).safeTransferFrom(msg.sender, address(this), _amount);
    emit Deposited(
      msg.sender,
      _owner,
      _positionId,
      _from,
      _to,
      _swapInterval,
      _rate,
      _userPosition.swapWhereLastUpdated + 1,
      _userPosition.finalSwap,
      _permissions
    );
    return _positionId;
  }

  /// @inheritdoc IDCAHubPositionHandler
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external returns (uint256 _positionId) {
    _positionId = deposit(_from, _to, _amount, _amountOfSwaps, _swapInterval, _owner, _permissions);
    if (_miscellaneous.length > 0) {
      emit Miscellaneous(_positionId, _miscellaneous);
    }
  }

  /// @inheritdoc IDCAHubPositionHandler
  function withdrawSwapped(uint256 _positionId, address _recipient) external nonReentrant returns (uint256) {
    _assertNonZeroAddress(_recipient);

    (uint256 _swapped, address _to) = _executeWithdraw(_positionId);
    _transfer(_to, _recipient, _swapped);
    emit Withdrew(msg.sender, _recipient, _positionId, _to, _swapped);
    return _swapped;
  }

  /// @inheritdoc IDCAHubPositionHandler
  function withdrawSwappedMany(PositionSet[] calldata _positions, address _recipient) external nonReentrant returns (uint256[] memory _swapped) {
    _assertNonZeroAddress(_recipient);
    _swapped = new uint256[](_positions.length);
    for (uint256 i = 0; i < _positions.length; ) {
      address _token = _positions[i].token;
      uint256[] memory _positionIds = _positions[i].positionIds;
      for (uint256 j = 0; j < _positionIds.length; ) {
        (uint256 _swappedByPosition, address _to) = _executeWithdraw(_positionIds[j]);
        if (_to != _token) revert PositionDoesNotMatchToken();
        _swapped[i] += _swappedByPosition;
        unchecked {
          j++;
        }
      }
      _transfer(_token, _recipient, _swapped[i]);
      unchecked {
        i++;
      }
    }
    emit WithdrewMany(msg.sender, _recipient, _positions, _swapped);
  }

  /// @inheritdoc IDCAHubPositionHandler
  function terminate(
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  ) external nonReentrant returns (uint256 _unswapped, uint256 _swapped) {
    if (_recipientUnswapped == address(0) || _recipientSwapped == address(0)) revert IDCAHub.ZeroAddress();

    DCA memory _userPosition = _userPositions[_positionId];
    _assertPositionExistsAndCallerHasPermission(_positionId, _userPosition, IDCAPermissionManager.Permission.TERMINATE);
    uint32 _performedSwaps = _getPerformedSwaps(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask);

    _swapped = _calculateSwapped(_positionId, _userPosition, _performedSwaps);
    _unswapped = _calculateUnswapped(_userPosition, _performedSwaps);

    _removeFromDelta(_userPosition, _performedSwaps);
    delete _userPositions[_positionId];
    delete _swappedBeforeModified[_positionId];
    permissionManager.burn(_positionId);

    _transfer(_userPosition.to, _recipientSwapped, _swapped);
    _transfer(_userPosition.from, _recipientUnswapped, _unswapped);

    emit Terminated(msg.sender, _recipientUnswapped, _recipientSwapped, _positionId, _unswapped, _swapped);
  }

  /// @inheritdoc IDCAHubPositionHandler
  function increasePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newAmountOfSwaps
  ) external nonReentrant whenNotPaused {
    _modify(_positionId, _amount, _newAmountOfSwaps, address(0));
  }

  /// @inheritdoc IDCAHubPositionHandler
  function reducePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newAmountOfSwaps,
    address _recipient
  ) external nonReentrant {
    _assertNonZeroAddress(_recipient);
    _modify(_positionId, _amount, _newAmountOfSwaps, _recipient);
  }

  function _modify(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newAmountOfSwaps,
    address _recipient
  ) internal {
    DCA memory _userPosition = _userPositions[_positionId];
    bool _increase = _recipient == address(0);
    _assertPositionExistsAndCallerHasPermission(
      _positionId,
      _userPosition,
      _increase ? IDCAPermissionManager.Permission.INCREASE : IDCAPermissionManager.Permission.REDUCE
    );

    if (_increase) {
      _assertTokensAreAllowed(_userPosition.from, _userPosition.to);
      (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_userPosition.from, _userPosition.to);
      activeSwapIntervals[_tokenA][_tokenB] |= _userPosition.swapIntervalMask;
    }

    uint32 _performedSwaps = _getPerformedSwaps(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask);
    uint256 _unswapped = _calculateUnswapped(_userPosition, _performedSwaps);
    uint256 _total = _increase ? _unswapped + _amount : _unswapped - _amount;
    if (_total != 0 && _newAmountOfSwaps == 0) revert ZeroSwaps();
    if (_total == 0 && _newAmountOfSwaps > 0) _newAmountOfSwaps = 0;

    uint120 _newRate = _newAmountOfSwaps == 0 ? 0 : _calculateRate(_total, _newAmountOfSwaps);
    (_userPositions[_positionId].rateLower, _userPositions[_positionId].rateHigher) = _splitRate(_newRate);

    uint32 _finalSwap = _performedSwaps + _newAmountOfSwaps;
    _userPositions[_positionId].swapWhereLastUpdated = _performedSwaps;
    _userPositions[_positionId].finalSwap = _finalSwap;
    _swappedBeforeModified[_positionId] = _calculateSwapped(_positionId, _userPosition, _performedSwaps);

    _removeFromDelta(_userPosition, _performedSwaps);
    _addToDelta(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask, _finalSwap, _newRate);

    if (_amount > 0) {
      if (_increase) {
        IERC20Metadata(_userPosition.from).safeTransferFrom(msg.sender, address(this), _amount);
      } else {
        _transfer(_userPosition.from, _recipient, _amount);
      }
    }

    emit Modified(msg.sender, _positionId, _newRate, _performedSwaps + 1, _finalSwap);
  }

  function _assertTokensAreAllowed(address _tokenA, address _tokenB) internal view {
    if (!allowedTokens[_tokenA] || !allowedTokens[_tokenB]) revert IDCAHubConfigHandler.UnallowedToken();
  }

  function _assertPositionExistsAndCallerHasPermission(
    uint256 _positionId,
    DCA memory _userPosition,
    IDCAPermissionManager.Permission _permission
  ) internal view {
    if (_userPosition.swapIntervalMask == 0) revert InvalidPosition();
    if (!permissionManager.hasPermission(_positionId, msg.sender, _permission)) revert UnauthorizedCaller();
  }

  function _addToDelta(
    address _from,
    address _to,
    bytes1 _swapIntervalMask,
    uint32 _finalSwap,
    uint120 _rate
  ) internal {
    _modifyDelta(_from, _to, _swapIntervalMask, _finalSwap, _rate, true);
  }

  function _removeFromDelta(DCA memory _userPosition, uint32 _performedSwaps) internal {
    if (_userPosition.finalSwap > _performedSwaps) {
      _modifyDelta(
        _userPosition.from,
        _userPosition.to,
        _userPosition.swapIntervalMask,
        _userPosition.finalSwap,
        _mergeRate(_userPosition),
        false
      );
    }
  }

  function _modifyDelta(
    address _from,
    address _to,
    bytes1 _swapIntervalMask,
    uint32 _finalSwap,
    uint120 _rate,
    bool _add
  ) internal {
    if (_from < _to) {
      if (_add) {
        swapData[_from][_to][_swapIntervalMask].nextAmountToSwapAToB += _rate;
        swapAmountDelta[_from][_to][_swapIntervalMask][_finalSwap + 1].swapDeltaAToB += _rate;
      } else {
        swapData[_from][_to][_swapIntervalMask].nextAmountToSwapAToB -= _rate;
        swapAmountDelta[_from][_to][_swapIntervalMask][_finalSwap + 1].swapDeltaAToB -= _rate;
      }
    } else {
      if (_add) {
        swapData[_to][_from][_swapIntervalMask].nextAmountToSwapBToA += _rate;
        swapAmountDelta[_to][_from][_swapIntervalMask][_finalSwap + 1].swapDeltaBToA += _rate;
      } else {
        swapData[_to][_from][_swapIntervalMask].nextAmountToSwapBToA -= _rate;
        swapAmountDelta[_to][_from][_swapIntervalMask][_finalSwap + 1].swapDeltaBToA -= _rate;
      }
    }
  }

  function _updateActiveIntervalsAndOracle(
    address _from,
    address _to,
    bytes1 _mask
  ) internal {
    (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_from, _to);
    bytes1 _activeIntervals = activeSwapIntervals[_tokenA][_tokenB];
    if (_activeIntervals & _mask == 0) {
      if (_activeIntervals == 0) {
        oracle.addSupportForPairIfNeeded(_tokenA, _tokenB, '');
      }
      activeSwapIntervals[_tokenA][_tokenB] = _activeIntervals | _mask;
    }
  }

  /** Returns the amount of tokens swapped in TO */
  function _calculateSwapped(
    uint256 _positionId,
    DCA memory _userPosition,
    uint32 _performedSwaps
  ) internal view returns (uint256 _swapped) {
    uint32 _newestSwapToConsider = _min(_performedSwaps, _userPosition.finalSwap);

    if (_userPosition.swapWhereLastUpdated > _newestSwapToConsider) {
      // If last update happened after the position's final swap, then a withdraw was executed, and we just return 0
      return 0;
    } else if (_userPosition.swapWhereLastUpdated == _newestSwapToConsider) {
      // If the last update matches the positions's final swap, then we can avoid all calculation below
      return _swappedBeforeModified[_positionId];
    }

    uint256 _positionsAccumRatio;
    if (_userPosition.from < _userPosition.to) {
      mapping(uint32 => AccumRatio) storage _accumRatioRef = accumRatio[_userPosition.from][_userPosition.to][_userPosition.swapIntervalMask];
      _positionsAccumRatio =
        _accumRatioRef[_newestSwapToConsider].accumRatioAToB -
        _accumRatioRef[_userPosition.swapWhereLastUpdated].accumRatioAToB;
    } else {
      mapping(uint32 => AccumRatio) storage _accumRatioRef = accumRatio[_userPosition.to][_userPosition.from][_userPosition.swapIntervalMask];
      _positionsAccumRatio =
        _accumRatioRef[_newestSwapToConsider].accumRatioBToA -
        _accumRatioRef[_userPosition.swapWhereLastUpdated].accumRatioBToA;
    }

    uint256 _magnitude = tokenMagnitude[_userPosition.from];
    uint120 _rate = _mergeRate(_userPosition);
    (bool _ok, uint256 _mult) = SafeMath.tryMul(_positionsAccumRatio, _rate);
    uint256 _swappedInCurrentPosition = (_ok ? _mult / _magnitude : (_positionsAccumRatio / _magnitude) * _rate) / FeeMath.FEE_PRECISION;
    _swapped = _swappedInCurrentPosition + _swappedBeforeModified[_positionId];
  }

  /** Returns how many FROM remains unswapped  */
  function _calculateUnswapped(DCA memory _userPosition, uint32 _performedSwaps) internal pure returns (uint256 _unswapped) {
    _unswapped = uint256(_subtractIfPossible(_userPosition.finalSwap, _performedSwaps)) * _mergeRate(_userPosition);
  }

  function _executeWithdraw(uint256 _positionId) internal returns (uint256 _swapped, address _to) {
    DCA memory _userPosition = _userPositions[_positionId];
    _assertPositionExistsAndCallerHasPermission(_positionId, _userPosition, IDCAPermissionManager.Permission.WITHDRAW);
    uint32 _performedSwaps = _getPerformedSwaps(_userPosition.from, _userPosition.to, _userPosition.swapIntervalMask);
    _swapped = _calculateSwapped(_positionId, _userPosition, _performedSwaps);
    _to = _userPosition.to;
    _userPositions[_positionId].swapWhereLastUpdated = _performedSwaps;
    delete _swappedBeforeModified[_positionId];
  }

  function _getPerformedSwaps(
    address _from,
    address _to,
    bytes1 _swapIntervalMask
  ) internal view returns (uint32) {
    (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_from, _to);
    return swapData[_tokenA][_tokenB][_swapIntervalMask].performedSwaps;
  }

  function _buildPosition(
    address _from,
    address _to,
    uint32 _amountOfSwaps,
    bytes1 _mask,
    uint120 _rate
  ) internal view returns (DCA memory _userPosition) {
    uint32 _performedSwaps = _getPerformedSwaps(_from, _to, _mask);
    (uint24 _lower, uint96 _higher) = _splitRate(_rate);
    _userPosition = DCA({
      swapWhereLastUpdated: _performedSwaps,
      finalSwap: _performedSwaps + _amountOfSwaps,
      swapIntervalMask: _mask,
      rateLower: _lower,
      rateHigher: _higher,
      from: _from,
      to: _to
    });
  }

  function _calculateRate(uint256 _amount, uint32 _amountOfSwaps) internal pure returns (uint120) {
    uint256 _rate = _amount / _amountOfSwaps;
    if (_rate > type(uint120).max) revert AmountTooBig();
    return uint120(_rate);
  }

  function _mergeRate(DCA memory _userPosition) internal pure returns (uint120) {
    return (uint120(_userPosition.rateHigher) << 24) + _userPosition.rateLower;
  }

  function _splitRate(uint120 _rate) internal pure returns (uint24 _lower, uint96 _higher) {
    _lower = uint24(_rate);
    _higher = uint96(_rate >> 24);
  }

  function _min(uint32 _a, uint32 _b) internal pure returns (uint32) {
    return _a > _b ? _b : _a;
  }

  function _subtractIfPossible(uint32 _a, uint32 _b) internal pure returns (uint32) {
    return _a > _b ? _a - _b : 0;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '../interfaces/IDCAHubSwapCallee.sol';
import '../libraries/Intervals.sol';
import '../libraries/FeeMath.sol';
import './DCAHubConfigHandler.sol';

abstract contract DCAHubSwapHandler is ReentrancyGuard, DCAHubConfigHandler, IDCAHubSwapHandler {
  struct PairMagnitudes {
    uint256 magnitudeA;
    uint256 magnitudeB;
  }

  using SafeERC20 for IERC20Metadata;

  function _registerSwap(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask,
    uint256 _ratioAToB,
    uint256 _ratioBToA,
    uint32 _timestamp
  ) internal virtual {
    SwapData memory _swapDataMem = swapData[_tokenA][_tokenB][_swapIntervalMask];
    if (_swapDataMem.nextAmountToSwapAToB > 0 || _swapDataMem.nextAmountToSwapBToA > 0) {
      mapping(uint32 => AccumRatio) storage _accumRatioRef = accumRatio[_tokenA][_tokenB][_swapIntervalMask];
      mapping(uint32 => SwapDelta) storage _swapAmountDeltaRef = swapAmountDelta[_tokenA][_tokenB][_swapIntervalMask];
      AccumRatio memory _accumRatioMem = _accumRatioRef[_swapDataMem.performedSwaps];
      _accumRatioRef[_swapDataMem.performedSwaps + 1] = AccumRatio({
        accumRatioAToB: _accumRatioMem.accumRatioAToB + _ratioAToB,
        accumRatioBToA: _accumRatioMem.accumRatioBToA + _ratioBToA
      });
      SwapDelta memory _swapDeltaMem = _swapAmountDeltaRef[_swapDataMem.performedSwaps + 2];
      uint224 _nextAmountToSwapAToB = _swapDataMem.nextAmountToSwapAToB - _swapDeltaMem.swapDeltaAToB;
      uint224 _nextAmountToSwapBToA = _swapDataMem.nextAmountToSwapBToA - _swapDeltaMem.swapDeltaBToA;
      swapData[_tokenA][_tokenB][_swapIntervalMask] = SwapData({
        performedSwaps: _swapDataMem.performedSwaps + 1,
        lastSwappedAt: _timestamp,
        nextAmountToSwapAToB: _nextAmountToSwapAToB,
        nextAmountToSwapBToA: _nextAmountToSwapBToA
      });
      delete _swapAmountDeltaRef[_swapDataMem.performedSwaps + 2];
      if (_nextAmountToSwapAToB == 0 && _nextAmountToSwapBToA == 0) {
        _markIntervalAsInactive(_tokenA, _tokenB, _swapIntervalMask);
      }
    } else {
      _markIntervalAsInactive(_tokenA, _tokenB, _swapIntervalMask);
    }
  }

  function _convertTo(
    uint256 _fromTokenMagnitude,
    uint256 _amountFrom,
    uint256 _ratioFromTo,
    uint32 _swapFee
  ) internal pure returns (uint256 _amountTo) {
    uint256 _numerator = FeeMath.subtractFeeFromAmount(_swapFee, _amountFrom * _ratioFromTo);
    _amountTo = _numerator / _fromTokenMagnitude;
    // Note: we need to round up because we can't ask for less than what we actually need
    if (_numerator % _fromTokenMagnitude != 0) _amountTo++;
  }

  function _getTimestamp() internal view virtual returns (uint32 _blockTimestamp) {
    _blockTimestamp = uint32(block.timestamp);
  }

  function _getTotalAmountsToSwap(
    address _tokenA,
    address _tokenB,
    bool _calculatePrivilegedAvailability
  )
    internal
    view
    virtual
    returns (
      uint256 _totalAmountToSwapTokenA,
      uint256 _totalAmountToSwapTokenB,
      bytes1 _intervalsInSwap
    )
  {
    bytes1 _activeIntervals = activeSwapIntervals[_tokenA][_tokenB];
    uint32 _blockTimestamp = _getTimestamp();
    bytes1 _mask = 0x01;
    while (_activeIntervals >= _mask && _mask > 0) {
      if (_activeIntervals & _mask != 0) {
        SwapData memory _swapDataMem = swapData[_tokenA][_tokenB][_mask];
        uint32 _swapInterval = Intervals.maskToInterval(_mask);
        uint32 _nextSwapAvailableAt = ((_swapDataMem.lastSwappedAt / _swapInterval) + 1) * _swapInterval;
        if (!_calculatePrivilegedAvailability) {
          // If the caller does not have privileges, then they will have to wait a little more to execute swaps
          _nextSwapAvailableAt += _swapInterval / 3;
        }
        if (_nextSwapAvailableAt > _blockTimestamp) {
          // Note: this 'break' is both an optimization and a search for more CoW. Since this loop starts with the smaller intervals, it is
          // highly unlikely that if a small interval can't be swapped, a bigger interval can. It could only happen when a position was just
          // created for a new swap interval. At the same time, by adding this check, we force intervals to be swapped together. Therefore
          // increasing the chance of CoW (Coincidence of Wants), and reducing the need for external funds.
          break;
        }
        _intervalsInSwap |= _mask;
        _totalAmountToSwapTokenA += _swapDataMem.nextAmountToSwapAToB;
        _totalAmountToSwapTokenB += _swapDataMem.nextAmountToSwapBToA;
      }
      _mask <<= 1;
    }

    if (_totalAmountToSwapTokenA == 0 && _totalAmountToSwapTokenB == 0) {
      // Note: if there are no tokens to swap, then we don't want to execute any swaps for this pair
      _intervalsInSwap = 0;
    }
  }

  function _calculateRatio(
    address _tokenA,
    address _tokenB,
    ITokenPriceOracle _oracle,
    bytes calldata _oracleData
  )
    internal
    view
    virtual
    returns (
      uint256 _ratioAToB,
      uint256 _ratioBToA,
      PairMagnitudes memory _magnitudes
    )
  {
    _magnitudes.magnitudeA = tokenMagnitude[_tokenA];
    _magnitudes.magnitudeB = tokenMagnitude[_tokenB];
    _ratioBToA = _oracle.quote(_tokenB, _magnitudes.magnitudeB, _tokenA, _oracleData);
    _ratioAToB = (_magnitudes.magnitudeB * _magnitudes.magnitudeA) / _ratioBToA;
  }

  /// @inheritdoc IDCAHubSwapHandler
  function getNextSwapInfo(
    address[] calldata _tokens,
    PairIndexes[] calldata _pairs,
    bool _calculatePrivilegedAvailability,
    bytes calldata _oracleData
  ) public view virtual returns (SwapInfo memory _swapInformation) {
    // Note: we are caching these variables in memory so we can read storage only once (it's cheaper that way)
    uint32 _swapFee = swapFee;
    ITokenPriceOracle _oracle = oracle;

    uint256[] memory _total = new uint256[](_tokens.length);
    uint256[] memory _needed = new uint256[](_tokens.length);
    _swapInformation.pairs = new PairInSwap[](_pairs.length);

    for (uint256 i = 0; i < _pairs.length; ) {
      uint8 indexTokenA = _pairs[i].indexTokenA;
      uint8 indexTokenB = _pairs[i].indexTokenB;
      if (
        indexTokenA >= indexTokenB ||
        (i > 0 &&
          (indexTokenA < _pairs[i - 1].indexTokenA || (indexTokenA == _pairs[i - 1].indexTokenA && indexTokenB <= _pairs[i - 1].indexTokenB)))
      ) {
        // Note: this confusing condition verifies that the pairs are sorted, first by token A, and then by token B
        revert InvalidPairs();
      }

      PairInSwap memory _pairInSwap;
      _pairInSwap.tokenA = _tokens[indexTokenA];
      _pairInSwap.tokenB = _tokens[indexTokenB];

      (_pairInSwap.totalAmountToSwapTokenA, _pairInSwap.totalAmountToSwapTokenB, _pairInSwap.intervalsInSwap) = _getTotalAmountsToSwap(
        _pairInSwap.tokenA,
        _pairInSwap.tokenB,
        _calculatePrivilegedAvailability
      );

      _total[indexTokenA] += _pairInSwap.totalAmountToSwapTokenA;
      _total[indexTokenB] += _pairInSwap.totalAmountToSwapTokenB;

      // Note: it would be better to calculate the magnitudes here instead of inside `_calculateRatio`, but it throws a "stack too deep" error
      PairMagnitudes memory _magnitudes;
      (_pairInSwap.ratioAToB, _pairInSwap.ratioBToA, _magnitudes) = _calculateRatio(
        _pairInSwap.tokenA,
        _pairInSwap.tokenB,
        _oracle,
        _oracleData
      );

      _needed[indexTokenA] += _convertTo(_magnitudes.magnitudeB, _pairInSwap.totalAmountToSwapTokenB, _pairInSwap.ratioBToA, _swapFee);
      _needed[indexTokenB] += _convertTo(_magnitudes.magnitudeA, _pairInSwap.totalAmountToSwapTokenA, _pairInSwap.ratioAToB, _swapFee);

      _swapInformation.pairs[i] = _pairInSwap;
      unchecked {
        i++;
      }
    }

    // Note: we are caching this variable in memory so we can read storage only once (it's cheaper that way)
    uint16 _platformFeeRatio = platformFeeRatio;

    _swapInformation.tokens = new TokenInSwap[](_tokens.length);
    for (uint256 i = 0; i < _swapInformation.tokens.length; ) {
      address _token = _tokens[i];
      if (!allowedTokens[_token]) revert IDCAHubConfigHandler.UnallowedToken();
      if (i > 0 && _token <= _tokens[i - 1]) {
        revert IDCAHub.InvalidTokens();
      }

      TokenInSwap memory _tokenInSwap;
      _tokenInSwap.token = _token;

      uint256 _neededInSwap = _needed[i];
      uint256 _totalBeingSwapped = _total[i];

      if (_neededInSwap > 0 || _totalBeingSwapped > 0) {
        uint256 _totalFee = FeeMath.calculateSubtractedFee(_swapFee, _neededInSwap);

        int256 _platformFee = int256((_totalFee * _platformFeeRatio) / MAX_PLATFORM_FEE_RATIO);

        // If diff is negative, we need tokens. If diff is positive, then we have more than is needed
        int256 _diff = int256(_totalBeingSwapped) - int256(_neededInSwap);

        // Instead of checking if diff is positive or not, we compare against the platform fee. This is to avoid any rounding issues
        if (_diff > _platformFee) {
          _tokenInSwap.reward = uint256(_diff - _platformFee);
        } else if (_diff < _platformFee) {
          _tokenInSwap.toProvide = uint256(_platformFee - _diff);
        }
        _tokenInSwap.platformFee = uint256(_platformFee);
      }
      _swapInformation.tokens[i] = _tokenInSwap;
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAHubSwapHandler
  function swap(
    address[] calldata _tokens,
    PairIndexes[] calldata _pairsToSwap,
    address _rewardRecipient,
    address _callbackHandler,
    uint256[] calldata _borrow,
    bytes calldata _callbackData,
    bytes calldata _oracleData
  ) public nonReentrant whenNotPaused returns (SwapInfo memory _swapInformation) {
    // Note: we are caching this variable in memory so we can read storage only once (it's cheaper that way)
    uint32 _swapFee = swapFee;

    {
      _swapInformation = getNextSwapInfo(_tokens, _pairsToSwap, hasRole(PRIVILEGED_SWAPPER_ROLE, msg.sender), _oracleData);

      uint32 _timestamp = _getTimestamp();
      bool _executedAPair;
      for (uint256 i = 0; i < _swapInformation.pairs.length; ) {
        PairInSwap memory _pairInSwap = _swapInformation.pairs[i];
        bytes1 _intervalsInSwap = _pairInSwap.intervalsInSwap;
        bytes1 _mask = 0x01;
        while (_intervalsInSwap >= _mask && _mask > 0) {
          if (_intervalsInSwap & _mask != 0) {
            _registerSwap(
              _pairInSwap.tokenA,
              _pairInSwap.tokenB,
              _mask,
              _subtractFeeFromAmount(_swapFee, _pairInSwap.ratioAToB),
              _subtractFeeFromAmount(_swapFee, _pairInSwap.ratioBToA),
              _timestamp
            );
            if (!_executedAPair) {
              _executedAPair = true;
            }
          }
          _mask <<= 1;
        }
        unchecked {
          i++;
        }
      }

      if (!_executedAPair) {
        revert NoSwapsToExecute();
      }
    }

    uint256[] memory _beforeBalances = new uint256[](_swapInformation.tokens.length);
    for (uint256 i = 0; i < _swapInformation.tokens.length; ) {
      TokenInSwap memory _tokenInSwap = _swapInformation.tokens[i];

      uint256 _amountToBorrow = _borrow[i];

      // Remember balances before callback
      if (_tokenInSwap.toProvide > 0 || _amountToBorrow > 0) {
        _beforeBalances[i] = _balanceOf(_tokenInSwap.token);
      }

      // Optimistically transfer tokens
      if (_rewardRecipient == _callbackHandler) {
        uint256 _amountToSend = _tokenInSwap.reward + _amountToBorrow;
        _transfer(_tokenInSwap.token, _callbackHandler, _amountToSend);
      } else {
        _transfer(_tokenInSwap.token, _rewardRecipient, _tokenInSwap.reward);
        _transfer(_tokenInSwap.token, _callbackHandler, _amountToBorrow);
      }
      unchecked {
        i++;
      }
    }

    // Make call
    IDCAHubSwapCallee(_callbackHandler).DCAHubSwapCall(msg.sender, _swapInformation.tokens, _borrow, _callbackData);

    // Checks and balance updates
    for (uint256 i = 0; i < _swapInformation.tokens.length; ) {
      TokenInSwap memory _tokenInSwap = _swapInformation.tokens[i];
      uint256 _addToPlatformBalance = _tokenInSwap.platformFee;

      if (_tokenInSwap.toProvide > 0 || _borrow[i] > 0) {
        uint256 _amountToHave = _beforeBalances[i] + _tokenInSwap.toProvide - _tokenInSwap.reward;

        uint256 _currentBalance = _balanceOf(_tokenInSwap.token);

        // Make sure tokens were sent back
        if (_currentBalance < _amountToHave) {
          revert IDCAHub.LiquidityNotReturned();
        }

        // Any extra tokens that might have been received, are set as platform balance
        _addToPlatformBalance += (_currentBalance - _amountToHave);
      }

      // Update platform balance
      if (_addToPlatformBalance > 0) {
        platformBalance[_tokenInSwap.token] += _addToPlatformBalance;
      }
      unchecked {
        i++;
      }
    }

    // Emit event
    emit Swapped(msg.sender, _rewardRecipient, _callbackHandler, _swapInformation, _borrow, _swapFee);
  }

  // Note: This is almost exactly as FeeMath.subtractFeeFromAmount, but without dividing by FEE_PRECISION.
  // We will make that division when calculating how much was swapped. By doing so, we don't lose precision which,
  // in the case of tokens with a small amount of decimals (like USDC), can end up being a lot of funds
  function _subtractFeeFromAmount(uint32 _fee, uint256 _amount) internal pure returns (uint256) {
    return _amount * (FeeMath.FEE_PRECISION - _fee / 100);
  }

  function _markIntervalAsInactive(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask
  ) internal {
    activeSwapIntervals[_tokenA][_tokenB] &= ~_swapIntervalMask;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '../libraries/Intervals.sol';
import '../libraries/FeeMath.sol';
import './DCAHubParameters.sol';

abstract contract DCAHubConfigHandler is DCAHubParameters, AccessControl, Pausable, IDCAHubConfigHandler {
  // Internal constants (all should be constants, but apparently the byte code size increases when they are)
  // solhint-disable var-name-mixedcase
  bytes32 public IMMEDIATE_ROLE = keccak256('IMMEDIATE_ROLE');
  bytes32 public TIME_LOCKED_ROLE = keccak256('TIME_LOCKED_ROLE');
  // solhint-enable var-name-mixedcase
  bytes32 public constant PLATFORM_WITHDRAW_ROLE = keccak256('PLATFORM_WITHDRAW_ROLE');
  bytes32 public constant PRIVILEGED_SWAPPER_ROLE = keccak256('PRIVILEGED_SWAPPER_ROLE');
  /// @inheritdoc IDCAHubConfigHandler
  uint32 public constant MAX_FEE = 100000; // 10%
  /// @inheritdoc IDCAHubConfigHandler
  uint16 public constant MAX_PLATFORM_FEE_RATIO = 10000;

  /// @inheritdoc IDCAHubConfigHandler
  ITokenPriceOracle public oracle;
  /// @inheritdoc IDCAHubConfigHandler
  uint32 public swapFee = 6000; // 0.6%
  /// @inheritdoc IDCAHubConfigHandler
  bytes1 public allowedSwapIntervals = 0xF0; // Start allowing weekly, daily, every 4 hours, hourly
  /// @inheritdoc IDCAHubConfigHandler
  uint16 public platformFeeRatio = 2500; // 25%
  /// @inheritdoc IDCAHubConfigHandler
  mapping(address => bool) public override allowedTokens;
  /// @inheritdoc IDCAHubConfigHandler
  mapping(address => uint120) public override tokenMagnitude;

  constructor(
    address _immediateGovernor,
    address _timeLockedGovernor,
    ITokenPriceOracle _oracle
  ) {
    if (_immediateGovernor == address(0) || _timeLockedGovernor == address(0) || address(_oracle) == address(0)) revert IDCAHub.ZeroAddress();
    _setupRole(IMMEDIATE_ROLE, _immediateGovernor);
    _setupRole(TIME_LOCKED_ROLE, _timeLockedGovernor);
    _setRoleAdmin(PLATFORM_WITHDRAW_ROLE, IMMEDIATE_ROLE);
    _setRoleAdmin(PRIVILEGED_SWAPPER_ROLE, IMMEDIATE_ROLE);
    // We set each role as its own admin, so they can assign new addresses with the same role
    _setRoleAdmin(IMMEDIATE_ROLE, IMMEDIATE_ROLE);
    _setRoleAdmin(TIME_LOCKED_ROLE, TIME_LOCKED_ROLE);
    oracle = _oracle;
  }

  function setAllowedTokens(address[] calldata _tokens, bool[] calldata _allowed) external onlyRole(IMMEDIATE_ROLE) {
    if (_tokens.length != _allowed.length) revert InvalidAllowedTokensInput();
    for (uint256 i = 0; i < _tokens.length; ) {
      address _token = _tokens[i];
      allowedTokens[_token] = _allowed[i];
      if (tokenMagnitude[_token] == 0) {
        tokenMagnitude[_token] = uint120(10**IERC20Metadata(_token).decimals());
      }
      unchecked {
        i++;
      }
    }
    emit TokensAllowedUpdated(_tokens, _allowed);
  }

  /// @inheritdoc IDCAHubConfigHandler
  function setOracle(ITokenPriceOracle _oracle) external onlyRole(TIME_LOCKED_ROLE) {
    _assertNonZeroAddress(address(_oracle));
    oracle = _oracle;
    emit OracleSet(_oracle);
  }

  /// @inheritdoc IDCAHubConfigHandler
  function setSwapFee(uint32 _swapFee) external onlyRole(TIME_LOCKED_ROLE) {
    _validateFee(_swapFee);
    swapFee = _swapFee;
    emit SwapFeeSet(_swapFee);
  }

  /// @inheritdoc IDCAHubConfigHandler
  function setPlatformFeeRatio(uint16 _platformFeeRatio) external onlyRole(TIME_LOCKED_ROLE) {
    if (_platformFeeRatio > MAX_PLATFORM_FEE_RATIO) revert HighPlatformFeeRatio();
    platformFeeRatio = _platformFeeRatio;
    emit PlatformFeeRatioSet(_platformFeeRatio);
  }

  /// @inheritdoc IDCAHubConfigHandler
  function addSwapIntervalsToAllowedList(uint32[] calldata _swapIntervals) external onlyRole(IMMEDIATE_ROLE) {
    for (uint256 i = 0; i < _swapIntervals.length; ) {
      allowedSwapIntervals |= Intervals.intervalToMask(_swapIntervals[i]);
      unchecked {
        i++;
      }
    }
    emit SwapIntervalsAllowed(_swapIntervals);
  }

  /// @inheritdoc IDCAHubConfigHandler
  function removeSwapIntervalsFromAllowedList(uint32[] calldata _swapIntervals) external onlyRole(IMMEDIATE_ROLE) {
    for (uint256 i = 0; i < _swapIntervals.length; ) {
      allowedSwapIntervals &= ~Intervals.intervalToMask(_swapIntervals[i]);
      unchecked {
        i++;
      }
    }
    emit SwapIntervalsForbidden(_swapIntervals);
  }

  /// @inheritdoc IDCAHubConfigHandler
  function pause() external onlyRole(IMMEDIATE_ROLE) {
    _pause();
  }

  /// @inheritdoc IDCAHubConfigHandler
  function unpause() external onlyRole(IMMEDIATE_ROLE) {
    _unpause();
  }

  /// @inheritdoc IDCAHubConfigHandler
  function paused() public view virtual override(IDCAHubConfigHandler, Pausable) returns (bool) {
    return super.paused();
  }

  function _validateFee(uint32 _fee) internal pure {
    if (_fee > MAX_FEE) revert HighFee();
    if (_fee % 100 != 0) revert InvalidFee();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './DCAHubConfigHandler.sol';

abstract contract DCAHubPlatformHandler is ReentrancyGuard, DCAHubConfigHandler, IDCAHubPlatformHandler {
  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IDCAHubPlatformHandler
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata _amounts, address _recipient)
    external
    nonReentrant
    onlyRole(PLATFORM_WITHDRAW_ROLE)
  {
    for (uint256 i = 0; i < _amounts.length; ) {
      platformBalance[_amounts[i].token] -= _amounts[i].amount;
      _transfer(_amounts[i].token, _recipient, _amounts[i].amount);
      unchecked {
        i++;
      }
    }

    emit WithdrewFromPlatform(msg.sender, _recipient, _amounts);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@mean-finance/oracles/solidity/interfaces/ITokenPriceOracle.sol';
import './IDCAPermissionManager.sol';

/**
 * @title The interface for all state related queries
 * @notice These methods allow users to read the hubs's current values
 */
interface IDCAHubParameters {
  /**
   * @notice Returns how much will the amount to swap differ from the previous swap. f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return swapDeltaAToB How much less of token A will the following swap require
   * @return swapDeltaBToA How much less of token B will the following swap require
   */
  function swapAmountDelta(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint128 swapDeltaAToB, uint128 swapDeltaBToA);

  /**
   * @notice Returns the sum of the ratios reported in all swaps executed until the given swap number
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return accumRatioAToB The sum of all ratios from A to B
   * @return accumRatioBToA The sum of all ratios from B to A
   */
  function accumRatio(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint256 accumRatioAToB, uint256 accumRatioBToA);

  /**
   * @notice Returns swapping information about a specific pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @return performedSwaps How many swaps have been executed
   * @return nextAmountToSwapAToB How much of token A will be swapped on the next swap
   * @return lastSwappedAt Timestamp of the last swap
   * @return nextAmountToSwapBToA How much of token B will be swapped on the next swap
   */
  function swapData(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask
  )
    external
    view
    returns (
      uint32 performedSwaps,
      uint224 nextAmountToSwapAToB,
      uint32 lastSwappedAt,
      uint224 nextAmountToSwapBToA
    );

  /**
   * @notice Returns the byte representation of the set of actice swap intervals for the given pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA The smaller of the pair's token
   * @param tokenB The other of the pair's token
   * @return The byte representation of the set of actice swap intervals
   */
  function activeSwapIntervals(address tokenA, address tokenB) external view returns (bytes1);

  /**
   * @notice Returns how much of the hub's token balance belongs to the platform
   * @param token The token to check
   * @return The amount that belongs to the platform
   */
  function platformBalance(address token) external view returns (uint256);
}

/**
 * @title The interface for all position related matters
 * @notice These methods allow users to create, modify and terminate their positions
 */
interface IDCAHubPositionHandler {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint120 rate;
  }

  /// @notice A list of positions that all have the same `to` token
  struct PositionSet {
    // The `to` token
    address token;
    // The position ids
    uint256[] positionIds;
  }

  /**
   * @notice Emitted when a position is terminated
   * @param user The address of the user that terminated the position
   * @param recipientUnswapped The address of the user that will receive the unswapped tokens
   * @param recipientSwapped The address of the user that will receive the swapped tokens
   * @param positionId The id of the position that was terminated
   * @param returnedUnswapped How many "from" tokens were returned to the caller
   * @param returnedSwapped How many "to" tokens were returned to the caller
   */
  event Terminated(
    address indexed user,
    address indexed recipientUnswapped,
    address indexed recipientSwapped,
    uint256 positionId,
    uint256 returnedUnswapped,
    uint256 returnedSwapped
  );

  /**
   * @notice Emitted when a position is created
   * @param depositor The address of the user that creates the position
   * @param owner The address of the user that will own the position
   * @param positionId The id of the position that was created
   * @param fromToken The address of the "from" token
   * @param toToken The address of the "to" token
   * @param swapInterval How frequently the position's swaps should be executed
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   * @param permissions The permissions defined for the position
   */
  event Deposited(
    address indexed depositor,
    address indexed owner,
    uint256 positionId,
    address fromToken,
    address toToken,
    uint32 swapInterval,
    uint120 rate,
    uint32 startingSwap,
    uint32 lastSwap,
    IDCAPermissionManager.PermissionSet[] permissions
  );

  /**
   * @notice Emitted when a position is created and extra data is provided
   * @param positionId The id of the position that was created
   * @param data The extra data that was provided
   */
  event Miscellaneous(uint256 positionId, bytes data);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from a position
   * @param withdrawer The address of the user that executed the withdraw
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positionId The id of the position that was affected
   * @param token The address of the withdrawn tokens. It's the same as the position's "to" token
   * @param amount The amount that was withdrawn
   */
  event Withdrew(address indexed withdrawer, address indexed recipient, uint256 positionId, address token, uint256 amount);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from many positions
   * @param withdrawer The address of the user that executed the withdraws
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positions The positions to withdraw from
   * @param withdrew The total amount that was withdrawn from each token
   */
  event WithdrewMany(address indexed withdrawer, address indexed recipient, PositionSet[] positions, uint256[] withdrew);

  /**
   * @notice Emitted when a position is modified
   * @param user The address of the user that modified the position
   * @param positionId The id of the position that was modified
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   */
  event Modified(address indexed user, uint256 positionId, uint120 rate, uint32 startingSwap, uint32 lastSwap);

  /// @notice Thrown when a user tries to create a position with the same `from` & `to`
  error InvalidToken();

  /// @notice Thrown when a user tries to create a position with a swap interval that is not allowed
  error IntervalNotAllowed();

  /// @notice Thrown when a user tries operate on a position that doesn't exist (it might have been already terminated)
  error InvalidPosition();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /// @notice Thrown when a user tries to create a position with zero swaps
  error ZeroSwaps();

  /// @notice Thrown when a user tries to create a position with zero funds
  error ZeroAmount();

  /// @notice Thrown when a user tries to withdraw a position whose `to` token doesn't match the specified one
  error PositionDoesNotMatchToken();

  /// @notice Thrown when a user tries create or modify a position with an amount too big
  error AmountTooBig();

  /**
   * @notice Returns the permission manager contract
   * @return The contract itself
   */
  function permissionManager() external view returns (IDCAPermissionManager);

  /**
   * @notice Returns total created positions
   * @return The total created positions
   */
  function totalCreatedPositions() external view returns (uint256);

  /**
   * @notice Returns a user position
   * @param positionId The id of the position
   * @return position The position itself
   */
  function userPosition(uint256 positionId) external view returns (UserPosition memory position);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions
  ) external returns (uint256 positionId);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @param miscellaneous Bytes that will be emitted, and associated with the position
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external returns (uint256 positionId);

  /**
   * @notice Withdraws all swapped tokens from a position to a recipient
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipient is zero
   * @param positionId The position's id
   * @param recipient The address to withdraw swapped tokens to
   * @return swapped How much was withdrawn
   */
  function withdrawSwapped(uint256 positionId, address recipient) external returns (uint256 swapped);

  /**
   * @notice Withdraws all swapped tokens from multiple positions
   * @dev Will revert:
   *      - With InvalidPosition if any of the position ids are invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position to any of the given positions
   *      - With ZeroAddress if recipient is zero
   *      - With PositionDoesNotMatchToken if any of the positions do not match the token in their position set
   * @param positions A list positions, grouped by `to` token
   * @param recipient The address to withdraw swapped tokens to
   * @return withdrawn How much was withdrawn for each token
   */
  function withdrawSwappedMany(PositionSet[] calldata positions, address recipient) external returns (uint256[] memory withdrawn);

  /**
   * @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With AmountTooBig if amount is too big
   * @param positionId The position's id
   * @param amount Amount of funds to add to the position
   * @param newSwaps The new amount of swaps
   */
  function increasePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps
  ) external;

  /**
   * @notice Withdraws the specified amount from the unswapped balance and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroSwaps if newSwaps is zero and amount is not the total unswapped balance
   * @param positionId The position's id
   * @param amount Amount of funds to withdraw from the position
   * @param newSwaps The new amount of swaps
   * @param recipient The address to send tokens to
   */
  function reducePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps,
    address recipient
  ) external;

  /**
   * @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipientUnswapped or recipientSwapped is zero
   * @param positionId The position's id
   * @param recipientUnswapped The address to withdraw unswapped tokens to
   * @param recipientSwapped The address to withdraw swapped tokens to
   * @return unswapped The unswapped balance sent to `recipientUnswapped`
   * @return swapped The swapped balance sent to `recipientSwapped`
   */
  function terminate(
    uint256 positionId,
    address recipientUnswapped,
    address recipientSwapped
  ) external returns (uint256 unswapped, uint256 swapped);
}

/**
 * @title The interface for all swap related matters
 * @notice These methods allow users to get information about the next swap, and how to execute it
 */
interface IDCAHubSwapHandler {
  /// @notice Information about a swap
  struct SwapInfo {
    // The tokens involved in the swap
    TokenInSwap[] tokens;
    // The pairs involved in the swap
    PairInSwap[] pairs;
  }

  /// @notice Information about a token's role in a swap
  struct TokenInSwap {
    // The token's address
    address token;
    // How much will be given of this token as a reward
    uint256 reward;
    // How much of this token needs to be provided by swapper
    uint256 toProvide;
    // How much of this token will be paid to the platform
    uint256 platformFee;
  }

  /// @notice Information about a pair in a swap
  struct PairInSwap {
    // The address of one of the tokens
    address tokenA;
    // The address of the other token
    address tokenB;
    // The total amount of token A swapped in this pair
    uint256 totalAmountToSwapTokenA;
    // The total amount of token B swapped in this pair
    uint256 totalAmountToSwapTokenB;
    // How much is 1 unit of token A when converted to B
    uint256 ratioAToB;
    // How much is 1 unit of token B when converted to A
    uint256 ratioBToA;
    // The swap intervals involved in the swap, represented as a byte
    bytes1 intervalsInSwap;
  }

  /// @notice A pair of tokens, represented by their indexes in an array
  struct PairIndexes {
    // The index of the token A
    uint8 indexTokenA;
    // The index of the token B
    uint8 indexTokenB;
  }

  /**
   * @notice Emitted when a swap is executed
   * @param sender The address of the user that initiated the swap
   * @param rewardRecipient The address that received the reward
   * @param callbackHandler The address that executed the callback
   * @param swapInformation All information related to the swap
   * @param borrowed How much was borrowed
   * @param fee The swap fee at the moment of the swap
   */
  event Swapped(
    address indexed sender,
    address indexed rewardRecipient,
    address indexed callbackHandler,
    SwapInfo swapInformation,
    uint256[] borrowed,
    uint32 fee
  );

  /// @notice Thrown when pairs indexes are not sorted correctly
  error InvalidPairs();

  /// @notice Thrown when trying to execute a swap, but there is nothing to swap
  error NoSwapsToExecute();

  /**
   * @notice Returns all information related to the next swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   * @param tokens The tokens involved in the next swap
   * @param pairs The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the next swap information for privileged and non-privileged accounts
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return swapInformation The information about the next swap
   */
  function getNextSwapInfo(
    address[] calldata tokens,
    PairIndexes[] calldata pairs,
    bool calculatePrivilegedAvailability,
    bytes calldata oracleData
  ) external view returns (SwapInfo memory swapInformation);

  /**
   * @notice Executes a flash swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   *      - With Paused if swaps are paused by protocol
   *      - With NoSwapsToExecute if there are no swaps to execute for the given pairs
   *      - With LiquidityNotReturned if the required tokens were not back during the callback
   * @param tokens The tokens involved in the next swap
   * @param pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param rewardRecipient The address to send the reward to
   * @param callbackHandler Address to call for callback (and send the borrowed tokens to)
   * @param borrow How much to borrow of each of the tokens in tokens. The amount must match the position of the token in the tokens array
   * @param callbackData Bytes to send to the caller during the callback
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return Information about the executed swap
   */
  function swap(
    address[] calldata tokens,
    PairIndexes[] calldata pairsToSwap,
    address rewardRecipient,
    address callbackHandler,
    uint256[] calldata borrow,
    bytes calldata callbackData,
    bytes calldata oracleData
  ) external returns (SwapInfo memory);
}

/**
 * @title The interface for handling all configuration
 * @notice This contract will manage configuration that affects all pairs, swappers, etc
 */
interface IDCAHubConfigHandler {
  /**
   * @notice Emitted when a new oracle is set
   * @param oracle The new oracle contract
   */
  event OracleSet(ITokenPriceOracle oracle);

  /**
   * @notice Emitted when a new swap fee is set
   * @param feeSet The new swap fee
   */
  event SwapFeeSet(uint32 feeSet);

  /**
   * @notice Emitted when new swap intervals are allowed
   * @param swapIntervals The new swap intervals
   */
  event SwapIntervalsAllowed(uint32[] swapIntervals);

  /**
   * @notice Emitted when some swap intervals are no longer allowed
   * @param swapIntervals The swap intervals that are no longer allowed
   */
  event SwapIntervalsForbidden(uint32[] swapIntervals);

  /**
   * @notice Emitted when a new platform fee ratio is set
   * @param platformFeeRatio The new platform fee ratio
   */
  event PlatformFeeRatioSet(uint16 platformFeeRatio);

  /**
   * @notice Emitted when allowed states of tokens are updated
   * @param tokens Array of updated tokens
   * @param allowed Array of new allow state per token were allowed[i] is the updated state of tokens[i]
   */
  event TokensAllowedUpdated(address[] tokens, bool[] allowed);

  /// @notice Thrown when trying to interact with an unallowed token
  error UnallowedToken();

  /// @notice Thrown when set allowed tokens input is not valid
  error InvalidAllowedTokensInput();

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to set a fee that is not multiple of 100
  error InvalidFee();

  /// @notice Thrown when trying to set a fee ratio that is higher that the maximum allowed
  error HighPlatformFeeRatio();

  /**
   * @notice Returns the max fee ratio that can be set
   * @dev Cannot be modified
   * @return The maximum possible value
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_PLATFORM_FEE_RATIO() external view returns (uint16);

  /**
   * @notice Returns the fee charged on swaps
   * @return swapFee The fee itself
   */
  function swapFee() external view returns (uint32 swapFee);

  /**
   * @notice Returns the price oracle contract
   * @return oracle The contract itself
   */
  function oracle() external view returns (ITokenPriceOracle oracle);

  /**
   * @notice Returns how much will the platform take from the fees collected in swaps
   * @return The current ratio
   */
  function platformFeeRatio() external view returns (uint16);

  /**
   * @notice Returns the max fee that can be set for swaps
   * @dev Cannot be modified
   * @return maxFee The maximum possible fee
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 maxFee);

  /**
   * @notice Returns a byte that represents allowed swap intervals
   * @return allowedSwapIntervals The allowed swap intervals
   */
  function allowedSwapIntervals() external view returns (bytes1 allowedSwapIntervals);

  /**
   * @notice Returns if a token is currently allowed or not
   * @return Allowed state of token
   */
  function allowedTokens(address token) external view returns (bool);

  /**
   * @notice Returns token's magnitude (10**decimals)
   * @return Stored magnitude for token
   */
  function tokenMagnitude(address token) external view returns (uint120);

  /**
   * @notice Returns whether swaps and deposits are currently paused
   * @return isPaused Whether swaps and deposits are currently paused
   */
  function paused() external view returns (bool isPaused);

  /**
   * @notice Sets a new swap fee
   * @dev Will revert with HighFee if the fee is higher than the maximum
   * @dev Will revert with InvalidFee if the fee is not multiple of 100
   * @param fee The new swap fee
   */
  function setSwapFee(uint32 fee) external;

  /**
   * @notice Sets a new price oracle
   * @dev Will revert with ZeroAddress if the zero address is passed
   * @param oracle The new oracle contract
   */
  function setOracle(ITokenPriceOracle oracle) external;

  /**
   * @notice Sets a new platform fee ratio
   * @dev Will revert with HighPlatformFeeRatio if given ratio is too high
   * @param platformFeeRatio The new ratio
   */
  function setPlatformFeeRatio(uint16 platformFeeRatio) external;

  /**
   * @notice Adds new swap intervals to the allowed list
   * @param swapIntervals The new swap intervals
   */
  function addSwapIntervalsToAllowedList(uint32[] calldata swapIntervals) external;

  /**
   * @notice Removes some swap intervals from the allowed list
   * @param swapIntervals The swap intervals to remove
   */
  function removeSwapIntervalsFromAllowedList(uint32[] calldata swapIntervals) external;

  /// @notice Pauses all swaps and deposits
  function pause() external;

  /// @notice Unpauses all swaps and deposits
  function unpause() external;
}

/**
 * @title The interface for handling platform related actions
 * @notice This contract will handle all actions that affect the platform in some way
 */
interface IDCAHubPlatformHandler {
  /**
   * @notice Emitted when someone withdraws from the paltform balance
   * @param sender The address of the user that initiated the withdraw
   * @param recipient The address that received the withdraw
   * @param amounts The tokens (and the amount) that were withdrawn
   */
  event WithdrewFromPlatform(address indexed sender, address indexed recipient, IDCAHub.AmountOfToken[] amounts);

  /**
   * @notice Withdraws tokens from the platform balance
   * @param amounts The amounts to withdraw
   * @param recipient The address that will receive the tokens
   */
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata amounts, address recipient) external;
}

interface IDCAHub is IDCAHubParameters, IDCAHubConfigHandler, IDCAHubSwapHandler, IDCAHubPositionHandler, IDCAHubPlatformHandler {
  /// @notice Specifies an amount of a token. For example to determine how much to borrow from certain tokens
  struct AmountOfToken {
    // The tokens' address
    address token;
    // How much to borrow or withdraw of the specified token
    uint256 amount;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the expected liquidity is not returned in flash swaps
  error LiquidityNotReturned();

  /// @notice Thrown when a list of token pairs is not sorted, or if there are duplicates
  error InvalidTokens();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.6;

/// @title TokenSorting library
/// @notice Provides functions to sort tokens easily
library TokenSorting {
  /// @notice Takes two tokens, and returns them sorted
  /// @param _tokenA One of the tokens
  /// @param _tokenB The other token
  /// @return __tokenA The first of the tokens
  /// @return __tokenB The second of the tokens
  function sortTokens(address _tokenA, address _tokenB) internal pure returns (address __tokenA, address __tokenB) {
    (__tokenA, __tokenB) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for an oracle that provides price quotes
 * @notice These methods allow users to add support for pairs, and then ask for quotes
 */
interface ITokenPriceOracle {
  /// @notice Thrown when trying to add support for a pair that cannot be supported
  error PairCannotBeSupported(address tokenA, address tokenB);

  /// @notice Thrown when trying to execute a quote with a pair that isn't supported yet
  error PairNotSupportedYet(address tokenA, address tokenB);

  /**
   * @notice Returns whether this oracle can support the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens can be supported by the oracle
   */
  function canSupportPair(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns whether this oracle is already supporting the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens is already being supported by the oracle
   */
  function isPairAlreadySupported(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns a quote, based on the given tokens and amount
   * @dev Will revert if pair isn't supported
   * @param tokenIn The token that will be provided
   * @param amountIn The amount that will be provided
   * @param tokenOut The token we would like to quote
   * @param data Custom data that the oracle might need to operate
   * @return amountOut How much `tokenOut` will be returned in exchange for `amountIn` amount of `tokenIn`
   */
  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    bytes calldata data
  ) external view returns (uint256 amountOut);

  /**
   * @notice Add or reconfigures the support for a given pair. This function will let the oracle take some actions
   *         to configure the pair, in preparation for future quotes. Can be called many times in order to let the oracle
   *         re-configure for a new context
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addOrModifySupportForPair(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;

  /**
   * @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
   *         then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation
   *         for future quotes
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addSupportForPairIfNeeded(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@mean-finance/nft-descriptors/solidity/interfaces/IDCAHubPositionDescriptor.sol';

interface IERC721BasicEnumerable {
  /**
   * @notice Count NFTs tracked by this contract
   * @return A count of valid NFTs tracked by this contract, where each one of
   *         them has an assigned and queryable owner not equal to the zero address
   */
  function totalSupply() external view returns (uint256);
}

/**
 * @title The interface for all permission related matters
 * @notice These methods allow users to set and remove permissions to their positions
 */
interface IDCAPermissionManager is IERC721, IERC721BasicEnumerable {
  /// @notice Set of possible permissions
  enum Permission {
    INCREASE,
    REDUCE,
    WITHDRAW,
    TERMINATE
  }

  /// @notice A set of permissions for a specific operator
  struct PermissionSet {
    // The address of the operator
    address operator;
    // The permissions given to the overator
    Permission[] permissions;
  }

  /// @notice A collection of permissions sets for a specific position
  struct PositionPermissions {
    // The id of the token
    uint256 tokenId;
    // The permissions to assign to the position
    PermissionSet[] permissionSets;
  }

  /**
   * @notice Emitted when permissions for a token are modified
   * @param tokenId The id of the token
   * @param permissions The set of permissions that were updated
   */
  event Modified(uint256 tokenId, PermissionSet[] permissions);

  /**
   * @notice Emitted when the address for a new descritor is set
   * @param descriptor The new descriptor contract
   */
  event NFTDescriptorSet(IDCAHubPositionDescriptor descriptor);

  /// @notice Thrown when a user tries to set the hub, once it was already set
  error HubAlreadySet();

  /// @notice Thrown when a user provides a zero address when they shouldn't
  error ZeroAddress();

  /// @notice Thrown when a user calls a method that can only be executed by the hub
  error OnlyHubCanExecute();

  /// @notice Thrown when a user tries to modify permissions for a token they do not own
  error NotOwner();

  /// @notice Thrown when a user tries to execute a permit with an expired deadline
  error ExpiredDeadline();

  /// @notice Thrown when a user tries to execute a permit with an invalid signature
  error InvalidSignature();

  /**
   * @notice The permit typehash used in the permit signature
   * @return The typehash for the permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the permission permit signature
   * @return The typehash for the permission permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the multi permission permit signature
   * @return The typehash for the multi permission permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function MULTI_PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the permission permit signature
   * @return The typehash for the permission set
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_SET_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the multi permission permit signature
   * @return The typehash for the position permissions
   */
  // solhint-disable-next-line func-name-mixedcase
  function POSITION_PERMISSIONS_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The domain separator used in the permit signature
   * @return The domain seperator used in encoding of permit signature
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the NFT descriptor contract
   * @return The contract for the NFT descriptor
   */
  function nftDescriptor() external returns (IDCAHubPositionDescriptor);

  /**
   * @notice Returns the address of the DCA Hub
   * @return The address of the DCA Hub
   */
  function hub() external returns (address);

  /**
   * @notice Returns the next nonce to use for a given user
   * @param user The address of the user
   * @return nonce The next nonce to use
   */
  function nonces(address user) external returns (uint256 nonce);

  /**
   * @notice Returns whether the given address has the permission for the given token
   * @param id The id of the token to check
   * @param account The address of the user to check
   * @param permission The permission to check
   * @return Whether the user has the permission or not
   */
  function hasPermission(
    uint256 id,
    address account,
    Permission permission
  ) external view returns (bool);

  /**
   * @notice Returns whether the given address has the permissions for the given token
   * @param id The id of the token to check
   * @param account The address of the user to check
   * @param permissions The permissions to check
   * @return hasPermissions Whether the user has each permission or not
   */
  function hasPermissions(
    uint256 id,
    address account,
    Permission[] calldata permissions
  ) external view returns (bool[] memory hasPermissions);

  /**
   * @notice Sets the address for the hub
   * @dev Can only be successfully executed once. Once it's set, it can be modified again
   *      Will revert:
   *      - With ZeroAddress if address is zero
   *      - With HubAlreadySet if the hub has already been set
   * @param hub The address to set for the hub
   */
  function setHub(address hub) external;

  /**
   * @notice Mints a new NFT with the given id, and sets the permissions for it
   * @dev Will revert with OnlyHubCanExecute if the caller is not the hub
   * @param id The id of the new NFT
   * @param owner The owner of the new NFT
   * @param permissions Permissions to set for the new NFT
   */
  function mint(
    uint256 id,
    address owner,
    PermissionSet[] calldata permissions
  ) external;

  /**
   * @notice Burns the NFT with the given id, and clears all permissions
   * @dev Will revert with OnlyHubCanExecute if the caller is not the hub
   * @param id The token's id
   */
  function burn(uint256 id) external;

  /**
   * @notice Sets new permissions for the given position
   * @dev Will revert with NotOwner if the caller is not the token's owner.
   *      Operators that are not part of the given permission sets do not see their permissions modified.
   *      In order to remove permissions to an operator, provide an empty list of permissions for them
   * @param id The token's id
   * @param permissions A list of permission sets
   */
  function modify(uint256 id, PermissionSet[] calldata permissions) external;

  /**
   * @notice Sets new permissions for the given positions
   * @dev This is basically the same as executing multiple `modify`
   * @param permissions A list of position permissions to set
   */
  function modifyMany(PositionPermissions[] calldata permissions) external;

  /**
   * @notice Approves spending of a specific token ID by spender via signature
   * @param spender The account that is being approved
   * @param tokenId The ID of the token that is being approved for spending
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets permissions via signature
   * @dev This method works similarly to `modifyMany`, but instead of being executed by the owner, it can be set by signature
   * @param permissions The permissions to set for the different positions
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function multiPermissionPermit(
    PositionPermissions[] calldata permissions,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets permissions via signature
   * @dev This method works similarly to `modify`, but instead of being executed by the owner, it can be set my signature
   * @param permissions The permissions to set
   * @param tokenId The token's id
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permissionPermit(
    PermissionSet[] calldata permissions,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets a new NFT descriptor
   * @dev Will revert with ZeroAddress if address is zero
   * @param descriptor The new NFT descriptor contract
   */
  function setNFTDescriptor(IDCAHubPositionDescriptor descriptor) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @title The interface for generating a description for a position in a DCA Hub
 * @notice Contracts that implement this interface must return a base64 JSON with the entire description
 */
interface IDCAHubPositionDescriptor {
  /**
   * @notice Generates a positions's description, both the JSON and the image inside
   * @param hub The address of the DCA Hub
   * @param positionId The token/position id
   * @return description The position's description
   */
  function tokenURI(address hub, uint256 positionId) external view returns (string memory description);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/// @title Intervals library
/// @notice Provides functions to easily convert from swap intervals to their byte representation and viceversa
library Intervals {
  /// @notice Thrown when a user tries convert and invalid interval to a byte representation
  error InvalidInterval();

  /// @notice Thrown when a user tries convert and invalid byte representation to an interval
  error InvalidMask();

  /// @notice Takes a swap interval and returns its byte representation
  /// @dev Will revert with InvalidInterval if the swap interval is not valid
  /// @param _swapInterval The swap interval
  /// @return The interval's byte representation
  function intervalToMask(uint32 _swapInterval) internal pure returns (bytes1) {
    if (_swapInterval == 1 minutes) return 0x01;
    if (_swapInterval == 5 minutes) return 0x02;
    if (_swapInterval == 15 minutes) return 0x04;
    if (_swapInterval == 30 minutes) return 0x08;
    if (_swapInterval == 1 hours) return 0x10;
    if (_swapInterval == 4 hours) return 0x20;
    if (_swapInterval == 1 days) return 0x40;
    if (_swapInterval == 1 weeks) return 0x80;
    revert InvalidInterval();
  }

  /// @notice Takes a byte representation of a swap interval and returns the swap interval
  /// @dev Will revert with InvalidMask if the byte representation is not valid
  /// @param _mask The byte representation
  /// @return The swap interval
  function maskToInterval(bytes1 _mask) internal pure returns (uint32) {
    if (_mask == 0x01) return 1 minutes;
    if (_mask == 0x02) return 5 minutes;
    if (_mask == 0x04) return 15 minutes;
    if (_mask == 0x08) return 30 minutes;
    if (_mask == 0x10) return 1 hours;
    if (_mask == 0x20) return 4 hours;
    if (_mask == 0x40) return 1 days;
    if (_mask == 0x80) return 1 weeks;
    revert InvalidMask();
  }

  /// @notice Takes a byte representation of a set of swap intervals and returns which ones are in the set
  /// @dev Will always return an array of length 8, with zeros at the end if there are less than 8 intervals
  /// @param _byte The byte representation
  /// @return _intervals The swap intervals in the set
  function intervalsInByte(bytes1 _byte) internal pure returns (uint32[] memory _intervals) {
    _intervals = new uint32[](8);
    uint8 _index;
    bytes1 _mask = 0x01;
    while (_byte >= _mask && _mask > 0) {
      if (_byte & _mask != 0) {
        _intervals[_index++] = maskToInterval(_mask);
      }
      _mask <<= 1;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/// @title Fee Math library
/// @notice Provides functions to calculate and apply fees to amounts
library FeeMath {
  /// @notice How much would a 1% fee be
  uint24 public constant FEE_PRECISION = 10000;

  /// @notice Takes a fee and an amount that has had the fee subtracted, and returns the amount that was subtracted
  /// @param _fee Fee that was applied
  /// @param _subtractionResult Amount that had the fee subtracted
  /// @return The amount that was subtracted
  function calculateSubtractedFee(uint32 _fee, uint256 _subtractionResult) internal pure returns (uint256) {
    return (_subtractionResult * _fee) / (FEE_PRECISION * 100 - _fee);
  }

  /// @notice Takes a fee and applies it to a certain amount. So if fee is 0.6%, it would return the 0.6% of the given amount
  /// @param _fee Fee to apply
  /// @param _amount Amount to apply the fee to
  /// @return The calculated fee
  function calculateFeeForAmount(uint32 _fee, uint256 _amount) internal pure returns (uint256) {
    return (_amount * _fee) / FEE_PRECISION / 100;
  }

  /// @notice Takes a fee and a certain amount, and subtracts the fee. So if fee is 0.6%, it would return 99.4% of the given amount
  /// @param _fee Fee to subtract
  /// @param _amount Amount that subtract the fee from
  /// @return The amount with the fee subtracted
  function subtractFeeFromAmount(uint32 _fee, uint256 _amount) internal pure returns (uint256) {
    return (_amount * (FEE_PRECISION - _fee / 100)) / FEE_PRECISION;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IDCAHub.sol';

/**
 * @title The interface for handling flash swaps
 * @notice Users that want to execute flash swaps must implement this interface
 */
interface IDCAHubSwapCallee {
  // solhint-disable-next-line func-name-mixedcase
  function DCAHubSwapCall(
    address sender,
    IDCAHub.TokenInSwap[] calldata tokens,
    uint256[] calldata borrowed,
    bytes calldata data
  ) external;
}