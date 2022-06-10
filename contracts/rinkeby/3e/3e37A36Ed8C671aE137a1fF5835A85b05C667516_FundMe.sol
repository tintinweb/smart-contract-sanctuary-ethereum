//SPDX-License-Identifer: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error notOwner();

contract FundMe {

using priceConverter for uint256;

    uint256 public constant minAmt=50*1e18;
    address[] funders;
    mapping(address=>uint256) public adsToFund;
    address public immutable owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAdress){
        owner= msg.sender;
        priceFeed= AggregatorV3Interface(priceFeedAdress);
    }

    function fund() public payable{
        require(msg.value.getConversionRate(priceFeed) >= minAmt,"Didn't send enough");
        funders.push(msg.sender);
        adsToFund[msg.sender]=msg.value;
    }

    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }

    function withdraw() public onlyOwner{
        for(uint256 funderIndex=0; funderIndex< funders.length; funderIndex++){
            address funder= funders[funderIndex];
            adsToFund[funder]=0;
        }
        funders= new address[](0);
        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"Call failed");
    }

    modifier onlyOwner(){
        // require(msg.sender== owner,"Sender is not owner");
        if (msg.sender != owner) { revert notOwner(); }
        _;
    }

}

//SPDX-License-Identifer: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceConverter{

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        (,int256 price,,,)= priceFeed.latestRoundData();
        return uint256(price*1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice= getPrice(priceFeed);
        uint256 ethinUSD= (ethPrice*ethAmount) / 1e18;
        return ethinUSD;
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