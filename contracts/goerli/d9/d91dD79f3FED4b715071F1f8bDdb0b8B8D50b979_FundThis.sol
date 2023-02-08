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

// SPDX-License-Identifier: Blank

// pragma
pragma solidity 0.8.7;

//imports
import "./PriceConverterLib.sol";

// error codes
error FundThis__NotDeployer();

// get funds from blch users
// set a min funding value in usd
// keep funder addresses and fund amounts
// withdraw funds

// v3 with gas efficiency techniques, receive and fallback additions

// Interfaces

// Libraries

// Contracts
/// @title A Contract For Funding The Contract
/// @author keenregen_study
/// @notice A simple funding contract for study purposes
/// @dev Price feeds are implemented as library
/// @custom:experimental This is an experimental contract.
contract FundThis {
     // Type Declerations
     // PriceConvertLib usage for uint256
     using PriceConverterLib for uint256;

     // State Vars
     // constants, privates and intertnals are better for gas efficiency
     uint256 public constant MIN_USD = 1 * 1e18;

     address[] private s_funders;
     mapping(address => uint256) private s_addressToAmountFunded;

     // immutables are better for gas efficiency
     address private immutable i_deployer;

     AggregatorV3Interface private s_priceFeed;

     modifier onlyDeployer() {
          // require(msg.sender == i_deployer, "Sender must be contract deployer.");
          // gas efficient way for errors
          if (msg.sender != i_deployer) revert FundThis__NotDeployer();
          _;
     }

     // Functions (const, rec, fallback, external, public, internal, private, view/pure)

     // called when the contract is deployed
     constructor(address priceFeedAddress) {
          i_deployer = msg.sender;
          s_priceFeed = AggregatorV3Interface(priceFeedAddress);
     }

     receive() external payable {
          fund();
     }

     fallback() external payable {
          fund();
     }

     /// @notice function to fund this contract
     /// @dev Price feeds are implemented as library
     function fund() public payable {
          // set min funding value with require keyword
          // if require condition is not met, the ops before are undone and gas remaining is sent back
          // msg.value : how much money is added to be sent
          require(
               msg.value.getConverted(s_priceFeed) >= MIN_USD,
               "min $1 is needed"
          ); // 1e18 = 1 * 10 * 10**18 wei = 1 ETH
          s_funders.push(msg.sender);
          s_addressToAmountFunded[msg.sender] += msg.value;
     }

     function withdraw() public payable onlyDeployer {
          // withdraw the funds (msg.sender should be casted to payable)
          // 1. Method: Transfer (max 2300 gas; if fails reverts the transaction)
          // payable(msg.sender).transfer(address(this).balance);
          // 2. Method: Send (max 2300 gas; if fails returns a bool)
          // bool sendingSuccess = payable(msg.sender).send(address(this).balance);
          // require(sendingSuccess, "Sending failed");
          // 3. Method: Call (forward all gas or set gas, returns bool) (recommended)
          (bool callSuccess /* bytes memory dataReturned */, ) = payable(
               msg.sender
          ).call{value: address(this).balance}("");
          require(callSuccess, "Sending failed");

          // reset the amounts funded
          for (
               uint256 funderIndex = 0;
               funderIndex < s_funders.length;
               funderIndex++
          ) {
               s_addressToAmountFunded[s_funders[funderIndex]] = 0;
          }

          // reset the funders array
          s_funders = new address[](0);
     }

     function gasEfficWithdraw() public payable onlyDeployer {
          address[] memory funders = s_funders;
          // mapping cannot be in memory
          for (
               uint256 funderIndex = 0;
               funderIndex < funders.length;
               funderIndex++
          ) {
               s_addressToAmountFunded[funders[funderIndex]] = 0;
          }
          // reset the funders array
          s_funders = new address[](0);
     }

     function getDeployer() public view returns (address) {
          return i_deployer;
     }

     function getFunder(uint256 index) public view returns (address) {
          return s_funders[index];
     }

     function getAmountFunded(
          address funderAddress
     ) public view returns (uint256) {
          return s_addressToAmountFunded[funderAddress];
     }

     function getPriceFeed() public view returns (AggregatorV3Interface) {
          return s_priceFeed;
     }
}

// Price Converter Library
// Libraries cannot have any state vars nor cannot send ETH

// SPDX-License-Identifier: Blank

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverterLib {
     function getPrice(
          AggregatorV3Interface priceFeed
     ) internal view returns (uint256) {
          // abi
          // a contract address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e  (eth / usd goerli testnet)
          (, int256 price, , , ) = priceFeed.latestRoundData();
          // ETH in usd (8 decimal places, should be 18 dec places as ETH and should be uint256 as ETH)
          return uint256(price) * 1e10;
     }

     function getConverted(
          uint256 ethAmount,
          AggregatorV3Interface priceFeed
     ) internal view returns (uint256) {
          // ETH in USD
          uint256 ethAmountInUsd = (getPrice(priceFeed) * ethAmount) / 1e18;
          return ethAmountInUsd;
     }
}