//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PriceConverter.sol";

contract FundMe {
  using PriceConverter for uint256;

  uint256 minUsd = 50 * 1e18;

  address[] public funders;
  mapping(address => uint256) address2Amt;

  address public owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    require(msg.value.converter(priceFeed) >= minUsd, "Not enough");
    funders.push(msg.sender);
    address2Amt[msg.sender] = msg.value;
  }

  function retrieve() public isOwner {
    for (uint256 i = 0; i < funders.length; i++) {
      address funder = funders[i];
      address2Amt[funder] = 0;
    }

    funders = new address[](0);
    (bool isSuccess, ) = payable(msg.sender).call{value: address(this).balance}(
      ""
    );
    require(isSuccess, "Call failed");
  }

  modifier isOwner() {
    require(msg.sender == owner, "Only owner can withdraw");
    _;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // AggregatorV3Interface pricefeed = AggregatorV3Interface(
    //   0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    // );
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price * 1e18);
  }

  function converter(uint256 eth, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 price = getPrice(priceFeed);
    uint256 ethInUsd = (price * eth) / 1e18;
    return ethInUsd;
  }
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