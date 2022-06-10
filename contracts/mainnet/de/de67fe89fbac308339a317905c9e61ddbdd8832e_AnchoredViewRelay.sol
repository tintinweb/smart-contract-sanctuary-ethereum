// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IOracleRelay.sol";

/// @title implementation of compounds' AnchoredView
/// @notice using a main relay and an anchor relay, the AnchoredView
/// ensures that the main relay's price is within some amount of the anchor relay price
/// if not, the call reverts, effectively disabling the oracle & any actions which require it
contract AnchoredViewRelay is IOracleRelay {
  address public _anchorAddress;
  IOracleRelay public _anchorRelay;

  address public _mainAddress;
  IOracleRelay public _mainRelay;

  uint256 public _widthNumerator;
  uint256 public _widthDenominator;

  /// @notice all values set at construction time
  /// @param anchor_address address of OracleRelay to use as anchor
  /// @param main_address address of OracleRelay to use as main
  /// @param widthNumerator numerator of the allowable deviation width
  /// @param widthDenominator denominator of the allowable deviation width
  constructor(
    address anchor_address,
    address main_address,
    uint256 widthNumerator,
    uint256 widthDenominator
  ) {
    _anchorAddress = anchor_address;
    _anchorRelay = IOracleRelay(anchor_address);

    _mainAddress = main_address;
    _mainRelay = IOracleRelay(main_address);

    _widthNumerator = widthNumerator;
    _widthDenominator = widthDenominator;
  }

  /// @notice returns current value of oracle
  /// @return current value of oracle
  /// @dev implementation in getLastSecond
  function currentValue() external view override returns (uint256) {
    return getLastSecond();
  }

  /// @notice compares the main value (chainlink) to the anchor value (uniswap v3)
  /// @notice the two prices must closely match +-buffer, or it will revert
  function getLastSecond() private view returns (uint256) {
    // get the main price
    uint256 mainValue = _mainRelay.currentValue();
    require(mainValue > 0, "invalid oracle value");

    // get anchor price
    uint256 anchorPrice = _anchorRelay.currentValue();
    require(anchorPrice > 0, "invalid anchor value");

    // calculate buffer
    uint256 buffer = (_widthNumerator * anchorPrice) / _widthDenominator;

    // create upper and lower bounds
    uint256 upperBounds = anchorPrice + buffer;
    uint256 lowerBounds = anchorPrice - buffer;

    // ensure the anchor price is within bounds
    require(mainValue < upperBounds, "anchor too low");
    require(mainValue > lowerBounds, "anchor too high");

    // return mainValue
    return mainValue;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title OracleRelay Interface
/// @notice Interface for interacting with OracleRelay
interface IOracleRelay {
  // returns  price with 18 decimals
  function currentValue() external view returns (uint256);
}