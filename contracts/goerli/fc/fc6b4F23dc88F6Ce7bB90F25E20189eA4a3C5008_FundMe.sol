// Get fund from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Set minimum ETH amount in USD
        // msg.value is default 18 decimals
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You didn't send enought ETH/USD you fooo!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, NotOwner());
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // for loop
    // [a, b, c, d,]
    // 0. 1. 2. 3.
    function withdraw() public payable onlyOwner {
        // require(msg.sender == owner, "Sender is not the owner fooo!")
        /* staring index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // logic
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        // withdraw my money foo!
        funders = new address[](0);
        // transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "You failed fooo!");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed fooo!");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
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
        // Need ABI
        // Need Address 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // ); - Without HRE deploying mocks
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
        // ETH in USD
    }

    /*
    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        return priceFeed.version();
    }
    */
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
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