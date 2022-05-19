// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Lottery {
  address payable[] public players;
  uint256 public usdEntryFee;
  AggregatorV3Interface internal ethToUsdPriceFeed;
  

  constructor(address _ethToUsdPriceFeed) {
    usdEntryFee = 50 * (10**18);
    ethToUsdPriceFeed = AggregatorV3Interface(_ethToUsdPriceFeed);
  }

  function enter() public payable {
    require(msg.value >= getEntranceFee(), "what?");
    players.push(payable(msg.sender));
  }

  function getEntranceFee() public view returns(uint256) {
    (,int price,,,) = ethToUsdPriceFeed.latestRoundData();
    // uint256 adjustPrice = uint256(price) * 10**10;
    return (usdEntryFee * 10**18) / uint256(price);
  }

  function startLottery() public {
    
  }

  function endLottery() public {}
}

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