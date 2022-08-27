// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address[] public funders;
    address public owner;
    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface priceFeed =
        AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        uint256 minimumUSD = 20 * 10**18;
        require(getConversion(msg.value) >= minimumUSD, "Not enough ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        int256 answer;
        (, answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1000000000);
    }

    function getConversion(uint256 _ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 10**18;
        return ethAmountInUsd;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
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