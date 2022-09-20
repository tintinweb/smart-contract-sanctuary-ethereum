// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './interfaces/IJBPriceFeed.sol';
import './libraries/JBFixedPointNumber.sol';

/** 
  @notice 
  A generalized price feed for the Chainlink AggregatorV3Interface.

  @dev
  Adheres to -
  IJBPriceFeed: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
contract JBChainlinkV3PriceFeed is IJBPriceFeed {
  // A library that provides utility for fixed point numbers.
  using JBFixedPointNumber for uint256;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error STALE_PRICE();
  error INCOMPLETE_ROUND();
  error NEGATIVE_PRICE();

  //*********************************************************************//
  // ---------------- public stored immutable properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    The feed that prices are reported from.
  */
  AggregatorV3Interface public immutable feed;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Gets the current price from the feed, normalized to the specified number of decimals.

    @param _decimals The number of decimals the returned fixed point price should include.

    @return The current price of the feed, as a fixed point number with the specified number of decimals.
  */
  function currentPrice(uint256 _decimals) external view override returns (uint256) {
    // Get the latest round information.
    (uint80 roundId, int256 _price, , uint256 updatedAt, uint80 answeredInRound) = feed
      .latestRoundData();

    // Make sure the price isn't stale.
    if (answeredInRound < roundId) revert STALE_PRICE();

    // Make sure the round is finished.
    if (updatedAt == 0) revert INCOMPLETE_ROUND();

    // Make sure the price is positive.
    if (_price < 0) revert NEGATIVE_PRICE();

    // Get a reference to the number of decimals the feed uses.
    uint256 _feedDecimals = feed.decimals();

    // Return the price, adjusted to the target decimals.
    return uint256(_price).adjustDecimals(_feedDecimals, _decimals);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _feed The feed to report prices from.
  */
  constructor(AggregatorV3Interface _feed) {
    feed = _feed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library JBFixedPointNumber {
  function adjustDecimals(
    uint256 _value,
    uint256 _decimals,
    uint256 _targetDecimals
  ) internal pure returns (uint256) {
    // If decimals need adjusting, multiply or divide the price by the decimal adjuster to get the normalized result.
    if (_targetDecimals == _decimals) return _value;
    else if (_targetDecimals > _decimals) return _value * 10**(_targetDecimals - _decimals);
    else return _value / 10**(_decimals - _targetDecimals);
  }
}