// Get funds from user.
// Withdraw funds - only owner can do it.
// Set a minimum funding value in USD using chainLink Oracle

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./PriceConverter.sol";

// Custom Errors - Gas Efficient
error NotOwner();

contract FundMe {
    // SmartContract can hold funds just like how wallets can!
    // In order to make a func to transact - we need to add "payable".
    // To know how many Gwei, wei, ethers the users actually transacting - use "msg.value".
    
    // Require - like if-else check - condition with else part.
    // 1e18 == 1 * 10 ** 18 = 1 Ether. 
    // If the condition is false, then it actually takes the lot of gas for computation, but it sends back the remaining gas!
    
    // Getting Info from library!
    using PriceConverter for uint256;

    // constants are variables that cannot be modified and their value is hardcoded & using constant can save gas costs!
    // "21,415 gas" - constant & "23,515 gas" - non-constant 
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    
    // 50/1,552.79(Eth value in usd) in wei must be the input!
    // msg.sender - address of whoever call this function.
    // While calling a library function, we need not to give parameters in (), we can directly give it by dot operator, if it is only one parameter!
    // If there 2 or more parameter, we should give next parameter onto the bracket
    function fund() public payable{
        require(msg.value.getConversionRate(s_priceFeed ) >= MINIMUM_USD, "Need atleast 1 ether!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    // A constructor code is executed once when a contract is created.
    // Immutable - like constants,  Values of immutable variables can be set inside the constructor but cannot be modified afterwards. 
    // "21,508 gas" - immutable && "23,644" - non-Immutable
    address public immutable i_owner;

   AggregatorV3Interface private s_priceFeed; // variable

    constructor(address priceFeed) {
       i_owner = msg.sender;
       s_priceFeed  = AggregatorV3Interface(priceFeed);
    }
    
    // Only owner of this contract can withdraw all these funds!
    // Modifier, is like middleware, used to check/call to its own function, when called in an another function! 
    modifier onlyOwner {
        //require(msg.sender == i_owner, "Only owner can withdraw the funds!");
        if(msg.sender != i_owner) { revert NotOwner(); }
       _; // Move ahead with other set of code!
    }

    // for(startingIndex, endingIndex, stepAmount)
    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; // withdrawel resets the funders addres - fund to zero
        }

        // Resetting the array - to zero.
        funders = new address[](0);

        // Actually withdrawing the funds - transffering back the ether to fund depositor.
        // 1) transfer => msg.sender = address => payable(msg.sender) = payable address => capable only of (2300 gas, throws error)
        // payable(msg.sender).transfer(address(this).balance);

        // 2) send => capable only of (2300 gas, returns bool)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failure");
        
        // ** Recommended **
        // 3) call => capable of (forwarding all gas or set gas, returns bool) => call("") => calls a func, but here we need not to call any function!
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}


// For Gas Optimization:
// 1) use Constants and Immutables
// 2) Use custom error rather than using require()

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are similar to SM that contains reusable codes, 
// It has functions that can be called by other contracts, Deploying a common code by creating a library reduces the gas cost
// It can't have state variables and can't send (or) hold ether unlike contract.
// All function are internal.

library PriceConverter {
    // Getting ETH/USD price using chainlink oracle. 
    // "As we interacting with other contract to get the price we need Address of that Price feeder contract along with its ABI"(We get it by imporing the chainlink priceFeed interface).
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeed);
        ( ,int256 price,,, ) = priceFeed.latestRoundData(); // Price of Eth in terms of USD.
        return uint256(price * 1e10); 
    }
    
    // Getting Eth price in terms of USD.
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
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