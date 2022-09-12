// SPDX-License-Identifier: MIT

pragma solidity >=0.0.6 <0.9.0;

import "AggregatorV3Interface.sol";

contract Lottery {
    address payable[] players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;


    constructor(address _price_feed_address) public {         // _priceFeedAddress: Parameter der im deploy.py Ã¼bergeben werden muss
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_price_feed_address);   // gets the PriceFeed contract address from deploy.py
    }
    
    
    function enter() public payable {
        players.push(payable(msg.sender));
    }


    function getEntrenceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;  
        return costToEnter;
    }


    function startLottery() public {
    }
 


    function endLottery() public {
    }


}

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