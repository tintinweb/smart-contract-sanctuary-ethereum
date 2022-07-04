// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// Custom Error
error NotOwner();

contract FundMe {
	using PriceConverter for uint256;

	uint256 public constant MINIMUM_USD = 50 * 1e18;

	// Collecting the addresses of the funders
	address[] public funders;

	// Mapping the funders to the amount they sent
	mapping(address => uint256) public addressToAmountFunded;

	function fund() public payable {
		require(
			msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
			/*reverting*/
			"Please send more.."
		);
		// Money math is done in terms of wei,
		// so, 1 ETH needs to be set as 1e18 value.

		funders.push(msg.sender);
		addressToAmountFunded[msg.sender] = msg.value;
	}

	function withdraw() public onlyOwner {
		for (
			uint256 funderIndex = 0;
			funderIndex < funders.length;
			funderIndex++
		) {
			address funder = funders[funderIndex];
			addressToAmountFunded[funder] = 0;
		}
		// reset the funders array
		funders = new address[](0);

		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}(""); // this returns two variables
		//(                ,bytes memory dataReturned)
		require(callSuccess, "Call failed");
	}

	address public immutable i_owner;

	// 21,508 gas - immutable
	// 23,644 gas - non-immutable

	AggregatorV3Interface public priceFeed;

	constructor(address priceFeedAddress) {
		i_owner = msg.sender; // whoever deploys the contract is the owner
		priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	modifier onlyOwner() {
		if (msg.sender != i_owner) {
			revert NotOwner();
		}
		_; // rest of the original code is executed by writing this underscore
	}

	// Special functions (constructor also) NO need to specify the "function" keyword.
	receive() external payable {
		fund();
	}

	fallback() external payable {
		fund();
	}
}

// This is a LIBRARY
// All the functions inside a library needs to be internal

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // NPM Package

library PriceConverter {
	function getPrice(AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		(, int256 price, , , ) = priceFeed.latestRoundData();

		// msg.value and this should be equal in terms of formats
		return uint256(price * 1e10); // (1 X 10)^10 == 10000000000
	}

	function getConversionRate(
		uint256 ethAmount,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getPrice(priceFeed);
		uint256 ethPriceInUsd = (ethPrice * ethAmount) / 1e18;

		return ethPriceInUsd;
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