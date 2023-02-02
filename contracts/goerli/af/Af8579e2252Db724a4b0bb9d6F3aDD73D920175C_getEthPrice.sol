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
pragma solidity 0.8.18;

//V2.0

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract getEthPrice {

    AggregatorV3Interface internal immutable i_priceFeed;

    constructor(address priceFeedAddress) {
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function getEthPriceInUSD() public view returns (uint) {
        /*
        roundId: The round ID.
        answer: The price.
        startedAt: Timestamp of when the round started.
        updatedAt: Timestamp of when the round was updated.
        answeredInRound: The round ID of the round in which the answer was computed.
        
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData(); */
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        return uint256(price);
    }
}