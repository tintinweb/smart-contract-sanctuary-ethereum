// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract Conversion{
    AggregatorV3Interface public price_feed;
    constructor(address feed_address) public{
        price_feed=AggregatorV3Interface(feed_address);
    }

    function get_version() public view returns(uint256){    
        return price_feed.version();
    }

    function eth2picousd() public view returns(uint256){
        (,int256 price,,,)=price_feed.latestRoundData();
        uint8 decimals=price_feed.decimals();
        uint256 price_in_picousd=uint256(price) * (uint256(10)**uint256(12-decimals));
        return price_in_picousd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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