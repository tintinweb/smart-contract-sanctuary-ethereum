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
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    uint256 public minimumUsd = 50 * 1e18;

    AggregatorV3Interface public priceFeed;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public owner;

    // Owner of the contract
    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a min fund amount in USD
        // 1. How do we send Eth to this contract?
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "Didn't send enough!"
        );
        // 1e18 == 1 * 10 ** 18 == 1000000000000000000 Wei
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function widhDraw() public onlyOwner {
        // for loop
        // for(starting index, ending index, step amount)
        // Ex (0, 10, 1)
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // Reset array
        funders = new address[](0);
        // Actually withdraw the funds

        // // Transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // Send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require (sendSuccess, "Send Failed");

        // Call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owener!");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address 0x3de1bE9407645533CD0CbeCf88dFE5297E7125e6
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x3de1bE9407645533CD0CbeCf88dFE5297E7125e6
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Eth in USD -> 1308.0000
        return uint256(price * 1e10); // 1 ** 10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // Remember in Solidity 1st (*) then (/)
        return ethAmountInUsd;
    }
}