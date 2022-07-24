// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8 ; 

import "./PrivateContract.sol";



contract FundMe {

    using PrivateContract for uint256;

    uint256 public constant MINIMUM_USD= 10 * 1e18;

    address[] public funders;

    mapping(address => uint256) public fundermap;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAdress){
        i_owner=msg.sender;
        priceFeed=AggregatorV3Interface(priceFeedAdress);
    }

    function fund() public payable {
        //want to sent a certain amount of money in USD
         require(msg.value.getConversionRate(priceFeed) >=MINIMUM_USD, "didn't send enough!!!");
         funders.push(msg.sender);
         fundermap[msg.sender]+=msg.value;
    }

    function withdraw() public onlyOwner {
      
        for (uint256 i=0; i<funders.length; i++){
            address fund=funders[i];
            fundermap[fund]=0;
        }


        funders= new address[](0);
         
        //  //transfer
        //  payable(msg.sender).transfer(address(this).balance);

        //  //send
        //  bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //  require(sendSuccess,"send failed");

         //call
         (bool callSucesss,)=payable(msg.sender).call{ value :address(this).balance }("");
         require(callSucesss,"send failed");





    }

    

    modifier onlyOwner{
            require(msg.sender == i_owner ,"sender is not the owner");
            _;
            }
    
   


 receive() external payable{
     fund();
 }

 fallback() external payable{
     fund();
 }





}

// // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.8 ; 

 import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

 library PrivateContract{
     
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){

         

        (/*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/)=priceFeed.latestRoundData();

            //to get price of eth in usd
       
        return uint256(price * 1e10);

    }

    function getVersion() internal view returns(uint256) {
        AggregatorV3Interface priceFeed=AggregatorV3Interface(	0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethprice=getPrice(priceFeed);
        uint256 ethAmountinUsd=(ethprice * ethAmount)/1e18;
        return ethAmountinUsd;
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