// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // constant - immutable : mean the vriable not changing more than 1 time.
    // and will save some gass

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // 21,393 gas : constant
    // 23,493 gas : non-constant

    address[] public funders;
    mapping(address => uint256) public addressToAmountFounder;

    address public immutable i_owner;

    // 21,486 gas : immutable
    // 23,622 gas : non-immutable

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    function fund() public payable {
        // we want to able to set a minimum fund amount in usd
        require(
            msg.value.getCoversionRate(priceFeed) >= MINIMUM_USD,
            "Didnt send enough!"
        ); // 1e18 = 1* 10 ** 18 = 1000000000000000000
        // masg.value have 18 decimals
        funders.push(msg.sender);
        addressToAmountFounder[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        require(msg.sender == i_owner, "Sender is not owner!");
        // for-loop
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFounder[funder] = 0;
        }

        // reset the array
        funders = new address[](0);

        //actually withdraw the fund

        //transfer
        //msg.sender = address
        //payable(msg.sender) = payable address
        /* payable(msg.sender).transfer(address(this).balance); */

        //send
        /* bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed"); */

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // what happen when someone send this contract ETH without calling fund function ?
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License_Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address  0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface pricefeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of usd
        // 3000,00000000 have 8 decimals
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getCoversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
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