// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "AggregatorV3Interface.sol";

contract GetPrice {
    // ethusd 合约地址
    address constant ETHUSDADRESS = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
    
    AggregatorV3Interface priceFeed;
    constructor() {
        priceFeed = AggregatorV3Interface(ETHUSDADRESS);
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    //function to get the version of the chainlink pricefeed
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        // ethPrice单位是wei => usd
        uint256 ethAmountInUsd = ethPrice * ethAmount / 1e18;
        return ethAmountInUsd;
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