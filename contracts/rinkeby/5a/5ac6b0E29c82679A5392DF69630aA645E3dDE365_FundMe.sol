// Get funds from users
// Withdraw funds
// Set a miminum funding value in USD

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

// constant, immutable

// 779,466
// 759924 gas

contract FundMe {
    using PriceConverter for uint256;

    // uint256 public constant MINIMUM_USD  = 50 * 1e18; // 1 * 10 ** 18
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // constant -  21,415 gas
    // non-constant - 23,515 gas
    // 21,415 * 81000000000 = 1734615000000000 = 0.001734615 ether * 1,358.87 = $ 2.35711628505
    //  23,515 * 81000000000 = 1904715000000000 = 0.001904715 ether * 1,358.87 = $ 2.58826007205

    address[] public funders;

    mapping(address => uint256) public addressToAmountFunded; // 0xa2adEE2b744B90DD9C22b1634cBB9F6A93a89D8d - 36000000000000000 Wei

    // address public immutable i_owner;
    address public immutable i_owner;

    // 21,508 gas - immutable
    // 23,644 gas - non-immutable

    AggregatorV3Interface private s_priceFeed;

    //  We can actually save an aggregator V3 interface object as global variable, being private means this variable can only be accessed from within this contract

    constructor(address priceFeedAddress) {
        // Now that: our constructor takes a parameter for the priceFeedAddress -  a variable of type address
        // i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
        // The interface - an interface object, which gets compiled down to the ABI.
        // If you match an ABI up with an contract address, you get a contract that you can interact with

        //In this case, we can match this Aggregator V3 interface with different price feed contract address on different chain
        //  to get and interact with mock price feed contract on local network;
        //  to get and interact with price feed contract on the different test network
        // and to get and interact with price feed contract on the different main net.
        i_owner = msg.sender;
    }

    // Limit tinkering / triaging to 20 minutes; move on to next step .
    // take at least 15 minutes yourself -> be 100% sure you exhausted all options .

    // 1,  Tinker and try to pinpoint exactly what's going on .
    // 2,  Google the exact error
    // 2.5,  Go to our Github repo discussions and/or updates
    // 3,  Ask a question on Stack Overflow or Stack Exchange Eth

    function fund() public payable {
        // MINIMUM_USD = 7; - cannot assign to a constant variable .
        // i_owner = msg.sender;   - cannot write to immutable here: immutable variables can only be initialized inline or assigned directly in the constructor .

        // 1, How to do we send ETH to this contract
        // 2, Want to be able to set a mimimum fund amount in USD
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more Eth!"
        ); // 1e18 == 1 * 10 ** 18  = 1000000000000000000 wei
        // a ton of computation here
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;

        // what is reverting ?
        // undo any action before, and send remaining gas back
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == i_owner,  "Sender is not owner!");

        // clear the the amountfunded for each funder:

        /*starting index; ending index; step amount */
        /* funderIndex++ equivalent to fundeIndex = funderIndex + 1 */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the funders array to be blank:

        funders = new address[](0);

        // actually withdraw the funds:

        // transfer:    msg.sender - type address ;   payable(msg.sender) - type address payable
        //   payable(msg.sender).transfer(address(this).balance);

        // send
        //   bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //   require(sendSuccess, "Send failed");

        // call
        //  (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        //  revert(); you can actually go ahead to revert any transaction or any function all in the middle of a function all .
    }

    modifier onlyOwner() {
        //    require(msg.sender == i_owner , "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // What happens if someone send this contract ETH without calling fund function
    // receive();
    // fallback();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Which again , we are importing fron Chainlink repo

// Which is an interface object, which gets compiled down to the ABI.
// If you match an ABI up with an contract address, you get a contract that you can interact with

library PriceConverter {
    // In our price converter, we just create a priceFeed variable of type aggregator V3 interface
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI
        //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 1743.00000000
        return uint256(price / 1e8); //  1*10**8
    }

    function getDecimal(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint8)
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        return priceFeed.decimals();
    }

    function getVersion(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = ethAmount * ethPrice;
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