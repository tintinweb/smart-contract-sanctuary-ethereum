// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "AggregatorV3Interface.sol";

contract Lottery {
    address payable[] public players;
    uint256 public usdEntryFee;
    //ETH / USD Sepolia Testnet 0x694AA1769357215DE4FAC081bf1f309aDC325306
    AggregatorV3Interface internal ethUSDpriceFeed;

    constructor(address _priceFeedAddress) public {
        usdEntryFee = 1000 * (10 ** 18);
        ethUSDpriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function enter() public payable {
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUSDpriceFeed.latestRoundData();
        uint256 adjustedprice = uint256(price) * 10 ** 10;
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedprice;
        return uint256(costToEnter);
    }

    function startLottery() public {}

    function endLottery() public {}
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