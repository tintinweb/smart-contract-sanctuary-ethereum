// get funds from users 
// withdraw fund(only owner )
// set minimum funding value in usd

// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.11;
import "./PriceConverter.sol";

error NotOwner();
contract FundMe{
    // contract deployement cost
    // gas cost with contant and immutable = 751682
    // gas cost without = 793959
   address public immutable i_owner;

    using PriceConverter for uint256;
    // we are using uint256 as first parameter
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // gas with constant = 21415(cheaper)
    // without constan=  23515
    address[] public funders;
    mapping(address => uint256)  public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;
   constructor(address priceFeedAddress){
       i_owner = msg.sender;
       priceFeed = AggregatorV3Interface(priceFeedAddress);
    }



    function fund() public payable {
        // want to able to set minimum fund amount in usd
        // 1. how to send eth to this contract
        require(msg.value.getConversionRate(priceFeed)>= MINIMUM_USD,"Didn't send enough" ); //1e18 == 1 * 10 ** 18 == 100000000000000000 wei == 1 eth
        // msg.value will be the first parameter of getConversionRate.
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
        // what is revert?
        // undo any action before and send remaining gas back
    }

  
   
 function withdraw() public onlyOwner{
        // reset the value
        for(uint256 funderIndex = 0;funderIndex<funders.length;funderIndex++){
         address funder = funders[funderIndex];
         addressToAmountFunded[funder] = 0;
 }
//  reset array 
 funders = new address[](0);

//  withdraw fund

// second return type of call is bytes data we dont need it here so ignoring
 (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
  require(success,"eth trasfer failed");
}

     modifier onlyOwner{
        //  
        if(msg.sender != i_owner){
            revert NotOwner();
        }
         _;
        //  underscore below the require runs the require statement first and then code
        //  underscore above will do vise-versa
         }

        //  what happens of someone send eth to this contract without calling fund function?
        
        receive() external payable{fund();}
        fallback() external payable{fund();}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter {

      function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        // ABI
        // address =>   0x8A753747A1Fa494EC906cE90E9f37563A8AF630e (rinkeby)


    (,int256 answer,,,
      // latestRounddata() returns many thing but we only need answer/price so we are deleting those value and leaving commas instead
      )=priceFeed.latestRoundData();

    //   answer is price of eth interms of USD
    // 3000.00000000

    // below code matches the decimal points and type cast int256 to uint256
    // because we are getting msg.value as uint256 and answer as int256

    
    return uint256(answer * 1e10); // 1**10 = 10000000000 
    // lets solve the maths 
    // suppose 1 eth == 3000 usd 
    // we will get 300000000000 as answer
    // the to match the decimal point with eth we do answer * 1e10 i.e 10000000000 
    // final return value will be 3000000000000000000000
    }


    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
     
     uint256 ethPrice = getPrice(priceFeed);
    // lets solve the maths
    //  ethPrice = 3000_000000000000000000
    // 1 eth is send so ethAmount = 1_000000000000000000 wei
     uint256 ethAmountInUsd = (ethPrice * ethAmount)/1e18;
     return ethAmountInUsd;
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