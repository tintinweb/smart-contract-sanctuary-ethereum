// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.0;

// 2. Imports
import "./PriceConverter.sol";

// 3. Error Codes
// A different way to throw errors -> more gas efficient
error FundMe__NotOwner();

// 4. Libraries
// 5. Interfaces

// 6. Contracts
contract FundMe {
    // 6.1. Type Declarations
    // Using a PriceConverter library to extract the math operations from the contract
    using PriceConverter for uint256;

    // 6.2. State Variables
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // "immutable" keyword only allows to update variable once after
    // declaring them (perfect for constructors + saves gas)
    address public immutable i_owner;

    // "constant" keyword prevents variable from being updated + saves gas
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface public priceFeed; // "priceFeed" *CONTRACT*

    // 6.3. Events (none here)

    // 6.4. Modifiers
    modifier onlyOwner() {
        // 0. Ensuring only the address that deployed this contract can withdraw funds
        // Run this code first

        // Few ways to do this:
        // 1. Old school
        // require(msg.sender == i_owner, "Sender is not the owner!");

        // 2. New & more gas efficient
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        // Run the rest of the func
        _;
    }

    // 6.5. Functions
    // 6.5.1 Constructors
    constructor(address priceFeedAddress) {
        // Assigning the owner in the constructor because it only runs once the contract is deployed
        // (aka we already have access to "msg.sender" address)
        i_owner = msg.sender;

        // Making our "priceFeedAddress" dynamic (so it could be used with different addresses)
        // ** By matching ABI ("AggregatorV3Interface") with the contract address ("priceFeedAddress"),
        // ** we get access to the *interface* itself & then are able to interact with it (e.g. get price, etc.)
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // 6.5.2. Receive
    // Triggering "fund()" func if someone sends ETH to this contract
    // without the "fund()" func
    receive() external payable {
        fund();
    }

    // 6.5.3. Fallback
    fallback() external payable {
        fund();
    }

    // 6.5.4. External Funcs

    // 6.5.5. Public Funcs
    function fund() public payable {
        // "1e18" = 1 * 10^18
        // Library functions automatically use the values they're used as
        // methods for as their initial argument
        // e.g. "msg.value" is used as the first argument for "getConversionRate(uint256 ethAmount)"
        // Additional arguments should be added normally e.g. for "getConversionRate (uint256 ethAmount, uint256 smthElse)"
        // We'd use "msg.value.getConversionRate(123)", "123" being "smthElse"
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Not enough eth sent!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // 1. Resetting the amounts funded by each funder to 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // 2. Resetting the array
        funders = new address[](0);

        // 3. Withdraw the funds (to the caller of this contract)

        // ** 3 ways to send funds in EVM: **
        // 1) Transfer
        // "msg.sender" -> address data type | "payable(msg.sender)" -> address payable data type
        // Funds go from msg.sender to the caller of this contract? NO
        // Funds go from "address(this)" to "msg.sender" (who, in this case,
        // I guess is the caller of this contract?)
        // payable(msg.sender).transfer(address(this).balance);

        // 2) Send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // 3) Call - *currently the recommended way to send & receive funds*
        // leaving "call()" blank since we don't want to call this func on any other contract
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // 6.5.6. Internal Funcs (none here)
    // 6.5.7. Private Funcs (none here)
    // 6.5.8. View/Pure Funcs (none here)
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing an interface (& most importantly, its ABI) to interact with it
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Getting price of ETH in USD
    // ** Libraries only get embedded into the contract if the library functions are *internal*
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // To get the ETH price in USD, we should divide "price" by 1e8
        // (since now it is e.g. 160000000000 but should be 1,600.00000000 USD))
        // "msg.value", however should be divided by 1e18 to get the price in ETH
        // since it's currently expressed in wei (x ETH * 1e18)
        // Hence, we're multiplying "price" by 1e10 to match "msg.value" format

        // Also changing price data type from "int256" to "uint256" -> not sure why
        return uint256(price * 1e10);
    }

    // ** Libraries only get embedded into the contract if the library functions are *internal*
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);

        // If we multiplied "ethPrice" & "ethAmount" without dividing it by 1e18,
        // we would've received 36 0's in the result.
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