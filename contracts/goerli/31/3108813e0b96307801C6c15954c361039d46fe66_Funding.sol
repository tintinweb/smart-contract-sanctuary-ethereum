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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./PriceConverter.sol";

error NotOwner();

contract Funding {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 0.02 * 1e18; // 1 * 10 ** 18
  // 0.02 / 1625 = 0.000012484592145 (12400000000000 Wei)

  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable i_owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Didn't sent enough!"
    );

    // 1e18 == 1 * 10 ** 18 == 1000000000000000000
    // 18 decimals

    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] += msg.value;
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
      address funder = funders[funderIdx];
      addressToAmountFunded[funder] = 0;
    }

    funders = new address[](0);

    // Call
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");

    // Transfer (to each other)
    // payable(msg.sender).transfer(address(this).balance);

    // Send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed");
  }

  modifier onlyOwner() {
    // require(msg.sender == i_owner, "Sender in not owner!"); // not optimized
    if (msg.sender != i_owner) {
      revert NotOwner();
    } // optimized
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

pragma solidity ^0.8.17;

// import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    // ABI
    // address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

    // AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //   0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    // );

    (, int price, , , ) = priceFeed.latestRoundData();

    // ETH in terms of USD
    // 1655.00000000

    return uint256(price * 1e10); // 1**10 == 10000000000
  }

  /*
  function getVersion() internal view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(
      0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    );
    return priceFeed.version();
  }
  */

  function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);

    // 1655_000000000000000000 = ETH / USD price
    // 1_000000000000000000 ETH

    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
    return ethAmountInUsd;
  }
}