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

// constant, immutable

// 900235 gas

// 880700 gas with constant minimumUsd

// 832279 gas with error notOwner, and with constant and immutable vars

error notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // 21415 gas constant
    // 23515 gas mutable
    // 23515 * current gas price in wei = actual cost of tx
    // ex. 23515 * 12 gwei (12000000000 wei) = 282180000000000 wei (0.00028218 ETH)

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    // 21508 gas immutable
    // 23622 gas mutable

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        _;
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?

        // when using a library for a data type,
        // the variable invoking the library is considered the first parameter
        // ex. getConversionRate(uint256) === uint256.getConversionRate()

        // all subsequent arguments expected of a function are passed in the parentheses
        // ex. getConversionRate uint256 a, string b) === uint256.getConversionRate(string);

        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); // 1e18 == 1 * 10 ** 18
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 x; x < funders.length; x++) {
            addressToAmountFunded[funders[x]] = 0;
            // less efficient to update all funders[] addresses one at a time...
            // funders[x] = address(0);
        }
        // than it is to just reset the whole array at once
        funders = new address[](0);

        // payable
        payable(msg.sender).transfer(address(this).balance);

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    // fallback for direct transactions without call data
    receive() external payable {
        fund();
    }

    // fallback for direct transactions with call data
    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// libraries:
// - cant have state variables
// - cant send ether
// - all functions are internal

library PriceConverter {
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        (, int256 price, , , ) = _priceFeed.latestRoundData();
        // ETH in terms of USD
        return uint256(price * 1e10); // price has 8 decimals, this adds 10 more decimal points to match ETH
    }

    function getVersion(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        return _priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}