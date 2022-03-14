/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// Part: AggregatorV3Interface

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

// getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  
contract FundMe {
    //using SafeMathChainLink for uint256;
    //can be used to attah lib functions(from A) to any type(B).

    mapping (address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    //owner is set as us who deployed it
    constructor() public{
        owner = msg.sender;
    }

    //we can let anyone fund this.
    function fund() public payable{

        uint256 minimumUSD = 50 * 10 ** 18; //50USD$;
        //require (getConversionRate(msg.value) >= minimumUSD, "Need to spend more than 50USD");
        addressToAmountFunded[msg.sender] += msg.value;
        //what the ETH -> USD Converstion rate.
        funders.push(msg.sender);
    }


    function getVersion() public view returns (uint256){
        //codebelow: we have a contract type AggregatorV3Interface
        // with the functions located in address given
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); 
        return priceFeed.version();

        //AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e).version();
    }

//  we get price of ethereum in usdt
    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); 
    ( ,int256 answer,,,)= priceFeed.latestRoundData();
    //to convert types we be using typecasting
    return uint256(answer * 1000000000000000000);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
       // uint256 ethPrice = getPrice();
        //uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return (getPrice() * ethAmount) / 1000000000000000000;
    }

//we are using modifiers as a way of running require statement better
    modifier onlyOwner {
        require (msg.sender ==owner);
        _;
    }
    function withdraw(uint256 amountWithdraw) payable  public{
        payable(owner).transfer(amountWithdraw);
        //once funds are withdrawn, the people who funded their 
        for (uint256 funderIndex=0;funderIndex <funders.length;funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] =0;
        } 
        funders = new address[](0);
    }
    
}