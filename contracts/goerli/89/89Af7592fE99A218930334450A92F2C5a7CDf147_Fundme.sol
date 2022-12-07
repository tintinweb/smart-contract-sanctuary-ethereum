/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
// This contract will make a call to another contract using an Interface. 
//      1) The contract we are calling is the ETH -- USD price feed on the Goerli testnet.
//          I.E. AggregatorV3Interface priceFeed = AggregatorV3Interface(
//               0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e)
// Interfaces are a minimilistic view into another contract !!

//  When we deploy a contract it will cost some ETH --> Wei 
//  Anytime we make a state change to BC it costs gas

//  Visibility: 
//          public      visible externally and internally (creates a getter function for storage/state variables)
//          internal    only visible internally
//          external    only visible externally (only for functions) - i.e. can only be message-called (via this.func)
//          private     only visible in the current contract (DEFAULT)

// Program Contents 
// Payable, msg.sender, msg.value, Units of Measure
// Payable  Allows for sending or receiving some type of Payment in ETH.. WEI ect 
// Wei/Gwei/Eth Converter
// msg.sender & msg.value

// We want this contract to be able to accept some type of Payment [Payable]

pragma solidity >=0.6.0 <0.9.0;

// Import from the Chainlink NPM Package. 
// Search on Web: npm @chainlink/contracts
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Replace above import with actual code which has an [interface].
// **************   Interfaces *******************
//  Interfaces do not have full function Implementations 
//  As shown below we have the function names and return type but no Implementation of functions.
//  Solidity does not natively know how to interact with other contracts. We need to provide 
//  this infomation to Solidity [I.E. What [functions] can be called on another contract !!
//  Similar to Structs, Interfaces can define a new [type].
//  
//  The Interface tells Solidity which functions this contract can interact with. 
//  Interfaces compile down to an ABI !!!! [Application Binary Interface].
//  The ABI tells Solidity [and other programming languages] how it can interact 
//  with [another contract]. 
//              The ABI tells Solidity which [functions] can be called on [another contract]
//
//  Note:   Anytime we want to interact with an already DEPLOYED smart contract, 
//          WE WILL NEED that Contracts ABI !!!!
//  Interfaces compile down to an ABI !!!! [Application Binary Interface].
//
// **************   Interfaces *******************
//  


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


contract Fundme {

    // Create a Function that can be used to Pay for things. 
    // Every single function call has a [value] associated with it.
    // Whenever you create a transaction you can always append a [value]
    // This [value] is how much [gwei or wei or eth] is going to be sent with our function call.
    // Wei, Gwei and ETH are just different ways to describe how much [value] we are going to send.
    // Here is a conversion website: https://eth-converter.com/
    // Example: 1 ETH is equal to 
    //          1000000000000000000 Wei [18 Zeroes]
    //          1000000000          Gwei [9 Zeroes]

    // The smallest unit of measure in ETH is Wei.
    //  1 Wei is equal to
    //  0.000000000000000001        ETH [18 Decimals]
    //  0.000000001                 Gwei [9 Decimals]

    //  Note: Most things are measured in Wei 

    //  What do we want to do when people send us some money ??
    //      1)  Keep track of who sent us some money 
    //      2)  Create a [mapping] between sender [address] and amount.
    //      3)  msg.sender and msg.value are key words in every function call.
    //      4)  Once we send money to a contract the address of the contract is the Owner of the cash !!
    //      5)  We want to set a minimum amount that can be sent to Fund the project, therefore we need
    //          to call an Oracle Chainlink interface that would give us the price of USD --> ETH 
    //          because we want to be able to set the minimul Amount in USD [or some other currency].


    // Mapping from the Sender Account address to the Amount of Wei that was sent. 
    // I.E. Which Account sent the Wei , and how much was sent.  
    mapping(address => uint256) public addressToAmountFunded;

    //address of the owner (who deployed the contract)
    address public owner;

    // array of addresses who deposited
    address[] public funders;
    

    //  the first person to deploy the contract is the owner
    //  The [constructor] gets called as soon as the contract is DEPLOYED 
    //  So, whoever DEPLOYS the Contract is the Owner of the Contract and the funds
    //  We need to limit the Withdraw function to the Owner of the contract.

    //Note: Dennis 11-17-22 removed the keyword [public] to use in solc 8.17
    // constructor() public {
        
    //  Note:   This [constructor()] will be run when the contract is DEPLOYED. The address [person]
    //          that DEPLOYS the contracts is the Owner of the contract. 
    constructor() {
        owner = msg.sender;
    }

    //  This function allows people to CROWD FUND the project we are working on
    //  with a Minimum amount of $50.00 USD dollars.
    function fund() public payable  {

        // Set the Minimum Price to $50.00 USD .. I.E 50 / 126971330000000000000
        // Convert the msg.value to the USD $50.00 equivalent.

        // 18 digit number to be compared with donated amount
        uint256 minimumUSD = 50 * 10**18; // Everything is in Wei so 10**18
        //is the donated amount less than 50USD?
        require(getConversionRate(msg.value) >= minimumUSD, "Not Enough ETH sent!!");

        addressToAmountFunded[msg.sender] += msg.value;
        // What is the ETH --> USD conversion rate ?
        // A blockchain is a deterministic system.
        // Chainlink has data feeds from outside world.
        // https://data.chain.link/ and https://docs.chain.link/
        // https://docs.chain.link/resources/link-token-contracts 
        // https://docs.chain.link/data-feeds/price-feeds

        //Store the Address of accounts who have sent ETH.
        funders.push(msg.sender);


        
        }
    
    // Working with the Interface is the same as working with a Struct or variable 
    // Define 
    //      type
    //      visibility 
    //      name

    function getVersion() public view returns (uint256) {

        // Had to check on the Constructor to see the input arguments to the Interface.
        // The constructor is located in PriceConsumerV3.sol. This is the address of the Contract
        // on the Goerli Testnet. https://docs.chain.link/data-feeds/price-feeds/addresses

        //  Type              visibility    name 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        return priceFeed.version();

        // (
        //     ,
        //     /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
        //     ,
        //     ,

        // ) = priceFeed.latestRoundData();
        // return uint256(price);

    }


    function getPrice() public view returns (uint256) {

        // Had to check on the Constructor to see the input arguments to the Interface.
        // The constructor is located in PriceConsumerV3.sol. This is the address of the Contract
        // on the Goerli Testnet. https://docs.chain.link/data-feeds/price-feeds/addresses

        //  Type              visibility    name 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        // Function latestRoundData() returns a Tuple, but we only need 1 value the price.
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000); // This will return 18 Decimal Places. Orig was 8 decimals.
        // 1269.71330000000000000 on 11-30-22 Price of ETH in USD 
        // 1276.35000000000000000 on 12-02-22 Price of ETH in USD

    }


    // This function will take an ETH amount and get the USD equivalent. 

    // Convert the input GWEI to USD Price. Use 1 Gwei = 1000000000 Wei  = 0.000000001 ETH
    //      Input: Wei of 1000000000 https://eth-converter.com/
    //      1) Get the current Price of ETH in USD [getPrice()]
 
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        //Note: Both ethPrice and ethAmount have an addtional 10**18 decimals 
        uint256 ethAmountInUsd = (ethPrice * ethAmount) /   1000000000000000000; // 18 zeroes
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
        // .00000126971330000 this is 1 Gwei in USD 
        // 5713709850000000000
    }

    //  modifier: https://medium.com/coinmonks/solidity-tutorial-all-about-modifiers-a86cf81c14cb
    //  When to use a modifier in Solidity?
    //  The main use case of modifiers is for automatically checking a condition, prior to executing a function.
    //  If the function does not meet the modifier requirement, an exception is thrown, and the function 
    //  execution stops.

    modifier onlyOwner() {
        //is the message sender owner of the contract?
        require(msg.sender == owner, "Only the owner of the Contract can withdraw funds");

        _;
    }

    function withdraw() public payable onlyOwner {

        //  [msg.sender.transfer] .. send ETH from one address to another.
        //  [address(this).balance] .. [(this) keyword in Solidity] is the current contract we are working in.
        //  We are sending the ETH to [msg.sender]. 
        //  So whoever called the withdraw function, transfer them [msg.sender] , all of the contracts ETH 
        //  I.E. transfer all of this contracts ETH to the msg.sender [caller of the withdraw] method.
        // msg.sender.transfer(address(this).balance);
        
        payable(msg.sender).transfer(address(this).balance); // 11-17-22 Had to cast to [payable] for version 8.17

        
        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //funders array will be rest to 0
        funders = new address[](0);
    }

    }