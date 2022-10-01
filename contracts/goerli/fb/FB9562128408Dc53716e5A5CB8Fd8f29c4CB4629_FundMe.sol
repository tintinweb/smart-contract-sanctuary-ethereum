// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // These are left as public but generally private fields cost less gas
    // if you want them accessible, consider adding getter methods instead.
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // These are left as public but generally private fields cost less gas
    // if you want them accessible, consider adding getter methods instead.
    uint256 public constant MINIMUM_USD = 50;

    // owner should never really be public and must always be immutable
    address public immutable owner;

    // These are left as public but generally private fields cost less gas
    // if you want them accessible, consider adding getter methods instead.
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddr) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddr);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Minimum of 1 ether allowed");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    function cheaperWithdrawal() public payable {
        // by directly using memory instead of relying on the storage, we can save
        // gas as well
        address[] memory c_funders = funders;
        for(uint256 funderIndex = 0; funderIndex < c_funders.length; funderIndex++) {
            address funder = c_funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        (bool callSuccess, ) = owner.call{ value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdrawal() onlyOwner public payable {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // 1. We can transfer
        // payable(msg.sender).transfer(address(this).balance);

        // 2. We can send instead
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Call failed");

        // 3. We can use the low level call function
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{ value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Use Georli Chainlink address
    int256 constant private oneWei = 1e10;

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , ,) = priceFeed.latestRoundData();

        // ETH/USD rate in 18 bits (wei)
        return uint256(answer * oneWei);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
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