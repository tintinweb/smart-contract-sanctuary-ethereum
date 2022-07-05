// SPDX-License-Identifier: MIT

// get funds from users
// withraw funds
// set a minimum funding value in USD

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    event Funded(address indexed from, uint256 amount);

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public /* immutable */ i_owner;
        uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

        AggregatorV3Interface public priceFeed;


    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a minimum fund amount in USD
        // 1. how du we send ETH to this contract?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 == 1 * 10 * 18 == 1 ETH
        // 18 decimals
        funders.push(msg.sender); // msg.sender: the wallet address calling the function
        addressToAmountFunded[msg.sender] = msg.value; // keeps track of all the funders in a map who fund our contract with their fund amount
        // what is reverting?
        // undo any action before, and send remaining gas back
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
        // reset the array
        funders = new address[](0);
        // actually withdraw the funds
        // three ways:

        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
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
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); //1**10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // ethPrice 3000_000000000000000000
        // ethAmount 1_000000000000000000
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // ethAmountInUsd 3000
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