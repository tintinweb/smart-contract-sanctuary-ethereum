// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './PriceConverter.sol';

contract FundMe {
  uint256 private constant MIN_USD = 1;

  using PriceConverter for uint256;

  struct Person {
    uint amount;
    string message;
  }

  address[] public addrs;

  mapping(address => Person) private funders;

  address public immutable owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  receive() external payable {
    fund("receive");
  }

  fallback() external payable {
    fund("fallback");
  }

  function getFunder(address addr) external view returns(Person memory){
    return funders[addr];
  }

  modifier shouldBeMoreThenMinUsd() {
    require(msg.value.getUsdPrice(priceFeed) >= MIN_USD, "Should be more then min usd amount");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner required");
    _;
  }

  function fund(string memory message) shouldBeMoreThenMinUsd public payable {
    Person memory person = Person({ amount: msg.value, message: message });

    funders[msg.sender] = person;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
    // need to clean funders here
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
    (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();

    return uint256(price * 1e10);
  }

  function getUsdPrice(uint256 weiAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
    uint256 ethPriceInWei = getLatestPrice(priceFeed);

    return (ethPriceInWei * weiAmount) / 1e36;
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