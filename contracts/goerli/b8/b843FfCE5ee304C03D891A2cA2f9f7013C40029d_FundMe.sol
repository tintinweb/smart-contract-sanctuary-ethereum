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
// Set a Minimum funding value in USD

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // Minimum funding value in USD
    uint256 public constant MINIMUM_USD = 10 * 1e18; // 1 * 10 ** 18
    // Array of addresses that have sent funds to the contract
    address[] public funders;
    // Mapping of addresses to the amount of funds they have sent to the contract
    mapping(address => uint256) public addressToAmountFunded;
    // The address of the contract owner
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    // Constructor sets the contract owner to the address that deployed the contract
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // Public function that accepts funds (payable)
    function fund() public payable {
        // Check if the value sent is greater than or equal to the MINIMUM_USD constant
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );
        // Add the sender's address to the funders array
        funders.push(msg.sender);
        // Add the amount sent to the addressToAmountFunded mapping
        addressToAmountFunded[msg.sender] = msg.value;
    }

    // Public function that can only be called by the contract owner
    function withdraw() public onlyOwner {
        // Iterate through the funders array
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            // Set the amount the funder has sent to 0 in the addressToAmountFunded mapping
            addressToAmountFunded[funder] = 0;
        }
        // Empty the funders array
        funders = new address[](0);

        // Try to transfer the remaining balance of the contract to the msg.sender
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Modifier that checks if the msg.sender is the contract owner
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // What happen if someone send ETH to this contract without calling the fund() function

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Library to convert ETH to USD
library PriceConverter {
    // Retrieves the latest price of ETH in terms of USD from a specific price feed contract (AggregatorV3Interface)
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Address of the price feed contract
        // Retrieves the latest price data from the price feed contract
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        //3000.00000000 8 Decimals
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    // Converts input ETH amount to USD
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Retrieves the current ETH price in USD
        uint256 ethPrice = getPrice(priceFeed);
        // Calculates the equivalent USD value of the input ETH amount
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }
}