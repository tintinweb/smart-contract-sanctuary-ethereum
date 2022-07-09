// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./utils/PriceConverter.sol";

// custom error less gas than require w/ string error message!
error NotOwner();
uint256 constant MIN_REQUIRED_USD = .5 * 1e18;

contract FundMe {
	// 1.
	using PriceConverter for AggregatorV3Interface;

	AggregatorV3Interface private immutable i_aggregator;
	address private immutable i_owner;
	mapping(address => uint256) public funds;
	address[] public funders; // help to make mapping above iterable

	constructor(address aggregatorAddress) {
		i_aggregator = AggregatorV3Interface(aggregatorAddress);
		i_owner = msg.sender;
	}

	function fund() external payable {
		require(i_aggregator.toUsd1e18(msg.value) >= MIN_REQUIRED_USD, "You must pay at least .5 USD");
		funds[msg.sender] += msg.value;
		funders.push(msg.sender);
	}

	function withdraw() external onlyOwner {
		// reset
		for (uint256 index = 0; index < funders.length; index++) {
			funds[funders[index]] = 0;
		}
		funders = new address[](0); // array w/ 0 elements
		// send eth
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success, "Could not send funds");
	}

	modifier onlyOwner() {
		if (msg.sender != i_owner) revert NotOwner();
		_;
	}

	fallback() external payable {
		this.fund();
	}

	receive() external payable {
		this.fund();
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
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
	function toUsd1e18(AggregatorV3Interface priceFeed, uint256 weis)
		internal
		view
		returns (uint256)
	{
		(, int256 usdPerEth1e8, , , ) = priceFeed.latestRoundData();
		return (uint256(usdPerEth1e8) * weis) / 1e8;
	}
}