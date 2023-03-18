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

// SPDX-License-Identifier: MIT

//Get funds
//Withdraw funds
// Set Min Funding Value

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    //constant  keywork reduces the gas cost
    uint256 public constant MINIMUM_USD = 50   * 1e18;//sending  from  outside or  transaction will be  cancelled.
    address[] public funders;
    mapping(address=>uint256) public addressToAmountFunded;

    //immutable saves more  gas
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    //called auto when contract is deployed
    //adding parameter  to contructor then we can save  aggregator v3 addterss as a  global var
    constructor(address  priceFeedAddres) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddres); //refer to priceconvertor.sol for reference
        //we can take this priceFeedAddres as a global var  and use  it   with priceconvertor
         // with hardhat  fund me we  want  t o avoid  hardcoding  of  addres with v3interface
    }

    /*function fund() public payable{
        //make the function  payable to make it appear for what is doing distinctly shown as  red button. Public  will make it accessible

        //Want  to be able to set min fund amount in USD
        //1. How do we send ETH  to this contract

        //We are able  to access value attribute check  Deploy & Run transaction

        //require // send  2 ETH  min to  fund
        require (getConversionRate(msg.value) >= MINIMUM_USD, "Send Enough ETH");// 1e18 == 1 * 10 * 18 == 1000000000000000000  wei  is 1  ETH 
    }*/

        function fund() public payable {
        //msg.value here is  whatever value it is for ETH or any other cryptocurrency we are interacting with
            require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        //require(getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public  onlyOwner{

        //require(msg.sender == owner, "Sender is not owner");

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //reset the array
        funders = new address[](0);

        //actually withdraw funds
        //call
                           //bytes memory dataReturned is optional     
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");    

    }

        // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    
    //This functions  are called if the user  called the wrong function and  we  still  want  to  handle  the  call  data
    //  User w ill lose the moeny  in a normal  scenari, however if  we handle the data  with some  special  function
    // we can still call these special function when user fails tto call the correct one and within those special  function call fund()
    
    fallback() external payable {  //  if htere is data  associated  with the function  but function itself is  wrong then  fallback is called
        fund();
    }

    receive() external payable { // when there  is  no  data    associated  recieve() gets called
        fund();
    }


    modifier onlyOwner {
            //require(msg.sender == i_owner, "Sender is not owner");
            if(msg.sender != i_owner) { revert  NotOwner();}
            _;
        }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    //function withdraw(

    //get  the conversion rate  using func

    //get  the price of ETH
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        //ABI : It is different  functions  and properties
        // Address : 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e goerli contract address from docs

       // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in  tterms of USD
        // ETH current price 
        //8 deimals associated in priceFeed we need 10 more
        return uint256(price * 1e10);

    }
    //we  eliminated the use of getversion  function for fundme 
   /* function getVersion() internal  view returns (uint256) {
        // with hardhat  fund me we  want  t o avoid  hardcoding  of  addres with v3interface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();//version of price feed

    }*/

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18; //need  to do  this as we do not want to end up with too many 0's

        return ethAmountInUSD;
}

}