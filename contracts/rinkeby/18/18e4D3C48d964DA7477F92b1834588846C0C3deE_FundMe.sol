// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable iOwner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    iOwner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    require(
      msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
      "Didn`t send enough!"
    ); // 1e18 ==  * 10 ** 18
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    funders = new address[](0);

    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }

  modifier onlyOwner() {
    // require(msg.sender == iOwner, "Sender is not owner!");
    if (msg.sender != iOwner) {
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

pragma solidity 0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    // ETH in terms of USD
    // 3000.00000000
    return uint256(price * 1e10); // 1 ** 10 == 10000000000
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
    return ethAmountInUsd;
  }
}

// function getVersion(AggregatorV3Interface priceFeed)
//   internal
//   view
//   returns (uint256)
// {
//   return priceFeed.version();
// }

// Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
// ABI
// AggregatorV3Interface priceFeed = AggregatorV3Interface(
//   0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
// );

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