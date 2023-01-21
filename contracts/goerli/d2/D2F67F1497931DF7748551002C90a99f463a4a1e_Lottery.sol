// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "AggregatorV3Interface.sol";

contract Lottery {
    address payable[] public players;
    uint256 public usdfee;
    AggregatorV3Interface internal ethUsdPriceFeed;

    constructor(address _priceFeedAddress) {
        usdfee = 50;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        uint256 feeinWei = getFeeInWei();
    }

    function enter() public payable {
        // minimum $50
        // require();
        players.push(payable(msg.sender));
    }

    function getFeeInWei() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 ethPrice = uint256(price); // USD per ETH * 10**8
        // USD / USD per ETH y *10**18 para obtener en WEI
        return uint256((usdfee * 10**8 * 10**18) / ethPrice);
    }

    function startLottery() public {}

    function endLottery() public {}
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