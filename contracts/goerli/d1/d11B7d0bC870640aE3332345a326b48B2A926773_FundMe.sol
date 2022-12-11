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

// people can send money to contract
// contract owner can withdraw money
// set minimum funding amount
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 837309 - without constant & immutable
// 817767 - with constant
// 794272 - with constant & immutable
// 769185 - with custom error
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 50 * 1e18;

  AggregatorV3Interface public priceFeed;

  // store list of funders
  address[] public funders;
  // map funders address to the amount funded
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable i_owner;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    // want to be able to set minimum fund amt in usd
    // how to send eth to contract?
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Didn't send enough!"
    );
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    // clear addressToMountFunded mapping
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    // clear funders array
    funders = new address[](0);
    // withdraw all contract balance
    (bool callSucces, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSucces, "Call failed");
  }

  modifier onlyOwner() {
    if (msg.sender != i_owner) {
      revert NotOwner();
    }
    _;
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    // ETH in term of USD. eg: 150000000000
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price * 1e10);
  }

  function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    // get eth price
    uint256 ethPrice = getPrice(priceFeed);
    // calculate eth amount to usd
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
    return ethAmountInUsd;
  }
}