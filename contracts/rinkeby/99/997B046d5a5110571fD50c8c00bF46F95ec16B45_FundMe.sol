//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

import "AggregatorV3Interface.sol";

// interface AggregatorV3Interface {
//   function decimals() external view returns (uint8);

//   function description() external view returns (string memory);

//   function version() external view returns (uint256);

//   // getRoundData and latestRoundData should both raise "No data present"
//   // if they do not have data to report, instead of returning unset values
//   // which could be misinterpreted as actual reported values.
//   function getRoundData(uint80 _roundId)
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

//   function latestRoundData()
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );
// };

contract FundMe{
    address [] public funders;
    mapping(address=>uint) public addressToAmountFunded;
    address public owner;
    AggregatorV3Interface public priceFeed;
    
    constructor (address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner=msg.sender;
    }
    
    function fund() public payable {
        uint minimumUsd=50;
        require (getConversationRate(msg.value)>minimumUsd,"Not enough ehter");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]+=msg.value;

    }
    function getVersion() public view returns(uint){
        // AggregatorV3Interface priceFeed=AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    function getPrice() public view returns (uint){
        // AggregatorV3Interface priceFeed=AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,)=priceFeed.latestRoundData();
        return uint(answer);
    }
    function getEntranceFee() public view returns (uint){
        uint minimumUsd=50;
        uint price=getPrice();
        uint precision=(1*10**18);
        return (minimumUsd*precision)/price;

    }
    function getConversationRate(uint ethAmount) public view returns (uint){
        uint ethPrice=getPrice();
        uint ethAmountInUsd=(ethPrice * ethAmount);
        return ethAmountInUsd;
    }
    modifier onlyOwner{
        require (msg.sender == owner);
        _;
    }
    function withdraw() onlyOwner public payable {
        payable(msg.sender).transfer(address(this).balance);
        for(uint funderIndex=0;funderIndex<funders.length;funderIndex++){
            address funder=funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }
        funders=new address[](0);
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