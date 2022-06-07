// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TestAggregator is AggregatorV3Interface
{
	uint8 DECIMALS;
	int256 PRICE;

	constructor(
		uint8 _decimals,
		int256 _price
	) {
		setDecimals(_decimals);
		setPrice(_price);
	}

	function setDecimals(uint8 _decimals) public {
		DECIMALS = _decimals;
	}

	function setPrice(int256 _price) public {
		PRICE = _price;
	}

	function decimals() external view returns (uint8) {
		return DECIMALS;
	}

	function description() external view returns (string memory) {
		return "Mock Aggregator";
	}

	function version() external view returns (uint256) {
		return 1;
	}

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
	) {
		return (_roundId, PRICE, 1, 1, 1);
	}

	function latestRoundData()
		external
		view
	returns (
		uint80 roundId,
		int256 answer,
		uint256 startedAt,
		uint256 updatedAt,
		uint80 answeredInRound
    ) {
		return (1, PRICE, 1, 1, 1);
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