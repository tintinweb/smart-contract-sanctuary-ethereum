// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ReturnPriceContract {

    mapping (address => AggregatorV3Interface) public priceFeeds;
    constructor() {
        priceFeeds[0x45442CB17bD3E3C0AeaE92BF425473E582d5e740] = AggregatorV3Interface(0x48731cF7e84dc94C5f84577882c14Be11a5B7456);
    }

    function getLatestPrice(address currencyAddress) public view returns (uint256) {
    AggregatorV3Interface priceFeed = priceFeeds[currencyAddress];
    require(address(priceFeed) != address(0), "Price feed not found");

    (, int price, , , ) = priceFeed.latestRoundData();
    require(price > 0, "Invalid price");

    uint256 scaledPrice = uint256(price) * 1e10;
    return scaledPrice;
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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