// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./PriceConvert.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
  using PriceConvert for uint256;
  uint256 public constant MINIMUM_USD = 50 * 10**18;

  address public immutable owner_adrs;

  AggregatorV3Interface public immutable priceFeed;

  constructor(address _priceFeed) {
    owner_adrs = msg.sender;
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  address[] public funder;
  mapping(address => uint256) funderMap;

  function fund() public payable {
    require(
      msg.value.getConversion(priceFeed) >= 10**18,
      "Value should be more then 1 Ether"
    );
    funder.push(msg.sender);
    funderMap[msg.sender] += msg.value;
  }

  function withdraw() public onlyOwner {
    for (uint256 i = 0; i < funder.length; i++) {
      funderMap[funder[i]] = 0;
    }
    funder = new address[](0);
    // payable(msg.sender).transfer(address(this).balance);
    bool result = payable(msg.sender).send(address(this).balance);
    require(result, "send fail");
    (bool resultCal, ) = payable(msg.sender).call{value: address(this).balance}(
      ""
    );
    require(resultCal, "send fail");
  }

  modifier onlyOwner() {
    require(owner_adrs == msg.sender, "only owner can withdraw");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvert {
  function getPrice(AggregatorV3Interface priceFeed)
    public
    view
    returns (uint256)
  {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price * 1e10);
  }

  function getVersion(AggregatorV3Interface priceFeed)
    public
    view
    returns (uint256)
  {
    return priceFeed.version();
  }

  function getConversion(uint256 ethAmout, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    return (ethAmout * getPrice(priceFeed)) / 1e18;
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