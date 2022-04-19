pragma solidity 0.6.6;

import "AggregatorV3Interface.sol";

contract FundMe {
    uint256 public minValue = 50 * 10**18;
    AggregatorV3Interface public priceFeed;
    mapping(address => uint256) public addyToValue;
    address[] public funders;

    constructor(address _pricefeed) public {
        priceFeed = AggregatorV3Interface(_pricefeed);
    }

    function fund() public payable {
        require(
            getConversionRate(msg.value) >= minValue,
            "You need to spend more eth"
        );
        addyToValue[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getConversionRate(uint256 _value) public view returns (uint256) {
        uint256 price = getLatestPrice();
        return (price * _value) / (10**18);
    }

    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return uint256(price * 10**10);
    }

    function withdraw() public payable {
        msg.sender.transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addyToValue[funders[i]] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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