// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; //constant variable are conventionally typed in CAPS\
    // constant and immutable are variable that we set 1 time, helps in gas optimization

    address[] public funders;
    mapping(address => uint256) public addressToAmoundFunded;

    address public /*immutable*/ owner; //uses prefix of i_before owner everywhere in SC   

    AggregatorV3Interface public priceFeed; // saving AggregatorV3Interface as a global variable

    constructor(address priceFeedAddress) {
        //we are adding parametres to this constructor function 
        // the parametre address is for the pricefeed, which we are gonna pass it
        // an address depending upon which chain we are on i.e., 4 for rinkeby

        // now that constructor has a parameter for the priceFeed, we can actually save an aggregator v3interface object
        // as a global variable
        // it is a function gets immediately called in the same transaction in which contract is created
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress); //now we have priceFeed address thats variable and modularized
    }

    function fund() public payable {
        //want to be able to set a minimum fund amount in USD
        //msg.value.getConversionRate();
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, // when we call the function,we should give it the priceFeed 
            
            //getConversionRate automatically gets passed the msg.value although it already is passed by ethAmout variable
            //because library functions gets pass this msg.value as the first priority
            "Didnt send enough!"
        ); //1e18 = 1x10 ^18
        //=1000000000000000000
        funders.push(msg.sender);
        addressToAmoundFunded[msg.sender] = msg.value;
    }

    //withdraw function

    //for loop is a loop to loop through some
    // index object/some range of numbers/task
    // a certain amount of times repeating
    function withdraw() public onlyOwner {
        /*starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            //for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++)
            //the last piece funderIndex mean that funderIndex itself and +1
            //0,10,1 => then range is 0,1,2,3...10 // 0,10,2 then range is 0,2,4,6,8,10
            address funder = funders[funderIndex];
            addressToAmoundFunded[funder] = 0;
        }
        //reset the array
        funders = new address[](0);
        //withdrawing can be done by three different ways: 1. transfer,
        //   payable(msg.sender).transfer(address(this).balance);// capped at 2300 gas, returns an error if failed
        //2. send,
        //  bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //  require(sendSuccess, "Send failed"); // also capped at 2300, doesnt revert when failed unless you
        // add bool and require method
        //3.call- very powerful as it doesnt require to have the ABI and still works
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //call function returns 2 variable: bytes object dataReturned and bool, bytes objects are arrays
        // we dont need bytes object data Returned
        require(callSuccess, "Call Failed"); // call is the recommended method for sending blockchain token
        revert();
        //msg.sender = address
        //payable(msg.sender) = payable address
        //in solidity, in order to send the native blockchain token like ETH, you can only work
        //with payable addresses
    }

    modifier onlyOwner() {
        //require(msg.sender ==i_owner, "Sender is not owner"); // == check if the two variables are equal
        if (msg.sender != owner) {
            revert NotOwner();
        } // gas efficient
        _; // this _ is telling the code to read the rest of your part after you the above modifier,
        // if "_" was placed above require function, it would mean to read your code first then read whats in the
        //modifier
    }
}

// PriceConversion is gonna be a library that we are going to attach to a uint256
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // in order to run function getPrice we need 1. ABI, 2. Address
        // Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface( //priceFeed variable of type AggregatorV3Interface
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // THe price it returns are ETH in terms of USD and in the format xxxx.xxxxxxxx
        // solidity doesnt support decimals
        return uint256(price * 1e10); // 1x10 = 10000000000
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed //ethAmount and Agg.V3Interface are two parametres for the function getConversionRate
    )
        internal
        view
        returns (
            // when we declare a function, we have to give the whole thing thats why Agg..V3Interface priceFeed is given here
            uint256
        )
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountinUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountinUsd;
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