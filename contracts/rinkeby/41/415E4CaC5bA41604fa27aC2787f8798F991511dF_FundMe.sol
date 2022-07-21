// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
// Withdraw Funds
// Set a minimum funding value in USD

// trick to reduce the gas cost in creating contract
// 1. constant
// 2. immutable
// 3. updating require statement by replacing it with error
// 4.
// using on variables that only if we only setting our variables once

// cost in creating the contract: 859,817
// 840269 gas: using constant
// 816786 gas: using constant and immutable

// why immutable and constant can reduce gas cost?
// because instead of storing those variables inside of a storage slot,
// we store it directly into the bytecode of the contract

error NotOwner();

contract FundMe {
    uint256 public constant MNIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    using PriceConverter for uint256;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;
    // setup the owner of the contract
    address public immutable i_owner;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // payable: mark the function can send ETH or whatever native blockchain token
        require(
            msg.value.getConversionRate(priceFeed) >= MNIMUM_USD,
            "didn't send enough eth"
        ); //1e18 = 1 * 10 ** 18 wei
        // what is reverting?
        // revert mean undo any action before, and send remaining gas back
        // requier statement: when you need something in your contract to happen, and you want the whole transaction to fail if that doesn't happen
        // to get the ETH or blockchainnative token value of a transaction, use the msg.value
        funders.push(msg.sender);
        // msg.sender stand for the address call the function
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // way to send eth or asset back to whom calling this function:
        // msg.sender = address
        // payable(msg.sender) = payable address (only payable address can send eth or asset)
        // 1. transfer: auto revert when the transfer fail
        // payable(msg.sender).transfer(address(this).balance);
        // 2. send: can only revert if we add the require statement
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "failed to send");
        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "failed to call");
    }

    // modifier only owner
    // modifier: a keyword that we can add right in the function declaration to
    // modify the function with that functionality

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
        // _; meaning doing the rest of the code
    }

    // What happens if someone sends this contract ETH without calling the fund function?

    // receive()
    receive() external payable {
        fund();
    }

    // fallback()

    fallback() external payable {
        fund();
    }
}

/*
    1. Enums
    2. Events
    3. Try / Catch
    4. Function Selectors
    5. abi.encode / decode
    6. Hashing
    7. Yul / Assembly 

    */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // to interact with other contract outside we need: ABI and Address of the contract
        // Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // ABI

        // hard coded
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); // 1 ** 10
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