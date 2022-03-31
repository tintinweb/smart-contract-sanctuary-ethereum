// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "AggregatorV3Interface.sol";

contract Lottery {
    address payable[] public players;
    uint256 public usdEntranceFee;
    AggregatorV3Interface internal ethUsdPriceFeed;

    constructor(address _priceFeedAddress) {
        usdEntranceFee = 50 * (10**18);
        // Network : Kovan
        // 0x9326BFA02ADD2366b30bacB125260Af641031331
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function enter() public payable {
        players.push(payable(msg.sender));
    }

    // function getEntranceFee() public view returns (uint256) {
    function getEntranceFee() public view returns (int256, uint8) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();
        uint8 decimals = ethUsdPriceFeed.decimals();
        return (answer, decimals);
    }

    function startLottery() public {}

    function endLottery() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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