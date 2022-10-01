// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.8;
//copied contract from lesson from remix FunMe2
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// this contract is when u make all conversion functions
//as library and use it






contract FundMe {
  
  using PriceConverter for uint256;
   //as getconvrate will return in 18 deci
   uint256 public minimumUsd=50 * 1e18;
   address[] public funders;
   mapping(address=>uint256) public addressToAmountFunded;

   //added
   //basically in oreder to convert we were using hardcoded address from chainLink
   //what when we have to change it? everytime change hardcoded one ?NO
   //plus in remix we were importing it directly and running it on online network
   //so how to use that in local?

   //so we have now change that hardcoded by passing the address dynamically
   //loading in constructor then passing into converter contract in getaPrice function as second arg
  
   //public variable
   AggregatorV3Interface public priceFeed;
   address public owner;


constructor(address priceFeedAddress){
    //in order to let owner be the one who can withdraw 
    owner=msg.sender;

    //added
    //passing address to priceFeed variable in constructor
    priceFeed = AggregatorV3Interface(priceFeedAddress);
}




   function fund() public payable{

       //we wrote msg.value.getConv insted  getConv(msg.value) 
       // as first arg will be given always like arg.function(if multile then all except first give herein parenthesis as usual)
       
       //priceFeed is now given as 2nd parameter to that contract
require(msg.value.getConversionRate(priceFeed) >= minimumUsd,"Didn't send enough");
// now to store all senders address
funders.push(msg.sender);
//settinf map values 
addressToAmountFunded[msg.sender]+=msg.value;
  }


function withdraw() public onlyOwner{

// as we did in constructor
//so only owner can withdraw
//  require(msg.sender==owner,"Sender is not owner");
//but since we have to check this cond in multiple func we will use modifiers
//added onlyOwner to chk that modifier first


    //we can withdraw funds but have to update funds of giver as well
    for(uint funderIndex=0;funderIndex<funders.length;funderIndex++){
        //get the address of the funder
        address funder=funders[funderIndex];
        //now setting its fund to 0 in map via address
        addressToAmountFunded[funder]=0;
    }

    //completely RESETtin THE ARRAY with 0 elements
    funders = new address[](0); 

    //actually withdraw the amount
    //3 ways

    //transfer //send //call

    //1st
  // msg.sender => address
  // payable(msg.sender) =>payable address(typecasting)
  //this will get the whole balance of this contract
  //it is limited to 2300 gas fee it will auto, revert incase of that and throws error
    payable(msg.sender).transfer(address(this).balance);
    
//2nd
// for send limit is same of 2300 but it will return bool so
// we have to revet it explicity by checking bool
bool sendSuccess = payable(msg.sender).send(address(this).balance ) ;
require( sendSuccess," Send failed ");


//3rd
//its a low level command very powerful
//returns two variable , boolean , byteobj (data in form of array)
//since we are not calling any funchere we put "" in ()
// ( bool callSuccess, bytes memory dataReturned ) = payable(msg.sender).call{value:address(this).balance}("");

//we don't need dataobj here as we ar not calling any funct
( bool callSuccess,)=payable(msg.sender).call{value:address(this).balance}("");
require(callSuccess,"Call failed");
}

modifier onlyOwner {

    require(msg.sender==owner,"Sender is not owner !");
    _;
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

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice( AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // Goerli ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        
      
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed )
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}