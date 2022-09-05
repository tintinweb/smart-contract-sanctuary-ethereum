// Get fund for users
//Withdraw funds
//Set minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceConverter.sol";
//to show errors within the contracts
error FundMe_NotOwner();

/** @title A contract for crowd funding
 * @author Partrick Colllins
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
  //Type declarations
  using PriceConverter for uint256;

  //State variables
  uint256 public constant MINIMUM_USD = 50 * 1e18;
  //store addresses of wallet funding our contract in the array
  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  // constant and immutable are use to optimize gas in contract when the variable are called once in a contract.
  address public immutable i_owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    require(
      msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
      "Didn't send enough!"
    );
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    funders = new address[](0);

    //actually withdraw the funds

    //transfer

    //msg.sender = address
    //msg.sender = payable address
    payable(msg.sender).transfer(address(this).balance);
    /*//send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send Failure");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance("")};
        require (callSuccess, "Call failed");
        */
  }

  modifier onlyOwner() {
    //require(msg.sender == i_owner, "Sender is not Owner!");
    _;
    if (msg.sender != i_owner) {
      revert FundMe_NotOwner();
    }
  }

  // how our transcation can be registered on the funders function without using the fund function
  // and it doesn't need a function keyword.
  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  // Concepts we didn't cover yet (will cover in later sections)
  // 1. Enum
  // 2. Events
  // 3. Try / Catch
  // 4. Function Selector
  // 5. abi.encode / decode
  // 6. Hash with keccak256
  // 7. Yul / Assembly
}

//STYLES TO WRITE OUR SOLIDITY CODES
//Pragma
//Imports
//Error codes
//Interfaces, Libraries, Contracts

//Inside each contract, library or interface, use the following order:
//Type declarations
//State variables
//Events
//Modifiers
//Functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    //ABI
    //ADDRESS
    /* AggregatorV3Interface priceFeed = AggregatorV3Interface(
      0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    ); */
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price * 1e18);
  }

  /*   function getVersion() internal view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(
      0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    );
    return priceFeed.version();
  } */

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
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

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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