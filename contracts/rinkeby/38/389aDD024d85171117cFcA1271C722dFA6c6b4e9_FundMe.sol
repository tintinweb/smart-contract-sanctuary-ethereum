// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./PriceConverter.sol";

contract FundMe {
  using PriceConverter for uint256;

  address private me;
  uint256 public minimumUsd = 1 * 10**18;

  address[] public funders;
  mapping(address => uint256) public moneyFunded;

  constructor() {
    me = msg.sender;
  }

  modifier onlyMe() {
    require(msg.sender == me, "Only Carl can call this function.");
    _;
  }

  function fund() public payable {
    require(msg.value.getConversionRate() >= minimumUsd, "Not enough sent. Minimum of $1.00");
    if (moneyFunded[msg.sender] > 0) {
      moneyFunded[msg.sender] += msg.value;
    } else {   
      funders.push(msg.sender);
      moneyFunded[msg.sender] = msg.value;
    }
  }

  function withdraw() public payable onlyMe {
    for (uint256 i; i < funders.length; i++) {
      address funder = funders[i];
      moneyFunded[funder] = 0;
    }
    funders = new address[](0);
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success, "Withdraw failed.");
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getNumOfFunders() public view returns (uint256) {
    return funders.length;
  }

  function conversionRate() public view returns (uint256) {
    return PriceConverter.getPrice();
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e -> ETH/USD (Rinkeby)
  function getPrice() internal view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(
      0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    );
    (, int256 price, , , ) = priceFeed.latestRoundData();
    // price will always return with 8 extra decimal places
    // msg.value has 18 decimal places
    // 10 = 18 - 8
    return uint256(price * 10**10);
  }

  function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
    uint256 ethPrice = getPrice();
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
    return ethAmountInUsd;
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