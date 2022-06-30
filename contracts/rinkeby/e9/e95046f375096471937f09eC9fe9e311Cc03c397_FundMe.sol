// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol" ;

contract FundMe {

    address public owner ; 

    mapping(address => uint256) public addressToAmountFunded ; 
    address[] public funders ;
    AggregatorV3Interface public priceFeed ;

    constructor(address _priceFeed) public{
        priceFeed = AggregatorV3Interface(_priceFeed) ; //Rinkeby USD/ETH oracle address : 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        owner = msg.sender ; 
    }

    function fund() public payable{
        // 50$
        uint256 minUSD = 50 * 10**18; 
        require(getConversionRate(msg.value) >= minUSD, "Floor price is 50$") ;
        addressToAmountFunded[msg.sender] += msg.value ;
        funders.push(msg.sender) ;  
    }

    function getVersion() public view returns(uint256){
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        (,int256 answer,,,) = priceFeed.latestRoundData() ; 
        return uint256(answer * 10000000000) ; // returns the value of 1ETH in USD
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){ // ethAmount is in wei
        uint256 ethPrice = getPrice(); 
        uint256 ethAmountInUsd = ( (ethAmount / 1000000000000000000) * (ethPrice / 10000000000) ) * 10**18;
        return ethAmountInUsd ; 
    }

    function getEntranceFee() public view returns(uint256){
        uint256 minimumUSD = 50 * 10**18 ;
        uint256 priceETH = getPrice() ;
        return minimumUSD / (priceETH / 10000000000) ; 
    }

    modifier onlyOwner(){
        require(msg.sender == owner) ; 
        _;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance ; // balance returns a result in wei
    }

    function withdraw() payable onlyOwner public { 
        payable(msg.sender).transfer(address(this).balance) ; 
        for (uint256 funderIndex=0; funderIndex < funders.length ; funderIndex++){
            address funder = funders[funderIndex] ; 
            addressToAmountFunded[funder] = 0 ; 
        }
        funders = new address[](0);
    }
}

//111,381443980

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