// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IPriceOracle.sol";
import "./PriceOracleStorage.sol";

contract PriceOracle is IPriceOracle, PriceOracleStorage {
  function setPriceAggregator(address asset, address aggregator) external {
    _priceAggregators[asset] = IPriceAggregator(aggregator);
  }

  function queryAssetPrice(
    address asset,
    uint timeframe
  ) external view virtual returns (uint price, uint lastUpdate) {
    IPriceAggregator aggregator = _priceAggregators[asset];
    require(address(aggregator) != address(0), "Aggregator is not registered");
    (price, lastUpdate) = _priceAggregators[asset].currentPrice();
    require(lastUpdate >= block.timestamp - timeframe, "Can not fetch the latest price");
    require(price > 0, "Price should be larger than 0");
  }

  function queryIsExistPriceAggregator(address asset) external view returns (bool) {
    return address(_priceAggregators[asset]) != address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceAggregator {
  function currentPrice() external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceOracle {
  function setPriceAggregator(address token, address aggregator) external;

  function queryAssetPrice(address asset, uint timeframe) external view returns (uint, uint);

  function queryIsExistPriceAggregator(address asset) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IPriceAggregator.sol";

contract PriceOracleStorage {
  mapping(address => IPriceAggregator) internal _priceAggregators;
}