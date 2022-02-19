/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    mapping(address => uint256) addressToAmountFunded;
    address[] public funders;
    address owner;
    uint256 public funded = 0;
    uint256 minUsdToFund = 5;

    constructor(address _contractOwner) {
        owner = _contractOwner;
    }

    function fund() public payable {
        uint256 minUsd = getMinUsdToFund();
        uint256 fundedInUsd = getConversionRate(msg.value);
        require(fundedInUsd > minUsd, "Min 5 USD!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        funded += msg.value;
    }

    function getEthPrice() private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price * (10**10))); // EHT/USD in 18 digits
    }

    function getMinUsdToFund() private view returns (uint256) {
        return (minUsdToFund * (10**18)); // min USD + 18 decimal places
    }

    function getConversionRate(uint256 ethAmount)
        private
        view
        returns (uint256)
    {
        uint256 ethPrice = getEthPrice();
        uint256 ethInUsd = (ethPrice * ethAmount) / (10**18);
        return ethInUsd;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function updateMinUsdToFund(uint256 _minUsdToFund) public OnlyOwner {
        minUsdToFund = _minUsdToFund;
    }

    function withdraw() public payable OnlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //funders array will be initialized to 0
        funders = new address[](0);
        funded = 0;
    }
}