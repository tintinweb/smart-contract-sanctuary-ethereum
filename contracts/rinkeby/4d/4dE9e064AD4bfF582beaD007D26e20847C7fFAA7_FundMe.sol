// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './PriceConverter.sol';

error FundMe__NotOwner();

error FundMe__MinUsd();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MIN_USD = 1;

  struct Person {
    uint amount;
    string message;
    bool exist;
  }

  mapping(address => Person) private s_funders;
  address[] private s_funderAddresses;

  address private immutable i_owner;

  AggregatorV3Interface private s_priceFeed;

  modifier shouldBeMoreThenMinUsd() {
    if (msg.value.getUsdPrice(s_priceFeed) < MIN_USD) {
      revert FundMe__MinUsd();
    }
    _;
  }

  modifier onlyOwner() {
    if (msg.sender != i_owner) {
      revert FundMe__NotOwner();
    }
    _;
  }

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  receive() external payable {
    fund("receive");
  }

  fallback() external payable {
    fund("fallback");
  }

  function withdraw() external onlyOwner {
    address[] memory funderAddresses = s_funderAddresses;

    for(uint i = 0; i < funderAddresses.length; i++) {
      s_funders[funderAddresses[i]].exist = false;
    }

    s_funderAddresses = new address[](0);

    payable(msg.sender).transfer(address(this).balance);    
  }

  function fund(string memory message) shouldBeMoreThenMinUsd public payable {
    Person memory person = Person({ amount: msg.value, message: message, exist: true });

    s_funders[msg.sender] = person;
    s_funderAddresses.push(msg.sender);
  }

  function getOwner() public view returns(address) {
    return i_owner;
  }

  function getPriceFeed() public view returns(AggregatorV3Interface) {
    return s_priceFeed;
  }

  function getFunder(address addr) public view returns(Person memory){
    return s_funders[addr];
  }

  function getFunderAddresses() public view returns(address[] memory) {
    return s_funderAddresses;
  }

  function getMinUsd() public pure returns(uint256) {
    return MIN_USD;
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