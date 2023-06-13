// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotEnoughETH();
error FundMe__NotOwner();
error FundMe__CallFailed();

contract FundMe {
    using PriceConverter for uint256;

    uint256 private constant MINIMUM_USD = 50 * 1e18;
    address private immutable i_owner;

    address[] public funders;
    mapping(address => uint256) private addressToAmountFunded;

    AggregatorV3Interface priceFeed;

    modifier onlyOwner {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if (msg.value.getConversionRate(priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughETH();
        }
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!callSuccess) {
            revert FundMe__CallFailed();
        }
    }

    function getMinimumUSD() public pure returns(uint256) {
        return MINIMUM_USD;
    }

    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address) {
        return funders[index];
    }

    function getAmountFunded(address funder) public view returns(uint256) {
        return addressToAmountFunded[funder];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // This function get the price of ETH in USD. Converts ETH to USD.
    // To get price info., we need to fetch price from an Oracle like ChainLink Data Feeds
    // Since we are dealing with external contract, we need to get the Address and ABI of the external contract
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price ** 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}