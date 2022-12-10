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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GetCoinCost.sol";

contract CoinCost {
    using GetCoinCost for uint;

    AggregatorV3Interface public priceFeed;

    constructor(AggregatorV3Interface priceFeedAddress) {
        priceFeed = priceFeedAddress;
    }

    function getCost(uint ethAmount) public view returns (uint) {
        uint price = ethAmount.convertETH(priceFeed);
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library GetCoinCost {
    function getETHCost(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function convertETH(uint ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        uint ethPrice = getETHCost(priceFeed);
        uint ethInUSD = (ethPrice * ethAmount) / 1e18;
        return ethInUSD;
    }
}