//Get Funds from users
// withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    // uint256 public number;
    uint256 public minimumUsd = 50;

    function fund() public payable {
        // Want to be able to set a minum fund amount
        // 1. How do we sen Eth to this contract
        // number = 5;
        require(msg.value > 1e18, "Didn't send enough");
    }

    function getPrice() public view returns (uint256){
        // ABI
        // 0xA39434A63A52E749F02807ae27335515BA4b07F7
        // AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7)
        //     .version();
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
        (, int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
      uint256 ethPrice = getPrice();
      uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
      return ethAmountInUsd;
    }
    // function withdraw(){};
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