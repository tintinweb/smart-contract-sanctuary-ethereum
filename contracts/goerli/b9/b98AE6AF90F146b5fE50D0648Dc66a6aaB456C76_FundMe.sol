// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getLatestPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    mapping(address => uint256) public totalFunded;
    mapping(address => uint256) public ammountinPot;
    address[] public funders;
    address[] public currentFunders;

    function fundersLength() public view returns (uint256) {
        return funders.length;
    }

    function currentFundersLength() public view returns (uint256) {
        return currentFunders.length;
    }

    AggregatorV3Interface public priceFeed;

    function fund() public payable {
        require(
            (msg.value) * (getLatestPrice()) >= getEntranceFee(),
            "Need more eth"
        );

        if (totalFunded[msg.sender] <= 0) {
            funders.push(msg.sender);
        }

        if (ammountinPot[msg.sender] <= 0) {
            currentFunders.push(msg.sender);
        }

        totalFunded[msg.sender] += msg.value;
        ammountinPot[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        //Aggregator version
        return priceFeed.version();
    }

    function getLatestPrice() public view returns (uint256) {
        //USD price
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10**10);
    }

    function withdraw() public payable onlyOwner {
        //withdraw funds
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 x = 0; x < currentFunders.length; x++) {
            ammountinPot[currentFunders[x]] = 0;
        }
        currentFunders = new address[](0);
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