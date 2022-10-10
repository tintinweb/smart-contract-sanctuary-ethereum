// SPDX-License-Identifier: MIT
// pragma
pragma solidity ^0.8.8;

// imports
import "./PriceConverter.sol";

// error codes
error FundMe__NotOwner();

// Interfacesm Libraries, Contracts

/**
 * @title FundMe A contract for crowdfunding
 * @author Henry and Aramidia Team
 * @notice This contract is demo of a crowdfunding contract
 * @dev this implements price feeds as our library
 */
contract FundMe {
  // Type declarations
  using PriceConverter for uint256;

  // State Variables
  uint256 public minimumUsd = 50 * 1e18;
  address[] public funders;
  mapping(address => uint256) public addressToAmmountFunded;
  address public immutable owner;

  AggregatorV3Interface public priceFeed;

  // modifiers
  modifier onlyOwner() {
    if (msg.sender == msg.sender) revert FundMe__NotOwner();
    _;
  }

  /**
   * Functionss Order
   * Constructor
   * receive
   * fallback
   * external
   * public
   * internal
   * private
   * view / pure
   */

  // functions
  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  /**
   * @notice This functionfunds the contract
   * @dev this implements price feeds as our library
   */
  function fund() public payable {
    // Want to be able to set a minimum fund ammount in USD
    // 1. How do we send ETH to this contact?

    require(
      msg.value.getConversionRate(priceFeed) >= minimumUsd,
      "Didn't send enough!!"
    ); // 1e18 = 1 * 10 ** 18 == 1000000000000000000;
    //18 decimals
    funders.push(msg.sender);
    addressToAmmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmmountFunded[funder] = 0;
    }

    // reset array
    funders = new address[](0);

    // call (forward all gas or set gas, returns bool)
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call Failed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // ABI
    // Address of the contact 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    (, int256 price, , , ) = priceFeed.latestRoundData();

    // ETH in terms of USD
    return uint256(price * 10000000000); // 1**10 == 1000000000
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountUsd = (ethPrice * ethAmount) / 1000000000000000000;

    return ethAmountUsd;
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