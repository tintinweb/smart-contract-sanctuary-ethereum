// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__onlyOwner();
error FundMe__notEnoughFunds();

contract FundMe {
  using PriceConverter for uint256;

  uint256 private constant MINIMUM_USD = 50 * 10**18;
  address private immutable i_owner;

  AggregatorV3Interface private s_priceFeed;
  address[] private s_funders;
  mapping(address => uint256) private s_addressToAmountFunded;

  constructor(address priceFeed) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeed);
  }

  modifier onlyOwner() {
    if (msg.sender != i_owner) {
      revert FundMe__onlyOwner();
    }
    _;
  }

  function fund() public payable {
    if (!(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD)) {
      revert FundMe__notEnoughFunds();
    }
    s_funders.push(msg.sender);
    s_addressToAmountFunded[msg.sender] += msg.value;
  }

  function withdraw() public onlyOwner {
    address[] memory tempFunders = s_funders;
    for (uint256 i = 0; i < tempFunders.length; i++) {
      address funder = tempFunders[i];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
    (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
    if (!callSuccess) {
      revert FundMe__onlyOwner();
    }
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface _priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 price, , , ) = _priceFeed.latestRoundData();
    return uint256(price * 10000000000); // 8 dec + 10 = 18
  }

  function getConversionRate(uint256 _value, AggregatorV3Interface _priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 price = getPrice(_priceFeed);
    uint256 ethAmountInUsd = (_value * price) / 1000000000000000000;
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