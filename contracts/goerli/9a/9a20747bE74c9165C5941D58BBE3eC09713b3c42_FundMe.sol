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

// Get fund from users
// Withdraw funs
// Set minimum funding in USD

import "./PriceConverter.sol";

error NotOwner(); // custom error

contract FundMe {
    using PriceConverter for uint256; // all uint256 can use this library methods

    address[] public funders; // array of funder addresses
    mapping(address => uint256) public addressToAmountFunded; // keep track of how much each address sent

    address public immutable iContractOwner; // address of contract owner
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18; // float doesnt work well so we need to use integers

    AggregatorV3Interface public priceFeed; // pricefeed state var

    constructor(address priceFeedAddress) {
        // called when contract is deployed
        iContractOwner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        // modifier used for methods
        if (msg.sender != iContractOwner) revert NotOwner(); // check if address is owner
        _; // continue with code of method
    }

    function fund() public payable {
        // payable - can receive funds
        // if not passed then revert, reverting will undo all actions above require and send remaining gas back
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Not enought ETH"
        ); // get received value using global msg.value,1ETH -> 1e18 == 1*10^18 math is done in wei
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        funders.push(msg.sender);

        if (addressToAmountFunded[msg.sender] == uint256(0)) {
            addressToAmountFunded[msg.sender] = msg.value;
        } else {
            addressToAmountFunded[msg.sender] += msg.value;
        }
    }

    function withdraw() public onlyOwner {
        // only owner can call this function
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; // we cannot reset mapping so we just set amount to 0
        }

        funders = new address[](0); // reset array, create empty with 0

        // transfer - simple transfer to (msg.sender)
        // payable(msg.sender).transfer(address(this).balance); // must cast mgs.sender to payable because only payable can sendm automatically reverts on fail

        // send - returns boolean
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed"); // transaction will only revert if we add require

        // call - lower level command, can call any function - recommended way of sending funds
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    fallback() external payable {
        // hadles case when users sends funds and nonexistent funcion is called with calldata
        fund();
    }

    receive() external payable {
        // handles case when user sends funds to contract without calldata
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // npm import external contract

library PriceConverter {
    // library cannot have state variables and cant send eth

    // we can use this function like msg.value.getConversionRate
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(price * 10000000000); // cast as uint256
        // or (Both will do the same thing)
        // return uint256(price * 1e10); // 1* 10^10 == 10000000000
    }

    // eth to usd, msg.value is considered first parameter
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // or (Both will do the same thing)
        // uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // 1 * 10 ** 18 == 1000000000000000000
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    // get aggregator version
    function getVersion(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // https://docs.chain.link/data-feeds/price-feeds/addresses/
        return priceFeed.version();
    }
}