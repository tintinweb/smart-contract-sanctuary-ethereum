// Get funds from users & withdraw funds
// Set a minimum deposit in USD

/*

Decentralized Oracles:

- blockchains are deterministic so that nodes can reach consensus.
- randomness would mean you cant reach a consensus
- so how do you get random data and/or api calls?
- oracles.
- but if u get that oracle data from a centralized node, whats the point of the smart contract?
- chainlink brings decentralized oracle data from offchain to on chain.

Chainlink data feeds:
- network of nodes gets data from apis/data providers etc.
- the nodes then come ot a consensus and deliver to a contract, which can be called.

Chainlink VRF:
- get verifiably random numbers delivered to your smart contract

Chainlink keepers:
- decentralized event driven computation. if trigger then do this

Chainlink APIs:
- can grab data from anywhere in the world via api. We will learn more about this...

GAS OPTIMIZATIONS

+ constant keyword.
- say you assign a variable at compile and never change it. E.g. minimumUsd in our contract. You can give it the constant keyword and it will take up less storage space.
- constant variable naming convention is ALL CAPS

+ immutable keyword.
- say you assign a variable at compile but don't set it. you only set it once, later in the contract.
- e.g., "owner" variable in our contract, which is declared at compile and assigned in the constructor.
- use immutable.
- convention is setting the variable as "i_varName"

+ custom errors (solidity 0.8.4+)
- declare an error outside of the contract.
- see onlyOwner modifier below for details.

*/

pragma solidity ^0.8.4;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    // if you use a library for some functions (which we are doing with PriceConverter.sol), you can "attach" those functions to specific types.
    // then it sort of acts like a method of a class object in python where you can do .function on a variable of that type.
    // the keyword is "using <LIBRARY> for <TYPE>"
    // e.g. we're using PriceConverter with the line here: require(msg.value.getConversionRate() >= MINIMUMUSD);
    using PriceConverter for uint256;

    uint256 public number;
    uint256 public constant MINIMUMUSD = 50 * 1e18;

    // HARDHAT VERSION ADDITIONS:
    AggregatorV3Interface public priceFeed;

    // Transaction fields:
    // - Every tx will have the following fields:
    // 1) Nonce 2) Gas Price 3) Gas Limit 4) To 5) Value 6) Data 7) v, r, s (components of tx signature).
    // Notice that every tx can have a value in wei. It can also have other value (not in wei) included in data.

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    // gets called upon deployment.
    // we can set the declared "owner" variable to be equal to the address of whoever deployed the contract initially.

    // original/remix version constructor didnt take any parameters.
    // constructor() {
    //     i_owner = msg.sender;
    // }

    // HARDHAT VERSION OF CONSTRUCTOR - for chainlink price feed address to be modular
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // error checking. say you forgot the "payable" below...
    // Step 1. read error code and it might be straightforward (e.g. in this case it will say make it payable)
    // -- spend at least 15-20 minutes on step 1 before trying next steps
    // Step 2. say you tinkered and can't figure it out. Google the error.
    // Step 2.5. for this course only, go to the github repo for this course.
    // Step 3. Ask a question on a forum like stack exchange eth and stack overflow.
    //

    function fund() public payable {
        // PAYABLE keyword is key. Allows someone to send wei with this function.
        // Just like the wallet can hold funds, so too can a contract address.

        // set a minimum fund amount in USD
        // -- remember, every tx will include the field 'value' so msg.value is just allowing us to grab that amount (could be 0 in a lot of cases).
        // -- require will revert if a condition is not met.s

        number = 5;
        // require(msg.value >= 1e18); // 1e18 wei == 1 eth
        // require(msg.value >= minimumUsd);

        // BEFORE using a library we would've done this:
        // require(getConversionRate(msg.value) >= minimumUsd, "didn't send enough!");

        // NOW with using a library we do this:
        // note that the variable that this function is being applied to will serve as the first input into that function
        // // REMIX VERSION:
        // // require(msg.value.getConversionRate() >= MINIMUMUSD);

        // // NEW VERSION FOR HARDHAT. We pass the newly created modular priceFeed object in as second variable (first variable is msg.value).
        require(msg.value.getConversionRate(priceFeed) >= MINIMUMUSD);

        // revert:
        // -- undo any actions from before and send any leftover gas back.
        // -- e.g. in above, number will no longer be stored as 5 if you sent less than 1 eth.

        // msg.sender = address of sender
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // we are going to use a modifier instead of code below, but this would be another way to make sure the owner is only one calling this.
        // make sure that the sender is the owner of the contract i.e. the person who deployed it.
        // require(msg.sender == owner, "sender is not owner");

        // for loop
        // for (starting index, ending index, step amount)
        // option 1: loop thru and reset each variable in the array
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // option 2: reset the array
        funders = new address[](0); // 0 specifies how many elements are in the array to start

        // now need to withdraw the funds
        // three ways: transfer, send, call

        // // transfer
        // // msg.sender (type address) needs to be typecast to payable msg.sender
        // payable(msg.sender).transfer(address(this).balance);

        // issues with transfer: if it fails, it will not return a boolean it will just fail
        // can use .send which will reeturn a boolean.

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call doesnt have capped gas.
        // call is RECOMMENDED WAY TO SEND/RECEIVE.
        // (bool callSuccess, bytes dataReturned) = payable(msg.sender).call{value: address(this).balance}("")
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        // require(msg.sender == i_owner, "Sender is not owner!");
        _; // this represents DO THE REST OF CODE in the function that uses this modifier.
    }

    // what happens if someone sends this contract eth without calling the fund contract?

    // receive & fallback are special functions in solidity.
    // see FallbackExample.sol

    // one purpose of this is if someone accidentally calls the wrong function but still sends eth, this will still work as if they had called fund()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./AggregatorV3Interface.sol";

// REMIX knows how to automatically download below using npm.
// With local code we need to add these manually
// it is much simpler than with brownie. Just do yarn add --dev @chainlink/contracts and then you dont have to touch the code below. Hardfhat will find it in node_modules folder
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// librarys cant maintain state and also cant send ether
// all of the functions are internal.

library PriceConverter {
    // since we want to compare a value to a USD-based minimum, we need to get the price of eth in USD first.
    // ORIGINAL REMIX VERSION DIDNT INCLUDE AggregatorV3Interface as FUNCTION IN getPrice()
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // THE BELOW CODE WAS WITH REMIX VERSION. NOW THAT WE PASS IN AN INTERFACE, NO LONGER NEED TO CREATE IT HERE.
        // // We're interacting with another contract so we need:
        // // 1) Address... we can get from docs: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e (Rinkeby)
        // // 2) ABI... we can use an interface.
        // // --- interfaces DECLARE the functions but doesnt say what they do. That's fine because we just need the names / required inputs / required outputs of the functions.
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        // // (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price, , , ) = priceFeed.latestRoundData(); // int instead of uint so that it can be negative.
        return uint256(price * 1e10); // because the chainlink oracle data is 8 decimals versus wei is 18
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    // Original REMIX VERSION
    // function getConversionRate(uint256 ethAmount)
    // HARDHAT VERSION (incorporates modular priceFeed)
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ORIGINAL REMIX VERSION DIDNT INCLUDE priceFeed AS A VARIABLE IN getPrice()
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
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