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
pragma solidity ^0.8.7;
import "./PriceConverterLibrary.sol";

/*
 in this contract we want to
  1. Get funds from users
  2. Withdraw funds
  3.Set a minimum funding value in USD

  Each transaction contains information like nonce(transaction count for the account), gas price,
  gas limit, to(address that the transaction is sent to), value(amount of wei to send), data(what to send
  to `to` address), vrs(crypotographic magic) component of the transaction signature

*/
contract GoFundMe{
    using priceConverter for uint256;
    /* this line above will make the functions of price converter library imported in this contract 
    accessible via uint256 eg msg.value.getConversionRate(), remember that msg.value has type uint256
    if the library function takes parameters, the uint256 value is regarded as the the first paramter
    eg msg.value in the example msg.value.getConversionRate(), the other parameters of the function
    can then be passed in the parenthesis of the function

    constants and immutable are used to declare variables that won't change and it is more gas efficient,
    because they are stored into the bytecode and not on the storage slot, they are easier to be read.
    constants should be declared with capital letters and underscore is used to join mutiple words
    use immutable for variables that will only recieve value once but in a different place from the line
    where it was declared eg variables that recieve there values in a contructor, immutable variables names
    can be preceded with i_ eg i_owner.
    using less require statement can  be gas efficient because the second argument of the require statement
    which is the string to be displayed when error occurs will need to be stored and thus will consume more gas
    rather work with custom errors and if statements which is more gas efficient
    */
    

    uint256 public constant MINIMUM_USD = 5 * 1e18; // we mutiply by 18 zeros so the unit will be same as etherium
    address[] public funders;
    mapping(address=>uint256) public addressToAmountFunded;
    address public immutable i_owner; // owner of the contract
    AggregatorV3Interface public priceFeed;


    constructor(address priceFeedAddress){
      i_owner = msg.sender;
      priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /* In order to send etherium you have to add payable keyword to the processing function
      * msg.value returns the value of wei a person is sending
      * msg.sender returns the address of whoever calls the function      
     */
    function fund() public payable{
        /* to validate the amount of ether the user is sending
          the require function checks whether the condition is passed, if condition fails
          it will display the message in the second argument, revert the previous action done
          in that function call (if any) and return the remaining gas fee (so the gas fee used to do
          any action before the line of code with the require statment will be lost)
        */ 
        require(msg.value.getConversionRate(priceFeed)>=MINIMUM_USD, "Amount sent is not enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner{        
        for(uint256 funderIndex =0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset funders array to new array with zero item
        funders = new address[](0);
        /*withdraw the actual funds, we can do that through transfer, send or call function,
        msg.sender is of type address, while payable(msg.sender) is of type payable address,
        address(this).balance returns the balance of the contract. The transfer and send method
        consumes 2300 gas and fails if the transaction requires more than 2300 gas
        */
        // // using transfer, it automatically reverts if the transfer fails
        // payable(msg.sender).transfer(address(this).balance);
        // /*using send, it doen't revert if transfer fails, rather it returns a boolean value false,
        //  so we might need to use require to revert it ourselves if it fails*/
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"Transfer failed");
        // // using call, returns 2 values, first one indicates whether it was successful and the other is the returned data(bytes memory dataReturned)
        (bool callSuccess, ) = payable(msg.sender).call{value:address(this).balance}('');
         require(callSuccess,"Transfer failed");
    }

    // a modifier is a keyword we can add to a function declaration to modifier the behaviour of that function
    modifier onlyOwner{
      require(msg.sender == i_owner,"Sender is not contract owner");
      _; /* this line means do the rest of the code in the function that calls this
       modifier after running the code in this modifier, if this _; comes first in the modifier
       it means do every thing in the calling function first before running the content of the modifier*/
    }

    receive() external payable{
      fund();
    }

    fallback() external payable{
      fund();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/*
    * A library is similar to a contract but you can't decalre a state variable and you can't send ether
    * Money maths is done in terms of wei, 1ether = 1E18 wei(1 * 10^18 wei)  
    * To convert the value of ether to USD, we can use chainlink and oracles.
    * Smart contracts are unable to connect with external systems like data feeds, APIs etc on their own. 
    * We dont want to get our data through a centralized node it will defeat the purpose of blockchain
    * Blockchain oracle is any device that interacts with the off chain(external) world to provide external
    data to smart contracts.
    * We will make use of chainlink(decentralized oracle network) to bring external data to our smart contract
    specifically we will be making use of chainlink data feed(this can return different data eg prices of cyptocurrencies).
    * Chainlink keepers is used for decentralized event driven executions
    * Chainlink nodes can make API calls
    * Chainlink VRF is used to get provable random numbers
*/
library priceConverter{
    
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        // here we have to interact with chainlink to get the price
        // inorder to interact with external contracts we will need the address and ABI
        // to get the ABI, we have to compile the interface   
        // this price below is ether in terms of USD         
        (,int256 price,,,) = priceFeed.latestRoundData();   
        // return uint256(price * 1e10); 
        return uint256(price); 

    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/1e18;
        return ethAmountInUsd;
    }    
}