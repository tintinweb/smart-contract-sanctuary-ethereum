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
// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// 859,721
// 840,185 - constant
// 816,726 - immutabel
// 791,836 - revert call
// 796,979 - add receive and fallback special function

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // 21,415
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public adressToAmountFunded;

    // 21,508
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Wanted to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enogh"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000 WEI == 1 ETH
        funders.push(msg.sender);
        adressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // for loop
        // [1, 2, 3, 4]
        // 0. 1. 2. 3.

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            adressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);
        // actually withdraw the funds

        // We have 3 ways to send native tokens
        // transfer - Have automatic revert
        // send - only revert if u put require command
        // call - call any function in etherum

        // transfer
        //payable(msg.sender).transfer(address(this).balance);
        // send
        //bool sendSucess = payable(msg.sender).send(address(this).balance);
        //require(sendSucess, "Send failed");
        // call -
        //(bool callSucess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender == i_owner) {
            revert NotOwner();
        }
        _; // do the rest of the code
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) public view returns (uint256) {
        // to interact to contract outside ours project
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        // Dont need fill all fields, just leave comma for field are unsed
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms in USD
        // 3000.00000000
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ehtAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ehtAmountInUsd;
    }
}