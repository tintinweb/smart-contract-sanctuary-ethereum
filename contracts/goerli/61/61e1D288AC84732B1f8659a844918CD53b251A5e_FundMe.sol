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
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConvertor.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract FundMe {

    using PriceConvertor for uint256;
    AggregatorV3Interface internal priceFeed;

    uint256 public constant MIN_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) > MIN_USD, 'Send More');
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library  PriceConvertor {

    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }


    function getConversionRate(uint256 ethPrice, AggregatorV3Interface priceFeed) internal view returns (uint256){
        uint256 ethUsd = getLatestPrice(priceFeed);
        uint256 usdAmount = (ethPrice * ethUsd) / 1e18;
        return usdAmount;
    }

}