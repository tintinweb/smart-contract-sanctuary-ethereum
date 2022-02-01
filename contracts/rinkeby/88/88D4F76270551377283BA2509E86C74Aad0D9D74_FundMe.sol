/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



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

// remember API links to interface while library links to code 

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() { // constructor : immediately executed when contract is deployed
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minUSD = 5*10**18;
        require (getConversionR8(msg.value) >= minUSD, "we need more gold");
        addressToAmountFunded[msg.sender] += msg.value; //msg.sender = sender, msg.value = how much sent (the value under "value" in deploy tab)
        //but what is ETH => USD conversion rate? oracle.
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); //why the fuck not enough funds
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
            // (uint80 roundId,
        (,int256 answer,,,) //commas indicate presence of unused variables roundID, startedAt, updatedAt, answeredInRound
            // uint256 startedAt,
            // uint256 updatedAt,
            // uint80 answeredInRound)
        = priceFeed.latestRoundData();

            // return answer; //int256 so wrong type
        return uint256(answer)*10_000_000_000; //=>testing stuff
            
            // return uint256(answer);
            //above will have 8 decimals (see decimals function in AggregatorV3Interface code)
    }

    function getConversionR8(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/1_000_000_000_000_000_000;
        return ethAmountInUsd;
    }

    modifier onlyOwner { //modifier used to change some function in some declarative way
        require(msg.sender==owner, "pls");
        _; //execute rest of code in function
    }

    function withdraw() payable onlyOwner public {
        // require (msg.sender == owner); replace this with modifier
        payable(msg.sender).transfer(address(this).balance); //this refers to contract u are currently in. address of this is the address of the contract u are in.        //whoever calls this function (msg.sender) transfer all money
        for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++) {// this means we have index variable funderIndex starting from 0, loop will finish when index is greater than length of funders. every finish of loop ++ to funderIndex
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);





    }

}