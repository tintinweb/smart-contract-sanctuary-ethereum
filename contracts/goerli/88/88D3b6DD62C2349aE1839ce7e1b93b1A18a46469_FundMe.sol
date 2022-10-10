// Get funds from users
// Withdraw funds
// Set a minimum funding in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    // constant and immutable helsp to bring down gas prices.

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // with constant: 21415, without constant:23515

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    // Wallets and Smart Contracts can hold native blockchain tokens like Ethereum

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // payable allows a function to send funds
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        // require(msg.value >= minimumUSD, "Didn't send enough."); // 1e18 = 1 and 18 0s = 1000000000000000000
        // msg.value.getConversionRate();
        // require(getConversionRate(msg.value) >= minimumUSD, "Didn't send enough.");
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough."
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;

        // What is reverting?
        // undo any action before, and send remaining gas back
        // reverts are really useful to save gas incase of a computation error because anything before the require
        // statement will be reverted back
    }

    // function getPrice() public view returns(uint256) {
    //     // ABI of the contract and the Address of the contract
    //     // contract address for Goreli TestNet 0xA39434A63A52E749F02807ae27335515BA4b07F7
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
    //     // (uint roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
    //     (,int256 price,,,) = priceFeed.latestRoundData();
    //     // ETH in terms of USD is returned here.
    //     // 3000.00000000 There are 8 decimal places associated with this account.
    //     return uint256(price * 1e10); // 1e10 = 10000000000
    // }

    // function getConversionRate(uint256 ethAmount) public view returns(uint256) {
    //     uint256 ethPrice = getPrice();
    //     uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18; // In Solidity always Multiply and then Divide.
    //     return ethAmountInUSD;
    // }

    function Withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not owner!");
        /* strating index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
            // addressToAmountFunded[funders[funderIndex]] = 0;
        }

        // reset the funders array
        funders = new address[](0);
        // actually withdraw the funds
        // 3 different ways: transfer, send, call

        // transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this). balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed"); // only revert if we add this statement here.

        // call
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        // revert(); can be used anywhere in a function to revert a transaction or a function call.
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        } // Gas efficient way.
        _; // means doing the rest of the code where this modifier is used. Position of this matters as
        // it determines what the order of the function will be.
    }

    // What happens when someone send this contract ETH without calling the fund function?

    // receive
    receive() external payable {
        fund();
    }

    // fallback
    fallback() external payable {
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
        // ABI of the contract and the Address of the contract
        // contract address for Goreli TestNet 0xA39434A63A52E749F02807ae27335515BA4b07F7
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xA39434A63A52E749F02807ae27335515BA4b07F7
        // );
        // (uint roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD is returned here.
        // 3000.00000000 There are 8 decimal places associated with this account.
        return uint256(price * 1e10); // 1e10 = 10000000000
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xA39434A63A52E749F02807ae27335515BA4b07F7
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18; // In Solidity always Multiply and then Divide.
        return ethAmountInUSD;
    }
}

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