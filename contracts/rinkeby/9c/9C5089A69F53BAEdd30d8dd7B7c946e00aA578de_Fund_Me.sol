/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;



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

// File: Fund_Me.sol

contract Fund_Me
{
    
    mapping(address=>uint256) public addressToAmountFunded;

    address public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;
    constructor(address _priceFeed)
    {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable 
    {
        
        uint256 minimumUsd = 50 * 10 ** 18 ;
        require(getConversion(msg.value) >= minimumUsd,"Enter usd greater the 50 Usd");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function get_version() public  view returns(uint256)
    {
       //AggregatorV3Interface feed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
       
       (,int256 price,,,) = priceFeed.latestRoundData();
       return  uint256(price * 10000000000);
    }

    function getConversion(uint256 ethprice) public view returns(uint256)
    {
         uint256 Currentethprice = get_version();
         uint256 priceinUsd =  ( Currentethprice * ethprice) / 1000000000000000000 ;
         return priceinUsd; 
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    function withdraw()  payable onlyOwner public   
    {
        payable(msg.sender).transfer(address(this).balance);

        for(uint funderInd = 0;funderInd < funders.length;funderInd++)
        {
                address funder = funders[funderInd];
                addressToAmountFunded[funder]=0;
        }
        funders = new address[](0);
    }
}