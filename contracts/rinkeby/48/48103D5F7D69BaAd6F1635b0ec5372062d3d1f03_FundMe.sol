// SPDX-License-Identifier: MIT

// wont work on javascript vm because we dont have a chain linknetwork for it, just interweb 3


pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

// constant keywork and immuniable keyword will bring gas cost down

// contract that allows people to fund a collective good send etheriuem polygon or alvalance owner can withdraw funds and do what they want
// fund and withdraw functions are payable functions.
// sned value to transaction which will be the fund function by pasteing value in the wei value section
// get funbds from users
// withdraw funds from users
// set a mininum funding value in USD

// 	901,675 gas the contract costs
//882,152  with constant key word
// vire functions do have gas cost when called
contract FundMe {

    using PriceConverter for uint256;


    // mininum amount of dollors sent
    // this value is outside of the blockchain
    // use decentralized oracle network toget the price of one either in terms of USD
uint256 public  constant  MINIMUM_Usd =  50 * 1e18;
//21371  -constant
//23471  -unconstant * 22 000 000 000 = 516 362 000 000 000  .00052  * 1490 (current price of Ethereum)// this will make  a big differance on expensive chains like etherium if you dont use constant keyword

// array to keep track of funders
address [] public funders;
// mapping addresses to how much money each one has sent
mapping(address => uint256) public addressToAmountFunded;

// on the only can call withdraw function
// constructor gets called immedately whenever you deploy a contract

// constructor will set up who the owner of the contract is

// variables that we set onetime butoutside of the same line we declraed  immutable
//immutable keyword also makes variables more gas efficent 

// consdtants and immutables save gas because  they are stored directly into the byte code of the contract instead of the storage slot
address public  immutable i_owner;
// pass usd address depending on what chain we are on rikeyby, polygon ,ect
//pass priceFeed address depending on what network we are on
// have it take address of pricefeed
// this brings over the aggretor to interat with the abi of the prices of the contract
// paramatising pricefeed address, passing it in with a constructor, gets saved as a global variable to an aggregatorv3 interface type, passing it (priceFeed) to  a get conversion rate function which passes it to the get price function which then calls the latest round data, refactored code to pass priceFeed address depending on what network we are on   
AggregatorV3Interface public priceFeed;
constructor(address priceFeedAddress) {
i_owner= msg.sender;
// this brings in the address depending on the chain that we are on
priceFeed=AggregatorV3Interface(priceFeedAddress);

}



// send money to
// anyone should be able to call this function
// payable makes function payable
// smart contrac t addresses can hold funds as well just like wallets
function fund() public payable{
    


    // set mininum fund amount in usd
    // get the value someone is sending rewuire is the limit for how much eth  or other polygon alvalance, ect to send
    // require is a c boolean checker
    //revert undo any action before, and send remaining gas back it undos any transaction made gas is still spent to change  example variable but the remaining gas gets returned
    
//    require (msg.value >  1e18, "Didn't send enough "); // 1e18 = 1*  10 ** 18 = 1000000000000000000 = 1 Eth
// need to convert etherium to USD
//msg.value is how mucb native block chain currency is sent
// use library file to get conversion rate
// msg.vale us considered the first parametor in library functions
// stick pricefeed in there so you can get the conversation rate of each chain
  require (msg.value.getConversionRate(priceFeed) >= MINIMUM_Usd, "Didn't send enough ");
  // msg.value will have 18 decimal places because 1 ETH = 18 decimal wei

  // when someone sends us moiney and the transaction goes through
  // msg .sender is the address who ever calls the fund function // our wallet address will be added to funders list
  funders.push(msg.sender);
  //gets activiated when contract is funded
  addressToAmountFunded[msg.sender] = msg.value;
}          
                            //function does whats in modify first before completing function
function withdraw() public  onlyOwner {
   
// loop through funding array to make sure each funder now has zero
// for lop loop for an index object or index or list a certain amoint of times
// staring index, ending index, step amount 
// wil withdraw from all the funders
for( uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
// access 0 element in the address
//acess 0 funder in the adress
 address funder = funders[funderIndex];
 //reset the mapping
 // reste number to 0
  addressToAmountFunded[funder] = 0;


}
// reset the array
// funders varable now has new address array with 0 objects in it to start
  funders = new address[](0);
// withdraw the funds
// 3 ways to send native block chain currency

// transfer
// send
// call

// transfer funds
// this key word refers to whole contract get balance of contract
// typecast sender address to payable you can only work with payable addresses in Etherium to send native block chain token
// to send tokens, wrap the address we want to send token to in payable, . transfer says how much we want to transfer
//transfer
// transfer automatically reverts if transfer failed
payable (msg.sender).transfer(address(this).balance);
//send
// need a bool to revert transaction in case it fails
bool sendSuccess = payable(msg.sender).send(address(this).balance);
require(sendSuccess, "Send failed");
// call
// third way to send block chain currency
// first lower level commands we use call any function in etheium without having the abi
// put information in call to get info from some other contract
// using call to send etherium or native block chain currency
// this function calls 2 variables  so you can show that by 2 parathesis on both sides
// the call function allows to call differant functions if it teturns data, it will be saved in the data returned varable it also returns call success which is true or false
// bytes object returns arrays so it needs to be in memory
// return s 2 variables but only need 1

// using call is the current recommeneded way for sending or recivieving block chain native token
 (bool callSuccess, /*bytes  memory dataReturned */) = payable(msg.sender).call{value: address (this).balance}('');
require(callSuccess, " call failed");
// once set any function  call or transaction call can be reverted
revert();
}

 //function does whats in modify first before completing function
modifier onlyOwner {
     // withdraw function is only called by the owner of the contract
    // require(msg.sender == i_owner, "Sender is not owner");
    // this dsaves alot of gas because you dont have to store string here
    //require is still common so get use writing it in both ways
    if(msg.sender != i_owner) {revert NotOwner(); }
    _;
}
//accidently sends money we can still process the transaction without calling find function
// if someone doesnt send enough money, the transaction will get reverted
// receieve function automatcally calls fund function
// the fund function takes less gas but they will get some credit and it will get funded to funders array
// function will still get funded without saying the fund function.

receive() external payable {
    fund();
}
// call back data that doesnt specifify other functions, this will be called
fallback() external payable {
    fund();
}

}


// updating the requires will make contract more gas efficent 

//What ahppens if someone sends this contract ETH without calling the fiund function

// receieve()

// fallback()
// recireve functions get triggered any time a transaction to the contract 
// fallback interacts with call data

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import  code outside of contract directly from github or known as the npm package
// yarn add hardhat to get hardhat
//yarn hardhat once you have it installed
// yarn add --dev @chainlink/contracts downloads package
//yarn hardhat compile

//yarn add --dev hardhat-deploy
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// libraries cant have any state variables and cant send ether  all functions in libraries are internal

//minimise math in fund me contract
library PriceConverter {
// First get price of Etherium to convert to usd using a function

// etheirum price
// make public internal in libraires
// put priceFeed in here  no longer need to hardcode the price feed
function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
// this is a function interacting with a contract outside of our project going to need:
// ABI, 
//Address eth/usd other contract address:	0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
// go to chain link doc to get eth in USD under etherium data feeds
// use this to make api calls
                                                                    //this is valid
// AggregatorV3Interface(	0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).version();
//create oaggregatorv3 interface variable called price feed = to contract
// AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    // also on chain link docs using data Feed section    just care about pice                                                                   //from aggreatorinerface contract on chain link github
(, int256 price,,, ) = priceFeed.latestRoundData();
// price of ETH in terms of USD
// 1,611.92571651 
// typecast uint256 to get uint256 number
//ETH in terms of USD
return uint256 (price * 1e10); // 1**10 == 10000000000
}
// uses interfaces to interact withcontracts that exist outside of project, use one of the interfaces that can be compiled down to the abi combine abi with the address to call the function
function getVersion() internal view returns (uint256) {
    AggregatorV3Interface priceFeed= AggregatorV3Interface(	0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    return priceFeed.version();
}

// convert etheirum to usd      intial parametor is message.value, the second will be the the prices on each chain                  
function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)internal view returns(uint256) {
// call pricefeed in the get price function
uint256 ethPrice = getPrice(priceFeed);
//30000,000000000000000000 = eth/usd price
// 1_000000000000000000 ETH.   // times eth price and amount divided by 1318
uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
// 2999.999999999999999999
// return exactly 3,000 in solidity
return ethAmountInUsd;


}






//owner of contract to withdraw from
// function withdraw(){

// }

// 1,611.92571651 8 decimals // get pirce usd on chain linmk documentation
// can use differant addresses for differant price feeds bying using th network that you want and looking at the addresses for price feeds

}

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