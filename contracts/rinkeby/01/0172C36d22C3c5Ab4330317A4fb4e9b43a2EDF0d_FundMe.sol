//SPDX-License-Identifier: MIT

//pragma solidity >=0.6.6 <0.9.0;
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToValue;
    address[] funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        //uint256 minimumAmount = 50 * 10 ** 18;
        //require(getConversionRate(msg.value) >= minimumAmount,"you need to spend more ETH");
        addressToValue[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //AggregatorV3Interface aggregator = AggregatorV3Interface(
        //   0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //AggregatorV3Interface aggregator = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 100000000); //converting gwei to wei
    }

    function getConversionRate(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 etherPrice = getPrice();
        uint256 etherAmountInUSD = (etherPrice * _ethAmount) /
            1000000000000000000;
        return etherAmountInUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addressToValue[funders[i]] = 0;
        }
        funders = new address[](0);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
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