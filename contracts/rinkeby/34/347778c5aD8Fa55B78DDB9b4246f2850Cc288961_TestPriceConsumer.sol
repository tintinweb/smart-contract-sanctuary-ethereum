// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TestPriceConsumer {
    AggregatorV3Interface internal priceFeed;
    address payable public owner;
    uint public usdValue;

    //KOVAN Testnet ETH/USD feed
    constructor() payable {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        owner = payable(msg.sender);
        //get the USD value of the amount deposited at deployment and store
        usdValue = (getLastEthPriceUSD() * (msg.value / 10**18)) * 10**18;
    }

    //Get the current USD price of ETH from chainlink price feeds
    function getLastEthPriceUSD() public view returns (uint) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price);
    }

    //For testing purposes to get test ETH back
    function withdraw() public {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
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