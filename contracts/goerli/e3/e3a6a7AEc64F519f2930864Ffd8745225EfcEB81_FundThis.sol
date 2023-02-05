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

// get funds from blch users
// set a min funding value in usd
// keep funder addresses and fund amounts
// withdraw funds

// v3 with gas efficiency techniques, receive and fallback additions

// SPDX-License-Identifier: Blank

pragma solidity 0.8.7;

import "./PriceConverterLib.sol";

error NotDeployer();

contract FundThis {
     // PriceConvertLib usage for uint256
     using PriceConverterLib for uint256;

     // constants are better for gas efficiency
     uint256 public constant MIN_USD = 1 * 1e18;

     address[] public funders;
     mapping(address => uint256) public addressToAmountFunded;

     // immutables are better for gas efficiency
     address immutable i_deployer;

     AggregatorV3Interface public priceFeed;

     // called when the contract is deployed
     constructor(address priceFeedAddress) {
          i_deployer = msg.sender;
          priceFeed = AggregatorV3Interface(priceFeedAddress);
     }

     function fund() public payable {
          // set min funding value with require keyword
          // if require condition is not met, the ops before are undone and gas remaining is sent back
          // msg.value : how much money is added to be sent
          require(
               msg.value.getConverted(priceFeed) >= MIN_USD,
               "min $1 is needed"
          ); // 1e18 = 1 * 10 * 10**18 wei = 1 ETH
          funders.push(msg.sender);
          addressToAmountFunded[msg.sender] += msg.value;
     }

     function withdraw() public onlyDeployer {
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
               funderIndex < funders.length;
               funderIndex++
          ) {
               addressToAmountFunded[funders[funderIndex]] = 0;
          }

          // reset the funders array
          funders = new address[](0);
     }

     modifier onlyDeployer() {
          // require(msg.sender == i_deployer, "Sender must be contract deployer.");
          // gas efficient way for errors
          if (msg.sender != i_deployer) revert NotDeployer();
          _;
     }

     receive() external payable {
          fund();
     }

     fallback() external payable {
          fund();
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