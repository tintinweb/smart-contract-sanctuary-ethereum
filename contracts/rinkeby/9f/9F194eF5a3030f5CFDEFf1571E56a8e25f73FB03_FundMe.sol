/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed){
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable{
        uint256 minimumUSD = 50 * 10**18;
        require(getConversionRate(msg.value) >= minimumUSD,"You need to spend more ETH");
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256){
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        uint8 decimal = priceFeed.decimals();
        (,int256 answer,,,)=priceFeed.latestRoundData();
        uint256 ethPrice = uint256(answer) * ((18-uint256(decimal))**10);
        // uint256 ethPrice = ((18-uint256(decimal))**10);
        return ethPrice;
    }

    function getDecimals() public view returns(uint8){
        return priceFeed.decimals();
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice*ethAmount)/100000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns(uint256){
        uint256 minimumUSD = 50*10**18;
        uint256 price = getPrice();
        uint256 precision = 1*10**18;
        // return (minimumUSD*precision) / price;
        return price;
    }
}