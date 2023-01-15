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
pragma solidity ^0.8.7;

// Get Funds from Users
// Withdraw Funds
// Set a minimum funding value in USD

import "./PriceConverter.sol";

// 838,793
// 819,070
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 10 * 1e18; // 1 * 10 ** 18
    // 21,393 gas - constant
    // 23,515 gas - non-constant

    error NotOwner();

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunder;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // i_owner = whoever deploys the contract;

        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD.
        // 1. How do we send ETH to this contract
        // msg.value.getConversionRate();
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 = 1 * 10 ** 18 = 10000000000000000
        funders.push(msg.sender);
        addressToAmountFunder[msg.sender] = msg.value;
        // What is reverting? -> transaction undone!
        // undo any action b4 and send the remaining gas
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == i_owner, "Sender is not i_owner!");
        /* uint256 fundersLength = funders.length;
        for (uint256 i = 0; i < fundersLength; i++) {
            address funder = funders[i];
            addressToAmountFunder[funder] = 0;
        } */
        // reset the array
        funders = new address[](0);
        // actually withdraw the funds

        // transfer, send, call

        // msg.sender = address;
        // payable(msg.sender) = payable address;

        payable(msg.sender).transfer(address(this).balance); // transfer

        bool sendSuccess = payable(msg.sender).send(address(this).balance); //send
        require(sendSuccess, "Send Failed!");

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not i_owner!");
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    // What happens if someone sends this contract ETH without calling the fund func

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    // fallback()
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address - 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        //  2000.0000000000
        return uint256(price * 1e10); // 1**10 = 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}