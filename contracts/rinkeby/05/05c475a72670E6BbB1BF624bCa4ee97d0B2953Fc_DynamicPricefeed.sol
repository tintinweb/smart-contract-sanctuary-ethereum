// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;
 import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
 

 contract DynamicPricefeed{
     constructor(){
         priceFeeds["ATOM / ETH"]=0xc751E86208F0F8aF2d5CD0e29716cA7AD98B5eF5;
         priceFeeds["ATOM / USD"]=0x3539F2E214d8BC7E611056383323aC6D1b01943c;
         priceFeeds["AUD / USD"]=0x21c095d2aDa464A294956eA058077F14F66535af;
     }

     mapping(string=>address) priceFeeds;
     /**
     * @dev This function is get symboPare and return the price feed of that pare
     * @param _symbolPare is a string value of symbols who the price feed ratio will be return.e.g ATOM / ETH ,  AUD / USD
     *
     */

     function getPrice(string memory _symbolPare) external view returns(int){
          require(priceFeeds[_symbolPare]!=address(0),"This symbol price has not been added. First add price feed with the help of setPriceFeedA");
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeeds[_symbolPare]).latestRoundData();

       return price;
     }

     

     function setPriceFeedAddress(string memory _symbolPare, address _priceFeedAddress) external{
         priceFeeds[_symbolPare]=_priceFeedAddress;
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