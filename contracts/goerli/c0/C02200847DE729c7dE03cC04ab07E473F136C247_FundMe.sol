// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // at least this version

import "./PriceConverter.sol";
/// Get funds from users
/// Withdraw funds
/// Set a minimum funding value in USD

/*
before - 834027 gas
constant MINIMUM_USD - 814467 gas
immutable i_owner - 790900 gas
*/

/// custom error
error NotOwner();

contract FundMe {
    /// using the library
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    /// keep a list of funding addresses
    address[] public funders;
    /// map of address to amount funded
    mapping(address => uint256) public addressToAmountFunded;

    // address public owner;
    address public immutable i_owner;

    // create an aggregator obj
    AggregatorV3Interface public priceFeed;

    // sets up contract
    constructor(address priceFeedAddress) {
        // contract deployer = owner
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        /// set minimum fund amount in USD
        /// min funding of 1eth
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough funds!"
        );
        /// saving to funders array
        funders.push(msg.sender);
        /// saving to a map
        addressToAmountFunded[msg.sender] = msg.value;
    }

    /// allows funder to withdraw
    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "sender is not owner");
        /// for loop - reset funders mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        /// reset array - 0 means 0 objects
        funders = new address[](0);
        /// withdraw the funds - 3 ways
        /*
        1. transfer to whomever is calling the function
            msg.sender = address
            payable(msg.sender) = payable address
        */

        // payable(msg.sender).transfer(address(this).balance);

        /// 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed. hence Reverting");

        /// 3. call
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed, revering");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "sender is not owner");
        /// custom error
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // represents the to-be run code
    }

    /*
    - what happens if someone sends this contract ETH without calling fund()
    - 2 special functions
        - receive
        - fallback
    */

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // at least this version

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        /// ABI
        /// Address - 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e ETH/USD
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        /// full data unpacking
        // (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed;
        (, int256 price, , , ) = priceFeed.latestRoundData();
        /// ETH in terms of USD
        /// 1800.00000000 usd at time of editing
        /// msg.value -> 18 decimal places
        /// ETH/USD from priceFeed -> 8 decimal places
        /// returned value needs to have 10 more decimal places to match
        return uint256(price * 1e10); // 1**10
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
        // 2000_00000000000000000 = ETH / USD price
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