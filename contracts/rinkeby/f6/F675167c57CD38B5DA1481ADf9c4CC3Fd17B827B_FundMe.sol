// SPDX-License-Identifier: MIT
/* =======Fomratted with Solidity Style Guide **/

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    
    address public /* immutable */ i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    // uint256 public constant MINIMUM_USD = 50 * 1e18; //constant variable are conventionally typed in CAPS\
    // constant and immutable are variable that we set 1 time, helps in gas optimization 

  AggregatorV3Interface public priceFeed;
    constructor(address priceFeedAddress) { // it is a function gets immediately called in the same transaction in which contract is created 
    priceFeed = AggregatorV3Interface(priceFeedAddress);
    i_owner = msg.sender;
  }
  fallback() external payable {
        fund();
  }

  receive() external payable {
        fund();
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

//==========want to be able to set a minimum fund amount in USD============

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!"); //1e18 = 1x10 ^18
    //=1000000000000000000
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
         //  emit Funded(msg.sender, msg.value);
    }
    
    modifier onlyOwner {
      //require(msg.sender ==i_owner, "Sender is not owner"); // == check if the two variables are equal
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;// this _ is telling the code to read the rest of your part after you read the above modifier,
    // if "_" was placed above require function, it would mean to read your code first then read whats in the modifier 
  }
  //WITHDRAW FUNCTION
    
  //for loop is a loop to loop through some
  // index object/some range of numbers/task 
  // a certain amount of times repeating
  function withdraw() payable onlyOwner public {
  /*starting index, ending index, step amount */
  for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
  // for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1 ){   || Also works the same
   //the last piece funderIndex mean that funderIndex itself and +1 
    //0,10,1 => then range is 0,1,2,3...10 // 0,10,2 then range is 0,2,4,6,8,10 
  address funder = funders[funderIndex];
  addressToAmountFunded[funder] = 0;
  }

  //----------RESET THE ARRAY----------

 funders = new address[](0);
  //withdrawing can be done by three different ways: 
  // 1. transfer,  payable(msg.sender).transfer(address(this).balance);// capped at 2300 gas, returns an error if failed
  
  // 2. send
  // bool sendSuccess = payable(msg.sender).send(address(this).balance);
  // require(sendSuccess, "Send failed");
  // also capped at 2300, doesnt revert when failed unless you
  // add bool and require method
  // 3. call
 (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
 require(callSuccess, "Call failed");
  }
 
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

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

// PriceConversion is gonna be a library that we are going to attach to a uint256  
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
    
        (,int price,,,) = priceFeed. latestRoundData();
        // THe price it returns are ETH in terms of USD and in the format xxxx.xxxxxxxx
        // solidity doesnt support decimals
        return uint256(price * 10000000000); // 1x10 = 10000000000
    }
   
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountinUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountinUsd;        
    }  
}