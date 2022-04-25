/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: MIT

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


contract PriceConverter {
    address private _ethusd = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address private _eurusd = 0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13;

    function getDerivedPrice()
        public
        view
        returns (int256)
    {
        ( , int256 basePrice, , , ) = AggregatorV3Interface(_ethusd).latestRoundData();
        ( , int256 quotePrice, , , ) = AggregatorV3Interface(_eurusd).latestRoundData();
        return basePrice * int256(18) / quotePrice;
    }

}