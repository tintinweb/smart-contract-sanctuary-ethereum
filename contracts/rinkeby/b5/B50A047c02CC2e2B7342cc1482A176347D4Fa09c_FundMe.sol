// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__NotEnough();
error FundMe__CallFailed();

/** @title A contract for crowd funding
 * @author Shaun Saker
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library */
contract FundMe {
    using PriceConverter for uint256;

    // we prefix immutable variables with i_ so that we can easily see that we do not need to optimise their gas usage
    address private immutable i_owner;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    // we predix storage variables with s_ so that it's easy to see (and optimise) where the most gas is used
    address[] private s_funders;

    mapping(address => uint256) private s_addressToAmountFunded;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // custom error saves gas because we don't need to store the string error message
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }

        _; // continue with the rest of the code
    }

    constructor(address priceFeedAddress) {
        // when the contract is deployed, we keep track of who deployed it
        // so only they can withdraw the funds
        i_owner = msg.sender;

        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // set a minimum in USD
        // msg.value is the value in wei of ETH
        // if this condition is not met, all the gas above this line is used
        // and all the gas below this function is reverted aka sent back
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnough();
        }

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public payable onlyOwner {
        // optimise gas usage by loading s_funders into memory
        // otherwise we read s_funders on every loop
        address[] memory funders = s_funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // TODO: why do we even need funders? Can't we just use the mapping s_addressToAmountFunded as the addresses are already duplicated tehre?
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the s_funders array
        s_funders = new address[](0);

        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");

        if (!callSuccess) {
            revert FundMe__CallFailed();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// this is a library
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // price is returned with 8 decimals while msg.value has 18 (wei)
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}