// Get funds from users
// Withdraw funds
// Set a minumum funding value in USD

// SPDX-License-Identifier: BSD2
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough"); // 10^18
        // NOTE: failing above requirement revert the functions performed so far. Gas is still spent for them.

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //require(msg.sender == i_owner, "Sender is not i_owner");

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1) {
            address funder = funders[funderIndex];

            addressToAmountFunded[funder] = 0;
        }

        // reset the funders array
        funders = new address[](0);

        // actually withdraw the funds

        /*
        // Method 1: transfer
        //
        // NOTE:
        // `msg.sender` has type of `address`
        // `payable(msg.sender)` has type of `payable address`
        // Only payable addresses can transfer blockchain token
        payable(msg.sender).transfer(address(this).balance);
        // Tranfer will automatically revert from here on failure

        // Method 2: send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // check status and manually revert.
        require(sendSuccess, "Send failed");
        */

        // Method 2: call
        (bool callSuccess, /*bytes memory  dataReturned*/) = payable(msg.sender).call{ value: address(this).balance }("");
        // check status and manually revert.
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not owner");

        if(msg.sender == i_owner) {
            revert NotOwner();
        }
        _; // run rest of the modified function
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: BSD2
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        ( //uint80 roundId
        , int256 price
        , //uint startedAt
        , //uint timeStamp
        , //uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return uint256(price * 1e10); // 10^10
   }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface _priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;

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