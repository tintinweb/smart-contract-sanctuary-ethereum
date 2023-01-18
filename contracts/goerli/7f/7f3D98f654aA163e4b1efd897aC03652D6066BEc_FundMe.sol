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
pragma solidity ^0.8.0;

import "./PriceConvertor.sol";

// constant , immutable
error wrongUser();

contract FundMe {
  using utils for uint256;
  uint256 public constant MINIMUMUSD = 1;
  address[] public funders;
  mapping(address => uint256) public addressToAmount;
  address public immutable i_owner;
  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    require(
      msg.value > MINIMUMUSD.getConversionRate(priceFeed),
      "DIDN'T SEND ENOUGH."
    );
    funders.push(msg.sender);
    addressToAmount[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmount[funder] = 0;
    }
    funders = new address[](0);

    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call Failed");
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  modifier onlyOwner() {
    if (msg.sender != i_owner) {
      revert wrongUser();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library utils { 
    function ethToUSD(
        AggregatorV3Interface PriceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = PriceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 dollarAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return ((dollarAmount * 1e36) / ethToUSD(priceFeed));
    }
}