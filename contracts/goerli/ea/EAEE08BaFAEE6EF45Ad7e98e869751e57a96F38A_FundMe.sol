// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Get funds from users
// store users that fund the system in an array
// store users that fund the system in a dictionary so as to map them with the amount they fund
// Withdraw funds
// set a minimum funding value in USD

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_AMOUNT = 50 * 1e18;
    address[] public funders;
    mapping (address => uint256) public fundersAddressToAmount;

    address public immutable owner;

    AggregatorV3Interface public priceFeed;

    constructor (address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // set minimum amount to be funded
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_AMOUNT, "Not enough funds in the system"); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        funders.push(msg.sender);
        fundersAddressToAmount[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 index =0; index < funders.length; index++) {
            address funder = funders[index];
            fundersAddressToAmount[funder] = 0;
        }

        // reset the funders array
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner {
        // require(msg.sender == owner, "Owner only");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _; // run rest of the code
    }

    receive() external payable {
        fund();
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // has 8 decimal places and eth has 18 decimals
        // therefore to make it the same we multiply by whats left to make it 18 => 10
        return uint256(price * 1e10); // 1**10 == 1
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
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