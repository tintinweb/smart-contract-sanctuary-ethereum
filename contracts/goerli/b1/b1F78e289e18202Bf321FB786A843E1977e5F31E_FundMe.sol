//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    address[] public fundersArray;
    mapping(address => uint256) public addressToAmountFunded;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;
        require(getConversion(msg.value) >= minimumUSD);
        addressToAmountFunded[msg.sender] += msg.value;
        fundersArray.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getConversion(uint256 ethAmount) public view returns (uint256) {
        uint256 price = getPrice();
        uint256 ethUSDPrice = (price * ethAmount) / 1000000000000000000;
        return ethUSDPrice;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 price = getPrice();
        uint256 minimumUSD = 50 * 10**18;
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 fundersIndex = 0;
            fundersIndex < fundersArray.length;
            fundersIndex++
        ) {
            address Funder = fundersArray[fundersIndex];
            addressToAmountFunded[Funder] = 0;
        }
        fundersArray = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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