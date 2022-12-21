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

// This program will help us learn how to:
// Get Funds
// Withdraw funds
// Set a minimum fundong value in usd on a smart contract.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // Setting minimum usd

    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    address[] public funders;
    mapping(address => uint256) public senderAddressToAmountSent;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // whatever is inside here takes precedence over every other part of the contract
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    // You must tag the function as payable when you want to use it to send eth
    // Contracts can hold funds just like wallets
    function fund() public payable {
        // The require call is basically an if else statment
        // If the require is not met, then the entire fucntion will be undone and whatever gas remaining after the require will be returned.
        // msg.sender and msg.value are universally accessible functions.

        // msg.value.getConversionRate == getConversionRate(msg.value)
        // This works because any function called on an object has that object as its first variable
        // if the function needs more than one variable input, then teh first input will be the method and every other input will be in the brackets.
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Not enough"
        ); // value is in terms of ether, so it has to be converted to usd.
        funders.push(msg.sender);
        senderAddressToAmountSent[msg.sender] += msg.value;
    }

    // withdraw function
    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "You're not the owner. Go away.");
        // for loop: Parameters - starting index; checking index; step amount.
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            senderAddressToAmountSent[funder] = 0;
        }
        // reset the array
        funders = new address[](0); // This means that funders is a brand new address array with 0 objects in it.
        // actually withdrawing the funds

        /* 
        // Transfer method.
        payable(msg.address).transfer(address(this).balance); // basically; transfer the balance of this contracts's address to this msg.sender
        // Send method.
        bool sendSuccess = payable(msg.sender).transfer(address(this).balance);
        require(sendSuccess, "Send Failed"); // this reverts teh tanscation is the sending fails.
        // Call method.
        */

        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call Failed"); // The call method - unlike the other two - does not have a gas limit.
    }

    // solidity modifiers

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "You're not the owner.");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // this underscore represents the original function code.
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        /** This contract needs to interact with another contract outside this one. so we need two things.
         * ABI
         * Address 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 (Go to Ethereum data feeds and grab the address from there)
         */
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // 1 ETH in terms of USD
        // Remember there are eight decimal places behind the value
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethtodollarPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethtodollarPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    // the recieve() and fallback() special funtions
    // recieve cannot have any parameters. It must be external and payable
}