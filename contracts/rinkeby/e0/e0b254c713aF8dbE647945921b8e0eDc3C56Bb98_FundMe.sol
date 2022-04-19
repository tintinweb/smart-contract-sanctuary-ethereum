/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/cha[email protected]/AggregatorV3Interface

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

// File: fundMe.sol

contract FundMe {
    address[] public funders;
    uint256 amountFunded;
    address public owner;
    AggregatorV3Interface public priceFeed;
    uint256 minimumAmount = 50 * 10**18;
    mapping(address => uint256) public addressToAmountFunded;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        require(
            getConversionRate(msg.value) >= minimumAmount,
            "not enough eth"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 currentEthprice = getPrice();
        uint256 priceInETh = (currentEthprice * ethAmount) /
            1000000000000000000;
        return priceInETh;
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumAmount * precision) / price) + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}