/**
 *Submitted for verification at Etherscan.io on 2022-06-02
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

contract TestNFT {
    AggregatorV3Interface internal ethToUSDPriceFeed;
    uint256 public accountETH;
    uint256 public accountUSD;

    uint256 constant tokenDecimal = 10;

    constructor() {
        ethToUSDPriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        accountETH = 10 * 10**tokenDecimal;
    }

    function buyETH(uint256 usdAmount) external {
        require(accountUSD >= usdAmount, "Not enough USD");
        (
            /*uint80 roundID*/,
            int256 ethPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethToUSDPriceFeed.latestRoundData();

        uint256 priceDecimal = ethToUSDPriceFeed.decimals();
        uint256 ethAmount =  (usdAmount * 10**priceDecimal) / uint256(ethPrice);
        accountUSD -= usdAmount;
        accountETH += ethAmount;
    }

    function sellETH(uint256 ethAmount) external {
        require(accountETH >= ethAmount, "Not enough USD");
        (
            /*uint80 roundID*/,
            int256 ethPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethToUSDPriceFeed.latestRoundData();

        uint256 priceDecimal = ethToUSDPriceFeed.decimals();
        uint256 usdAmount =  (ethAmount * uint256(ethPrice)) / (10**priceDecimal);
        accountUSD += usdAmount;
        accountETH -= ethAmount;
    }

    function accountValueInETH() public view returns (uint256)  {
        uint256 usdToETH = 0;
        uint256 totalAmountInETH = 0;
        if (accountUSD > 0) {
            (
            /*uint80 roundID*/,
            int256 ethPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
            ) = ethToUSDPriceFeed.latestRoundData();

            uint256 priceDecimal = ethToUSDPriceFeed.decimals();
            usdToETH =  (accountUSD * 10**priceDecimal) / uint256(ethPrice);
        }
        totalAmountInETH = accountETH + usdToETH;
        return totalAmountInETH;
    }


    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethToUSDPriceFeed.latestRoundData();
        return price;
    }
}