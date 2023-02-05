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

//refactored for JS / TS deployment, Lesson 7
// kept comments, removed some, added new ones

// what the contract do:
// Allow users to fund and withdraw
// a minimum value to fund
// convert the fund amount to a USD value equivalent
// only owner can withdraw
// keep tracks of who fund, arrays list and struct

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

/*
for gas efficiency change require statements and their custom error message which are arrays of string
saved into memory, into if statements and revert condition.
to do so we declare the error code outside the contract scope then change require statements into if + revert
    gas before : 759,956  
    gas after : 734,929
*/

contract FundMe {
    using PriceConverter for uint256;

    // let set a minimum value using chainlink in USD, 50$
    // upgrade to 18th
    // uint256 public MINIMUM_USD = 50 * 1e18;
    // if eth is 1260 do 50 / 1260 = eth amount to input for funding

    // gas efficient solution
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    uint256 public constant MINIMUM_USD2 = 50 * 1e18;
    /*
    Constant variables are ALL CAPS
    When a variable is set globally with no purpose ever to change it can be set to constant
    doing so the variable will not occupy a storage spot no more. Memory allocation on the blockchain
    lower computation, lower gas
    gas before : 803,089 
    gas after : 783,523 
    gas before and after constant on that function call only can change from few cents to a whole dollar depending of the price of ether
    */

    // funders arrays. an array of addresses public called funders
    address[] public funders;
    // mapp which addresses funded with what amount
    mapping(address => uint256) public addressToAmountFunded;

    // OnlyOwner constructor
    // it is a function called immidiatly after the contract is being deployed

    // global variable of an address called owner
    //address public owner;

    // gas efficient solution
    address public immutable i_owner;

    /*
    immutables variables are specified immutable and the variables starts by i_
    When a variable is set once outside of the line whre they are declared, they are set as immutable
    like for constructors
    gas before : 783,523  
    gas after : 759,956
    gas before and after immutable on that function call only can change from few cents to a whole dollar depending of the price of ether
    */

    // immutable and constant are saved directly into the bytecode of the contract instead of in a storage slot.

    /*
    REFACTOR LESSON 7 step 0 (next step is in priceconverter.sol)

    - added a pricefeed parameter to the constructor, which use a global variable containing an address
    address will change depending of the network we use.
    change made for it
    - added parameter to getConvertionRate, which use the getPrice function to which
    the parameter of priceFeed is also added.
    Allowing to delete the hardcoded initial priceFeed address that was in getPrice()
    since it is now a global variable
    */

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        //set owner to the contract deployer address
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // want everybody to be able to fund the contract -> function public payable
    // needs to be payable to allow transaction with the functions for a deposit
    function fund() public payable {
        // now we can do this
        // msg.value.getConversionRate(); // secretly the same as -> getConversionRate(msg.value);

        // if compiling with the line under will get an error as
        // because in our library at the getConversionRate function,
        // the first parameter it use will be the object on itself, will use msg.value for msg.value.
        // require(getConversionRate(msg.value) >= MINIMUM_USD, "Not sufficient amount for funding, 1 eth minimum."); //1e18 is the same as 1*10**18 -> 100000000000000000000
        // so we need to change it for :
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Not sufficient amount for funding, 1 eth minimum."
        ); //1e18 is the same as 1*10**18 -> 100000000000000000000
        // we are not passing a variable to getConversionRate because msg.value is considered to be the first parameter due to be imported as a library.
        // so if getConversionRate requires a parameter as input it will use that one first.
        // if it requires another parameter or more, those will need to be put into getConversionRate parenthesis.
        // msg.value.getConversionRate(param2, param3, etc...)

        // each time someone funds add to the the array
        funders.push(msg.sender);
        // show how much has been funded from that sender
        addressToAmountFunded[msg.sender] = msg.value;
    }

    // function for withdrawing
    function withdraw() public onlyOwner {
        // after withdrawing put back to zero the amount funded by that wallet address
        // loop through the array for this

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array, 2 ways
        // loop through each element and delete it one by one
        // or refresh it to a zero state as a new array of 0
        funders = new address[](0);

        // withdraw from a contract, 3 ways for doing so.
        // transfer, send, call

        // transfert is the simplest and makes the most sense at this level
        // transfer to the sender(like the requester here) at this contract balance
        // works only for payable address.
        //msg.sender is of type address
        // where payable(msg.sender) is of type payable address, so we just wrap into the payable type caster
        //payable(msg.sender).transfer(address(this).balance);

        //transfer details:
        /*
        Auto revert
        a normal transaction is capped at 2100 gas fee, transfer is capped at 2300
        if more gas fee is used on transfer it will throw an error and revert the transaction
        */

        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess,"Send failed");

        //send details:
        /*
        Needs a boolean and require statements for reverting
        send is also capped at 2300, but if it errors it return a boolean, success or not, transaction doesn't revert.
        to have it reverting it need a boolean state that require true or false, success or failure. which allow a revert condition
        */

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
        //call details:
        /*
        Low level command.
        It is the most powerfull and allow  to call any function on the whole Ethereum space
        without the need to have the ABI. 
        For now we stay at the stage of balance transactions and we'll get to it later.
        Similar to send for its structure.
        first parenthesis following is used for calling a function
        
        calls particularity:
        No cap gas
        calls allow us to call any function on ethereum without its ABI, so it own a structure considering that
        here we leave it blank -> ("")
        to have it working as a value of a transaction we need to call that value and input what we want into it,
        can be done using curly brackets before any function call.
        -> {value: address(this).balance}("")
        so calls return actually 2 variables, curly brackets one and parenthesis one.
        so on the left hand side it needs to be adhusted for 2 variables, 
        the way to attribute two variables is the same as the getprice function, into parenthesis coma separated.
        -> (bool callSuccess, bytes memory dataReturned) =
        it returns a boolean checking true or false and where the function call is saved. as it is saved in a byte object it needs to be put in memory.
        but as we dont need the second one it can be deleted and leave the coma like for getPrice function earlier.
        ->  (bool callSuccess,) =
        then add a require statements for the boolean to be attributed to something.
        */

        // for the most parts, call is the best practice, it can be case by case.
    }

    //Modifier
    /*
    quick way to have a onlyowner logic into withdraw() is to set a requirement
    require(msg.sender == owner, "Not the owner!");

    or to set a modifier having the same  requirement in a separate place, allowing then to be able to put that modifier 
    in any function declaration easily.
    modifier are set at the bottom of the code and last line of it must end by -> _;
    allow to do this after -> function withdraw() public onlyOwner{blablabla}

    in the logic it will read withdraw declaration then stop at onlyowner, look at the modifier
    do everything that is inside the modifier then do restart reading where it stopped  when it meet the _; in the modifier.
    so it will start reading again at the withdraw declaration at the onlyOwner position.
    */
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Not the owner!");

        // if solution for gas efficiency using custom errors from the top
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // add receive and fallback to prevent when someone is trying to send Eth directly without interacting with any other functions.
    // like a default interaction case.

    // when receive get a call from outside it redirect to the fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// this contract will be used as a library that we will attach to an uint256
// for let say be able to even use msg.value as it was an object, array, struct or even a function and be able to call function on it.
// like -> msg.value.GetPrice();
// library function should be internals
// library global frame start with library not contract
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //function to get the price of eth
    //get price in term of usd

    /*
    REFACTOR Lesson 7 Step2 (step 1 is at the bottom)

    - added the AggregatorV3Interface of priceFeed parameter
    - which allow us to delete the hardcoded price feed initialy written in this function
    - commented it, step 3 inside the function
     */
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // since we are interacting with something outside of this contract we need two things:

        // I.The ABI
        // to get the ABI there is multiple way:
        // 1. import the whole code of the other contract in ours.
        //  But we dont need to include all functions, we can just include what we need.
        // 2. There is a concept in solidity called Interface.
        //  https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
        // Let's look at AggregatorV3Interface, there is function without their logics.
        // If we compile AggregatorV3Interface, we can get its ABI.
        // So if we copy the code of it and paste it in this contract we can work with its ABI.
        // remember in one contract we can have multiple contracts if they re well defined in their own contract{} declatarion.
        // So doing so allow us to do something like this:
        // AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e).version()
        // AggregatorV3Interface at that address, and if both can work together then we can call any functions without errors, so let try to call version of aggregator at this address.
        /* A More detailed image of that exemple
           function getVersion() public view returns (uint256) {
               // Make an object of type AggregatorV3Interface (the contract), called priceFeed, with values of Aggregator at the Goerli address of ETH/USD
               AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
               // And return an uint256 of the version of priceFeed, wich is the same way to ask the version as it is The aggregator at the ETH/USD address, just put into one variable / object.
               return priceFeed.version();
           }
           This is an easy way for us to interact with contracts that exist outside of ours.
        */
        // 3. we can also import the contract at the top -> import "./AggregatorV3Interface.sol"
        // and create a local contract named the same containing its code.
        // 4. or we can directly import from github and npm (package manager)
        // if we look at the doc of chainlink interfaces its explained how to. remix is smart enough to understand it.
        // import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

        // 5. there is a way to interact with any contract without the ABI but for now let stick to the ABI normal ways as above.

        // II.The contract address to interact with
        // ETH/USD goerli contract address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        /*
        REFACTOR Lesson 7 Step3 (step 2 is at the top)

        -comment priceFeed, so no more hardcoded addresses
        */

        // so here is our contact to aggregator contract
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );

        // from which we call latestRoundData and values we want to keep and return
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // eth in terms of usd as we speak
        // 126000000000 -> 8 decimals on this price feed so -> 1260.00000000
        // return the price, but our msg.value is an uint so it also need to be casted as an uint, also it needs 10 more decimals to match those 18 from msg.value in wei
        return uint256(price * 1e10); // 1e10 = 1 raised to the 10th -> 10000000000
        // then change the function type to view and to returns that uint256
    }

    function getVersion() internal view returns (uint256) {
        // Make an object of type AggregatorV3Interface (the contract), called priceFeed, with values of Aggregator at the Goerli address of ETH/USD
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        // And return an uint256 of the version of priceFeed, wich is the same way to ask the version as it is The aggregator at the ETH/USD address, just put into one variable / object.
        return priceFeed.version();
    }

    //function to get the conversion rate
    // as input, an uint256 of ethAmount, public view returning an uint256

    /*
    REFACTOR Lesson 7 Step 1

    - added a new parameter to the getConversionRate, of type AggregatorV3Interface named priceFeed
    - now when we call the getPrice function we pass the priceFeed to it
     */
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //call getPrice and attribute the value to a variable
        uint256 ethPrice = getPrice(priceFeed);
        // multiply and add first in solidity then divide.
        // divide by 1e18 because else it will get 36 decimals
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}