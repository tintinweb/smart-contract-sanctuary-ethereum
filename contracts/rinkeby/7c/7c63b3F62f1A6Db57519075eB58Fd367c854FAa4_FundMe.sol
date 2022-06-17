// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 50 * 1e18;
  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;
  address public immutable i_owner;
  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  modifier onlyOwner{
    require(msg.sender == i_owner);
    _;
  }

  function fund() public payable {
    require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "The minimum fund value is 50 USD");

    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] += msg.value;
  }

  function withdraw() public onlyOwner payable {
    for (uint256 i = 0; i < funders.length; i++) {
        addressToAmountFunded[funders[i]] = 0;
    }

    funders = new address[](0);

    (bool callSuccess,) = payable(msg.sender).call{ value: address(this).balance }("");

    require(callSuccess, "Call has failed");
  }

  // Prevent wrong fund calls
  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getLatestETHPrice(
    AggregatorV3Interface priceFeed
  )
    internal
    view
    returns (uint256)
  {
    (
      /*uint80 roundID*/,
      int price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();

    return uint256(price * 1e10);
  }

  function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
  )
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getLatestETHPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
    // the actual ETH/USD conversion rate, after adjusting the extra 0s.
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