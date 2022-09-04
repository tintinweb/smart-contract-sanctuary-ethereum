// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD
// Solidity works badly with decimals

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// Custom error for less gas cost
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunding;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // msg.sender of the constructor is whomever is deploying the contract
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough."); // Minimum value to send has to be greater than 1 ETH
        // 18 decimals
        // msg.value.getConversionRate() same as getConversionRate(msg.value)
        require(
            // msg.value is the first parameter going into getConverionRate, so priceFeed would be the second one
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough."
        );
        funders.push(msg.sender);
        addressToAmountFunding[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not the owner."); -> But what if we have a lot of
        // functions with this requiring? -> We create a modifier

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunding[funder] = 0;
        }

        // Reset the array of funders
        funders = new address[](0);

        //Withdraw the funds - See diferences in the video - 4:49:44

        // // TRANSFER
        // payable(msg.sender).transfer(address(this).balance);
        // // msg.sender type is address
        // // payable(msg.sender) type is payable address -> To send a native token like
        // // ETH you need to do it into a payable address

        // // SEND
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed.")

        // CALL
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("")
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Create a modifier -> A key word that we can add in the function declaration to modify
    // it's functionality

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner."); // Do this first
        // _; // _ means doing the rest of the code ( inside the function )
        // ...; this code would be executed after the function

        // Less gas cost by using custom errors
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
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

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
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
        // (uint80 roundId, int price, uint startedAt, uint timeStamps, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD - 8 decimals

        return uint256(price * 1e10); // 18 decimals
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // uint256 ethAmountInUsd = (ethPrice * ethAmount); --> IT HAS 36 DECIMALS
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // --> 18 decimals

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