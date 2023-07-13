/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title OracleRelay Interface
/// @notice Interface for interacting with OracleRelay
interface IOracleRelay {
  /// @notice Emited when the underlyings are different in the anchored view
  error OracleRelay_DifferentUnderlyings();

  enum OracleType {
    Chainlink,
    Uniswap,
    Price
  }

  /// @notice returns the price with 18 decimals
  /// @return _currentValue the current price
  function currentValue() external returns (uint256 _currentValue);

  /// @notice returns the price with 18 decimals without any state changes
  /// @dev some oracles require a state change to get the exact current price.
  ///      This is updated when calling other state changing functions that query the price
  /// @return _price the current price
  function peekValue() external view returns (uint256 _price);

  /// @notice returns the type of the oracle
  /// @return _type the type (Chainlink/Uniswap/Price)
  function oracleType() external view returns (OracleType _type);

  /// @notice returns the underlying asset the oracle is pricing
  /// @return _underlying the address of the underlying asset
  function underlying() external view returns (address _underlying);
}

abstract contract OracleRelay is IOracleRelay {
  /// @notice The WETH address
  address public constant wETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  /// @notice The type of oracle
  OracleType public oracleType;
  /// @notice The underlying asset
  address public underlying;

  constructor(OracleType _oracleType) {
    oracleType = _oracleType;
  }

  /// @notice set the underlying address
  function _setUnderlying(address _underlying) internal {
    underlying = _underlying;
  }

  /// @dev Most oracles don't require a state change for pricing, for those who do, override this function
  function currentValue() external virtual returns (uint256 _currentValue) {
    _currentValue = peekValue();
  }

  /// @notice The current reported value of the oracle
  /// @dev Implementation in _get()
  /// @return _price The current value
  function peekValue() public view virtual override returns (uint256 _price);
}

interface IChainlinkOracleRelay {
  /// @notice Returns True if the oracle is stale
  function isStale() external view returns (bool _stale);
}

/// @notice Implementation of compounds' AnchoredView, using a main relay and an anchor relay, the AnchoredView
/// ensures that the main relay's price is within some amount of the anchor relay price
/// if not, the call reverts, effectively disabling the oracle & any actions which require it
contract AnchoredViewRelay is OracleRelay {
  /// @notice The interface of the anchor relay
  IOracleRelay public anchorRelay;

  /// @notice The interface of the main relay
  IOracleRelay public mainRelay;

  /// @notice The numerator of the allowable deviation from the anchor price
  uint256 public widthNumerator;

  /// @notice The denominator of the allowable deviation from the anchor price
  uint256 public widthDenominator;

  /// @notice The numerator of the allowable deviation from the anchor price for the stale price
  uint256 public staleWidthNumerator;

  /// @notice The denominator of the allowable deviation from the anchor price for the stale price
  uint256 public staleWidthDenominator;

  /// @notice All values set at construction time
  /// @param _anchorAddress The address of OracleRelay to use as anchor
  /// @param _mainAddress The address of OracleRelay to use as main
  /// @param _widthNumerator The numerator of the allowable deviation width
  /// @param _widthDenominator The denominator of the allowable deviation width
  /// @param _widthNumerator The numerator of the allowable deviation width for the stale price
  /// @param _widthDenominator The denominator of the allowable deviation width for the stale price
  constructor(
    address _anchorAddress,
    address _mainAddress,
    uint256 _widthNumerator,
    uint256 _widthDenominator,
    uint256 _staleWidthNumerator,
    uint256 _staleWidthDenominator
  ) OracleRelay(IOracleRelay(_mainAddress).oracleType()) {
    anchorRelay = IOracleRelay(_anchorAddress);

    mainRelay = IOracleRelay(_mainAddress);

    address _underlying = anchorRelay.underlying();

    /// Ensure the two relays have the same underlying
    if (_underlying != mainRelay.underlying()) revert OracleRelay_DifferentUnderlyings();

    /// Set the underlying
    _setUnderlying(_underlying);

    widthNumerator = _widthNumerator;
    widthDenominator = _widthDenominator;

    staleWidthNumerator = _staleWidthNumerator;
    staleWidthDenominator = _staleWidthDenominator;
  }

  /// @notice returns the price with 18 decimals without any state changes
  /// @dev some oracles require a state change to get the exact current price.
  ///      This is updated when calling other state changing functions that query the price
  /// @return _price the current price
  function peekValue() public view override returns (uint256 _price) {
    _price = _getLastSecond();
  }

  /// @notice Compares the main value (chainlink) to the anchor value (uniswap v3)
  /// @dev The two prices must closely match +-buffer, or it will revert
  /// @return _mainValue The current value of oracle
  function _getLastSecond() private view returns (uint256 _mainValue) {
    // get the main price
    _mainValue = mainRelay.peekValue();
    require(_mainValue > 0, 'invalid oracle value');

    uint256 _anchorPrice = anchorRelay.peekValue();
    require(_anchorPrice > 0, 'invalid anchor value');

    uint256 _buffer;
    if (IChainlinkOracleRelay(address(mainRelay)).isStale()) {
      /// If the price is stale the range percentage is smaller
      _buffer = (staleWidthNumerator * _anchorPrice) / staleWidthDenominator;
    } else {
      _buffer = (widthNumerator * _anchorPrice) / widthDenominator;
    }

    // create upper and lower bounds
    uint256 _upperBounds = _anchorPrice + _buffer;
    uint256 _lowerBounds = _anchorPrice - _buffer;

    // ensure the anchor price is within bounds
    require(_mainValue < _upperBounds, 'anchor too low');
    require(_mainValue > _lowerBounds, 'anchor too high');
  }
}