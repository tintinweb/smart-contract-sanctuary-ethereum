// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    // function that gets called immediately when a contract gets deployed
    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // the owners (caller) wallet address
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // Contracts can hold funds since they get deployed with a ETH address using the keyword "payable"
    function fund() public payable {
        // Want to be able to set a minimum fund aboutn in USD.

        // value is in ETH or some derivative of ETH like wei / gwei
        // require is a conditional statement,
        // if it fails the contract returns the remaining gas fees to the calling contract.
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to send more ETH"
        ); // 1e18 == 1 * 10 ** 18 = 1000000000000000000 = 1 ETH

        // sender like value is a global always available keyword. sender = address of whoever calls the fund function.
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    // the onlyOwner modifier gets executed first before the withdraw function
    function withdraw() public onlyOwner {
        // remove the mapping amount for all addresses
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the funders address array
        funders = new address[](0);

        // msg.sender = address
        // payable(msg.sender) = payable address
        // with transfer, if it fails it reverts the transaction and throws an error
        // payable(msg.sender).transfer(address(this).balance); // "this" refers to the entire contract

        // send won't error but gives a boolean of whether or not it was successful
        // you need to accompany it with a require to throw an error message
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        // another way to check is the below if statement which is more gas efficient
        if (msg.sender != i_owner) {
            revert NotOwner();
        }

        _; // do the rest of the code. a place holder for the unmodified code
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // ETH price in USD
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}