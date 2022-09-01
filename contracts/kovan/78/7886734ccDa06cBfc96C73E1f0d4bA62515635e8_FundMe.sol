// SPDX-License-Identifier: GPL-3.0
// Goal
// 1.deposit the toen into the contract
// 1.1 ge the conversation rate from the chain link feeds
// 1.2 by using this function get the token back
// 2.withdraw the token from the contract
pragma solidity >=0.7.0 <0.9.0;
import "./PriceConverter.sol";

  /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */

     error NotOwner();
contract FundMe {
    using PriceConverter for uint256;
    uint256  constant MINIMUM_USD = 50*1e18;
    address[] public funders;
    mapping(address=>uint256) public addressToAmountFunded;
    address public  immutable i_onlyOwner;
    AggregatorV3Interface public priceFeed;
// beofre immutable 23600
// immutable 	21464 gas 
    constructor(address priceFeedAddress){   
        i_onlyOwner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
        
    

    function fund() public payable{
    // no constant 674892
    // constant 653869
        require(msg.value.getConversationRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]=msg.value;

    }

// reset the fund amount to 0
  function withdraw() public  i_Owner{
     
//  no immutable 653869
// 
      for(uint256 funderIndex=0; funderIndex < funders.length;funderIndex++){
         address funder = funders[funderIndex];
          addressToAmountFunded[funder]=  0;
      }
// reset the address array to empty element array
      funders = new address[](0);

    //   send the ethrenum
    (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}("");
    require(callSuccess,"call Failed");
  }

modifier  i_Owner(){
// require(msg.sender == i_onlyOwner,"you need to be the project owner!");
if(msg.sender!=i_onlyOwner) revert NotOwner();
_;
}

// receive

receive() external payable{
fund();
}
  
// fallback
fallback() external payable{
  fund();
}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    // latest price is the rate with init
   function getLatestPrice(AggregatorV3Interface priceFeed) public view returns(uint256) {
    //   AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
         ( ,int256 price,,,) = priceFeed.latestRoundData();
         return uint256(price * 1e10);
   }

//    rate with decimal 
// price of the final function
// library should be the internal, set the public will cause Error
// FundMe hardhat deploy -> Error: invalid bytecode (argument="bytecode", value="0
// https://github.com/smartcontractkit/full-blockchain-solidity-course-js/discussions/201
function getConversationRate(uint256 ethamount,AggregatorV3Interface priceFeed)  internal view returns(uint256){
    uint256 ethPrice = getLatestPrice(priceFeed);
    //  rate with decimal 
    uint256 ethamountInUsd = (ethamount * ethPrice) / 1e18;

    return  ethamountInUsd;
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