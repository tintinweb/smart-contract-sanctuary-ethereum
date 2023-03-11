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

//SPDX-License-Identifier: MIT
//pragma
 pragma solidity ^0.8.8;
 //import
import "./priceconvertor.sol";
//error codes
 error Fundme_notowner();
 //interfaces,library,contract

/**
 @title a contract for crowd funding 
 @author tiwariji 
 @notice this contract is to demo a sample funding contract
 @dev this implements price feeds as our library 
 */

contract Fundme{
    //type declarations
    using priceconvertor for uint256;
     // constant and immutable are better way to save gas 
    uint256 public constant MINIMUM_USD=50* 10**18;

//  uint256 public number;
// ask about error on stack exchange ETH
                    
       address[] public funders;
//state variables
mapping(address=> uint256) public  addresstoamountfunded;

address public immutable  i_owner;
AggregatorV3Interface public priceFeed;

//modifier
modifier onlyowner{
      //  require(msg.sender == i_owner ,"sender is not owner");
      if(msg.sender!=i_owner){revert Fundme_notowner();}
        _;
}
//FUnction Order 
//constructor
//receive
//fallback
//external
//public
//internal
//private
//view/pure


        constructor(address priceFeedAddress){
            i_owner=msg.sender;
            priceFeed=AggregatorV3Interface(priceFeedAddress);

        }
      receive() external payable {
        fund();
      }
      fallback() external payable {
        fund();
      }
/**
 @notice this function funds this contract
 @dev this implements price feed as our library
 */
      function fund()public payable {
      require(msg.value.getconversionrate(priceFeed)>=MINIMUM_USD,"didnt send enough");
        
      funders.push(msg.sender);
      addresstoamountfunded[msg.sender]=msg.value;
        
          //reverting returns the total gas spent when particular amount of transaction does not meet the conditions
          
        //   number=5;
        // msg.value.getconversionrate();
         
          // msg.value has 18 decimal places 


          // getting an input from the real world is a genuine concern and to do thiswe also need to take care that there
          //sholud not be a single data provider we are provided with
          // chainlink which is a decentralized oracle network which help us to build hybrid smart contracts 
          //which is also able to extract data from the real world
          
      }
      

      function withdraw() public onlyowner{
        //    require(msg.sender==owner,"sender is not owner!");

          for(uint256 funderindex=0;funderindex<funders.length;funderindex++){
              address funder= funders[funderindex];
              addresstoamountfunded[funder]=0;
          }
          //reset the array 
          funders = new address[](0);
          //transfer 
          //msg.sender is of type address

         payable( msg.sender).transfer(address(this).balance);
         //send 
         bool sendsuccess= payable(msg.sender).send(address(this).balance);
         require(sendsuccess ,"send failed");
         //call
         (bool callsuccess ,)=payable(msg.sender).call{value : address(this).balance}("");
         require(callsuccess,"call failed");
         
          
      }
   //modifier (could be used when several function need some change)
   //
      //receive and fallback basically takes large amount of gas
      
    
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

 library priceconvertor{
     function getprice(AggregatorV3Interface priceFeed )internal view returns(uint256)  {
          // abi of contract
          //address  too 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
       
         ( ,int256 price,,, )=priceFeed.latestRoundData();
         // it has 8 decimal values
           return uint256(price*10**10);
      }


     

      function getconversionrate(uint256 ethamount,AggregatorV3Interface priceFeed) internal view returns(uint256) {
          uint256 ethprice =getprice(priceFeed);
          // 1516.000000000000000000
          // 1
          uint256 ethamountinusd =(ethprice*ethamount)/1e18;
          return ethamountinusd ;
      }
 }