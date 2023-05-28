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

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

//818210 gas
//constant
//immutable
error NotOwner();

contract FundMe{
    using PriceConverter for uint256;

    uint256 public  constant MINIMUM_USD=50*1e18;//351-constant 2451 without constant
    address[] public funders;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner=msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    mapping(address=>uint256)public addressToAmountFunded;

    //AggregatorV3Interface internal priceEth; //AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

   

    function fundMe()public payable{
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,"Funds below required limit!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]+=msg.value;

    }

    function withdraw()public onlyOwner{
        
        /*starting index,ending index,step amount*/
        for(uint256 funderIndex=0;funderIndex<funders.length;funderIndex++){
            address funder=funders[funderIndex];
            addressToAmountFunded[funder]=0;

        }
        //reset the array
        funders=new address[](0);
        //actually withdraw the funds

        //transfer
        
       // payable(msg.sender).transfer(address(this).balance);// automatically reverts if transaction failed
        
        //send 
      // bool sendSuccess = payable(msg.sender).send(address(this).balance);// only reverts if require is added 
       //require( sendSuccess , "send Failure!");

       //call
       (bool callSuccess,)=payable(msg.sender).call{value:address(this).balance}("");
       require(callSuccess , "call failed");


    }
    modifier onlyOwner{
       // require(msg.sender==i_owner,"sender's address is not bearer of the wallet(contract)!");
       // _;
       if(msg.sender!=i_owner){revert NotOwner();}
       _;
    }
    //what happens when sb sends this contract ETH without hitting the fund()
    receive()external payable{
        fundMe();
    }
    fallback()external payable{
        fundMe();
    }

    
}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{

    function getPrice(AggregatorV3Interface priceFeed)internal view returns(uint256){
    /*AggregatorV3Interface priceEth = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);*//*Removes need 
    for hardcoding this bit of code here*/    
    (,int price,,,)=priceFeed.latestRoundData();
    return uint256(price*1e10);

    }

    function getConversionRate(uint256 etherValue,AggregatorV3Interface priceFeed)internal view returns(uint256){
        //converts msg.value from eth to in terms of dollars 
        uint256 etherPrice = getPrice(priceFeed);
        uint256 priceEthinUsd = (etherPrice*etherValue)/1e18;
        return priceEthinUsd;

    }

}