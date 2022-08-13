// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BrokerDefiPriceConsumer {

    AggregatorV3Interface internal priceFeed;

    uint nftPrice = 2500_000_000_000; // 2500 in usdt

    uint public raiseToPower = 8; // for final price calculation

    uint public divider = 1_00_000_000;

    address payable public test = payable(0xA97F7EB14da5568153Ea06b2656ccF7c338d942f);

    constructor() {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function getLatestEthPrice() public view returns (uint) {
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    function getTokenPriceInEth() public view returns(uint) {
        return ((nftPrice / (getLatestEthPrice() / divider)) * 10**raiseToPower);
    }

    function getTokenPriceInEth(uint price, uint _divider, uint _raiseToPower) public payable returns(uint) {
        require(msg.value >= ((price / (getLatestEthPrice() / _divider)) * 10**_raiseToPower), "insuffecient value");
        test.transfer(((price / (getLatestEthPrice() / _divider)) * 10**_raiseToPower));
        return ((price / (getLatestEthPrice() / _divider)) * 10**_raiseToPower);
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