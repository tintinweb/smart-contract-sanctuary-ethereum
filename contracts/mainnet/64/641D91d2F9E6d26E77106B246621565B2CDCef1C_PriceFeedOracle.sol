// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IPriceFeedOracle.sol";

/// @title PriceFeedOracle
/// @author Bluejay Core Team
/// @notice PriceFeedOracle combines multiple Chainlink oracle price feed to provide 
/// an single aggregated price feed
contract PriceFeedOracle is IPriceFeedOracle {
  uint8 private constant decimals = 18;
  uint256 private constant WAD = 10**decimals;

  /// @notice List of aggregators to get the price feeds from
  Feed[] public path;

  /// @notice Contructor of the price feed oracle
  /// @dev If you need the SGD/DAI price and only have the SGD/USD and DAI/USD price feed,
  /// You can obtain the SGD/DAI by dividing the SGD/USD price by the DAI/USD price.
  /// To perform the division, set the invert flag to true for the DAI/USD price feed.
  /// For the purpose of the price stabilizer, we always use the <stablecoin>/<reserve> pair,
  /// Where the stablecoin is the base, and the reserve currency is the quote.
  /// @param aggregators List of Chainlink (V3) aggregator to get the price feeds from
  /// @param inverts List of boolean to check if we should invert the price
  constructor(address[] memory aggregators, bool[] memory inverts) {
    require(aggregators.length == inverts.length, "Mismatched arrays");
    for (uint256 i = 0; i < aggregators.length; i++) {
      path.push(
        Feed({
          aggregator: AggregatorV3Interface(aggregators[i]),
          decimals: AggregatorV3Interface(aggregators[i]).decimals(),
          invert: inverts[i]
        })
      );
    }
  }

  /// @notice Get the price of the stablecoin against reserve asset
  /// @dev The base currency should be the stablecoin, and the quote currency should be the reserve asset
  /// @return price Price of the stablecoin
  function getPrice() public view override returns (uint256 price) {
    uint256 numerator = WAD;
    uint256 denominator = 1;
    uint256 pathLength = path.length;
    for (uint256 i = 0; i < pathLength; i++) {
      Feed memory feed = path[i];
      (, int256 feedPrice, , , ) = feed.aggregator.latestRoundData();
      uint256 scaledPrice = uint256(
        scalePrice(feedPrice, feed.decimals, decimals)
      );
      if (feed.invert) {
        numerator *= WAD;
        denominator *= scaledPrice;
      } else {
        numerator *= scaledPrice;
        denominator *= WAD;
      }
    }
    price = numerator / denominator;
  }

  /// @notice Internal function to scale the price feed to the correct decimals
  /// @dev The decimals are obtained from the Chainlink aggregator directly
  /// @return price Price, scaled to WAD
  function scalePrice(
    int256 _price,
    uint8 _priceDecimals,
    uint8 _targetDecimals
  ) internal pure returns (int256) {
    if (_priceDecimals < _targetDecimals) {
      return _price * int256(10**uint256(_targetDecimals - _priceDecimals));
    } else if (_priceDecimals > _targetDecimals) {
      return _price / int256(10**uint256(_priceDecimals - _targetDecimals));
    }
    return _price;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../external/AggregatorV3Interface.sol";

interface IPriceFeedOracle {
  struct Feed {
    AggregatorV3Interface aggregator;
    uint8 decimals;
    bool invert;
  }

  function getPrice() external view returns (uint256 price);
  
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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