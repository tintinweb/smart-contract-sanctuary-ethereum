// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '../interfaces/oracles/IOracleAggregator.sol';
import '../libraries/TokenSorting.sol';
import '../utils/Governable.sol';

contract OracleAggregator is Governable, IOracleAggregator {
  // Note: by default oracle 1 will take precendence over oracle 2
  /// @inheritdoc IOracleAggregator
  IPriceOracle public immutable oracle1;
  /// @inheritdoc IOracleAggregator
  IPriceOracle public immutable oracle2;
  mapping(address => mapping(address => OracleInUse)) internal _oracleInUse;

  constructor(
    IPriceOracle _oracle1,
    IPriceOracle _oracle2,
    address _governor
  ) Governable(_governor) {
    require(address(_oracle1) != address(0) && address(_oracle2) != address(0), 'ZeroAddress');
    oracle1 = _oracle1;
    oracle2 = _oracle2;
  }

  /// @inheritdoc IPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool) {
    return oracle1.canSupportPair(_tokenA, _tokenB) || oracle2.canSupportPair(_tokenA, _tokenB);
  }

  /// @inheritdoc IPriceOracle
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut) {
    (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_tokenIn, _tokenOut);
    OracleInUse _inUse = _oracleInUse[_tokenA][_tokenB];
    require(_inUse != OracleInUse.NONE, 'PairNotSupported');
    if (_inUse == OracleInUse.ORACLE_1) {
      return oracle1.quote(_tokenIn, _amountIn, _tokenOut);
    } else {
      return oracle2.quote(_tokenIn, _amountIn, _tokenOut);
    }
  }

  /// @inheritdoc IOracleAggregator
  function oracleInUse(address _tokenA, address _tokenB) external view returns (OracleInUse) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    return _oracleInUse[__tokenA][__tokenB];
  }

  /// @inheritdoc IPriceOracle
  function reconfigureSupportForPair(address _tokenA, address _tokenB) external onlyGovernor {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    _addSupportForPair(__tokenA, __tokenB);
  }

  /// @inheritdoc IPriceOracle
  function addSupportForPairIfNeeded(address _tokenA, address _tokenB) external {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    if (_oracleInUse[__tokenA][__tokenB] == OracleInUse.NONE) {
      _addSupportForPair(__tokenA, __tokenB);
    }
  }

  /// @inheritdoc IOracleAggregator
  function setOracleForPair(
    address _tokenA,
    address _tokenB,
    OracleInUse _oracle
  ) external onlyGovernor {
    if (_oracle == OracleInUse.ORACLE_1) {
      oracle1.addSupportForPairIfNeeded(_tokenA, _tokenB);
    } else if (_oracle == OracleInUse.ORACLE_2) {
      oracle2.addSupportForPairIfNeeded(_tokenA, _tokenB);
    } else {
      revert InvalidOracle();
    }
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    _setOracleInUse(__tokenA, __tokenB, _oracle);
  }

  function _addSupportForPair(address _tokenA, address _tokenB) internal virtual {
    if (oracle1.canSupportPair(_tokenA, _tokenB)) {
      oracle1.reconfigureSupportForPair(_tokenA, _tokenB);
      _setOracleInUse(_tokenA, _tokenB, OracleInUse.ORACLE_1);
    } else {
      oracle2.reconfigureSupportForPair(_tokenA, _tokenB);
      _setOracleInUse(_tokenA, _tokenB, OracleInUse.ORACLE_2);
    }
  }

  function _setOracleInUse(
    address _tokenA,
    address _tokenB,
    OracleInUse _oracle
  ) internal {
    _oracleInUse[_tokenA][_tokenB] = _oracle;
    emit OracleSetForUse(_tokenA, _tokenB, _oracle);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './IPriceOracle.sol';

/// @title An implementation of IPriceOracle that aggregates two other oracles
/// @notice This oracle will use two other oracles to support price quotes
interface IOracleAggregator is IPriceOracle {
  /// @notice The oracle that is currently in use by a specific pair
  enum OracleInUse {
    // No oracle is being used right now for the pair
    NONE,
    // Oracle 1 is being used for the pair
    ORACLE_1,
    // Oracle 2 is being used for the pair
    ORACLE_2
  }

  /// @notice Emitted when a new oracle is set for use for a pair
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param oracleInUse The oracle that will be used for the pair
  event OracleSetForUse(address tokenA, address tokenB, OracleInUse oracleInUse);

  /// @notice Thrown when trying to set an invalid oracle for use
  error InvalidOracle();

  /// @notice Returns the first oracle of the two being aggregated
  /// @return The first oracle
  function oracle1() external view returns (IPriceOracle);

  /// @notice Returns the second oracle of the two being aggregated
  /// @return The second oracle
  function oracle2() external view returns (IPriceOracle);

  /// @notice Returns the oracle that is being used for the given pair
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @return The oracle that is being used for the given pair
  function oracleInUse(address _tokenA, address _tokenB) external view returns (OracleInUse);

  /// @notice Sets the oracle for the given pair, and initializes the oracle if necessary
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function setOracleForPair(
    address _tokenA,
    address _tokenB,
    OracleInUse _oracle
  ) external;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;

interface IGovernable {
  event PendingGovernorSet(address pendingGovernor);
  event PendingGovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;

  function governor() external view returns (address);

  function pendingGovernor() external view returns (address);

  function isGovernor(address _account) external view returns (bool _isGovernor);

  function isPendingGovernor(address _account) external view returns (bool _isPendingGovernor);
}

abstract contract Governable is IGovernable {
  address private _governor;
  address private _pendingGovernor;

  constructor(address __governor) {
    require(__governor != address(0), 'Governable: zero address');
    _governor = __governor;
  }

  function governor() external view override returns (address) {
    return _governor;
  }

  function pendingGovernor() external view override returns (address) {
    return _pendingGovernor;
  }

  function setPendingGovernor(address __pendingGovernor) external virtual override onlyGovernor {
    _setPendingGovernor(__pendingGovernor);
  }

  function _setPendingGovernor(address __pendingGovernor) internal {
    require(__pendingGovernor != address(0), 'Governable: zero address');
    _pendingGovernor = __pendingGovernor;
    emit PendingGovernorSet(__pendingGovernor);
  }

  function acceptPendingGovernor() external virtual override onlyPendingGovernor {
    _acceptPendingGovernor();
  }

  function _acceptPendingGovernor() internal {
    require(_pendingGovernor != address(0), 'Governable: no pending governor');
    _governor = _pendingGovernor;
    _pendingGovernor = address(0);
    emit PendingGovernorAccepted();
  }

  function isGovernor(address _account) public view override returns (bool _isGovernor) {
    return _account == _governor;
  }

  function isPendingGovernor(address _account) public view override returns (bool _isPendingGovernor) {
    return _account == _pendingGovernor;
  }

  modifier onlyGovernor() {
    require(isGovernor(msg.sender), 'Governable: only governor');
    _;
  }

  modifier onlyPendingGovernor() {
    require(isPendingGovernor(msg.sender), 'Governable: only pending governor');
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for an oracle that provides price quotes
/// @notice These methods allow users to add support for pairs, and then ask for quotes
interface IPriceOracle {
  /// @notice Returns whether this oracle can support this pair of tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  /// @return Whether the given pair of tokens can be supported by the oracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool);

  /// @notice Returns a quote, based on the given tokens and amount
  /// @param _tokenIn The token that will be provided
  /// @param _amountIn The amount that will be provided
  /// @param _tokenOut The token we would like to quote
  /// @return _amountOut How much _tokenOut will be returned in exchange for _amountIn amount of _tokenIn
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut);

  /// @notice Reconfigures support for a given pair. This function will let the oracle take some actions to configure the pair, in
  /// preparation for future quotes. Can be called many times in order to let the oracle re-configure for a new context.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function reconfigureSupportForPair(address _tokenA, address _tokenB) external;

  /// @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
  /// then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation for future quotes.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function addSupportForPairIfNeeded(address _tokenA, address _tokenB) external;
}