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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error Unauthorized();
error CallFailed();

contract FundMe {
    using PriceConverter for uint256;

    address public immutable i_owner;
    uint256 public constant MIN_USD = 5 * 1e18; // $5.00
    address[] public funders;
    mapping(address => uint256) public funderToAmountFunded;

    modifier onlyOwner {
        if (msg.sender != i_owner) revert Unauthorized();
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MIN_USD, "Minimum amount not reached: Less than $5.00");
        if (funderToAmountFunded[msg.sender] == 0) {
            funders.push(msg.sender);
        }
        funderToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        uint256 l = funders.length;

        for (uint256 i = 0; i < l; i++) {
            address funder = funders[i];
            funderToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool success,) = payable(i_owner).call{value: address(this).balance}("");
        if (!success) revert CallFailed();
    }

    function getConversionRate() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getFundersLength() public view returns (uint256) {
        return funders.length;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    /**
     * Returns the latest price
     */
    function getPrice() internal view returns (uint256) {
        /**
         * Network: Goerli
         * Aggregator: ETH/USD
         * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
         */
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    /**
     * Returns equivalent USD from ETH value
     */
    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}