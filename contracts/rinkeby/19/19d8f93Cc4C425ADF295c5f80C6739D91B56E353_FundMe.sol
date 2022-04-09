//licence identifier
// SPDX-License-Identifier: MIT


// because solidity is always upgrading its source code, some source codes may not work in some version of solidity, 
// hence a need for ur to always ensure we choose a solidity version, depending on our need. 
// alwyas remember to end ypur line of code with semi-colum. 
// the code below says that, we want to work with a solidity version within the renage of 0,6 to 0.9 
pragma solidity ^0.8.0;


// for our contract, we are interesting in writing a contract that builds a factory pattern in smart contracts.
//in our simpleStorage contract, we were able to write a contract to store numbers and match these numbers to stored names 
// in the factory pattern, our interest is to write a contract that generates much of the simpleStorage contracts, and deploys them.
// a need to do this, creates a need for the storage factory.we shall interact in this contrac to deploy another contract.

// before creating our contract, we shall first import the simplestorage 

// we can import the aggregator chain link code to enable convert from eth to other currencies


 import "AggregatorV3Interface.sol";

//the interface contract allows us to interact with non deterministics programs, to enable us get the conversion rate from ETH to other currencies

// we have the interface of the agregator, which contains its address and all. interface do not have function implementation
// e.g in the line of codes below, that the functions are not complete. they just have function name, and return type
//

//interface AggregatorV3Interface {
  //function decimals() external view returns (uint8);

  //function description() external view returns (string memory);

  //function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  //function getRoundData(uint80 _roundId)
   // external
    //view
    //returns (
      //uint80 roundId,
      //int256 answer,
      //uint256 startedAt,
      //uint256 updatedAt,
      //uint80 answeredInRound
    //);

  //function latestRoundData()
    //external
    //view
    //returns (
      //uint80 roundId,
      //int256 answer,
      //uint256 startedAt,
      //uint256 updatedAt,
      //uint80 answeredInRound
    //);
//}

//we shall now creat our contract

contract FundMe {

    // let us build a mapping between address and value

    mapping (address =>uint256) public addressToAmountFunded;

    // when a mapping is initialised, every set of key is initialised.
    // because we cant possibly go through every key, we will create an array for the funders. this way, we will loop through, and reset the balance to zero

    address[] public funders;

    address public owner;


    //lets build a fnction within the fundme contract, that can accept payment

    // we will create a constructor that helps us set only the admins as those who are able to withdraw from this smart contract
    constructor() {
        // what ever we add in here, will be executed immidiately we deploy this smart contract
        owner= msg.sender;
        // the sender of this will who ever deploys this smart contract
    }

    function fund() public payable {

        // now we want to set a minimum amount in dollars that a person can donate to us
        // we can achieve this by settig a minimum value

        uint256 minimumUSD = 50 * 10 ** 18;
        // now that we have set the minimum amount, how do we ensure it is implemented

        // we will use the require statement to check the truthfulness of what ever we set

        require(GetConversion(msg.value) >=minimumUSD, "You need to send a minimum worth of $50 ETH");
        // the function payabel, is meant to allow the function accept payment or pay for things
        // every single function call, has associated with it, a value. 
        // at this stage, when we deploy our contract, the fund me function displays in red, indicating that, it is a payable function
        

        // next, we want to keep tract of who sent us funding, by creating a mapping between address to value, 
        // let us keep this record by using some key word msg.sender and msg.reciever which go along with every transaction

        addressToAmountFunded[msg.sender] += msg.value;
        //msg.sender is the sender of the function call, and msg.value is the amount they have sent.

        //next, we want to set the minimum value that we can be funded
        // we intend to do this using different tokens. 

        // we know that blockchains are deterministic systems and oracles are a bridge between this deterministics 
        // system and the real world. we will be using the oracle for this purpose; to convvert from ETH to other currencies and set a minimum value that we can be funded with
        // we shall be using a oracle network called chainlink, which is a decentralised system that allows us to get data and  carry out computation in a highly civil resistance decentralised manners


        // in our previous line of code, we instructed solidity to match the sender and the value they send. we also know that solidity does not know how to interact with another contract
        // we will be teaching solidity how to do that. in this case, we want our contract fundme to interact with the interface above
        // we will tell our contract what functions to interact with in the other contract

        // similar to struts, interface can also help us find new types
        // interfaces compile down to what is called the ABI (application binary interface). this tells solidity what functions in the other contracts it can interact with
        

        //now when a person funds the contract, we will push it into the array

        funders.push(msg.sender);





    }

    // now we want to interact with the version function in the interface, so we shall create and get version function
     function GetVersion() public view returns(uint256) {
         // we used the view function because we are just going to be reading the state
         // we will name it price feed, since the aggregator will be giving us pricefeed. the contract is initialised by the right hand side

         AggregatorV3Interface pricefeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

         // next, we write a line of code to be able to call pricefeed

         return pricefeed.version();

         // the above function has just called the version of the aggregatorv3interface

         // we will now try to get the price feed


     }

     // we are going to write a function that interacts with the aggregator function to get pricefeed

     function GetPrice() public view returns(uint256) {
         // we will see in our interface that the latestRoundData data has 5 values. 
         AggregatorV3Interface pricefeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

         // since this is going to return 5 values, we can have our contract return the 5 values.
        //(   uint80 roundId,
            //int256 answer,
            //uint256 startedAt,
            //uint256 updatedAt,
            //uint80 answeredInRound
       //) = pricefeed.latestRoundData();

       // to make our codes much cleaner, we will ignore the other variables we wont be using by a doing the code below

        ( ,int256 answer,,,) = pricefeed.latestRoundData();


       // a tupple is a list of objects of potentially different types, whose number is a constant at compile-time. the above is a type of tupple, that allows us define various variables in it.

        // now, we want to choose a variable to print. our public view is in uint256, but some of our variables are not in uint256
        // to get this variables, we will need to cast them to uint256. e.g we want the answer, yet its in int256. we shall cast it to uint256 with the code below

        //return uint256(answer);
        // the above line of code should return the ETH price in USD

        // to convert to wei, we simply multiply by 1000000000

         return uint256(answer*10000000000);
     }

     // having gotten our contract to interac with interface and get ETH value for USD, we want to get the conversaion rate

    // the function below will help us get conversion rate
     
     function GetConversion (uint256 ethAmount) public view returns(uint256) {
         uint256 ethprice = GetPrice(); //we want to convert what amount we get
         uint256 ethAmountInUSD = (ethprice * ethAmount)/1000000000000000000;
         return ethAmountInUSD;

     }

     // we have succeded in making provision to fund the above account, but did not make provision for withdrawal. 
     //we shall create a function that allows us withdraw the amount recieved.

     modifier onlyowner {
         require(msg.sender == owner);
         _;

         // the modifier will ask the function to run the reauire statement first, then whereever the _ is in your modifier, run the rest of the code

     }

     function withdraw()payable onlyowner public { 

         //require(msg.sender == owner);
         payable(msg.sender).transfer(address(this).balance);

         //the tranfer function helps send eth from one adress to another.

         // next, when we withdraw everything, we want to set balance in that mapping to zero
         // we will use the for loop to carry this out

         for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){

             //the for loop will loop through all the arrays 

             // we are seaching through the funders array 

             address funder = funders[funderIndex];

             addressToAmountFunded[funder]=0;

             //now we have to reset our funders array as well

         }

         funders = new address[](0);


     }
     //right now, anyone can withdraw funds in this contract. we want to limit the withdrawal to only admins
     // to do this, we will use the contructor, to avoid others contracts from having the ability to interact with it
    

    // what if we have many contracts that want to use the require function to ensure only owner can withdraw funds
    // we will be using the modifier function to put that in place. Modifiers are used to change the behaviour of a function in a declarative way
    // we want to be able to loop through every denor to reduce their balance to 0. to do this, we will use the array
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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