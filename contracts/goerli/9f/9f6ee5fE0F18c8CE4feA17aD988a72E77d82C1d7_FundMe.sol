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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Importing library
import "./PriceConverter.sol";

// Creating a costum error
error NotOwner();

contract FundMe {
    // Specify the usage for PriceConverter | library --> uint256
    using PriceConverter for uint256;
    // Who deploy the contract
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    // A function that runs whenever the contract gets deployed
    // Parameterize priceFeedAddress
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    uint256 public constant MINIMUM_USD = 10 * 1e18;
    // Funders dynamic list
    address[] public funders;
    // Associate address and funds
    mapping(address => uint256) public AddressToAmountFunds;

    function fund() public payable {
        // Gets funds from users
        // Set a minimum funding value in USD
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Send at least 10$!"
        );
        // Add sender's address
        funders.push(msg.sender);
        // Adding funds to actually sender
        AddressToAmountFunds[msg.sender] += msg.value;
    }

    function withdraw() public OnlyOwner {
        // Reset all addresses funds with a for loop
        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            AddressToAmountFunds[funder] = 0;
        }

        // Reset funders array
        funders = new address[](0);

        // Withdraw
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
        // Call returns two things, we have no interest in data in this case. Leave a comma.
    }

    // Modifier to add permission at contract's owner
    modifier OnlyOwner() {
        // This is an example of custom error to save gas
        if (i_owner != msg.sender) {
            revert NotOwner();
        }
        _; // All the function code will execute after the require
    }

    // Receive external payments
    receive() external payable {
        fund();
    }

    // Calls a function that doesn't exist
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Importing from GitHub Chainlink interface(abi) (chainlink/contracts package)
// Matched with address gives you the ability to interact with contract
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Get price of ETH in USD
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // 1000.00000000

        // Moltiplicating to get the same decimals number
        // Decimals must be equal msg.value has 18 decimals, price 8 decimals
        return uint256(price * 1e10);
        // Converting the same type of msg.value --> uint256(int number)
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Convert msg.value from ETH in USD
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 = ETH / USD price
        // 1_000000000000000000 ETH

        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}