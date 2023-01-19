//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    address[] public fundersArray;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 5 * 10**18;
        require(
            getConversion(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        fundersArray.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10**10); //$1,545.610000000000000000
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getConversion(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountToUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountToUSD; //$1,545.610000000000000000
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price) + 1;
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