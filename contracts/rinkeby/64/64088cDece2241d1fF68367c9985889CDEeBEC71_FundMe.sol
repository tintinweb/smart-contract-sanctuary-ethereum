// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  address public immutable i_owner;
  uint256 public constant MINIMUM_PRICE_USD = 50 * 1e18;
  address[] public funders;
  mapping(address => uint256) fundersToAmount;
  AggregatorV3Interface public immutable i_priceEth;

  modifier OnlyOwner() {
    if (msg.sender != i_owner) {
      revert NotOwner();
    }
    _;
  }

  constructor(address _priceFeeAddress) {
    i_owner = msg.sender;
    i_priceEth = AggregatorV3Interface(_priceFeeAddress);
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  function fund() public payable {
    require(
      msg.value.getConversionRate(i_priceEth) >= MINIMUM_PRICE_USD,
      "Amount not enough"
    );

    funders.push(msg.sender);
    fundersToAmount[msg.sender] = msg.value;
  }

  function withdraw() public OnlyOwner {
    for (uint256 i = 0; i < funders.length; i++) {
      address funderAddress = funders[i];
      fundersToAmount[funderAddress] = 0;
    }

    funders = new address[](0);

    bool sendSuccess = payable(msg.sender).send(address(this).balance);
    require(sendSuccess, "Error sending the funds");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPriceEthInUsd(AggregatorV3Interface priceEth)
    internal
    view
    returns (uint256)
  {
    (, int256 price, , , ) = priceEth.latestRoundData();
    return uint256(price * 1e10);
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceEth)
    internal
    view
    returns (uint256)
  {
    uint256 ethPriceInUsd = getPriceEthInUsd(priceEth);
    uint256 ethAmountInUsd = (ethPriceInUsd * ethAmount) / 1e18;

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