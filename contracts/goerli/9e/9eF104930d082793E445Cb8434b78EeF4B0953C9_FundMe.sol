// Get funds from user
// witdraw funds

//  set a minimum funding value in USD

// SPDX-License-Identifier:MIT
pragma solidity 0.8.8;

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    uint256 public minUSD = 50 * 1e18;

    address[] public funders;

    mapping(address => uint256) public addressToAmountFunded;

    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a minimum fund amont
        // 1. how do we send ETH to this contract?
        require(msg.value.getConversion(priceFeed) >= minUSD, "Did'nt send enough");
        // msg.value gives the amount of wei we spend on it
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
        //  1e18=10^18=100000000000000000000
        //  What is reverting
        // undo any section before, and send remaining
    }

    // address
    // 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

    // function witdraw(){}
    function witdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // revering the array
        // funders=new address[](0);

        // payable(msg.sender).transfer(address(this).balance);

        // require(sendSuccess,"Send failure");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Send Failue");
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Tera baap yaha chodh kai gaya thaa kee tere Maa"
        );
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e18); // 1e*18 == 18000000000
    }

    // function getVersion() public view returns

    function getConversion(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed =
        uint256 ethPrice = getLatestPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;

        return ethAmountInUsd;
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