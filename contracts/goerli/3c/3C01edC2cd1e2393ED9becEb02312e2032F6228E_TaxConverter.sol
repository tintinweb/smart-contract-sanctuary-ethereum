//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library TaxConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function _nairaToDolar(uint256 price, uint256 _rate)
        internal
        pure
        returns (uint256)
    {
        return price * _rate;
    }

    function getTaxPrice(
        uint256 totalPriceInNairaForADayTrip,
        AggregatorV3Interface priceFeed,
        uint256 rate,
        uint256 busCapacity,
        uint256 taxRate
    ) internal view returns (uint256) {
        uint256 price = totalPriceInNairaForADayTrip * busCapacity;
        uint256 ethAmount = _nairaToDolar(price, rate) * 10**18;
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        uint256 tax = (ethAmountInUsd * taxRate) / 100;
        return tax;
    }
}

//fisrt get the tax price, buscapacity, tax rate
// tp 500 naira, 15, 5
//covert 200 to $ using rate
//convert $ to gwei

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