// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract FundMe {
  address private immutable i_owner;
  address[] private s_funders;
  mapping(address => uint256) private s_addrToAmtFunded;
  uint256 private constant MINIMUM_USD = 50 * 10**18;
  AggregatorV3Interface private immutable i_priceFeed;
  using PriceConverter for uint256;

  modifier onlyOwner() {
    require(msg.sender == i_owner, "only owner is allowed to withdraw");
    _;
  }

  constructor(address _priceFeed) {
    i_priceFeed = AggregatorV3Interface(_priceFeed);
    i_owner = msg.sender;
  }

  function fund() public payable {
    require(msg.value.getConversionRate(i_priceFeed) >= MINIMUM_USD, "not enough ETH");
    s_addrToAmtFunded[msg.sender] += msg.value;
    s_funders.push(msg.sender);
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = i_owner.call{value: address(this).balance}("");
    require(success, "withdraw failed");

    for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
      address funderAddr = s_funders[funderIndex];
      s_addrToAmtFunded[funderAddr] = 0;
    }
    s_funders = new address[](0);
  }

  function cheaperWithdraw() public payable onlyOwner {
    // payable(msg.sender).transfer(address(this).balance);
    (bool success, ) = i_owner.call{value: address(this).balance}("");
    require(success, "cheaperWithdraw failed");

    address[] memory funders = s_funders; // mapping can't be in memory
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funderAddr = funders[funderIndex];
      s_addrToAmtFunded[funderAddr] = 0;
    }

    s_funders = new address[](0);
  }

  function getOwner() public view returns (address) {
    return i_owner;
  }

  function getFunder(uint256 _index) public view returns (address) {
    return s_funders[_index];
  }

  function getAddrToAmtFunded(address _funderAddress) public view returns (uint256) {
    return s_addrToAmtFunded[_funderAddress];
  }

  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return i_priceFeed;
  }

  function getVersion() public view returns (uint256) {
    return i_priceFeed.version();
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
    (
      ,
      /* uint80 roundID */
      int256 answer, /* uint startedAt */
      ,
      ,
    ) = /* uint timeStamp */
      /* uint80 answeredInRound */
      _priceFeed.latestRoundData();

    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
  // call it get fiatConversionRate, since it assumes something about decimals
  // It wouldn't work for every aggregator
  function getConversionRate(uint256 _ethAmount, AggregatorV3Interface _priceFeed) internal view returns (uint256) {
    uint256 ethPrice = getPrice(_priceFeed);
    uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}