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
pragma solidity ^0.8.17;

import "./PriceConverter.sol";

error FundMe__notOwner();
error FundMe__callFailed();
error FundMe__notMinFunds();

/**
 * @title A contract for crowdfunding
 * @author vvinteresting
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */

// Functions order:
// constructor
// receive
// fallback
// external
// public
// internal
// private
// view / pure
contract FundMe {
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__notOwner();
        }
        _;
    }

    // constructor
    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // receive
    receive() external payable {
        fund();
    }

    // fallback
    fallback() external payable {
        fund();
    }

    // public
    /**
     * @notice This function funds this contract
     */
    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?

        // when using a library for a data type,
        // the variable invoking the library is considered the first parameter
        // ex. getConversionRate(uint256) === uint256.getConversionRate()

        // all subsequent arguments expected of a function are passed in the parentheses
        // ex. getConversionRate uint256 a, string b) === uint256.getConversionRate(string);

        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__notMinFunds();
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    /**
     * @notice This function withdraws funds previously accrued
     */
    function withdraw() public payable onlyOwner {
        for (uint256 x; x < s_funders.length; x++) {
            s_addressToAmountFunded[s_funders[x]] = 0;
            // less efficient to update all funders[] addresses one at a time...
            // funders[x] = address(0);
        }
        // than it is to just reset the whole array at once
        s_funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert FundMe__callFailed();
        }
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        uint256 length = funders.length;
        for (uint256 x; x < length; x++) {
            address funder = s_funders[x];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if (!success) {
            revert FundMe__callFailed();
        }
    }

    // view
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// libraries:
// - cant have state variables
// - cant send ether
// - all functions are internal

library PriceConverter {
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        (, int256 price, , , ) = _priceFeed.latestRoundData();
        // ETH in terms of USD
        return uint256(price * 1e10); // price has 8 decimals, this adds 10 more decimal points to match ETH
    }

    function getVersion(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        return _priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}