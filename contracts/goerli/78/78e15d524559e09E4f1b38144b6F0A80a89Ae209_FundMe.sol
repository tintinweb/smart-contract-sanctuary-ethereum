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

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// Transactions - Value Transfer
// Nonce: tx count for the account
// Gas price: price per unit of gas (in wei)
// Gas Limit: max gas that this tx can users
// To: address the tx is sent to
// Value: amount of wei to send
// Data: what to sned to the To address
// v, r, s: components of tx signature

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// 837285 before constant MINIMUM_USD
// 817755 after constant MINIMUM_USD

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 50 * 1e18;

  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable i_owner; // variable set only once but not on the same line as initialisation can be set as immutable

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    // constructors are functions that get called immediately after deploying the contract
    i_owner = msg.sender; // sender of constructor is the address that deployed the contract
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    // Want to be able to set a minimum fund amount in USD
    // 1. How do we send ETH to this contract?

    // require(boolean, revert message)
    // Reverting undoes any previous action, send remaining gas back
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Didn't send enough!"
    ); // 1e18 wei = 1ETH
    funders.push(msg.sender); // add funder address to funders list
    addressToAmountFunded[msg.sender] = msg.value; // add funder address to mapping to amount funded
  }

  function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex]; // get address for each funder on the list
      addressToAmountFunded[funder] = 0; // reset amount funded to zero
    }

    // Reset the array
    funders = new address[](0); // (0) means 0 objects upon declaration

    // Three methods to withdraw funds:
    // transfer
    // Need to typecast address to 'payable address' type
    // payable(msg.sender).transfer(address(this).balance); // 'this' refers to this entire contract
    // // send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed"); // will revert transaction if fails
    // call
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }

  modifier onlyOwner() {
    // can add modifiers to functions
    // require(msg.sender == i_owner, "Sender is not owner"); // check the withdrawer is the owner of the contract

    // alternative, declare custom errors
    if (msg.sender != i_owner) {
      revert NotOwner();
    }

    _; // underscore represents the code of the function being modified
  }

  // What happens if someone sends this contract ETH without calling the fund function?

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// libraries can't have any state variables or send ether
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // import ABI from github

library PriceConverter {
  function getPrice(
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price * 1e10);
    // uint256 addDecimals = 18 - priceFeed.decimals();
    // return price * (10 ** addDecimals);
  }

  function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    uint ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
    return ethAmountInUsd;
  }
}