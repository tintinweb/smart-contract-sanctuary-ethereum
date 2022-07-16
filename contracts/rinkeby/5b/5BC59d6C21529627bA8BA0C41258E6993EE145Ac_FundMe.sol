// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__InsufficientFunds();
error FundMe__NotOwner();
error FundMe__WithdrawFailed();

contract FundMe {
    using PriceConverter for uint256;

    AggregatorV3Interface private immutable priceFeed;
    address[] private funders;
    mapping(address => uint256) public getFundsOfFunder;
    uint256 private constant MIN_USD = 20 * 10 ** 18;
    address private immutable owner;

    modifier OnlyOwner() {
        if(msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    
    function fund() public payable {
        if(msg.value.getConversionRate(priceFeed) < MIN_USD) revert FundMe__InsufficientFunds();
        funders.push(msg.sender);
        getFundsOfFunder[msg.sender] += msg.value;
    }

    function withdraw() public payable OnlyOwner {
        for(uint i = 0; i < funders.length;) {
            address funder = funders[i];
            getFundsOfFunder[funder] = 0;
            unchecked{ i++; }
        }
        funders = new address[](0);

        (bool isSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!isSuccess) revert FundMe__WithdrawFailed();
    }

    function totalBalance() view public returns (uint256) {
        return address(this).balance;
    }

    function getMinimumUSD() pure public returns(uint256) {
        return MIN_USD;
    }

    function getEthPrice() view external returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getFunder(uint256 _index) public view returns(address) {
        return funders[_index];
    }

    function getFunders() public view returns(address[] memory) {
        return funders;
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

library PriceConverter {
    function getEthPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 amount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getEthPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * amount) / 1e18;
        return ethAmountInUsd;
    }
}