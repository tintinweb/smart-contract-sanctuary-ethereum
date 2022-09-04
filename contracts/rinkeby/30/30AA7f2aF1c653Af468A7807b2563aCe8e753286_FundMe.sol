// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

contract FundMe {
  using PriceConverter for uint256;
  uint256 public minFundUSD = 10;
  address public owner;
  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function checkBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function withdraw() external onlyOwner {
    (bool sent, ) = owner.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function fund() external payable {
    require(msg.value.weiToUSD(priceFeed) >= minFundUSD, "more money plz");
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function weiToUSD(uint256 gweiAmt, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 ETHpriceRaw, , , ) = priceFeed.latestRoundData();
    uint256 ETHprice = uint256(ETHpriceRaw / 100000000);
    // return ETHprice;
    return (gweiAmt * ETHprice) / 1000000000000000000;
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