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
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// constant, immuteable to reduce gas for one time function that is used once

// 837285 gas non-constant
// 817743 gas constant
// 794260 gas constant MINIMUM_USD & immutable owner

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    // 23515 gas non constant
    // 21415 gas constant
    // 21508 gas constant MINIMUM_USD & immutable owner

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // Limit tinkering / triaging to 20 minutes
    // at least 15 minutes yourself -> or be 100% sure you have exhausted all options

    // steps:
    // 1. Tinker and try to pinpoint exactly what's going on
    // 2. Google the exact error
    // 2.5. Go to our Github repo discussion and/or updates
    // 3. Ask a question on a forum like Stack Exchange ETH and Stack Overflow

    function fund() public payable {
        // getConversionRate(msg.value);
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send eth to this contract?
        // 'payable' --> Red button instead of Orange
        // Contract address can hold fund too, just like wallet
        // msg.value is one of the global keyswords in solidity

        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Please send more!"
        ); //1e18 = 1 x 10^18 = 1,000,000,000,000,000,000 wei = 1 ETH)

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        // msg.value has 18 decimal places (wei)
        // what is reverting?
        // undo any action before, and send remaining gas back
    }

    function withdraw() public onlyOwner {
        /* starting index, ending index, step ammount */
        // "/* */" brackets for comment
        // for loop
        // [a, b, c, d]
        //  0. 1. 2. 3.
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);
        // actually withdraw the funds

        // 3 different send eth/native token:
        // transfer - simplest [2300 gas, throws error]
        // send [2300 gas, returns bool]
        // call [forward all gas, returns bool]

        // msg.sender = address
        // payable(msg.sender) = payable address
        // to send native blockchain token like ETH, only work with payble address

        // transfer:
        // payable(msg.sender).transfer(address(this).balance);

        // send:
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!")

        // call:
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "sender is not owner!");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
        // = setting parameter
        // == checking if msg.sender = owner
    }

    // sending eth to contact without calling the fund fuction

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI (Application Binary Interface) & Address of contract for external data are needed
        // ABI (although there technically is another way to interact with contract w/o ABI)

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD = $1260
        // uint80 roundId / int price / uint startedAt / uint timeStamp / uint80 answeredInRound
        return uint256(price * 1e10);
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountinUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountinUSD;
    }
}