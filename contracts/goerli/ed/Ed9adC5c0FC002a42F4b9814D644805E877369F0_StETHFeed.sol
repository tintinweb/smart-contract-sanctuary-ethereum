// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface StETH {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}
contract StETHFeed {

    AggregatorV3Interface constant ETH_USD = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    StETH constant STETH = StETH(0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F);

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ETH_USD.latestRoundData();
        if (price < 0) {
            return (uint80(0), 0, uint(0), uint(0), uint80(0));
        }

        uint256 ethAmount = STETH.getPooledEthByShares(1e18);
        uint256 realPrice = (ethAmount * uint(price * (10**10)))/1e18;
        realPrice /= 1e10;

        return (uint80(0), int(realPrice), uint(0), uint(0), uint80(0));
    }
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